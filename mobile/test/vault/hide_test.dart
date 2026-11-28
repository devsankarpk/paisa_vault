import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/dashboard/month_summary.dart';
import 'package:paisa_vault/features/lock/biometrics.dart';
import 'package:paisa_vault/features/lock/pin_service.dart';
import 'package:paisa_vault/features/search/transaction_filter.dart';
import 'package:paisa_vault/features/transactions/transaction_repository.dart';
import 'package:paisa_vault/features/vault/hide_service.dart';
import 'package:paisa_vault/features/vault/vault_key_service.dart';
import 'package:paisa_vault/features/vault/vault_session.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late VaultSession vault;
  late HideService hide;
  late TransactionRepository repo;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pv_hide');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
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
    hide = HideService(db, vault, clock);
    repo = TransactionRepository(db, clock);
  });
  tearDown(() async {
    await vault.lock();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<int> add(
    String merchant,
    int paise, {
    int? raw,
    String fp = '',
  }) async {
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountPaise: paise,
            direction: Direction.debit,
            merchant: Value(merchant),
            categoryName: const Value('Shopping'),
            bankCode: const Value('HDFC'),
            last4: const Value('6464'),
            rawMessageId: Value(raw),
            fingerprint: fp.isEmpty ? 'fp-$merchant' : fp,
            occurredAt: DateTime(2026, 11, 20),
            createdAt: DateTime(2026, 11, 20),
          ),
        );
  }

  test('a locked vault refuses to hide anything', () async {
    final id = await add('Secret Shop', 50000);
    expect(() => hide.hide(id), throwsStateError);
    expect(await db.select(db.transactions).get(), hasLength(1));
  });

  test(
    'hidden transaction is in no list, search, total or message text',
    () async {
      final raw = await db
          .into(db.rawMessages)
          .insert(
            RawMessagesCompanion.insert(
              sender: 'VM-HDFCBK',
              body: 'invented text for Secret Shop 500',
              receivedAt: DateTime(2026, 11, 20),
              contentHash: 'h1',
              createdAt: DateTime(2026, 11, 20),
            ),
          );
      final keep = await add('Visible Shop', 20000);
      final secret = await add('Secret Shop', 50000, raw: raw);
      await vault.openWithPin('2468');
      expect(await hide.hide(secret), isTrue);
      await vault.lock();

      final all = await repo.watchAll().first;
      expect(all.map((t) => t.id), [keep]);
      expect(
        await repo.search(const TransactionFilter(text: 'Secret')),
        isEmpty,
      );
      expect(
        await repo.search(const TransactionFilter(amountPaise: 50000)),
        isEmpty,
      );
      final month = summariseMonth(all, DateTime(2026, 11));
      expect(month.spendPaise, 20000);
      // The saved SMS text no longer holds the merchant, but its hash is kept.
      final m = await db.select(db.rawMessages).getSingle();
      expect(m.body, isEmpty);
      expect(m.contentHash, 'h1');
    },
  );
}
