import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/screen_guard.dart';

import 'add_card_screen.dart';
import 'card_detail_screen.dart';
import 'card_labels.dart';
import 'providers.dart';

/// The card vault list. Shows only the bank, last 4 digits, type and network.
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider).asData?.value ?? const [];
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Card vault',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: PvColors.background,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: 'Add card',
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddCardScreen()),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Only the last 4 digits are shown here. The CVV is never stored.',
                style: TextStyle(color: PvColors.primary, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No cards yet. Tap + to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PvColors.muted),
                ),
              ),
            for (final e in cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(
                      Icons.credit_card,
                      color: PvColors.primary,
                    ),
                    title: Text(
                      '${e.bankName} ${maskedLast4(e.card.last4)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${cardTypeLabel(e.card.type)} · ${networkLabel(e.card.network)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CardDetailScreen(cardId: e.card.id),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
