import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/lock/biometrics.dart';
import 'package:paisa_vault/features/lock/pin_service.dart';
import 'package:paisa_vault/features/vault/card_secret_store.dart';
import 'package:paisa_vault/features/vault/vault_key_service.dart';
import 'package:paisa_vault/features/vault/vault_session.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late VaultSession vault;
  late CardSecretStore store;
  const good = '4111111111111111'; // public test number

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pv_cardsecret');
    final secrets = MemorySecretStore();
    final clock = FakeClock(DateTime(2026, 11, 28, 10));
    final pin = PinService(secrets, clock, iterations: 1000);
    await pin.setPin('2468');
    vault = VaultSession(
      file: File('${dir.path}/vault.db'),
      keys: VaultKeyService(secrets, iterations: 1000),
      pin: pin,
      biometrics: FakeBiometrics(),
      clock: clock,
    );
    store = CardSecretStore(vault, clock);
    await vault.openWithPin('2468');
  });
  tearDown(() async {
    await vault.lock();
    dir.deleteSync(recursive: true);
  });

  test('number round trips and spaces are ignored', () async {
    expect(await store.saveNumber(1, '4111 1111 1111 1111'), isNull);
    expect(await store.readNumber(1), good);
    expect(await store.readNumber(2), isNull);
  });

  test(
    'the number is not readable in the file, even with the vault key',
    () async {
      await store.saveNumber(1, good);
      final key = List<int>.of(vault.key);
      await vault.lock();
      final bytes = File('${dir.path}/vault.db').readAsBytesSync();
      expect(String.fromCharCodes(bytes).contains(good), isFalse);
      // Reopen: the stored field is still ciphertext, not the digits.
      await vault.openWithPin('2468');
      final db = vault.db;
      final row = await db.select(db.cardSecrets).getSingle();
      expect(row.numberCipher, isNot(contains(good)));
      expect(key, isNotEmpty);
    },
  );

  test('a ciphertext moved to another card does not decrypt', () async {
    await store.saveNumber(1, good);
    final db = vault.db;
    await db.customStatement("UPDATE card_secrets SET id = '2'");
    expect(await store.readNumber(2), isNull);
  });

  test('bad numbers are refused and nothing is saved', () async {
    expect(await store.saveNumber(1, '12ab'), NumberProblem.notDigits);
    expect(await store.saveNumber(1, '1234'), NumberProblem.badLength);
    expect(
      await store.saveNumber(1, '4111111111111112'),
      NumberProblem.failsCheck,
    );
    expect(await store.readNumber(1), isNull);
  });

  test('locked vault refuses reads and the key is gone', () async {
    await store.saveNumber(1, good);
    await vault.lock();
    expect(() => store.readNumber(1), throwsStateError);
    expect(() => vault.key, throwsStateError);
  });

  test('delete removes the number', () async {
    await store.saveNumber(1, good);
    await store.delete(1);
    expect(await store.readNumber(1), isNull);
  });

  test(
    'card PIN is off until saved, is encrypted, and keeps the number',
    () async {
      await store.saveNumber(1, good);
      expect(await store.readPin(1), isNull);
      expect(await store.savePin(1, '12'), isFalse);
      expect(await store.savePin(1, '4821'), isTrue);
      expect(await store.readPin(1), '4821');
      expect(await store.readNumber(1), good);
      final db = vault.db;
      final row = await db.select(db.cardSecrets).getSingle();
      expect(row.pinCipher, isNot(contains('4821')));
      // A PIN can be saved without a number, and deleted on its own.
      expect(await store.savePin(2, '123456'), isTrue);
      await store.deletePin(1);
      expect(await store.readPin(1), isNull);
      expect(await store.readNumber(1), good);
      expect(await store.readPin(2), '123456');
    },
  );

  test('the PIN and number ciphertexts are not interchangeable', () async {
    await store.saveNumber(1, good);
    await store.savePin(1, '4821');
    final db = vault.db;
    await db.customStatement(
      'UPDATE card_secrets SET pin_cipher = number_cipher',
    );
    expect(await store.readPin(1), isNull);
  });
}
