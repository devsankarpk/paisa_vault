import '../../core/db/app_database.dart';

/// Where one category's spending stands in a month.
class CategorySpend {
  const CategorySpend(this.name, this.paise);
  final String name;
  final int paise;
}

/// Earning, spending and savings for one calendar month, from the transactions.
/// Transfers between your own accounts do not count either way.
class MonthSummary {
  const MonthSummary({
    required this.earningPaise,
    required this.spendPaise,
    required this.byCategory,
  });
  final int earningPaise;
  final int spendPaise;

  /// Spending by category, largest first. Uncategorised money out is listed as "Uncategorised".
  final List<CategorySpend> byCategory;

  int get savingsPaise => earningPaise - spendPaise;
  bool get isEmpty => earningPaise == 0 && spendPaise == 0;

  /// Percentage of spending for a category, rounded; 0 when nothing was spent.
  int percentOf(CategorySpend c) =>
      spendPaise <= 0 ? 0 : (c.paise * 100 / spendPaise).round();
}

const uncategorisedLabel = 'Uncategorised';

MonthSummary summariseMonth(List<Transaction> all, DateTime month) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  var earning = 0;
  var spend = 0;
  final by = <String, int>{};
  for (final t in all) {
    if (t.selfTransfer || t.categoryName == 'Transfer') continue;
    final at = t.occurredAt.toLocal();
    if (at.isBefore(start) || !at.isBefore(end)) continue;
    if (t.direction == Direction.credit) {
      earning += t.amountPaise;
    } else {
      spend += t.amountPaise;
      final name = t.categoryName ?? uncategorisedLabel;
      by[name] = (by[name] ?? 0) + t.amountPaise;
    }
  }
  final list = [for (final e in by.entries) CategorySpend(e.key, e.value)]
    ..sort((a, b) => b.paise.compareTo(a.paise));
  return MonthSummary(
    earningPaise: earning,
    spendPaise: spend,
    byCategory: list,
  );
}
