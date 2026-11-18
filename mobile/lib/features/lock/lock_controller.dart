import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/secret_store.dart';
import 'biometrics.dart';
import 'pin_service.dart';

enum LockStatus { loading, needsSetup, locked, unlocked }

class LockState {
  const LockState({
    this.status = LockStatus.loading,
    this.biometricEnabled = false,
    this.autoLock = const Duration(minutes: 1),
  });

  final LockStatus status;
  final bool biometricEnabled;
  final Duration autoLock;

  LockState copyWith({
    LockStatus? status,
    bool? biometricEnabled,
    Duration? autoLock,
  }) => LockState(
    status: status ?? this.status,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    autoLock: autoLock ?? this.autoLock,
  );
}

final secretStoreProvider = Provider<SecretStore>(
  (_) => throw UnimplementedError(),
);
final biometricsProvider = Provider<Biometrics>(
  (_) => throw UnimplementedError(),
);
final pinServiceProvider = Provider<PinService>(
  (ref) => PinService(ref.watch(secretStoreProvider), ref.watch(clockProvider)),
);

final lockControllerProvider = NotifierProvider<LockController, LockState>(
  LockController.new,
);

class LockController extends Notifier<LockState> {
  static const _bioKey = 'pv_bio_enabled';
  static const _autoLockKey = 'pv_autolock_secs';

  Timer? _idle;
  DateTime? _backgroundedAt;

  SecretStore get _store => ref.read(secretStoreProvider);
  PinService get _pin => ref.read(pinServiceProvider);

  @override
  LockState build() {
    ref.onDispose(() => _idle?.cancel());
    return const LockState();
  }

  /// Reads saved settings and decides whether to ask for setup or the PIN.
  Future<void> load() async {
    final bio = await _store.read(_bioKey) == 'true';
    final secs = int.tryParse(await _store.read(_autoLockKey) ?? '');
    final hasPin = await _pin.hasPin;
    state = LockState(
      status: hasPin ? LockStatus.locked : LockStatus.needsSetup,
      biometricEnabled: bio && hasPin,
      autoLock: secs == null
          ? const Duration(minutes: 1)
          : Duration(seconds: secs),
    );
  }

  /// First-time setup. Biometrics are only turned on if the user asked for them.
  Future<void> createPin(String pin, {required bool enableBiometrics}) async {
    await _pin.setPin(pin);
    await _store.write(_bioKey, '$enableBiometrics');
    state = state.copyWith(biometricEnabled: enableBiometrics);
    _unlocked();
  }

  Future<PinCheck> tryPin(String pin) async {
    final result = await _pin.verify(pin);
    if (result is PinOk) _unlocked();
    return result;
  }

  /// Returns true when the biometric check passed and the app is now unlocked.
  Future<bool> tryBiometrics() async {
    if (!state.biometricEnabled) return false;
    final bio = ref.read(biometricsProvider);
    if (!await bio.isAvailable) return false;
    final ok = await bio.authenticate('Unlock Paisa Vault');
    if (ok) _unlocked();
    return ok;
  }

  Future<void> setAutoLock(Duration d) async {
    await _store.write(_autoLockKey, '${d.inSeconds}');
    state = state.copyWith(autoLock: d);
    touch();
  }

  Future<void> setBiometricEnabled(bool on) async {
    await _store.write(_bioKey, '$on');
    state = state.copyWith(biometricEnabled: on);
  }

  void lock() {
    _idle?.cancel();
    if (state.status == LockStatus.unlocked) {
      state = state.copyWith(status: LockStatus.locked);
    }
  }

  /// Call on any user touch while unlocked: restarts the idle timer.
  void touch() {
    _idle?.cancel();
    if (state.status != LockStatus.unlocked) return;
    _idle = Timer(state.autoLock, lock);
  }

  void appBackgrounded() {
    _backgroundedAt = ref.read(clockProvider).now();
    _idle?.cancel();
  }

  void appResumed() {
    final at = _backgroundedAt;
    _backgroundedAt = null;
    if (at == null || state.status != LockStatus.unlocked) return;
    if (ref.read(clockProvider).now().difference(at) >= state.autoLock) {
      lock();
    } else {
      touch();
    }
  }

  void _unlocked() {
    state = state.copyWith(status: LockStatus.unlocked);
    touch();
  }
}
