import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/clock.dart';
import 'vault_database.dart';
import 'vault_session.dart';

/// Why a card number was not accepted.
enum NumberProblem { badLength, notDigits, failsCheck }

/// Digits only, 12 to 19 long, and passing the Luhn check every real card number passes.
NumberProblem? checkCardNumber(String raw) {
  final n = raw.replaceAll(RegExp(r'[\s-]'), '');
  if (!RegExp(r'^\d+$').hasMatch(n)) return NumberProblem.notDigits;
  if (n.length < 12 || n.length > 19) return NumberProblem.badLength;
  var sum = 0;
  for (var i = 0; i < n.length; i++) {
    var d = int.parse(n[n.length - 1 - i]);
    if (i.isOdd) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 == 0 ? null : NumberProblem.failsCheck;
}

/// Full card numbers, encrypted field by field (AES-256-GCM) inside vault.db, on top of the
/// database's own encryption. Works only while the vault is open. No CVV, ever.
class CardSecretStore {
  CardSecretStore(this._session, this._clock);
  final VaultSession _session;
  final Clock _clock;

  static final _gcm = AesGcm.with256bits();

  /// A separate key for card fields, derived from the vault key.
  Future<SecretKey> _fieldKey() =>
      Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
        secretKey: SecretKey(_session.key),
        nonce: const <int>[],
        info: utf8.encode('paisa-vault card field v1'),
      );

  /// Ties each ciphertext to its card so rows cannot be swapped.
  List<int> _aad(String id, String field) => utf8.encode('$id|$field');

  Future<String> _seal(String id, String field, String value) async {
    final box = await _gcm.encrypt(
      utf8.encode(value),
      secretKey: await _fieldKey(),
      aad: _aad(id, field),
    );
    return base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  Future<String?> _open(String id, String field, String? stored) async {
    if (stored == null) return null;
    final raw = base64Decode(stored);
    if (raw.length < 12 + 16) return null;
    try {
      final clear = await _gcm.decrypt(
        SecretBox(
          raw.sublist(12, raw.length - 16),
          nonce: raw.sublist(0, 12),
          mac: Mac(raw.sublist(raw.length - 16)),
        ),
        secretKey: await _fieldKey(),
        aad: _aad(id, field),
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  /// Saves the number for [cardId]. Returns the problem when it is not a valid number.
  Future<NumberProblem?> saveNumber(int cardId, String raw) async {
    final problem = checkCardNumber(raw);
    if (problem != null) return problem;
    final id = '$cardId';
    final cipher = await _seal(
      id,
      'number',
      raw.replaceAll(RegExp(r'[\s-]'), ''),
    );
    final db = _session.db;
    await db
        .into(db.cardSecrets)
        .insertOnConflictUpdate(
          CardSecretsCompanion(
            id: Value(id),
            numberCipher: Value(cipher),
            createdAt: Value(_clock.now()),
          ),
        );
    return null;
  }

  /// The saved number, or null when none is saved.
  Future<String?> readNumber(int cardId) async {
    final db = _session.db;
    final row = await (db.select(
      db.cardSecrets,
    )..where((t) => t.id.equals('$cardId'))).getSingleOrNull();
    return _open('$cardId', 'number', row?.numberCipher);
  }

  /// A card PIN is 4 to 6 digits.
  static bool validPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

  /// Saves the optional card PIN. False when it is not 4 to 6 digits. Keeps any saved number.
  Future<bool> savePin(int cardId, String pin) async {
    if (!validPin(pin)) return false;
    final id = '$cardId';
    final cipher = await _seal(id, 'pin', pin);
    final db = _session.db;
    final exists = await (db.select(
      db.cardSecrets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (exists == null) {
      await db
          .into(db.cardSecrets)
          .insert(
            CardSecretsCompanion.insert(
              id: id,
              createdAt: _clock.now(),
              pinCipher: Value(cipher),
            ),
          );
    } else {
      await (db.update(db.cardSecrets)..where((t) => t.id.equals(id))).write(
        CardSecretsCompanion(pinCipher: Value(cipher)),
      );
    }
    return true;
  }

  Future<String?> readPin(int cardId) async {
    final db = _session.db;
    final row = await (db.select(
      db.cardSecrets,
    )..where((t) => t.id.equals('$cardId'))).getSingleOrNull();
    return _open('$cardId', 'pin', row?.pinCipher);
  }

  Future<void> deletePin(int cardId) async {
    final db = _session.db;
    await (db.update(db.cardSecrets)..where((t) => t.id.equals('$cardId')))
        .write(const CardSecretsCompanion(pinCipher: Value(null)));
  }

  Future<void> delete(int cardId) async {
    final db = _session.db;
    await (db.delete(
      db.cardSecrets,
    )..where((t) => t.id.equals('$cardId'))).go();
  }
}
