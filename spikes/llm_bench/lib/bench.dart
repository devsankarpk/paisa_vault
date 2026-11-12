import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

import 'postprocess.dart';

const categories =
    'Food, Groceries, Shopping, Bills, Travel, Health, Entertainment, Other, Income, Transfer';

const _prompt = r'''You read Indian bank SMS messages and extract the transaction as JSON.
Reply with one JSON object only, no other text.
Keys: is_transaction (bool), bank, account_type (debit_card|credit_card|savings_account|upi), last4, amount (number), direction (debit|credit), merchant, channel (UPI|NEFT|IMPS|ATM|POS|online), reference, date (YYYY-MM-DD), category.
Rules:
- is_transaction is false for OTPs, promotions, balance alerts and anything with no money moved.
- amount is the transaction amount as a number (not the balance). Copy it exactly from the SMS.
- direction is "debit" when money left the account, "credit" when it arrived.
- last4 is the last 4 digits of the card or account, as text.
- category must be one of: __CATS__.
- Use null for anything the SMS does not say. Never guess.

Examples:
SMS: Rs.250.00 spent on HDFC Bank Card x1234 at ZOMATO on 12-10-26. Avl limit Rs XXXX
JSON: {"is_transaction": true, "bank": "HDFC", "account_type": "credit_card", "last4": "1234", "amount": 250.0, "direction": "debit", "merchant": "ZOMATO", "channel": "POS", "reference": null, "date": "2026-10-12", "category": "Food"}
SMS: Rs 5,000.00 credited to A/c XX9876 on 01-11-26 by NEFT from ACME PVT LTD. Ref 998877. -SBI
JSON: {"is_transaction": true, "bank": "SBI", "account_type": "savings_account", "last4": "9876", "amount": 5000.0, "direction": "credit", "merchant": "ACME PVT LTD", "channel": "NEFT", "reference": "998877", "date": "2026-11-01", "category": "Income"}
SMS: 482913 is your OTP for login. Do not share it with anyone.
JSON: {"is_transaction": false, "bank": null, "account_type": null, "last4": null, "amount": null, "direction": null, "merchant": null, "channel": null, "reference": null, "date": null, "category": null}

Now the real SMS.
SMS:
"""__SMS__"""
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
  final seeds = (jsonDecode(await rootBundle.loadString('assets/seed_sms.json'))
          as List)
      .cast<Map<String, dynamic>>();
  final name = modelPath.split(Platform.pathSeparator).last;
  final isQwen = name.toLowerCase().contains('qwen');

  final loadWatch = Stopwatch()..start();
  final engine = await LlamaEngine.load(
    LlamaModel(ModelSource.path(modelPath)),
    params: const ModelParams(contextSize: 2048),
  );
  loadWatch.stop();
  final rssAfterLoad = ProcessInfo.currentRss;

  final hit = {for (final f in fields) f: [0, 0]};
  final misses = <String>[];
  final times = <double>[];
  var parseFailures = 0;
  try {
    for (var i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final sms = seed['body'] as String;
      final expected = seed['expected'] as Map<String, dynamic>;
      onProgress('${i + 1}/${seeds.length}  $name');
      var text = _prompt.replaceAll('__CATS__', categories).replaceAll('__SMS__', sms);
      if (isQwen) text = '$text\n/no_think';
      final watch = Stopwatch()..start();
      final reply = await engine
          .create(
            [LlamaChatMessage.fromText(role: LlamaChatRole.user, text: text)],
            params: const GenerationParams(maxTokens: 300, temp: 0),
          )
          .text();
      watch.stop();
      times.add(watch.elapsedMilliseconds / 1000);
      final parsed = parseJson(reply);
      if (parsed == null) parseFailures++;
      final data = postprocess(parsed ?? {}, sms);
      for (final f in fields) {
        final want = expected[f];
        if (want == null && f != 'is_transaction') continue;
        if (f != 'is_transaction' && expected['is_transaction'] != true) continue;
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
    ..writeln('Load time: ${(loadWatch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s')
    ..writeln('Per SMS: avg ${avg.toStringAsFixed(1)} s, slowest ${worst.toStringAsFixed(1)} s')
    ..writeln('Memory after load: ${(rssAfterLoad / 1048576).toStringAsFixed(0)} MB')
    ..writeln('Memory at end: ${(ProcessInfo.currentRss / 1048576).toStringAsFixed(0)} MB')
    ..writeln('Reply was not JSON: $parseFailures')
    ..writeln();
  for (final f in fields) {
    final ok = hit[f]![0];
    final n = hit[f]![1];
    b.writeln('${f.padRight(15)} $ok/$n  ${(100 * ok / n).toStringAsFixed(1)}%');
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
