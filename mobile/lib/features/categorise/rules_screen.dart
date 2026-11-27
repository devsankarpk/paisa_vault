import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../categories/providers.dart';
import '../transactions/providers.dart';

final merchantRulesProvider = StreamProvider<List<MerchantRule>>((ref) async* {
  yield* (await ref.watch(transactionRepositoryProvider.future)).watchRules();
});

/// Merchants the app files automatically. Change the category or forget a rule.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    MerchantRule rule,
  ) async {
    final names = namesOrDefault(ref.read(categoryNamesProvider));
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(rule.merchantKey),
        children: [
          for (final n in names)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(n),
              child: Text(
                n,
                style: TextStyle(
                  fontWeight: n == rule.categoryName
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == rule.categoryName) return;
    await (await ref.read(transactionRepositoryProvider.future))
        .changeRule(rule.id, picked);
  }

  Future<void> _forget(
    BuildContext context,
    WidgetRef ref,
    MerchantRule rule,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forget this rule?'),
        content: Text(
          '${rule.merchantKey} will no longer be filed under ${rule.categoryName} automatically. '
          'Transactions already filed keep their category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await (await ref.read(transactionRepositoryProvider.future))
        .deleteRule(rule.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(merchantRulesProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Merchant rules',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: rules.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No rules yet. When you answer "What was this?" and choose "Always use this category", the merchant shows up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PvColors.muted, height: 1.4),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Changing or forgetting a rule affects new transactions only.',
                    style: TextStyle(color: PvColors.muted, height: 1.4),
                  ),
                ),
                for (final r in rules)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      title: Text(
                        r.merchantKey,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(r.categoryName),
                      onTap: () => _change(context, ref, r),
                      trailing: IconButton(
                        tooltip: 'Forget rule',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _forget(context, ref, r),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
