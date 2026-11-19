import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../../services/sms_source.dart';

class RawMessageRepository {
  RawMessageRepository(this._db, this._clock);
  final AppDatabase _db;
  final Clock _clock;

  /// Two saves of the same text this close together are one SMS (two Shortcut automations).
  static const duplicateWindow = Duration(minutes: 2);

  static String hashOf(String sender, String body) =>
      sha256.convert(utf8.encode('${sender.toUpperCase()}\n$body')).toString();

  /// Saves the message. Returns its id, or null when it is a repeat of one just saved.
  Future<int?> save(IncomingSms sms) async {
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
            createdAt: _clock.now(),
          ),
        );
  }
}

/// Moves staged messages into the database, then tells the native side they are safe.
class SmsIngest {
  SmsIngest(this._source, this._repo);
  final SmsSource _source;
  final RawMessageRepository _repo;
  bool _running = false;

  /// Returns how many new messages were saved.
  Future<int> drain() async {
    if (_running) return 0;
    _running = true;
    try {
      final staged = await _source.pending();
      var saved = 0;
      final done = <String>[];
      for (final s in staged) {
        if (await _repo.save(s.sms) != null) saved++;
        done.add(s.id);
      }
      if (done.isNotEmpty) await _source.acknowledge(done);
      return saved;
    } finally {
      _running = false;
    }
  }
}
