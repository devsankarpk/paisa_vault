# iOS Shortcut to App Intent spike (Phase 0)

Run 13 Nov 2026 on an iPhone 15, iOS 26.7.1. Code: `spikes/llm_bench/ios/Runner/LogBankMessageIntent.swift`, inbox view in `spikes/llm_bench/lib/main.dart`.

## What was built

An App Intent "Log Bank Message" with one text parameter. It appends the message and a timestamp to `Documents/shortcut_inbox.jsonl` inside the app sandbox. The text is not written to the system log. Shortcuts automation: Message contains a keyword, Run Immediately, action Log Bank Message with Shortcut Input.

## Results

| Check | Result |
|---|---|
| Action appears in Shortcuts and runs | Yes |
| Message reaches the app | Yes, within a few seconds |
| "Shortcut ran" banner | Yes, appears each time |
| Message with a keyword the automation lacks (for example "Sent", UPI wording) | Not triggered |
| Same message matching two automations (`Sent` and `Rs.`) | Saved twice |
| App swiped away, phone unlocked (14 Nov 2026) | Works: banner appeared and the message was saved to the inbox; one SMS again saved twice when two keywords matched |
| App swiped away, phone locked for a while, then unlocked just before the transfer (14 Nov 2026) | Works: Shortcut fired and saved the message while the app was closed; two identical records again |
| Not yet confirmed | Phone locked the whole time the SMS arrives (screen off); iMessage and RCS messages; whether `Rs.` also matches non-bank chats; behaviour after a phone restart before first unlock |

## What this means for the design

1. **Several keywords are needed.** One automation per keyword, as the spec says. A message with `debited` alone misses "Sent ... From A/c" style alerts. Suggested set to test further: `debited`, `credited`, `spent`, `Sent`, `Rs.`, `INR`.
2. **The app must drop duplicates.** A message that contains several keywords arrives once per matching automation. Deduplicate on a fingerprint (bank, last 4, amount, reference, date), or a hash of the text, within the saving step. This is the same check planned for joint accounts.
3. **Expect non-bank messages.** Broad keywords let other messages through, so the OTP and promo filter must run on everything the shortcut sends.
4. **Tell users about the banner** during onboarding (already planned).
5. **Onboarding is manual and long.** Each keyword is a separate automation the user must build by hand. The setup guide needs screenshots, and a check step ("send a test SMS") so the user knows it works.

## Still to test

- App closed and phone locked, with the screen off for some minutes.
- iMessage and RCS messages containing a keyword.
- Whether a Sender filter can restrict automations to bank senders and cut noise.
- Reliability over a day of real messages (missed or delayed runs).
