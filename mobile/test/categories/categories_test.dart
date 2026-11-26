import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/features/budgets/budget_repository.dart';
import 'package:paisa_vault/features/categories/category_repository.dart';
import 'package:paisa_vault/features/transactions/transaction_repository.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late FakeClock clock;
  late CategoryRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_cat');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    clock = FakeClock(DateTime(2026, 11, 26, 12));
    repo = CategoryRepository(db, clock);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<List<String>> visible() => repo.watchVisibleNames().first;

  test(
    'a new database starts with the default list, Income and Transfer last',
    () async {
      expect(await visible(), [...seedExpenseCategories, 'Income', 'Transfer']);
    },
  );

  test('add: new names go before Income and Transfer; empty and repeats are refused', () async {
    expect(await repo.add('  Rent '), CategoryResult.ok);
    expect(await repo.add('rent'), CategoryResult.exists); // ignores case
    expect(await repo.add('  '), CategoryResult.empty);
    final names = await visible();
    expect(names.indexOf('Rent'), seedExpenseCategories.length);
    expect(names.sublist(names.length - 2), ['Income', 'Transfer']);
    expect(names.where((n) => n == 'Rent'), hasLength(1));
  });

  test('rename updates transactions, rules and budgets', () async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountPaise: 1000,
            direction: Direction.debit,
            categoryName: const Value('Food'),
            fingerprint: 'a',
            occurredAt: DateTime(2026, 11, 5),
            createdAt: DateTime(2026, 11, 5),
          ),
        );
    await TransactionRepository(db, clock).saveRule('SWIGGY', 'Food');
    await BudgetRepository(db, clock).save('Food', 500000);

    expect(await repo.rename('Food', 'Eating out'), CategoryResult.ok);
    expect(
      (await db.select(db.transactions).getSingle()).categoryName,
      'Eating out',
    );
    expect(
      (await db.select(db.merchantRules).getSingle()).categoryName,
      'Eating out',
    );
    expect(
      (await db.select(db.budgets).getSingle()).categoryName,
      'Eating out',
    );
    expect(await visible(), contains('Eating out'));
    expect(await visible(), isNot(contains('Food')));
  });

  test(
    'rename cannot take another category\'s name, and Income is fixed',
    () async {
      expect(await repo.rename('Food', 'Bills'), CategoryResult.exists);
      expect(await repo.rename('Income', 'Salary'), CategoryResult.fixed);
      expect(await repo.setHidden('Transfer', true), CategoryResult.fixed);
      expect(await repo.rename('Nope', 'X'), CategoryResult.notFound);
    },
  );

  test(
    'hiding keeps old transactions but stops offering the category',
    () async {
      expect(await repo.setHidden('Travel', true), CategoryResult.ok);
      expect(await visible(), isNot(contains('Travel')));
      final all = await repo.watchAll().first;
      expect(all.firstWhere((c) => c.name == 'Travel').hidden, isTrue);
      await repo.setHidden('Travel', false);
      expect(await visible(), contains('Travel'));
    },
  );
}
