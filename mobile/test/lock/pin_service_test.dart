import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/lock/pin_service.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  late MemorySecretStore store;
  late FakeClock clock;
  late PinService pin;

  setUp(() {
    store = MemorySecretStore();
    clock = FakeClock(DateTime(2026, 11, 20, 10));
    pin = PinService(store, clock, iterations: 1000);
  });

  test('no PIN at first, then correct PIN opens', () async {
    expect(await pin.hasPin, false);
    await pin.setPin('1234');
    expect(await pin.hasPin, true);
    expect(await pin.verify('1234'), isA<PinOk>());
  });

  test('PIN is not stored in plain text', () async {
    await pin.setPin('4821');
    expect(store.map.values.any((v) => v.contains('4821')), false);
  });

  test('rejects a PIN of the wrong shape', () async {
    expect(() => pin.setPin('12'), throwsArgumentError);
    expect(() => pin.setPin('abcd'), throwsArgumentError);
  });

  test('wrong PIN counts down, then locks out with growing waits', () async {
    await pin.setPin('1234');
    for (var i = 3; i >= 0; i--) {
      final r = await pin.verify('0000');
      expect(r, isA<PinWrong>());
      expect((r as PinWrong).triesBeforeLock, i);
    }
    var r = await pin.verify('0000');
    expect((r as PinLocked).remaining, const Duration(seconds: 30));

    // Even the right PIN is refused during the lockout.
    expect(await pin.verify('1234'), isA<PinLocked>());

    clock.current = clock.current.add(const Duration(seconds: 31));
    r = await pin.verify('0000');
    expect((r as PinLocked).remaining, const Duration(minutes: 1));
  });

  test('right PIN after the lockout clears the counter', () async {
    await pin.setPin('1234');
    for (var i = 0; i < 5; i++) {
      await pin.verify('0000');
    }
    clock.current = clock.current.add(const Duration(minutes: 2));
    expect(await pin.verify('1234'), isA<PinOk>());
    expect(await pin.lockedFor(), isNull);
    expect(await pin.verify('0000'), isA<PinWrong>());
  });

  test('lockout survives a new service instance (app restart)', () async {
    await pin.setPin('1234');
    for (var i = 0; i < 5; i++) {
      await pin.verify('0000');
    }
    final again = PinService(store, clock, iterations: 1000);
    expect(await again.verify('1234'), isA<PinLocked>());
  });

  test('clear removes the PIN', () async {
    await pin.setPin('1234');
    await pin.clear();
    expect(await pin.hasPin, false);
  });
}
