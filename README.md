# Paisa Vault

Private, offline-first expense manager (Flutter, on-device AI). See the product plan for details.

## Screen prototype (dummy data)

A clickable, mobile-sized web prototype of every planned screen, styled after the UI reference (soft blue cards, donut chart, bar statistics, floating bottom navigation). All data is fake. No build step, no dependencies.

Screens: lock, home, dashboard, activity, search, "what was this?", card vault, card detail (reveal), add card, profile, hidden vault, self transfers, household, reports, budgets, alerts, backup, security.

### Run it

**VS Code:** open this folder, install the "Live Server" extension, right-click `app/index.html` and choose "Open with Live Server".

**Terminal:**

```sh
cd app
python3 -m http.server 8080
# open http://localhost:8080 (use browser device mode / phone width for best view)
```

You can also just double-click `app/index.html`. On the lock screen tap any 4 digits (or "Use Face ID").

### Screenshots

PNGs of every screen are in `screenshots/`. To regenerate: `npm i playwright && node screenshots.js`.
