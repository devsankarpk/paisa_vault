import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/secret_store.dart';
import 'core/theme/app_theme.dart';
import 'features/lock/biometrics.dart';
import 'features/lock/lock_controller.dart';
import 'features/lock/lock_gate.dart';
import 'features/sms/native_sms_source.dart';
import 'features/sms/sms_runner.dart';
import 'features/sms/saved_count.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        secretStoreProvider.overrideWithValue(SecureSecretStore()),
        biometricsProvider.overrideWithValue(LocalAuthBiometrics()),
        smsSourceProvider.overrideWithValue(NativeSmsSource()),
      ],
      child: const PaisaVaultApp(),
    ),
  );
}

class PaisaVaultApp extends StatelessWidget {
  const PaisaVaultApp({super.key, this.home = const _Home()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paisa Vault',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: LockGate(child: SmsRunner(child: home)),
    );
  }
}

/// Placeholder home until the transaction list exists. Shows only how many messages are saved.
class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(savedMessageCountProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paisa Vault'),
            const SizedBox(height: 8),
            Text(
              count.when(
                data: (n) => 'Saved messages: $n',
                loading: () => 'Saved messages: ...',
                error: (_, _) => 'Saved messages: error',
              ),
              style: const TextStyle(color: Colors.grey),
            ),
            for (final t
                in ref.watch(savedTimesProvider).value ?? const <DateTime>[])
              Text(
                t.toLocal().toString().substring(0, 19),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
