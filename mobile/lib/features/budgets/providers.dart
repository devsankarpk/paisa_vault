import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../services/notifier.dart';
import '../transactions/providers.dart';
import 'budget_repository.dart';

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return BudgetRepository(db, ref.watch(clockProvider));
});

/// Budgets with this month's spending. Recomputed whenever transactions change.
final budgetStatusesProvider = FutureProvider<List<BudgetStatus>>((ref) async {
  ref.watch(transactionsProvider);
  final repo = await ref.watch(budgetRepositoryProvider.future);
  return repo.statuses();
});

/// Shows a notification for any budget level newly crossed. Safe to call often: each level
/// fires once a month. Never throws, so a notification problem cannot stop SMS handling.
Future<void> runBudgetAlerts(
  Future<BudgetRepository> repo,
  AlertNotifier notifier,
) async {
  try {
    await BudgetAlerter(await repo, notifier).run();
  } catch (_) {}
}
