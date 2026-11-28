import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../core/secret_store.dart';

/// Looks after the key that opens vault.db. The key is random and is never stored as it is:
///  * wrapped under a key made from the PIN (PBKDF2 + AES-256-GCM), so the PIN opens it;
///  * optionally, a second copy for Face ID / fingerprint, which the caller may read only
///    after a successful biometric check. That copy sits in the Keystore / Keychain, so it is
///    guarded by the app's biometric gate, not by a hardware-bound key (see ADR 0003).
class VaultKeyService {
  VaultKeyService(this._store, {this.iterations = 200000});
  final SecretStore _store;

  /// Slow on purpose. Tests pass a small number.
  final int iterations;

  static const pinWrapKey = 'pv_vault_pin_wrap';
  static const bioCopyKey = 'pv_vault_bio_key';
  static const secretKeys = [pinWrapKey, bioCopyKey];

  static final _gcm = AesGcm.with256bits();

  Future<bool> get exists async => await _store.read(pinWrapKey) != null;
  Future<bool> get hasBiometricCopy async =>
      await _store.read(bioCopyKey) != null;

  /// Makes a new random vault key and wraps it under [pin]. Returns the key.
  Future<List<int>> create(String pin, {required bool biometricCopy}) async {
    final r = Random.secure();
    final key = List<int>.generate(32, (_) => r.nextInt(256));
    final salt = List<int>.generate(16, (_) => r.nextInt(256));
    final kek = await _kek(pin, salt, iterations);
    final box = await _gcm.encrypt(key, secretKey: kek);
    final out = <int>[
      ...salt,
      ...(ByteData(4)..setUint32(0, iterations)).buffer.asUint8List(),
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ];
    await _store.write(pinWrapKey, base64Encode(out));
    if (biometricCopy) await _store.write(bioCopyKey, base64Encode(key));
    return key;
  }

  /// The key, or null when [pin] is wrong or there is no vault yet. The PIN's own lockout is
  /// enforced by PinService before this is called.
  Future<List<int>?> unwrapWithPin(String pin) async {
    final stored = await _store.read(pinWrapKey);
    if (stored == null) return null;
    final raw = base64Decode(stored);
    if (raw.length != 16 + 4 + 12 + 32 + 16) return null;
    final salt = raw.sublist(0, 16);
    final rounds = ByteData.sublistView(Uint8List.fromList(raw.sublist(16, 20)))
        .getUint32(0);
    final nonce = raw.sublist(20, 32);
    final cipher = raw.sublist(32, 64);
    final mac = Mac(raw.sublist(64, 80));
    try {
      final kek = await _kek(pin, salt, rounds);
      return await _gcm.decrypt(
        SecretBox(cipher, nonce: nonce, mac: mac),
        secretKey: kek,
      );
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  /// The biometric copy. Call only after the biometric check passed.
  Future<List<int>?> readBiometricCopy() async {
    final v = await _store.read(bioCopyKey);
    return v == null ? null : base64Decode(v);
  }

  Future<void> storeBiometricCopy(List<int> key) =>
      _store.write(bioCopyKey, base64Encode(key));

  Future<void> removeBiometricCopy() => _store.delete(bioCopyKey);

  /// Forgets the vault key (used by "Erase everything"). vault.db becomes unreadable.
  Future<void> forget() async {
    for (final k in secretKeys) {
      await _store.delete(k);
    }
  }

  Future<SecretKey> _kek(String pin, List<int> salt, int rounds) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: rounds,
    bits: 256,
  ).deriveKeyFromPassword(password: pin, nonce: salt);
}
