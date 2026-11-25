import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/tables.dart';
import 'package:paisa_vault/features/pipeline/rule_extractor.dart';
import 'package:paisa_vault/features/sms/sms_classifier.dart';

/// Golden SMS suite. Invented messages in each bank's usual format (no real customer data),
/// each with the fields the rules must read. A failure means the rules would misread a message
/// of that kind. Real-message accuracy is checked on the phones (see docs/PROGRESS.md).
void main() {
  final samples = (jsonDecode(
    File('test/golden/golden_sms.json').readAsStringSync(),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  const classifier = SmsClassifier();
  const rules = RuleExtractor();

  // Per-field results, printed at the end so the score is visible in CI logs.
  final hits = <String, int>{};
  final total = <String, int>{};
  void score(String field, bool ok) {
    total[field] = (total[field] ?? 0) + 1;
    if (ok) hits[field] = (hits[field] ?? 0) + 1;
  }

  tearDownAll(() {
    final line = total.keys
        .map((k) => '$k ${hits[k] ?? 0}/${total[k]}')
        .join(', ');
    // ignore: avoid_print
    print('GOLDEN rules: $line');
  });

  for (final s in samples) {
    final id = s['id'] as String;
    final body = s['body'] as String;
    final want = s['expect'] as Map<String, dynamic>;

    test('golden $id', () {
      final kind = classifier.classify(body).kind.name;
      score('kind', kind == want['kind']);
      expect(kind, want['kind'], reason: 'classification');
      if (want['kind'] != 'transaction') return;

      final f = rules.extract(body);
      void check(String field, Object? wanted, Object? got) {
        if (wanted == null) return;
        score(field, wanted == got);
        expect(got, wanted, reason: field);
      }

      check('amount', want['amountPaise'], f.amountPaise);
      check('direction', want['direction'], f.direction?.name);
      check('bank', want['bank'], f.bank);
      check('last4', want['last4'], f.last4);
      check('reference', want['reference'], f.reference);
      check('channel', want['channel'], f.channel);
    });
  }

  test('every bank we support has golden messages', () {
    final banks = samples
        .map((s) => (s['expect'] as Map<String, dynamic>)['bank'])
        .whereType<String>()
        .toSet();
    expect(banks, containsAll(['HDFC', 'SBI', 'YES', 'RBL', 'INDIAN']));
    expect(Direction.values, isNotEmpty);
  });
}
