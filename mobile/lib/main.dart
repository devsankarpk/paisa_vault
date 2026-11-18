import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/secret_store.dart';
import 'core/theme/app_theme.dart';
import 'features/lock/biometrics.dart';
import 'features/lock/lock_controller.dart';
import 'features/lock/lock_gate.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        secretStoreProvider.overrideWithValue(SecureSecretStore()),
        biometricsProvider.overrideWithValue(LocalAuthBiometrics()),
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
      home: LockGate(child: home),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Paisa Vault')));
  }
}
