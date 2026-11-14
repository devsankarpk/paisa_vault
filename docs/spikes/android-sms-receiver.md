# Android SMS receiver spike (Phase 0)

Run 13 Nov 2026 on the vivo V2303 (Android 15), debug build of `mobile/`. Code: `mobile/android/app/src/main/kotlin/com/paisavault/paisa_vault/SmsReceiver.kt`.

## Result

A normal SMS from a mobile number reached the receiver while the app was installed and the SMS permission was granted. Logged (no message text): sender `+91…`, subscription id 1, 1 part, 144 characters.

| Check | Result |
|---|---|
| Plain SMS received on the real phone | Yes |
| Sender, SIM subscription id and length readable | Yes (`sub=1`) |
| Message text never logged | Yes, by design |
| Dual SIM (two different subscription ids) | Not tested: the vivo has one SIM only |
| RCS chat messages | Not tested |
| Delivery with the app swiped away or after reboot | Not tested |
| Real bank alert with a letter sender | Yes: `JX-INDBNK-S` and `BV-INDBNK-S` (two headers for what looks like one alert), SIM 1, 142 characters. Added `INDBNK` to the sender table (Indian Bank, to confirm). |
| Delivery with the app swiped away (vivo, default settings) | Delayed: the system received the SMS at 16:30 and 16:32, the receiver logged them at 16:34:06 (2 to 4 minutes late), probably because vivo froze the app and delivered the broadcasts when it woke. Retest after Autostart and battery settings are changed. |
| Retest 14 Nov 2026 (vivo, app swiped away, battery set to unrestricted; no Autostart page on this Android 15 build) | Fixed: Google Messages processed the bank SMS at 14:57:25.4, the receiver logged it at 14:57:25.98 (about 0.6 s). Sender `JD-INDBNK-S`, SIM 1, 142 characters, no text logged. `INDBNK` confirmed as the user's bank (Indian Bank). |

## Still to test

- Done 14 Nov: unrestricted battery fixed the delay on the vivo (one run). Onboarding must still guide vivo, Xiaomi and similar users to this setting. If delivery is late on other phones, onboarding for vivo, Xiaomi and similar phones must guide users through these settings, and the notification flow must not assume instant delivery.
- App swiped away, phone locked, and after a restart.
- RCS: send from a contact with chat features on; the receiver may not see these at all. Record the result and decide whether onboarding tells users to turn RCS off for bank senders (banks send plain SMS, so this may be a non-issue).
- Dual SIM on a second device or a borrowed phone, if one is available.
