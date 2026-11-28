import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/screen_guard.dart';

import '../transactions/transaction_repository.dart' show bankNames;
import 'bill_setup_screen.dart';
import 'card_labels.dart';
import 'card_repository.dart';
import 'providers.dart';

/// Add a card by typing. Camera scan and NFC come later. There is no field for the CVV, the
/// full number or the PIN here on purpose.
class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key, this.editing});

  /// When set, the screen changes this card instead of adding one.
  final CardEntry? editing;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  String _bank = 'HDFC';
  CardType _type = CardType.credit;
  CardNetwork _network = CardNetwork.visa;
  final _last4 = TextEditingController();
  final _expiry = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      final c = e.card;
      _bank = bankNames.containsKey(e.bankCode) ? e.bankCode : _bank;
      _type = c.type;
      _network = c.network;
      _last4.text = c.last4;
      if (c.expiryMonth != null) {
        _expiry.text =
            '${c.expiryMonth.toString().padLeft(2, '0')}/${c.expiryYear! % 100}';
      }
    }
  }

  @override
  void dispose() {
    _last4.dispose();
    _expiry.dispose();
    super.dispose();
  }

  /// "08/30" or "8/2030" -> (8, 2030). Empty means no expiry. Null means unreadable.
  (int?, int?)? _parseExpiry(String text) {
    final t = text.trim();
    if (t.isEmpty) return (null, null);
    final m = RegExp(r'^(\d{1,2})\s*/\s*(\d{2}|\d{4})$').firstMatch(t);
    if (m == null) return null;
    final year = int.parse(m.group(2)!);
    return (int.parse(m.group(1)!), year < 100 ? 2000 + year : year);
  }

  Future<void> _save() async {
    final expiry = _parseExpiry(_expiry.text);
    if (expiry == null) {
      setState(() => _error = 'Write the expiry like 08/30, or leave it empty');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = await ref.read(cardRepositoryProvider.future);
    final editing = widget.editing;
    final added = editing != null
        ? CardAdded(
            await repo.update(
              editing.card.id,
              bankCode: _bank,
              type: _type,
              network: _network,
              last4: _last4.text.trim(),
              expiryMonth: expiry.$1,
              expiryYear: expiry.$2,
            ),
            editing.card.id,
          )
        : await repo.add(
            bankCode: _bank,
            type: _type,
            network: _network,
            last4: _last4.text.trim(),
            expiryMonth: expiry.$1,
            expiryYear: expiry.$2,
          );
    if (!mounted) return;
    if (added.result != CardResult.ok) {
      setState(() {
        _saving = false;
        _error = switch (added.result) {
          CardResult.badLast4 => 'Enter exactly 4 digits',
          CardResult.badExpiry => 'Check the expiry month and year',
          CardResult.exists => 'This card is already added',
          CardResult.notFound => 'This card no longer exists',
          _ => 'Could not add the card',
        };
      });
      return;
    }
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    if (editing == null && _type == CardType.credit) {
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => BillSetupScreen(cardId: added.id!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.editing == null ? 'Add card' : 'Edit card',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: PvColors.background,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Enter the card details by hand. Only the last 4 digits and the expiry are kept '
              'here. The CVV is never asked for or stored.',
              style: TextStyle(color: PvColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _bank,
              decoration: const InputDecoration(labelText: 'Bank'),
              items: [
                for (final e in bankNames.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _bank = v ?? _bank),
            ),
            const SizedBox(height: 12),
            SegmentedButton<CardType>(
              segments: const [
                ButtonSegment(value: CardType.credit, label: Text('Credit')),
                ButtonSegment(value: CardType.debit, label: Text('Debit')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CardNetwork>(
              initialValue: _network,
              decoration: const InputDecoration(labelText: 'Network'),
              items: [
                for (final n in CardNetwork.values)
                  DropdownMenuItem(value: n, child: Text(networkLabel(n))),
              ],
              onChanged: (v) => setState(() => _network = v ?? _network),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _last4,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Last 4 digits',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expiry,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Expiry (optional)',
                hintText: 'MM/YY',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: PvColors.error),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                widget.editing != null
                    ? 'Save changes'
                    : _type == CardType.credit
                    ? 'Next: bill reminder'
                    : 'Save card',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
