import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/core/db/encrypted_executor.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/features/cards/card_repository.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late AppDatabase db;
  late CardRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_cards');
    db = AppDatabase(openEncrypted(File('${dir.path}/main.db'), randomKey()));
    repo = CardRepository(db, FakeClock(DateTime(2026, 11, 28)));
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<CardResult> add({
    String last4 = '6464',
    CardType type = CardType.credit,
    int? month = 8,
    int? year = 2030,
  }) async => (await repo.add(
    bankCode: 'HDFC',
    type: type,
    network: CardNetwork.visa,
    last4: last4,
    expiryMonth: month,
    expiryYear: year,
  )).result;

  test(
    'adding a card lists it with its bank, and shows only last 4 data',
    () async {
      expect(await add(), CardResult.ok);
      final list = await repo.watchAll().first;
      expect(list.single.bankName, 'HDFC Bank');
      expect(list.single.card.last4, '6464');
      expect(list.single.card.type, CardType.credit);
    },
  );

  test('there is no place to store a CVV or a full number', () async {
    final cols = await db
        .customSelect("select name from pragma_table_info('cards')")
        .get();
    final names = cols.map((r) => r.read<String>('name')).join(' ');
    expect(names.contains('cvv'), isFalse);
    expect(names.contains('number'), isFalse);
    expect(names.contains('pin'), isFalse);
  });

  test('bad input is refused', () async {
    expect(await add(last4: '12'), CardResult.badLast4);
    expect(await add(last4: '12ab'), CardResult.badLast4);
    expect(await add(month: 13), CardResult.badExpiry);
    expect(await add(month: 5, year: null), CardResult.badExpiry);
    expect(await repo.watchAll().first, isEmpty);
  });

  test('the same card twice is refused, a different type is allowed', () async {
    expect(await add(), CardResult.ok);
    expect(await add(), CardResult.exists);
    expect(await add(type: CardType.debit), CardResult.ok);
  });

  test(
    'a card takes over the account its SMS transactions already use',
    () async {
      final bank = await db
          .into(db.banks)
          .insertReturning(
            BanksCompanion.insert(code: 'HDFC', name: 'HDFC Bank'),
          );
      final account = await db
          .into(db.accounts)
          .insertReturning(
            AccountsCompanion.insert(
              bankId: Value(bank.id),
              kind: AccountKind.savings,
              last4: '6464',
              status: const Value(AccountStatus.pending),
              createdAt: DateTime(2026, 11, 20),
            ),
          );
      expect(await add(), CardResult.ok);
      final card = (await repo.watchAll().first).single.card;
      expect(card.accountId, account.id);
      final after = await db.select(db.accounts).getSingle();
      expect(after.status, AccountStatus.confirmed);
      expect(after.kind, AccountKind.creditCard);
      expect(await db.select(db.accounts).get(), hasLength(1));
    },
  );

  test(
    'bill settings: credit cards only, checked, saved once per card',
    () async {
      await add();
      await add(type: CardType.debit);
      final cards = (await repo.watchAll().first).map((e) => e.card).toList();
      final credit = cards.firstWhere((c) => c.type == CardType.credit);
      final debit = cards.firstWhere((c) => c.type == CardType.debit);

      expect(
        await repo.saveBill(debit.id, statementDay: 5, dueDay: 25),
        CardResult.notCredit,
      );
      expect(
        await repo.saveBill(credit.id, statementDay: 0, dueDay: 25),
        CardResult.badDays,
      );
      expect(
        await repo.saveBill(credit.id, statementDay: 5, dueDay: 32),
        CardResult.badDays,
      );
      expect(
        await repo.saveBill(999, statementDay: 5, dueDay: 25),
        CardResult.notFound,
      );

      expect(
        await repo.saveBill(
          credit.id,
          statementDay: 5,
          dueDay: 25,
          creditLimitPaise: 15000000,
          reminderDays: [1, 5, 5],
        ),
        CardResult.ok,
      );
      var b = (await repo.billFor(credit.id))!;
      expect(b.dueDay, 25);
      expect(b.reminderDays, '5,1');
      expect(b.creditLimitPaise, 15000000);

      await repo.saveBill(credit.id, statementDay: 6, dueDay: 26);
      b = (await repo.billFor(credit.id))!;
      expect(b.statementDay, 6);
      expect(await db.select(db.cardBillSettings).get(), hasLength(1));
    },
  );

  test('removing a card keeps the account and its transactions', () async {
    await add();
    final card = (await repo.watchAll().first).single.card;
    await repo.saveBill(card.id, statementDay: 5, dueDay: 25);
    await repo.remove(card.id);
    expect(await repo.watchAll().first, isEmpty);
    expect(await db.select(db.cardBillSettings).get(), isEmpty);
    expect(await db.select(db.accounts).get(), hasLength(1));
  });

  test('edit: details change, card moves to the matching account, bill stays for credit', () async {
    await add();
    final id = (await repo.watchAll().first).single.card.id;
    await repo.saveBill(id, statementDay: 5, dueDay: 25);
    final r = await repo.update(
      id,
      bankCode: 'SBI',
      type: CardType.credit,
      network: CardNetwork.mastercard,
      last4: '1234',
      expiryMonth: 9,
      expiryYear: 2031,
    );
    expect(r, CardResult.ok);
    final e = (await repo.watchAll().first).single;
    expect(e.bankCode, 'SBI');
    expect(e.card.last4, '1234');
    expect(e.card.network, CardNetwork.mastercard);
    expect(e.card.expiryYear, 2031);
    final account = await (db.select(
      db.accounts,
    )..where((a) => a.id.equals(e.card.accountId!))).getSingle();
    expect(account.last4, '1234');
    expect(await repo.billFor(id), isNotNull);
  });

  test('edit: switching to debit drops the bill reminder', () async {
    await add();
    final id = (await repo.watchAll().first).single.card.id;
    await repo.saveBill(id, statementDay: 5, dueDay: 25);
    await repo.update(
      id,
      bankCode: 'HDFC',
      type: CardType.debit,
      network: CardNetwork.visa,
      last4: '6464',
    );
    expect(await repo.billFor(id), isNull);
  });

  test('edit: refuses a clash, bad input and a missing card', () async {
    await add();
    await add(last4: '1111');
    final cards = (await repo.watchAll().first).map((e) => e.card).toList();
    Future<CardResult> edit(int id, String last4, {int? m, int? y}) =>
        repo.update(
          id,
          bankCode: 'HDFC',
          type: CardType.credit,
          network: CardNetwork.visa,
          last4: last4,
          expiryMonth: m,
          expiryYear: y,
        );
    expect(await edit(cards[0].id, '1111'), CardResult.exists);
    expect(await edit(cards[0].id, '12'), CardResult.badLast4);
    expect(
      await edit(cards[0].id, '6464', m: 13, y: 2030),
      CardResult.badExpiry,
    );
    expect(await edit(999, '2222'), CardResult.notFound);
    expect(await edit(cards[0].id, '6464'), CardResult.ok); // unchanged is fine
  });
}
