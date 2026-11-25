import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../../services/sms_source.dart';
import 'sms_classifier.dart';

class RawMessageRepository {
  RawMessageRepository(this._db, this._clock);
  final AppDatabase _db;
  final Clock _clock;

  /// Two saves of the same text this close together are one SMS (two Shortcut automations).
  static const duplicateWindow = Duration(minutes: 2);

  /// Saved message text is kept this long for re-checks, then deleted (policy: 30 to 90 days).
  static const retention = Duration(days: 60);

  /// Deletes message text received before [cutoff] that is already processed or ignored. The
  /// transactions made from it stay, and just lose the link to the original text. Returns how
  /// many messages were deleted.
  Future<int> purgeOlderThan(DateTime cutoff) async {
    final old =
        await (_db.select(_db.rawMessages)..where(
              (m) =>
                  m.receivedAt.isSmallerThanValue(cutoff) &
                  m.status.equals(RawMessageStatus.newMessage.name).not(),
            ))
            .get();
    if (old.isEmpty) return 0;
    final ids = old.map((m) => m.id).toList();
    return _db.transaction(() async {
      await (_db.update(_db.transactions)
            ..where((t) => t.rawMessageId.isIn(ids)))
          .write(const TransactionsCompanion(rawMessageId: Value(null)));
      return (_db.delete(_db.rawMessages)..where((m) => m.id.isIn(ids))).go();
    });
  }

  /// When the app last saved a message from the phone, or null if it never has. Used to spot a
  /// Shortcuts automation that has stopped running.
  Future<DateTime?> lastSavedAt() async {
    final latest = _db.rawMessages.createdAt.max();
    final row = await (_db.selectOnly(
      _db.rawMessages,
    )..addColumns([latest])).getSingle();
    return row.read(latest);
  }

  static String hashOf(String sender, String body) =>
      sha256.convert(utf8.encode('${sender.toUpperCase()}\n$body')).toString();

  /// Saves the message. Returns its id, or null when it is a repeat of one just saved.
  Future<int?> save(
    IncomingSms sms, {
    RawMessageStatus status = RawMessageStatus.newMessage,
  }) async {
    final hash = hashOf(sms.sender, sms.body);
    final since = sms.receivedAt.subtract(duplicateWindow);
    final until = sms.receivedAt.add(duplicateWindow);
    final repeat =
        await (_db.select(_db.rawMessages)
              ..where(
                (m) =>
                    m.contentHash.equals(hash) &
                    m.receivedAt.isBetweenValues(since, until),
              )
              ..limit(1))
            .get();
    if (repeat.isNotEmpty) return null;
    return _db
        .into(_db.rawMessages)
        .insert(
          RawMessagesCompanion.insert(
            sender: sms.sender,
            body: sms.body,
            receivedAt: sms.receivedAt,
            simSubscriptionId: Value(sms.simSubscriptionId),
            contentHash: hash,
            status: Value(status),
            createdAt: _clock.now(),
          ),
        );
  }
}

/// What one drain did. Counts only.
class IngestResult {
  const IngestResult({
    required this.saved,
    required this.dropped,
    required this.byKind,
  });
  final int saved;
  final int dropped;
  final Map<SmsKind, int> byKind;
}

/// Moves staged messages into the database, then tells the native side they are safe.
/// OTP and promotional messages are dropped without being stored.
class SmsIngest {
  SmsIngest(
    this._source,
    this._repo, [
    this._classifier = const SmsClassifier(),
  ]);
  final SmsSource _source;
  final RawMessageRepository _repo;
  final SmsClassifier _classifier;
  bool _running = false;

  Future<IngestResult> drain() async {
    if (_running) return const IngestResult(saved: 0, dropped: 0, byKind: {});
    _running = true;
    try {
      final staged = await _source.pending();
      var saved = 0;
      var dropped = 0;
      final byKind = <SmsKind, int>{};
      final done = <String>[];
      for (final s in staged) {
        final kind = _classifier
            .classify(s.sms.body, sender: s.sms.sender)
            .kind;
        byKind[kind] = (byKind[kind] ?? 0) + 1;
        if (kind == SmsKind.otp || kind == SmsKind.promo) {
          dropped++;
        } else {
          final status = kind == SmsKind.transaction
              ? RawMessageStatus.newMessage
              : RawMessageStatus.ignored;
          if (await _repo.save(s.sms, status: status) != null) saved++;
        }
        done.add(s.id);
      }
      if (done.isNotEmpty) await _source.acknowledge(done);
      return IngestResult(saved: saved, dropped: dropped, byKind: byKind);
    } finally {
      _running = false;
    }
  }
}
