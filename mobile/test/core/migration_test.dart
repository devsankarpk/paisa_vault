import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;
import '../generated_migrations/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 to v2 gives exactly the v2 schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('v2 to v3 adds the merchant rules table', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });

  test('v1 data survives the upgrade and new columns have safe defaults', () async {
    final schema = await verifier.schemaAt(1);
    // A v1 database holding one raw message and one transaction.
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old.customStatement(
      'INSERT INTO raw_messages (sender, body, received_at, content_hash, status, created_at) '
      "VALUES ('X', 'Rs 5 debited', 1795000000, 'h', 'newMessage', 1795000000)",
    );
    await old.customStatement(
      'INSERT INTO transactions (amount_paise, currency, direction, status, fingerprint, '
      'occurred_at, shared, self_transfer, created_at) '
      "VALUES (500, 'INR', 'debit', 'confirmed', 'f', 1795000000, 0, 0, 1795000000)",
    );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    final t = await db.select(db.transactions).getSingle();
    expect(t.amountPaise, 500);
    expect(t.bankCode, isNull);
    expect(t.last4, isNull);
    expect(t.userCorrected, false);
    expect((await db.select(db.rawMessages).get()).length, 1);
    await db.close();
  });

  test('a fresh install is at v3 too', () async {
    final db = v3.DatabaseAtV3((await verifier.schemaAt(3)).newConnection());
    expect(db.schemaVersion, 3);
    await db.close();
  });
}
