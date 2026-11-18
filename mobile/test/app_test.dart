import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/lock/biometrics.dart';
import 'package:paisa_vault/features/lock/lock_controller.dart';
import 'package:paisa_vault/main.dart';

void main() {
  testWidgets('a fresh install asks to set up the lock first', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          biometricsProvider.overrideWithValue(
            FakeBiometrics(available: false),
          ),
        ],
        child: const PaisaVaultApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Before you start'), findsOneWidget);
  });
}
