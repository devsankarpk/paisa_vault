# Phase 1A: Foundation, SMS and AI

**Dates:** 19 Nov to 16 Dec 2026 (4 weeks). **Back to:** [index](../PHASE_PLAN.md)

## 1. Goal and output
A real bank SMS becomes a stored, card-mapped transaction on both Android and iPhone, inside an encrypted, PIN-locked app.

## 2. Spec coverage
CLAUDE.md 3.1 (SMS reading), 3.2 (on-device AI), section 4 (layers 1 to 4), section 7 (main database, app lock), section 6 (first tables).

## 3. Prerequisites
- Phase 0 exit gate passed, model chosen (ADR 0001).
- Decisions logged: state management, min OS versions, ids, folder layout.
- Signed-off screens: lock, PIN, onboarding, Shortcut guide, transaction detail.

## 4. Work breakdown

### Week 1: project, database, lock
| Task | Deliverable | Days |
|---|---|---|
| Project structure and the interfaces: `SmsSource`, `LlmEngine`, `CardReader`, `TextScanner`, `Clock`, `Logger`. Fakes for tests. | Interfaces plus fakes | 1 |
| Encrypted main.db: drift with drift_flutter, sqlite3 with SQLCipher-compatible build (not the deprecated sqlcipher_flutter_libs). Key in Android Keystore or iOS Keychain. Open in background. | Encrypted DB opens, wrong key fails | 2 |
| Schema v1 and migrations: banks (with sender_ids), accounts, transactions, raw_messages, settings, pipeline_log, hidden_hash (reserved). Amounts in paise plus currency code. | Migration tests | 1 |
| App lock: PIN screen, biometrics (local_auth), auto-lock timer, create-PIN flow with the recovery note. | Lock and unlock work on both OSes | 1 |

### Week 2: SMS input
| Task | Deliverable | Days |
|---|---|---|
| Android: SMS disclosure screen, then RECEIVE_SMS and READ_SMS request. Own Kotlin plugin, saves the raw message first, enqueues processing. Stores sender, body, time, SIM subscription id. | SMS saved even when the app is closed | 2.5 |
| iPhone: App Intent "Log Bank Message" in the Runner target, writes to a shared container the app reads on open. Shortcut guide screen. | Shortcut saves SMS in the background | 2.5 |
| OTP and promo filter: only messages with an amount and a debit/credit word go on. Sender normalisation (T2). | Filter passes the golden corpus | 1 |
| Encrypted raw_messages with a 30 to 90 day purge job. | Purge test | 0.5 |

### Week 3: the AI pipeline
| Task | Deliverable | Days |
|---|---|---|
| `LlmEngine` implementation for the chosen model, model manifest (id, version, licence, prompt version, schema version). Model bundled (Play Asset Delivery install-time pack, iOS bundle). | Model loads and answers on both phones | 2 |
| Extraction prompt and strict JSON schema: bank, account type, last 4, amount, debit/credit, merchant, channel, reference, date, suggested category. Validation, one retry, then "please confirm". | Schema validator and tests | 1.5 |
| Amount safety check: returned amount must appear in the SMS text. | Failing case becomes "please confirm" | 0.5 |
| Processing queue: Android WorkManager job after save, iPhone processing on next app open. | Queue survives app kill | 1 |

### Week 4: mapping, hardening, privacy basics
| Task | Deliverable | Days |
|---|---|---|
| Duplicate check using a fingerprint (bank, last 4, amount, reference, date). | Dedupe tests | 1 |
| Bank, card and account mapping by bank plus last 4. Unknown last 4 creates a pending account. Unrecognised sender, confirm state. | Mapping tests | 1 |
| Pipeline log and local crash capture (T5), redaction unit test. Model-version stored on each transaction (T6). | Log ready for diagnostics screen | 1 |
| Privacy basics (T4): consent screens, "Erase everything" that wipes both databases and keys. | Erase test | 0.5 |
| Backup key design note: backups use a passphrase-derived key, not device keys. | Short design doc | 0.5 |
| Golden-SMS suite in CI, device run on both phones with real new SMS from all five banks. Phase review and demo. | Exit gate checked | 1 |

## 5. Data model
main.db: banks, accounts, transactions, raw_messages, settings, plus new `pipeline_log` and `hidden_hash` (empty until Phase 2). New columns: `raw_messages.sim_subscription_id`, `banks.sender_ids`, `transactions.model_id`, `transactions.prompt_version`. See [DECISIONS.md](../DECISIONS.md).

## 6. Packages
drift, drift_flutter, sqlite3 (3.x with sqlite3mc), flutter_secure_storage plus native Keystore/Keychain code, local_auth, cryptography, flutter_gemma or llamadart (per ADR 0001), workmanager, own Kotlin SMS plugin, Swift App Intent.

## 7. Prototype screens that become real
[Lock](../../screenshots/lock.png), [SMS disclosure](../../screenshots/onboard.png), [Shortcut guide](../../screenshots/shortcut.png), [Create PIN](../../screenshots/setpin.png), [Transaction detail with please confirm](../../screenshots/txn-9.png), [Security](../../screenshots/security.png).

## 8. Tests
- **Unit:** schema validation, safety check, OTP filter, sender normalisation, dedupe, mapping, purge.
- **Golden corpus:** accuracy per field, runs in CI with a fake or a small real model; full model runs on devices.
- **Security:** database unreadable without the key, no plaintext SMS on disk, key not in app files.
- **Manifest check in CI:** release build has no INTERNET permission (until Phase 4).
- **Device:** real new SMS from each of the five banks on Android and iPhone, with the app closed and open.
- **Reliability:** kill the app during processing, no message lost or duplicated.

## 9. Exit gate
- A real SMS from each of the five banks becomes a stored, mapped transaction on Android and on iPhone.
- Amount safety check proven with a deliberately wrong model output.
- Golden-SMS suite green in CI, meeting the Phase 0 thresholds.
- Release build contains no INTERNET permission.
- "Erase everything" removes all data.
- Redaction test passes for the default log.

## 10. Risks and fallback
| Risk | Fallback |
|---|---|
| iPhone cannot process in the background | Process on next open (already the design); show an "AI processing" state |
| Model too slow with a long queue | Process newest first, batch while charging |
| SQLCipher build issues on one OS | Fall back to field-level encryption only as a stopgap, fix before Phase 2 |
| Play asset delivery setup delays | Test with a local bundle first, add the pack before Phase 5 |

## 11. Demo
Receive a real bank SMS on each phone and show it as a mapped transaction. Show a "please confirm" case, the lock screen and "Erase everything".

**Platform topics:** T2, T4, T5, T6 in [PLATFORM_AND_COMPLIANCE.md](../PLATFORM_AND_COMPLIANCE.md).
