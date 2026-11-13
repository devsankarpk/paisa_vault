import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'bench.dart';

void main() {
  runApp(const MaterialApp(home: BenchPage()));
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<BenchPage> with WidgetsBindingObserver {
  String? _dir;
  List<File> _models = [];
  String _status = 'Pick a model file';
  String _report = '';
  bool _running = false;

  List<String> _inbox = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _loadInbox();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadInbox();
  }

  /// Messages saved by the iPhone Shortcut action "Log Bank Message" (iOS only).
  Future<void> _loadInbox() async {
    if (!Platform.isIOS) return;
    final docs = await getApplicationDocumentsDirectory();
    final f = File('${docs.path}/shortcut_inbox.jsonl');
    final lines = f.existsSync() ? f.readAsLinesSync() : <String>[];
    setState(() {
      _inbox = [
        for (final l in lines.reversed)
          if (l.trim().isNotEmpty) _summary(l),
      ];
    });
  }

  String _summary(String line) {
    try {
      final m = jsonDecode(line) as Map<String, dynamic>;
      final body = (m['body'] as String).replaceAll('\n', ' ');
      final snip = body.length > 40 ? '${body.substring(0, 40)}...' : body;
      return '${m['received_at']}  (${m['length']} chars)  $snip';
    } on FormatException {
      return 'unreadable line';
    }
  }

  Future<void> _refresh() async {
    // Android: app-specific external folder (adb push). iPhone: Documents (Finder file sharing).
    final base = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final files = base == null
        ? <File>[]
        : base
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.gguf'))
              .toList();
    setState(() {
      _dir = base?.path;
      _models = files;
    });
  }

  Future<void> _run(File model) async {
    setState(() {
      _running = true;
      _report = '';
    });
    try {
      final result = await runBenchmark(
        model.path,
        onProgress: (s) {
          debugPrint('BENCH_PROGRESS $s');
          setState(() => _status = s);
        },
      );
      debugPrint('BENCH_REPORT\n${result.report}');
      setState(() {
        _report = result.report;
        _status = 'Done';
      });
    } catch (e) {
      debugPrint('BENCH_ERROR $e');
      setState(() {
        _report = 'Error: $e';
        _status = 'Failed';
      });
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LLM bench')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Model folder:\n${_dir ?? '...'}'),
          const SizedBox(height: 8),
          if (_models.isEmpty) const Text('No .gguf files found yet.'),
          for (final f in _models)
            ListTile(
              title: Text(f.path.split(Platform.pathSeparator).last),
              subtitle: Text(
                '${(f.lengthSync() / 1048576).toStringAsFixed(0)} MB',
              ),
              trailing: ElevatedButton(
                onPressed: _running ? null : () => _run(f),
                child: const Text('Run'),
              ),
            ),
          TextButton(onPressed: _refresh, child: const Text('Refresh list')),
          const Divider(),
          Text(_status),
          if (_report.isNotEmpty)
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: _report)),
              child: const Text('Copy results'),
            ),
          if (Platform.isIOS) ...[
            const Divider(),
            Text('Shortcut inbox: ${_inbox.length} message(s)'),
            for (final line in _inbox.take(10))
              Text(line, style: const TextStyle(fontSize: 12)),
            TextButton(
              onPressed: _loadInbox,
              child: const Text('Refresh inbox'),
            ),
          ],
          SelectableText(
            _report,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
