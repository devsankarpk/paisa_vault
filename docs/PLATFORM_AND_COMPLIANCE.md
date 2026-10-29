# Platform and compliance topics (T1 to T7)

These seven topics are not covered by [CLAUDE.md](../CLAUDE.md) but can change scope or block release. Each has what is known, what must be verified, the plan, and a fallback. The facts are the current understanding and must be verified in the phase named, because platform rules change. Nothing here is legal advice.

| Topic | Verify in | Built in | Phase file |
|---|---|---|---|
| T1 Household Wi-Fi permissions | Phase 0 | Phase 4 | [Phase 4](phases/phase-4-household-sharing.md) |
| T2 Dual SIM, RCS, sender IDs | Phase 0 | Phase 1A | [Phase 1A](phases/phase-1a-foundation-sms-ai.md) |
| T3 Model licence | Phase 0 | Phase 5 (screen if needed) | [Phase 0](phases/phase-0-groundwork.md) |
| T4 Privacy forms and law | Phase 0 | Phases 1A and 5 | [Phase 5](phases/phase-5-release.md) |
| T5 Diagnostics | Phase 1A | Phases 1A and 1B | [Phase 1B](phases/phase-1b-categorise-search-budgets.md) |
| T6 Model updates | Phase 1A | Phases 1A, 1B, 5 | [Phase 1A](phases/phase-1a-foundation-sms-ai.md) |
| T7 NFC card reading | Phase 0 | Phase 2 | [Phase 2](phases/phase-2-cards-privacy.md) |

---

## T1. Household Wi-Fi sync permissions

**Idea:** two phones on the same Wi-Fi find each other by mDNS and talk over a local socket.

**Known**
- iPhone: needs `NSLocalNetworkUsageDescription` and `NSBonjourServices` (for example `_paisavault._tcp`) in Info.plist. The system shows a local-network prompt on first use.
- Android: local sockets need the INTERNET permission even on a LAN. mDNS needs a multicast lock (`CHANGE_WIFI_MULTICAST_STATE`). Android 13 and later may need `NEARBY_WIFI_DEVICES`, depending on the discovery API.

**Conflict with the spec:** CLAUDE.md section 7 says the app needs no network permission except local Wi-Fi sync. In practice that means the Android build has INTERNET from Phase 4 onward.

**Plan**
- Gates: builds for Phases 1A to 3 ship without INTERNET (checked in CI). Phase 4 adds it, and a network test proves traffic goes only to the paired peer's LAN address.
- Phase 0 spike: two phones, discovery, one encrypted message each way, on a normal and on an isolated Wi-Fi.
- Phase 4: the pairing screen explains the prompts before they appear.

**Verify:** exact permissions on the Android versions you target, the discovery package's behaviour on iOS.

**Fallback:** show the peer's IP under the QR to type in, then encrypted file export. Routers with client isolation block sync; document it.

---

## T2. Dual SIM, RCS and sender-ID variants

**Idea:** bank SMS come from header IDs such as `VM-HDFCBK` or `AX-SBIINB`: a two-letter operator and region prefix, a bank code, and sometimes a `-S`, `-T`, `-P` or `-G` suffix.

**Plan**
- Normalise the header (strip prefix and suffix, uppercase) and match it against `banks.sender_ids` for HDFC, SBI, ICICI, Axis and Yes.
- An unknown sender with a transaction-like body is shown as "unrecognised sender, confirm", not dropped.
- Dual SIM: store the SIM subscription id with each raw message so a card can be tied to its SIM.
- RCS: business RCS messages may not reach the app as classic SMS. Phase 0 checks, per bank, whether alerts arrive as plain SMS, on both RCS settings on Android, and how the iPhone Shortcut behaves with RCS and iMessage threads.

**Deliverable:** `testdata/sender_ids.json` and a per-bank table of sender IDs, SMS or RCS, formats and SIM.

**Fallback (proposed, small):** "Share to Paisa Vault" from any message text so a missed SMS can still be added. Decide in Phase 0 whether it is in version 1.

---

## T3. Model licence

**Idea:** Gemma models are released under Google's Gemma Terms of Use rather than a standard open-source licence. Redistributing one inside an app generally means carrying the terms and a notice and passing the use restrictions on to users. Qwen3 models are Apache 2.0 (verify for the exact size).

**Plan**
- A licence column in the Phase 0 scorecard: licence, redistribution in a store app allowed, obligations, attribution text.
- Read the current terms of the chosen model and record them in ADR 0001.
- If there are obligations, Phase 5 adds an in-app "Licences and terms" screen and a line in the app's terms.

**Rule:** the licence is pass or fail, alongside accuracy. A model that cannot be redistributed in a store app does not win, however accurate.

---

## T4. Privacy forms and law

**Google Play**
- Permissions Declaration for SMS with the core-feature justification and a demo video.
- Prominent disclosure before the permission prompt (already designed as the onboarding screen).
- Data Safety form. Data processed only on the device and not sent off it is generally declared as not collected. Household sync is device to device and end-to-end encrypted, to be declared accurately.
- A privacy policy URL.

**Apple**
- App Privacy label ("data not collected" only if true for every feature), privacy policy URL, and review notes explaining the Shortcut route and that no SMS leaves the phone.

**India: Digital Personal Data Protection Act 2023**
- Treat as a design checklist even though processing is on-device: clear notice and consent, purpose limitation, retention limits (raw messages 30 to 90 days), a way to erase everything, no third-party SDKs that send data.
- Ask a qualified person to review before release.

**Plan**
- Phase 0: data inventory (what is stored, where, how encrypted, retention, shared with whom) and a draft privacy policy.
- Phase 1A: consent screens and "Erase everything".
- Phase 5: finish and host the policy (a static page, outside the app), complete both store forms, run the SDK audit.

**Deliverables:** `docs/privacy/data-inventory.md`, `docs/privacy/privacy-policy-draft.md`, a store-forms checklist (created in Phase 0).

---

## T5. Diagnostics without a network

**Idea:** nothing is sent anywhere, so failures in the field are visible only if the user shares a file.

**Plan**
1. A local pipeline log. For each SMS: a status (received, filtered, parsed, safety check failed, deduped, mapped, categorised), timings and model version. No SMS text, amounts or merchants in the default log.
2. A diagnostics screen: parse success rate, please-confirm rate, average seconds per SMS, last errors.
3. Export via the system share sheet, redacted by default. A separate opt-in toggle can include SMS samples, each shown for review with account numbers masked.
4. Local crash capture (Flutter error handlers and platform exit reasons) included in the export.
5. During dogfood and beta the user shares diagnostics by hand.

**Rule:** no analytics or crash SDK that sends data.

**Test:** the default export contains no run of six or more digits and no rupee amounts.

---

## T6. Model updates

**Idea:** the model ships inside the app, so a new model means a new app version. No runtime downloads, which keeps the no-network promise.

**Plan**
- `LlmEngine` interface and a model manifest (id, version, licence, prompt version, schema version).
- Each transaction stores the model and prompt version that produced it.
- After an update with a newer model, offer "Re-check recent transactions" using raw messages (kept 30 to 90 days), showing differences for confirmation instead of overwriting silently.
- The golden corpus must pass before a model change ships (CI gate).
- Android: the model is a Play Asset Delivery install-time pack, updated with the app. iPhone: bundled.

**Later option, not planned:** user-initiated model download. It needs a new privacy decision, so it stays on the Future list.

---

## T7. NFC card reading

**Idea:** contactless cards may return the card number and expiry over NFC, but many issuers return a token, masked data or nothing, and RuPay cards use different application IDs than Visa and Mastercard.

**Plan**
- Phase 0: test every card you own and record a matrix: bank, network, debit or credit, contactless, number read, expiry read, time. Compute the success rate.
- Manual entry is first-class. The Add card screen leads with manual entry and camera scan (ML Kit works on Android too). "Tap card" is an optional shortcut.
- Proposed gate: if NFC reads the number on fewer than half the tested cards, ship it as "try NFC" with an honest message, or drop it from version 1. That would be a deliberate change to CLAUDE.md decision 9, recorded in [DECISIONS.md](DECISIONS.md).

**Security:** only the card's own number and expiry; CVV never read or stored; the number is encrypted field by field.

**Deliverables:** NFC test matrix, spike code behind the `CardReader` interface, reordered Add card screen.
