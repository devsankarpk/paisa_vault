import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/main.dart';

void main() {
  testWidgets('app starts and shows its name', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaisaVaultApp()));
    expect(find.text('Paisa Vault'), findsOneWidget);
  });
}
