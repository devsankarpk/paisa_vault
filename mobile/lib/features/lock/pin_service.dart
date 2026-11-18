import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../core/clock.dart';
import '../../core/secret_store.dart';

/// Length of the PIN. The signed-off design uses 4 digits; change here to move to 6.
const pinLength = 4;

sealed class PinCheck {
  const PinCheck();
}

class PinOk extends PinCheck {
  const PinOk();
}

class PinWrong extends PinCheck {
  const PinWrong(this.triesBeforeLock);

  /// How many more wrong tries before the next lockout (0 means this try started one).
  final int triesBeforeLock;
}

class PinLocked extends PinCheck {
  const PinLocked(this.remaining);
  final Duration remaining;
}

/// Stores the PIN as a salted, slow hash and slows down guessing. With only 4 digits, the
/// attempt limit is what protects the PIN.
class PinService {
  PinService(this._store, this._clock, {this.iterations = 60000});

  final SecretStore _store;
  final Clock _clock;
  final int iterations;

  static const _hashKey = 'pv_pin_hash';
  static const _saltKey = 'pv_pin_salt';
  static const _failsKey = 'pv_pin_fails';
  static const _lockUntilKey = 'pv_pin_lock_until';

  /// Wrong tries allowed before the first lockout.
  static const freeTries = 4;

  /// Lockout after the 5th, 6th, 7th, 8th and later wrong tries.
  static const lockouts = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];

  Future<bool> get hasPin async => await _store.read(_hashKey) != null;

  Future<List<int>> _hash(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final key = await pbkdf2.deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }

  Future<void> setPin(String pin) async {
    _check(pin);
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    await _store.write(_saltKey, base64Encode(salt));
    await _store.write(_hashKey, base64Encode(await _hash(pin, salt)));
    await _store.delete(_failsKey);
    await _store.delete(_lockUntilKey);
  }

  void _check(String pin) {
    if (!RegExp('^\\d{$pinLength}\$').hasMatch(pin)) {
      throw ArgumentError('PIN must be $pinLength digits');
    }
  }

  /// Time left on a lockout, or null when guessing is allowed.
  Future<Duration?> lockedFor() async {
    final until = int.tryParse(await _store.read(_lockUntilKey) ?? '');
    if (until == null) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until)
        .difference(_clock.now());
    return left > Duration.zero ? left : null;
  }

  Future<PinCheck> verify(String pin) async {
    final locked = await lockedFor();
    if (locked != null) return PinLocked(locked);

    final hash = await _store.read(_hashKey);
    final salt = await _store.read(_saltKey);
    if (hash == null || salt == null) throw StateError('No PIN set');
    final attempt = await _hash(pin, base64Decode(salt));
    if (_equal(attempt, base64Decode(hash))) {
      await _store.delete(_failsKey);
      await _store.delete(_lockUntilKey);
      return const PinOk();
    }

    final fails = (int.tryParse(await _store.read(_failsKey) ?? '') ?? 0) + 1;
    await _store.write(_failsKey, '$fails');
    if (fails > freeTries) {
      final wait = lockouts[min(fails - freeTries - 1, lockouts.length - 1)];
      await _store.write(
        _lockUntilKey,
        '${_clock.now().add(wait).millisecondsSinceEpoch}',
      );
      return PinLocked(wait);
    }
    return PinWrong(freeTries - fails);
  }

  /// Removes the PIN (used by "Erase everything").
  Future<void> clear() async {
    for (final k in [_hashKey, _saltKey, _failsKey, _lockUntilKey]) {
      await _store.delete(k);
    }
  }

  bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
