import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'encrypted_executor.dart';
import 'key_store.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Settings,
    Banks,
    Accounts,
    RawMessages,
    Transactions,
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
  int get schemaVersion => 2;

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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
