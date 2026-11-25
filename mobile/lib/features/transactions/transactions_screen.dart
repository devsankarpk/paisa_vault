import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../sms/shortcut_guide_screen.dart';
import '../sms/shortcut_health.dart';
import '../categorise/ask_screen.dart';
import '../search/search_screen.dart';
import 'add_message_screen.dart';
import '../settings/settings_screen.dart';
import 'format.dart';
import 'providers.dart';
import 'signing_expiry.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(transactionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Add a bank SMS',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddMessageScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SigningBanner(),
          const _ShortcutBanner(),
          const _AskBanner(),
          Expanded(child: _body(list)),
        ],
      ),
    );
  }

  Widget _body(AsyncValue<List<Transaction>> list) {
    return list.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load transactions')),
      data: (items) => items.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => TransactionTile(items[i]),
            ),
    );
  }
}

/// Warns before a free-account build stops working (7 days after it was signed).
class _SigningBanner extends ConsumerWidget {
  const _SigningBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(signingDaysLeftProvider).asData?.value;
    if (days == null || days > signingWarnDays) return const SizedBox.shrink();
    final text = days < 0
        ? 'This build has expired. New bank SMS are not being saved. Reinstall it from the Mac.'
        : days == 0
        ? 'This build expires today. Reinstall it from the Mac.'
        : 'This build expires in $days day${days == 1 ? '' : 's'}. Reinstall it from the Mac.';
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDEBEB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: PvColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tells the user how many transactions are waiting for a category.
class _AskBanner extends ConsumerWidget {
  const _AskBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(uncategorisedProvider).asData?.value.length ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return InkWell(
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const AskScreen())),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFE8EEFF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          '$n transaction${n == 1 ? '' : 's'} need${n == 1 ? 's' : ''} a category. Tap to answer.',
          style: const TextStyle(
            color: PvColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// iPhone only: warns when no bank SMS has reached the app, or none for a week, since a
/// Shortcuts automation that stops running gives no error.
class _ShortcutBanner extends ConsumerWidget {
  const _ShortcutBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(needsShortcutGuideProvider)) return const SizedBox.shrink();
    final loaded = ref.watch(lastBankMessageProvider);
    if (!loaded.hasValue) return const SizedBox.shrink();
    final last = loaded.value;
    final now = ref.watch(clockProvider).now();
    final text = switch (shortcutHealth(last, now)) {
      ShortcutHealth.ok => null,
      ShortcutHealth.neverReceived => 'No bank SMS has reached the app yet. Tap to check your Shortcuts setup.',
      ShortcutHealth.stale =>
        'No bank SMS for ${daysSince(last!, now)} days. If you had bank transactions, tap to check your Shortcuts setup.',
    };
    if (text == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () => openShortcutGuide(context),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFFDF6E3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFA06A10),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'No transactions yet.\nNew bank SMS will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(color: PvColors.muted, fontSize: 16, height: 1.4),
      ),
    ),
  );
}

class TransactionTile extends StatelessWidget {
  const TransactionTile(this.t, {super.key});
  final Transaction t;

  @override
  Widget build(BuildContext context) {
    final needs = t.status == TransactionStatus.pleaseConfirm;
    final title = t.merchant ?? (needs ? 'Unknown merchant' : 'Transaction');
    final sub = [
      formatDate(t.occurredAt),
      if (t.bankCode != null) t.bankCode!,
      if (t.last4 != null) '••${t.last4}',
    ].join(' · ');
    final credit = t.direction == Direction.credit;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TransactionDetailScreen(id: t.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: PvColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    if (needs)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Please check',
                          style: TextStyle(
                            color: Color(0xFFA06A10),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                signedAmount(t.amountPaise, t.direction),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: credit ? const Color(0xFF1E8E5A) : PvColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
