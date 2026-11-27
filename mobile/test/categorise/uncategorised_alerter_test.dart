import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/features/categorise/uncategorised_alerter.dart';
import 'package:paisa_vault/services/notifier.dart';
import 'package:paisa_vault/testing/fakes.dart';

class _Rec implements AlertNotifier {
  final shown = <(String, String)>[];
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async => shown.add((title, body));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late FakeClock clock;
  late _Rec rec;
  late UncategorisedAlerter alerter;
  var n = 0;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_uncat');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    clock = FakeClock(DateTime(2026, 11, 10, 12));
    rec = _Rec();
    alerter = UncategorisedAlerter(db, clock, rec);
    n = 0;
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> add({String? category}) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          amountPaise: 48000,
          direction: Direction.debit,
          merchant: const Value('RAJU STORES'),
          categoryName: Value(category),
          fingerprint: 'f${n++}',
          occurredAt: DateTime(2026, 11, 10),
          createdAt: DateTime(2026, 11, 10),
        ),
      );

  test('nothing to ask means no notification', () async {
    await add(category: 'Food');
    expect(await alerter.run(), 0);
    expect(rec.shown, isEmpty);
  });

  test(
    'one new transaction is announced once, without merchant or amount',
    () async {
      await add();
      expect(await alerter.run(), 1);
      expect(await alerter.run(), 0);
      expect(rec.shown, hasLength(1));
      final text = '${rec.shown.single.$1} ${rec.shown.single.$2}';
      expect(text.contains('RAJU'), isFalse);
      expect(text.contains('480'), isFalse);
    },
  );

  test('several are grouped into one evening reminder a day', () async {
    await add();
    await add();
    await add();
    expect(await alerter.run(), 0); // noon: wait for the evening
    clock.current = DateTime(2026, 11, 10, 19);
    expect(await alerter.run(), 1);
    expect(rec.shown.single.$2, contains('3 transactions'));
    expect(await alerter.run(), 0); // same day: not again
    clock.current = DateTime(2026, 11, 11, 19);
    expect(await alerter.run(), 0); // nothing new since
    await add();
    expect(await alerter.run(), 1); // a new one, next evening reminder
    expect(rec.shown, hasLength(2));
  });
}
