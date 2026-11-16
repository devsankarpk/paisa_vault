# NFC card read (Phase 0): deferred

Status: **not tested.** The vivo V2303 has no NFC, and the iPhone cannot read payment cards over NFC (Apple does not allow it). No other NFC Android phone is available yet.

## What exists
`spikes/nfc_card/` is a working spike app (Android, `flutter_nfc_kit`). It selects the card's payment application, reads the records, and reports only: network, whether a card number came back, its last 4 digits, whether the checksum passes, whether the expiry came back, and the time taken. It never shows or stores the full number and does not read the CVV. The parsing logic has three passing tests.

## To finish
Borrow an NFC Android phone, install `spikes/nfc_card/build/app/outputs/flutter-apk/app-release.apk` (rebuild with `flutter build apk --release` if the folder is missing), and read every card you own. Record each card in the table below.

| Bank | Network | Debit or credit | Contactless | Number read | Expiry read | Time |
|---|---|---|---|---|---|---|
| | | | | | | |

Gate (docs/PLATFORM_AND_COMPLIANCE.md T7): if the number is read on fewer than half the cards, ship it as "try NFC" with an honest message, or drop it from version 1.

## Decision for now
Add card leads with manual entry and camera scan. NFC is an optional "tap card" shortcut in Phase 2, subject to this matrix.
