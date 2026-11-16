# Camera card scan spike (Phase 0)

Run 16 Nov 2026 on the iPhone 15 and the vivo V2303 (Android 15). Code: `spikes/camera_scan/`. On-device text recognition (`google_mlkit_text_recognition`), one photo per card, front of the card only. The app shows only the last 4 digits and the expiry, deletes the photo straight after reading, and logs only layout shapes (digits as `d`, letters as `a`), never real numbers or names.

## Result

Camera scan reads the number on both phones for the cards tried, after the parser was fixed for the layouts below. It works on the vivo, which has no NFC, so it is the main add-card shortcut on phones like it.

| Phone | Scans | Number found | Checksum passed | Expiry found |
|---|---|---|---|---|
| iPhone 15 (final build, 4 scans) | 4 | 4 | 3 | 2 |
| vivo V2303 | about 10 | found on every layout listed below once fixed; checksum and expiry flags were not logged on the vivo | | |

The owner reported that both phones read the cards correctly in the final round. The vivo log did not record the checksum, so the vivo column is less exact than the iPhone one.

## What went wrong on the way (and was fixed)

| Problem | Cause | Fix |
|---|---|---|
| iPhone app closed after taking the photo | The newest ML Kit plugin (1.0.x, Swift Package Manager) did not bundle the model: "Invalid model path" | Pin `google_mlkit_text_recognition` 0.15.x and `google_mlkit_commons` 0.11.x, which use CocoaPods. Installed CocoaPods as a Ruby gem (Homebrew had to compile `cmake` and was too slow) |
| vivo NullPointerException after the photo | R8 shrinking removed plugin classes in the release build | Turn off `isMinifyEnabled` for the spike |
| Number on two or four lines not read | The code looked inside one line only | Join neighbouring digit-only lines, sorted top to bottom |
| Four blocks, each with a stray `\|` | The reader added a bar from the card edge | Treat `\|` as a separator |
| Dot or dash between blocks | The reader sometimes returns `.` for a space | Accept `.`, `,`, `-` between digit groups |
| A digit missing (15 digits returned) | Reader error | Cannot be repaired; the checksum fails and the app must ask to rescan |

## Layouts seen

- Two rows of 8 digits (flat print)
- One line `12 + 4` digits
- Dash or dot between blocks
- Four blocks on four lines, each with a stray bar
- Expiry on its own line (`MM/YY`), or attached to a word on the same line

## Decisions for Phase 2

1. Add card: **lead with manual entry and camera scan**. NFC is an optional extra (see `docs/DECISIONS.md`).
2. Use **live scanning** that tries several frames and accepts the first reading that passes the Luhn checksum and has a plausible expiry, instead of one photo. A reading that fails the checksum shows "please rescan or type it".
3. Never save the photo, never log the number or name, delete any temporary file straight away. Do not scan the back (CVV).
4. Keep the parser in `spikes/camera_scan/lib/card_parse.dart` (12 tests) as the starting point behind the `CardReader` interface.
5. Pin the ML Kit plugin versions exactly. Re-test before upgrading to the 1.x line, which needs Swift Package Manager and currently crashes on iOS.

## Not tested

- Embossed or metallic cards, glare, dim light, and the phone held in the hand.
- Cards of every network and bank (the matrix has only the few cards the owner scanned).
- Live camera scanning (this spike takes photos).
