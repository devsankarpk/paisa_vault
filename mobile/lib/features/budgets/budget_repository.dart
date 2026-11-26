import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../../services/notifier.dart';

/// Alert levels, in percent of the budget.
const budgetThresholds = [70, 80, 90, 100];

/// "2026-11": budgets run for one calendar month.
String periodOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// A budget with this month's spending.
class BudgetStatus {
  const BudgetStatus(this.budget, this.spentPaise);
  final Budget budget;
  final int spentPaise;

  int get percent =>
      budget.limitPaise <= 0 ? 0 : (spentPaise * 100 ~/ budget.limitPaise);
}

/// One alert that should be shown now.
class BudgetAlert {
  const BudgetAlert(this.category, this.threshold);
  final String category;
  final int threshold;
}

class BudgetRepository {
  BudgetRepository(this._db, this._clock);
  final AppDatabase _db;
  final Clock _clock;

  /// Sets the monthly limit for a category (adds it, or changes the existing one).
  Future<void> save(String category, int limitPaise) {
    final row = BudgetsCompanion.insert(
      categoryName: category,
      limitPaise: limitPaise,
      createdAt: _clock.now(),
    );
    return _db
        .into(_db.budgets)
        .insert(
          row,
          onConflict: DoUpdate(
            (_) => BudgetsCompanion(limitPaise: Value(limitPaise)),
            target: [_db.budgets.categoryName],
          ),
        );
  }

  Future<void> remove(int id) async {
    final b = await (_db.select(
      _db.budgets,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    if (b == null) return;
    await (_db.delete(_db.budgets)..where((x) => x.id.equals(id))).go();
    await (_db.delete(
      _db.budgetAlertLog,
    )..where((l) => l.categoryName.equals(b.categoryName))).go();
  }

  /// Money going out in [category] during the month of [when]. Own-account transfers do not count.
  Future<int> spent(String category, DateTime when) async {
    final start = DateTime(when.year, when.month);
    final end = DateTime(when.year, when.month + 1);
    final total = _db.transactions.amountPaise.sum();
    final row =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([total])
              ..where(
                _db.transactions.categoryName.equals(category) &
                    _db.transactions.direction.equals(Direction.debit.name) &
                    _db.transactions.selfTransfer.equals(false) &
                    _db.transactions.occurredAt.isBiggerOrEqualValue(start) &
                    _db.transactions.occurredAt.isSmallerThanValue(end),
              ))
            .getSingle();
    return row.read(total) ?? 0;
  }

  /// Every budget with this month's spending, largest share first.
  Future<List<BudgetStatus>> statuses([DateTime? when]) async {
    final at = when ?? _clock.now();
    final list = await _db.select(_db.budgets).get();
    final out = [
      for (final b in list) BudgetStatus(b, await spent(b.categoryName, at)),
    ];
    out.sort((a, b) => b.percent.compareTo(a.percent));
    return out;
  }

  /// Finds budgets that crossed a new level this month and records it, so each level fires
  /// once per month. When spending jumps over several levels, only the highest is returned
  /// (the lower ones are recorded as done).
  Future<List<BudgetAlert>> newAlerts() async {
    final now = _clock.now();
    final period = periodOf(now);
    final alerts = <BudgetAlert>[];
    for (final s in await statuses(now)) {
      final reached = budgetThresholds.where((t) => s.percent >= t).toList();
      if (reached.isEmpty) continue;
      final fired =
          (await (_db.select(_db.budgetAlertLog)..where(
                    (l) =>
                        l.categoryName.equals(s.budget.categoryName) &
                        l.period.equals(period),
                  ))
                  .get())
              .map((l) => l.threshold)
              .toSet();
      final fresh = reached.where((t) => !fired.contains(t)).toList();
      if (fresh.isEmpty) continue;
      for (final t in fresh) {
        await _db
            .into(_db.budgetAlertLog)
            .insert(
              BudgetAlertLogCompanion.insert(
                categoryName: s.budget.categoryName,
                period: period,
                threshold: t,
                firedAt: now,
              ),
            );
      }
      alerts.add(BudgetAlert(s.budget.categoryName, fresh.last));
    }
    return alerts;
  }
}

/// Turns newly crossed budget levels into notifications. The text names only the category and
/// the percentage, never amounts or merchants, because notifications show on the lock screen.
class BudgetAlerter {
  BudgetAlerter(this._budgets, this._notifier);
  final BudgetRepository _budgets;
  final AlertNotifier _notifier;

  /// Returns how many notifications were shown.
  Future<int> run() async {
    final alerts = await _budgets.newAlerts();
    for (final a in alerts) {
      await _notifier.show(
        id: a.category.hashCode ^ a.threshold,
        title: '${a.category} budget',
        body: a.threshold >= 100
            ? 'You have used all of this month\'s ${a.category} budget.'
            : 'You have used ${a.threshold}% of this month\'s ${a.category} budget.',
      );
    }
    return alerts.length;
  }
}
