import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/crash_log.dart';
import 'core/providers.dart';
import 'core/secret_store.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/system_bar_padding.dart';
import 'features/lock/biometrics.dart';
import 'features/lock/lock_controller.dart';
import 'features/lock/lock_gate.dart';
import 'features/sms/native_sms_source.dart';
import 'features/sms/sms_runner.dart';
import 'features/transactions/transactions_screen.dart';
import 'services/local_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CrashLog().install();
  runApp(
    ProviderScope(
      overrides: [
        secretStoreProvider.overrideWithValue(SecureSecretStore()),
        biometricsProvider.overrideWithValue(LocalAuthBiometrics()),
        smsSourceProvider.overrideWithValue(NativeSmsSource()),
        notifierProvider.overrideWithValue(LocalNotifier()),
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
      builder: (context, child) => SystemBarPadding(child: child!),
      home: LockGate(child: SmsRunner(child: home)),
    );
  }
}
