import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseKeyException implements Exception {
  const DatabaseKeyException(this.message);
  final String message;
  @override
  String toString() => 'DatabaseKeyException: $message';
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Opens [file] encrypted with [key] (SQLCipher-compatible settings).
/// Throws [DatabaseKeyException] when the key is wrong or encryption is not available.
NativeDatabase openEncrypted(File file, List<int> key) {
  return NativeDatabase(file, setup: (db) => applyKey(db, key));
}

/// Applies [key] to an open connection and checks it works.
void applyKey(Database db, List<int> key) {
  // Without the SQLite3 Multiple Ciphers build, PRAGMA key is silently ignored and the
  // file would be stored in plain text. Refuse to continue in that case.
  // `pragma cipher` only exists in the SQLite3 Multiple Ciphers build and, unlike a
  // normal query, does not need the key yet.
  if (db.select('pragma cipher').isEmpty) {
    throw const DatabaseKeyException(
      'Encryption is not available in this SQLite build',
    );
  }
  db.execute("pragma cipher = 'sqlcipher'");
  db.execute('pragma legacy = 4');
  db.execute('pragma key = "x\'${_hex(key)}\'"');
  try {
    db.select('select count(*) from sqlite_master');
  } on SqliteException {
    throw const DatabaseKeyException('Wrong key or database is not encrypted');
  }
}
