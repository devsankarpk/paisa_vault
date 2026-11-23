import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/tables.dart';
import 'package:paisa_vault/features/pipeline/extraction_pipeline.dart';
import 'package:paisa_vault/features/pipeline/model_reply.dart';
import 'package:paisa_vault/testing/fakes.dart';

const cats = ['Food', 'Shopping', 'Bills', 'Other', 'Income', 'Transfer'];

void main() {
  group('model reply check', () {
    ModelReply? parse(String s) => parseModelReply(s, categories: cats);

    test('accepts a valid reply, even inside extra text or a think block', () {
      expect(
        parse('{"merchant": "ZOMATO", "category": "Food", "channel": "POS"}')!
            .merchant,
        'ZOMATO',
      );
      expect(
        parse(
          '<think>hmm</think>Here: {"merchant": null, "category": "Other", "channel": "ATM"}',
        )!.channel,
        'ATM',
      );
    });

    test('rejects what is not valid', () {
      expect(parse('no json here'), isNull);
      expect(
        parse('{"merchant": "A", "category": "Pizza", "channel": "UPI"}'),
        isNull,
      ); // not in list
      expect(
        parse(
          '{"merchant": "A", "category": "Food", "channel": "CARRIER PIGEON"}',
        ),
        isNull,
      );
      expect(
        parse('{"merchant": 5, "category": "Food", "channel": "UPI"}'),
        isNull,
      );
      expect(parse('{"merchant": "A", "extra": "x"}'), isNull);
      expect(parse('{"merchant": "${'x' * 200}", "category": "Food"}'), isNull);
      expect(parse('[1, 2]'), isNull);
      expect(parse('{"merchant": "A", "category": '), isNull);
    });

    test('empty strings become null', () {
      final r = parse(
        '{"merchant": " ", "category": "Food", "channel": null}',
      )!;
      expect(r.merchant, isNull);
      expect(r.category, 'Food');
    });
  });

  group('pipeline', () {
    const good = '{"merchant": "ZOMATO", "category": "Food", "channel": "POS"}';
    const sms =
        'Rs.250.00 spent on HDFC Bank Card x1234 on 12-10-26 at your favourite place.';

    test(
      'rules plus a valid model reply give a confirmed transaction',
      () async {
        final llm = FakeLlmEngine([good]);
        final r = await ExtractionPipeline(llm, categories: cats).process(sms);
        final t = r.transaction!;
        expect(t.amountPaise, 25000);
        expect(t.direction, Direction.debit);
        expect(t.bank, 'HDFC');
        expect(t.last4, '1234');
        expect(t.date, DateTime(2026, 10, 12));
        expect(t.merchant, 'ZOMATO');
        expect(t.category, 'Food');
        expect(t.channel, 'POS');
        expect(t.status, TransactionStatus.confirmed);
        expect(t.modelId, 'fake-model');
        expect(t.promptVersion, 'p1');
        expect(llm.prompts.length, 1);
      },
    );

    test('a rule-found merchant is trusted over the model', () async {
      final llm = FakeLlmEngine([
        '{"merchant": "WRONG", "category": "Food", "channel": "POS"}',
      ]);
      final r = await ExtractionPipeline(
        llm,
        categories: cats,
      ).process('Rs 5 spent on card XX1 at ZOMATO on 12-10-26.');
      expect(r.transaction!.merchant, 'ZOMATO');
    });

    test('a bad reply is retried once and then used', () async {
      final llm = FakeLlmEngine(['not json', good]);
      final r = await ExtractionPipeline(llm, categories: cats).process(sms);
      expect(llm.prompts.length, 2);
      expect(r.transaction!.status, TransactionStatus.confirmed);
      expect(r.transaction!.category, 'Food');
    });

    test(
      'two bad replies mean please confirm, keeping the rule fields',
      () async {
        final llm = FakeLlmEngine(['nope', '{"category": "Pizza"}']);
        final r = await ExtractionPipeline(llm, categories: cats).process(sms);
        final t = r.transaction!;
        expect(llm.prompts.length, 2);
        expect(t.status, TransactionStatus.pleaseConfirm);
        expect(t.confirmReason, 'bad_reply');
        expect(t.amountPaise, 25000);
        expect(t.category, isNull);
      },
    );

    test('a model that throws also means please confirm', () async {
      final llm = FakeLlmEngine([Exception('boom')]);
      final r = await ExtractionPipeline(llm, categories: cats).process(sms);
      expect(r.transaction!.status, TransactionStatus.pleaseConfirm);
      expect(r.transaction!.confirmReason, 'model_error');
      expect(r.transaction!.amountPaise, 25000);
    });

    test(
      'no amount or no direction gives no transaction and no model call',
      () async {
        final llm = FakeLlmEngine([good]);
        final p = ExtractionPipeline(llm, categories: cats);
        expect(
          (await p.process('Your account was credited')).reason,
          NoTransaction.noAmount,
        );
        expect(
          (await p.process('Balance is Rs 1,234.00')).reason,
          NoTransaction.noDirection,
        );
        expect(llm.prompts, isEmpty);
      },
    );

    test('the prompt holds the SMS and only the allowed categories', () async {
      final llm = FakeLlmEngine([good]);
      await ExtractionPipeline(llm, categories: cats).process(sms);
      expect(
        llm.prompts.single,
        contains('Food, Shopping, Bills, Other, Income, Transfer'),
      );
      expect(llm.prompts.single.trimRight().endsWith(sms), true);
    });
  });
}
