# Decision log

Status values: **Confirmed** (you said so), **Proposed** (my default, change if you disagree), **Open** (decided by a test), **Phase 0** (decide in that phase, deadline given).

## Product decisions

| # | Decision | Status | Phase |
|---|---|---|---|
| D1 | Banks to support first: HDFC, SBI, ICICI, Axis, Yes Bank | Confirmed | 0 |
| D2 | Team: one developer, a real Android phone and a real iPhone | Confirmed | all |
| D3 | Budget period: calendar month. Salary-date cycle later. | Proposed | 1B |
| D4 | Default categories: Food, Groceries, Shopping, Bills, Travel, Health, Entertainment, Other, plus Income and Transfer | Proposed | 1B |
| D5 | App name: "Paisa Vault" as the working name | Proposed | 5 |
| D6 | UI style: soft-blue prototype design supersedes the white and grey guideline in CLAUDE.md 3.11 | Confirmed | 0 |
| D7 | Local LLM: Gemma 3 1B vs Qwen3 1.7B, chosen by the Phase 0 scorecard. **The only open technical decision.** | Open | 0 |

## Design decisions from the gap review

| # | Gap in the spec | Decision | Status | Phase |
|---|---|---|---|---|
| G1 | Hidden dedupe needs vault.db, which is locked during background SMS processing | Keep a keyed hash (HMAC) of the fingerprint in main.db. Matches go to a vault queue and are stored on next unlock. vault.db keeps the authoritative copy. | Confirmed | 1A reserve, 2 build |
| G2 | No PIN recovery without a server | Biometrics can unlock if enrolled; otherwise wipe and restore from the passphrase backup. Stated plainly in setup. | Confirmed | 1A, 1B |
| G3 | Prototype shows balance, earning, savings, daily limit, which the spec does not define | Derive earning, spend, savings from categorised transactions. Drop available balance. Daily limit becomes an optional budget. | Confirmed | 1B |
| G4 | Backup and restore on a new phone: device keys cannot be exported | Backup uses its own passphrase-derived key. Raw messages excluded from backups (proposed). | Proposed | 1A design, 1B build |
| G5 | Income credits have no category rule | Credits map to Income or are asked; never to expense categories. | Proposed | 1B |
| G6 | "Totals still add up correctly, with no gaps" is ambiguous (CLAUDE.md 3.6) | Hidden transactions are removed from every total, including household totals; the true-budget view in the vault adds them back for the owner only. | Proposed | 2 |
| G7 | iPhone processes SMS only when the app opens, so "What was this?" cannot fire instantly | The question appears on next open and is explained in onboarding. | Proposed | 1B |
| G8 | CLAUDE.md section 7 implies no network permission, but Android needs INTERNET for local sockets | Builds before Phase 4 have no INTERNET; Phase 4 adds it with a LAN-only network test. | Proposed | 4 |
| G9 | NFC may read few Indian cards | Manual and camera entry first-class; NFC gated on the Phase 0 matrix. | Proposed | 0, 2 |

## Schema additions beyond CLAUDE.md section 6

| Addition | Why | Phase |
|---|---|---|
| `banks.sender_ids` | Map sender header to bank (T2) | 1A |
| `raw_messages.sim_subscription_id` | Dual SIM (T2) | 1A |
| `transactions.model_id`, `transactions.prompt_version` | Re-check after model updates (T6) | 1A |
| `pipeline_log` | Local diagnostics (T5) | 1A |
| `hidden_hash` | Hidden dedupe while the vault is locked (G1) | 1A reserve, 2 use |

## Technical decisions to take in Phase 0 (deadline 18 Nov 2026)

State management approach, minimum Android and iOS versions, bundle and package ids, Flutter folder layout, logging approach, PDF package, share-to-app in version 1 (yes or no), Google Play and Apple developer account set-up.

## Changes to CLAUDE.md

- 3.11: note that the prototype style supersedes the white and grey guideline (done).
- 10: record the confirmed and proposed open items (done).
- 2, decision 9 (card capture): may change after the Phase 0 NFC matrix (T7).
