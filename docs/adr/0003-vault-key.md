# ADR 0003: How vault.db is locked

Status: **Accepted with one known limit** (28 Nov 2026). Built in Phase 2, Week 2.

## Context

CLAUDE.md sections 3.6 and 7 want hidden transactions and card secrets in a separate encrypted database that opens only after PIN, fingerprint or Face ID, every time. main.db is different: its key sits in the Keystore or Keychain so new SMS can be saved in the background.

## Decision

1. **vault.db has its own random 256-bit key.** It is a separate file, opened with the same SQLCipher-compatible settings as main.db.
2. **The key is never stored as it is.** It is wrapped with AES-256-GCM under a key made from the PIN (PBKDF2-HMAC-SHA256, 200,000 rounds, random 16-byte salt). Only a correct PIN unwraps it.
3. **The PIN's attempt limit applies first.** Opening the vault calls the same PIN check as the lock screen, so guessing is slowed the same way. A locked-out PIN cannot open the vault even when correct.
4. **Face ID and fingerprint use a second copy** of the key kept in the Keystore or Keychain. The app reads it only after a successful biometric check, and only if the user turned biometrics on. It is created the first time the vault is opened with the PIN while biometrics are on.
5. **The key is first created on the first PIN opening of the vault**, not at setup, so older installs need no migration.
6. **Locking closes vault.db and drops the key from memory.** This happens whenever the app locks (auto-lock, leaving the app). The vault object throws if used while closed, so no code can reach it by accident.
7. **Every opening is logged** in the vault (time and method: pin or biometric).
8. **"Erase everything"** deletes vault.db and both stored keys.

## Known limit

The biometric copy (point 4) is protected by the app's own biometric check, not by a key bound to the phone's secure hardware. Someone who can read the app's Keychain or Keystore entries on an unlocked or rooted phone could read that copy. The PIN copy has no such weakness: it is useless without the PIN. Anyone who needs that stronger guarantee can leave biometrics off for the vault.

**Planned hardening:** a hardware-bound, biometric-gated key (Android Keystore with `setUserAuthenticationRequired`, iOS Keychain access control `biometryCurrentSet`) through a small native plugin. It is left for the security review at the end of Phase 2.

## Why not the alternatives

- *Key only in the Keychain or Keystore, no PIN:* nothing then ties the vault to the owner. Anyone who opens the app could read it.
- *Key from the PIN only, no biometric copy:* safe, but the owner would type the PIN every time, and the plan asks for biometric opening.
- *A 4-digit PIN as the sole secret on a stolen file:* the PIN has only 10,000 values, so the wrapped key alone does not stop an offline guess. It is kept in the Keystore or Keychain, which gives device protection and the attempt limit above.

## Checks

Tested (`test/vault/vault_test.dart`): closed until opened; wrong PIN refused and counted; lockout stops even the right PIN; wrong key cannot read the file and the file has no readable text; audit rows; biometric needs the copy, a passing check and a sensor; lock is safe to repeat; key stored wrapped; no CVV column; erase forgets the keys.

Still to do: the hardware-bound biometric key, and a check on both phones once the vault screens exist.
