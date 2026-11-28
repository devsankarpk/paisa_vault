import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart' show Direction;
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/lock/biometrics.dart';
import 'package:paisa_vault/features/lock/pin_service.dart';
import 'package:paisa_vault/features/settings/erase_service.dart';
import 'package:paisa_vault/features/vault/vault_database.dart';
import 'package:paisa_vault/features/vault/vault_key_service.dart';
import 'package:paisa_vault/features/vault/vault_session.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;
  late MemorySecretStore store;
  late FakeClock clock;
  late FakeBiometrics bio;
  late PinService pin;
  late VaultKeyService keys;
  late VaultSession vault;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pv_vault');
    file = File('${dir.path}/vault.db');
    store = MemorySecretStore();
    clock = FakeClock(DateTime(2026, 11, 28, 10));
    bio = FakeBiometrics();
    pin = PinService(store, clock, iterations: 1000);
    await pin.setPin('2468');
    keys = VaultKeyService(store, iterations: 1000);
    vault = VaultSession(
      file: file,
      keys: keys,
      pin: pin,
      biometrics: bio,
      clock: clock,
    );
  });
  tearDown(() async {
    await vault.lock();
    dir.deleteSync(recursive: true);
  });

  Future<void> hide(String merchant) => vault.db
      .into(vault.db.hiddenTransactions)
      .insert(
        HiddenTransactionsCompanion.insert(
          amountPaise: 123400,
          direction: Direction.debit,
          merchant: Value(merchant),
          fingerprint: 'fp-$merchant',
          occurredAt: DateTime(2026, 11, 20),
          createdAt: DateTime(2026, 11, 20),
        ),
      );

  test(
    'the vault is closed until opened, and reaching it then fails',
    () async {
      expect(vault.isOpen, isFalse);
      expect(() => vault.db, throwsStateError);
    },
  );

  test(
    'the right PIN opens it, data survives a lock, and the PIN reopens it',
    () async {
      expect(await vault.openWithPin('2468'), isA<PinOk>());
      await hide('SECRET SHOP');
      await vault.lock();
      expect(vault.isOpen, isFalse);
      expect(await vault.openWithPin('2468'), isA<PinOk>());
      final rows = await vault.db.select(vault.db.hiddenTransactions).get();
      expect(rows.single.merchant, 'SECRET SHOP');
    },
  );

  test(
    'a wrong PIN does not open it and counts towards the PIN lockout',
    () async {
      expect(await vault.openWithPin('2468'), isA<PinOk>());
      await vault.lock();
      final r = await vault.openWithPin('1111');
      expect(r, isA<PinWrong>());
      expect(vault.isOpen, isFalse);
      for (var i = 0; i < 4; i++) {
        await vault.openWithPin('1111');
      }
      expect(
        await vault.openWithPin('2468'),
        isA<PinLocked>(),
      ); // even the right one waits
      expect(vault.isOpen, isFalse);
    },
  );

  test(
    'without the key the file cannot be read, and holds no readable text',
    () async {
      await vault.openWithPin('2468');
      await hide('VERY DISTINCT NAME');
      await vault.lock();
      final wrong = VaultDatabase.open(file, List<int>.filled(32, 7));
      await expectLater(
        wrong.select(wrong.vaultAudit).get(),
        throwsA(anything),
      );
      await wrong.close();
      final raw = String.fromCharCodes(file.readAsBytesSync());
      expect(raw.contains('VERY DISTINCT NAME'), isFalse);
      expect(raw.contains('SQLite format'), isFalse);
    },
  );

  test(
    'every opening is written to the audit log with how it was opened',
    () async {
      await vault.openWithPin('2468', offerBiometrics: true);
      await vault.lock();
      await vault.openWithBiometrics();
      final log = await vault.db.select(vault.db.vaultAudit).get();
      expect(log.map((e) => e.method), ['pin', 'biometric']);
    },
  );

  test(
    'biometric opening needs the copy, a passing check and an available sensor',
    () async {
      await vault.openWithPin('2468'); // no biometric copy kept
      await vault.lock();
      expect(await vault.openWithBiometrics(), isFalse);

      await vault.openWithPin(
        '2468',
        offerBiometrics: true,
      ); // copy added on this open
      await vault.lock();
      bio.passes = false;
      expect(await vault.openWithBiometrics(), isFalse);
      bio.passes = true;
      bio.available = false;
      expect(await vault.openWithBiometrics(), isFalse);
      bio.available = true;
      expect(await vault.openWithBiometrics(), isTrue);
      expect(vault.isOpen, isTrue);
    },
  );

  test('locking closes the vault, and a second lock is harmless', () async {
    await vault.openWithPin('2468');
    await vault.lock();
    await vault.lock();
    expect(vault.isOpen, isFalse);
    expect(() => vault.db, throwsStateError);
  });

  test('the key is stored wrapped, never as it is', () async {
    await vault.openWithPin('2468', offerBiometrics: true);
    final wrapped = store.map[VaultKeyService.pinWrapKey]!;
    expect(wrapped.isNotEmpty, isTrue);
    expect(await keys.unwrapWithPin('0000'), isNull);
    expect(await keys.unwrapWithPin('2468'), isNotNull);
  });

  test(
    'card secrets have no CVV column, and erase forgets the vault',
    () async {
      await vault.openWithPin('2468');
      final cols = await vault.db
          .customSelect("select name from pragma_table_info('card_secrets')")
          .get();
      final names = cols.map((r) => r.read<String>('name')).join(' ');
      expect(names.contains('cvv'), isFalse);
      expect(EraseService.secretKeys, containsAll(VaultKeyService.secretKeys));
      expect(EraseService.files, contains('vault.db'));
      await vault.lock();
      await keys.forget();
      expect(await keys.exists, isFalse);
      expect(await keys.unwrapWithPin('2468'), isNull);
    },
  );
}
