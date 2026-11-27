import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import 'diagnostics_report.dart';

final diagnosticsProvider = FutureProvider.autoDispose<DiagnosticsReport>((
  ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return buildDiagnostics(
    db,
    await getApplicationSupportDirectory(),
    ref.read(clockProvider).now(),
  );
});

/// How well the automatic reading is working. Numbers only, never amounts or message text.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  Future<void> _share(DiagnosticsReport r) async {
    final file = File(
      '${(await getTemporaryDirectory()).path}/paisa-vault-diagnostics.txt',
    );
    await file.writeAsString(r.toText());
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(diagnosticsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diagnostics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(diagnosticsProvider),
          ),
        ],
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not read the diagnostics.')),
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card('Transactions', [
              _row('Total', '${r.transactions}'),
              _row(
                'Needing a check',
                '${r.pleaseConfirm} (${(r.pleaseConfirmRate * 100).toStringAsFixed(1)}%)',
              ),
              for (final e in r.confirmReasons.entries)
                _row('  ${_reason(e.key)}', '${e.value}'),
              _row(
                'Edited by hand',
                '${r.corrected} (${(r.correctedRate * 100).toStringAsFixed(1)}%)',
              ),
              _row('Without a category', '${r.uncategorised}'),
            ]),
            _card('Saved messages', [
              if (r.messages.isEmpty) _row('None yet', ''),
              for (final e in r.messages.entries) _row(e.key, '${e.value}'),
            ]),
            _card('On-device model', [
              _row('Answers', '${r.model.answers}'),
              _row(
                'Seconds per answer',
                '${r.model.avgSeconds.toStringAsFixed(1)} avg, ${r.model.slowestSeconds.toStringAsFixed(1)} slowest',
              ),
              _row(
                'Loads',
                '${r.model.loads}, ${r.model.avgLoadSeconds.toStringAsFixed(1)} s each',
              ),
              if (r.model.modelMissing > 0)
                _row('Model file missing', '${r.model.modelMissing} times'),
              for (final e in r.model.errors.entries)
                _row('Error ${e.key}', '${e.value}'),
            ]),
            _card('Crashes', [
              _row('Recorded', '${r.crashes}'),
              for (final c in r.lastCrashes)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(c, style: const TextStyle(fontSize: 12)),
                ),
            ]),
            const SizedBox(height: 4),
            const Text(
              'The shared report has only these numbers. It has no amounts, merchants, names or message text.',
              style: TextStyle(color: PvColors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _share(r),
              child: const Text('Share report'),
            ),
          ],
        ),
      ),
    );
  }

  String _reason(String code) => switch (code) {
    'no_model' => 'model not installed',
    'bad_reply' => 'model reply rejected',
    'model_error' => 'model error',
    _ => code,
  };

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _card(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
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
        ...children,
      ],
    ),
  );
}
