import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'biometrics.dart';
import 'lock_controller.dart';
import 'pin_pad.dart';
import 'pin_service.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    this.error = false,
  });
  final String title;
  final String subtitle;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: PvColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.shield_outlined, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: error ? PvColors.error : PvColors.muted,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Asks for the PIN (and Face ID / fingerprint when turned on).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  String _message = 'Enter your PIN to unlock';
  bool _error = false;
  bool _blocked = false;
  BiometricKind _kind = BiometricKind.fingerprint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    ref.read(biometricsProvider).kind.then((k) {
      if (mounted) setState(() => _kind = k);
    });
  }

  bool _prompting = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// iOS refuses the Face ID prompt while the app is in the background, so the
  /// automatic prompt is retried each time the app comes back to the front.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _bio(settle: true);
  }

  Future<void> _bio({bool settle = false}) async {
    if (_prompting || !mounted) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    _prompting = true;
    // Give iOS a moment to finish bringing the app to the front.
    if (settle) await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      if (mounted) {
        await ref.read(lockControllerProvider.notifier).tryBiometrics();
      }
    } finally {
      _prompting = false;
    }
  }

  String _wait(Duration d) => d.inMinutes >= 1
      ? 'Too many tries. Try again in ${d.inMinutes + 1} min.'
      : 'Too many tries. Try again in ${d.inSeconds + 1} s.';

  Future<void> _submit(String pin) async {
    final r = await ref.read(lockControllerProvider.notifier).tryPin(pin);
    if (!mounted) return;
    setState(() {
      _blocked = r is PinLocked;
      switch (r) {
        case PinOk():
          break;
        case PinWrong(:final triesBeforeLock):
          _error = true;
          _message = triesBeforeLock == 0
              ? 'Wrong PIN. The next wrong try locks the app for a while.'
              : 'Wrong PIN. Try again.';
        case PinLocked(:final remaining):
          _error = true;
          _message = _wait(remaining);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bio = ref.watch(
      lockControllerProvider.select((s) => s.biometricEnabled),
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  title: 'Paisa Vault',
                  subtitle: _message,
                  error: _error,
                ),
                PinPad(
                  length: pinLength,
                  enabled: !_blocked,
                  onComplete: _submit,
                  bottomLeft: bio
                      ? IconButton(
                          onPressed: _bio,
                          iconSize: 34,
                          color: PvColors.primary,
                          tooltip: _kind == BiometricKind.face
                              ? 'Use Face ID'
                              : 'Use fingerprint',
                          icon: Icon(
                            _kind == BiometricKind.face
                                ? Icons.face_unlock_outlined
                                : Icons.fingerprint,
                          ),
                        )
                      : null,
                ),
                if (_blocked)
                  TextButton(
                    onPressed: () => setState(() {
                      _blocked = false;
                      _error = false;
                      _message = 'Enter your PIN to unlock';
                    }),
                    child: const Text('Try again'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// First run: recovery note, then create and confirm a PIN, then offer biometrics.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

enum _Step { note, create, confirm, biometrics }

class _SetupScreenState extends ConsumerState<SetupScreen> {
  _Step _step = _Step.note;
  String _first = '';
  String? _error;

  Future<void> _onPin(String pin) async {
    if (_step == _Step.create) {
      setState(() {
        _first = pin;
        _step = _Step.confirm;
        _error = null;
      });
    } else if (_step == _Step.confirm) {
      if (pin != _first) {
        setState(() {
          _step = _Step.create;
          _first = '';
          _error = 'The two PINs did not match. Start again.';
        });
        return;
      }
      final bio = ref.read(biometricsProvider);
      if (await bio.isAvailable) {
        setState(() => _step = _Step.biometrics);
      } else {
        await ref
            .read(lockControllerProvider.notifier)
            .createPin(pin, enableBiometrics: false);
      }
    }
  }

  Future<void> _finish(bool useBio) async {
    var enable = useBio;
    if (useBio) {
      enable = await ref
          .read(biometricsProvider)
          .authenticate('Turn on biometric unlock');
    }
    await ref
        .read(lockControllerProvider.notifier)
        .createPin(_first, enableBiometrics: enable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: switch (_step) {
              _Step.note => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Header(title: 'Before you start', subtitle: ''),
                  const Text(
                    'Everything stays on this phone. There is no account and no server, so '
                    'nobody can reset your PIN for you.\n\n'
                    'If you forget your PIN and have not turned on Face ID or fingerprint, the only '
                    'way back in is to erase the app and restore from your encrypted backup file.',
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => setState(() => _step = _Step.create),
                    child: const Text('I understand'),
                  ),
                ],
              ),
              _Step.create || _Step.confirm => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    title: _step == _Step.create
                        ? 'Create your PIN'
                        : 'Confirm your PIN',
                    subtitle:
                        _error ??
                        (_step == _Step.create
                            ? 'Choose a $pinLength-digit PIN.'
                            : 'Enter the same PIN again.'),
                    error: _error != null,
                  ),
                  PinPad(
                    key: ValueKey(_step),
                    length: pinLength,
                    onComplete: _onPin,
                  ),
                ],
              ),
              _Step.biometrics => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Header(
                    title: 'Unlock faster?',
                    subtitle: 'Use Face ID or fingerprint instead of typing your PIN. Your PIN still works.',
                  ),
                  FilledButton(
                    onPressed: () => _finish(true),
                    child: const Text('Turn on'),
                  ),
                  TextButton(
                    onPressed: () => _finish(false),
                    child: const Text('Not now'),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}
