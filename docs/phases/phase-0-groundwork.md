# Phase 0: Groundwork and design lock

**Dates:** 29 Oct to 18 Nov 2026 (3 weeks). **Back to:** [index](../PHASE_PLAN.md)

## 1. Goal and output
Remove the biggest unknowns before app code: choose the local LLM, prove the four platform spikes on real devices, and sign off the screens. Output: an accepted LLM decision (ADR 0001), working spikes, and a design-locked prototype.

## 2. Spec coverage
CLAUDE.md sections 2 (decisions 3 to 9), 3.1, 3.2, 3.5 (capture only), 3.9 (spike only), 3.11, 8 (Phase 0), 9, 10.

## 3. Prerequisites
- One Android phone and one iPhone, plus a second phone on the same Wi-Fi for the sync spike.
- Access to SMS from HDFC, SBI, ICICI, Axis and Yes Bank (own accounts).
- All physical cards you own, for the NFC test.

## 4. Work breakdown

### Week 1: data and Android basics
| Task | Deliverable | Days |
|---|---|---|
| Collect SMS: 20 or more per bank across debit, credit, UPI, NEFT/IMPS, ATM, POS, failed, refund, OTP and promo. Include both SIMs if dual SIM. | Raw files kept outside git | 2 |
| Anonymisation script: mask names, account and card numbers (keep last 4), phone numbers, balances if wanted. Output `testdata/sms_samples.json`. | Script and anonymised corpus | 1 |
| Label each sample by hand: expected JSON (bank, type, last 4, amount, debit/credit, merchant, channel, reference, date, category). | `testdata/sms_labels.json` | 1.5 |
| Sender ID table per bank (T2): sender IDs seen, SMS or RCS, formats, SIM. | `testdata/sender_ids.json` | 0.5 |
| Flutter project skeleton, lint, CI running tests. Decide folder layout. | CI green on an empty app | 1 |
| Android SMS receiver spike (own Kotlin plugin): log a new bank SMS with sender and SIM subscription id. | Working receiver on the real phone | 1 |

### Week 2: platform spikes and the LLM bake-off
| Task | Deliverable | Days |
|---|---|---|
| iOS Shortcut to App Intent spike: Message automation with Run Immediately, "Log Bank Message" intent, save in background, note the "Shortcut ran" banner. Test with SMS and with RCS/iMessage conversations. | Notes and a working intent on the iPhone | 2 |
| NFC spike on every card you own (T7): matrix of bank, network, debit/credit, contactless, number read, expiry read, time. | `docs/spikes/nfc-matrix.md` | 1 |
| iPhone and Android camera card scan spike (ML Kit text recognition). | Accuracy notes on your cards | 1 |
| **LLM bake-off** (below). | Scorecard and ADR 0001 draft | 3 |
| Wi-Fi sync spike (T1): mDNS discovery and one encrypted message each way between two phones, on a normal and an isolated Wi-Fi. | `docs/spikes/wifi-sync.md` | 1 |

### Week 3: bundling, design, decisions
| Task | Deliverable | Days |
|---|---|---|
| Bundling check: model size in a Play Asset Delivery install-time pack, iOS app size, install time. | Size table in ADR 0001 | 1 |
| Design lock: update the prototype for decided gaps (see section 7), review every screen, sign off. | Signed-off screenshots | 2 |
| Technical decisions recorded in DECISIONS.md: state management, min Android and iOS versions, bundle and package ids, folder layout, logging approach. | Decisions logged | 1 |
| Privacy groundwork (T4): data inventory and draft privacy policy. Draft the Play SMS declaration text. | `docs/privacy/` drafts | 1 |
| Licence review for the chosen model (T3). | Licence section in ADR 0001 | 0.5 |
| Phase review and demo. | Phase 0 exit gate checked | 0.5 |

## LLM bake-off (the one open decision)
**Candidates (CLAUDE.md 3.2):** Gemma 3 1B int4 via flutter_gemma (LiteRT-LM), and Qwen3 1.7B via llamadart. Add another model only if both fail.

**Fairness rules:** same prompt, same JSON schema, same corpus, same devices, each run three times, results averaged. Prompt versions are recorded.

**Scorecard**

| Criterion | How measured | Pass threshold (set before running) |
|---|---|---|
| Amount correct | Exact match against label | 98% |
| Amount appears in SMS | The safety check | 100% of accepted results |
| Bank and last 4 | Exact match | 95% |
| Debit/credit | Exact match | 98% |
| Merchant | Normalised match | 90% |
| Channel, reference, date | Exact match | 90% |
| Category suggestion | Within user category list | 80% |
| Valid JSON | Schema check | 99% |
| Speed per SMS | Seconds, on Android mid-range and on iPhone | Under 3 s |
| Memory and battery | Peak RAM, battery drop over 50 SMS | Documented, no crash |
| Size | Installed model size | Documented |
| Licence | Redistribution in a store app, obligations (T3) | Must allow it |

**Decision rule:** the model must pass every threshold. If both pass, pick the smaller and faster. If neither passes, try prompt changes (few-shot examples, shorter schema) for one more day, then evaluate another model. A model with a licence that blocks store redistribution is out regardless of accuracy.

## 5. Data model
No production tables. Only the corpus files and the spike code.

## 6. Packages tried
flutter_gemma, llamadart, flutter_nfc_kit or emv_nfc_reader, google_mlkit_text_recognition, bonsoir or nsd, cryptography.

## 7. Prototype changes decided here (design lock)
Open [screenshots](../../screenshots/) and sign off each screen. Changes to make in `app/` before sign-off:
- Dashboard: remove "available balance", keep earning, spend, savings from transactions; daily limit shown as an optional budget.
- Add card: lead with manual entry and camera scan, NFC as an optional "tap" shortcut (see T7 result).
- Add: PIN recovery note on Create PIN, "Erase everything" in Security, diagnostics screen, model and licence note.
- Add: category and merchant-rule management, empty states, iPhone "AI processing" state, report-time self-transfer confirmation.
- Add: "unrecognised sender, confirm" state.

## 8. Tests
- Corpus labels are double-checked (each label reviewed twice).
- Bake-off script is repeatable: one command reruns it.
- Spike code runs on the real devices, not only simulators.

## 9. Exit gate
All of these:
- ADR 0001 accepted: model chosen, scorecard attached, thresholds met, licence checked.
- Android SMS receiver works on the real phone, including a message on the second SIM if present.
- iOS Shortcut route saves a bank SMS in the background, or the fallback is chosen.
- NFC matrix recorded and the NFC decision made (ships, optional, or dropped).
- Wi-Fi sync spike works on a normal network, with the fallback decided for isolated networks.
- Screens signed off, and the technical decisions logged.

## 10. Risks and fallback
| Risk | Fallback |
|---|---|
| iOS Shortcut does not run reliably in the background | Add "Share to Paisa Vault" and manual entry as the iPhone path, adjust onboarding |
| Neither model meets the thresholds | Prompt tuning, then another small model; hybrid with rules for amount and bank |
| Too slow on mid-range Android | Queue processing, smaller model, process on charge |
| NFC reads few cards | See T7: manual entry first, NFC optional |
| Banks use RCS | Check each bank, document, rely on share-to-app for those |

## 11. Demo
Show: a real SMS arriving on Android and being logged, a Shortcut firing on the iPhone, the scorecard with the chosen model, the NFC matrix, and the signed-off screens.

**Platform topics:** T1, T2, T3, T4, T7 in [PLATFORM_AND_COMPLIANCE.md](../PLATFORM_AND_COMPLIANCE.md).
