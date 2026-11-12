import 'package:flutter_test/flutter_test.dart';
import 'package:llm_bench/postprocess.dart';

void main() {
  test('amount check handles Rs. prefix', () {
    expect(amountInSms(25.0, 'Sent Rs.25.00 From HDFC'), isTrue);
    expect(amountInSms(1480.0, 'Rs 1,480.00 debited'), isTrue);
    expect(amountInSms(25.0, 'Rs 125.00 debited'), isFalse);
    expect(amountInSms(null, 'Rs 25'), isFalse);
  });

  test('sent UPI SMS becomes a debit with fields from the text', () {
    final d = postprocess(
      {'amount': 25.0, 'direction': 'credit', 'last4': '*8435'},
      'Sent Rs.25.00 From HDFC Bank A/C *8435 To Karthik On 05/11/26 Ref 135804839331',
    );
    expect(d['is_transaction'], true);
    expect(d['direction'], 'debit');
    expect(d['bank'], 'HDFC');
    expect(d['last4'], '8435');
    expect(d['date'], '2026-11-05');
    expect(d['reference'], '135804839331');
  });

  test('promo, balance and failed messages are not transactions', () {
    for (final sms in [
      'Get a loan up to Rs 5,00,000 at 10.5%! Apply now',
      'Your A/c XX4821 balance is Rs 9,999.00 as of 05-11-26',
      'UPI of Rs.500.00 from HDFC Bank A/c XX4821 failed. Will be refunded if debited.',
    ]) {
      expect(postprocess({'is_transaction': true, 'amount': 500.0}, sms)['is_transaction'], false);
    }
  });

  test('UPI handle bank is ignored and merchant comes from the handle', () {
    final d = postprocess(
      {'amount': 250.0, 'bank': 'HDFC', 'merchant': 'OKHDFCBANK'},
      'Rs.250.00 credited to your Yes Bank A/c XX7788 from VPA anita@okhdfcbank (UPI Ref 650011223344)',
    );
    expect(d['bank'], 'YES');
    expect(d['merchant'], 'anita');
  });
}
