import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/features/sms/sms_classifier.dart';

// Invented messages in the common formats. They are not real customer messages.
const cases = <SmsKind, List<String>>{
  SmsKind.transaction: [
    'Rs 499.00 debited from A/c XX1234 on 20-11-26 to VPA swiggy@icici. UPI Ref 123456789012. Not you? Call 18001234567',
    'INR 1,250.00 spent on HDFC Bank Card XX4321 at AMAZON on 20-Nov-26. Avl Lmt INR 80,000.00',
    'Rs.2000.00 credited to A/c XX5678 on 20-11-26 by UPI ref 345678901234',
    'Sent Rs.150.00 From HDFC Bank A/C *1234 To MERCHANT On 20/11/26 Ref 987654321098',
    'Payment of Rs 15,000.00 received towards your card XX9999 on 20-11-26. Thank you',
    'FASTag: Rs 85.00 debited for toll at Plaza on 20-11-26. Balance Rs 640.00',
    'Cash withdrawal of Rs 5,000.00 from ATM on 20-11-26. A/c XX1234',
    'Refund of Rs 300.00 credited to your A/c XX1234 on 20-11-26',
    'Rs 500 spent at ZOMATO with your card XX1111. Get 5% cashback offer on next order. T&C apply',
    'USD 12.99 spent on your credit card XX2222 at NETFLIX on 20-Nov-26',
    'Your txn of Rs 100 failed. Rs 100 credited back to A/c XX1234',
    'A/c XX1234 debited Rs 200.00 on 20-11-26. Rs 200 will reach the merchant in 2 days. Do not share OTP with anyone',
  ],
  SmsKind.otp: [
    '123456 is your OTP for txn of Rs 500.00 at AMAZON. Do not share it with anyone.',
    'Your OTP is 4821. Valid for 10 minutes. Never share it.',
    'OTP for Rs.1,500 payment to FLIPKART is 556677. Do not share.',
    'Use verification code 889900 to log in to your bank account.',
  ],
  SmsKind.promo: [
    'Pre-approved personal loan up to Rs 5,00,000! Apply now at http://bit.ly/abc123',
    'Get 10% cashback up to Rs 100 on UPI payments. Offer valid till 30 Nov. T&C apply',
    'Credit card with zero fee for life. Apply now: https://example.com/card',
    'Congratulations! You have won Rs 50,000. Click to claim',
    'Download the app and get Rs 250 off your first order. Exclusive offer',
  ],
  SmsKind.reminder: [
    'Your HDFC credit card statement is generated. Total amount due Rs 12,345.00. Pay by 05-Dec-26',
    'Rs 999.00 will be debited on 25-Nov-26 towards your mandate NETFLIX',
    'Minimum amount due Rs 1,235.00 on your card XX1111. Due date 05-Dec-26',
    'Reminder: your EMI of Rs 4,500 is scheduled on 03-Dec-26. Keep funds in A/c XX1234',
  ],
  SmsKind.declined: [
    'Your txn of Rs 500 at XYZ STORE was declined. Card XX1111',
    'UPI transaction of Rs 100.00 failed. Amount not debited from A/c XX1234',
    'Payment of Rs 2,000 could not be processed. Please try again',
  ],
  SmsKind.other: [
    'Your available balance is INR 1,234.56 as on 20-11-26',
    'Dear customer, your card has been blocked. Call us',
    'Thank you for banking with us',
  ],
};

void main() {
  const classifier = SmsClassifier();

  for (final entry in cases.entries) {
    for (final body in entry.value) {
      test(
        '${entry.key.name}: ${body.length > 30 ? body.substring(0, 30) : body}',
        () {
          final r = classifier.classify(body);
          expect(r.kind, entry.key, reason: 'got $r');
        },
      );
    }
  }

  test('a charged AutoPay is a transaction, but setting a mandate up or a future debit is not', () {
    const c = SmsClassifier();
    expect(
      c
          .classify(
            'AutoPay (E-mandate) Success!\nFor Acme Tools\nTxn Amt:INR2399.00 Via:HDFC Bank CC 1111',
          )
          .kind,
      SmsKind.transaction,
    );
    expect(
      c
          .classify(
            'Your e-mandate for Rs 499.00 has been successfully registered.',
          )
          .kind,
      SmsKind.reminder,
    );
    expect(
      c
          .classify('Rs 499.00 will be debited on 5 Dec as per your e-mandate.')
          .kind,
      SmsKind.reminder,
    );
  });

  test('a failed payment that was refunded still counts as a credit', () {
    final r = classifier.classify(
      'Txn of Rs 100 failed. Amount reversed to A/c XX1234',
    );
    expect(r.kind, SmsKind.transaction, reason: 'got $r');
  });

  test('the reason code never contains message text', () {
    final r = classifier.classify('Rs 499 debited from A/c XX1234 to SWIGGY');
    expect(r.reason, matches(RegExp(r'^[a-z_]+$')));
  });

  test('empty message is other', () {
    expect(classifier.classify('').kind, SmsKind.other);
  });
}
