import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../transactions/transaction_repository.dart' show bankNames;

enum CardResult {
  ok,
  badLast4,
  badExpiry,
  exists,
  notCredit,
  badDays,
  notFound,
}

/// The outcome of adding a card, with the new card's id when it worked.
class CardAdded {
  const CardAdded(this.result, [this.id]);
  final CardResult result;
  final int? id;
}

/// A card with its bank's name, for the list.
class CardEntry {
  const CardEntry(this.card, this.bankName);
  final PvCard card;
  final String bankName;
}

/// Cards the user added. Holds only what the list may show; the full number and PIN will be
/// kept encrypted in vault.db. There is no CVV anywhere. Adding a card files its bank and last 4
/// under one account, so SMS transactions for that card are already linked to it.
class CardRepository {
  CardRepository(this._db, this._clock);
  final AppDatabase _db;
  final Clock _clock;

  Future<CardAdded> add({
    required String bankCode,
    required CardType type,
    required CardNetwork network,
    required String last4,
    int? expiryMonth,
    int? expiryYear,
  }) async {
    if (!RegExp(r'^\d{4}$').hasMatch(last4)) {
      return const CardAdded(CardResult.badLast4);
    }
    if ((expiryMonth == null) != (expiryYear == null)) {
      return const CardAdded(CardResult.badExpiry);
    }
    if (expiryMonth != null &&
        (expiryMonth < 1 ||
            expiryMonth > 12 ||
            expiryYear! < 2000 ||
            expiryYear > 2100)) {
      return const CardAdded(CardResult.badExpiry);
    }
    return _db.transaction(() async {
      final bank = await _bank(bankCode);
      final dup =
          await (_db.select(_db.cards)..where(
                (c) =>
                    c.bankId.equals(bank.id) &
                    c.type.equals(type.name) &
                    c.last4.equals(last4),
              ))
              .getSingleOrNull();
      if (dup != null) return const CardAdded(CardResult.exists);
      final accountId = await _account(
        bank.id,
        last4,
        type == CardType.credit
            ? AccountKind.creditCard
            : AccountKind.debitCard,
      );
      final id = await _db
          .into(_db.cards)
          .insert(
            CardsCompanion.insert(
              bankId: bank.id,
              accountId: Value(accountId),
              type: type,
              network: network,
              last4: last4,
              expiryMonth: Value(expiryMonth),
              expiryYear: Value(expiryYear),
              createdAt: _clock.now(),
            ),
          );
      return CardAdded(CardResult.ok, id);
    });
  }

  Future<Bank> _bank(String code) async {
    final found = await (_db.select(
      _db.banks,
    )..where((b) => b.code.equals(code))).getSingleOrNull();
    return found ??
        await _db
            .into(_db.banks)
            .insertReturning(
              BanksCompanion.insert(code: code, name: bankNames[code] ?? code),
            );
  }

  /// Reuses the account SMS transactions already created for this bank and last 4 (confirming
  /// it, since the user now vouches for it), or makes a confirmed one.
  Future<int> _account(int bankId, String last4, AccountKind kind) async {
    final existing =
        await (_db.select(_db.accounts)
              ..where((a) => a.bankId.equals(bankId) & a.last4.equals(last4))
              ..orderBy([(a) => OrderingTerm.asc(a.id)])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      if (existing.status == AccountStatus.pending) {
        await (_db.update(
          _db.accounts,
        )..where((a) => a.id.equals(existing.id))).write(
          AccountsCompanion(
            status: Value(AccountStatus.confirmed),
            kind: Value(kind),
          ),
        );
      }
      return existing.id;
    }
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            bankId: Value(bankId),
            kind: kind,
            last4: last4,
            createdAt: _clock.now(),
          ),
        );
  }

  Stream<List<CardEntry>> watchAll() {
    final q = _db.select(_db.cards).join([
      innerJoin(_db.banks, _db.banks.id.equalsExp(_db.cards.bankId)),
    ])..orderBy([OrderingTerm.asc(_db.cards.id)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          CardEntry(r.readTable(_db.cards), r.readTable(_db.banks).name),
      ],
    );
  }

  /// Removes the card and its bill reminders. The account and its transactions stay.
  Future<void> remove(int cardId) => _db.transaction(() async {
    await (_db.delete(
      _db.cardBillSettings,
    )..where((b) => b.cardId.equals(cardId))).go();
    await (_db.delete(_db.cards)..where((c) => c.id.equals(cardId))).go();
  });

  Future<CardBillSetting?> billFor(int cardId) => (_db.select(
    _db.cardBillSettings,
  )..where((b) => b.cardId.equals(cardId))).getSingleOrNull();

  /// Saves bill reminder settings for a credit card. Days are days of the month; reminders are
  /// days before the due date.
  Future<CardResult> saveBill(
    int cardId, {
    required int statementDay,
    required int dueDay,
    int? creditLimitPaise,
    List<int> reminderDays = const [5, 1],
  }) async {
    final card = await (_db.select(
      _db.cards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null) return CardResult.notFound;
    if (card.type != CardType.credit) return CardResult.notCredit;
    bool day(int d) => d >= 1 && d <= 31;
    if (!day(statementDay) ||
        !day(dueDay) ||
        reminderDays.any((d) => d < 0 || d > 30) ||
        (creditLimitPaise != null && creditLimitPaise <= 0)) {
      return CardResult.badDays;
    }
    final days = (reminderDays.toSet().toList()..sort((a, b) => b.compareTo(a)))
        .join(',');
    await _db
        .into(_db.cardBillSettings)
        .insert(
          CardBillSettingsCompanion.insert(
            cardId: cardId,
            statementDay: statementDay,
            dueDay: dueDay,
            creditLimitPaise: Value(creditLimitPaise),
            reminderDays: Value(days),
          ),
          onConflict: DoUpdate(
            (_) => CardBillSettingsCompanion(
              statementDay: Value(statementDay),
              dueDay: Value(dueDay),
              creditLimitPaise: Value(creditLimitPaise),
              reminderDays: Value(days),
            ),
            target: [_db.cardBillSettings.cardId],
          ),
        );
    return CardResult.ok;
  }
}
