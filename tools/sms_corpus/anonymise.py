#!/usr/bin/env python3
"""Turn raw exported SMS into an anonymised corpus for Paisa Vault.

Raw files stay in testdata/raw/ (git-ignored). Output goes to
testdata/sms_samples.json. Review the output by eye before committing it.

Usage:
  python3 -I tools/sms_corpus/anonymise.py INPUT --format adb|xml|blocks|chatdb [--all] [-o OUT]
See tools/sms_corpus/README.md for how to export from each phone.
"""
import argparse
import hashlib
import json
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

# Normalised sender codes (after stripping the operator prefix) per bank. The first five are the
# core banks counted in the Phase 0 scorecard; the rest are bonus samples for format variety.
# Codes are best-effort and vary by operator: run with --list-senders to find any that are missing.
CORE_BANKS = ('HDFC', 'SBI', 'ICICI', 'AXIS', 'YES')
BANK_CODES = {
    'HDFC': ['HDFCBK', 'HDFCBN', 'HDFCBANK'],
    'SBI': ['SBIINB', 'SBIUPI', 'SBICRD', 'SBIPSG', 'SBMSMS', 'ATMSBI', 'SBIBNK'],
    'ICICI': ['ICICIB', 'ICICIT', 'ICICIO', 'ICIBNK'],
    'AXIS': ['AXISBK', 'AXISBN', 'AXISMB'],
    'YES': ['YESBNK', 'YESBKS', 'YESBNKL', 'YESBAK'],
    'PNB': ['PNBSMS', 'PNBBNK', 'PNBONE'],
    'BOB': ['BOBSMS', 'BOBTXN', 'BARODA', 'BOBCRD'],
    'CANARA': ['CANBNK', 'CANARA', 'CANBKS'],
    'UNION': ['UNIONB', 'UBOIBK', 'UNIONS'],
    'KOTAK': ['KOTAKB', 'KOTAKM', 'KMBLTD'],
    'INDUSIND': ['INDUSB', 'INDUSL', 'INDUSI'],
    'IDFC': ['IDFCFB', 'IDFCBK'],
    'FEDERAL': ['FEDBNK', 'FEDFIB', 'FEDERL'],
    'BOI': ['BOIIND', 'BOIBNK'],
    'INDIAN': ['INDIAN', 'INDBKS', 'INDBNK'],
    'CENTRAL': ['CBOIND', 'CENTRL'],
    'UCO': ['UCOBNK', 'UCOSMS'],
    'IDBI': ['IDBIBK', 'IDBIBN'],
    'RBL': ['RBLBNK', 'RBLCRD'],
    'AU': ['AUBANK', 'AUSFBL', 'AUSFB'],
    'BANDHAN': ['BANDHN', 'BDHNBK'],
    'SIB': ['SIBSMS', 'SOUTHI'],
    'KARNATAKA': ['KARBNK', 'KBLBNK'],
    'PAYTMBANK': ['PAYTMB', 'PYTMBK'],
    'IPPB': ['IPPBMS', 'IPPBNK'],
}


def normalise_sender(raw):
    """VM-HDFCBK, AX-SBIINB-S, HDFCBK-S(SMSFT) -> HDFCBK, SBIINB, HDFCBK (strip prefix, suffix, iPhone tag)."""
    s = re.sub(r'\s*\([^)]*\)\s*$', '', raw.strip().upper())  # iPhone adds e.g. (SMSFT), (SMSFP_RM)
    m = re.match(r'^(?:[A-Z]{2}-)?([A-Z0-9]{3,11})(?:-[STPG])?$', s)
    return m.group(1) if m else s


def bank_for(sender):
    """Exact code match; codes of 6+ characters also match on their first five (HDFCBK ~ HDFCBX).
    Short codes match exactly only, so AUTOMT does not count as AU."""
    for bank, codes in BANK_CODES.items():
        if sender in codes or any(len(c) >= 6 and sender.startswith(c[:5]) for c in codes):
            return bank
    return None


def mask_digits(match):
    digits = re.sub(r'\D', '', match.group(0))
    return 'X' * (len(digits) - 4) + digits[-4:]


def anonymise(text):
    t = text
    t = re.sub(r'https?://\S+|\b(?:bit\.ly|tinyurl\.com)/\S+', '<URL>', t)
    t = re.sub(r'[\w.+-]+@[\w-]+\.[\w.]+', '<EMAIL>', t)
    # UPI handles whose local part is a phone number identify a person; named merchant handles stay.
    t = re.sub(r'\b\d{8,12}@[a-z]+\b', '<UPI>', t, flags=re.I)
    t = re.sub(r'(?:\+91[\s-]?|\b0)?\b[6-9]\d{9}\b', '<PHONE>', t)
    # Long digit runs (account, card, mobile-linked) keep only the last 4. Reference numbers
    # are kept: they are needed for duplicate-detection tests and are not personal.
    t = re.sub(r'(?i)((?:a/c|acct?|account|card|ending|no\.?)\D{0,12})(\d{5,})',
               lambda m: m.group(1) + mask_digits(re.search(r'\d+', m.group(2))), t)
    t = re.sub(r'\b[Xx*]{2,}\d{2,6}\b', lambda m: m.group(0), t)  # already masked by the bank
    # Balances reveal finances. The transaction amount is kept, the balance is masked.
    t = re.sub(r'(?i)((?:avl\.?|available|avail\.?|total|clear|ledger)?\s*(?:bal(?:ance)?|bal\.)\s*(?:is|:|-)?\s*)'
               r'((?:rs\.?|inr|₹)\s*)?[\d,]+(?:\.\d+)?(?:\s*(?:cr|dr))?',
               lambda m: m.group(1) + (m.group(2) or 'Rs ') + 'XXXX', t)
    # Greeting names: "Dear SANKAR", "Hi Sankar Kumar,"
    t = re.sub(r'\b(Dear|Hi|Hello)\s+(?!Customer|Card|Member|User|Sir|Madam)[A-Z][A-Za-z.]+(?:\s+[A-Z][A-Za-z.]+){0,2}',
               r'\1 <NAME>', t)
    return t


def parse_adb(path):
    rows, cur = [], None
    for line in open(path, encoding='utf-8', errors='replace'):
        if line.startswith('Row:'):
            if cur:
                rows.append(cur)
            cur = line.rstrip('\n')
        elif cur is not None:
            cur += '\n' + line.rstrip('\n')
    if cur:
        rows.append(cur)
    out = []
    for r in rows:
        m = re.match(r'Row: \d+ address=(.*?), body=(.*), date=(\d+)(?:, sub_id=(-?\d+))?\s*$', r, re.S)
        if m:
            out.append({'sender': m.group(1), 'body': m.group(2),
                        'ts': int(m.group(3)) / 1000, 'sim': m.group(4)})
    return out


def parse_xml(path):
    out = []
    for sms in ET.parse(path).getroot().iter('sms'):
        out.append({'sender': sms.get('address', ''), 'body': sms.get('body', ''),
                    'ts': int(sms.get('date', '0')) / 1000, 'sim': sms.get('sub_id')})
    return out


def parse_blocks(path):
    """Plain text: blocks split by a line '---'. First line 'sender: VM-HDFCBK', optional
    'date: 2026-10-21', optional 'sim: 1', then the message body."""
    out = []
    for block in re.split(r'^---\s*$', open(path, encoding='utf-8').read(), flags=re.M):
        lines = [l for l in block.strip().splitlines()]
        if not lines:
            continue
        meta, body = {}, []
        for i, l in enumerate(lines):
            m = re.match(r'^(sender|date|sim):\s*(.*)$', l, re.I)
            if m and not body:
                meta[m.group(1).lower()] = m.group(2).strip()
            else:
                body.append(l)
        ts = 0
        if meta.get('date'):
            ts = datetime.fromisoformat(meta['date']).replace(tzinfo=timezone.utc).timestamp()
        out.append({'sender': meta.get('sender', ''), 'body': '\n'.join(body), 'ts': ts, 'sim': meta.get('sim')})
    return out


def parse_chatdb(path):
    """Mac Messages database (iPhone messages forwarded to the Mac). Needs Full Disk Access."""
    con = sqlite3.connect(f'file:{path}?mode=ro', uri=True)
    q = ('SELECT h.id, m.text, m.date FROM message m JOIN handle h ON m.handle_id = h.ROWID '
         'WHERE m.is_from_me = 0 AND m.text IS NOT NULL')
    out = []
    for sender, text, d in con.execute(q):
        out.append({'sender': sender, 'body': text, 'ts': d / 1e9 + 978307200, 'sim': None})
    return out


PARSERS = {'adb': parse_adb, 'xml': parse_xml, 'blocks': parse_blocks, 'chatdb': parse_chatdb}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('input')
    ap.add_argument('--format', required=True, choices=PARSERS)
    ap.add_argument('--all', action='store_true', help='keep senders that are not one of the five banks')
    ap.add_argument('-o', '--out', default='testdata/sms_samples.json')
    ap.add_argument('--review', default='testdata/review.txt')
    ap.add_argument('--list-senders', action='store_true',
                    help='print each distinct sender and its count (no message text) and exit')
    a = ap.parse_args(argv)

    if a.list_senders:
        counts = {}
        for r in PARSERS[a.format](a.input):
            sender = normalise_sender(r['sender'])
            counts[sender] = counts.get(sender, 0) + 1
        for sender, n in sorted(counts.items(), key=lambda kv: -kv[1]):
            print(f'{sender:<14} {n:>4}  {bank_for(sender) or "-"}')
        return 0

    seen, samples = set(), []
    for r in PARSERS[a.format](a.input):
        sender = normalise_sender(r['sender'])
        bank = bank_for(sender)
        if not bank and not a.all:
            continue
        body = anonymise(r['body'])
        key = hashlib.sha1(body.encode()).hexdigest()
        if key in seen:
            continue
        seen.add(key)
        date = datetime.fromtimestamp(r['ts'], timezone.utc).strftime('%Y-%m-%d') if r['ts'] else None
        samples.append({'id': f'{(bank or "OTHER").lower()}-{len(samples) + 1:03d}', 'bank_hint': bank,
                        'sender': sender, 'core': bank in CORE_BANKS, 'date': date,
                        'sim': r.get('sim'), 'body': body})

    with open(a.out, 'w', encoding='utf-8') as f:
        json.dump(samples, f, ensure_ascii=False, indent=2)
    with open(a.review, 'w', encoding='utf-8') as f:
        for s in samples:
            f.write(f"[{s['id']}] {s['sender']} {s['date']}\n{s['body']}\n\n")
    by = {}
    for s in samples:
        by[s['bank_hint'] or 'OTHER'] = by.get(s['bank_hint'] or 'OTHER', 0) + 1
    order = [b for b in CORE_BANKS if b in by] + sorted(b for b in by if b not in CORE_BANKS)
    by = {b: by[b] for b in order}
    print(f'Wrote {len(samples)} messages to {a.out}: {by}')
    print(f'Core banks (scorecard): {sum(1 for s in samples if s["core"])}. Others are bonus samples.')
    print(f'Read {a.review} and check for names, places or anything personal before committing.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
