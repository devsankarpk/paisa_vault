// Coverage of the rule extractor on the local, git-ignored corpus. Prints how many transaction
// messages each field was found in, and ids of messages missing amount or direction.
// Never prints message text.
//   dart run tool/rules_report.dart ../testdata/iphone_inbox_samples.json
import 'dart:convert';
import 'dart:io';

import 'package:paisa_vault/features/pipeline/rule_extractor.dart';
import 'package:paisa_vault/features/sms/sms_classifier.dart';

void main(List<String> args) {
  final samples = (jsonDecode(
    File(args.first).readAsStringSync(),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  const classifier = SmsClassifier();
  const rules = RuleExtractor();
  final found = <String, int>{};
  var n = 0;
  for (final s in samples) {
    final body = s['body'] as String;
    if (classifier.classify(body).kind != SmsKind.transaction) continue;
    n++;
    final f = rules.extract(body);
    void count(String k, bool ok) {
      if (ok) found[k] = (found[k] ?? 0) + 1;
    }

    count('amount', f.amountPaise != null);
    count('direction', f.direction != null);
    count('bank', f.bank != null);
    count('last4', f.last4 != null);
    count('channel', f.channel != null);
    count('reference', f.reference != null);
    count('date', f.date != null);
    count('merchant', f.merchant != null);
    if (f.amountPaise == null || f.direction == null) {
      stdout.writeln(
        'missing amount/direction: ${s['id']} bank=${s['bank_hint']} len=${body.length}',
      );
    }
  }
  stdout.writeln('Transaction messages: $n');
  for (final k in [
    'amount',
    'direction',
    'bank',
    'last4',
    'channel',
    'reference',
    'date',
    'merchant',
  ]) {
    stdout.writeln('${k.padRight(10)} ${found[k] ?? 0}/$n');
  }
}
