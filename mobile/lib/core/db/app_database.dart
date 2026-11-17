import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'encrypted_executor.dart';
import 'key_store.dart';

part 'app_database.g.dart';

/// Key-value app settings. More tables arrive with schema v1.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens main.db in the app's private folder with a key from [keyStore].
  static Future<AppDatabase> open(KeyStore keyStore) async {
    final dir = await getApplicationSupportDirectory();
    final key = await keyStore.keyFor('main');
    return AppDatabase(openEncrypted(File(p.join(dir.path, 'main.db')), key));
  }

  @override
  int get schemaVersion => 1;
}
