import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/features/backup/backup_service.dart';
import 'package:paisa_vault/features/budgets/budget_repository.dart';
import 'package:paisa_vault/features/transactions/transaction_repository.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late FakeClock clock;
  var n = 0;

  AppDatabase open(String name) =>
      AppDatabase(openEncrypted(File('${dir.path}/$name'), randomKey()));

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_backup');
    db = open('a.db');
    clock = FakeClock(DateTime(2026, 11, 26, 12));
    n = 0;
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  // Few rounds: the real number is deliberately slow.
  BackupService svc(AppDatabase d) => BackupService(d, iterations: 1000);

  Future<void> fill() async {
    final repo = TransactionRepository(db, clock);
    final account = await repo.accountFor(
      'HDFC',
      '1234',
      AccountKind.creditCard,
    );
    final raw = await db
        .into(db.rawMessages)
        .insert(
          RawMessagesCompanion.insert(
            sender: 'HDFCBK',
            body: 'SECRET-MESSAGE-TEXT Rs 499 debited',
            receivedAt: DateTime(2026, 11, 20),
            contentHash: 'h',
            createdAt: DateTime(2026, 11, 20),
          ),
        );
    for (final rs in [499, 250, 80]) {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              rawMessageId: Value(rs == 499 ? raw : null),
              accountId: Value(account),
              amountPaise: rs * 100,
              direction: Direction.debit,
              merchant: Value('SHOP $rs'),
              categoryName: const Value('Food'),
              note: Value('note $rs'),
              fingerprint: 'f${n++}',
              occurredAt: DateTime(2026, 11, 20 + n),
              createdAt: DateTime(2026, 11, 20),
            ),
          );
    }
    await repo.saveRule('SHOP', 'Groceries');
    await BudgetRepository(db, clock).save('Food', 500000);
    await BudgetRepository(db, clock).newAlerts();
  }

  Future<Map<String, Object?>> everything(AppDatabase d) async => {
    'tx': (await d.select(d.transactions).get())
        .map((t) => t.toJson()..['rawMessageId'] = null)
        .toList(),
    'acc': (await d.select(d.accounts).get()).map((x) => x.toJson()).toList(),
    'bank': (await d.select(d.banks).get()).map((x) => x.toJson()).toList(),
    'cat': (await d.select(d.categories).get()).map((x) => x.toJson()).toList(),
    'rule': (await d.select(d.merchantRules).get())
        .map((x) => x.toJson())
        .toList(),
    'bud': (await d.select(d.budgets).get()).map((x) => x.toJson()).toList(),
    'log': (await d.select(d.budgetAlertLog).get())
        .map((x) => x.toJson())
        .toList(),
  };

  test('back up, restore on a clean install, and every row matches', () async {
    await fill();
    final file = await svc(db).create('correct horse');
    final before = await everything(db);

    final fresh = open(
      'b.db',
    ); // a new phone: empty apart from the starting categories
    addTearDown(fresh.close);
    final counts = await svc(fresh).restore(file, 'correct horse');
    expect(counts.transactions, 3);
    expect(counts.budgets, 1);
    expect(jsonEncode(await everything(fresh)), jsonEncode(before));
  });

  test('restoring replaces what was there', () async {
    await fill();
    final file = await svc(db).create('correct horse');
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountPaise: 1,
            direction: Direction.debit,
            fingerprint: 'extra',
            occurredAt: DateTime(2026, 11, 25),
            createdAt: DateTime(2026, 11, 25),
          ),
        );
    await svc(db).restore(file, 'correct horse');
    expect(await db.select(db.transactions).get(), hasLength(3));
  });

  test('the file does not contain message text or readable data', () async {
    await fill();
    final file = await svc(db).create('correct horse');
    final text = latin1.decode(file);
    expect(text, isNot(contains('SECRET-MESSAGE-TEXT')));
    expect(text, isNot(contains('SHOP 499')));
    expect(text, isNot(contains('HDFC')));
    // and restoring does not bring the message text back
    final fresh = open('c.db');
    addTearDown(fresh.close);
    await svc(fresh).restore(file, 'correct horse');
    expect(await fresh.select(fresh.rawMessages).get(), isEmpty);
    expect(
      (await fresh.select(fresh.transactions).get()).every(
        (t) => t.rawMessageId == null,
      ),
      isTrue,
    );
  });

  test('a wrong passphrase, a damaged file and a non-backup are refused, nothing changes', () async {
    await fill();
    final file = await svc(db).create('correct horse');
    final before = jsonEncode(await everything(db));

    Future<BackupProblem> problem(List<int> bytes, String pass) async {
      try {
        await svc(db).restore(Uint8List.fromList(bytes), pass);
      } on BackupException catch (e) {
        return e.problem;
      }
      fail('should have been refused');
    }

    expect(
      await problem(file, 'wrong passphrase'),
      BackupProblem.wrongPassphrase,
    );
    final damaged = file.toList()..[file.length ~/ 2] ^= 0xFF;
    expect(
      await problem(damaged, 'correct horse'),
      BackupProblem.wrongPassphrase,
    );
    expect(
      await problem(
        utf8.encode('hello, not a backup file at all, long enough'),
        'x',
      ),
      BackupProblem.notABackup,
    );
    expect(await problem([1, 2, 3], 'x'), BackupProblem.notABackup);
    expect(jsonEncode(await everything(db)), before);
  });

  test('two backups of the same data differ (fresh salt and nonce)', () async {
    await fill();
    final a = await svc(db).create('correct horse');
    final b = await svc(db).create('correct horse');
    expect(a, isNot(b));
  });

  test('inspect reports counts without changing anything', () async {
    await fill();
    final file = await svc(db).create('correct horse');
    final c = await svc(db).inspect(file, 'correct horse');
    expect((c.transactions, c.accounts, c.rules, c.budgets), (3, 1, 1, 1));
  });
}
