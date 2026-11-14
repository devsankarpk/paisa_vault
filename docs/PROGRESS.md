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
- [ ] Free Apple ID added in Xcode for signing (needed to run apps on the iPhone)
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
- [ ] Phone models and OS versions recorded in [TESTING.md](TESTING.md)
- [ ] Google Play and Apple developer accounts set up (or decision to defer)

**Week 1: data and Android basics**

- [ ] Collect SMS, 20 or more per core bank (HDFC, SBI, ICICI, Axis, Yes), all message types. Other Indian banks are optional bonus samples
- [x] Anonymisation script ([tools/sms_corpus/](../tools/sms_corpus/), 9 tests passing)
- [ ] Anonymised corpus `testdata/sms_samples.json`
- [ ] Labels `testdata/sms_labels.json`
- [ ] Sender ID table `testdata/sender_ids.json` (T2): draft with the known codes created; fill in what your phones actually receive, SMS or RCS, and SIM
- [x] `testdata/` raw data in `.gitignore`
- [x] Flutter project skeleton in `mobile/`, lint and test pass locally; CI workflow added (confirm it is green after the first push)
- [ ] Android SMS receiver spike on the real phone (receiver works on the emulator: sender and SIM id logged, no message text; real vivo: plain SMS and a real bank alert (INDBNK) received, sender and SIM id logged; app swiped away was 2 to 4 minutes late on default settings, 0.6 s after setting battery to unrestricted (14 Nov); restart, dual SIM and RCS still to test, see docs/spikes/android-sms-receiver.md)

**Week 2: spikes and LLM bake-off**

- [ ] iOS Shortcut to App Intent spike (SMS and RCS/iMessage): SMS path works on iPhone 15 (a few seconds, banner shows, duplicates when several keywords match); closed-app (unlocked) works as of 14 Nov; locked-then-unlocked works; SMS arriving while still locked, iMessage and RCS still open. See docs/spikes/ios-shortcut.md
- [ ] NFC spike and card matrix (T7)
- [ ] Camera card scan spike
- [ ] LLM Stage A: prompt and schema tuning on the Mac (first pass done on 24 synthetic SMS: Qwen3 1.7B 2 misses, Gemma 3 1B 11 misses; needs the real corpus to confirm)
- [x] LLM Stage B: benchmark app run on both phones (iPhone 15 release: Gemma 1.7 s, Qwen3 2.4 s per SMS; vivo: 4.7 s and 6.8 s; working choice Qwen3 1.7B, see DECISIONS.md). Reruns on real SMS and the latest vivo build still open.
- [ ] Scorecard and ADR 0001 draft
- [ ] Wi-Fi sync spike (T1)

**Week 3: bundling, design, decisions**

- [ ] Bundling check: model size, install-time pack, iOS app size
- [ ] Design lock: prototype updated and every screen signed off
- [ ] Technical decisions logged in [DECISIONS.md](DECISIONS.md) (state management, min OS versions, ids, folder layout, logging, PDF package, share-to-app)
- [ ] Privacy groundwork: data inventory, draft policy, Play SMS declaration draft (T4)
- [x] Model licence review (T3): both models can be shipped; Qwen3 is simpler (Apache 2.0). See docs/spikes/model-licences.md
- [ ] Phase review and demo

**Exit gate**

- [ ] ADR 0001 accepted (model chosen, thresholds met, licence checked)
- [x] Android SMS receiver works on the real phone
- [x] iOS Shortcut route saves SMS in the background, or fallback chosen (app closed works; app must deduplicate the double save)
- [ ] NFC decision made
- [ ] Wi-Fi sync works, fallback decided
- [ ] Screens signed off and technical decisions logged

---

## Phase 1A: Foundation, SMS and AI

[Details](phases/phase-1a-foundation-sms-ai.md)

- [ ] Interfaces and fakes (SmsSource, LlmEngine, CardReader, TextScanner, Clock, Logger)
- [ ] Encrypted main.db with keys in Keystore or Keychain
- [ ] Schema v1 and migrations
- [ ] App lock: PIN, biometrics, auto-lock, create-PIN with recovery note
- [ ] Android SMS disclosure and receiver plugin
- [ ] iPhone App Intent and Shortcut guide
- [ ] OTP and promo filter, sender normalisation
- [ ] Encrypted raw_messages with purge job
- [ ] LlmEngine for the chosen model, manifest, bundled model
- [ ] Extraction prompt and strict JSON schema
- [ ] Amount safety check
- [ ] Processing queue (WorkManager, next-open on iPhone)
- [ ] Duplicate check
- [ ] Bank, card and account mapping
- [ ] Pipeline log, local crash capture, redaction test
- [ ] Consent screens and "Erase everything"
- [ ] Backup key design note
- [ ] Golden-SMS suite in CI, real SMS from all five banks on both phones

**Exit gate**

- [ ] Real SMS from each bank becomes a mapped transaction on Android and iPhone
- [ ] Amount safety check proven
- [ ] Golden suite green and meets Phase 0 thresholds
- [ ] Release build has no INTERNET permission
- [ ] "Erase everything" works
- [ ] Redaction test passes

## Phase 1B: Categorise, search, budgets, backup

[Details](phases/phase-1b-categorise-search-budgets.md)

- [ ] Categories, merchants, merchant_rules, seed data
- [ ] Categoriser (rule, similar, LLM, ask)
- [ ] Income handling
- [ ] Manual entry and transaction detail/edit
- [ ] "What was this?" flow and notification
- [ ] Category and merchant-rule management screens
- [ ] Search (date, category, exact amount in range, text) with indexes
- [ ] Budgets and threshold alerts, once per period
- [ ] Uncategorised alert and evening grouping
- [ ] Dashboard numbers from transactions
- [ ] Encrypted backup and restore
- [ ] PIN recovery path
- [ ] Diagnostics screen and export
- [ ] Re-check after model change
- [ ] One-week dogfood on both phones

**Exit gate**

- [ ] A week of real use with no lost or duplicated transactions
- [ ] Same merchant categorised automatically after first answer
- [ ] Each threshold alerts once per period
- [ ] Restore reproduces the ledger exactly
- [ ] Diagnostics export has no amounts, merchants or SMS text

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
