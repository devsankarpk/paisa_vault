# ADR 0002: How the backup file is protected

Status: **Accepted** (27 Nov 2026). Built and tested in Phase 1B.

## Context

The database key lives in the Android Keystore or iOS Keychain and cannot leave the phone. A backup that depended on it could not be restored on a new phone, or after "Erase everything". The same file is also the only way back in after a forgotten PIN (DECISIONS G2).

## Decision

1. **The backup has its own key, made from a passphrase the user types.** Nothing about the phone's keys is used, so the file opens on any phone with the app and the passphrase.
2. **Key derivation:** PBKDF2-HMAC-SHA256, 600,000 rounds, a random 16-byte salt per file.
3. **Encryption:** AES-256-GCM with a random 12-byte nonce. The 16-byte tag detects a wrong passphrase or a damaged file, and nothing is changed in that case.
4. **File layout:** `PVBK` | format version (1 byte) | rounds (4 bytes) | salt (16) | nonce (12) | cipher text | tag (16). The rounds are stored in the file, so the number can be raised later and old files still open.
5. **Contents:** transactions, accounts, categories, merchant rules and budgets, as gzip-compressed JSON. **Left out:** saved SMS text, and anything hidden (hidden transactions and card secrets are never exported, CLAUDE.md sections 3.6 and 7).
6. **Restore replaces everything in one database transaction.** A failed restore leaves the existing data as it was.
7. **The passphrase is never stored.** The screen says so: lose it and the file cannot be opened. Minimum 8 characters.

## Why not the alternatives

- *Key from the PIN:* a 4-digit PIN has 10,000 possibilities, which is too few to protect a file that leaves the phone.
- *Key in the Keychain or Keystore:* cannot move to another phone.
- *A server or cloud escrow:* breaks the "no server, no account" promise.

## Consequences

- A weak passphrase weakens the file. The 600,000 rounds slow guessing but do not stop it for a short or common passphrase.
- Restoring a backup brings back transactions but not the original SMS text, so "Re-check with the model" works only on messages received after the restore.
- A forgotten passphrase means no restore. This is by design.

## Checks

- Tested: round trip, wrong passphrase, damaged file, nothing hidden or raw in the file (`test/backup/backup_test.dart`).
- Still to do: restore on a clean install on a phone.
