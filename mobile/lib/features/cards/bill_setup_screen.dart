import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../transactions/rule_amount.dart';
import 'card_repository.dart';
import 'providers.dart';

/// Credit card bill reminder: statement day, due day, optional limit, days before to remind.
class BillSetupScreen extends ConsumerStatefulWidget {
  const BillSetupScreen({super.key, required this.cardId});
  final int cardId;

  @override
  ConsumerState<BillSetupScreen> createState() => _BillSetupScreenState();
}

class _BillSetupScreenState extends ConsumerState<BillSetupScreen> {
  static const _choices = [7, 5, 3, 2, 1, 0];
  int _statement = 1;
  int _due = 20;
  final _limit = TextEditingController();
  final _remind = <int>{5, 1};
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final b = await (await ref.read(cardRepositoryProvider.future))
        .billFor(widget.cardId);
    if (b != null && mounted) {
      setState(() {
        _statement = b.statementDay;
        _due = b.dueDay;
        _limit.text = b.creditLimitPaise == null
            ? ''
            : (b.creditLimitPaise! / 100).toStringAsFixed(
                b.creditLimitPaise! % 100 == 0 ? 0 : 2,
              );
        _remind
          ..clear()
          ..addAll(
            b.reminderDays.isEmpty
                ? const <int>[]
                : b.reminderDays.split(',').map(int.parse),
          );
      });
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _save() async {
    int? limit;
    if (_limit.text.trim().isNotEmpty) {
      limit = rupeesToPaise(_limit.text);
      if (limit == null || limit <= 0) {
        setState(
          () => _error =
              'Enter the limit as a positive amount, or leave it empty',
        );
        return;
      }
    }
    final r = await (await ref.read(cardRepositoryProvider.future)).saveBill(
      widget.cardId,
      statementDay: _statement,
      dueDay: _due,
      creditLimitPaise: limit,
      reminderDays: _remind.toList(),
    );
    if (!mounted) return;
    if (r != CardResult.ok) {
      setState(() => _error = 'Could not save the reminder');
      return;
    }
    Navigator.of(context).pop();
  }

  Widget _day(String label, int value, ValueChanged<int> onChanged) =>
      DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var d = 1; d <= 31; d++)
            DropdownMenuItem(value: d, child: Text('Day $d')),
        ],
        onChanged: (v) => onChanged(v ?? value),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bill reminder',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Days are days of the month. Reminders are shown on this phone only.',
                  style: TextStyle(color: PvColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                _day(
                  'Statement day',
                  _statement,
                  (v) => setState(() => _statement = v),
                ),
                const SizedBox(height: 12),
                _day('Payment due day', _due, (v) => setState(() => _due = v)),
                const SizedBox(height: 12),
                TextField(
                  controller: _limit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Credit limit (₹, optional)',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Remind me before the due date',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in _choices)
                      FilterChip(
                        label: Text(
                          d == 0 ? 'On the day' : '$d day${d == 1 ? '' : 's'}',
                        ),
                        selected: _remind.contains(d),
                        onSelected: (on) => setState(
                          () => on ? _remind.add(d) : _remind.remove(d),
                        ),
                      ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: PvColors.error),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
    );
  }
}
