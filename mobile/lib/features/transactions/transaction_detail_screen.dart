import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import 'edit_transaction_sheet.dart';
import 'format.dart';
import 'providers.dart';

/// Shows everything the app read from one message, next to the original message, so the owner
/// can check it and correct or report anything wrong.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionProvider(id)).value;
    final original = ref.watch(originalMessageProvider(id)).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: tx == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (tx.status == TransactionStatus.pleaseConfirm)
                  _Banner(confirmReasonLabel(tx.confirmReason)),
                _Card(
                  children: [
                    _Row('Amount', signedAmount(tx.amountPaise, tx.direction)),
                    _Row(
                      'Type',
                      tx.direction == Direction.debit
                          ? 'Money out (debit)'
                          : 'Money in (credit)',
                    ),
                    _Row('Date', formatDate(tx.occurredAt)),
                    _Row('Merchant', tx.merchant),
                    _Row('Category', tx.categoryName),
                    _Row('Bank', tx.bankCode),
                    _Row('Account', accountKindLabel(tx.accountKind)),
                    _Row('Last 4 digits', tx.last4),
                    _Row('Channel', tx.channel),
                    _Row('Reference', tx.reference),
                    _Row(
                      'Status',
                      tx.userCorrected
                          ? 'Corrected by you'
                          : (tx.status == TransactionStatus.confirmed
                                ? 'OK'
                                : 'Please check'),
                    ),
                    if (tx.note != null) _Row('Note', tx.note),
                  ],
                ),
                const SizedBox(height: 16),
                _Card(
                  children: [
                    const Text(
                      'Original message',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      original ?? 'Not available',
                      style: const TextStyle(color: PvColors.ink, height: 1.4),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => showEditTransactionSheet(context, tx),
                  child: const Text('Correct something'),
                ),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _report(tx)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied. It has no message text.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Copy details to report a problem'),
                ),
              ],
            ),
    );
  }

  /// A report to paste to the developer. Holds the extracted fields only, never message text.
  String _report(Transaction t) => [
    'Transaction #${t.id}',
    'amount=${formatRupees(t.amountPaise)} direction=${t.direction.name}',
    'bank=${t.bankCode ?? '-'} kind=${t.accountKind ?? '-'} last4=${t.last4 ?? '-'}',
    'merchant=${t.merchant ?? '-'} category=${t.categoryName ?? '-'} channel=${t.channel ?? '-'}',
    'reference=${t.reference ?? '-'} date=${formatDate(t.occurredAt)}',
    'status=${t.status.name} reason=${t.confirmReason ?? '-'} corrected=${t.userCorrected}',
  ].join('\n');
}

class _Banner extends StatelessWidget {
  const _Banner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFDF6E3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFFA06A10), height: 1.35),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: PvColors.muted)),
        ),
        Expanded(
          child: Text(
            value ?? 'Not found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: value == null ? const Color(0xFFD64545) : PvColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
