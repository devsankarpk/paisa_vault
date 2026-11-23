import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/features/pipeline/extraction_pipeline.dart';
import 'package:paisa_vault/features/sms/raw_message_repository.dart';
import 'package:paisa_vault/features/transactions/format.dart';
import 'package:paisa_vault/features/transactions/processing_service.dart';
import 'package:paisa_vault/features/transactions/rule_amount.dart';
import 'package:paisa_vault/features/transactions/transaction_detail_screen.dart';
import 'package:paisa_vault/features/transactions/transaction_repository.dart';
import 'package:paisa_vault/features/transactions/transactions_screen.dart';
import 'package:paisa_vault/services/sms_source.dart';
import 'package:paisa_vault/testing/fakes.dart';

// Invented messages, not real customer messages.
const withMerchant =
    'Rs 250.00 spent on HDFC Bank Card x1234 at ZOMATO on 12-10-26.';
const noMerchant =
    'Rs 499.00 debited from A/c XX1234 on 20-11-26. UPI Ref 123456789012';
const goodReply =
    '{"merchant": "SOME SHOP", "category": "Shopping", "channel": "UPI"}';

IncomingSms sms(String body, DateTime at) =>
    IncomingSms(sender: '', body: body, receivedAt: at);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late FakeClock clock;
  late RawMessageRepository raw;
  late TransactionRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_tx');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    clock = FakeClock(DateTime(2026, 11, 21, 12));
    raw = RawMessageRepository(db, clock);
    repo = TransactionRepository(db, clock);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  ProcessingService service({FakeLlmEngine? llm}) => ProcessingService(
    db,
    repo,
    ExtractionPipeline(llm, categories: defaultCategories),
  );

  group('typed amounts', () {
    test('rupeesToPaise accepts normal input and rejects the rest', () {
      expect(rupeesToPaise('499'), 49900);
      expect(rupeesToPaise(' 499.5 '), 49950);
      expect(rupeesToPaise('1,250.00'), 125000);
      expect(rupeesToPaise('abc'), isNull);
      expect(rupeesToPaise(''), isNull);
    });
  });

  group('formatting', () {
    test('Indian grouping', () {
      expect(formatRupees(49900), '499.00');
      expect(formatRupees(123456), '1,234.56');
      expect(formatRupees(12345678), '1,23,456.78');
      expect(formatRupees(10000050), '1,00,000.50');
      expect(formatRupees(5), '0.05');
    });
    test('signed amount and date', () {
      expect(signedAmount(125000, Direction.debit), '-₹1,250.00');
      expect(signedAmount(125000, Direction.credit), '+₹1,250.00');
      expect(formatDate(DateTime(2026, 11, 2)), '2 Nov 2026');
    });
  });

  group('processing', () {
    test(
      'a new message becomes a transaction and is marked processed',
      () async {
        await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
        final r = await service(llm: FakeLlmEngine([goodReply])).processNew();
        expect(r.transactions, 1);
        final t = await db.select(db.transactions).getSingle();
        expect(t.amountPaise, 25000);
        expect(t.merchant, 'ZOMATO'); // rule beats the model
        expect(t.bankCode, 'HDFC');
        expect(t.last4, '1234');
        expect(t.occurredAt, DateTime(2026, 10, 12));
        expect(t.rawMessageId, isNotNull);
        expect(
          (await db.select(db.rawMessages).getSingle()).status,
          RawMessageStatus.processed,
        );
      },
    );

    test('with no model, a message whose merchant the rules cannot find needs checking', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      await service().processNew();
      final t = await db.select(db.transactions).getSingle();
      expect(t.status, TransactionStatus.pleaseConfirm);
      expect(t.confirmReason, 'no_model');
      expect(t.merchant, isNull);
      expect(t.modelId, isNull);
    });

    test(
      'with no model, a message whose merchant the rules found is confirmed',
      () async {
        await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
        await service().processNew();
        expect(
          (await db.select(db.transactions).getSingle()).status,
          TransactionStatus.confirmed,
        );
      },
    );

    test('a message with no amount is ignored and not retried', () async {
      await raw.save(
        sms('Your account was credited', DateTime(2026, 11, 21, 10)),
      );
      final first = await service().processNew();
      expect(first.skipped, 1);
      expect((await service().processNew()).skipped, 0);
      expect(
        (await db.select(db.rawMessages).getSingle()).status,
        RawMessageStatus.ignored,
      );
      expect(await db.select(db.transactions).get(), isEmpty);
    });

    test('running twice does not duplicate transactions', () async {
      await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
      final s = service();
      await s.processNew();
      await s.processNew();
      expect((await db.select(db.transactions).get()).length, 1);
    });
  });

  group('corrections', () {
    test('an edit confirms the transaction and marks it corrected', () async {
      await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
      await service().processNew();
      final id = (await db.select(db.transactions).getSingle()).id;
      await repo.correct(
        id,
        merchant: 'RAJU STORES',
        categoryName: 'Groceries',
        amountPaise: 50000,
      );
      final t = await db.select(db.transactions).getSingle();
      expect(t.merchant, 'RAJU STORES');
      expect(t.categoryName, 'Groceries');
      expect(t.amountPaise, 50000);
      expect(t.status, TransactionStatus.confirmed);
      expect(t.userCorrected, true);
    });
  });

  group('screens', () {
    ProviderContainer? container;

    Future<void> pump(WidgetTester t, Widget home) async {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          clockProvider.overrideWithValue(clock),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: MaterialApp(home: home),
        ),
      );
    }

    // Bounded pumps: a loading spinner animates forever, so pumpAndSettle would never return.
    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 4; i++) {
        // The database runs outside the test clock, so give it real time.
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    // Remove the screen and let drift's query-cleanup timer run, so no timer is left pending.
    Future<void> finish(WidgetTester t) async {
      await t.pumpWidget(const SizedBox());
      container?.dispose(); // cancels the live queries now, inside the test
      container = null;
      for (var i = 0; i < 3; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump(const Duration(seconds: 1));
      }
    }

    testWidgets('empty list says so', (t) async {
      await pump(t, const TransactionsScreen());
      await settle(t);
      expect(find.textContaining('No transactions yet'), findsOneWidget);
      await finish(t);
    });

    testWidgets('list shows merchant, amount, bank and a check flag', (
      t,
    ) async {
      await t.runAsync(() async {
        await raw.save(sms(withMerchant, DateTime(2026, 11, 21, 10)));
        await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 11)));
        await service().processNew();
      });
      await pump(t, const TransactionsScreen());
      await settle(t);
      expect(find.text('ZOMATO'), findsOneWidget);
      expect(find.text('-₹250.00'), findsOneWidget);
      expect(find.text('Unknown merchant'), findsOneWidget);
      expect(find.text('Please check'), findsOneWidget);
      expect(find.textContaining('HDFC'), findsWidgets);
      await finish(t);
    });

    testWidgets(
      'detail shows every field and the original message, and the edit sheet checks input',
      (t) async {
        t.view.physicalSize = const Size(800, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        late int id;
        await t.runAsync(() async {
          await raw.save(sms(noMerchant, DateTime(2026, 11, 21, 10)));
          await service().processNew();
          id = (await db.select(db.transactions).getSingle()).id;
        });
        await pump(t, TransactionDetailScreen(id: id));
        await settle(t);
        expect(find.text('-₹499.00'), findsOneWidget);
        expect(find.text('20 Nov 2026'), findsOneWidget);
        expect(find.text('123456789012'), findsOneWidget);
        expect(
          find.text('Not found'),
          findsWidgets,
        ); // merchant and category are missing
        expect(find.textContaining('No merchant found yet'), findsOneWidget);
        expect(find.text(noMerchant), findsOneWidget); // original message

        // The edit sheet opens pre-filled and refuses a bad amount.
        await t.tap(find.text('Correct something'));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.text('Correct transaction'), findsOneWidget);
        await t.enterText(find.widgetWithText(TextField, 'Amount (₹)'), 'abc');
        // Call the button directly: the sheet sits partly off the test screen.
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed!();
        await t.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('Enter an amount'), findsOneWidget);
        await finish(t);
      },
    );
  });
}
