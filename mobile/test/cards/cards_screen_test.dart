import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/features/cards/cards_screen.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  ProviderContainer? container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_cards_ui');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester t) async {
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async => db),
        clockProvider.overrideWithValue(FakeClock(DateTime(2026, 11, 28))),
      ],
    );
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container!,
        child: const MaterialApp(home: CardsScreen()),
      ),
    );
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> finish(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    container?.dispose();
    container = null;
    for (var i = 0; i < 3; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(seconds: 1));
    }
  }

  testWidgets(
    'empty list says so, then a typed card appears with a bill setup',
    (t) async {
      t.view.physicalSize = const Size(
        800,
        1800,
      ); // tall, so the whole detail list is built
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await pump(t);
      await settle(t);
      expect(find.textContaining('No cards yet'), findsOneWidget);
      expect(find.textContaining('CVV is never stored'), findsOneWidget);

      await t.tap(find.byTooltip('Add card'));
      await settle(t);
      expect(find.textContaining('never asked for or stored'), findsOneWidget);
      expect(
        find.byType(TextField),
        findsNWidgets(2),
      ); // last 4 and expiry only
      await t.enterText(find.widgetWithText(TextField, 'Last 4 digits'), '12');
      await t.tap(find.text('Next: bill reminder'));
      await settle(t);
      expect(find.text('Enter exactly 4 digits'), findsOneWidget);

      await t.enterText(
        find.widgetWithText(TextField, 'Last 4 digits'),
        '6464',
      );
      await t.tap(find.text('Next: bill reminder'));
      await settle(t);
      expect(find.text('Statement day'), findsOneWidget); // bill setup opened
      await t.tap(find.text('Save'));
      await settle(t);

      expect(find.text('HDFC Bank •••• 6464'), findsOneWidget);
      expect(find.text('Credit card · Visa'), findsOneWidget);
      await t.pump(const Duration(seconds: 1)); // let the page transition end
      await t.tap(find.text('HDFC Bank •••• 6464'));
      await settle(t);
      await settle(t);
      expect(find.text('Statement'), findsOneWidget);
      expect(find.textContaining('5, 1 days before'), findsOneWidget);
      await finish(t);
    },
  );
}
