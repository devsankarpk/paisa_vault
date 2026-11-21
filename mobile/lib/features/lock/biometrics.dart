import 'package:local_auth/local_auth.dart';

/// Which biometric the phone offers, used to pick the unlock icon.
enum BiometricKind { face, fingerprint }

/// Fingerprint / Face ID behind an interface so tests can fake it.
abstract class Biometrics {
  Future<bool> get isAvailable;

  /// Face when the phone has face recognition, otherwise fingerprint.
  Future<BiometricKind> get kind;

  /// True only when the user passed the biometric check.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  @override
  Future<bool> get isAvailable async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricKind> get kind async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricKind.face;
    } catch (_) {}
    return BiometricKind.fingerprint;
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

class FakeBiometrics implements Biometrics {
  FakeBiometrics({
    this.available = true,
    this.passes = true,
    this.biometricKind = BiometricKind.fingerprint,
  });
  bool available;
  BiometricKind biometricKind;

  @override
  Future<BiometricKind> get kind async => biometricKind;
  bool passes;
  int prompts = 0;

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return passes;
  }
}
