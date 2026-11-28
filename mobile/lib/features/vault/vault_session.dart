import 'dart:io';

import '../../core/clock.dart';
import '../lock/biometrics.dart';
import '../lock/pin_service.dart';
import 'vault_database.dart';
import 'vault_key_service.dart';

/// Opens vault.db only after the owner proves who they are, and closes it again on lock.
/// While the vault is closed the key is not held anywhere in memory.
class VaultSession {
  VaultSession({
    required this.file,
    required this.keys,
    required this.pin,
    required this.biometrics,
    required this.clock,
  });

  final File file;
  final VaultKeyService keys;
  final PinService pin;
  final Biometrics biometrics;
  final Clock clock;

  VaultDatabase? _db;
  bool get isOpen => _db != null;

  /// The open vault. Throws StateError when it is locked, so no code can reach it by accident.
  VaultDatabase get db => _db ?? (throw StateError('The vault is locked'));

  /// Opens with the PIN. The PIN's attempt limit applies. The first successful call creates
  /// the vault key; [offerBiometrics] says whether to keep a Face ID / fingerprint copy too.
  Future<PinCheck> openWithPin(
    String code, {
    bool offerBiometrics = false,
  }) async {
    final check = await pin.verify(code);
    if (check is! PinOk) return check;
    List<int>? key;
    if (await keys.exists) {
      key = await keys.unwrapWithPin(code);
    } else {
      key = await keys.create(code, biometricCopy: offerBiometrics);
    }
    if (key == null) return const PinWrong(0);
    if (offerBiometrics && !await keys.hasBiometricCopy) {
      await keys.storeBiometricCopy(key);
    }
    await _open(key, 'pin');
    return const PinOk();
  }

  /// Opens with Face ID / fingerprint. False when there is no biometric copy, the check fails,
  /// or the phone offers none.
  Future<bool> openWithBiometrics() async {
    if (!await keys.hasBiometricCopy) return false;
    if (!await biometrics.isAvailable) return false;
    if (!await biometrics.authenticate('Open the private vault')) return false;
    final key = await keys.readBiometricCopy();
    if (key == null) return false;
    await _open(key, 'biometric');
    return true;
  }

  Future<void> _open(List<int> key, String method) async {
    await lock();
    final db = VaultDatabase.open(file, key);
    try {
      await db
          .into(db.vaultAudit)
          .insert(
            VaultAuditCompanion.insert(openedAt: clock.now(), method: method),
          );
    } catch (_) {
      await db.close();
      rethrow;
    }
    _db = db;
  }

  /// Closes the vault. Safe to call when it is already closed.
  Future<void> lock() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
