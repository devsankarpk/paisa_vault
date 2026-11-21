import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/sms/raw_message_repository.dart';
import 'package:paisa_vault/features/sms/shortcut_guide_screen.dart';
import 'package:paisa_vault/features/sms/sms_classifier.dart';
import 'package:paisa_vault/features/sms/sms_disclosure_screen.dart';
import 'package:paisa_vault/features/sms/sms_runner.dart';
import 'package:paisa_vault/services/sms_source.dart';
import 'package:paisa_vault/testing/fakes.dart';

IncomingSms sms(String body, {DateTime? at, String sender = 'VM-HDFCBK'}) =>
    IncomingSms(
      sender: sender,
      body: body,
      receivedAt: at ?? DateTime(2026, 11, 20, 10),
      simSubscriptionId: 1,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late FakeClock clock;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_sms');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    clock = FakeClock(DateTime(2026, 11, 20, 10, 5));
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  group('RawMessageRepository', () {
    test('saves a message with sender, SIM and time', () async {
      final repo = RawMessageRepository(db, clock);
      final id = await repo.save(sms('Rs 5 debited'));
      expect(id, isNotNull);
      final row = await db.select(db.rawMessages).getSingle();
      expect(row.sender, 'VM-HDFCBK');
      expect(row.simSubscriptionId, 1);
      expect(row.status, RawMessageStatus.newMessage);
    });

    test('the same SMS saved twice close together is stored once', () async {
      final repo = RawMessageRepository(db, clock);
      await repo.save(
        sms('Rs 5 debited', at: DateTime(2026, 11, 20, 10, 0, 0)),
      );
      final again = await repo.save(
        sms('Rs 5 debited', at: DateTime(2026, 11, 20, 10, 0, 4)),
      );
      expect(again, isNull);
      expect((await db.select(db.rawMessages).get()).length, 1);
    });

    test('the same text much later is a new message', () async {
      final repo = RawMessageRepository(db, clock);
      await repo.save(sms('Rs 5 debited', at: DateTime(2026, 11, 20, 10)));
      expect(
        await repo.save(sms('Rs 5 debited', at: DateTime(2026, 11, 21, 10))),
        isNotNull,
      );
    });
  });

  group('SmsIngest', () {
    test('saves staged messages, then acknowledges them', () async {
      final source = FakeSmsSource()
        ..emit(sms('Rs 1 debited'))
        ..emit(sms('Rs 2 credited'));
      final saved = (await SmsIngest(
        source,
        RawMessageRepository(db, clock),
      ).drain()).saved;
      expect(saved, 2);
      expect(source.staged, isEmpty);
      expect(source.acknowledged.length, 2);
    });

    test('a repeat is acknowledged but not stored twice', () async {
      final source = FakeSmsSource()
        ..emit(sms('Rs 1 debited'))
        ..emit(sms('Rs 1 debited'));
      final saved = (await SmsIngest(
        source,
        RawMessageRepository(db, clock),
      ).drain()).saved;
      expect(saved, 1);
      expect(source.acknowledged.length, 2);
    });

    test(
      'OTP and promo messages are dropped, not stored, but acknowledged',
      () async {
        final source = FakeSmsSource()
          ..emit(
            sms('123456 is your OTP for txn of Rs 500.00. Do not share it.'),
          )
          ..emit(
            sms('Pre-approved loan up to Rs 5,00,000! Apply now http://x.co/a'),
          )
          ..emit(sms('Rs 75.00 debited from A/c XX1234 to TESTSHOP'));
        final r = await SmsIngest(
          source,
          RawMessageRepository(db, clock),
        ).drain();
        expect(r.dropped, 2);
        expect(r.saved, 1);
        expect(r.byKind[SmsKind.otp], 1);
        expect(source.staged, isEmpty);
        expect((await db.select(db.rawMessages).get()).length, 1);
      },
    );

    test(
      'transactions are marked new, reminders and declines are ignored',
      () async {
        final source = FakeSmsSource()
          ..emit(sms('Rs 75.00 debited from A/c XX1234 to TESTSHOP'))
          ..emit(
            sms(
              'Statement generated. Total amount due Rs 12,345.00. Pay by 05-Dec-26',
            ),
          )
          ..emit(sms('Your txn of Rs 500 at XYZ STORE was declined'));
        await SmsIngest(source, RawMessageRepository(db, clock)).drain();
        final rows = await db.select(db.rawMessages).get();
        expect(
          rows.where((r) => r.status == RawMessageStatus.newMessage).length,
          1,
        );
        expect(
          rows.where((r) => r.status == RawMessageStatus.ignored).length,
          2,
        );
      },
    );

    test(
      'if saving fails nothing is acknowledged, so nothing is lost',
      () async {
        final source = FakeSmsSource()..emit(sms('Rs 1 debited'));
        final ingest = SmsIngest(source, _FailingRepository(db, clock));
        await expectLater(ingest.drain(), throwsA(anything));
        expect(source.staged.length, 1);
        expect(source.acknowledged, isEmpty);
      },
    );
  });

  group('SmsRunner', () {
    Future<(ProviderContainer, FakeSmsSource, MemorySecretStore)> pump(
      WidgetTester t, {
      required bool granted,
      bool iphone = false,
    }) async {
      final source = FakeSmsSource(granted: granted);
      final store = MemorySecretStore();
      final container = ProviderContainer(
        overrides: [
          smsSourceProvider.overrideWithValue(source),
          secretStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(clock),
          appDatabaseProvider.overrideWith((ref) async => db),
          needsShortcutGuideProvider.overrideWithValue(iphone),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SmsRunner(child: Text('HOME'))),
        ),
      );
      await t.pumpAndSettle();
      return (container, source, store);
    }

    testWidgets('no permission yet: shows the disclosure before asking', (
      t,
    ) async {
      final (c, source, _) = await pump(t, granted: false);
      expect(find.byType(SmsDisclosureScreen), findsOneWidget);
      expect(find.textContaining('never uploaded'), findsOneWidget);
      expect(source.permissionRequests, 0);
      c.dispose();
    });

    testWidgets('Continue asks for permission once and remembers', (t) async {
      final (c, source, store) = await pump(t, granted: true);
      // granted already: straight to home, no disclosure
      expect(find.text('HOME'), findsOneWidget);
      expect(source.permissionRequests, 0);
      c.dispose();
      expect(store.map, isEmpty);
    });

    testWidgets('Not now goes to home and does not ask again', (t) async {
      final (c, source, store) = await pump(t, granted: false);
      await t.tap(find.textContaining('Not now'));
      await t.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(source.permissionRequests, 0);
      expect(store.map['pv_sms_disclosure_seen'], 'true');
      c.dispose();
    });

    testWidgets('iPhone: shows the Shortcut guide once, then home', (t) async {
      // A tall screen so the whole guide is built (the list is lazy).
      t.view.physicalSize = const Size(800, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final (c, source, store) = await pump(t, granted: true, iphone: true);
      expect(find.byType(ShortcutGuideScreen), findsOneWidget);
      expect(find.textContaining('Shortcut ran'), findsOneWidget);
      expect(find.byType(SmsDisclosureScreen), findsNothing);
      expect(source.permissionRequests, 0);
      await t.tap(find.text('I have set it up'));
      await t.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(store.map['pv_shortcut_guide_seen'], 'true');
      c.dispose();
    });

    testWidgets('a message arriving while open is saved', (t) async {
      final (c, source, _) = await pump(t, granted: true);
      source.emit(sms('Rs 9 debited at SWIGGY'));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await t.pumpAndSettle();
      final rows = await t.runAsync(() => db.select(db.rawMessages).get());
      expect(rows!.length, 1);
      expect(source.staged, isEmpty);
      c.dispose();
    });
  });
}

class _FailingRepository extends RawMessageRepository {
  _FailingRepository(super.db, super.clock);
  @override
  Future<int?> save(
    IncomingSms sms, {
    RawMessageStatus status = RawMessageStatus.newMessage,
  }) async => throw StateError('disk full');
}
