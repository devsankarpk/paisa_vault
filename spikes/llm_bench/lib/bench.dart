import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

import 'postprocess.dart';

const categories =
    'Food, Groceries, Shopping, Bills, Travel, Health, Entertainment, Other, Income, Transfer';

const _prompt = r'''Name the merchant and category of this Indian bank SMS.
Reply with one JSON object only: {"merchant": ..., "category": ..., "channel": ...}
- merchant is the shop, app or person paid (or the payer for money received). Never the bank that sent the SMS. Use null for ATM cash or when none is named.
- channel is one of UPI, NEFT, IMPS, ATM, POS (card at a shop), online (card on a website or app).
- category must be one of: __CATS__.

SMS: Rs.250.00 spent on HDFC Bank Card x1234 at ZOMATO on 12-10-26.
{"merchant": "ZOMATO", "category": "Food", "channel": "POS"}
SMS: Rs 5,000.00 credited to A/c XX9876 on 01-11-26 by NEFT from ACME PVT LTD. Ref 998877.
{"merchant": "ACME PVT LTD", "category": "Income", "channel": "NEFT"}
SMS: Rs 2,000 withdrawn at SBI ATM from A/c XX9876 on 14-10-26.
{"merchant": null, "category": "Other", "channel": "ATM"}
SMS: __SMS__
''';

const fields = [
  'is_transaction',
  'bank',
  'last4',
  'amount',
  'direction',
  'channel',
  'merchant',
  'reference',
  'date',
];

bool _matches(String field, dynamic want, dynamic got) {
  if (field == 'amount') {
    return got is num && (got - (want as num)).abs() < 0.005;
  }
  if (field == 'merchant') {
    final a = want.toString().toLowerCase();
    final b = (got ?? '').toString().toLowerCase();
    return b.isNotEmpty && (a.contains(b) || b.contains(a));
  }
  return got == want;
}

/// Pulls the first {...} object out of the model reply, ignoring any think block.
Map<String, dynamic>? parseJson(String reply) {
  final clean = reply.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
  final start = clean.indexOf('{');
  final end = clean.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    return Map<String, dynamic>.from(
      jsonDecode(clean.substring(start, end + 1)) as Map,
    );
  } on FormatException {
    return null;
  }
}

class BenchResult {
  BenchResult(this.report, this.json);
  final String report;
  final Map<String, dynamic> json;
}

/// Runs every seed SMS through the model at [modelPath] and scores the answers.
Future<BenchResult> runBenchmark(
  String modelPath, {
  required void Function(String) onProgress,
}) async {
  final seeds = (jsonDecode(
    await rootBundle.loadString('assets/seed_sms.json'),
  ) as List).cast<Map<String, dynamic>>();
  final name = modelPath.split(Platform.pathSeparator).last;
  final isQwen = name.toLowerCase().contains('qwen');

  final loadWatch = Stopwatch()..start();
  final engine = await LlamaEngine.load(
    LlamaModel(ModelSource.path(modelPath)),
    params: const ModelParams(
      contextSize: 1024,
      numberOfThreads: 4,
      numberOfThreadsBatch: 6,
    ),
  );
  loadWatch.stop();
  final rssAfterLoad = ProcessInfo.currentRss;

  final hit = {
    for (final f in fields) f: [0, 0],
  };
  final misses = <String>[];
  final times = <double>[];
  var parseFailures = 0;
  try {
    for (var i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final sms = seed['body'] as String;
      final expected = seed['expected'] as Map<String, dynamic>;
      onProgress('${i + 1}/${seeds.length}  $name');
      final rules = ruleFields(sms);
      final low = sms.toLowerCase();
      final moved =
          RegExp(
            r'\b(debited|sent|spent|paid|withdrawn|purchase|purchased|deducted|payment of|credited|received|deposited|refund(?:ed)?)\b',
          ).hasMatch(low) &&
          !RegExp(r'\b(failed|declined|unsuccessful)\b').hasMatch(low) &&
          rules['amount'] != null;
      final watch = Stopwatch()..start();
      Map<String, dynamic>? parsed;
      if (moved) {
        var text = _prompt
            .replaceAll('__CATS__', categories)
            .replaceAll('__SMS__', sms);
        if (isQwen) text = '$text\n/no_think';
        final reply = await engine.create([
          LlamaChatMessage.fromText(role: LlamaChatRole.user, text: text),
        ], params: const GenerationParams(maxTokens: 60, temp: 0)).text();
        parsed = parseJson(reply);
        if (parsed == null) parseFailures++;
      }
      watch.stop();
      if (moved) times.add(watch.elapsedMilliseconds / 1000);
      final llm = {...?parsed};
      if (looksLikeBank(llm['merchant']?.toString())) llm['merchant'] = null;
      final ch = llm['channel']?.toString();
      const valid = ['UPI', 'NEFT', 'IMPS', 'ATM', 'POS', 'online'];
      llm['channel'] = valid.cast<String?>().firstWhere(
        (v) => v!.toLowerCase() == ch?.toLowerCase(),
        orElse: () => null,
      );
      final fromRules = ruleMerchant(sms);
      if (fromRules != null) {
        llm['merchant'] = fromRules;
      } else if (RegExp(r'[\w.\-]+@\w+').hasMatch(sms)) {
        llm['merchant'] = null; // postprocess takes the UPI handle instead
      }
      final data = postprocess({...rules, ...llm}, sms);
      for (final f in fields) {
        final want = expected[f];
        if (want == null && f != 'is_transaction') continue;
        if (f != 'is_transaction' && expected['is_transaction'] != true)
          continue;
        hit[f]![1]++;
        if (_matches(f, want, data[f])) {
          hit[f]![0]++;
        } else {
          misses.add('${seed['id']} $f: want $want, got ${data[f]}');
        }
      }
    }
  } finally {
    await engine.dispose();
  }

  final avg = times.reduce((a, b) => a + b) / times.length;
  final worst = times.reduce((a, b) => a > b ? a : b);
  final b = StringBuffer()
    ..writeln('Model: $name')
    ..writeln('Messages: ${seeds.length}')
    ..writeln(
      'Load time: ${(loadWatch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s',
    )
    ..writeln(
      'Per SMS: avg ${avg.toStringAsFixed(1)} s, slowest ${worst.toStringAsFixed(1)} s',
    )
    ..writeln(
      'Memory after load: ${(rssAfterLoad / 1048576).toStringAsFixed(0)} MB',
    )
    ..writeln(
      'Memory at end: ${(ProcessInfo.currentRss / 1048576).toStringAsFixed(0)} MB',
    )
    ..writeln('Reply was not JSON: $parseFailures')
    ..writeln();
  for (final f in fields) {
    final ok = hit[f]![0];
    final n = hit[f]![1];
    b.writeln(
      '${f.padRight(15)} $ok/$n  ${(100 * ok / n).toStringAsFixed(1)}%',
    );
  }
  b
    ..writeln()
    ..writeln('Misses:');
  for (final m in misses) {
    b.writeln('  $m');
  }
  if (misses.isEmpty) b.writeln('  none');
  return BenchResult(b.toString(), {
    'model': name,
    'avgSeconds': avg,
    'loadSeconds': loadWatch.elapsedMilliseconds / 1000,
    'parseFailures': parseFailures,
    'misses': misses.length,
  });
}
