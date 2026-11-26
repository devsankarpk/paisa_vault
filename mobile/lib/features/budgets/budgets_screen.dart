import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../categories/providers.dart';
import '../transactions/format.dart';
import '../transactions/rule_amount.dart';
import 'budget_repository.dart';
import 'providers.dart';

/// Monthly spending limits per category, with how much of each is used so far.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    BudgetStatus? existing,
  }) async {
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => _BudgetDialog(existing: existing),
    );
    if (result == null) return;
    final repo = await ref.read(budgetRepositoryProvider.future);
    await repo.save(result.$1, result.$2);
    // Alerts need permission. Ask once, now that the user has a reason to want them.
    await ref.read(notifierProvider).requestPermission();
    ref.invalidate(budgetStatusesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(budgetStatusesProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budgets',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No budgets yet.\nSet a monthly limit for a category and get an alert at 70, 80, 90 and 100%.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: PvColors.muted,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = list[i];
                final over = s.percent >= 100;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _edit(context, ref, existing: s),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.budget.categoryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${s.percent}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: over ? PvColors.error : PvColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (s.percent / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            color: over ? PvColors.error : PvColors.primary,
                            backgroundColor: const Color(0xFFE8EEFF),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${formatRupees(s.spentPaise)} of ₹${formatRupees(s.budget.limitPaise)} this month',
                            style: const TextStyle(color: PvColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BudgetDialog extends ConsumerStatefulWidget {
  const _BudgetDialog({this.existing});
  final BudgetStatus? existing;

  @override
  ConsumerState<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<_BudgetDialog> {
  late String? _category = widget.existing?.budget.categoryName;
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : formatRupees(widget.existing!.budget.limitPaise)
              .replaceAll(',', '')
              .replaceAll(RegExp(r'\.00$'), ''),
  );
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final paise = rupeesToPaise(_amount.text);
    if (_category == null) {
      setState(() => _error = 'Choose a category');
    } else if (paise == null || paise <= 0) {
      setState(() => _error = 'Enter an amount like 5000');
    } else {
      Navigator.pop(context, (_category!, paise));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? 'Change budget' : 'Add budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in namesOrDefault(
                ref.watch(categoryNamesProvider),
              ).where((c) => c != 'Income' && c != 'Transfer'))
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: editing ? null : (v) => setState(() => _category = v),
          ),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monthly limit (₹)',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
