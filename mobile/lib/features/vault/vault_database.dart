import 'dart:io';

import 'package:drift/drift.dart';

import '../../core/db/encrypted_executor.dart';
import '../../core/db/tables.dart' show Direction;

part 'vault_database.g.dart';

/// Transactions the owner hid. A copy of the fields a transaction has, kept only here.
class HiddenTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountPaise => integer()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get direction => textEnum<Direction>()();
  TextColumn get channel => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get bankCode => text().nullable()();
  TextColumn get last4 => text().nullable()();
  TextColumn get accountKind => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get fingerprint => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

/// The authoritative list of fingerprints of hidden transactions, so a re-sent SMS stays hidden.
/// main.db keeps only keyed hashes of these.
class HiddenFingerprints extends Table {
  TextColumn get fingerprint => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {fingerprint};
}

/// Card number and optional PIN, each encrypted on its own before it is stored. [id] is what
/// cards.secretRef in main.db points to. There is no CVV column and there never will be.
class CardSecrets extends Table {
  TextColumn get id => text()();
  TextColumn get numberCipher => text().nullable()();
  TextColumn get pinCipher => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row each time the vault is opened. Method is "pin" or "biometric".
@DataClassName('VaultAuditEntry')
class VaultAudit extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get openedAt => dateTime()();
  TextColumn get method => text()();
}

@DriftDatabase(
  tables: [HiddenTransactions, HiddenFingerprints, CardSecrets, VaultAudit],
)
class VaultDatabase extends _$VaultDatabase {
  VaultDatabase(super.executor);

  /// Opens vault.db at [file], encrypted with [key]. A wrong key throws DatabaseKeyException.
  static VaultDatabase open(File file, List<int> key) =>
      VaultDatabase(openEncrypted(file, key));

  @override
  int get schemaVersion => 1;
}
