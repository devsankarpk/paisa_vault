import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../../services/notifier.dart';

/// Tells the user when a transaction needs a category. One new transaction is announced at
/// once. Several waiting at the same time are grouped into one reminder a day, shown from
/// [eveningHour] on. The text never names a merchant or an amount, so it is safe on a lock screen.
class UncategorisedAlerter {
  UncategorisedAlerter(this._db, this._clock, this._notifier);
  final AppDatabase _db;
  final Clock _clock;
  final AlertNotifier _notifier;

  static const eveningHour = 18;
  static const _lastIdKey = 'uncat_alert_last_id';
  static const _dayKey = 'uncat_alert_day';
  static const notificationId = 7001;

  Future<String?> _get(String key) async => (await (_db.select(
    _db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value) => _db
      .into(_db.settings)
      .insert(
        SettingsCompanion.insert(key: key, value: value),
        onConflict: DoUpdate(
          (_) => SettingsCompanion(value: Value(value)),
          target: [_db.settings.key],
        ),
      );

  /// Returns how many notifications were shown (0 or 1).
  Future<int> run() async {
    final ids =
        (await (_db.select(_db.transactions)
                  ..where((t) => t.categoryName.isNull())
                  ..orderBy([(t) => OrderingTerm.asc(t.id)]))
                .get())
            .map((t) => t.id)
            .toList();
    if (ids.isEmpty) return 0;
    final lastId = int.tryParse(await _get(_lastIdKey) ?? '') ?? 0;
    final fresh = ids.where((i) => i > lastId).isNotEmpty;
    if (!fresh) return 0;
    final now = _clock.now();
    if (ids.length == 1) {
      await _notifier.show(
        id: notificationId,
        title: 'What was this?',
        body: 'A transaction needs a category. Open Paisa Vault to choose.',
      );
    } else {
      final today = '${now.year}-${now.month}-${now.day}';
      if (now.hour < eveningHour || await _get(_dayKey) == today) return 0;
      await _notifier.show(
        id: notificationId,
        title: 'Transactions need a category',
        body: '${ids.length} transactions are waiting for a category.',
      );
      await _set(_dayKey, today);
    }
    await _set(_lastIdKey, '${ids.last}');
    return 1;
  }
}

/// Safe to call often. Never throws, so a notification problem cannot stop SMS handling.
Future<void> runUncategorisedAlert(
  Future<AppDatabase> db,
  Clock clock,
  AlertNotifier notifier,
) async {
  try {
    await UncategorisedAlerter(await db, clock, notifier).run();
  } catch (_) {}
}
