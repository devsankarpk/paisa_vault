import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../budgets/providers.dart';
import '../transactions/providers.dart';
import 'backup_service.dart';

/// Make an encrypted backup file, or restore one. The passphrase is never stored: lose it and
/// the file cannot be opened.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _status;

  Future<BackupService> _service() async =>
      BackupService(await ref.read(appDatabaseProvider.future));

  Future<String?> _askPassphrase({required bool confirm}) => showDialog<String>(
    context: context,
    builder: (_) => _PassphraseDialog(confirm: confirm),
  );

  Future<void> _backup() async {
    final pass = await _askPassphrase(confirm: true);
    if (pass == null || !mounted) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final bytes = await (await _service()).create(pass);
      final now = ref.read(clockProvider).now();
      final name =
          'PaisaVault-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.pvbackup';
      final file = File('${(await getTemporaryDirectory()).path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      if (mounted) {
        setState(
          () =>
              _status = 'Backup file created. Keep it and the passphrase safe.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _status = 'Could not make the backup (${e.runtimeType}).',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty || !mounted) return;
    final path = picked.first.path;
    if (path == null) return;
    final pass = await _askPassphrase(confirm: false);
    if (pass == null || !mounted) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final service = await _service();
      final bytes = await File(path).readAsBytes();
      final counts = await service.inspect(bytes, pass);
      if (!mounted) return;
      final sure = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Replace everything?'),
          content: Text(
            'This backup has ${counts.transactions} transactions, ${counts.accounts} accounts, '
            '${counts.rules} merchant rules and ${counts.budgets} budgets.\n\n'
            'Restoring deletes what is on this phone now and replaces it. Original message text is not part of a backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Replace',
                style: TextStyle(color: PvColors.error),
              ),
            ),
          ],
        ),
      );
      if (sure != true) return;
      await service.restore(bytes, pass);
      ref.invalidate(processingServiceProvider);
      ref.invalidate(budgetStatusesProvider);
      if (mounted) {
        setState(
          () => _status = 'Restored ${counts.transactions} transactions.',
        );
      }
    } on BackupException catch (e) {
      if (mounted) {
        setState(
          () => _status = switch (e.problem) {
            BackupProblem.wrongPassphrase =>
              'Wrong passphrase, or the file is damaged. Nothing was changed.',
            BackupProblem.notABackup =>
              'That is not a Paisa Vault backup file.',
            BackupProblem.tooNew => 'This backup is from a newer version of the app. Update the app first.',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _status =
              'Could not restore (${e.runtimeType}). Nothing was changed.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Backup and restore',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: PvColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          'Your backup file',
          'An encrypted file you keep yourself (Files, AirDrop, email to yourself). It holds '
              'transactions, accounts, categories, merchant rules and budgets.\n\n'
              'It does not hold the original message text. It is locked with a passphrase you '
              'choose, which is not stored anywhere: if you forget it, the backup cannot be opened.',
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _backup,
          child: const Text('Back up now'),
        ),
        const SizedBox(height: 24),
        _card(
          'Restore',
          'Pick a backup file and enter its passphrase. This replaces everything on this phone. '
              'Use it on a new phone or after erasing the app.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : _restore,
          child: const Text('Restore from a file'),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_status!, style: const TextStyle(height: 1.4)),
          ),
      ],
    ),
  );

  Widget _card(String title, String body) => Container(
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

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.confirm});
  final bool confirm;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _ok() {
    if (widget.confirm) {
      if (_a.text.length < BackupService.minPassphraseLength) {
        setState(
          () => _error =
              'Use at least ${BackupService.minPassphraseLength} characters',
        );
        return;
      }
      if (_a.text != _b.text) {
        setState(() => _error = 'The two passphrases do not match');
        return;
      }
    } else if (_a.text.isEmpty) {
      setState(() => _error = 'Enter the passphrase');
      return;
    }
    Navigator.pop(context, _a.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.confirm ? 'Choose a passphrase' : 'Enter the passphrase',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.confirm)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Write it down somewhere safe. It cannot be recovered.',
              style: TextStyle(color: PvColors.muted),
            ),
          ),
        TextField(
          controller: _a,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Passphrase'),
        ),
        if (widget.confirm)
          TextField(
            controller: _b,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Repeat passphrase',
              errorText: _error,
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: PvColors.error)),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _ok, child: const Text('OK')),
    ],
  );
}
