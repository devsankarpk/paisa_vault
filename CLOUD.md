Paisa Vault — Product & Technical Plan
Working name. Version 1.0 — 16 October 2026 Status: Requirements agreed. Screen designs pending (sample designs to be shared later).

1. Overview
   Paisa Vault is a private, offline-first expense manager for Android and iPhone, built in Flutter with an encrypted SQLite database.

It reads new bank and UPI SMS and uses an on-device AI model (no cloud) to work out the bank, card, amount, merchant and category of each transaction. It learns from the user's answers, keeps a secure card vault, supports hidden (private) transactions, gives budget alerts, and lets a household (husband and wife) share transactions phone-to-phone over Wi-Fi.

Core principles

Private by design: all data and AI stay on the phone. No server and no cloud account.
Secure: the database is encrypted, sensitive data needs PIN or fingerprint/Face ID, and the CVV is never stored.
Simple UI: white background, grey borders and separators, minimal animation.
Scope: India-first (INR, Indian banks), with the database ready for multi-currency later. 2. Decisions Agreed

# Topic Decision

1 Platforms Android and iPhone, one Flutter codebase
2 Database SQLite, encrypted (SQLCipher-compatible), using the drift package
3 SMS on Android The app reads new SMS directly. We will apply for Google Play's SMS permission exception (money management).
4 SMS on iPhone An iOS Shortcuts "Message" automation sends each new bank SMS to the app
5 Old SMS Not supported. Only new SMS received after install are processed.
6 AI model One bundled on-device LLM running through Flutter on both platforms. No dependency on Apple Foundation Models or Google Gemini Nano.
7 Model delivery Shipped inside the app at install time: Play Asset Delivery install-time pack on Android, bundled on iPhone. No separate download step.
8 Bank detection The LLM identifies the bank, card type (debit/credit), last 4 digits, amount, merchant and channel. A simple safety check confirms the amount actually appears in the SMS.
9 Card capture Android: NFC reads the card number and expiry. iPhone: camera scan or manual entry, because Apple does not allow NFC to read payment cards. Other details are always entered manually.
10 Card security The list shows only the last 4 digits, card type and bank. Full details need PIN, fingerprint or Face ID. CVV is never stored. Storing the card PIN is optional and comes with a warning.
11 Hidden transactions Kept in a separate encrypted vault. Visible only to the owner after PIN, fingerprint or Face ID. Never exported or shared.
12 Household sharing QR code pairing plus phone-to-phone transfer over the same Wi-Fi, end-to-end encrypted.
13 Self transfers The app asks the user to confirm likely self transfers whenever a report is generated, and at every month-end.
14 Credit card bills When a credit card is added, the app asks for bill reminder details.
15 Currency INR now. The database stores a currency code from day one for future multi-currency support. 3. Features
3.1 SMS Reading
Android

The app listens for new SMS (RECEIVE_SMS / READ_SMS permissions).
Before asking for permission, an in-app screen explains that SMS are processed only on the phone and never uploaded. Google requires this.
OTP and promotional messages are ignored. Only messages with an amount and a debit/credit word are processed.
iPhone

During onboarding, the app guides the user to create a Shortcuts automation:
Go to Automation → Message → "Message contains" with a keyword: debited, credited, spent, Rs or INR, one keyword per automation.
Choose Run Immediately.
Add the action "Log Bank Message" (Paisa Vault) with the message as input.
The app receives the SMS text in the background and saves it.
iOS may show a small "Shortcut ran" banner. The user should be told about this during setup.
Both platforms: only new messages are handled. There is no import of older SMS.

3.2 On-Device AI (LLM)
Model: Gemma 3 1B (int4, about 530 MB) via flutter_gemma (LiteRT-LM engine), the same model on both platforms.
Alternative to test in Phase 0: Qwen3 1.7B via llamadart.
Final choice is based on accuracy with our real SMS samples.
What the LLM extracts:
Bank
Card or account type (debit card / credit card / savings account / UPI)
Last 4 digits
Amount
Debit or credit
Merchant
Channel (UPI / NEFT / IMPS / ATM / POS / online)
Reference number
Date
Suggested category
Output format: strict JSON, checked against a schema.
Safety check: the amount returned must appear in the SMS text. If it doesn't, the transaction is marked "please confirm".
Speed: about 2 seconds per SMS on a modern phone once the model is loaded.
Background handling:
Android: the SMS is saved immediately and the AI processing runs in a short background job.
iPhone: the SMS is saved by the Shortcut and the AI processing runs when the app is next opened.
The user always sees the result within seconds of opening the app.
3.3 Categorisation and Learning
When a transaction arrives, the app picks a category in this order:

Known merchant rule. For example, "SWIGGY → Food". This is checked using the UPI ID first, then the merchant name.

Similar past transaction. Fuzzy name matching against the database, e.g. "SWIGGY INSTAMART" matches "SWIGGY".

LLM suggestion, limited to the user's category list.

Ask the user. This applies to a first-time merchant that can't be categorised. A notification appears:

"₹480 paid to RAJU STORES. What was this?"

The user then:

Taps a category.
Can add a purpose note (optional).
Can choose "Always use this category for RAJU STORES" to save a rule.
Can choose "Hide this transaction" to move it to the private vault.
Every answer is saved, so the same merchant is categorised automatically next time.

3.4 Search
By date range
By category
By exact amount within a date range (e.g. ₹499 between 1–15 Oct)
Free text search on merchant and notes
Filters can be combined.
3.5 Card Vault
Adding a card:
Android: tap the card on the phone (NFC) to read the card number and expiry.
iPhone: scan with the camera or type the details.
Bank, card type, network and holder name are entered or confirmed manually.
List view: last 4 digits, card type (debit/credit) and bank only.
Details view: full card number (and the PIN, if saved) after PIN, fingerprint or Face ID. Details are shown for about 30–60 seconds, then hidden again.
CVV is never stored.
Card PIN storage: optional and off by default. Before enabling it, the user sees a warning that most banks make the cardholder liable if a stored PIN is misused.
Screen protection: screenshots are blocked on card screens, and the screen is blurred in the app switcher.
Credit card bill reminders are set up when adding a credit card:
Statement date
Payment due date
Credit limit (optional)
Reminder days before the due date (e.g. 5 days and 1 day)
Automatic mapping: each SMS transaction is linked to the right card or account using the bank and the last 4 digits.
3.6 Hidden (Private) Transactions
Any transaction can be marked Hidden, for example a business expense.
Hidden transactions move to a separate encrypted vault database with its own key.
What others see when the app is opened:
Hidden transactions don't appear in any list, total, chart, budget or search.
Totals still add up correctly, with no gaps.
The vault entry point is not obvious.
Owner access: the owner opens the vault with PIN, fingerprint or Face ID. Inside, an optional "true budget" view includes hidden spending.
Exports and sharing: hidden transactions are never exported or shared with the household.
Repeated SMS: if the same SMS arrives again, it stays hidden.
3.7 Self Transfers
A self transfer is money moved between the user's own accounts, or a credit card bill payment. These are not spending.

Detection: the app flags possible self transfers, for example the same amount debited from one own account and credited to another within a short time, or a payment to one's own credit card.
When the app asks:
Every time a report is generated, before totals are shown: "These look like transfers between your own accounts. Confirm?"
At every month-end, as a notification: "You have 3 possible self transfers this month. Please review."
Result: confirmed self transfers are excluded from spending totals and budgets.
3.8 Alerts
Uncategorised transaction: an alert is sent when a transaction can't be categorised. If several are pending, they are grouped into a daily evening reminder.
Budget alerts: sent when spending crosses 70%, 80% and 90% (and 100%) of a budget. Each threshold is alerted only once per period.
Credit card due date reminders.
Month-end self transfer review.
All alerts are local notifications. No server is involved.
3.9 Household Sharing (Husband & Wife)
One-time pairing:
Phone A shows a QR code. Phone B scans it.
Both phones show a 6-digit code to confirm they match.
Each phone saves the other's security key.
Sync:
Both phones must be on the same Wi-Fi.
The transfer is end-to-end encrypted and only sends changes since the last sync.
What is shared: only transactions marked as shared. Hidden transactions are never shared.
Duplicates: for a joint account, both phones may get the same SMS. Duplicates are detected by bank, last 4 digits, amount and reference number, and shown once.
Home budget view: combined spending of both users for household categories. Personal budgets stay private.
Fallback: an encrypted export file with a passphrase, shared via WhatsApp, AirDrop or Quick Share, and imported on the other phone.
3.10 Reports
Monthly and custom date range reports
Category breakdown, top merchants, card-wise spending
Self transfer confirmation before the report is generated
Export to an encrypted file, plus PDF/CSV for the user's own records
3.11 UI Guidelines
White background with grey borders and separators
Minimal animation: simple fades only
Clean, readable typography
Screens to be finalised once sample designs are shared 4. Architecture
┌──────────────────────────────────────────────────────────────┐
│ 1. INPUT │
│ Android SMS receiver │ iOS Shortcut (App Intent) │ │
│ Manual entry │ NFC card (Android) │ Camera OCR (iPhone) │
├──────────────────────────────────────────────────────────────┤
│ 2. PROCESSING (shared Dart code) │
│ OTP/promo filter → LLM extraction → amount safety check │
│ → duplicate check → categoriser (rule → similar → LLM → │
│ ask user) │
├──────────────────────────────────────────────────────────────┤
│ 3. SERVICES │
│ Transactions │ Cards & banks │ Budgets │ Alerts │ │
│ Hidden vault │ Self transfers │ Reports │ Household sync │
├──────────────────────────────────────────────────────────────┤
│ 4. STORAGE │
│ main.db (encrypted) │ vault.db (separately encrypted) │
│ Keys in Android Keystore / iOS Keychain + Secure Enclave │
├──────────────────────────────────────────────────────────────┤
│ 5. UI — Flutter, white + grey, PIN/biometric lock │
└──────────────────────────────────────────────────────────────┘ 5. Recommended Flutter Packages
Purpose Package
Database drift + drift_flutter + sqlite3 3.x with sqlite3mc/SQLCipher (not the deprecated sqlcipher_flutter_libs)
Local LLM flutter_gemma (LiteRT-LM). Alternative: llamadart
Android SMS Own small Kotlin plugin (preferred) or another_telephony
iOS Shortcuts Swift AppIntent in the Runner target, or flutter_app_intents
Biometrics local_auth
Secure keys flutter_secure_storage plus native Keystore/Keychain code for biometric-locked keys
NFC (Android) flutter_nfc_kit or emv_nfc_reader
Camera OCR (iPhone card scan) google_mlkit_text_recognition
Notifications flutter_local_notifications
Background jobs (Android) workmanager
QR codes mobile_scanner + qr_flutter
Local network dart:io HttpServer/WebSocket + mDNS (bonsoir/nsd)
Encryption cryptography / cryptography_flutter
All AI, NFC and SMS packages sit behind app-level interfaces, so they can be replaced without rewriting the app.

6. Database Design
   main.db — encrypted

Table Purpose
banks Bank list, SMS sender IDs
accounts Savings, current, credit card and wallet accounts, with last 4 digits
cards Card summary only: bank, network, debit/credit, last 4 digits, expiry, link to the vault secret
card_bill_settings Statement date, due date, limit, reminder days (credit cards)
categories Category tree (expense / income / transfer)
merchants Canonical merchant name, UPI ID, default category
merchant_rules Learned and user rules (merchant → category, purpose note)
transactions Amount (in paise) + currency, debit/credit, channel, merchant, card/account, category, status, fingerprint, shared flag, self-transfer flag
raw_messages Encrypted SMS text, kept 30–90 days for re-processing, then purged
budgets Category, period, amount, alert thresholds (70/80/90/100)
budget_alert_log Which thresholds already fired in each period
self_transfer_reviews Suggested pairs and the user's yes/no answers
household_peers Paired phone, public key, last sync time
household_transactions Shared transactions received from the partner
sync_log Sync history
settings App settings
vault.db — separately encrypted, opened only after PIN, fingerprint or Face ID

Table Purpose
hidden_transactions Private transactions
hidden_fingerprints Prevents hidden transactions reappearing
card_secrets Encrypted full card number and optional PIN (no CVV field)
vault_audit Log of vault openings
Indexes:

Date
Category + date
Amount + date, for fast "amount within dates" search
Full-text search on merchant and notes 7. Security Summary
Main database: encrypted with a key held in Android Keystore or iOS Keychain. It can open in the background so new SMS can be saved.
Vault database: encrypted with a separate key that needs PIN, fingerprint or Face ID every time.
Card number and PIN: additionally encrypted field by field (AES-256-GCM).
App lock: PIN or biometrics on open and after inactivity.
Screen protection: screenshots blocked on sensitive screens, and the screen blurred in the app switcher.
Backups: phone cloud backups are excluded. The app offers its own encrypted backup file with a user passphrase.
Network: no internet needed at all. The AI model is bundled, so the app can run without network permission except for the local Wi-Fi household sync.
Compliance:
Card storage follows the spirit of RBI tokenisation rules: only the last 4 digits and the bank are shown by default.
CVV is never stored.
PIN storage is opt-in with a warning. 8. Phase Plan
Phase 0 — Groundwork (2 weeks)
Collect sample SMS from our banks and remove personal details.
Test Gemma 3 1B vs Qwen3 1.7B on these samples for accuracy and speed on our own phones.
Build working prototypes:
iOS Shortcut → App Intent
Android SMS receiver
Android NFC card read
iPhone camera card scan
Check model bundling: Play Asset Delivery pack size and iOS app size.
Output: final model choice and a confirmed technical approach.
Phase 1 — Core App / MVP (7–8 weeks)
Project setup, encrypted database, app lock (PIN + biometrics)
SMS input:
Android SMS receiver with permission disclosure screen
iPhone Shortcut onboarding guide
OTP and promotional SMS filtering
Processing:
On-device LLM with bundled model, amount safety check, duplicate check
Automatic bank, card and account mapping using the last 4 digits
Categories:
Categories and manual transaction entry
Merchant rules, similar-transaction matching
First-time "What was this?" question flow
Search, budgets and alerts:
Search by date, category, and amount within dates
Monthly budgets with 70/80/90/100% alerts, plus uncategorised alerts
Backup: encrypted backup and restore
Output: a usable personal expense tracker on both phones.
Phase 2 — Cards & Privacy (4 weeks)
Card vault:
Last 4 digits list, biometric reveal, auto-hide timer
Android NFC card add, iPhone camera scan and manual entry
Credit cards: bill reminder setup and due date notifications
Card PIN: optional PIN storage with warning
Hidden transactions: separate vault database, private owner view, "true budget" view
Output: secure card storage and private transactions.
Phase 3 — Reports & Self Transfers (3 weeks)
Monthly and custom reports, category, merchant and card breakdowns
Self transfers:
Detection
Confirmation step before every report
Month-end review notification
PDF/CSV export for personal records
Output: accurate reports without double-counting own transfers.
Phase 4 — Household Sharing (4 weeks)
QR code pairing with 6-digit confirmation
Encrypted Wi-Fi sync of shared transactions
Duplicate handling for joint accounts, conflict handling
Combined home budget view
Encrypted file export/import as a fallback
Output: husband and wife can share a household budget.
Phase 5 — Release & Polish (2–3 weeks, then ongoing)
Apply the final screen designs (once shared).
Google Play submission with the SMS permission declaration form and demo video; App Store submission.
Testing on mid-range Android phones, accessibility, performance and battery tuning.
Future:
Multi-currency
Subscription and EMI detection
Refund linking
Home screen widgets
Hindi and regional language UI
Estimated total: about 22–24 weeks for one experienced Flutter developer, or less with two developers working in parallel from Phase 2.

9. Risks & Mitigations
   Risk Mitigation
   Google Play rejects the SMS permission Make SMS the clearly stated core feature, show the disclosure screen, and submit a demo video. Fallback: manual entry build, or install directly (APK) for household use.
   App size grows by about 500 MB because of the bundled model Use a Play Asset Delivery install-time pack. Choose the smallest model that passes the accuracy tests.
   The LLM misreads an amount or merchant Amount safety check, "please confirm" status, and learning from user corrections
   Slower AI on mid-range phones Process SMS in a queue and test on a mid-range device in Phase 0
   iPhone "Shortcut ran" banner Explain it during onboarding
   Bank SMS formats change The LLM handles format changes better than fixed rules. Monitor accuracy.
   Storing card PINs Opt-in only, biometric-locked, with a clear warning
10. Open Items
    Screen designs: sample designs to be shared
    Final model choice after Phase 0 testing
    App name and branding
    List of banks to support first (for collecting test SMS)
    Default category list
    Budget period: calendar month or salary-date cycle?
