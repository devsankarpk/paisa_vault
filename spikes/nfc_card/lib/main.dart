import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

import 'emv.dart';

void main() => runApp(const NfcSpikeApp());

class NfcSpikeApp extends StatelessWidget {
  const NfcSpikeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NFC card spike',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: const Home(),
      );
}

class Row1 {
  Row1(this.label, this.f, this.ms, this.note);
  final String label;
  final CardFindings f;
  final int ms;
  final String note;
  String get line =>
      '$label | ${f.network} | pan:${f.panFound ? "yes(${f.panSource},len${f.panLength},luhn:${f.luhn},last4 ${f.last4})" : "no"} | '
      'expiry:${f.expiryFound ? "yes" : "no"} | holder:${f.holderFound ? "yes" : "no"} | ${ms}ms${note.isEmpty ? "" : " | $note"}';
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _label = TextEditingController();
  final rows = <Row1>[];
  String status = 'Checking NFC...';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    FlutterNfcKit.nfcAvailability.then((a) => setState(() => status = 'NFC: ${a.name}'));
  }

  Future<String> _tx(String hex) async => (await FlutterNfcKit.transceive(hex)).toUpperCase();

  // Response data without the 2-byte status word; returns null if SW is not 9000.
  String? _data(String resp) =>
      resp.length >= 4 && resp.endsWith('9000') ? resp.substring(0, resp.length - 4) : null;

  Future<void> _read() async {
    if (busy) return;
    setState(() {
      busy = true;
      status = 'Hold the card against the back of the phone...';
    });
    final sw = Stopwatch()..start();
    var f = CardFindings();
    var note = '';
    try {
      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 20));
      if (tag.type != NFCTagType.iso7816) {
        f.error = 'not an ISO 7816 card (${tag.type.name})';
        note = f.error;
      } else {
        final all = <Tlv>[];
        // 1. PPSE
        final ppse = _data(await _tx('00A404000E325041592E5359532E444446303100'));
        final aids = <String>[];
        if (ppse != null) {
          final t = parseTlv(ppse);
          all.addAll(t);
          aids.addAll(allValues(t, '4F'));
        } else {
          note = 'PPSE refused';
        }
        // Fallback to well-known AIDs when PPSE lists none.
        if (aids.isEmpty) {
          aids.addAll(['A0000005241010', 'A0000000031010', 'A0000000041010']);
        }
        var chosen = '';
        for (final aid in aids) {
          final len = (aid.length ~/ 2).toRadixString(16).padLeft(2, '0').toUpperCase();
          final sel = _data(await _tx('00A40400$len${aid}00'));
          if (sel == null) continue;
          chosen = aid;
          final selT = parseTlv(sel);
          all.addAll(selT);
          // 2. GPO with PDOL filled in
          final pdol = firstValue(selT, '9F38');
          var pdolData = '';
          if (pdol != null) {
            var i = 0;
            while (i + 2 <= pdol.length) {
              var tag2 = pdol.substring(i, i + 2);
              i += 2;
              if ((int.parse(tag2, radix: 16) & 0x1F) == 0x1F) {
                while (i + 2 <= pdol.length) {
                  final b = pdol.substring(i, i + 2);
                  tag2 += b;
                  i += 2;
                  if ((int.parse(b, radix: 16) & 0x80) == 0) break;
                }
              }
              final l = int.parse(pdol.substring(i, i + 2), radix: 16);
              i += 2;
              String v = '00' * l;
              if (tag2 == '9F66' && l == 4) v = '36000000';
              if ((tag2 == '9F1A' || tag2 == '5F2A') && l == 2) v = '0356';
              pdolData += v;
            }
          }
          final inner = '83${(pdolData.length ~/ 2).toRadixString(16).padLeft(2, '0')}$pdolData';
          final gpoLen = (inner.length ~/ 2).toRadixString(16).padLeft(2, '0');
          final gpo = _data(await _tx('80A80000$gpoLen${inner.toUpperCase()}00'));
          var afl = '';
          if (gpo != null) {
            if (gpo.startsWith('77')) {
              final g = parseTlv(gpo);
              all.addAll(g);
              afl = firstValue(g, '94') ?? '';
            } else if (gpo.startsWith('80')) {
              // format 1: 80 len AIP(2) AFL...
              final body = gpo.substring(4);
              afl = body.length > 4 ? body.substring(4) : '';
            }
          } else {
            note = '${note.isEmpty ? "" : "$note; "}GPO refused';
          }
          // 3. Read records from the AFL, else scan a few likely records.
          final reads = <List<int>>[];
          for (var k = 0; k + 8 <= afl.length; k += 8) {
            final sfi = int.parse(afl.substring(k, k + 2), radix: 16) >> 3;
            final first = int.parse(afl.substring(k + 2, k + 4), radix: 16);
            final last = int.parse(afl.substring(k + 4, k + 6), radix: 16);
            for (var r = first; r <= last && r < first + 20; r++) {
              reads.add([sfi, r]);
            }
          }
          if (reads.isEmpty) {
            for (var s = 1; s <= 3; s++) {
              for (var r = 1; r <= 4; r++) {
                reads.add([s, r]);
              }
            }
          }
          for (final sr in reads) {
            final p2 = ((sr[0] << 3) | 4).toRadixString(16).padLeft(2, '0');
            final p1 = sr[1].toRadixString(16).padLeft(2, '0');
            final rec = _data(await _tx('00B2$p1${p2.toUpperCase()}00'));
            if (rec != null) all.addAll(parseTlv(rec));
          }
          if (extractFindings(all).panFound) break; // got it
        }
        f = extractFindings(all, aid: chosen);
        if (chosen.isEmpty) note = '${note.isEmpty ? "" : "$note; "}no application selected';
        if (!f.panFound && note.isEmpty) note = 'no number returned';
      }
    } catch (e) {
      f.error = e.toString();
      note = 'error: ${e.toString().split("\n").first}';
    } finally {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
    }
    sw.stop();
    setState(() {
      rows.insert(0, Row1(_label.text.isEmpty ? '(no label)' : _label.text, f, sw.elapsedMilliseconds, note));
      busy = false;
      status = 'Done. Tap Read card for the next card.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('NFC card spike')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(status),
            const SizedBox(height: 8),
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Label (bank, debit/credit), no card number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton(onPressed: busy ? null : _read, child: const Text('Read card')),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: rows.isEmpty
                    ? null
                    : () => Clipboard.setData(ClipboardData(text: rows.map((r) => r.line).join('\n'))),
                child: const Text('Copy results'),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('Only last 4 digits are shown. The full number is never displayed, saved or logged.',
                style: TextStyle(fontSize: 12)),
            const Divider(),
            Expanded(
              child: ListView(children: [for (final r in rows) ListTile(dense: true, title: Text(r.line))]),
            ),
          ]),
        ),
      );
}
