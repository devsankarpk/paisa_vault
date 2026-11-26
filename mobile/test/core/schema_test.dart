import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;
  late List<int> key;
  late AppDatabase db;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_schema');
    file = File('${dir.path}/main.db');
    key = randomKey();
    db = AppDatabase(openEncrypted(file, key));
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<Set<String>> names(String type) async {
    final rows = await db
        .customSelect(
          "select name from sqlite_master where type = '$type' and name not like 'sqlite_%'",
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  test('schema creates the planned tables', () async {
    expect(db.schemaVersion, 4);
    expect(
      await names('table'),
      containsAll([
        'settings',
        'banks',
        'accounts',
        'raw_messages',
        'transactions',
        'merchant_rules',
        'budgets',
        'budget_alert_log',
        'pipeline_log',
        'hidden_hash',
      ]),
    );
  });

  test('indexes for date, amount+date, category+date exist', () async {
    expect(
      await names('index'),
      containsAll([
        'txn_date',
        'txn_amount_date',
        'txn_category_date',
        'txn_fingerprint',
        'raw_messages_hash',
      ]),
    );
  });

  test('migration from an older file keeps data (reopen)', () async {
    await db
        .into(db.banks)
        .insert(BanksCompanion.insert(code: 'HDFC', name: 'HDFC Bank'));
    await db.close();
    db = AppDatabase(openEncrypted(file, key));
    expect((await db.select(db.banks).get()).single.code, 'HDFC');
    final v = await db.customSelect('pragma user_version').getSingle();
    expect(v.read<int>('user_version'), 4);
  });

  test('transaction stores paise and currency, with safe defaults', () async {
    final bankId = await db
        .into(db.banks)
        .insert(BanksCompanion.insert(code: 'HDFC', name: 'HDFC Bank'));
    final accId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            bankId: Value(bankId),
            kind: AccountKind.debitCard,
            last4: '1234',
            createdAt: DateTime(2026, 11, 20),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountPaise: 49900,
            direction: Direction.debit,
            fingerprint: 'f1',
            occurredAt: DateTime(2026, 11, 20),
            createdAt: DateTime(2026, 11, 20),
            accountId: Value(accId),
          ),
        );
    final t = await db.select(db.transactions).getSingle();
    expect(t.amountPaise, 49900);
    expect(t.currency, 'INR');
    expect(t.status, TransactionStatus.confirmed);
    expect(t.shared, false);
    expect(t.selfTransfer, false);
  });

  test('foreign keys are enforced', () async {
    await expectLater(
      db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              bankId: const Value(999),
              kind: AccountKind.savings,
              last4: '1234',
              createdAt: DateTime(2026),
            ),
          ),
      throwsA(anything),
    );
  });

  test('one account per bank, kind and last 4', () async {
    final bankId = await db
        .into(db.banks)
        .insert(BanksCompanion.insert(code: 'SBI', name: 'SBI'));
    Future<int> add() => db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            bankId: Value(bankId),
            kind: AccountKind.savings,
            last4: '9999',
            createdAt: DateTime(2026),
          ),
        );
    await add();
    await expectLater(add(), throwsA(anything));
  });
}
