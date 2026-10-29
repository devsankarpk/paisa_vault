# Phase 1B: Categorise, search, budgets, backup

**Dates:** 17 Dec 2026 to 13 Jan 2027 (4 weeks). **Back to:** [index](../PHASE_PLAN.md)

## 1. Goal and output
A usable personal expense tracker on both phones: transactions are categorised and learned, searchable, budgeted with alerts, and safely backed up.

## 2. Spec coverage
CLAUDE.md 3.3 (categorisation and learning), 3.4 (search), 3.8 (budget and uncategorised alerts), section 7 (backups), 8 (Phase 1 remainder).

## 3. Prerequisites
- Phase 1A exit gate passed.
- Default categories (proposed): Food, Groceries, Shopping, Bills, Travel, Health, Entertainment, Other, plus Income and Transfer.
- Budget period: calendar month (proposed). Salary-date cycle is a later option.

## 4. Work breakdown

### Week 1: categories and rules
| Task | Deliverable | Days |
|---|---|---|
| Tables: categories (tree: expense, income, transfer), merchants, merchant_rules. Seed default categories. | Migration and seed | 1 |
| Categoriser in order: merchant rule (UPI ID first, then name), similar past transaction (fuzzy, e.g. "SWIGGY INSTAMART" to "SWIGGY"), LLM suggestion limited to the user's categories, else ask. | Categoriser with a test per step | 2.5 |
| Income handling: salary and other credits map to Income or are asked, never to expense categories. | Tests | 0.5 |
| Manual entry and transaction detail/edit: category, note, shared flag, hide action (hook only, stored but vault arrives in Phase 2). | Screens working | 1 |

### Week 2: "What was this?" and search
| Task | Deliverable | Days |
|---|---|---|
| "What was this?" flow: notification ("Rs 480 paid to RAJU STORES. What was this?"), category pick, optional note, "always use this category" saves a rule. On iPhone the prompt appears on next app open. | Flow on both OSes | 2 |
| Category and merchant-rule management screens, with empty states. | Screens | 1 |
| Search: date range, category, exact amount within a date range, text on merchant and notes. Filters combine. Indexes: date, category+date, amount+date, full-text. | Search with indexes | 2 |

### Week 3: budgets and alerts
| Task | Deliverable | Days |
|---|---|---|
| Budgets per category and calendar month, with thresholds 70, 80, 90 and 100%. Add budget form. | Budget CRUD | 1.5 |
| budget_alert_log: each threshold fires once per period. Uncategorised alert, grouped into a daily evening reminder when several are pending. flutter_local_notifications. | Alert tests | 2 |
| Dashboard numbers: earning, spend and savings derived from categorised transactions. Optional daily limit as a budget. | Dashboard live | 1 |
| Self-transfer placeholder: transfers flagged later in Phase 3, already excluded from budgets by a flag. | Flag in schema | 0.5 |

### Week 4: backup, diagnostics, dogfood
| Task | Deliverable | Days |
|---|---|---|
| Encrypted backup file with a user passphrase (key derived from the passphrase, not device keys). Restore on a clean install or a new phone. Decide whether raw_messages are included (proposed: excluded). | Backup and restore round trip | 2 |
| PIN recovery path: biometric unlock if enrolled, else wipe and restore, explained in setup. | Flow tested | 0.5 |
| Diagnostics screen and export (T5): success rate, please-confirm rate, speed, last errors, redacted export. | Screen and export | 1 |
| Re-check recent transactions after a model change (T6), using raw_messages. | Reprocess job | 0.5 |
| One-week dogfood on both phones with real use, collect diagnostics, fix top issues. Phase review. | Exit gate checked | 1 plus week |

## 5. Data model
New: categories, merchants, merchant_rules, budgets, budget_alert_log. Index list above. Self-transfer flag on transactions already in 1A.

## 6. Packages
flutter_local_notifications, workmanager (reminders), drift full-text search, cryptography, share_plus for exports (decided in Phase 0).

## 7. Prototype screens that become real
[Ask](../../screenshots/ask.png), [Transaction detail](../../screenshots/txn-9.png), [Add transaction](../../screenshots/addtxn.png), [Search](../../screenshots/search.png), [Budgets](../../screenshots/budgets.png), [Dashboard](../../screenshots/dashboard.png), [Alerts](../../screenshots/alerts.png), [Activity](../../screenshots/activity.png), [Home](../../screenshots/home.png), [Backup](../../screenshots/backup.png).

## 8. Tests
- **Unit:** each categoriser step and the order, fuzzy matching thresholds, search filters, budget math, threshold-once logic across period change.
- **Property test:** search by amount within dates returns exactly the matching rows.
- **Backup:** back up, wipe, restore, compare all rows and settings.
- **Alerts:** simulated month with spend crossing each threshold, one alert each.
- **Device:** notifications on Android 13+ and iOS with permission denied and granted.

## 9. Exit gate
- One week of real daily use on both phones with no lost or duplicated transactions.
- Same merchant is categorised automatically after the first answer.
- Each budget threshold alerts exactly once per period.
- Backup restored on a clean install reproduces the ledger exactly.
- Diagnostics export contains no amounts, merchants or SMS text by default.

## 10. Risks and fallback
| Risk | Fallback |
|---|---|
| Fuzzy matching makes wrong matches | Raise the threshold, ask the user below it |
| Notification permission denied | In-app inbox of pending questions |
| LLM category suggestions weak | Rely on rules and asking; suggestion is optional |
| Restore on a new phone fails because of keys | Backup uses its own passphrase-derived key (designed in 1A) |

## 11. Demo
Categorise a first-time merchant, show it learned on the next SMS, search by exact amount in a date range, trigger budget alerts, back up and restore.

**Platform topics:** T5, T6 in [PLATFORM_AND_COMPLIANCE.md](../PLATFORM_AND_COMPLIANCE.md).
