import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../transactions/processing_service.dart';
import '../transactions/providers.dart';

/// After a newer model or prompt arrives, re-reads recent transactions and shows what would
/// change. Nothing is overwritten until the user applies it.
class RecheckScreen extends ConsumerStatefulWidget {
  const RecheckScreen({super.key});

  @override
  ConsumerState<RecheckScreen> createState() => _RecheckScreenState();
}

class _RecheckScreenState extends ConsumerState<RecheckScreen> {
  bool _running = false;
  String? _status;
  List<RecheckChange>? _changes;
  final _picked = <int>{};

  Future<void> _start() async {
    setState(() {
      _running = true;
      _status = 'Starting the model…';
      _changes = null;
    });
    final service = await ref.read(processingServiceProvider.future);
    final result = await service.previewRecheck(
      progress: (done, total) {
        if (mounted) setState(() => _status = 'Checked $done of $total…');
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _changes = result;
      _picked
        ..clear()
        ..addAll([
          for (final c in result ?? const <RecheckChange>[]) c.transactionId,
        ]);
      _status = result == null
          ? 'The model is not available right now. Try again in a moment.'
          : result.isEmpty
          ? 'Everything already matches the current model. Nothing to change.'
          : null;
    });
  }

  Future<void> _apply() async {
    final service = await ref.read(processingServiceProvider.future);
    final chosen = [
      for (final c in _changes!)
        if (_picked.contains(c.transactionId)) c,
    ];
    await service.applyRecheck(chosen);
    if (!mounted) return;
    setState(() {
      _changes = const [];
      _status =
          'Updated ${chosen.length} transaction${chosen.length == 1 ? '' : 's'}.';
    });
  }

  String _line(String label, String? from, String? to) =>
      '$label: ${from ?? 'none'} → ${to ?? 'none'}';

  @override
  Widget build(BuildContext context) {
    final changes = _changes ?? const <RecheckChange>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Re-check with the model',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Reads your most recent transactions again with the model on this phone and shows '
            'what would change. Only transactions made by an older model are looked at, and '
            'anything you edited yourself is never touched. Nothing changes until you apply it.',
            style: TextStyle(color: PvColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _running ? null : _start,
            child: Text(_running ? 'Checking…' : 'Check recent transactions'),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_status!),
            ),
          for (final c in changes)
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: CheckboxListTile(
                value: _picked.contains(c.transactionId),
                onChanged: (v) => setState(
                  () => v == true
                      ? _picked.add(c.transactionId)
                      : _picked.remove(c.transactionId),
                ),
                title: Text(
                  c.newMerchant ?? c.oldMerchant ?? 'Transaction',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    if (c.oldMerchant != c.newMerchant)
                      _line('Merchant', c.oldMerchant, c.newMerchant),
                    if (c.oldCategory != c.newCategory)
                      _line('Category', c.oldCategory, c.newCategory),
                    if (c.oldChannel != c.newChannel)
                      _line('Channel', c.oldChannel, c.newChannel),
                  ].join('\n'),
                ),
              ),
            ),
          if (changes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: _picked.isEmpty ? null : _apply,
                child: Text('Apply ${_picked.length} selected'),
              ),
            ),
        ],
      ),
    );
  }
}
