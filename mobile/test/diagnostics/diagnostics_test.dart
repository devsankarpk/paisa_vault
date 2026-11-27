import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/features/diagnostics/diagnostics_report.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  var n = 0;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_diag');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    n = 0;
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('model log lines become averages, slowest and error counts', () {
    final s = summariseModelLog([
      '2026-11-26T05:00:00Z loaded seconds=2.6',
      '2026-11-26T05:00:04Z generated seconds=3.0 chars=88 think=false',
      '2026-11-26T05:00:09Z generated seconds=5.0 chars=90 think=false',
      '2026-11-26T05:01:00Z generate_failed error=TimeoutException',
      '2026-11-26T05:02:00Z generate_failed error=TimeoutException',
      '2026-11-26T05:03:00Z model_not_found',
      'garbage line',
    ]);
    expect(s.answers, 2);
    expect(s.avgSeconds, 4.0);
    expect(s.slowestSeconds, 5.0);
    expect(s.loads, 1);
    expect(s.avgLoadSeconds, 2.6);
    expect(s.errors, {'TimeoutException': 2});
    expect(s.modelMissing, 1);
    expect(summariseModelLog([]).answers, 0);
  });

  Future<void> add({
    TransactionStatus status = TransactionStatus.confirmed,
    String? reason,
    String? category,
    bool corrected = false,
    String? merchant,
    String? note,
  }) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          amountPaise: 98765400,
          direction: Direction.debit,
          status: Value(status),
          confirmReason: Value(reason),
          categoryName: Value(category),
          userCorrected: Value(corrected),
          merchant: Value(merchant),
          note: Value(note),
          fingerprint: 'f${n++}',
          occurredAt: DateTime(2026, 11, 20),
          createdAt: DateTime(2026, 11, 20),
        ),
      );

  test('counts, rates and reasons come from the database', () async {
    await add(category: 'Food');
    await add(status: TransactionStatus.pleaseConfirm, reason: 'no_model');
    await add(status: TransactionStatus.pleaseConfirm, reason: 'no_model');
    await add(
      status: TransactionStatus.pleaseConfirm,
      reason: 'bad_reply',
      category: 'Food',
    );
    await add(category: 'Food', corrected: true);
    final r = await buildDiagnostics(db, dir, DateTime(2026, 11, 26));
    expect(r.transactions, 5);
    expect(r.pleaseConfirm, 3);
    expect(r.pleaseConfirmRate, closeTo(0.6, 1e-9));
    expect(r.confirmReasons, {'no_model': 2, 'bad_reply': 1});
    expect(r.uncategorised, 2);
    expect(r.corrected, 1);
    expect(r.schemaVersion, db.schemaVersion);
  });

  test('an empty app gives zero rates, not an error', () async {
    final r = await buildDiagnostics(db, dir, DateTime(2026, 11, 26));
    expect(r.pleaseConfirmRate, 0);
    expect(r.toText(), contains('Transactions: 0'));
  });

  test(
    'the shared report has no amounts, merchants, notes or message text',
    () async {
      await add(
        category: 'Food',
        merchant: 'ZZ-CANARY-MERCHANT',
        note: 'ZZ-CANARY-NOTE',
      );
      await db
          .into(db.rawMessages)
          .insert(
            RawMessagesCompanion.insert(
              sender: 'ZZ-CANARY-SENDER',
              body: 'ZZ-CANARY-BODY Rs 987654.00 debited',
              receivedAt: DateTime(2026, 11, 20),
              contentHash: 'h',
              createdAt: DateTime(2026, 11, 20),
            ),
          );
      File('${dir.path}/model_runs.log').writeAsStringSync(
        '2026-11-26T05:00:04Z generated seconds=3.0 chars=88\n'
        '2026-11-26T05:00:05Z generate_failed error=Oops 123456789012\n',
      );
      File('${dir.path}/crash.log').writeAsStringSync(
        '2026-11-26T05:00:06Z crash type=StateError at a.dart:1\n',
      );
      final text = (await buildDiagnostics(
        db,
        dir,
        DateTime(2026, 11, 26),
      )).toText();
      for (final secret in [
        'ZZ-CANARY',
        '987654',
        '98765400',
        '123456789012',
      ]) {
        expect(text, isNot(contains(secret)), reason: secret);
      }
      expect(text, contains('StateError'));
      expect(text, contains('Crashes recorded: 1'));
    },
  );
}
