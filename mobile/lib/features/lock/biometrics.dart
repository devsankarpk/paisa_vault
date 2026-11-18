import 'package:local_auth/local_auth.dart';

/// Fingerprint / Face ID behind an interface so tests can fake it.
abstract class Biometrics {
  Future<bool> get isAvailable;

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
  FakeBiometrics({this.available = true, this.passes = true});
  bool available;
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
