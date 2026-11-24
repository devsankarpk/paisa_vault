import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sms_source.dart';
import 'providers.dart';

enum AddMessageResult { added, repeat, notATransaction, empty }

/// Saves pasted text as if the SMS had just arrived, then turns it into a transaction.
/// Used to recover a message the Shortcut missed.
Future<AddMessageResult> addPastedMessage(WidgetRef ref, String text) async {
  final body = text.trim();
  if (body.isEmpty) return AddMessageResult.empty;
  final repo = await ref.read(rawMessageRepositoryProvider.future);
  final id = await repo.save(
    IncomingSms(
      sender: '',
      body: body,
      receivedAt: ref.read(clockProvider).now(),
    ),
  );
  if (id == null) return AddMessageResult.repeat;
  final r = await (await ref.read(processingServiceProvider.future))
      .processNew();
  return r.transactions > 0
      ? AddMessageResult.added
      : r.duplicates > 0
      ? AddMessageResult.repeat
      : AddMessageResult.notATransaction;
}

class AddMessageScreen extends ConsumerStatefulWidget {
  const AddMessageScreen({super.key});

  @override
  ConsumerState<AddMessageScreen> createState() => _AddMessageScreenState();
}

class _AddMessageScreenState extends ConsumerState<AddMessageScreen> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) setState(() => _text.text = data!.text!);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await addPastedMessage(ref, _text.text);
      if (!mounted) return;
      if (r == AddMessageResult.added) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _message = switch (r) {
          AddMessageResult.empty => 'Paste the bank SMS first.',
          AddMessageResult.repeat =>
            'This transaction is already saved, so nothing was added.',
          _ => 'No amount and debit or credit found, so nothing was added.',
        };
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Add a bank SMS',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: PvColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Missed a message? Copy the bank SMS from Messages and paste it here. '
          'It is processed on this phone like a new one.',
          style: TextStyle(color: PvColors.muted, height: 1.4),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Paste the SMS text',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _paste,
            icon: const Icon(Icons.content_paste),
            label: const Text('Paste from clipboard'),
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _message!,
              style: const TextStyle(color: PvColors.error),
            ),
          ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Add transaction'),
        ),
      ],
    ),
  );
}
