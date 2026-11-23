import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/lock/biometrics.dart';
import 'package:paisa_vault/features/lock/lock_controller.dart';
import 'package:paisa_vault/features/lock/pin_service.dart';
import 'package:paisa_vault/main.dart';
import 'package:paisa_vault/testing/fakes.dart';

Future<void> enter(WidgetTester t, String pin) async {
  for (final d in pin.split('')) {
    await t.tap(find.text(d));
    await t.pump();
  }
  await t.pumpAndSettle();
}

void main() {
  late MemorySecretStore store;
  late FakeClock clock;
  late FakeBiometrics bio;
  ProviderContainer? live;

  // Runs a widget test and always stops the app's idle timer at the end.
  void scenario(String name, Future<void> Function(WidgetTester t) body) {
    testWidgets(name, (t) async {
      await body(t);
      await t.pumpWidget(const SizedBox());
      live?.dispose();
      live = null;
    });
  }

  Future<ProviderContainer> start(WidgetTester t) async {
    final container = ProviderContainer(
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        biometricsProvider.overrideWithValue(bio),
        clockProvider.overrideWithValue(clock),
        smsSourceProvider.overrideWithValue(FakeSmsSource()),
        pinServiceProvider.overrideWith(
          (ref) => PinService(store, clock, iterations: 1000),
        ),
      ],
    );
    live = container;
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PaisaVaultApp(
          home: Scaffold(body: Center(child: Text('Paisa Vault'))),
        ),
      ),
    );
    await t.pumpAndSettle();
    return container;
  }

  setUp(() {
    store = MemorySecretStore();
    clock = FakeClock(DateTime(2026, 11, 20, 10));
    bio = FakeBiometrics(available: false);
  });

  scenario('first run: note, create, confirm, then home', (t) async {
    await start(t);
    expect(find.text('Before you start'), findsOneWidget);
    expect(find.textContaining('nobody can reset your PIN'), findsOneWidget);
    await t.tap(find.text('I understand'));
    await t.pumpAndSettle();
    expect(find.text('Create your PIN'), findsOneWidget);
    await enter(t, '1357');
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await enter(t, '1357');
    expect(find.text('Paisa Vault'), findsOneWidget); // home
    expect(find.text('Enter your PIN to unlock'), findsNothing);
  });

  scenario('mismatched confirmation starts again', (t) async {
    await start(t);
    await t.tap(find.text('I understand'));
    await t.pumpAndSettle();
    await enter(t, '1357');
    await enter(t, '1358');
    expect(find.text('Create your PIN'), findsOneWidget);
    expect(find.textContaining('did not match'), findsOneWidget);
  });

  scenario('locked app: wrong PIN stays locked, right PIN opens', (t) async {
    await PinService(store, clock, iterations: 1000).setPin('2468');
    await start(t);
    expect(find.text('Enter your PIN to unlock'), findsOneWidget);
    await enter(t, '1111');
    expect(find.textContaining('Wrong PIN'), findsOneWidget);
    await enter(t, '2468');
    expect(find.text('Enter your PIN to unlock'), findsNothing);
    expect(find.text('Wrong PIN. Try again.'), findsNothing);
  });

  scenario('five wrong PINs show a lockout message', (t) async {
    await PinService(store, clock, iterations: 1000).setPin('2468');
    await start(t);
    for (var i = 0; i < 5; i++) {
      await enter(t, '1111');
      if (i < 4) continue;
    }
    expect(find.textContaining('Too many tries'), findsOneWidget);
  });

  scenario('biometrics offered when available, and unlock the app', (t) async {
    bio = FakeBiometrics(available: true, passes: true);
    final c = await start(t);
    await t.tap(find.text('I understand'));
    await t.pumpAndSettle();
    await enter(t, '1357');
    await enter(t, '1357');
    expect(find.text('Unlock faster?'), findsOneWidget);
    await t.tap(find.text('Turn on'));
    await t.pumpAndSettle();
    expect(c.read(lockControllerProvider).biometricEnabled, true);

    c.read(lockControllerProvider.notifier).lock();
    await t.pumpAndSettle();
    // Lock screen asks for biometrics straight away and it passes.
    expect(c.read(lockControllerProvider).status, LockStatus.unlocked);
    expect(bio.prompts, greaterThanOrEqualTo(2));
  });

  scenario('lock screen shows a face icon on Face ID phones, no text link', (
    t,
  ) async {
    bio = FakeBiometrics(
      available: true,
      passes: false,
      biometricKind: BiometricKind.face,
    );
    await PinService(store, clock, iterations: 1000).setPin('2468');
    await store.write('pv_bio_enabled', 'true');
    await start(t);
    expect(find.byIcon(Icons.face_unlock_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsNothing);
    expect(find.text('Use biometrics'), findsNothing);
  });

  scenario('lock screen shows a fingerprint icon on fingerprint phones', (
    t,
  ) async {
    bio = FakeBiometrics(available: true, passes: false);
    await PinService(store, clock, iterations: 1000).setPin('2468');
    await store.write('pv_bio_enabled', 'true');
    await start(t);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.byIcon(Icons.face_unlock_outlined), findsNothing);
  });

  scenario('failed biometrics fall back to the PIN', (t) async {
    bio = FakeBiometrics(available: true, passes: true);
    await PinService(store, clock, iterations: 1000).setPin('2468');
    await store.write('pv_bio_enabled', 'true');
    bio.passes = false;
    final c = await start(t);
    expect(c.read(lockControllerProvider).status, LockStatus.locked);
    await enter(t, '2468');
    expect(c.read(lockControllerProvider).status, LockStatus.unlocked);
  });

  scenario('locks after the idle time and when away from the app too long', (
    t,
  ) async {
    await PinService(store, clock, iterations: 1000).setPin('2468');
    final c = await start(t);
    await enter(t, '2468');
    final n = c.read(lockControllerProvider.notifier);
    expect(c.read(lockControllerProvider).status, LockStatus.unlocked);

    // Idle timer
    await t.pump(const Duration(minutes: 1, seconds: 1));
    expect(c.read(lockControllerProvider).status, LockStatus.locked);

    // Short trip to another app: stays unlocked
    await enter(t, '2468');
    n.appBackgrounded();
    clock.current = clock.current.add(const Duration(seconds: 20));
    n.appResumed();
    expect(c.read(lockControllerProvider).status, LockStatus.unlocked);

    // Long trip: locks
    n.appBackgrounded();
    clock.current = clock.current.add(const Duration(minutes: 2));
    n.appResumed();
    await t.pump();
    expect(c.read(lockControllerProvider).status, LockStatus.locked);
  });
}
