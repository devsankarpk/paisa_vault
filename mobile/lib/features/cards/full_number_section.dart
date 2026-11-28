import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../vault/card_secret_store.dart';
import '../vault/providers.dart';
import '../vault/unlock_dialog.dart';
import '../vault/vault_session.dart';

/// How long a revealed number stays on screen.
const revealSeconds = 45;

/// "Show full number" for one card. Needs PIN or biometrics, shows the number for
/// [revealSeconds], then hides it and closes the vault again.
class FullNumberSection extends ConsumerStatefulWidget {
  const FullNumberSection({super.key, required this.cardId});
  final int cardId;

  @override
  ConsumerState<FullNumberSection> createState() => _FullNumberSectionState();
}

class _FullNumberSectionState extends ConsumerState<FullNumberSection>
    with WidgetsBindingObserver {
  String? _number;
  String? _pin;
  bool _none = false;
  int _left = 0;
  Timer? _timer;
  Future<VaultSession>? _session; // set once the vault has been asked for

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _hide();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _lock();
    super.dispose();
  }

  Future<void> _lock() async => (await _session)?.lock();

  void _hide() {
    _timer?.cancel();
    _lock();
    if (mounted) {
      setState(() {
        _number = null;
        _pin = null;
        _none = false;
      });
    }
  }

  void _countdown() {
    _timer?.cancel();
    _left = revealSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (--_left <= 0) {
        _hide();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _show() async {
    _session ??= ref.read(vaultSessionProvider.future);
    if (!await unlockVault(context, ref)) return;
    final store = await ref.read(cardSecretStoreProvider.future);
    final n = await store.readNumber(widget.cardId);
    final pin = await store.readPin(widget.cardId);
    if (!mounted) return;
    setState(() {
      _number = n;
      _pin = pin;
      _none = n == null;
    });
    _countdown();
  }

  Future<void> _add() async {
    _timer?.cancel(); // the vault must stay open while the number is typed
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NumberDialog(cardId: widget.cardId),
    );
    if (saved == true) await _show();
  }

  Future<void> _savePin() async {
    _timer?.cancel(); // keep the vault open while the owner reads and types
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save the card PIN?'),
        content: const Text(
          'Most banks hold the cardholder responsible if a stored PIN is misused. '
          'It is kept encrypted in your private vault and shown only after your PIN, '
          'Face ID or fingerprint. Only save it if you accept that risk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Do not save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I understand, continue'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return _countdown();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CardPinDialog(cardId: widget.cardId),
    );
    if (saved == true) {
      final store = await ref.read(cardSecretStoreProvider.future);
      final pin = await store.readPin(widget.cardId);
      if (mounted) setState(() => _pin = pin);
    }
    _countdown();
  }

  Future<void> _removePin() async {
    final store = await ref.read(cardSecretStoreProvider.future);
    await store.deletePin(widget.cardId);
    if (mounted) setState(() => _pin = null);
  }

  Widget _pinBlock() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(height: 24),
      const Text('Card PIN', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      if (_pin != null) ...[
        SelectableText(
          _pin!,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        TextButton(
          onPressed: _removePin,
          child: const Text('Delete saved PIN'),
        ),
      ] else ...[
        const Text(
          'Not saved. Saving it is optional.',
          style: TextStyle(color: PvColors.muted),
        ),
        TextButton(onPressed: _savePin, child: const Text('Save card PIN')),
      ],
    ],
  );

  String _spaced(String n) =>
      RegExp(r'.{1,4}').allMatches(n).map((m) => m[0]).join(' ');

  @override
  Widget build(BuildContext context) {
    final n = _number;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Full card number',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (n != null) ...[
            SelectableText(
              _spaced(n),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hides in $_left seconds',
              style: const TextStyle(color: PvColors.muted),
            ),
            _pinBlock(),
            TextButton(onPressed: _hide, child: const Text('Hide now')),
          ] else if (_none) ...[
            const Text(
              'No full number saved for this card.',
              style: TextStyle(color: PvColors.muted),
            ),
            TextButton(onPressed: _add, child: const Text('Add card number')),
            _pinBlock(),
            TextButton(onPressed: _hide, child: const Text('Hide now')),
          ] else ...[
            const Text(
              'Needs your PIN, Face ID or fingerprint to show. The CVV is never stored.',
              style: TextStyle(color: PvColors.muted, height: 1.4),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _show,
              child: const Text('Show full number'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberDialog extends ConsumerStatefulWidget {
  const _NumberDialog({required this.cardId});
  final int cardId;
  @override
  ConsumerState<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends ConsumerState<_NumberDialog> {
  final _ctl = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = await ref.read(cardSecretStoreProvider.future);
    final p = await store.saveNumber(widget.cardId, _ctl.text);
    if (!mounted) return;
    if (p == null) {
      Navigator.pop(context, true);
    } else {
      setState(
        () => _problem = switch (p) {
          NumberProblem.notDigits => 'Use digits only',
          NumberProblem.badLength => 'A card number has 12 to 19 digits',
          NumberProblem.failsCheck => 'This number does not look right',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Full card number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Card number',
              errorText: _problem,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Do not enter the CVV. This app never stores it.',
            style: TextStyle(color: PvColors.muted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _CardPinDialog extends ConsumerStatefulWidget {
  const _CardPinDialog({required this.cardId});
  final int cardId;
  @override
  ConsumerState<_CardPinDialog> createState() => _CardPinDialogState();
}

class _CardPinDialogState extends ConsumerState<_CardPinDialog> {
  final _ctl = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = await ref.read(cardSecretStoreProvider.future);
    final ok = await store.savePin(widget.cardId, _ctl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _problem = 'A card PIN has 4 to 6 digits');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Card PIN'),
      content: TextField(
        controller: _ctl,
        keyboardType: TextInputType.number,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Card PIN', errorText: _problem),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
