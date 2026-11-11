import unittest

import sms_extract as x

BLANK = dict(is_transaction=False, bank=None, account_type=None, last4=None, amount=None,
             direction=None, merchant=None, channel=None, reference=None, date=None, category=None)


class AmountCheck(unittest.TestCase):
    def test_found(self):
        self.assertTrue(x.amount_in_sms(25.0, 'Sent Rs.25.00 From HDFC'))
        self.assertTrue(x.amount_in_sms(1480.0, 'Rs 1,480.00 debited'))

    def test_not_found(self):
        self.assertFalse(x.amount_in_sms(25.0, 'Rs 125.00 debited'))
        self.assertFalse(x.amount_in_sms(None, 'Rs 25'))


class Postprocess(unittest.TestCase):
    def test_sent_upi_is_debit(self):
        sms = 'Sent Rs.25.00 From HDFC Bank A/C *8435 To Karthik On 05/11/26 Ref 135804839331'
        d = x.postprocess(dict(BLANK, amount=25.0, direction='credit', last4='*8435'), sms)
        self.assertEqual((d['is_transaction'], d['direction'], d['bank']), (True, 'debit', 'HDFC'))
        self.assertEqual((d['last4'], d['date'], d['reference']), ('8435', '2026-11-05', '135804839331'))

    def test_upi_channel_and_vpa_prefix(self):
        d = x.postprocess(dict(BLANK, amount=480.0, merchant='VPA swiggy@icici'),
                          'Rs.480.00 debited to VPA swiggy@icici - HDFC Bank')
        self.assertEqual((d['channel'], d['merchant'], d['bank']), ('UPI', 'swiggy@icici', 'HDFC'))

    def test_promo_balance_and_failed_are_not_transactions(self):
        for sms in ['Get a loan up to Rs 5,00,000 at 10.5%! Apply now',
                    'Your A/c XX4821 balance is Rs 9,999.00 as of 05-11-26',
                    'UPI of Rs.500.00 from HDFC Bank A/c XX4821 failed. Will be refunded if debited.']:
            d = x.postprocess(dict(BLANK, is_transaction=True, amount=500.0), sms)
            self.assertFalse(d['is_transaction'], sms)

    def test_upi_handle_bank_ignored_and_merchant_from_handle(self):
        sms = 'Rs.250.00 credited to your Yes Bank A/c XX7788 from VPA anita@okhdfcbank (UPI Ref 650011223344)'
        d = x.postprocess(dict(BLANK, amount=250.0, bank='HDFC', merchant='OKHDFCBANK'), sms)
        self.assertEqual((d['bank'], d['merchant']), ('YES', 'anita'))

    def test_reference_keeps_digits_only(self):
        d = x.postprocess(dict(BLANK, amount=1.0, reference='P2M/630011223344'), 'Rs 1 debited')
        self.assertEqual(d['reference'], '630011223344')

    def test_otp_is_not_transaction(self):
        d = x.postprocess(dict(BLANK, is_transaction=True), '482913 is your OTP. Do not share.')
        self.assertFalse(d['is_transaction'])


if __name__ == '__main__':
    unittest.main()
