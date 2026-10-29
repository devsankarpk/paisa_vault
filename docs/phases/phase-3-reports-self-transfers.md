# Phase 3: Reports and self transfers

**Dates:** 11 Feb to 3 Mar 2027 (3 weeks). **Back to:** [index](../PHASE_PLAN.md)

## 1. Goal and output
Accurate reports that do not double count the user's own money movements: transfers between own accounts, credit card bill payments and wallet top-ups are confirmed and left out of spending.

## 2. Spec coverage
CLAUDE.md 3.7 (self transfers), 3.8 (month-end review notification), 3.10 (reports), section 6 (self_transfer_reviews).

## 3. Prerequisites
- Phase 2 exit gate passed (hidden data must be excluded from reports).
- Accounts and cards mapped by bank and last 4 (Phases 1A and 2).
- Signed-off screens: self transfers, reports, report confirmation gate.

## 4. Work breakdown

### Week 1: self-transfer detection and review
| Task | Deliverable | Days |
|---|---|---|
| Table self_transfer_reviews: suggested pair, reason, user answer, timestamps. | Migration | 0.5 |
| Detection rules: same amount debited from one own account and credited to another within a short window; payment to one's own credit card; transfer to one's own wallet. Window and tolerance are settings with defaults. | Detector with tests per rule | 2 |
| Review screen: "Yes, mine" or "No, spending", reason shown. Confirmed transfers excluded from totals and budgets; answer remembered for similar future pairs. | Screen and effects | 1.5 |
| Month-end notification: "You have 3 possible self transfers this month. Please review." | Scheduled local notification | 1 |

### Week 2: reports
| Task | Deliverable | Days |
|---|---|---|
| Report engine: monthly and custom date range. Category breakdown, top merchants, card-wise spending. Hidden data excluded. | Engine and tests | 2 |
| Confirmation gate: every time a report is generated and unconfirmed suggestions exist, ask before totals are shown. | Gate screen | 1 |
| Reports screen with month chips and custom range, donut and top-merchant list. | Screen | 1.5 |
| Household-ready totals: shared flag respected (shared view arrives in Phase 4). | Flag respected | 0.5 |

### Week 3: export and hardening
| Task | Deliverable | Days |
|---|---|---|
| PDF and CSV export for the user's own records. Export via the share sheet. | Files open correctly | 1.5 |
| Encrypted export file with passphrase (same format as the backup key design). | Round trip | 1 |
| Reconciliation checks against the ledger, edge cases (refund-like credits, month boundaries, time zones). | Reconciliation tests | 1 |
| Dogfood a full month of real data. Phase review. | Exit gate checked | 1.5 |

## 5. Data model
main.db: self_transfer_reviews. Self-transfer flag already on transactions.

## 6. Packages
A PDF package (chosen in Phase 0 or here), csv, share_plus, cryptography, flutter_local_notifications.

## 7. Prototype screens that become real
[Self transfers](../../screenshots/selftransfers.png), [Reports](../../screenshots/reports.png), [Alerts](../../screenshots/alerts.png), [Profile](../../screenshots/profile.png).

## 8. Tests
- **Detector:** table-driven cases for each rule, including near misses that must not match (same amount but days apart).
- **Reconciliation:** report totals equal the sum of ledger rows after exclusions, for random generated months.
- **Hidden exclusion:** hidden amounts are in no report and no export (reuses the Phase 2 test).
- **Gate:** report cannot show totals while suggestions are unconfirmed.
- **Export:** CSV opens in a spreadsheet, PDF renders, encrypted file needs the passphrase.

## 9. Exit gate
- Report totals reconcile to the ledger to the paisa.
- Confirmed self transfers are excluded from totals and budgets.
- The confirmation step appears before every report that has unconfirmed suggestions.
- Month-end notification fires.
- PDF, CSV and encrypted exports work.

## 10. Risks and fallback
| Risk | Fallback |
|---|---|
| Too many false suggestions | Tighten the window, require both legs in own accounts, rank by confidence |
| Missing leg (only one side's SMS arrives) | Ask the user, allow manual marking |
| PDF package problems | Generate simple HTML-to-PDF or ship CSV first |

## 11. Demo
Generate a report, answer the self-transfer prompt, show the totals change, export a PDF and CSV.
