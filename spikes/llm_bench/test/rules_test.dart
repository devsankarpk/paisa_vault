import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_bench/postprocess.dart';

void main() {
  test('rules read amount and last4 from every seed SMS', () {
    final seeds = (jsonDecode(File('assets/seed_sms.json').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();
    final bad = <String>[];
    for (final s in seeds) {
      final exp = s['expected'] as Map<String, dynamic>;
      if (exp['is_transaction'] != true) continue;
      final r = ruleFields(s['body'] as String);
      final last4 = r['last4']?.toString();
      final got4 = last4 == null ? null : last4.substring(last4.length - 4);
      if (r['amount'] != exp['amount']) {
        bad.add('${s['id']} amount ${r['amount']} vs ${exp['amount']}');
      }
      if (got4 != exp['last4']) {
        bad.add('${s['id']} last4 $got4 vs ${exp['last4']}');
      }
    }
    expect(bad, isEmpty);
  });
}
