# Store forms checklist (draft, 14 Nov 2026)

Created in Phase 0, finished in Phase 5. Tick items when done.

## Google Play
- [ ] Developer account open and verified
- [ ] Prominent disclosure screen before the SMS permission prompt (onboarding)
- [ ] Permissions Declaration for SMS (text below)
- [ ] Demo video, 1 to 2 minutes, showing: disclosure screen, permission prompt, a bank SMS arriving, the transaction appearing, no upload
- [ ] Data Safety form: data processed on device only, not collected; household sync device to device and end-to-end encrypted (declare accurately in Phase 4)
- [ ] Privacy policy URL (hosted page)
- [ ] Install-time asset pack uploaded, size checked
- [ ] Fallback if SMS is refused: manual-entry build, or APK for household use

### SMS declaration: draft text
**Permission:** RECEIVE_SMS and READ_SMS.
**Core feature:** Paisa Vault is a personal expense manager. Its main purpose is to record money spent and received, automatically, from the user's bank and UPI transaction SMS.
**Why SMS is needed:** Banks send each transaction as an SMS. The app reads each new bank SMS to find the amount, bank, card or account, merchant and category. Manual entry does not give the same result, because users would have to type every transaction.
**Exception claimed:** Financial or money-management app that needs to read SMS to provide its core function.
**Handling:** Messages are processed only on the phone by an on-device model. They are not uploaded, shared or sold. OTP and promotional messages are ignored. Older messages are not read. Raw text is deleted after [30 or 90] days.
**Disclosure:** A screen before the permission prompt explains this and the user can decline and enter transactions by hand.
**Not used for:** advertising, profiling, or any purpose other than expense tracking.

## Apple
- [ ] Developer account open
- [ ] App Privacy label: data not collected (only if true for every feature, check again in Phase 4)
- [ ] Privacy policy URL
- [ ] Review notes: explain the Shortcuts automation route ("Log Bank Message" App Intent), that the user creates it, that no SMS leaves the phone, and give test steps
- [ ] Camera usage text for card scan; Face ID usage text
- [ ] Local network usage text and Bonjour service (Phase 4)
- [ ] App size and download warning checked with the bundled model

## Both
- [ ] SDK audit: no third-party SDK sends data off the phone
- [ ] Open source licences screen (Qwen3 Apache 2.0, plus any Gemma notice if used)
- [ ] Legal review of the policy
- [ ] Bundle and package id confirmed before accounts are created (cannot change after publishing)
