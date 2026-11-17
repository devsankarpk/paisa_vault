import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
  runApp(const ProviderScope(child: PaisaVaultApp()));
}

class PaisaVaultApp extends StatelessWidget {
  const PaisaVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paisa Vault',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('Paisa Vault'))),
    );
  }
}
