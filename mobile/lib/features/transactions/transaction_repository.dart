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

class TransactionRepository {
  TransactionRepository(this._db, this._clock);
  final AppDatabase _db;
  final Clock _clock;

  Future<int> insertExtracted(
    ExtractedTransaction t, {
    required int rawMessageId,
    required DateTime receivedAt,
  }) {
    final when = t.date ?? receivedAt;
    return _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            rawMessageId: Value(rawMessageId),
            amountPaise: t.amountPaise,
            direction: t.direction,
            channel: Value(t.channel),
            merchant: Value(t.merchant),
            status: Value(t.status),
            reference: Value(t.reference),
            bankCode: Value(t.bank),
            last4: Value(t.last4),
            accountKind: Value(t.accountKind.name),
            categoryName: Value(t.category),
            confirmReason: Value(t.confirmReason),
            modelId: Value(t.modelId),
            promptVersion: Value(t.promptVersion),
            fingerprint: fingerprintOf(t, when),
            occurredAt: when,
            createdAt: _clock.now(),
          ),
        );
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
