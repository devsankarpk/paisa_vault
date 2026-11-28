import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/core/ui/screen_guard.dart';
import 'package:paisa_vault/features/lock/biometrics.dart';
import 'package:paisa_vault/features/lock/lock_controller.dart'
    show pinServiceProvider;
import 'package:paisa_vault/features/lock/pin_service.dart';
import 'package:paisa_vault/features/transactions/transaction_detail_screen.dart';
import 'package:paisa_vault/features/vault/hidden_screen.dart';
import 'package:paisa_vault/features/vault/providers.dart';
import 'package:paisa_vault/features/vault/vault_key_service.dart';
import 'package:paisa_vault/features/vault/vault_session.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'hide from the detail screen, then unhide from the private vault',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('pv_hide_ui');
      final db = AppDatabase(
        openEncrypted(File('${dir.path}/main.db'), randomKey()),
      );
      final secrets = MemorySecretStore();
      final clock = FakeClock(DateTime(2026, 11, 28, 10));
      final pin = PinService(secrets, clock, iterations: 1000);
      await t.runAsync(() => pin.setPin('2468'));
      final keys = VaultKeyService(secrets, iterations: 1000);
      final vault = VaultSession(
        file: File('${dir.path}/vault.db'),
        keys: keys,
        pin: pin,
        biometrics: FakeBiometrics(),
        clock: clock,
      );
      final id = await t.runAsync(
        () => db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                amountPaise: 50000,
                direction: Direction.debit,
                merchant: const Value('Secret Shop'),
                fingerprint: 'fp1',
                occurredAt: DateTime(2026, 11, 20),
                createdAt: DateTime(2026, 11, 20),
              ),
            ),
      );
      t.view.physicalSize = const Size(800, 1800);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          vaultSessionProvider.overrideWith((ref) async => vault),
          vaultKeyServiceProvider.overrideWithValue(keys),
          pinServiceProvider.overrideWithValue(pin),
          clockProvider.overrideWithValue(clock),
          screenGuardProvider.overrideWithValue(FakeScreenGuard()),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TransactionDetailScreen(id: id!),
                        ),
                      ),
                      child: const Text('open detail'),
                    ),
                    Consumer(
                      builder: (context, ref, _) => TextButton(
                        onPressed: () => openHiddenVault(context, ref),
                        child: const Text('open vault'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> work() async {
        for (var i = 0; i < 4; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)),
          );
          await t.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> typePin() async {
        for (final d in '2468'.split('')) {
          await t.tap(find.text(d).last);
        }
        await work();
      }

      await t.tap(find.text('open detail'));
      await work();
      expect(find.text('Secret Shop'), findsWidgets);
      await t.tap(find.text('Hide this transaction'));
      await work();
      await typePin();
      await work();
      expect(find.text('Moved to your private vault'), findsOneWidget);
      expect(vault.isOpen, isFalse);
      expect(await t.runAsync(() => db.select(db.transactions).get()), isEmpty);

      await t.tap(find.text('open vault'));
      await work();
      await typePin();
      await work();
      expect(find.text('Private vault'), findsOneWidget);
      expect(find.text('Secret Shop'), findsOneWidget);
      await t.tap(find.text('Secret Shop'));
      await work();
      await t.tap(find.text('Unhide'));
      await work();
      expect(find.textContaining('Nothing hidden'), findsOneWidget);
      expect(
        await t.runAsync(() => db.select(db.transactions).get()),
        hasLength(1),
      );

      await t.tap(find.byTooltip('Back'));
      await work();
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Private vault'), findsNothing);
      expect(vault.isOpen, isFalse); // leaving the vault closes it

      await t.pumpWidget(const SizedBox());
      container.dispose();
      for (var i = 0; i < 3; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump(const Duration(seconds: 1));
      }
      await t.runAsync(() async {
        await vault.lock().timeout(const Duration(seconds: 5));
        await db.close().timeout(const Duration(seconds: 5));
      });
      await t.pump(const Duration(seconds: 1));
      dir.deleteSync(recursive: true);
    },
  );
}
