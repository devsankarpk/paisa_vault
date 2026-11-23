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
import 'features/transactions/transactions_screen.dart';

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
  const PaisaVaultApp({super.key, this.home = const TransactionsScreen()});

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
