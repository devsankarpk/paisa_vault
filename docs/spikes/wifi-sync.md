# Wi-Fi household sync spike (Phase 0, T1)

Run 16 Nov 2026: iPhone 15 (iOS 26.7.1) and vivo V2303 (Android 15) on the same home Wi-Fi (192.168.1.x). Code: `spikes/wifi_sync/`.

## What the spike does
Each phone starts a small HTTP server on a random port, advertises it over mDNS as `_paisavault._tcp`, and looks for the other phone. The phone with the smaller name starts. They swap X25519 public keys, derive an AES-256 key (HKDF-SHA256), and show a 6-digit code made from both public keys, so a person can compare it on both screens. One message goes each way, encrypted with AES-256-GCM. Nothing is stored.

## Results

| Check | Result |
|---|---|
| Discovery by mDNS, vivo finds iPhone | Yes, with no manual address (found 8.2 s after the vivo app started; the iPhone opened a few seconds later) |
| Manual address (ip:port), iPhone to vivo | Yes |
| Key exchange | 32 ms |
| Encrypted message each way | Yes, 8 ms round trip |
| 6-digit code matches on both phones | Yes (125805 on both) |
| Tampered message rejected, third party cannot read | Yes, unit tests |
| iPhone local-network permission prompt | Appears on first run; the user allowed it |
| Isolated Wi-Fi (guest network, client isolation) | **Not tested** |
| The vivo reaching the iPhone by manual address (reverse direction) | Not tested; automatic discovery did connect from the vivo to the iPhone |
| Both phones started at once | Not tested; the smaller-name rule avoids two connections |

## Notes
- On the iPhone the Wi-Fi address is the one on `en0`. `192.0.0.x` is the mobile data interface and must not be used. The app must pick the Wi-Fi interface.
- Android needs INTERNET, ACCESS_WIFI_STATE and CHANGE_WIFI_MULTICAST_STATE. iPhone needs `NSLocalNetworkUsageDescription` and `NSBonjourServices`. This confirms the T1 note: the Android build has INTERNET from Phase 4, and Phases 1 to 3 ship without it.
- Plain HTTP is used only to carry encrypted bytes; the key exchange here is unauthenticated, so the 6-digit code (or the QR code in the real design) is what stops a person-in-the-middle. The real pairing must compare the code or carry the key in the QR.
- Packages: `nsd` 5.0.1 and `cryptography` 2.9.0 (pure Dart; fine for small messages, check speed for a large first sync).

## Decisions
1. Discovery by mDNS works between iPhone and Android, so Phase 4 can use it.
2. Keep the fallbacks: show the address under the QR to type in, and the encrypted file export for isolated networks.
3. The real pairing puts the public key in the QR code and checks it, in addition to the 6-digit code.

## Still to do
Test on an isolated guest network, and with the apps in the background. Record the outcome here.
