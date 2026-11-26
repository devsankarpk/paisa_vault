import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../budgets/providers.dart';
import '../categories/providers.dart';
import 'format.dart';
import 'providers.dart';
import 'rule_amount.dart';

Future<void> showEditTransactionSheet(BuildContext context, Transaction tx) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EditSheet(tx),
  );
}

class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet(this.tx);
  final Transaction tx;

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final _merchant = TextEditingController(text: widget.tx.merchant ?? '');
  late final _amount = TextEditingController(
    text: formatRupees(widget.tx.amountPaise).replaceAll(',', ''),
  );
  late final _note = TextEditingController(text: widget.tx.note ?? '');
  late String? _category = widget.tx.categoryName;
  late Direction _direction = widget.tx.direction;
  bool _always = false;
  String? _error;

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The visible categories, plus this transaction's own one if it has since been hidden.
  List<String> _choices() {
    final names = namesOrDefault(ref.watch(categoryNamesProvider));
    final own = _category;
    return own != null && !names.contains(own) ? [...names, own] : names;
  }

  Future<void> _save() async {
    final paise = rupeesToPaise(_amount.text);
    if (paise == null || paise <= 0) {
      setState(() => _error = 'Enter an amount like 499 or 499.50');
      return;
    }
    final repo = await ref.read(transactionRepositoryProvider.future);
    await repo.correct(
      widget.tx.id,
      merchant: _merchant.text.trim(),
      categoryName: _category,
      direction: _direction,
      amountPaise: paise,
      note: _note.text.trim(),
    );
    final merchant = _merchant.text.trim();
    if (_always && _category != null && merchant.isNotEmpty) {
      await repo.saveRule(merchant, _category!);
    }
    await runBudgetAlerts(
      ref.read(budgetRepositoryProvider.future),
      ref.read(notifierProvider),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Correct transaction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SegmentedButton<Direction>(
              segments: const [
                ButtonSegment(value: Direction.debit, label: Text('Money out')),
                ButtonSegment(value: Direction.credit, label: Text('Money in')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                errorText: _error,
              ),
            ),
            TextField(
              controller: _merchant,
              decoration: const InputDecoration(labelText: 'Merchant'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in _choices())
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            if (_merchant.text.trim().isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Always use this category for this merchant'),
                value: _always,
                onChanged: (v) => setState(() => _always = v ?? false),
              ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
