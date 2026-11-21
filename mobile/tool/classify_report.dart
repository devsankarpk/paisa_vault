// Runs the SMS classifier over the local, git-ignored corpus and prints ids, kinds, reason codes
// and lengths only. Never prints message text.
//   dart run tool/classify_report.dart ../testdata/iphone_inbox_samples.json
import 'dart:convert';
import 'dart:io';

import 'package:paisa_vault/features/sms/sms_classifier.dart';

void main(List<String> args) {
  final samples = jsonDecode(File(args.first).readAsStringSync()) as List<dynamic>;
  const classifier = SmsClassifier();
  final counts = <String, int>{};
  for (final s in samples.cast<Map<String, dynamic>>()) {
    final body = s['body'] as String;
    final r = classifier.classify(body, sender: s['sender'] as String? ?? '');
    counts[r.kind.name] = (counts[r.kind.name] ?? 0) + 1;
    stdout.writeln('${s['id']}  bank=${s['bank_hint']}  ${r.kind.name}  ${r.reason}  len=${body.length}');
  }
  stdout.writeln('\nTotals: $counts');
}
