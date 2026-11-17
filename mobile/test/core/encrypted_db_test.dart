import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_db');
    file = File('${dir.path}/main.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('data written with a key can be read back with the same key', () async {
    final key = randomKey();
    final db = AppDatabase(openEncrypted(file, key));
    await db
        .into(db.settings)
        .insert(SettingsCompanion.insert(key: 'a', value: 'b'));
    await db.close();

    final again = AppDatabase(openEncrypted(file, key));
    expect((await again.select(again.settings).get()).single.value, 'b');
    await again.close();
  });

  test('the file is not plain SQLite and holds no readable text', () async {
    final db = AppDatabase(openEncrypted(file, randomKey()));
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(key: 'secretword', value: 'secretvalue'),
        );
    await db.close();

    final bytes = file.readAsBytesSync();
    expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
    expect(String.fromCharCodes(bytes), isNot(contains('secretvalue')));
  });

  test('wrong key fails', () async {
    final db = AppDatabase(openEncrypted(file, randomKey()));
    await db
        .into(db.settings)
        .insert(SettingsCompanion.insert(key: 'a', value: 'b'));
    await db.close();

    expect(() async {
      final bad = AppDatabase(openEncrypted(file, randomKey()));
      await bad.select(bad.settings).get();
    }(), throwsA(anything));
  });

  test('key store makes a stable 256-bit key per name', () async {
    final store = MemoryKeyStore();
    final a = await store.keyFor('main');
    expect(a.length, 32);
    expect(await store.keyFor('main'), a);
    expect(await store.keyFor('vault'), isNot(a));
    await store.delete('main');
    expect(await store.keyFor('main'), isNot(a));
  });
}
