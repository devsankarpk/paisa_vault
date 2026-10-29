# Paisa Vault: Phase Plan (v2.0)

Built from [CLAUDE.md](../CLAUDE.md) (the spec). Only the on-device LLM is left undecided; Phase 0 decides it. Every other open item has a value (confirmed or proposed) in [DECISIONS.md](DECISIONS.md).

**Team and devices:** one developer, one real Android phone, one real iPhone.
**Start:** 2026-10-29.

## Documents

| Document | Purpose |
|---|---|
| This file | Overview, timeline, feature coverage |
| [phases/phase-0-groundwork.md](phases/phase-0-groundwork.md) | Spikes, LLM bake-off, design lock |
| [phases/phase-1a-foundation-sms-ai.md](phases/phase-1a-foundation-sms-ai.md) | Encrypted DB, lock, SMS to transaction |
| [phases/phase-1b-categorise-search-budgets.md](phases/phase-1b-categorise-search-budgets.md) | Categories, search, budgets, backup |
| [phases/phase-2-cards-privacy.md](phases/phase-2-cards-privacy.md) | Card vault, hidden vault |
| [phases/phase-3-reports-self-transfers.md](phases/phase-3-reports-self-transfers.md) | Reports, self transfers |
| [phases/phase-4-household-sharing.md](phases/phase-4-household-sharing.md) | Pairing and Wi-Fi sync |
| [phases/phase-5-release.md](phases/phase-5-release.md) | Polish and store submissions |
| [PLATFORM_AND_COMPLIANCE.md](PLATFORM_AND_COMPLIANCE.md) | Seven platform and legal topics (T1 to T7) |
| [DECISIONS.md](DECISIONS.md) | Decision log and spec gaps |
| [TESTING.md](TESTING.md) | Test strategy, golden SMS corpus, device matrix |
| [RISKS.md](RISKS.md) | Risk register |

## Timeline

| Phase | Weeks | Start | End | Output |
|---|---|---|---|---|
| 0 Groundwork and design lock | 3 | 29 Oct 2026 | 18 Nov 2026 | LLM chosen, spikes proven, screens signed off |
| 1A Foundation, SMS and AI | 4 | 19 Nov 2026 | 16 Dec 2026 | A bank SMS becomes a stored, mapped transaction |
| 1B Categorise, search, budgets, backup | 4 | 17 Dec 2026 | 13 Jan 2027 | Usable personal tracker |
| 2 Cards and privacy | 4 | 14 Jan 2027 | 10 Feb 2027 | Card vault and hidden transactions |
| 3 Reports and self transfers | 3 | 11 Feb 2027 | 3 Mar 2027 | Accurate reports |
| 4 Household sharing | 4 | 4 Mar 2027 | 31 Mar 2027 | Shared household budget |
| Buffer | 4 | 1 Apr 2027 | 28 Apr 2027 | Overruns, bug fixing |
| 5 Release and polish | 3 | 29 Apr 2027 | 19 May 2027 | Store submissions |
| Store review and fixes | about 2 | 20 May 2027 | early Jun 2027 | Published, or fallback chosen |

CLAUDE.md estimates 22 to 24 weeks. This plan budgets the upper end of each range (25 weeks, one extra week in Phase 0 for design lock) plus a 4 week buffer, about 16%. Dates are targets; each phase ends on its exit gate, not on the date.

```
Phase 0 → 1A → 1B → 2 → 3 → 4 → buffer → 5
              └── dogfood on both phones from end of 1B onward
```

If a second developer joins, Phase 2 (cards, privacy) and Phase 3 (reports) can run in parallel after 1B. Phase 4 needs both.

## Feature coverage (CLAUDE.md section 3)

Each feature has one phase that completes it. Some have earlier foundations or later additions, noted in the last column.

| Spec | Feature | Completed in | Also touched |
|---|---|---|---|
| 3.1 | SMS reading (Android, iPhone) | 1A | Spikes in 0 |
| 3.2 | On-device AI, safety check | 1A | Choice in 0, reprocess in 1B |
| 3.3 | Categorisation and learning | 1B | Hide hook in 1B, vault in 2 |
| 3.4 | Search | 1B | |
| 3.5 | Card vault, bill reminders | 2 | NFC spike in 0 |
| 3.6 | Hidden transactions | 2 | Hash table reserved in 1A |
| 3.7 | Self transfers | 3 | |
| 3.8 | Alerts | 1B (budget, uncategorised) | Card due in 2, month-end in 3 |
| 3.9 | Household sharing | 4 | Sync spike in 0 |
| 3.10 | Reports | 3 | |
| 3.11 | UI | 0 (sign-off) | Polish in 5 |

## Database tables (CLAUDE.md section 6) by phase

| Phase | main.db | vault.db |
|---|---|---|
| 1A | banks, accounts, transactions, raw_messages, settings, pipeline_log (new), hidden_hash (new) | n/a |
| 1B | categories, merchants, merchant_rules, budgets, budget_alert_log | n/a |
| 2 | cards, card_bill_settings | hidden_transactions, hidden_fingerprints, card_secrets, vault_audit |
| 3 | self_transfer_reviews | n/a |
| 4 | household_peers, household_transactions, sync_log | n/a |

New tables and columns added by the review are listed in [DECISIONS.md](DECISIONS.md).

## What changed from CLAUDE.md section 8, and why

| Change | Reason |
|---|---|
| Design lock moves into Phase 0 | The clickable prototype already exists. Flutter work starts from approved screens. |
| Phase 1 split into 1A and 1B | 7 to 8 weeks in one block hides risk. 1A proves SMS to AI, 1B builds the product around it. |
| Platform and store risks start in Phase 0 | Play's SMS permission, the iPhone Shortcut route and NFC reads can each change the scope. |
| Exit gates are measurable | A phase ends on a check, not a date. |
| Explicit buffer | Solo work on two native bridges plus an LLM is easy to under-estimate. |
| Review gaps recorded | See [DECISIONS.md](DECISIONS.md) and [PLATFORM_AND_COMPLIANCE.md](PLATFORM_AND_COMPLIANCE.md). |

## Working rules for every phase

- A phase is not done until every item in its exit gate passes on a real device (and on both OSes where the feature applies).
- The golden SMS corpus runs in CI from Phase 1A. No change merges if accuracy drops.
- Real SMS never go into git. Only anonymised files are committed (see [TESTING.md](TESTING.md)).
- Native and AI packages sit behind app-level interfaces so they can be replaced.
- Each phase ends with a short demo against the screens listed in its file.
- If a risk trigger in [RISKS.md](RISKS.md) fires, stop and decide on the fallback before continuing.
