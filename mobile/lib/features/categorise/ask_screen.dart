import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../budgets/providers.dart';
import '../transactions/format.dart';
import '../transactions/providers.dart';
import '../transactions/transaction_repository.dart';

/// Transactions that still have no category. Always on top of the list screen as a banner.
final uncategorisedProvider = StreamProvider<List<Transaction>>((ref) async* {
  final repo = await ref.watch(transactionRepositoryProvider.future);
  yield* repo.watchUncategorised();
});

/// "What was this?": one card per transaction waiting for a category.
class AskScreen extends ConsumerWidget {
  const AskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(uncategorisedProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'What was this?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nothing to answer. Every transaction has a category.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PvColors.muted, fontSize: 16),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  AskCard(key: ValueKey(list[i].id), tx: list[i]),
            ),
    );
  }
}

class AskCard extends ConsumerStatefulWidget {
  const AskCard({super.key, required this.tx});
  final Transaction tx;

  @override
  ConsumerState<AskCard> createState() => _AskCardState();
}

class _AskCardState extends ConsumerState<AskCard> {
  bool _always = true;

  Future<void> _pick(String category) async {
    final repo = await ref.read(transactionRepositoryProvider.future);
    await repo.answer(widget.tx, category, always: _always);
    await runBudgetAlerts(
      ref.read(budgetRepositoryProvider.future),
      ref.read(notifierProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tx;
    final credit = t.direction == Direction.credit;
    final merchant = t.merchant;
    final what = merchant == null || merchant.trim().isEmpty
        ? (credit ? 'received' : 'paid')
        : (credit ? 'received from $merchant' : 'paid to $merchant');
    final choices = credit
        ? const ['Income', 'Transfer', 'Other']
        : defaultCategories.where((c) => c != 'Income').toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₹${formatRupees(t.amountPaise)} $what',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            formatDate(t.occurredAt),
            style: const TextStyle(color: PvColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in choices)
                ActionChip(label: Text(c), onPressed: () => _pick(c)),
            ],
          ),
          if (merchant != null && merchant.trim().isNotEmpty)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('Always use this category for $merchant'),
              value: _always,
              onChanged: (v) => setState(() => _always = v),
            ),
        ],
      ),
    );
  }
}
