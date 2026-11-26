import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';

enum BackupProblem { wrongPassphrase, notABackup, tooNew }

class BackupException implements Exception {
  const BackupException(this.problem);
  final BackupProblem problem;
  @override
  String toString() => 'BackupException(${problem.name})';
}

/// How many rows of each kind a backup holds. Counts only.
class BackupCounts {
  const BackupCounts({
    required this.transactions,
    required this.accounts,
    required this.rules,
    required this.budgets,
  });
  final int transactions;
  final int accounts;
  final int rules;
  final int budgets;
}

/// An encrypted backup file with its own passphrase. The key comes from the passphrase alone
/// (PBKDF2), never from this phone's keys, so the file restores on a new phone.
///
/// The file holds transactions, accounts, categories, merchant rules and budgets. It does not
/// hold the original message text, and never anything hidden.
///
/// Layout: "PVBK" | format 1 byte | iterations 4 bytes | salt 16 | nonce 12 | cipher | mac 16.
class BackupService {
  BackupService(this._db, {this.iterations = defaultIterations});
  final AppDatabase _db;

  /// Slow on purpose, so guessing a passphrase is expensive. Tests pass a small number.
  final int iterations;
  static const defaultIterations = 600000;
  static const minPassphraseLength = 8;
  static const _magic = [0x50, 0x56, 0x42, 0x4B]; // PVBK
  static const _format = 1;
  static const _headerLength = 4 + 1 + 4 + 16 + 12;

  final _aes = AesGcm.with256bits();

  Future<SecretKey> _key(String passphrase, List<int> salt, int rounds) =>
      Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: rounds,
        bits: 256,
      ).deriveKeyFromPassword(password: passphrase, nonce: salt);

  Future<Map<String, Object?>> _snapshot() async {
    List<Map<String, Object?>> rows<T extends DataClass>(List<T> l) => [
      for (final r in l) r.toJson(),
    ];
    final transactions = (await _db.select(_db.transactions).get())
        // The message text is not in the backup, so the link to it is dropped.
        .map((t) => t.toJson()..['rawMessageId'] = null)
        .toList();
    return {
      'schema': _db.schemaVersion,
      'settings': rows(await _db.select(_db.settings).get()),
      'banks': rows(await _db.select(_db.banks).get()),
      'accounts': rows(await _db.select(_db.accounts).get()),
      'categories': rows(await _db.select(_db.categories).get()),
      'merchantRules': rows(await _db.select(_db.merchantRules).get()),
      'budgets': rows(await _db.select(_db.budgets).get()),
      'budgetAlertLog': rows(await _db.select(_db.budgetAlertLog).get()),
      'transactions': transactions,
    };
  }

  /// Builds the encrypted file bytes.
  Future<Uint8List> create(String passphrase) async {
    final random = Random.secure();
    List<int> bytes(int n) => List.generate(n, (_) => random.nextInt(256));
    final salt = bytes(16);
    final nonce = bytes(12);
    final plain = GZipCodec().encode(
      utf8.encode(jsonEncode(await _snapshot())),
    );
    final box = await _aes.encrypt(
      plain,
      secretKey: await _key(passphrase, salt, iterations),
      nonce: nonce,
      aad: _magic,
    );
    final header = BytesBuilder()
      ..add(_magic)
      ..addByte(_format)
      ..add((ByteData(4)..setUint32(0, iterations)).buffer.asUint8List())
      ..add(salt)
      ..add(nonce);
    return (header
          ..add(box.cipherText)
          ..add(box.mac.bytes))
        .toBytes();
  }

  static bool _hasMagic(Uint8List f) {
    for (var i = 0; i < _magic.length; i++) {
      if (f[i] != _magic[i]) return false;
    }
    return true;
  }

  Future<Map<String, Object?>> _open(Uint8List file, String passphrase) async {
    if (file.length < _headerLength + 16 || !_hasMagic(file)) {
      throw const BackupException(BackupProblem.notABackup);
    }
    if (file[4] > _format) throw const BackupException(BackupProblem.tooNew);
    final rounds = ByteData.sublistView(file, 5, 9).getUint32(0);
    final salt = file.sublist(9, 25);
    final nonce = file.sublist(25, 37);
    final cipher = file.sublist(37, file.length - 16);
    final mac = Mac(file.sublist(file.length - 16));
    final List<int> plain;
    try {
      plain = await _aes.decrypt(
        SecretBox(cipher, nonce: nonce, mac: mac),
        secretKey: await _key(passphrase, salt, rounds),
        aad: _magic,
      );
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupProblem.wrongPassphrase);
    }
    try {
      return jsonDecode(utf8.decode(GZipCodec().decode(plain)))
          as Map<String, Object?>;
    } catch (_) {
      throw const BackupException(BackupProblem.notABackup);
    }
  }

  /// Checks the file and passphrase and says what is inside, without changing anything.
  Future<BackupCounts> inspect(Uint8List file, String passphrase) async {
    final data = await _open(file, passphrase);
    int n(String k) => (data[k] as List?)?.length ?? 0;
    return BackupCounts(
      transactions: n('transactions'),
      accounts: n('accounts'),
      rules: n('merchantRules'),
      budgets: n('budgets'),
    );
  }

  /// Replaces everything in the app with the backup, all or nothing. Message text is not
  /// restored, so transactions come back without their original message.
  Future<BackupCounts> restore(Uint8List file, String passphrase) async {
    final data = await _open(file, passphrase);
    if (((data['schema'] as int?) ?? 0) > _db.schemaVersion) {
      throw const BackupException(BackupProblem.tooNew);
    }
    List<Map<String, Object?>> list(String k) =>
        ((data[k] as List?) ?? const []).cast<Map<String, Object?>>();
    await _db.transaction(() async {
      // Children first, so nothing points at a missing parent while deleting.
      await _db.delete(_db.budgetAlertLog).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.rawMessages).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.banks).go();
      await _db.delete(_db.merchantRules).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.settings).go();
      Future<void> put<T extends Table, D>(
        TableInfo<T, D> table,
        String key,
        Insertable<D> Function(Map<String, Object?>) read,
      ) async {
        for (final r in list(key)) {
          await _db.into(table).insert(read(r));
        }
      }

      await put(_db.settings, 'settings', Setting.fromJson);
      await put(_db.categories, 'categories', Category.fromJson);
      await put(_db.banks, 'banks', Bank.fromJson);
      await put(_db.accounts, 'accounts', Account.fromJson);
      await put(_db.merchantRules, 'merchantRules', MerchantRule.fromJson);
      await put(_db.budgets, 'budgets', Budget.fromJson);
      await put(
        _db.budgetAlertLog,
        'budgetAlertLog',
        BudgetAlertLogData.fromJson,
      );
      await put(_db.transactions, 'transactions', Transaction.fromJson);
    });
    return BackupCounts(
      transactions: list('transactions').length,
      accounts: list('accounts').length,
      rules: list('merchantRules').length,
      budgets: list('budgets').length,
    );
  }
}
