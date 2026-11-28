import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/screen_guard.dart';
import '../transactions/format.dart';
import 'providers.dart';
import 'unlock_dialog.dart';
import 'vault_database.dart';
import 'vault_session.dart';

/// Opens the private vault: asks for the PIN, then shows what was hidden, with Unhide. The
/// vault closes again when the screen is left or the app goes to the background.
Future<void> openHiddenVault(BuildContext context, WidgetRef ref) async {
  if (!await unlockVault(context, ref)) return;
  if (!context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const HiddenScreen()));
}

class HiddenScreen extends ConsumerStatefulWidget {
  const HiddenScreen({super.key});
  @override
  ConsumerState<HiddenScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends ConsumerState<HiddenScreen>
    with WidgetsBindingObserver {
  List<HiddenTransaction>? _items;
  VaultSession? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session?.lock();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _load() async {
    _session = await ref.read(vaultSessionProvider.future);
    final service = await ref.read(hideServiceProvider.future);
    final items = await service.list();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _unhide(HiddenTransaction h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Show in the normal list?'),
        content: const Text(
          'It will appear in your lists, totals, budgets and search again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unhide'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final service = await ref.read(hideServiceProvider.future);
    await service.unhide(h.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Private vault',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: PvColors.background,
          surfaceTintColor: Colors.transparent,
        ),
        body: items == null
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nothing hidden.\nOpen a transaction and tap Hide to move it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PvColors.muted, height: 1.4),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final h in items)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          title: Text(h.merchant ?? 'Unknown'),
                          subtitle: Text(
                            '${formatDate(h.occurredAt)} · ${h.categoryName ?? 'Uncategorised'}',
                          ),
                          trailing: Text(
                            signedAmount(h.amountPaise, h.direction),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () => _unhide(h),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
