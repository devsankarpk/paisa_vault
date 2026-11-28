import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/cards/full_number_section.dart';
import 'package:paisa_vault/features/lock/biometrics.dart';
import 'package:paisa_vault/features/lock/lock_controller.dart'
    show pinServiceProvider;
import 'package:paisa_vault/features/lock/pin_service.dart';
import 'package:paisa_vault/features/vault/providers.dart';
import 'package:paisa_vault/features/vault/vault_key_service.dart';
import 'package:paisa_vault/features/vault/vault_session.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'number needs the PIN, shows for 45 seconds, then hides and locks',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('pv_fullnum');
      final secrets = MemorySecretStore();
      final clock = FakeClock(DateTime(2026, 11, 28, 10));
      final pin = PinService(secrets, clock, iterations: 1000);
      await t.runAsync(() => pin.setPin('2468'));
      final vault = VaultSession(
        file: File('${dir.path}/vault.db'),
        keys: VaultKeyService(secrets, iterations: 1000),
        pin: pin,
        biometrics: FakeBiometrics(),
        clock: clock,
      );
      t.view.physicalSize = const Size(800, 1800);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);

      final keys = VaultKeyService(secrets, iterations: 1000);
      final container = ProviderContainer(
        overrides: [
          vaultKeyServiceProvider.overrideWithValue(keys),
          vaultSessionProvider.overrideWith((ref) async => vault),
          pinServiceProvider.overrideWithValue(pin),
          clockProvider.overrideWithValue(clock),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: FullNumberSection(cardId: 1)),
          ),
        ),
      );
      Future<void> work() async {
        for (var i = 0; i < 4; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)),
          );
          await t.pump(const Duration(milliseconds: 100));
        }
      }

      await work();
      expect(find.text('Show full number'), findsOneWidget);
      expect(vault.isOpen, isFalse);

      await t.tap(find.text('Show full number'));
      await work();
      expect(find.text('Enter your PIN'), findsOneWidget);
      // wrong PIN first
      for (final d in '1111'.split('')) {
        await t.tap(find.text(d).last);
      }
      await work();
      expect(find.text('Wrong PIN'), findsOneWidget);
      expect(vault.isOpen, isFalse);
      for (final d in '2468'.split('')) {
        await t.tap(find.text(d).last);
      }
      await work();
      expect(vault.isOpen, isTrue);
      expect(find.text('No full number saved for this card.'), findsOneWidget);

      await t.tap(find.text('Add card number'));
      await work();
      await t.enterText(find.byType(TextField), '4111 1111 1111 1112');
      await t.tap(find.text('Save'));
      await work();
      expect(find.text('This number does not look right'), findsOneWidget);
      await t.enterText(find.byType(TextField), '4111111111111111');
      await t.tap(find.text('Save'));
      await work();
      await work();
      expect(find.text('4111 1111 1111 1111'), findsOneWidget);
      expect(find.textContaining('Hides in 45'), findsOneWidget);

      // Card PIN is off by default; saving needs the warning to be accepted.
      expect(find.text('Not saved. Saving it is optional.'), findsOneWidget);
      await t.tap(find.text('Save card PIN'));
      await work();
      expect(
        find.textContaining('responsible if a stored PIN'),
        findsOneWidget,
      );
      await t.tap(find.text('I understand, continue'));
      await work();
      await t.enterText(find.byType(TextField), '12');
      await t.tap(find.text('Save'));
      await work();
      expect(find.text('A card PIN has 4 to 6 digits'), findsOneWidget);
      await t.enterText(find.byType(TextField), '4821');
      await t.tap(find.text('Save'));
      await work();
      await work();
      expect(find.text('4821'), findsOneWidget);

      await t.pump(const Duration(seconds: 46));
      await work();
      expect(find.text('4111 1111 1111 1111'), findsNothing);
      expect(find.text('Show full number'), findsOneWidget);
      expect(vault.isOpen, isFalse);

      await t.pumpWidget(const SizedBox());
      container.dispose();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      dir.deleteSync(recursive: true);
    },
  );
}
