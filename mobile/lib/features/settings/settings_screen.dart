import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../lock/lock_controller.dart';
import '../sms/raw_message_repository.dart';
import 'erase_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _erase(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erase everything?'),
        content: const Text(
          'This deletes all transactions, saved messages, accounts and your PIN from this '
          'phone. It cannot be undone, and there is no copy anywhere else.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Erase everything',
              style: TextStyle(color: PvColors.error),
            ),
          ),
        ],
      ),
    );
    if (sure != true) return;
    final db = await ref.read(appDatabaseProvider.future);
    await EraseService(
      appSupport: await getApplicationSupportDirectory(),
      keyStore: ref.read(keyStoreProvider),
      secrets: ref.read(secretStoreProvider),
      sms: ref.read(smsSourceProvider),
      closeDatabase: db.close,
    ).eraseAll();
    ref.invalidate(appDatabaseProvider);
    // Back to the first-time screen: choose a new PIN.
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    await ref.read(lockControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Settings',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: PvColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          title: 'Your data stays on this phone',
          body:
              'Bank messages are read and understood on this phone. Nothing is uploaded, '
              'and there is no account or server.\n\n'
              'Kept: transactions, accounts and categories, in an encrypted database.\n'
              'The original message text is kept for $_days days so transactions can be '
              're-checked, then deleted. Transactions stay.\n'
              'Never kept: card CVV.',
        ),
        const SizedBox(height: 16),
        const _Card(
          title: 'Erase everything',
          body: 'Deletes all data and your PIN from this phone and starts the app fresh.',
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _erase(context, ref),
          style: OutlinedButton.styleFrom(foregroundColor: PvColors.error),
          child: const Text('Erase everything'),
        ),
      ],
    ),
  );
}

final _days = RawMessageRepository.retention.inDays;

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: PvColors.ink, height: 1.4)),
      ],
    ),
  );
}
