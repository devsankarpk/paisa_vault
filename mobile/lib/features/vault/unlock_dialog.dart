import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../lock/lock_controller.dart';
import '../lock/pin_pad.dart';
import '../lock/pin_service.dart';
import 'providers.dart';

/// Asks for the PIN (or Face ID / fingerprint) and opens the vault. True when it is open.
Future<bool> unlockVault(BuildContext context, WidgetRef ref) async {
  final session = await ref.read(vaultSessionProvider.future);
  if (session.isOpen) return true;
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _UnlockDialog(),
  );
  return ok == true;
}

class _UnlockDialog extends ConsumerStatefulWidget {
  const _UnlockDialog();
  @override
  ConsumerState<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends ConsumerState<_UnlockDialog> {
  String? _error;
  bool _bio = false;

  @override
  void initState() {
    super.initState();
    ref.read(vaultKeyServiceProvider).hasBiometricCopy.then((v) {
      if (mounted) setState(() => _bio = v);
    });
  }

  Future<void> _pin(String code) async {
    final session = await ref.read(vaultSessionProvider.future);
    final offer = ref.read(lockControllerProvider).biometricEnabled;
    final r = await session.openWithPin(code, offerBiometrics: offer);
    if (!mounted) return;
    switch (r) {
      case PinOk():
        Navigator.pop(context, true);
      case PinLocked(:final remaining):
        setState(
          () => _error = 'Too many tries. Wait ${remaining.inSeconds} seconds.',
        );
      case PinWrong():
        setState(() => _error = 'Wrong PIN');
    }
  }

  Future<void> _biometric() async {
    final session = await ref.read(vaultSessionProvider.future);
    if (await session.openWithBiometrics()) {
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'This opens your private vault.',
              style: TextStyle(
                color: _error == null ? PvColors.muted : PvColors.error,
              ),
            ),
            const SizedBox(height: 16),
            PinPad(
              length: pinLength,
              onComplete: _pin,
              bottomLeft: _bio
                  ? IconButton(
                      onPressed: _biometric,
                      icon: const Icon(Icons.fingerprint),
                      color: PvColors.primary,
                      tooltip: 'Use Face ID or fingerprint',
                    )
                  : null,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
