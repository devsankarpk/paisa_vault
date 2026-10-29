# Phase 5: Release and polish

**Dates:** 29 Apr to 19 May 2027 (3 weeks), after a 4-week buffer (1 to 28 Apr). Store review runs into early June. **Back to:** [index](../PHASE_PLAN.md)

## 1. Goal and output
Both apps submitted to the stores with all required declarations, tested on mid-range devices, accessible, and privacy-reviewed. Fallback paths ready if a store says no.

## 2. Spec coverage
CLAUDE.md section 8 (Phase 5), 9 (risks), 7 (compliance), 3.11 (UI). Also the Future list.

## 3. Prerequisites
- Phase 4 exit gate passed; buffer used for open bugs.
- Developer accounts for Google Play and the Apple Developer Program (not covered by CLAUDE.md; set up in Phase 0 so approval time does not block).
- Privacy policy drafted in Phase 0 and a place to host it (static page).

## 4. Work breakdown

### Week 1: quality
| Task | Deliverable | Days |
|---|---|---|
| Visual polish against the signed-off screens: spacing, states, fades only, dark-mode decision. | Screens match | 2 |
| Accessibility: text scaling, contrast, screen reader labels, touch targets, focus order. | Checklist passed | 1.5 |
| Performance and battery on a mid-range Android: startup, SMS to transaction time, model load, background job cost. | Report and fixes | 1.5 |

### Week 2: compliance and packaging
| Task | Deliverable | Days |
|---|---|---|
| Privacy review against section 7 and the data inventory. SDK audit: no analytics, ads or crash SDK that sends data. | Signed checklist | 1 |
| Google Play: SMS permission declaration, prominent disclosure screen verified, demo video, Data Safety form, Play Asset Delivery pack, store listing. | Submission ready (T4) | 2 |
| Apple: App Privacy label, review notes explaining the Shortcut route and that no SMS leaves the phone, screenshots, listing. | Submission ready (T4) | 1.5 |
| Licence screen for the chosen model, if its terms require it (T3). | Screen and notice | 0.5 |

### Week 3: release
| Task | Deliverable | Days |
|---|---|---|
| Release candidates, closed testing on Play, TestFlight on iPhone with the household. | Feedback list | 2 |
| Fix release blockers, final model prompt freeze, version tags, rollback plan. | RC final | 1.5 |
| Submit both stores. Prepare the fallbacks: direct APK for household use, manual-entry build. | Submitted | 1.5 |

### After submission (about 2 weeks)
Respond to review questions, resubmit as needed, choose the fallback if Play rejects SMS permission. Start the Future backlog.

## 5. Data model
No new tables. Migration and upgrade tests from every earlier schema version.

## 6. Packages
No new core packages. Build tooling: Play Asset Delivery, Xcode and Play Console.

## 7. Prototype screens
All screens, final pass. See the gallery in the [README](../../README.md).

## 8. Tests
- **Upgrade:** install the Phase 1A build, upgrade through each phase to the release build, data intact.
- **Device matrix:** see [TESTING.md](../TESTING.md); mid-range Android is required.
- **Accessibility:** screen reader walkthrough of the main flows.
- **Store checks:** pre-launch report on Play, TestFlight review.
- **Security:** final run of the privacy tests (hidden, CVV, no INTERNET outside the sync feature, no public IP traffic).

## 9. Exit gate
- Both stores approved, or the fallback is chosen and documented.
- All privacy, security and accessibility checklists signed.
- Release build passes the full test suite and the device matrix.

## 10. Risks and fallback
| Risk | Fallback |
|---|---|
| Play rejects the SMS permission | Resubmit with clearer core-feature justification; else direct APK for household, or a manual-entry build with share-to-app |
| Apple rejects the Shortcut route | Explain in review notes; if refused, ship manual entry plus share extension on iPhone |
| App size too large | Smaller model quantisation, install-time pack tuning |
| Review delays | Buffer already used; ship the household via TestFlight and APK meanwhile |

## 11. Demo
End-to-end run on both phones from a clean install: onboarding, SMS to categorised transaction, card, hidden vault, report, household sync.

## Future (not scheduled)
Multi-currency, subscription and EMI detection, refund linking, home screen widgets, Hindi and regional languages, user-initiated model download (needs a privacy decision).

**Platform topics:** T3, T4, T6 in [PLATFORM_AND_COMPLIANCE.md](../PLATFORM_AND_COMPLIANCE.md).
