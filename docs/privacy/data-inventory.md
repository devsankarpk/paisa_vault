# Data inventory (draft, 14 Nov 2026)

What Paisa Vault stores, where, how it is protected, how long it is kept, and who gets it. Based on CLAUDE.md sections 3, 6 and 7. Nothing is built yet, so this describes the plan. Update it whenever a feature changes.

## Principles
- All data stays on the phone. There is no server, no account and no analytics or crash-report SDK.
- Release builds for Phases 1 to 3 have no INTERNET permission. From Phase 4 the Android build has it for household sync only.
- The one exception is household sync: phone to phone over the same Wi-Fi, end-to-end encrypted, shared transactions only.

## Inventory

| Data | Source | Stored in | Protection | Retention | Leaves the phone? |
|---|---|---|---|---|---|
| Bank and UPI SMS text (raw) | SMS receiver (Android), Shortcut (iPhone) | `main.db` `raw_messages` | Database encryption; text field encrypted | 30 to 90 days, then purged (user setting) | No |
| Parsed transaction (amount, direction, merchant, bank, last 4, channel, reference, date, category) | Rules and on-device model | `main.db` `transactions` | Database encryption | Until user deletes | Only if marked shared, to the paired phone |
| Merchant rules and notes | User answers | `main.db` | Database encryption | Until user deletes | No |
| Budgets and alert log | User | `main.db` | Database encryption | Until user deletes | No |
| Card summary (bank, network, type, last 4, expiry) | NFC (Android), camera or manual (iPhone) | `main.db` `cards` | Database encryption | Until card is removed | No |
| Full card number, optional card PIN | User or NFC | `vault.db` `card_secrets` | Separate key behind PIN or biometrics, plus field encryption (AES-256-GCM) | Until card is removed | No |
| CVV | | Never stored | | | |
| Hidden transactions | User | `vault.db` | Separate key behind PIN or biometrics | Until user deletes | Never (not exported, not shared) |
| Vault opening log | App | `vault.db` `vault_audit` | Vault key | Until user clears | No |
| Self-transfer reviews | App and user | `main.db` | Database encryption | Until user deletes | No |
| Household peer key, shared transactions received | Pairing and sync | `main.db` | Database encryption; sync is end-to-end encrypted | Until unpaired | Only to and from the paired phone |
| Camera frames for card scan (iPhone) | Camera | Memory only | On-device text recognition | Not kept | No |
| App PIN (hash), biometric settings | User | Keystore or Keychain | Hardware-backed | Until reset | No |
| Encryption keys | App | Android Keystore, iOS Keychain and Secure Enclave | Hardware-backed | Life of the install | No |
| Backup file | User action | A file the user chooses | Passphrase encryption | User controls | Only where the user sends it |

## Permissions
| Permission | Platform | Why | Phase |
|---|---|---|---|
| RECEIVE_SMS, READ_SMS | Android | Read new bank SMS (core feature) | 1 |
| POST_NOTIFICATIONS | Both | Budget, due date and "What was this?" alerts | 1 |
| USE_BIOMETRIC | Both | App and vault unlock | 1 |
| NFC | Android | Read card number and expiry | 2 |
| Camera | iPhone | Scan card | 2 |
| INTERNET, multicast, local network | Android, iPhone | Household sync only | 4 |

## Excluded
- Phone cloud backups are switched off for the app databases.
- No third-party SDK may send data off the phone. The Phase 5 SDK audit checks this.
- Old SMS are never imported.

## To confirm before release
- Whether the on-device model files or `llamadart` write any logs or caches that contain message text.
- Retention default for raw messages (30 or 90 days).
- Erase-everything flow (Phase 1).
