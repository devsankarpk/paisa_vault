# Paisa Vault

A private, offline-first expense manager for Android and iPhone. It reads new bank and UPI SMS, uses an on-device AI model to work out the bank, card, amount, merchant and category, and keeps everything on the phone. No server, no cloud account.

**Status:** planning complete, clickable screen prototype available. The Flutter app has not been started. Phase 0 is next.

- Full product and technical spec: [CLAUDE.md](CLAUDE.md)
- Phase-by-phase plan: [docs/PHASE_PLAN.md](docs/PHASE_PLAN.md)

## Principles

- **Private by design.** Data and AI stay on the phone.
- **Secure.** Encrypted database, PIN or biometric lock, separate vault for hidden data, CVV never stored.
- **Simple.** Few taps, clear screens.
- **India first.** INR and Indian banks, with a currency code stored from day one.

## Try the prototype

A clickable, mobile-sized web prototype of every planned screen. All data is fake. No build step, no dependencies.

**VS Code:** open this folder, install the "Live Server" extension, right-click `app/index.html` and choose "Open with Live Server".

**Terminal:**

```sh
cd app
python3 -m http.server 8080
# open http://localhost:8080 (use browser device mode / phone width for best view)
```

You can also double-click `app/index.html`. On the lock screen tap any 4 digits (or "Use Face ID").

Tips:
- The hidden vault has no menu entry on purpose. Long-press (or double-click) the avatar on the Profile tab.
- The Profile tab has "SMS setup guide" for the onboarding screens.

## Screens

Spec numbers (3.x) refer to [CLAUDE.md](CLAUDE.md). The visual style follows the soft-blue UI reference and replaces the white/grey guideline in spec 3.11.

### Access and onboarding

| | | | |
|---|---|---|---|
| ![Lock](screenshots/lock.png) | ![Onboarding](screenshots/onboard.png) | ![Shortcut](screenshots/shortcut.png) | ![PIN](screenshots/setpin.png) |
| **Lock** PIN or Face ID | **SMS disclosure** (3.1) | **iPhone Shortcut guide** (3.1) | **Create PIN** |

### Home and insights

| | | | |
|---|---|---|---|
| ![Home](screenshots/home.png) | ![Dashboard](screenshots/dashboard.png) | ![Activity](screenshots/activity.png) | ![Search](screenshots/search.png) |
| **Home** cards, quick actions | **Dashboard** spend and budgets | **Activity** weekly stats | **Search** date, category, amount (3.4) |

### Transactions and learning

| | | | |
|---|---|---|---|
| ![Ask](screenshots/ask.png) | ![Detail](screenshots/txn-9.png) | ![Add](screenshots/addtxn.png) | |
| **What was this?** (3.3) | **Detail** with "please confirm" (3.2) | **Manual entry** | |

### Cards

| | | | |
|---|---|---|---|
| ![Cards](screenshots/cards.png) | ![Card](screenshots/card-hdfc.png) | ![Add card](screenshots/addcard.png) | ![Bill](screenshots/billsetup.png) |
| **Card vault** last 4 only (3.5) | **Reveal** after Face ID | **Add card** NFC, camera | **Bill reminder** setup |

### Privacy, money and people

| | | | |
|---|---|---|---|
| ![Hidden](screenshots/hidden.png) | ![Self](screenshots/selftransfers.png) | ![Reports](screenshots/reports.png) | ![Budgets](screenshots/budgets.png) |
| **Hidden vault** (3.6) | **Self transfers** (3.7) | **Reports** (3.10) | **Budgets** (3.8) |
| ![Alerts](screenshots/alerts.png) | ![Household](screenshots/household.png) | ![Backup](screenshots/backup.png) | ![Security](screenshots/security.png) |
| **Alerts** (3.8) | **Household** (3.9) | **Encrypted backup** | **Security** |

![Profile](screenshots/profile.png)

**Profile** is the entry to everything else.

## How it works

```
SMS (Android receiver / iOS Shortcut) → filter OTP and promo → on-device LLM
→ amount safety check → duplicate check → categoriser (rule → similar → LLM → ask you)
→ encrypted SQLite: main.db + separate vault.db for hidden data
```

## Key decisions

| Topic | Decision |
|---|---|
| Platforms | Android and iPhone, one Flutter codebase |
| Database | Encrypted SQLite (drift, SQLCipher-compatible) |
| SMS | Android reads new SMS directly. iPhone uses a Shortcuts automation. Only new SMS, never old ones. |
| AI | One bundled on-device LLM (Gemma 3 1B, Qwen3 1.7B tested in Phase 0), shipped with the app |
| Cards | Android NFC, iPhone camera or manual. List shows last 4 only. CVV never stored. PIN storage opt-in. |
| Hidden data | Separate encrypted vault, never exported or shared |
| Household | QR pairing, end-to-end encrypted sync over the same Wi-Fi |
| Currency | INR now, currency code stored for later |

## Phase plan

One developer, starting 29 Oct 2026. 25 weeks of phases plus a 4 week buffer, store submission by 19 May 2027. Only the on-device LLM is undecided; Phase 0 decides it.

| Phase | Dates | Weeks | Output | Details |
|---|---|---|---|---|
| 0 Groundwork and design lock | 29 Oct to 18 Nov 2026 | 3 | LLM chosen, platform spikes proven, screens signed off | [phase 0](docs/phases/phase-0-groundwork.md) |
| 1A Foundation, SMS and AI | 19 Nov to 16 Dec | 4 | SMS becomes a stored, card-mapped transaction | [phase 1A](docs/phases/phase-1a-foundation-sms-ai.md) |
| 1B Categorise, search, budgets, backup | 17 Dec to 13 Jan 2027 | 4 | Usable personal tracker | [phase 1B](docs/phases/phase-1b-categorise-search-budgets.md) |
| 2 Cards and privacy | 14 Jan to 10 Feb | 4 | Card vault and hidden transactions | [phase 2](docs/phases/phase-2-cards-privacy.md) |
| 3 Reports and self transfers | 11 Feb to 3 Mar | 3 | Accurate reports | [phase 3](docs/phases/phase-3-reports-self-transfers.md) |
| 4 Household sharing | 4 Mar to 31 Mar | 4 | Shared household budget | [phase 4](docs/phases/phase-4-household-sharing.md) |
| Buffer | 1 Apr to 28 Apr | 4 | Overruns and bug fixing | n/a |
| 5 Release and polish | 29 Apr to 19 May | 3 | Play Store and App Store submissions | [phase 5](docs/phases/phase-5-release.md) |

Each phase ends on a measurable exit gate. Overview and feature coverage: [docs/PHASE_PLAN.md](docs/PHASE_PLAN.md).

### Planning documents

- [Decision log](docs/DECISIONS.md): confirmed and proposed decisions, spec gaps found in review
- [Platform and compliance](docs/PLATFORM_AND_COMPLIANCE.md): Wi-Fi permissions, dual SIM and RCS, model licence, privacy forms, diagnostics, model updates, NFC
- [Testing strategy](docs/TESTING.md)
- [Risk register](docs/RISKS.md)

## Known prototype gaps

Tracked so Phase 0 can close them:
- No screens yet for category and merchant-rule management, month-end self-transfer review, report-time confirmation gate, empty states, or the iPhone "AI processing" state.
- Several controls are visual only: search filter chips, switches, period chips, Pay, Add budget.
- Single fixed dataset. Nothing is saved.

## Open items

- **Open:** the on-device LLM (Gemma 3 1B or Qwen3 1.7B), chosen by the Phase 0 scorecard.
- **Confirmed:** first banks are HDFC, SBI, ICICI, Axis and Yes Bank.
- **Proposed:** calendar-month budgets; categories Food, Groceries, Shopping, Bills, Travel, Health, Entertainment, Other, plus Income and Transfer; "Paisa Vault" kept as the working name.

Full list in [docs/DECISIONS.md](docs/DECISIONS.md).

## Repository layout

```
app/          clickable prototype (index.html, app.js, data.js, styles.css)
screenshots/  PNG of every screen
docs/         phase plan, per-phase files, decisions, testing, risks, platform notes
CLAUDE.md     product and technical spec
screenshots.js  regenerates the PNGs
```

Regenerate screenshots: `npm i playwright && node screenshots.js`.
