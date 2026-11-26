import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'encrypted_executor.dart';
import 'key_store.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// The starting category list (decision D4). Added once, when the table is empty.
const seedExpenseCategories = [
  'Food',
  'Groceries',
  'Shopping',
  'Bills',
  'Travel',
  'Health',
  'Entertainment',
  'Other',
];

Future<void> seedCategories(AppDatabase db) async {
  if ((await db.select(db.categories).get()).isNotEmpty) return;
  final now = DateTime.now();
  var order = 0;
  Future<void> add(String name, CategoryKind kind) => db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          name: name,
          kind: kind,
          sortOrder: Value(order++),
          createdAt: now,
        ),
      );
  for (final c in seedExpenseCategories) {
    await add(c, CategoryKind.expense);
  }
  await add('Income', CategoryKind.income);
  await add('Transfer', CategoryKind.transfer);
}

@DriftDatabase(
  tables: [
    Settings,
    Banks,
    Accounts,
    RawMessages,
    Transactions,
    MerchantRules,
    Categories,
    Budgets,
    BudgetAlertLog,
    PipelineLog,
    HiddenHash,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens main.db in the app's private folder with a key from [keyStore].
  static Future<AppDatabase> open(KeyStore keyStore) async {
    final dir = await getApplicationSupportDirectory();
    final key = await keyStore.keyFor('main');
    return AppDatabase(openEncrypted(File(p.join(dir.path, 'main.db')), key));
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.bankCode);
        await m.addColumn(transactions, transactions.last4);
        await m.addColumn(transactions, transactions.accountKind);
        await m.addColumn(transactions, transactions.categoryName);
        await m.addColumn(transactions, transactions.confirmReason);
        await m.addColumn(transactions, transactions.userCorrected);
      }
      if (from < 3) {
        await m.createTable(merchantRules);
      }
      if (from < 4) {
        await m.createTable(budgets);
        await m.createTable(budgetAlertLog);
        await m.createIndex(budgetAlertOnce);
      }
      if (from < 5) {
        await m.createTable(categories);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await seedCategories(this);
    },
  );
}
