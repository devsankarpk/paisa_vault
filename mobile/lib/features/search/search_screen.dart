import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../categories/providers.dart';
import '../transactions/format.dart';
import '../transactions/providers.dart';
import '../transactions/rule_amount.dart';
import '../transactions/transactions_screen.dart';
import 'transaction_filter.dart';

/// Find transactions by dates, category, exact amount and words. Filters combine.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  final _amount = TextEditingController();
  TransactionFilter _filter = const TransactionFilter();
  List<Transaction> _results = const [];
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _text.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final repo = await ref.read(transactionRepositoryProvider.future);
    final found = await repo.search(_filter);
    if (mounted) setState(() => _results = found);
  }

  void _set(TransactionFilter f) {
    _filter = f;
    _run();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filter.from == null || _filter.to == null
          ? null
          : DateTimeRange(start: _filter.from!, end: _filter.to!),
    );
    if (range != null) _set(_filter.copyWith(from: range.start, to: range.end));
  }

  void _onAmount(String v) {
    if (v.trim().isEmpty) {
      setState(() => _amountError = null);
      _set(_filter.copyWith(clearAmount: true));
      return;
    }
    final paise = rupeesToPaise(v);
    setState(
      () => _amountError = paise == null ? 'Enter like 499 or 499.50' : null,
    );
    if (paise != null) _set(_filter.copyWith(amountPaise: paise));
  }

  void _clear() {
    _text.clear();
    _amount.clear();
    _amountError = null;
    _set(const TransactionFilter());
  }

  @override
  Widget build(BuildContext context) {
    final f = _filter;
    final dates = f.from == null || f.to == null
        ? 'Any dates'
        : '${formatDate(f.from!)} to ${formatDate(f.to!)}';
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!f.isEmpty || _amount.text.isNotEmpty)
            TextButton(onPressed: _clear, child: const Text('Clear')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _text,
                  decoration: const InputDecoration(
                    labelText: 'Merchant or note',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => _set(_filter.copyWith(text: v)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: f.category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Any'),
                          ),
                          for (final c in namesOrDefault(
                            ref.watch(allNamesProvider),
                          ))
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) => _set(
                          v == null
                              ? _filter.copyWith(clearCategory: true)
                              : _filter.copyWith(category: v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Exact amount (₹)',
                          errorText: _amountError,
                        ),
                        onChanged: _onAmount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDates,
                        icon: const Icon(Icons.date_range),
                        label: Text(dates, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    if (f.from != null)
                      IconButton(
                        tooltip: 'Any dates',
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            _set(_filter.copyWith(clearDates: true)),
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${_results.length} found',
                      style: const TextStyle(color: PvColors.muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions match.',
                      style: TextStyle(color: PvColors.muted, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => TransactionTile(_results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
