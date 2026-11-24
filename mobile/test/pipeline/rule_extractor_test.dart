import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/tables.dart';
import 'package:paisa_vault/features/pipeline/amount_check.dart';
import 'package:paisa_vault/features/pipeline/rule_extractor.dart';

// Invented messages in common bank formats. They are not real customer messages.
void main() {
  const rules = RuleExtractor();

  group('amounts in paise', () {
    test('plain, decimals and Indian lakh grouping', () {
      expect(parsePaise('499'), 49900);
      expect(parsePaise('499.00'), 49900);
      expect(parsePaise('12.5'), 1250);
      expect(parsePaise('1,250.75'), 125075);
      expect(parsePaise('1,00,000.50'), 10000050);
      expect(parsePaise('abc'), isNull);
    });

    test('read from the SMS text', () {
      expect(
        rules.extract('Rs 499.00 debited from A/c XX1234').amountPaise,
        49900,
      );
      expect(
        rules.extract('INR 1,250.00 spent on card XX4321').amountPaise,
        125000,
      );
      expect(
        rules.extract('Rs.2,00,000.00 credited to A/c XX1').amountPaise,
        20000000,
      );
      expect(rules.extract('₹75 paid to TESTSHOP').amountPaise, 7500);
    });
  });

  group('amount safety check', () {
    test('amount appears in the text', () {
      expect(amountAppearsInSms(49900, 'Rs 499.00 debited'), true);
      expect(amountAppearsInSms(49900, 'Rs 499 debited'), true);
      expect(amountAppearsInSms(125000, 'INR 1,250.00 spent'), true);
      expect(amountAppearsInSms(1250, 'Rs 12.5 paid'), true);
    });

    test('an invented amount is rejected', () {
      expect(amountAppearsInSms(50000, 'Rs 499.00 debited'), false);
      // 49 is only part of 499
      expect(amountAppearsInSms(4900, 'Rs 499.00 debited'), false);
      // a decimal tail is not an amount by itself
      expect(amountAppearsInSms(99, 'Rs 499.99 debited'), false);
    });
  });

  group('direction', () {
    test('debit and credit words', () {
      expect(
        rules.extract('Rs 5 debited from A/c XX1').direction,
        Direction.debit,
      );
      expect(
        rules.extract('Rs 5 spent on card XX1').direction,
        Direction.debit,
      );
      expect(
        rules.extract('Sent Rs 5 from A/c XX1').direction,
        Direction.debit,
      );
      expect(
        rules.extract('Rs 5 credited to A/c XX1').direction,
        Direction.credit,
      );
      expect(
        rules.extract('Refund of Rs 5 received').direction,
        Direction.credit,
      );
    });

    test('the first word describes this account', () {
      expect(
        rules
            .extract('Rs 5 debited from A/c XX1 and credited to A/c XX2')
            .direction,
        Direction.debit,
      );
      expect(
        rules
            .extract(
              'Rs 5 credited to A/c XX1 by transfer, debited from A/c XX2',
            )
            .direction,
        Direction.credit,
      );
    });

    test('no movement word means no direction', () {
      expect(rules.extract('Balance Rs 1,234.00').direction, isNull);
    });
  });

  group('bank, card and account', () {
    test('bank from the text, ignoring UPI handles', () {
      expect(rules.extract('Rs 5 spent on HDFC Bank Card XX1').bank, 'HDFC');
      expect(rules.extract('Rs 5 debited A/c XX1 by SBI. UPI').bank, 'SBI');
      expect(
        rules.extract('Rs 5 debited to anita@okhdfcbank via YES BANK UPI').bank,
        'YES',
      );
      expect(
        rules.extract('Rs 5 spent on your RBL Bank Credit Card XX9').bank,
        'RBL',
      );
      expect(rules.extract('Rs 5 debited, Indian Bank A/c XX1').bank, 'INDIAN');
      expect(rules.extract('Rs 5 debited, A/c XX1').bank, isNull);
    });

    test('account kind', () {
      expect(
        rules.extract('Rs 5 spent on Credit Card XX1').accountKind,
        AccountKind.creditCard,
      );
      expect(
        rules.extract('Rs 5 spent on Card XX1').accountKind,
        AccountKind.debitCard,
      );
      expect(
        rules.extract('Rs 5 debited from A/c XX1').accountKind,
        AccountKind.savings,
      );
    });

    test('last four digits', () {
      expect(rules.extract('debited from A/c XX1234').last4, '1234');
      expect(rules.extract('spent on card ending 4321').last4, '4321');
      expect(rules.extract('debited from A/c 00112233445566').last4, '5566');
      expect(rules.extract('debited from your account').last4, isNull);
    });
  });

  group('channel, reference, date', () {
    test('channel', () {
      expect(rules.extract('Rs 5 debited via UPI to a@b').channel, 'UPI');
      expect(rules.extract('credited by NEFT from ACME').channel, 'NEFT');
      expect(rules.extract('sent by IMPS').channel, 'IMPS');
      expect(rules.extract('Rs 2000 withdrawn at SBI ATM').channel, 'ATM');
      expect(rules.extract('Rs 5 spent on card XX1 at SHOP').channel, isNull);
    });

    test('reference numbers', () {
      expect(
        rules.extract('debited. UPI Ref 123456789012. Not you?').reference,
        '123456789012',
      );
      expect(rules.extract('credited. Ref No 998877').reference, '998877');
      expect(
        rules.extract('debited. txn id 123456789012').reference,
        '123456789012',
      );
      expect(rules.extract('debited. Ref 12').reference, isNull);
    });

    test('dates, day first', () {
      expect(rules.extract('debited on 20-11-26').date, DateTime(2026, 11, 20));
      expect(
        rules.extract('debited on 05/11/2026').date,
        DateTime(2026, 11, 5),
      );
      expect(
        rules.extract('debited on 2026-10-18').date,
        DateTime(2026, 10, 18),
      );
      expect(rules.extract('debited on 02-Nov-26').date, DateTime(2026, 11, 2));
      expect(rules.extract('debited on 12Oct26').date, DateTime(2026, 10, 12));
      expect(rules.extract('debited on 31-02-26').date, isNull);
      expect(rules.extract('debited today').date, isNull);
    });
  });

  group('merchant by known phrasings', () {
    test('payee named in the text', () {
      expect(
        rules.extract('Rs 5 spent on card XX1 at ZOMATO on 12-10-26.').merchant,
        'ZOMATO',
      );
      expect(
        rules.extract('Rs 5 debited, UPI-SWIGGY-swiggy@icici-123').merchant,
        'SWIGGY',
      );
      expect(
        rules
            .extract('Rs 5 credited by NEFT from ACME PVT LTD. Ref 99')
            .merchant,
        'ACME PVT LTD',
      );
      expect(
        rules.extract('Sent Rs 5 To TESTSHOP On 20/11/26 Ref 1').merchant,
        'TESTSHOP',
      );
    });

    test('UPI handle names the payee', () {
      expect(
        rules.extract('Rs 5 debited from A/c XX1 to VPA anita@okaxis').merchant,
        'anita',
      );
    });

    test('unknown phrasing leaves it to the model', () {
      expect(rules.extract('Rs 5 debited from A/c XX1').merchant, isNull);
      expect(rules.extract('Rs 2000 withdrawn at SBI ATM').merchant, isNull);
    });
  });

  group('last 4 digits in brackets', () {
    for (final (text, want) in [
      ('Rs 5 spent on HDFC Bank Card (1234) at SHOP', '1234'),
      ('Rs 5 spent on Credit Card ending (XX1234) at SHOP', '1234'),
      ('Rs 5 debited from A/c (XXXX1234) on 12-10-26', '1234'),
      ('Rs 5 spent on card no. [x5678] at SHOP', '5678'),
      ('Rs 5 spent on your card ending with (4321)', '4321'),
      ('Rs 5 spent at SHOP using (XX9876) on 12-10-26', '9876'),
    ]) {
      test(text, () => expect(const RuleExtractor().extract(text).last4, want));
    }
  });
}
