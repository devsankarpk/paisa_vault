# Paisa Vault

A private, offline-first expense manager for Android and iPhone. It reads new bank and UPI SMS, uses an on-device AI model to work out the bank, card, amount, merchant and category, and keeps everything on the phone. No server, no cloud account.

**Status:** planning complete, clickable screen prototype available. The Flutter app has not been started. Phase 0 is next.

- Full product and technical spec: [CLOUD.md](CLOUD.md)
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

Spec numbers (3.x) refer to [CLOUD.md](CLOUD.md). The visual style follows the soft-blue UI reference and replaces the white/grey guideline in spec 3.11.

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

About 22 to 24 weeks for one developer. Details, scope and exit gates are in [docs/PHASE_PLAN.md](docs/PHASE_PLAN.md).

| Phase | Weeks | Output |
|---|---|---|
| 0 Groundwork and design lock | 2 to 3 | Model chosen, platform spikes proven, screens signed off |
| 1A Foundation, SMS and AI | 4 | SMS becomes a stored, card-mapped transaction |
| 1B Categorise, search, budgets, backup | 3 to 4 | Usable personal tracker |
| 2 Cards and privacy | 4 | Card vault and hidden transactions |
| 3 Reports and self transfers | 3 | Accurate reports |
| 4 Household sharing | 4 | Shared household budget |
| 5 Release and polish | 2 to 3 | Play Store and App Store submissions |

## Known prototype gaps

Tracked so Phase 0 can close them:
- No screens yet for category and merchant-rule management, month-end self-transfer review, report-time confirmation gate, empty states, or the iPhone "AI processing" state.
- Several controls are visual only: search filter chips, switches, period chips, Pay, Add budget.
- Single fixed dataset. Nothing is saved.

## Open items

Bank list for test SMS, default categories, budget period (calendar month or salary cycle), final model, app name and branding.

## Repository layout

```
app/          clickable prototype (index.html, app.js, data.js, styles.css)
screenshots/  PNG of every screen
docs/         phase plan
CLOUD.md      product and technical spec
screenshots.js  regenerates the PNGs
```

Regenerate screenshots: `npm i playwright && node screenshots.js`.
