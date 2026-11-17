# Testing strategy

## Principles
- The riskiest parts are the SMS pipeline and the privacy promises, so those get the most tests.
- Anything that says "never" (never stored, never shared, never shown) has an automated test.
- Real SMS never go into git.

## Test layers

| Layer | What | Where it runs | Starts |
|---|---|---|---|
| Unit | Filters, schema validation, safety check, dedupe, mapping, categoriser, budget math, detectors | CI on every commit | 1A |
| Golden SMS corpus | Per-field accuracy of the pipeline against labelled SMS | CI with a fake or small model; full model on devices | 0 (bake-off), 1A (CI) |
| Database | Migrations, encryption, wrong key fails, indexes | CI | 1A |
| Integration | SMS in, transaction out, notifications, backup restore | Devices and emulators | 1A |
| Privacy and security | Hidden exclusion, no CVV, no plaintext at rest, no public traffic | CI plus device | 1A, 2, 4 |
| Device | Real SMS from each bank, NFC, Shortcut, biometrics, sync | Your Android and iPhone | every phase |
| Accessibility and performance | Text scaling, screen reader, mid-range speed and battery | Devices | 5 |

## Golden SMS corpus

Files (kept out of git until anonymised):
- `testdata/sms_samples.json`: anonymised messages with sender and SIM.
- `testdata/sms_labels.json`: expected output for each sample.
- `testdata/sender_ids.json`: sender IDs by bank.

Format of a label:

```json
{ "id": "hdfc-017", "bank": "HDFC", "type": "credit_card", "last4": "4821",
  "amount_paise": 48000, "direction": "debit", "merchant": "SWIGGY",
  "channel": "UPI", "reference": "5123XXXX", "date": "2026-10-21",
  "category": "Food", "expect": "ok" }
```

Coverage per bank, at least 20 samples: debit card, credit card, UPI, NEFT/IMPS, ATM, POS, failed transaction, refund, OTP (must be ignored), promo (must be ignored). Grow the corpus whenever a real failure is found.

Anonymisation: mask names, account and card numbers (keep last 4), phone numbers. Review every file by eye before committing.

CI rule: accuracy per field must not drop below the Phase 0 thresholds.

## Phase-specific automated checks

| Check | Phase | Rule |
|---|---|---|
| No INTERNET permission in release manifest | 1A to 3 | Build fails if present |
| Database unreadable without the key | 1A | Open with wrong key must fail |
| Amount safety check | 1A | A wrong model amount becomes "please confirm" |
| Redaction | 1A | Default diagnostics export has no 6+ digit runs or rupee amounts |
| Alert once per threshold | 1B | Simulated month |
| Backup round trip | 1B | Back up, wipe, restore, compare |
| Hidden exclusion | 2 | Hidden amounts absent from every list, total, chart, budget, search, export, sync payload |
| No CVV | 2 | No column, no log, no storage |
| Report reconciliation | 3 | Totals equal ledger after exclusions |
| LAN-only traffic | 4 | Only the paired peer's LAN address |
| Upgrade path | 5 | Oldest build upgrades to release with data intact |

## Device matrix

Recorded 17 Nov 2026.

| Device | Model and OS | Used for | Notes |
|---|---|---|---|
| Android phone | vivo V29e (model V2303), Android 15, one SIM, **no NFC** | SMS receiver, camera scan, biometrics, WorkManager, notifications, Wi-Fi sync | Mid-range. Default vivo battery settings delay SMS delivery by minutes when the app is swiped away; set battery to unrestricted. No Autostart page on this build. |
| iPhone | iPhone 15, iOS 26.7.1 | Shortcut and App Intent, camera scan, Face ID, local network | Free developer signing: installed apps expire after 7 days. Intel Mac, Flutter 3.47.8. |
| NFC Android phone | Not available yet | NFC card read matrix (T7) | Borrow one to finish `docs/spikes/nfc-matrix.md`. |
| Android with two SIMs | Not available | Dual-SIM subscription ids | The vivo has one SIM only. |
| A second phone on the same Wi-Fi | The iPhone and the vivo serve as each other's peer | Household sync | An isolated guest network is still to test. |
| A different Android (high-end or older) | Not available | Speed and battery limits | Borrow one in Phase 5. |
| Cards you own | Some scanned with the camera | NFC and scan tests | |

## Dogfood
End of 1B: one week of real use on both phones. Collect diagnostics exports, fix the top issues before Phase 2.
