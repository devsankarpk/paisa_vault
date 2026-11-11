#!/usr/bin/env python3
"""Score a local model on the synthetic seed set (Phase 0, Stage A). Mac numbers guide prompt
tuning only; the model is chosen on the real phones with the real SMS corpus (Stage B).

Usage: python3 tools/llm_console/evaluate.py [--model gemma3:1b] [--limit N] [-f seed_sms.json]
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sms_extract as x  # noqa: E402

FIELDS = ['is_transaction', 'bank', 'last4', 'amount', 'direction', 'channel', 'merchant',
          'reference', 'date']


def matches(field, want, got):
    if field == 'amount':
        return got is not None and abs(float(got) - want) < 0.005
    if field == 'merchant':
        a, b = want.lower(), str(got or '').lower()
        return bool(b) and (a in b or b in a)
    return got == want


def main(argv=None):
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', default=x.MODEL)
    ap.add_argument('--limit', type=int, default=0)
    ap.add_argument('-f', '--file', default=os.path.join(here, 'seed_sms.json'))
    a = ap.parse_args(argv)
    x.check_ready(a.model)
    rows = json.load(open(a.file, encoding='utf-8'))
    rows = rows[:a.limit] if a.limit else rows

    hit = {f: [0, 0] for f in FIELDS}
    times, bad = [], []
    for r in rows:
        data, secs = x.extract(r['body'], a.model)
        times.append(secs)
        for f in FIELDS:
            want = r['expected'].get(f)
            if want is None and f != 'is_transaction':
                continue  # only score fields the SMS actually states
            if f != 'is_transaction' and not r['expected']['is_transaction']:
                continue
            hit[f][1] += 1
            if matches(f, want, data.get(f)):
                hit[f][0] += 1
            else:
                bad.append(f"{r['id']} {f}: want {want!r}, got {data.get(f)!r}")
    print(f'\nModel {a.model}, {len(rows)} messages, average {sum(times) / len(times):.1f}s per SMS')
    for f in FIELDS:
        ok, n = hit[f]
        print(f'  {f:<15} {ok:>2}/{n:<2} {100 * ok / n:5.1f}%')
    print('\nMisses:')
    print('\n'.join('  ' + b for b in bad) or '  none')
    return 0


if __name__ == '__main__':
    sys.exit(main())
