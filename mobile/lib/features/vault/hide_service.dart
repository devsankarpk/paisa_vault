import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import 'vault_database.dart';
import 'vault_session.dart';

/// Moves a transaction into vault.db and back. The vault must be open (the caller asks for
/// the PIN first); a locked vault throws StateError. After a hide the transaction is gone from
/// main.db, so no list, total, chart, budget, search, export or household sync can see it.
class HideService {
  HideService(this._main, this._vault, this._clock);
  final AppDatabase _main;
  final VaultSession _vault;
  final Clock _clock;

  /// Hides the transaction. False when it no longer exists.
  Future<bool> hide(int transactionId) async {
    final vault = _vault.db; // throws while locked
    final t = await (_main.select(
      _main.transactions,
    )..where((x) => x.id.equals(transactionId))).getSingleOrNull();
    if (t == null) return false;
    // The vault copy comes first: if the second step fails, nothing is lost.
    await vault.transaction(() async {
      await vault
          .into(vault.hiddenTransactions)
          .insert(
            HiddenTransactionsCompanion.insert(
              amountPaise: t.amountPaise,
              currency: Value(t.currency),
              direction: t.direction,
              channel: Value(t.channel),
              merchant: Value(t.merchant),
              categoryName: Value(t.categoryName),
              bankCode: Value(t.bankCode),
              last4: Value(t.last4),
              accountKind: Value(t.accountKind),
              reference: Value(t.reference),
              note: Value(t.note),
              fingerprint: t.fingerprint,
              occurredAt: t.occurredAt,
              createdAt: _clock.now(),
            ),
          );
      await vault
          .into(vault.hiddenFingerprints)
          .insert(
            HiddenFingerprintsCompanion.insert(
              fingerprint: t.fingerprint,
              createdAt: _clock.now(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    });
    await _main.transaction(() async {
      final raw = t.rawMessageId;
      await (_main.delete(
        _main.transactions,
      )..where((x) => x.id.equals(t.id))).go();
      if (raw != null) {
        final others = await (_main.select(
          _main.transactions,
        )..where((x) => x.rawMessageId.equals(raw))).get();
        if (others.isEmpty) {
          // The SMS text would still show the amount and merchant: blank it. The hash stays so
          // the same SMS saved again is still recognised as a repeat.
          await (_main.update(
            _main.rawMessages,
          )..where((m) => m.id.equals(raw))).write(
            RawMessagesCompanion(
              body: const Value(''),
              status: Value(RawMessageStatus.processed),
            ),
          );
        }
      }
    });
    return true;
  }

  /// Hidden transactions, newest first.
  Future<List<HiddenTransaction>> list() {
    final vault = _vault.db;
    return (vault.select(vault.hiddenTransactions)..orderBy([
          (h) => OrderingTerm.desc(h.occurredAt),
          (h) => OrderingTerm.desc(h.id),
        ]))
        .get();
  }

  /// Puts a hidden transaction back in the normal lists. It comes back as confirmed and
  /// corrected, so a re-check never changes it. If an identical one already exists (the same
  /// SMS arrived again), it is not added twice.
  Future<bool> unhide(int hiddenId) async {
    final vault = _vault.db;
    final h = await (vault.select(
      vault.hiddenTransactions,
    )..where((x) => x.id.equals(hiddenId))).getSingleOrNull();
    if (h == null) return false;
    await _main.transaction(() async {
      final twin = await (_main.select(
        _main.transactions,
      )..where((x) => x.fingerprint.equals(h.fingerprint))).get();
      if (twin.isNotEmpty) return;
      final accountId = await _accountFor(h.bankCode, h.last4);
      await _main
          .into(_main.transactions)
          .insert(
            TransactionsCompanion.insert(
              amountPaise: h.amountPaise,
              currency: Value(h.currency),
              direction: h.direction,
              channel: Value(h.channel),
              merchant: Value(h.merchant),
              accountId: Value(accountId),
              categoryName: Value(h.categoryName),
              bankCode: Value(h.bankCode),
              last4: Value(h.last4),
              accountKind: Value(h.accountKind),
              reference: Value(h.reference),
              note: Value(h.note),
              status: const Value(TransactionStatus.confirmed),
              userCorrected: const Value(true),
              fingerprint: h.fingerprint,
              occurredAt: h.occurredAt,
              createdAt: _clock.now(),
            ),
          );
    });
    await vault.transaction(() async {
      await (vault.delete(
        vault.hiddenTransactions,
      )..where((x) => x.id.equals(hiddenId))).go();
      final more = await (vault.select(
        vault.hiddenTransactions,
      )..where((x) => x.fingerprint.equals(h.fingerprint))).get();
      if (more.isEmpty) {
        await (vault.delete(
          vault.hiddenFingerprints,
        )..where((x) => x.fingerprint.equals(h.fingerprint))).go();
      }
    });
    return true;
  }

  Future<int?> _accountFor(String? bankCode, String? last4) async {
    if (bankCode == null || last4 == null) return null;
    final bank = await (_main.select(
      _main.banks,
    )..where((b) => b.code.equals(bankCode))).getSingleOrNull();
    if (bank == null) return null;
    final account =
        await (_main.select(_main.accounts)
              ..where((a) => a.bankId.equals(bank.id) & a.last4.equals(last4))
              ..orderBy([(a) => OrderingTerm.asc(a.id)])
              ..limit(1))
            .getSingleOrNull();
    return account?.id;
  }
}
