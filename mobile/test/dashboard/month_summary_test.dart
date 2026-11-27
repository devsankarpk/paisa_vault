import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/app_database.dart';
import 'package:paisa_vault/features/dashboard/month_summary.dart';

Transaction tx(
  int rs,
  Direction d,
  DateTime on, {
  String? category,
  bool selfTransfer = false,
}) => Transaction(
  id: on.millisecondsSinceEpoch + rs,
  amountPaise: rs * 100,
  currency: 'INR',
  direction: d,
  status: TransactionStatus.confirmed,
  categoryName: category,
  userCorrected: false,
  fingerprint: 'f$rs${on.day}',
  occurredAt: on,
  createdAt: on,
  selfTransfer: selfTransfer,
  shared: false,
);

void main() {
  final nov = DateTime(2026, 11, 10);
  test('earning, spend, savings and category split for one month', () {
    final s = summariseMonth([
      tx(1000, Direction.credit, DateTime(2026, 11, 1), category: 'Income'),
      tx(300, Direction.debit, DateTime(2026, 11, 2), category: 'Food'),
      tx(100, Direction.debit, DateTime(2026, 11, 3), category: 'Food'),
      tx(100, Direction.debit, DateTime(2026, 11, 4)),
      tx(500, Direction.debit, DateTime(2026, 11, 5), category: 'Transfer'),
      tx(700, Direction.debit, DateTime(2026, 11, 6), selfTransfer: true),
      tx(999, Direction.debit, DateTime(2026, 10, 31), category: 'Food'),
      tx(999, Direction.debit, DateTime(2026, 12, 1), category: 'Food'),
    ], nov);
    expect(s.earningPaise, 100000);
    expect(s.spendPaise, 50000);
    expect(s.savingsPaise, 50000);
    expect(s.byCategory.map((c) => c.name), ['Food', uncategorisedLabel]);
    expect(s.percentOf(s.byCategory.first), 80);
  });

  test('an empty month is empty and has no percentages', () {
    final s = summariseMonth([], nov);
    expect(s.isEmpty, isTrue);
    expect(s.savingsPaise, 0);
  });
}
