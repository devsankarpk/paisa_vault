import json
import os
import tempfile
import unittest

import anonymise as an


class Normalise(unittest.TestCase):
    def test_sender(self):
        self.assertEqual(an.normalise_sender('VM-HDFCBK'), 'HDFCBK')
        self.assertEqual(an.normalise_sender('AX-SBIINB-S'), 'SBIINB')
        self.assertEqual(an.normalise_sender('JD-ICICIB-T'), 'ICICIB')

    def test_iphone_sender_tags(self):
        self.assertEqual(an.normalise_sender('TX-SBIBNK(SMSFP)'), 'SBIBNK')
        self.assertEqual(an.normalise_sender('HDFCBK-S'), 'HDFCBK')
        self.assertEqual(an.normalise_sender('CP-YESBNK-S(SMSFT)'), 'YESBNK')
        self.assertEqual(an.normalise_sender('VM-ICICIT(SMSFT_RM)'), 'ICICIT')
        self.assertEqual(an.bank_for(an.normalise_sender('AX-YESBAK(SMSFT)')), 'YES')

    def test_bank(self):
        self.assertEqual(an.bank_for('HDFCBK'), 'HDFC')
        self.assertEqual(an.bank_for('AXISBK'), 'AXIS')
        self.assertEqual(an.bank_for('YESBNK'), 'YES')
        self.assertIsNone(an.bank_for('AMAZON'))

    def test_other_banks(self):
        for raw, bank in [('VM-KOTAKB', 'KOTAK'), ('AD-PNBSMS', 'PNB'), ('BZ-CANBNK', 'CANARA'),
                          ('VK-BOBSMS-S', 'BOB'), ('JD-IDFCFB', 'IDFC'), ('AX-AUBANK', 'AU'),
                          ('VM-IPPBMS', 'IPPB'), ('CP-FEDBNK-T', 'FEDERAL')]:
            self.assertEqual(an.bank_for(an.normalise_sender(raw)), bank, raw)

    def test_short_codes_do_not_overmatch(self):
        self.assertIsNone(an.bank_for('AUTOMT'))
        self.assertIsNone(an.bank_for('AUCARD'))
        self.assertIsNone(an.bank_for('UCO'))

    def test_core_banks(self):
        self.assertEqual(set(an.CORE_BANKS), {'HDFC', 'SBI', 'ICICI', 'AXIS', 'YES'})
        self.assertTrue(set(an.CORE_BANKS) <= set(an.BANK_CODES))


class Mask(unittest.TestCase):
    def test_keeps_amount_and_last4(self):
        t = an.anonymise('Rs.480.00 debited from A/c XX4821 on 21-10-26 to VPA swiggy@icici. Ref 612345678901')
        self.assertIn('Rs.480.00', t)
        self.assertIn('XX4821', t)
        self.assertIn('swiggy@icici', t)
        self.assertIn('612345678901', t)  # reference number kept on purpose

    def test_long_account_keeps_last4(self):
        t = an.anonymise('Your A/c 50100123456789 is debited Rs 100')
        self.assertNotIn('50100123456789', t)
        self.assertIn('XXXXXXXXXX6789', t)

    def test_phone_and_personal_upi(self):
        t = an.anonymise('Sent to 9876543210@ybl, call 9123456789 or +91 98765 43210')
        self.assertNotIn('9876543210', t)
        self.assertNotIn('9123456789', t)
        self.assertIn('<UPI>', t)

    def test_balance_masked_amount_kept(self):
        t = an.anonymise('Rs 2,499.00 spent on card. Avl Bal Rs 84,250.50')
        self.assertIn('Rs 2,499.00', t)
        self.assertNotIn('84,250', t)
        self.assertIn('Avl Bal Rs XXXX', t)

    def test_name_url_email(self):
        t = an.anonymise('Dear SANKAR, visit https://hdfcbank.com/x or mail me@mail.com')
        self.assertIn('Dear <NAME>', t)
        self.assertIn('<URL>', t)
        self.assertIn('<EMAIL>', t)
        self.assertNotIn('SANKAR', t)

    def test_dear_customer_kept(self):
        self.assertIn('Dear Customer', an.anonymise('Dear Customer, Rs 5 debited'))


class EndToEnd(unittest.TestCase):
    def test_blocks_filters_and_dedupes(self):
        raw = ('sender: VM-HDFCBK\ndate: 2026-10-21\nRs 480 debited A/c XX4821. Avl Bal Rs 9,999\n---\n'
               'sender: VM-HDFCBK\ndate: 2026-10-22\nRs 480 debited A/c XX4821. Avl Bal Rs 9,999\n---\n'
               'sender: AMAZON\nBuy now\n')
        with tempfile.TemporaryDirectory() as d:
            src, out, rev = (os.path.join(d, n) for n in ('in.txt', 'out.json', 'rev.txt'))
            open(src, 'w').write(raw)
            an.main([src, '--format', 'blocks', '-o', out, '--review', rev])
            data = json.load(open(out))
        self.assertEqual(len(data), 1)  # duplicate body and non-bank sender dropped
        self.assertEqual(data[0]['bank_hint'], 'HDFC')
        self.assertNotIn('9,999', data[0]['body'])
        self.assertTrue(data[0]['core'])

    def test_bonus_bank_flagged_not_core(self):
        raw = 'sender: VM-KOTAKB\nRs 250 debited A/c XX1234\n---\n'
        with tempfile.TemporaryDirectory() as d:
            src, out, rev = (os.path.join(d, n) for n in ('in.txt', 'out.json', 'rev.txt'))
            open(src, 'w').write(raw)
            an.main([src, '--format', 'blocks', '-o', out, '--review', rev])
            data = json.load(open(out))
        self.assertEqual(data[0]['bank_hint'], 'KOTAK')
        self.assertFalse(data[0]['core'])

    def test_list_senders_prints_no_body(self):
        raw = 'sender: VM-HDFCBK\nSECRET BODY Rs 5\n---\nsender: XX-MYSTRY\nhello\n---\n'
        with tempfile.TemporaryDirectory() as d:
            src = os.path.join(d, 'in.txt')
            open(src, 'w').write(raw)
            import io, contextlib
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                an.main([src, '--format', 'blocks', '--list-senders'])
        out = buf.getvalue()
        self.assertIn('HDFCBK', out)
        self.assertIn('MYSTRY', out)
        self.assertNotIn('SECRET', out)


if __name__ == '__main__':
    unittest.main()
