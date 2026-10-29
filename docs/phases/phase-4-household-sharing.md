# Phase 4: Household sharing

**Dates:** 4 Mar to 31 Mar 2027 (4 weeks). **Back to:** [index](../PHASE_PLAN.md)

## 1. Goal and output
Two phones belonging to one household share chosen transactions over the same Wi-Fi, end-to-end encrypted, with a combined home budget. Hidden transactions never leave the phone.

## 2. Spec coverage
CLAUDE.md 3.9 (household sharing), section 6 (household_peers, household_transactions, sync_log), section 7 (network), decision 12.

## 3. Prerequisites
- Phase 3 exit gate passed.
- Wi-Fi sync spike from Phase 0 (T1) with fallback decided.
- Two real phones for testing, ideally one Android and one iPhone.
- Signed-off screens: household, pairing, shared flag, home budget.

## 4. Work breakdown

### Week 1: pairing and keys
| Task | Deliverable | Days |
|---|---|---|
| Key design: long-term key pair per phone in Keystore or Keychain, peer public key stored in household_peers. | Design note and code | 1.5 |
| QR pairing: phone A shows a QR (mobile_scanner and qr_flutter), phone B scans, both show a 6-digit code to confirm. | Pairing flow | 2 |
| Unpair and re-pair, lost-phone handling (revoke the peer). | Flow and tests | 1.5 |

### Week 2: transport and sync
| Task | Deliverable | Days |
|---|---|---|
| Add the INTERNET permission and the iPhone local-network keys (NSLocalNetworkUsageDescription, NSBonjourServices) and Android multicast lock (T1). Pre-explain prompts on the pairing screen. | Prompts explained and handled | 1 |
| Local transport: HttpServer or WebSocket plus mDNS discovery (bonsoir or nsd). Fallback: show the peer's IP under the QR to type in. | Phones find each other | 2 |
| End-to-end encrypted channel using the paired keys. Only sends changes since the last sync (sync_log). | Delta sync both ways | 2 |

### Week 3: shared data
| Task | Deliverable | Days |
|---|---|---|
| Shared flag per transaction, share rules (by category or per transaction). Only shared transactions are sent. Hidden never included. | Share control | 1.5 |
| household_transactions table for received transactions, shown with who paid. | Shared list | 1 |
| Duplicate detection for joint accounts: bank, last 4, amount, reference; shown once. | Dedupe tests | 1.5 |
| Conflict rules: edits on both phones, last-writer or field rules, documented. | Tests | 1 |

### Week 4: home budget, fallback, hardening
| Task | Deliverable | Days |
|---|---|---|
| Home budget view: combined spending for household categories. Personal budgets stay private. | Screen | 1.5 |
| Encrypted file export and import with passphrase as the fallback, shared via WhatsApp, AirDrop or Quick Share. | Round trip | 1.5 |
| Network test: the app connects only to the paired peer's LAN address, never a public IP. Failure cases: isolated Wi-Fi, one phone offline, mid-sync interruption. | Test report | 1 |
| Phase review and demo. | Exit gate checked | 1 |

## 5. Data model
main.db: household_peers, household_transactions, sync_log. Shared flag already on transactions.

## 6. Packages
mobile_scanner, qr_flutter, dart:io HttpServer and WebSocket, bonsoir or nsd, cryptography and cryptography_flutter.

## 7. Prototype screens that become real
[Household](../../screenshots/household.png), [Profile](../../screenshots/profile.png), [Dashboard](../../screenshots/dashboard.png), [Budgets](../../screenshots/budgets.png).

## 8. Tests
- **Privacy:** hidden transactions are never in any sync payload (automated, reuses generated data).
- **Crypto:** payload unreadable without the keys, tampered payload rejected, replay rejected.
- **Pairing:** mismatching 6-digit codes abort pairing.
- **Sync:** two-way delta sync, interrupted sync resumes, no duplicates after repeated syncs.
- **Dedupe:** the same joint-account SMS on both phones shows once.
- **Network:** traffic capture shows only LAN traffic to the paired peer.
- **Device:** Android to iPhone, Android to Android, iPhone to iPhone as available, normal and isolated Wi-Fi.

## 9. Exit gate
- Two real phones pair by QR and sync both ways on the same Wi-Fi.
- Hidden transactions never leave the device (test green).
- A duplicate SMS on both phones appears once.
- Network test shows no traffic outside the LAN.
- Fallback file export and import work.

## 10. Risks and fallback
| Risk | Fallback |
|---|---|
| Router blocks device-to-device traffic | IP entry, then file export |
| iOS local-network permission denied | Explain and link to Settings; use file export |
| Clock differences cause conflicts | Use logical versions, not only time |
| Two different OS pairs behave differently | Test all pairs; document limitations |

## 11. Demo
Pair two phones by QR, share a transaction, show the combined home budget, show a hidden transaction not appearing, and use the file fallback.

**Platform topics:** T1 in [PLATFORM_AND_COMPLIANCE.md](../PLATFORM_AND_COMPLIANCE.md).
