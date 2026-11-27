import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../transactions/format.dart';
import 'bill_setup_screen.dart';
import 'card_labels.dart';
import 'providers.dart';

/// One card. The full number is not here yet: it will need PIN or biometrics to reveal.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});
  final int cardId;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove this card?'),
        content: const Text(
          'The card and its bill reminders are removed. Your transactions stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: PvColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await (await ref.read(cardRepositoryProvider.future)).remove(cardId);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(cardsProvider).asData?.value ?? const [];
    final found = entries.where((e) => e.card.id == cardId);
    if (found.isEmpty) return const Scaffold(body: SizedBox.shrink());
    final e = found.first;
    final c = e.card;
    final bill = ref.watch(billProvider(cardId)).asData?.value;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: PvColors.muted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${e.bankName} ${maskedLast4(c.last4)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                row('Bank', e.bankName),
                row('Card', maskedLast4(c.last4)),
                row('Type', cardTypeLabel(c.type)),
                row('Network', networkLabel(c.network)),
                row('Expiry', expiryLabel(c)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The full card number is not stored yet. When it is, it will need your PIN, Face ID or fingerprint to show.',
            style: TextStyle(color: PvColors.muted, height: 1.4),
          ),
          if (c.type == CardType.credit) ...[
            const SizedBox(height: 20),
            const Text(
              'Bill reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (bill == null)
              const Text(
                'Not set up. Add the statement and due dates to get reminders.',
                style: TextStyle(color: PvColors.muted),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    row('Statement', dayLabel(bill.statementDay)),
                    row('Payment due', dayLabel(bill.dueDay)),
                    row(
                      'Credit limit',
                      bill.creditLimitPaise == null
                          ? 'Not entered'
                          : '₹${formatRupees(bill.creditLimitPaise!)}',
                    ),
                    row(
                      'Remind',
                      bill.reminderDays.isEmpty
                          ? 'No reminders'
                          : '${bill.reminderDays.split(',').join(', ')} days before',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BillSetupScreen(cardId: cardId),
                ),
              ),
              child: Text(
                bill == null ? 'Set up bill reminder' : 'Change bill reminder',
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _remove(context, ref),
            child: const Text(
              'Remove card',
              style: TextStyle(color: PvColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
