# Paisa Vault: Phase Plan (v1.1)

Refines section 8 of [CLOUD.md](../CLOUD.md). Total effort is unchanged at about 22 to 24 weeks for one experienced Flutter developer, or less with two developers working in parallel from Phase 2.

## What changed from v1.0 and why

| Change | Reason |
|---|---|
| Design lock moved from Phase 5 into Phase 0 | The clickable prototype already exists, so Flutter work can start from approved screens instead of waiting for final designs. |
| Phase 1 split into 1A and 1B | 7 to 8 weeks in one block hides risk. 1A proves the SMS to AI pipeline, 1B builds the product around it. |
| Store and platform risks start in Phase 0 | Google Play's SMS permission and the iOS Shortcut route can each sink the project. They should not first appear at release. |
| Exit gate added to every phase | A phase ends on a measurable check, not on a date. |
| Open items given a phase and an owner | Bank list, default categories and budget period block Phase 0 and 1 work. |
| Test and CI strategy added | v1.0 had none. |

## Overview

| Phase | Weeks | Output |
|---|---|---|
| 0 Groundwork and design lock | 2 to 3 | Model chosen, four platform spikes proven, screens signed off |
| 1A Foundation, SMS and AI | 4 | A bank SMS becomes a stored, card-mapped transaction on both OSes |
| 1B Categorise, search, budgets, backup | 3 to 4 | A usable personal tracker |
| 2 Cards and privacy | 4 | Card vault and hidden transactions |
| 3 Reports and self transfers | 3 | Accurate reports without double counting |
| 4 Household sharing | 4 | Husband and wife share a household budget |
| 5 Release and polish | 2 to 3 | Store submissions and hardening |
| Future | n/a | Multi-currency, EMI detection, refunds, widgets, regional languages |

## Phase 0: Groundwork and design lock (2 to 3 weeks)

**Goal:** remove the biggest unknowns before writing app code.

**Scope**
- Collect anonymised sample SMS from the chosen banks (at least 20 per bank, debit, credit, UPI, ATM, failed and OTP).
- Compare Gemma 3 1B and Qwen3 1.7B on those samples for accuracy and speed on real phones, including one mid-range Android.
- Four spikes on real devices: Android SMS receiver, iOS Shortcut to App Intent, Android NFC card read, iPhone camera card scan.
- Measure model bundling: Play Asset Delivery pack size and iOS app size.
- Finish the prototype: close the gaps listed in the README, then sign off every screen.
- Decide open items: first banks, default categories, budget period (calendar month or salary cycle), final app name.
- Draft the Google Play SMS permission declaration and plan the demo video.

**Exit gate**
- Model chosen, with extraction accuracy on real SMS at or above a threshold agreed up front (suggested: 95% on amount, 90% on merchant).
- All four spikes work on real devices, or a documented fallback is chosen.
- Designs signed off.

**Risks:** iOS Shortcut cannot run reliably in the background (fallback: manual share-to-app), model too slow on mid-range phones (fallback: smaller model or queue).

## Phase 1A: Foundation, SMS and AI (4 weeks)

**Scope**
- Flutter project, CI, lint and test setup.
- drift with SQLCipher-compatible encrypted main.db, keys in Keystore or Keychain.
- App lock: PIN and biometrics, auto-lock after inactivity.
- Onboarding: SMS disclosure screen (Android), Shortcut setup guide (iPhone), PIN setup.
- SMS ingest on both platforms. OTP and promo filter.
- On-device LLM with bundled model, strict JSON schema, amount safety check, "please confirm" status.
- Duplicate check, and bank, card and account mapping by bank plus last 4 digits.

**Exit gate**
- A real bank SMS becomes a stored, mapped transaction on both Android and iPhone.
- Golden-SMS regression suite is green in CI.
- No network permission in the build apart from local network.

## Phase 1B: Categorise, search, budgets, backup (3 to 4 weeks)

**Scope**
- Categories, manual entry, transaction detail and edit.
- Category order: merchant rule, similar past transaction, LLM suggestion, ask the user.
- "What was this?" flow with note, "always use this category" and "hide" options.
- Search by date, category, exact amount within dates, and free text (full-text index).
- Monthly budgets with 70, 80, 90 and 100% alerts, each fired once per period. Uncategorised alerts, grouped into an evening reminder.
- Encrypted backup and restore with passphrase.

**Exit gate**
- Dogfood for one week on both phones with no data loss.
- Budget alert fires exactly once per threshold per period (automated test).
- Restore of a backup reproduces the ledger exactly.

## Phase 2: Cards and privacy (4 weeks)

**Scope**
- Card vault: last-4 list, biometric reveal, auto-hide after 30 to 60 seconds, screenshot block, app-switcher blur.
- Android NFC add, iPhone camera scan and manual entry.
- Credit card bill setup and due-date reminders.
- Optional card PIN storage, off by default, with warning.
- Separate vault.db with its own key, hidden transactions, true-budget view.
- Vault entry point is not obvious: no menu item, long-press on the profile avatar in the prototype.

**Exit gate**
- Automated test: a hidden transaction appears in no list, total, chart, search result or export.
- Automated test: no CVV field exists and none is written anywhere.
- Repeated SMS for a hidden transaction stays hidden.

## Phase 3: Reports and self transfers (3 weeks)

**Scope**
- Monthly and custom range reports: category, top merchants, card-wise.
- Self-transfer detection (same amount out and in within a short window, own credit card payment, own wallet).
- Confirmation step before every report, and a month-end notification.
- PDF and CSV export, plus encrypted export.

**Exit gate**
- Report totals reconcile to the ledger to the paisa.
- Confirmed self transfers are excluded from totals and budgets.

## Phase 4: Household sharing (4 weeks)

**Scope**
- QR pairing with a 6-digit match code, key exchange.
- Wi-Fi discovery and end-to-end encrypted delta sync.
- Shared flag per transaction, joint-account duplicate detection (bank, last 4, amount, reference).
- Conflict rules, combined home budget view.
- Encrypted file export and import as a fallback.

**Exit gate**
- Two real phones sync in both directions on the same Wi-Fi.
- Automated test: hidden transactions never leave the device.
- A duplicate SMS on both phones shows once.

## Phase 5: Release and polish (2 to 3 weeks, then ongoing)

**Scope**
- Visual polish against the signed-off designs, accessibility (text scaling, contrast, screen reader labels).
- Performance and battery tuning on mid-range Android.
- Google Play submission with SMS declaration and demo video. App Store submission.
- Privacy and security review against CLOUD.md section 7.

**Exit gate**
- Both stores approved, or the fallback is chosen (direct APK for household use, or a manual-entry build).

## Cross-cutting, every phase
- Unit tests on the SMS pipeline with a growing golden corpus. Never commit real SMS.
- Platform packages sit behind app-level interfaces so they can be replaced.
- A short demo to the product owner at the end of each phase.

## Open items and when they must be settled

| Item | Needed by |
|---|---|
| Banks to support first | Start of Phase 0 |
| Default category list | End of Phase 0 |
| Budget period: calendar month or salary cycle | End of Phase 0 |
| Final app name and branding | Start of Phase 5 |
| Final model choice | End of Phase 0 |
