# Progress tracker

The single place to see what is done and what is not. Tasks mirror the phase files; details live there. Update this file in the same commit as the work.

**Last updated:** 11 Nov 2026

## Current focus

Phase 0, week 1: tooling, SMS corpus, first spikes.

## Blocked on you

Checked 2 Nov 2026. Done by me: Android licences, SDK 36, build-tools 28.0.3, CocoaPods 1.16.2. Still needs you (adb PATH is now done):

- [x] `adb` on your PATH (verified 2 Nov 2026: a new shell finds it, version 1.0.41)
- [x] iPhone connected (cable, Trust, Developer Mode)
- [x] Android phone connected (verified 2 Nov 2026: model V2303, Android 15, API 35)
- [x] Free Apple ID added in Xcode for signing (needed to run apps on the iPhone)
- [ ] Tell me phone models and OS versions (and whether a mid-range Android is available)
- [ ] Export bank SMS and run the anonymiser: follow [tools/sms_corpus/README.md](../tools/sms_corpus/README.md), then read `testdata/review.txt` before anything is committed

## Phase status

| Phase                                  | Dates                 | Status      |
| -------------------------------------- | --------------------- | ----------- |
| Planning                               | to 29 Oct 2026        | Done        |
| 0 Groundwork and design lock           | 29 Oct to 18 Nov 2026 | In progress |
| 1A Foundation, SMS and AI              | 19 Nov to 16 Dec      | Not started |
| 1B Categorise, search, budgets, backup | 17 Dec to 13 Jan 2027 | Not started |
| 2 Cards and privacy                    | 14 Jan to 10 Feb      | Not started |
| 3 Reports and self transfers           | 11 Feb to 3 Mar       | Not started |
| 4 Household sharing                    | 4 Mar to 31 Mar       | Not started |
| Buffer                                 | 1 Apr to 28 Apr       | Not started |
| 5 Release and polish                   | 29 Apr to 19 May      | Not started |

Status values: Not started, In progress, Blocked, Done.

---

## Planning (done)

- [x] Product and technical spec ([CLAUDE.md](../CLAUDE.md))
- [x] Clickable prototype, 24 screens, screenshots
- [x] README with screen gallery and phase table
- [x] Phase plan index and seven phase files
- [x] Platform and compliance notes (T1 to T7), decision log, testing strategy, risk register
- [x] Decisions confirmed: banks, team, LLM left open, hidden dedupe, PIN recovery, dashboard scope

## Phase 0: Groundwork and design lock

[Details](phases/phase-0-groundwork.md)

**Tooling**

- [x] Flutter upgraded to 3.47.8 stable
- [x] Flutter pointed at JDK 17 (Android Studio bundled)
- [x] Intel Mac risk recorded (R19)
- [x] Android licences accepted, SDK 36 and build-tools 28.0.3 installed
- [x] CocoaPods updated to 1.16.2
- [x] `adb` on PATH
- [x] Both phones connected and recognised by `flutter devices` (Android V2303 on Android 15, iPhone on iOS 26.7.1)
- [x] Phone models and OS versions recorded in [TESTING.md](TESTING.md)
- [ ] Google Play and Apple developer accounts set up (or decision to defer) (owner is creating both, 17 Nov 2026; bundle ids to be confirmed first)

**Week 1: data and Android basics**

- [ ] Collect SMS, 20 or more per scored bank (HDFC, SBI, Yes, RBL, Indian Bank: the owner's real banks, decided 20 Nov), all message types. ICICI and Axis stay supported but unscored. Owner's banks (20 Nov): iPhone SIM has HDFC, SBI, Yes Bank accounts and RBL, HDFC, SBI credit cards; Indian Bank (INDBNK) is on the vivo; ICICI is a FASTag account only (toll SMS, a special format); Axis not used. HDFC, SBI, Yes, RBL and Indian Bank are the scored banks. iPhone inbox pulled 17 Nov: 35 lines, 26 unique (HDFC 21, SBI 1, Indian 1, RBL 1, 2 unmatched); `tools/sms_corpus/pull_iphone_inbox.sh` repeats it. Other Indian banks are optional bonus samples
- [x] Anonymisation script ([tools/sms_corpus/](../tools/sms_corpus/), 9 tests passing)
- [ ] Anonymised corpus `testdata/sms_samples.json`
- [ ] Labels `testdata/sms_labels.json`
- [ ] Sender ID table `testdata/sender_ids.json` (T2): draft with the known codes created; fill in what your phones actually receive, SMS or RCS, and SIM
- [x] `testdata/` raw data in `.gitignore`
- [x] Flutter project skeleton in `mobile/`, lint and test pass locally; CI workflow added (confirm it is green after the first push)
- [ ] Android SMS receiver spike on the real phone (receiver works on the emulator: sender and SIM id logged, no message text; real vivo: plain SMS and a real bank alert (INDBNK) received, sender and SIM id logged; app swiped away was 2 to 4 minutes late on default settings, 0.6 s after setting battery to unrestricted (14 Nov); restart, dual SIM and RCS still to test, see docs/spikes/android-sms-receiver.md)

**Week 2: spikes and LLM bake-off**

- [ ] iOS Shortcut to App Intent spike (SMS and RCS/iMessage): SMS path works on iPhone 15 (a few seconds, banner shows, duplicates when several keywords match); closed-app (unlocked) works as of 14 Nov; locked-then-unlocked works; SMS arriving while still locked, iMessage and RCS still open. See docs/spikes/ios-shortcut.md
- [ ] NFC spike and card matrix (T7) (spike app built and tested in the parser; no NFC phone available yet, matrix deferred, see `docs/spikes/nfc-matrix.md`)
- [x] Camera card scan spike (works on iPhone 15 and vivo after parser fixes, see `docs/spikes/camera-scan.md`)
- [ ] LLM Stage A: prompt and schema tuning on the Mac (first pass done on 24 synthetic SMS: Qwen3 1.7B 2 misses, Gemma 3 1B 11 misses; needs the real corpus to confirm)
- [x] LLM Stage B: benchmark app run on both phones (iPhone 15 release: Gemma 1.7 s, Qwen3 2.4 s per SMS; vivo: 4.7 s and 6.8 s; working choice Qwen3 1.7B, see DECISIONS.md). Reruns on real SMS and the latest vivo build still open.
- [x] Scorecard and ADR 0001 draft (`docs/adr/0001-on-device-model.md`, status Proposed; open checks listed there)
- [x] Wi-Fi sync spike (T1) (iPhone and vivo found each other by mDNS on home Wi-Fi, encrypted message each way, same code on both; isolated network untested, see `docs/spikes/wifi-sync.md`)

**Week 3: bundling, design, decisions**

- [ ] Bundling check: model size, install-time pack, iOS app size (sizes measured; model fits in one Play pack; install-time packs give no file path so first-run copy is needed; real Play and TestFlight upload still to do, see `docs/spikes/bundling.md`)
- [x] Design lock: prototype updated and every screen signed off (owner approved the screenshots on 17 Nov 2026; changes later are allowed)
- [x] Technical decisions logged in [DECISIONS.md](DECISIONS.md) (state management, min OS versions, ids, folder layout, logging, PDF package, share-to-app)
- [x] Privacy groundwork: data inventory, draft policy, Play SMS declaration draft (T4) (`docs/privacy/`; legal review and hosting still to do in Phase 5)
- [x] Model licence review (T3): both models can be shipped; Qwen3 is simpler (Apache 2.0). See docs/spikes/model-licences.md
- [ ] Phase review and demo

**Exit gate**

- [ ] ADR 0001 accepted (model chosen, thresholds met, licence checked)
- [x] Android SMS receiver works on the real phone
- [x] iOS Shortcut route saves SMS in the background, or fallback chosen (app closed works; app must deduplicate the double save)
- [ ] NFC decision made (provisional: optional, manual entry and camera first; owner will test NFC later with a borrowed phone)
- [ ] Wi-Fi sync works, fallback decided (works on home Wi-Fi; fallbacks kept; isolated network still to test)
- [x] Screens signed off and technical decisions logged

---

## Phase 1A: Foundation, SMS and AI

[Details](phases/phase-1a-foundation-sms-ai.md)

- [x] Interfaces and fakes (SmsSource, LlmEngine, CardReader, TextScanner, Clock, Logger) in mobile/lib, Riverpod wired, 3 tests
- [x] Encrypted main.db with keys in Keystore or Keychain (drift + SQLite3 Multiple Ciphers in SQLCipher mode; wrong key refused, refuses to open if encryption missing; 4 tests; checked on iPhone 15 and vivo V29e; background open still to test with SMS)
- [x] Schema v1 and migrations (7 tables, paise + currency, indexes, foreign keys on, schema dump saved in mobile/drift_schemas for v2 migration tests; 6 tests)
- [x] App lock: PIN, biometrics, auto-lock, create-PIN with recovery note (built 17 Nov, 27 tests pass, 4-digit PIN with lockout; iPhone 15 checked 18 Nov: Face ID, auto-lock, blank app switcher, lockout; vivo V29e passed all 9 checks on 18 Nov: PIN, fingerprint, auto-lock, blank recent-apps card, lockout)
- [x] Android SMS disclosure and receiver plugin (done 19 Nov: Keystore-encrypted stage, drain into raw_messages, disclosure screen, RECEIVE_SMS only, 37 Dart + 7 Kotlin tests; real INDBNK alerts saved on vivo with the app open and with it closed)
- [x] iPhone App Intent and Shortcut guide (done 21 Nov: Log Bank Message action in the real app, encrypted per-message stage, Shortcut guide screen, drain into raw_messages, repeats merged; a real HDFC alert on the iPhone fired the Rs automation, was staged encrypted and saved after unlock; keep the Message field on the Shortcut Input variable, never "Ask Each Time"; free signing expires after 7 days)
- [ ] OTP and promo filter, sender normalisation (built 21 Nov: rule classifier with 34 tests, OTP and promo dropped and never stored, reminders and declines stored as ignored; run on 31 real messages: 25 transaction, 4 other, 2 promo; 3 messages to review with the owner; sender normalisation done in the SMS tool only, not yet in the app)
- [x] Encrypted raw_messages with purge job (done 25 Nov: whole database encrypted; original message text deleted 60 days after it arrived, transactions stay; unprocessed messages never deleted; tested)
- [ ] LlmEngine for the chosen model, manifest, bundled model
- [x] Extraction prompt and strict JSON schema (done 23 Nov: rules read amount, direction, bank, last 4, date, reference, channel and known merchant phrasings; model asked only for merchant, category, channel; strict reply check, one retry, then please confirm; 26 tests; on 25 real transaction messages rules found amount, direction, last 4 and date in all 25)
- [x] Amount safety check (done 23 Nov: amount must literally appear in the SMS, tested with Indian number grouping)
- [x] Processing queue (light version chosen 27 Nov: a message is saved in the encrypted stage at once and survives the app being killed; with the app closed, Android now shows a plain "bank message saved, open Paisa Vault" notification with no sender, amount or text; the model still runs when the app is opened, same as iPhone. Android build compiles; not yet seen on the vivo. Running the model in the background was left out on purpose: it needs a hidden Flutter engine and a plugin refactor, and stays on the later list)
- [x] Duplicate check (same bank, last 4, amount, day and reference; none without a reference)
- [x] Bank, card and account mapping (bank + last 4; new ones saved as pending until confirmed in the accounts screen)
- [x] Pipeline log, local crash capture, redaction test (done 25 Nov: crash.log keeps error type and first stack lines only, never the error message; diagnostics lines are redacted; tests process a message with distinctive text and check no log holds it)
- [x] Consent screens and "Erase everything" (done 25 Nov: SMS disclosure on Android, Shortcut guide on iPhone, new Settings screen with privacy note and Erase everything; erase checked on the iPhone, not yet on the vivo)
- [x] Backup key design note (docs/adr/0002-backup-key.md, 27 Nov)
- [ ] Golden-SMS suite in CI, real SMS from all five banks on both phones (CI part done 25 Nov: 22 invented messages in each bank's format, per-field score printed; found and fixed one gap, "card ... was used for Rs"; real SMS from all five banks on both phones still to do)

**Exit gate**

- [ ] Real SMS from each bank becomes a mapped transaction on Android and iPhone
- [x] Amount safety check (done 23 Nov: amount must literally appear in the SMS, tested with Indian number grouping) proven
- [ ] Golden suite green and meets Phase 0 thresholds
- [x] Release build has no INTERNET permission (Android checked 27 Nov: the release APK asks only for RECEIVE_SMS, notifications, biometrics and vibrate; the INTERNET permission is only in the debug and profile manifests. The Wi-Fi household sync in Phase 4 will need it and must be justified then)
- [ ] "Erase everything" works (iPhone checked 25 Nov; vivo still to check)
- [x] Redaction test passes

## Phase 1B: Categorise, search, budgets, backup

[Details](phases/phase-1b-categorise-search-budgets.md)

- [x] Categories, merchants, merchant_rules, seed data (done 26 Nov, schema v5: categories table seeded with the default list; Income and Transfer fixed; seed data tested)
- [x] Categoriser (rule, similar, LLM, ask) (done 25 Nov: user rule, then similar merchant already categorised by you, then the model suggestion, else it waits for your answer; tested)
- [x] Income handling (done 25 Nov: money in only gets Income or Transfer, otherwise it is asked)
- [ ] Manual entry and transaction detail/edit
- [ ] "What was this?" flow and notification (in-app part done 25 Nov: banner on the list, answer screen with category buttons and "always use for this merchant", same checkbox in the edit sheet; notification still to do)
- [x] Category and merchant-rule management screens (categories done 26 Nov: Settings, Manage categories, add, rename everywhere, hide; merchant rules done 27 Nov: Settings, Merchant rules, change category, forget)
- [ ] Search (date, category, exact amount in range, text) with indexes (done 25 Nov: search screen with dates, category, exact amount and merchant or note text, filters combine, tested; text search uses a plain match, not full-text, which is enough for personal volumes; left open to check on the phone)
- [ ] Budgets and threshold alerts, once per period (done 25 Nov, schema v4: budgets per category per calendar month, alert log, 70/80/90/100% each once a month, only the highest level when spending jumps, local notification with category and percentage only, no amounts; Budgets screen with progress bars; left open until seen firing on a phone)
- [x] Uncategorised alert and evening grouping
- [x] Dashboard numbers from transactions (done 27 Nov: earning, spend, savings and spend by category for a month, month picker; own-account transfers left out; Budgets reached from the dashboard)
- [ ] Encrypted backup and restore (built 26 Nov: AES-256-GCM file, key from your own passphrase with PBKDF2 600,000 rounds, not from phone keys; holds transactions, accounts, categories, rules and budgets, no message text; replace-all restore; tested round trip, wrong passphrase, damaged file; left open until a backup is restored on a clean install on a phone)
- [x] PIN recovery path (done 27 Nov: "Forgot PIN?" on the lock screen explains that nobody can reset it, points to Face ID or fingerprint if on, else erase and restore the backup, with two confirmations; setup note says to create a PIN then restore; the full erase and restore round trip on a phone is still to be checked)
- [x] Diagnostics screen and export (done 26 Nov: Settings, Diagnostics shows transaction counts, needs-a-check rate and reasons, hand-edit rate, saved messages by state, model speed and errors, crashes; shared report is numbers only; tested with canary merchant, note, sender, message text and amounts)
- [x] Re-check after model change (done 27 Nov: Settings, Re-check with the model reads up to 20 recent unedited transactions made by an older model or prompt, shows merchant, category and channel differences, applies only the ones you tick)
- [ ] One-week dogfood on both phones

**Exit gate**

- [ ] A week of real use with no lost or duplicated transactions
- [ ] Same merchant categorised automatically after first answer
- [ ] Each threshold alerts once per period
- [ ] Restore reproduces the ledger exactly
- [x] Diagnostics export has no amounts, merchants or SMS text (tested 26 Nov)

## Phase 2: Cards and privacy

[Details](phases/phase-2-cards-privacy.md)

- [ ] cards and card_bill_settings, card mapping
- [ ] Card list and detail screens
- [ ] Add card: manual, camera, NFC per Phase 0 result
- [ ] vault.db with its own key
- [ ] Field-level encryption and timed reveal
- [ ] Optional card PIN with warning
- [ ] Screenshot block and app-switcher blur
- [ ] Hide flow and unhide
- [ ] Repeat SMS stays hidden while vault locked (hash design)
- [ ] Non-obvious vault entry and true-budget view
- [ ] Exports and sharing exclude hidden data
- [ ] Credit card bill setup and reminders
- [ ] Vault audit log, auto-lock clears keys
- [ ] Security review

**Exit gate**

- [ ] Hidden exclusion test green
- [ ] No CVV stored or logged
- [ ] Card number only after auth, hides after timer
- [ ] Repeat hidden SMS stays hidden with vault locked
- [ ] Bill reminders fire

## Phase 3: Reports and self transfers

[Details](phases/phase-3-reports-self-transfers.md)

- [ ] self_transfer_reviews table
- [ ] Detection rules
- [ ] Review screen and exclusion
- [ ] Month-end notification
- [ ] Report engine
- [ ] Confirmation gate before reports
- [ ] Reports screen
- [ ] PDF and CSV export
- [ ] Encrypted export
- [ ] Reconciliation tests
- [ ] One month of real data

**Exit gate**

- [ ] Totals reconcile to the paisa
- [ ] Confirmed transfers excluded from totals and budgets
- [ ] Gate appears before every report with unconfirmed items
- [ ] Month-end notification fires
- [ ] PDF, CSV and encrypted exports work

## Phase 4: Household sharing

[Details](phases/phase-4-household-sharing.md)

- [ ] Key design and pairing storage
- [ ] QR pairing with 6-digit code
- [ ] Unpair and revoke
- [ ] INTERNET and local-network permissions added
- [ ] Local transport and mDNS, with IP fallback
- [ ] E2E encrypted delta sync
- [ ] Shared flag and share rules
- [ ] household_transactions and shared list
- [ ] Joint-account dedupe
- [ ] Conflict rules
- [ ] Home budget view
- [ ] Encrypted file export and import
- [ ] LAN-only network test

**Exit gate**

- [ ] Two phones pair and sync both ways
- [ ] Hidden never leaves the device
- [ ] Duplicate SMS shows once
- [ ] No traffic outside the LAN
- [ ] File fallback works

## Phase 5: Release and polish

[Details](phases/phase-5-release.md)

- [ ] Visual polish
- [ ] Accessibility pass
- [ ] Mid-range Android performance and battery
- [ ] Privacy review and SDK audit
- [ ] Google Play: SMS declaration, demo video, Data Safety, asset pack, listing
- [ ] Apple: privacy label, review notes, listing
- [ ] Model licence screen if required
- [ ] Release candidates, closed testing, TestFlight
- [ ] Fix blockers, freeze prompt, tag, rollback plan
- [ ] Submit both stores

**Exit gate**

- [ ] Both stores approved, or fallback chosen
- [ ] Privacy, security and accessibility checklists signed
- [ ] Release build passes full tests and device matrix

---

## Log

| Date        | What changed                                                                                                                                                                               |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 27 Nov 2026 | Fixed a missed transaction: a card AutoPay success message ("AutoPay (E-mandate) Success!", amount written INR2399.00, card written "CC 1111") was filed as a reminder because it says "mandate", had no direction and no card digits. Now it is a debit on the card. Messages set aside by older rules are looked at once more after an update (classifier version 2), so the missed one appears by itself. It appeared twice (the shortcut copy and an earlier paste were both saved), so messages with the same text (ignoring spacing, line breaks and punctuation) now make one transaction, and existing extras are removed once per update (classifier version 6). A second cleanup removes a copy saved without a merchant next to one with a merchant (same amount, day and card digits, no reference); rows you edited are never removed. Added to the golden suite with invented details. |
| 26 Nov 2026 | Diagnostics screen and shareable report (Settings, Diagnostics): rates, reasons, model speed, errors, crashes. A test with canary text proves the report holds no amounts, merchants, notes or message text. |
| 26 Nov 2026 | Paste-an-SMS now checks first: the same text is refused however old, and a transaction with the same amount, day and card asks "Add anyway?". Found when the + button let an already-saved message be added again. Tested. |
| 26 Nov 2026 | Encrypted backup and restore (Settings, Backup and restore): passphrase-locked file shared through the iOS and Android share sheet, restore from a picked file with a confirm step. Round trip, wrong passphrase and damaged file tested; not yet tried on a phone. |
| 26 Nov 2026 | Editable categories (schema v5): add, rename (updates transactions, rules and budgets) and hide, from Settings. Every picker and the model prompt use the stored list. Tested; not yet seen on a phone. |
| 26 Nov 2026 | Budgets (schema v4), once-per-month threshold alerts, local notifications (flutter_local_notifications), Budgets screen. Also fixed a bug found by a new test: changing the category for a merchant that already had a rule would have crashed. Tested; not yet seen on a phone. |
| 25 Nov 2026 | Search screen (magnifier on the Transactions screen): dates, category, exact amount, merchant or note text; filters combine. Tested; not yet seen on a phone. |
| 25 Nov 2026 | Phase 1B started: schema v3 (merchant_rules), categoriser (rule, similar merchant, model, else ask), "What was this?" screen and banner, "always use this category" learning. Tested; not yet seen on a phone. |
| 25 Nov 2026 | iPhone Shortcut health check: banner on the Transactions screen when no bank SMS has ever reached the app or none for 7 days, a last-received line and "Setup steps and test" button in Settings, and a test step in the guide that turns green when a message arrives. Built after two real transactions were missed once the reinstall broke the automations. Apple does not allow apps to create automations, so the user must re-check them after every reinstall. Tested; not yet seen on the phone. |
| 25 Nov 2026 | Local crash log (error type and stack lines only), redaction tests, and a golden SMS suite in CI (22 invented messages across HDFC, SBI, Yes, RBL, Indian Bank, OTP, promo, reminder, declined; all fields 100%). The suite found that "card ... was used for Rs" was not read as a transaction; fixed. |
| 25 Nov 2026 | Settings screen with privacy note and "Erase everything" (checked on the iPhone: app returns to PIN setup with an empty list). Original message text is deleted after 60 days; transactions stay, so 3 and 6 month reports are unaffected. |
| 24 Nov 2026 | Added "Add a bank SMS" (paste a missed message, + button on Transactions), an in-app banner that warns 3 days before the free Apple signing expires, and last 4 digits are now read when written in brackets. Stored transactions missing bank or last 4 are filled in again when the rules improve. Tested on iPhone; vivo not updated yet. |
| 24 Nov 2026 | Transactions are linked to an account by bank and last 4 (new accounts saved as pending), and a repeat of the same transaction with the same reference number is stored once. Existing rows get linked. iPhone app stopped working because the free Apple signing expired after 7 days; reinstalled (next expiry 1 Dec) until the paid account is set up. |
| 23 Nov 2026 | On-device model confirmed on both phones: iPhone 15 about 3.3 s per message, vivo 5 to 16 s. Fixed three problems found on real data: earlier failed rows were never re-checked, a model channel word like "Online" caused the whole reply to be rejected (now matched ignoring capitals; unknown channel ignored), and grey label text was too faint (darker). |
| 23 Nov 2026 | On-device model engine added (Qwen3 1.7B via llamadart, loaded from the app folder, freed after each batch) with a diagnostics log; not yet confirmed running on a real transaction. Lock fixes tested on iPhone: every touch resets the idle timer, the app locks as soon as it is left, and Face ID prompts again when the app returns to the front. |
| 23 Nov 2026 | Schema v2 (bank, last 4, account kind, category name, confirm reason, corrected flag) with migration tests; the v1 to v2 upgrade ran on the owner's iPhone with real data. Messages are now processed into transactions; Transactions list, detail with the original message, and an edit sheet added. |
| 23 Nov 2026 | AI pipeline logic built without the model: rule extractor, strict model-reply check, amount safety check, extraction pipeline around the LlmEngine interface (now text in, text out). Real model engine and bundling still to do. |
| 21 Nov 2026 | Lock screen shows a Face ID or fingerprint icon instead of text. OTP and promo filter built and run on the real corpus (counts only); three messages left to review. |
| 21 Nov 2026 | iPhone route confirmed with a real HDFC alert: automation fired, message staged and saved after unlock. Earlier misses were automation setup (old Llm Bench action, Ask Each Time). Llm Bench removed from the iPhone; inbox saved in testdata/raw/iphone_inbox_all.jsonl. |
| 20 Nov 2026 | iPhone Shortcut route built in the real app. Manual action proven end to end (found and fixed a lost-message bug in the first stage design). Real bank SMS automations are not triggering: under investigation. |
| 19 Nov 2026 | Android SMS receiver done: bank alerts are encrypted-staged even with the app closed and saved to raw_messages on unlock; disclosure screen added. Old test database on the phones had to be wiped (same schema version, fewer tables). |
| 18 Nov 2026 | App lock done and checked on iPhone 15 and vivo V29e. SMS tool reads the iPhone Shortcut inbox (35 lines, 26 unique; HDFC 21). |
| 17 Nov 2026 | Schema v1 done: banks, accounts, raw_messages, transactions, pipeline_log, hidden_hash, settings. |
| 17 Nov 2026 | Encrypted main.db done: file is unreadable without the key on both iPhone 15 and vivo V29e, wrong key refused. |
| 17 Nov 2026 | Package ids confirmed (Android `com.paisavault.paisa_vault`, iOS `com.paisavault.paisaVault`). Phase 1A started: app interfaces, fakes and Riverpod set up in `mobile/`. |
| 17 Nov 2026 | Design signed off from the screenshots (owner; later changes allowed). vivo benchmark rerun on the latest build: Qwen3 5.9 s and 93.8% merchant, Gemma 4.2 s and 87.5%. Device matrix recorded. NFC left for later. Owner's main phone is the iPhone and they will use the app themselves; Apple and Google accounts being created.  |
| 16 Nov 2026 | Camera card scan works on iPhone and vivo (`docs/spikes/camera-scan.md`). Wi-Fi sync spike works on home Wi-Fi (`docs/spikes/wifi-sync.md`). NFC spike app built, untested (vivo has no NFC). ADR 0001 and privacy drafts written. Technical decisions logged. |
| 14 Nov 2026 | vivo SMS delay fixed: with battery set to unrestricted, a real bank alert reached the receiver about 0.6 s after the system got it, app swiped away. `INDBNK` confirmed as Indian Bank. Still to test: after phone restart, RCS. |
| 13 Nov 2026 | Android SMS receiver works on the real vivo (plain SMS, sub id 1, no text logged). One SIM only, so dual SIM untested. Notes in `docs/spikes/android-sms-receiver.md`. |
| 13 Nov 2026 | iOS Shortcut spike: App Intent "Log Bank Message" saves SMS text from a Shortcuts automation on the iPhone 15 within seconds. Several keywords double-save, so the app must deduplicate. Notes in `docs/spikes/ios-shortcut.md`. |
| 12 Nov 2026 | Split extraction (rules plus model for merchant, category, channel) benchmarked on both phones. iPhone 15 release: Gemma 1.7 s, Qwen3 2.4 s per SMS; vivo: 4.7 s and 6.8 s. Working model choice Qwen3 1.7B recorded in `docs/DECISIONS.md`; ADR 0001 still needs vivo and real-SMS reruns, licence and pack-size checks. |
| 12 Nov 2026 | Benchmark app `spikes/llm_bench/` runs Gemma 3 1B and Qwen3 1.7B on the iPhone 15 and vivo. vivo avg per SMS: Gemma 12.5 s, Qwen3 60.7 s (target under 3 s). Next: rules take most fields, model returns merchant and category only. Runtime notes in `docs/spikes/llm-runtime.md`. |
| 2 Nov 2026  | Both phones detected by `flutter devices`: Android V2303 (Android 15) and iPhone (iOS 26.7.1).                                                                                              |
| 11 Nov 2026 | Added 24-message synthetic seed set and scorer. Mac result: Qwen3 1.7B 100% on all fields except channel (86.7%); Gemma 3 1B weaker on reference (63.6%) and channel (80%). Small synthetic test, not the model decision. |
| 6 Nov 2026  | Android SMS receiver spike (`mobile/android/.../SmsReceiver.kt`) logs sender and SIM id on the emulator. Sender ID table drafted. `models/` git-ignored.                                         |
| 6 Nov 2026  | Flutter skeleton in `mobile/`, stricter lints, one widget test, CI workflow. Gemma 3 1B console app in `tools/llm_console/`: first runs got several fields wrong, so prompt tuning is next. |
| 4 Nov 2026  | SMS tool now recognises 20 more Indian banks as bonus samples (core five unchanged), adds a `core` flag and `--list-senders`. 14 tests passing.                                           |
| 2 Nov 2026  | `adb` added to PATH by you and verified.                                                                                                                                                   |
| 2 Nov 2026  | Accepted Android licences, installed SDK 36 and build-tools 28.0.3, updated CocoaPods. Added SMS anonymiser, export guide and `.gitignore`. `flutter doctor` Android toolchain now passes. |
| 2 Nov 2026  | Verified the "Blocked on you" items: none done yet.                                                                                                                                        |
| 2 Nov 2026  | Created this tracker. Phase 0 in progress.                                                                                                                                                 |
| 29 Oct 2026 | Flutter upgraded to 3.47.8, JDK 17 configured, Intel Mac risk recorded. Planning docs committed.                                                                                           |
| 27 Nov 2026 | "Needs a category" notification: one new uncategorised transaction is announced at once; several waiting are grouped into one reminder a day, shown after 6 pm the next time the app processes messages. Text never names a merchant or amount. Exact-time reminders while the app is closed need the background job (WorkManager), still open. |
| 27 Nov 2026 | Merchant rules screen (Settings > Merchant rules): lists the merchants the app files automatically, change a rule's category or forget it. Changes affect new transactions only. |
| 27 Nov 2026 | Dashboard: earning, spend and savings for a calendar month with a category donut and list, previous and next month. Own-account transfers and the Transfer category do not count; money out with no category shows as Uncategorised. The Transactions top bar now opens the dashboard; Budgets is a button on it. |
| 27 Nov 2026 | PIN recovery: "Forgot PIN?" on the lock screen. Explains there is no reset, suggests Face ID or fingerprint when turned on, otherwise offers erase everything (two confirmations) and then restore from the encrypted backup after creating a new PIN. Erase logic shared with Settings. |
| 27 Nov 2026 | Re-check after a model change (T6): Settings > Re-check with the model. Looks at up to 20 recent transactions made by an older model or prompt version, never ones you edited, and needs the original message still saved. Shows old and new merchant, category and channel; nothing changes until you tick and apply. Unchanged ones are marked as checked so they are not run again. |
| 27 Nov 2026 | Android: when a bank SMS is saved while the app is closed, a notification says so (generic text only). Notification permission is now asked right after the SMS permission, not only when a budget is added. Chosen instead of a background model run, which is riskier and needs the vivo to prove. |
| 27 Nov 2026 | Android: the last row of every list was hidden behind the navigation bar on the vivo (newer Android draws the app edge to edge). The whole app now stops above the bar on Android; iPhone unchanged. |
| 27 Nov 2026 | Wrote the backup key design note (ADR 0002). Checked the Android release APK permissions: no INTERNET, no READ_SMS. |
