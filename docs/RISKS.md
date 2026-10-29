# Risk register

Expands CLAUDE.md section 9 with triggers and fallbacks, and adds risks found in the review. Review at the end of every phase.

| # | Risk | Likelihood | Impact | Trigger | Fallback | Retire in |
|---|---|---|---|---|---|---|
| R1 | Google Play rejects the SMS permission | Medium | High | Rejection or request for changes | Clearer core-feature justification and demo video; else direct APK for household, or a manual-entry build with share-to-app | 5 |
| R2 | iPhone Shortcut does not run reliably in the background | Medium | High | Phase 0 spike fails or is flaky | Share-to-app and manual entry as the iPhone path | 0 |
| R3 | Model too large or app too big | Medium | Medium | Bundle size check above the store or user limits | Smaller quantisation or model, install-time pack tuning | 0, 5 |
| R4 | LLM misreads amount or merchant | Medium | High | Golden corpus below threshold | Amount safety check, "please confirm", learning from corrections, rules for amount and bank | 1A |
| R5 | Slow AI on mid-range phones | Medium | Medium | Over 3 s per SMS | Queue, newest first, process on charge, smaller model | 0, 5 |
| R6 | iPhone "Shortcut ran" banner annoys users | High | Low | Feedback | Explain in onboarding | 1A |
| R7 | Bank SMS formats change | Medium | Medium | Failure rate rises in diagnostics | Grow the corpus, update prompt, LLM tolerates format change | ongoing |
| R8 | Stored card PIN is misused | Low | High | n/a | Opt-in only, biometric-locked, clear warning | 2 |
| R9 | Hidden transaction leaks | Low | High | Any test failure | Block release; separate database by construction | 2 |
| R10 | Model licence blocks store distribution (T3) | Low | High | Licence review | Choose another model | 0 |
| R11 | RCS bank alerts never reach the app (T2) | Medium | Medium | Phase 0 per-bank check | Share-to-app | 0 |
| R12 | NFC reads few cards (T7) | High | Low | Phase 0 matrix | Manual and camera entry first | 0 |
| R13 | Wi-Fi sync blocked by router (T1) | Medium | Medium | Isolated-Wi-Fi spike | IP entry, then file export | 0, 4 |
| R14 | Privacy form or law mismatch (T4) | Low | High | Store review or legal review | Fix declarations, remove the feature that conflicts | 5 |
| R15 | Solo schedule slips | High | Medium | A phase overruns by more than a week | Use the 4-week buffer, cut Future items, defer household polish | each phase |
| R16 | Forgotten PIN locks the user out (G2) | Medium | Medium | Support request | Biometric fallback, wipe and restore from backup | 1B |
| R17 | Backup cannot restore on a new phone (G4) | Medium | High | Restore test fails | Passphrase-derived backup key | 1B |
| R18 | Real SMS leak into git | Low | High | Commit hook flags personal data | `.gitignore` for raw data, anonymise before commit, review | 0 |
