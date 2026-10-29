# Phase 2: Cards and privacy

**Dates:** 14 Jan to 10 Feb 2027 (4 weeks). **Back to:** [index](../PHASE_PLAN.md)

## 1. Goal and output
Secure card storage and private transactions: a card vault protected by PIN or biometrics, bill reminders for credit cards, and a separate hidden vault whose entries never show anywhere else.

## 2. Spec coverage
CLAUDE.md 3.5 (card vault), 3.6 (hidden transactions), 3.8 (credit card due reminders), section 6 (vault.db tables, cards, card_bill_settings), section 7 (vault key, field encryption, screen protection).

## 3. Prerequisites
- Phase 1B exit gate passed.
- NFC decision from Phase 0 (ships, optional, or dropped).
- Signed-off screens: cards, card detail, add card, bill setup, hidden vault, security.

## 4. Work breakdown

### Week 1: cards
| Task | Deliverable | Days |
|---|---|---|
| Tables cards (bank, network, debit/credit, last 4, expiry, link to vault secret) and card_bill_settings. Link cards to accounts by bank and last 4. | Migration, mapping tests | 1.5 |
| Card list: last 4, type, bank only. Card detail screen. | Screens | 1 |
| Add card: manual entry first, camera scan (ML Kit, both OSes), NFC (Android) according to the Phase 0 result. Bank, type, network and holder confirmed by hand. CVV field does not exist. | Add flows | 2.5 |

### Week 2: vault and secrets
| Task | Deliverable | Days |
|---|---|---|
| vault.db with its own key that needs PIN, fingerprint or Face ID on every open. Tables hidden_transactions, hidden_fingerprints, card_secrets, vault_audit. | Vault opens only after auth | 2 |
| Card number (and optional PIN) encrypted field by field, AES-256-GCM. Full number only after auth, shown 30 to 60 seconds, then hidden. | Reveal flow with timer | 1.5 |
| Card PIN storage: off by default, warning that banks may hold the cardholder liable. | Warning and switch | 0.5 |
| Screen protection: block screenshots on card screens (Android secure flag, iOS equivalent), blur in the app switcher. | Verified on both OSes | 1 |

### Week 3: hidden transactions
| Task | Deliverable | Days |
|---|---|---|
| Hide flow: any transaction moves to vault.db; removed from lists, totals, charts, budgets, search. | Hide and unhide | 1.5 |
| Repeat SMS stays hidden while the vault is locked: keyed hash (HMAC) of the fingerprint in main.db, authoritative copy in vault.db. Matching SMS go to a vault queue and are stored on next unlock. | Hash design and tests | 1.5 |
| Non-obvious entry point (long-press on the profile avatar in the prototype). Owner view with the true-budget switch. | Entry and view | 1 |
| Exports and household sharing exclude hidden data by construction (separate DB). | Exclusion tests | 1 |

### Week 4: credit card bills, hardening
| Task | Deliverable | Days |
|---|---|---|
| Credit card bill setup: statement date, due date, limit (optional), reminder days (e.g. 5 and 1). Local notifications. | Reminders fire | 1.5 |
| Vault audit log of openings. Auto-lock closes the vault and clears keys from memory. | Tests | 1 |
| Security review against section 7, fix findings. Dogfood hidden and card flows. Phase review. | Exit gate checked | 2.5 |

## 5. Data model
main.db: cards, card_bill_settings, hidden_hash usage. vault.db: hidden_transactions, hidden_fingerprints, card_secrets (no CVV field), vault_audit.

## 6. Packages
flutter_nfc_kit or emv_nfc_reader (per Phase 0), google_mlkit_text_recognition, local_auth, flutter_secure_storage with native biometric-locked keys, cryptography (AES-256-GCM), flutter_local_notifications.

## 7. Prototype screens that become real
[Cards](../../screenshots/cards.png), [Card reveal](../../screenshots/card-hdfc.png), [Add card](../../screenshots/addcard.png), [Bill setup](../../screenshots/billsetup.png), [Hidden vault](../../screenshots/hidden.png), [Security](../../screenshots/security.png).

## 8. Tests
- **Automated privacy test:** a hidden transaction is absent from every list, total, chart, budget, search result, export and household payload. Run over a generated dataset.
- **No CVV test:** schema has no CVV column; scan the databases and logs after adding a card with a CVV typed in a form field that does not exist.
- **Vault key test:** after lock or auto-lock the vault cannot be opened without auth; key not in memory dumps or files.
- **Repeat SMS test:** a second identical SMS for a hidden transaction stays hidden, with the vault locked.
- **Secrets at rest:** card number is not readable in the database file.
- **Device:** screenshots blocked, app-switcher blur, biometric failure and fallback to PIN.

## 9. Exit gate
- Hidden transactions appear nowhere outside the vault (automated test green).
- No CVV is stored or logged.
- Full card number is shown only after auth and hides after the timer.
- Repeat SMS for a hidden transaction stays hidden with the vault locked.
- Credit card due reminders fire at the set days.

## 10. Risks and fallback
| Risk | Fallback |
|---|---|
| NFC reads few cards | Manual and camera entry are first-class; NFC marked optional (T7) |
| Biometric key invalidated when the user changes fingerprints | Fall back to PIN re-entry and re-wrap the key |
| iOS screenshot blocking is limited | Blur on app switch and hide sensitive views during screen recording |
| Hidden hash leaks information | Keyed HMAC with a key stored only in the vault |

## 11. Demo
Add a card, reveal it with Face ID and watch it re-hide, hide a transaction and show it missing from every view, open the vault via the avatar, trigger a bill reminder.

**Platform topics:** T7 in [PLATFORM_AND_COMPLIANCE.md](../PLATFORM_AND_COMPLIANCE.md).
