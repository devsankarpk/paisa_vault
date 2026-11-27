import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../categorise/merchant_key.dart';
import '../search/transaction_filter.dart';
import '../pipeline/extraction_pipeline.dart';
import '../pipeline/rule_extractor.dart';

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
    final category = await categorise(t.merchant, t.direction, t.category);
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
            categoryName: Value(category),
            confirmReason: Value(t.confirmReason),
            modelId: Value(t.modelId),
            promptVersion: Value(t.promptVersion),
            fingerprint: fingerprint,
            occurredAt: when,
            createdAt: _clock.now(),
          ),
        );
  }

  /// Text made comparable: lower case, letters and digits only. The same SMS saved by the
  /// Shortcut and by a paste can differ in line breaks, spaces or a trailing newline.
  static String comparable(String body) =>
      body.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  /// True when a different saved message with the same text (ignoring spacing and punctuation)
  /// already made a transaction. The same SMS can be saved twice (two Shortcut automations, or a
  /// paste of one already received); it is one payment.
  Future<bool> sameTextAlreadyCounted(RawMessage m) async {
    final mine = comparable(m.body);
    final near =
        await (_db.select(_db.rawMessages)..where(
              (r) =>
                  r.id.equals(m.id).not() &
                  r.receivedAt.isBiggerOrEqualValue(
                    m.receivedAt.subtract(const Duration(days: 3)),
                  ) &
                  r.receivedAt.isSmallerOrEqualValue(
                    m.receivedAt.add(const Duration(days: 3)),
                  ),
            ))
            .get();
    final same = near.where((r) => comparable(r.body) == mine).toList();
    if (same.isEmpty) return false;
    final made =
        await (_db.select(_db.transactions)
              ..where((t) => t.rawMessageId.isIn(same.map((o) => o.id)))
              ..limit(1))
            .get();
    return made.isNotEmpty;
  }

  /// Removes extra transactions made from messages with the same text, keeping the one you
  /// edited, or else the oldest. Returns how many were removed.
  Future<int> removeSameTextDuplicates() async {
    final rows = await _db
        .customSelect(
          'SELECT t.id AS id, r.body AS body, t.user_corrected AS corrected '
          'FROM transactions t JOIN raw_messages r ON r.id = t.raw_message_id',
        )
        .get();
    final groups = <String, List<({int id, bool corrected})>>{};
    for (final r in rows) {
      groups.putIfAbsent(comparable(r.read<String>('body')), () => []).add((
        id: r.read<int>('id'),
        corrected: r.read<bool>('corrected'),
      ));
    }
    var removed = 0;
    for (final g in groups.values) {
      if (g.length < 2) continue;
      g.sort((a, b) {
        if (a.corrected != b.corrected) return a.corrected ? -1 : 1;
        return a.id.compareTo(b.id);
      });
      for (final extra in g.skip(1)) {
        if (extra.corrected) continue; // never delete something the user edited
        await (_db.delete(
          _db.transactions,
        )..where((t) => t.id.equals(extra.id))).go();
        removed++;
      }
    }
    return removed;
  }

  /// Removes extra transactions that are the same payment saved from two differently worded
  /// copies of one SMS (for example a pasted copy and the shortcut copy). Only rows with no
  /// reference number, the same amount, direction, day, card digits and merchant, and never
  /// one you edited. Keeps the edited one, or else the oldest. Returns how many were removed.
  Future<int> removeLookalikeDuplicates() async {
    final all = await (_db.select(
      _db.transactions,
    )..where((t) => t.reference.isNull())).get();
    // Same payment: amount, direction, day and card digits. The merchant may be missing on one.
    final groups = <String, List<Transaction>>{};
    for (final t in all) {
      final d = t.occurredAt.toLocal();
      final key =
          '${t.amountPaise}|${t.direction.name}|${d.year}-${d.month}-${d.day}|${t.last4 ?? ''}';
      groups.putIfAbsent(key, () => []).add(t);
    }
    var removed = 0;
    Future<void> drop(Transaction t) async {
      await (_db.delete(
        _db.transactions,
      )..where((x) => x.id.equals(t.id))).go();
      removed++;
    }

    int order(Transaction a, Transaction b) {
      if (a.userCorrected != b.userCorrected) return a.userCorrected ? -1 : 1;
      return a.id.compareTo(b.id);
    }

    for (final g in groups.values) {
      if (g.length < 2) continue;
      final named = g.where((t) => merchantKey(t.merchant ?? '').isNotEmpty);
      final blank = g.where((t) => merchantKey(t.merchant ?? '').isEmpty);
      // A row with no merchant next to one that has a merchant is the same payment.
      if (named.isNotEmpty) {
        for (final t in blank) {
          if (!t.userCorrected) await drop(t);
        }
      }
      final byMerchant = <String, List<Transaction>>{};
      for (final t in named) {
        byMerchant.putIfAbsent(merchantKey(t.merchant!), () => []).add(t);
      }
      for (final m in byMerchant.values) {
        if (m.length < 2) continue;
        m.sort(order);
        for (final extra in m.skip(1)) {
          if (!extra.userCorrected) await drop(extra);
        }
      }
    }
    return removed;
  }

  /// A transaction you already have that looks like the one in [body]: same amount, same
  /// direction, same day, and the same last 4 when both messages give one. Null when none, or
  /// when the text has no clear amount and direction. Used before adding a pasted message.
  Future<Transaction?> findLikelyDuplicate(String body, DateTime today) async {
    final f = const RuleExtractor().extract(body);
    final amount = f.amountPaise;
    final direction = f.direction;
    if (amount == null || direction == null) return null;
    final day = f.date ?? today;
    final start = DateTime(day.year, day.month, day.day);
    final same =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.amountPaise.equals(amount) &
                  t.direction.equals(direction.name) &
                  t.occurredAt.isBiggerOrEqualValue(start) &
                  t.occurredAt.isSmallerThanValue(
                    DateTime(day.year, day.month, day.day + 1),
                  ),
            ))
            .get();
    for (final t in same) {
      if (f.last4 == null || t.last4 == null || f.last4 == t.last4) return t;
    }
    return null;
  }

  /// Picks a category in this order: a rule the user made, a similar merchant the user already
  /// categorised, then the model's suggestion. Null means "ask the user". Money coming in is
  /// never put in an expense category: only Income or Transfer are accepted for it.
  Future<String?> categorise(
    String? merchant,
    Direction direction,
    String? modelCategory,
  ) async {
    bool fits(String? c) =>
        c != null &&
        (direction == Direction.debit || c == 'Income' || c == 'Transfer');
    final key = merchantKey(merchant);
    if (key.isNotEmpty) {
      final rules = await _db.select(_db.merchantRules).get();
      // An exact rule wins over a looser one ("SWIGGY INSTAMART" over "SWIGGY").
      rules.sort(
        (a, b) => b.merchantKey.length.compareTo(a.merchantKey.length),
      );
      for (final r in rules) {
        if (sameMerchant(key, r.merchantKey) && fits(r.categoryName)) {
          return r.categoryName;
        }
      }
      final past =
          await (_db.select(_db.transactions)
                ..where(
                  (t) =>
                      t.userCorrected.equals(true) &
                      t.categoryName.isNotNull() &
                      t.merchant.isNotNull(),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.id)]))
              .get();
      for (final p in past) {
        if (p.direction == direction &&
            sameMerchant(key, merchantKey(p.merchant))) {
          return p.categoryName;
        }
      }
    }
    return fits(modelCategory) ? modelCategory : null;
  }

  /// Remembers that [merchant] always gets [category], and applies it to transactions that are
  /// still waiting for a category. Returns how many of those were updated.
  Future<int> saveRule(String merchant, String category) async {
    final key = merchantKey(merchant);
    if (key.isEmpty) return 0;
    await _db
        .into(_db.merchantRules)
        .insert(
          MerchantRulesCompanion.insert(
            merchantKey: key,
            categoryName: category,
            createdAt: _clock.now(),
          ),
          onConflict: DoUpdate(
            (_) => MerchantRulesCompanion(categoryName: Value(category)),
            target: [_db.merchantRules.merchantKey],
          ),
        );
    final waiting =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.categoryName.isNull() &
                  t.userCorrected.equals(false) &
                  t.merchant.isNotNull(),
            ))
            .get();
    var n = 0;
    for (final t in waiting) {
      if (!sameMerchant(key, merchantKey(t.merchant))) continue;
      if (t.direction == Direction.credit &&
          category != 'Income' &&
          category != 'Transfer') {
        continue;
      }
      await (_db.update(_db.transactions)..where((x) => x.id.equals(t.id)))
          .write(TransactionsCompanion(categoryName: Value(category)));
      n++;
    }
    return n;
  }

  /// Transactions with no category, newest first: the "What was this?" questions.
  Stream<List<Transaction>> watchUncategorised() =>
      (_db.select(_db.transactions)
            ..where((t) => t.categoryName.isNull())
            ..orderBy([
              (t) => OrderingTerm.desc(t.occurredAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  /// The user's answer to "What was this?". With [always], the merchant is remembered.
  Future<void> answer(
    Transaction t,
    String category, {
    String? note,
    bool always = false,
  }) async {
    await correct(t.id, categoryName: category, note: note);
    if (always && t.merchant != null && t.merchant!.trim().isNotEmpty) {
      await saveRule(t.merchant!, category);
    }
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

  /// Re-reads bank and last 4 from the saved message for transactions that are missing them,
  /// after the rules got better. Fills only empty fields; never changes a value that is there.
  /// Returns how many transactions were updated.
  Future<int> refillRuleFields() async {
    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  (t.last4.isNull() | t.bankCode.isNull()) &
                  t.rawMessageId.isNotNull(),
            ))
            .get();
    var n = 0;
    for (final t in rows) {
      final raw = await (_db.select(
        _db.rawMessages,
      )..where((m) => m.id.equals(t.rawMessageId!))).getSingleOrNull();
      if (raw == null) continue;
      final f = const RuleExtractor().extract(raw.body);
      final bank = t.bankCode ?? f.bank;
      final last4 = t.last4 ?? f.last4;
      if (bank == t.bankCode && last4 == t.last4) continue;
      await (_db.update(
        _db.transactions,
      )..where((x) => x.id.equals(t.id))).write(
        TransactionsCompanion(bankCode: Value(bank), last4: Value(last4)),
      );
      n++;
    }
    return n;
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

  /// Transactions matching every filter that is set, newest first. Dates include both end days.
  Future<List<Transaction>> search(TransactionFilter f) {
    final q = _db.select(_db.transactions);
    final from = f.from;
    final to = f.to;
    final category = f.category;
    final amount = f.amountPaise;
    // "%" and "_" typed by the user are plain characters, not wildcards.
    final text = f.text.trim().replaceAll(RegExp(r'[%_]'), '');
    q.where((t) {
      Expression<bool> ok = const Constant(true);
      if (from != null) {
        ok &= t.occurredAt.isBiggerOrEqualValue(
          DateTime(from.year, from.month, from.day),
        );
      }
      if (to != null) {
        ok &= t.occurredAt.isSmallerThanValue(
          DateTime(to.year, to.month, to.day + 1),
        );
      }
      if (category != null) ok &= t.categoryName.equals(category);
      if (amount != null) ok &= t.amountPaise.equals(amount);
      if (text.isNotEmpty) {
        ok &= t.merchant.like('%$text%') | t.note.like('%$text%');
      }
      return ok;
    });
    q.orderBy([
      (t) => OrderingTerm.desc(t.occurredAt),
      (t) => OrderingTerm.desc(t.id),
    ]);
    return q.get();
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
