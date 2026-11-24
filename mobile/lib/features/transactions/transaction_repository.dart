import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../pipeline/extraction_pipeline.dart';

/// The default category list (decision D4). Becomes user-editable in Phase 1B.
const defaultCategories = [
  'Food',
  'Groceries',
  'Shopping',
  'Bills',
  'Travel',
  'Health',
  'Entertainment',
  'Other',
  'Income',
  'Transfer',
];

/// Hash of bank, last 4, amount, reference and date, used to spot the same transaction twice.
String fingerprintOf(ExtractedTransaction t, DateTime when) {
  final day = '${when.year}-${when.month}-${when.day}';
  return sha256
      .convert(
        utf8.encode(
          '${t.bank}|${t.last4}|${t.amountPaise}|${t.reference}|$day',
        ),
      )
      .toString();
}

const _bankNames = {
  'HDFC': 'HDFC Bank',
  'SBI': 'State Bank of India',
  'YES': 'Yes Bank',
  'RBL': 'RBL Bank',
  'INDIAN': 'Indian Bank',
  'ICICI': 'ICICI Bank',
  'AXIS': 'Axis Bank',
};

class TransactionRepository {
  TransactionRepository(this._db, this._clock);
  final AppDatabase _db;
  final Clock _clock;

  /// Stores a transaction and links it to its account (bank + last 4).
  ///
  /// Returns null when it is a duplicate of one already stored: same bank, last 4, amount, day
  /// and bank reference number. Without a reference number nothing is treated as a duplicate,
  /// because two identical payments on one day can be real.
  Future<int?> insertExtracted(
    ExtractedTransaction t, {
    required int rawMessageId,
    required DateTime receivedAt,
  }) async {
    final when = t.date ?? receivedAt;
    final fingerprint = fingerprintOf(t, when);
    if (t.reference != null && t.bank != null && t.last4 != null) {
      final same =
          await (_db.select(_db.transactions)
                ..where((x) => x.fingerprint.equals(fingerprint))
                ..limit(1))
              .getSingleOrNull();
      if (same != null) return null;
    }
    final accountId = await accountFor(t.bank, t.last4, t.accountKind);
    return _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            rawMessageId: Value(rawMessageId),
            amountPaise: t.amountPaise,
            direction: t.direction,
            channel: Value(t.channel),
            merchant: Value(t.merchant),
            accountId: Value(accountId),
            status: Value(t.status),
            reference: Value(t.reference),
            bankCode: Value(t.bank),
            last4: Value(t.last4),
            accountKind: Value(t.accountKind.name),
            categoryName: Value(t.category),
            confirmReason: Value(t.confirmReason),
            modelId: Value(t.modelId),
            promptVersion: Value(t.promptVersion),
            fingerprint: fingerprint,
            occurredAt: when,
            createdAt: _clock.now(),
          ),
        );
  }

  /// Finds the account for a bank code and last 4, creating it (as pending, for the user to
  /// confirm later) when it is new. Null when the message did not give both.
  Future<int?> accountFor(
    String? bankCode,
    String? last4,
    AccountKind kind,
  ) async {
    if (bankCode == null || last4 == null) return null;
    var bank = await (_db.select(
      _db.banks,
    )..where((b) => b.code.equals(bankCode))).getSingleOrNull();
    bank ??= await _db
        .into(_db.banks)
        .insertReturning(
          BanksCompanion.insert(
            code: bankCode,
            name: _bankNames[bankCode] ?? bankCode,
          ),
        );
    final existing =
        await (_db.select(_db.accounts)
              ..where((a) => a.bankId.equals(bank!.id) & a.last4.equals(last4))
              ..orderBy([(a) => OrderingTerm.asc(a.id)])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            bankId: Value(bank.id),
            kind: kind,
            last4: last4,
            status: const Value(AccountStatus.pending),
            createdAt: _clock.now(),
          ),
        );
  }

  /// Links transactions saved before accounts existed. Returns how many were linked.
  Future<int> linkUnlinked() async {
    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.accountId.isNull() &
                  t.bankCode.isNotNull() &
                  t.last4.isNotNull(),
            ))
            .get();
    var n = 0;
    for (final t in rows) {
      final kind =
          AccountKind.values.asNameMap()[t.accountKind] ?? AccountKind.savings;
      final id = await accountFor(t.bankCode, t.last4, kind);
      if (id == null) continue;
      await (_db.update(_db.transactions)..where((x) => x.id.equals(t.id)))
          .write(TransactionsCompanion(accountId: Value(id)));
      n++;
    }
    return n;
  }

  /// Newest first.
  Stream<List<Transaction>> watchAll() {
    return (_db.select(_db.transactions)..orderBy([
          (t) => OrderingTerm.desc(t.occurredAt),
          (t) => OrderingTerm.desc(t.id),
        ]))
        .watch();
  }

  Stream<Transaction?> watchOne(int id) => (_db.select(
    _db.transactions,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<RawMessage?> rawMessageFor(Transaction t) async {
    final id = t.rawMessageId;
    if (id == null) return null;
    return (_db.select(
      _db.rawMessages,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  /// A user edit. Marks the transaction confirmed and corrected so a later re-check keeps it.
  Future<void> correct(
    int id, {
    String? merchant,
    String? categoryName,
    Direction? direction,
    int? amountPaise,
    String? note,
  }) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        merchant: merchant == null
            ? const Value.absent()
            : Value(merchant.isEmpty ? null : merchant),
        categoryName: categoryName == null
            ? const Value.absent()
            : Value(categoryName),
        direction: direction == null ? const Value.absent() : Value(direction),
        amountPaise: amountPaise == null
            ? const Value.absent()
            : Value(amountPaise),
        note: note == null
            ? const Value.absent()
            : Value(note.isEmpty ? null : note),
        status: const Value(TransactionStatus.confirmed),
        userCorrected: const Value(true),
      ),
    );
  }
}
