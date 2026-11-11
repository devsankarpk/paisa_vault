#!/usr/bin/env python3
"""Console app: extract transaction fields from a bank SMS with Gemma 3 1B (Phase 0, Stage A).

Runs the model locally through Ollama (http://localhost:11434). Nothing leaves this Mac.
Mac numbers guide prompt tuning only; the model choice is decided on the real phones (Stage B).

Usage:
  python3 tools/llm_console/sms_extract.py                  # interactive: paste an SMS, press Enter
  python3 tools/llm_console/sms_extract.py -m "Rs 480 debited ..."
  python3 tools/llm_console/sms_extract.py -f testdata/sms_samples.json [-n 10]
Setup: ollama pull gemma3:1b   (see tools/llm_console/README.md)
"""
import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.request

OLLAMA = 'http://localhost:11434'
MODEL = 'gemma3:1b'

CATEGORIES = ['Food', 'Groceries', 'Shopping', 'Bills', 'Travel', 'Health', 'Entertainment',
              'Other', 'Income', 'Transfer']

# Strict output shape (spec 3.2). Ollama constrains generation to this JSON schema.
SCHEMA = {
    'type': 'object',
    'properties': {
        'is_transaction': {'type': 'boolean'},
        'bank': {'type': ['string', 'null']},
        'account_type': {'type': ['string', 'null'],
                         'enum': ['debit_card', 'credit_card', 'savings_account', 'upi', None]},
        'last4': {'type': ['string', 'null']},
        'amount': {'type': ['number', 'null']},
        'direction': {'type': ['string', 'null'], 'enum': ['debit', 'credit', None]},
        'merchant': {'type': ['string', 'null']},
        'channel': {'type': ['string', 'null'],
                    'enum': ['UPI', 'NEFT', 'IMPS', 'ATM', 'POS', 'online', None]},
        'reference': {'type': ['string', 'null']},
        'date': {'type': ['string', 'null']},
        'category': {'type': ['string', 'null'], 'enum': CATEGORIES + [None]},
    },
    'required': ['is_transaction', 'bank', 'account_type', 'last4', 'amount', 'direction',
                 'merchant', 'channel', 'reference', 'date', 'category'],
}

PROMPT = """You read Indian bank SMS messages and extract the transaction as JSON.
Rules:
- is_transaction is false for OTPs, promotions, balance alerts and anything with no money moved.
- amount is the transaction amount as a number (not the balance). Copy it exactly from the SMS.
- direction is "debit" when money left the account, "credit" when it arrived.
- last4 is the last 4 digits of the card or account, as text.
- date is YYYY-MM-DD if the SMS gives a date, else null.
- category must be one of: {cats}.
- Use null for anything the SMS does not say. Never guess.

Examples:
SMS: Rs.250.00 spent on HDFC Bank Card x1234 at ZOMATO on 12-10-26. Avl limit Rs XXXX
JSON: {{"is_transaction": true, "bank": "HDFC", "account_type": "credit_card", "last4": "1234", "amount": 250.0, "direction": "debit", "merchant": "ZOMATO", "channel": "POS", "reference": null, "date": "2026-10-12", "category": "Food"}}
SMS: Rs 5,000.00 credited to A/c XX9876 on 01-11-26 by NEFT from ACME PVT LTD. Ref 998877. -SBI
JSON: {{"is_transaction": true, "bank": "SBI", "account_type": "savings_account", "last4": "9876", "amount": 5000.0, "direction": "credit", "merchant": "ACME PVT LTD", "channel": "NEFT", "reference": "998877", "date": "2026-11-01", "category": "Income"}}
SMS: 482913 is your OTP for login. Do not share it with anyone.
JSON: {{"is_transaction": false, "bank": null, "account_type": null, "last4": null, "amount": null, "direction": null, "merchant": null, "channel": null, "reference": null, "date": null, "category": null}}

Now the real SMS.
SMS:
\"\"\"{sms}\"\"\"
"""


def ollama(path, payload=None, timeout=120):
    req = urllib.request.Request(
        OLLAMA + path, data=json.dumps(payload).encode() if payload is not None else None,
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def check_ready(model):
    try:
        names = [m['name'] for m in ollama('/api/tags', timeout=5).get('models', [])]
    except (urllib.error.URLError, OSError):
        sys.exit('Ollama is not running. Start it with: ollama serve   (or open the Ollama app)')
    if not any(n == model or n.startswith(model + ':') or n.split(':')[0] == model for n in names):
        sys.exit(f'Model {model} not installed. Run: ollama pull {model}')


def amount_in_sms(amount, sms):
    """Safety check from spec 3.2: the amount the model returns must literally appear in the SMS."""
    if amount is None:
        return False
    plain = sms.replace(',', '')
    candidates = {f'{amount:.2f}', f'{amount:g}', str(int(amount)) if float(amount).is_integer() else ''}
    return any(c and re.search(r'(?<!\d)(?<!\d\.)' + re.escape(c) + r'(?!\d|\.\d)', plain) for c in candidates)


BANK_NAMES = [('HDFC', r'hdfc'), ('SBI', r'\bsbi\b|state bank'), ('ICICI', r'icici'),
              ('AXIS', r'axis'), ('YES', r'yes\s*bank')]
DEBIT_WORDS = r'\b(debited|sent|spent|paid|withdrawn|purchase|purchased|deducted|payment of)\b'
CREDIT_WORDS = r'\b(credited|received|deposited|refund(?:ed)?)\b'
FAILED_WORDS = r'\b(failed|declined|unsuccessful)\b'


def postprocess(data, sms):
    """Cheap, deterministic fixes for mistakes the 1B model makes. Rules win over the model."""
    low = sms.lower()
    debit, credit = re.search(DEBIT_WORDS, low), re.search(CREDIT_WORDS, low)
    # No money moved: OTPs, promos, balance alerts (no debit/credit word) and failed attempts.
    if not (debit or credit) or re.search(FAILED_WORDS, low):
        data['is_transaction'] = False
        return data
    if data.get('amount') is not None and (debit or credit):
        data['is_transaction'] = True
        if debit and not credit:
            data['direction'] = 'debit'
        elif credit and not debit:
            data['direction'] = 'credit'
    # UPI handles like anita@okhdfcbank name the other party's bank, so ignore them. First mention wins.
    text = re.sub(r'\S*@\S*', ' ', low)
    found = [(m.start(), name) for name, pat in BANK_NAMES if (m := re.search(pat, text))]
    if found:
        data['bank'] = min(found)[1]
    if re.search(r'\bupi\b|\bvpa\b|\w@\w', low):
        data['channel'] = 'UPI'
        if data.get('account_type') in (None, 'credit_card') and 'credit card' not in low:
            data['account_type'] = 'savings_account'
    ref = re.search(r'\bref(?:erence)?\.?(?:\s*(?:no|number|id)\.?)?[\s:#-]*(?:upi[\s:-]*)?(\d{6,})', low)
    if ref:
        data['reference'] = ref.group(1)
    d = re.search(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2}|\d{4})\b', sms)
    if d:  # Indian SMS dates are day first
        day, mon, yr = int(d.group(1)), int(d.group(2)), int(d.group(3))
        yr += 2000 if yr < 100 else 0
        if 1 <= day <= 31 and 1 <= mon <= 12:
            data['date'] = f'{yr:04d}-{mon:02d}-{day:02d}'
    if data.get('last4'):
        digits = re.sub(r'\D', '', str(data['last4']))
        data['last4'] = digits[-4:] if len(digits) >= 4 else None
    handle = re.search(r'([\w.\-]+)@(\w+)', sms)
    if handle and (data.get('merchant') or '').lower() in ('', 'vpa', 'upi', handle.group(2).lower()):
        data['merchant'] = handle.group(1)
    if data.get('reference'):
        digits = re.search(r'\d{6,}', str(data['reference']))
        data['reference'] = digits.group(0) if digits else None
    if data.get('merchant'):
        data['merchant'] = re.sub(r'^(vpa|upi)[\s:-]+', '', data['merchant'], flags=re.I).strip()
    return data


def extract(sms, model=MODEL):
    t0 = time.perf_counter()
    payload = {
        'model': model, 'stream': False, 'format': SCHEMA,
        'options': {'temperature': 0, 'num_predict': 300},
        'messages': [{'role': 'user', 'content': PROMPT.format(cats=', '.join(CATEGORIES), sms=sms)}],
    }
    if model.startswith('qwen3'):
        payload['think'] = False  # skip the reasoning phase: too slow for a per-SMS task
    res = ollama('/api/chat', payload)
    secs = time.perf_counter() - t0
    try:
        data = json.loads(res['message']['content'])
    except (json.JSONDecodeError, KeyError):
        return {'error': 'model did not return valid JSON', 'raw': res.get('message', {}).get('content')}, secs
    data = postprocess(data, sms)
    if data.get('is_transaction'):
        data['status'] = 'ok' if amount_in_sms(data.get('amount'), sms) else 'please_confirm'
    return data, secs


def show(sms, model):
    data, secs = extract(sms, model)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    print(f'-- {secs:.1f}s' + ('  (amount not found in SMS: please confirm)'
                              if data.get('status') == 'please_confirm' else ''))
    return data, secs


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('-m', '--message', help='one SMS text')
    ap.add_argument('-f', '--file', help='anonymised corpus JSON from anonymise.py')
    ap.add_argument('-n', type=int, default=0, help='with --file, only the first N messages')
    ap.add_argument('--model', default=MODEL)
    a = ap.parse_args(argv)
    check_ready(a.model)

    if a.message:
        show(a.message, a.model)
    elif a.file:
        samples = json.load(open(a.file, encoding='utf-8'))
        samples = samples[:a.n] if a.n else samples
        times, confirm = [], 0
        for s in samples:
            print(f"\n[{s['id']}] {s['body']}")
            data, secs = show(s['body'], a.model)
            times.append(secs)
            confirm += data.get('status') == 'please_confirm'
        if times:
            print(f'\n{len(times)} messages, average {sum(times) / len(times):.1f}s, '
                  f'{confirm} flagged please_confirm')
    else:
        print(f'Model {a.model}. Paste an SMS on one line and press Enter. Empty line quits.')
        while True:
            try:
                sms = input('\nSMS> ').strip()
            except EOFError:
                break
            if not sms:
                break
            show(sms, a.model)
    return 0


if __name__ == '__main__':
    sys.exit(main())
