import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'card_parse.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Card scan spike',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const Home(),
  );
}

class Row2 {
  Row2(this.label, this.f, this.ms, this.lineCount, this.shape);
  final String label;
  final ScanFindings f;
  final int ms;
  final int lineCount;
  final String shape;
  String get line =>
      '$label | number:${f.numberFound ? "yes(len${f.length},luhn:${f.luhn},last4 ${f.last4})" : "no"} | '
      'expiry:${f.expiryFound ? "yes ${f.expiry}" : "no"} | candidates:${f.candidates} | ocr lines:$lineCount | ${ms}ms | shape: $shape';
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _label = TextEditingController();
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final rows = <Row2>[];
  String status =
      'Put the card on a plain surface in good light, then tap Scan card.';
  bool busy = false;

  Future<void> _scan() async {
    if (busy) return;
    setState(() => busy = true);
    File? file;
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (shot == null) {
        setState(() {
          busy = false;
          status = 'Cancelled.';
        });
        return;
      }
      file = File(shot.path);
      final sw = Stopwatch()..start();
      final result = await _recognizer.processImage(
        InputImage.fromFilePath(shot.path),
      );
      final all = [for (final b in result.blocks) ...b.lines];
      // Top-to-bottom, then left-to-right, so split numbers join in the right order.
      all.sort((a, b) {
        final dy = a.boundingBox.top - b.boundingBox.top;
        if (dy.abs() > a.boundingBox.height * 0.5) return dy < 0 ? -1 : 1;
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });
      final lines = [for (final l in all) l.text];
      // Safe layout description: digits become d, letters become a, nothing real is kept.
      final shape = [
        for (final l in all)
          l.text
              .replaceAll(RegExp(r'[A-Za-z]'), 'a')
              .replaceAll(RegExp(r'\d'), 'd'),
      ].join(' | ');
      final f = parseCardText(lines);
      debugPrint(
        'PV_SHAPE ${f.numberFound ? "found" : "none"} cands=${f.candidates} | $shape',
      );
      try {
        final dir = await getApplicationDocumentsDirectory();
        await File('${dir.path}/scan_shapes.log').writeAsString(
          '${DateTime.now().toIso8601String()} ${f.numberFound ? "found" : "none"} luhn=${f.luhn} expiry=${f.expiryFound} cands=${f.candidates} | $shape\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      sw.stop();
      setState(() {
        rows.insert(
          0,
          Row2(
            _label.text.isEmpty ? '(no label)' : _label.text,
            f,
            sw.elapsedMilliseconds,
            lines.length,
            shape,
          ),
        );
        status = 'Done. Next card, or Copy results.';
      });
    } catch (e) {
      setState(() => status = 'Error: ${e.toString().split("\n").first}');
    } finally {
      // The photo contains the full card number: delete it straight away.
      try {
        await file?.delete();
      } catch (_) {}
      setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Card scan spike')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status),
          const SizedBox(height: 8),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Label (bank, debit/credit, front or back), no number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: busy ? null : _scan,
                child: const Text('Scan card'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: rows.isEmpty
                    ? null
                    : () => Clipboard.setData(
                        ClipboardData(text: rows.map((r) => r.line).join('\n')),
                      ),
                child: const Text('Copy results'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Text is read on the phone. Only last 4 digits and the expiry month and year are shown. The photo is deleted right after reading. Do not scan the back (CVV).',
            style: TextStyle(fontSize: 12),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                for (final r in rows)
                  ListTile(dense: true, title: Text(r.line)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
