# LLM runtime check for Flutter (Phase 0)

Checked 11 Nov 2026 from pub.dev pages and the downloaded package files. Nothing here is run on a phone yet.

## Findings

| | flutter_gemma | flutter_edge_ai | llamadart |
|---|---|---|---|
| Status | Discontinued. 1.11.4 is the last version. | Successor of flutter_gemma. 2.6.0, MIT, verified publisher, published within the last few days. | 0.19.5, MIT, verified publisher, published within the last day. |
| Engines | LiteRT-LM | Pluggable add-on packages: LiteRT-LM (`.litertlm`), MediaPipe (`.task`, upstream in maintenance), ONNX, llama.cpp (`.gguf`), OS models | llama.cpp (`.gguf`) and LiteRT-LM (`.litertlm`) |
| Gemma 3 1B | Yes | Named explicitly | Via GGUF or LiteRT-LM |
| Qwen3 1.7B | Not listed | Not mentioned on the package page; maybe via its llama.cpp add-on (to verify) | Qwen3 named for strict JSON schema output; GGUF works |
| Android | Not stated | LiteRT parts need minSdk 30 and arm64-v8a only | minSdk not stated |
| iOS | Not stated | 15.0, up to 16.4 with the llama add-on | 16.4 or newer |
| INTERNET permission | Not checked | Documented as needed for model downloads; must be added by hand for release | No uses-permission found in the package's android folder |
| Build-time downloads | Not checked | Not checked | Its build hook downloads prebuilt native binaries from GitHub (`leehack/llamadart-native`, `litert-lm-native`) during the build |

## What this means

- `flutter_gemma` should not be used. It is discontinued.
- `llamadart` is the only candidate seen that clearly covers both models (Gemma 3 1B and Qwen3 1.7B) on both platforms with one API and GGUF files, the same family we tested on the Mac.
- `flutter_edge_ai` is the closest to the original plan (LiteRT-LM), but Qwen3 support is unconfirmed.

## Risks to settle in the benchmark

1. **Native binaries from a single maintainer's GitHub releases.** `llamadart` fetches prebuilt libraries at build time. Decide whether to pin versions and checksums, or vendor the libraries, before this is used for a privacy-focused app.
2. **No-INTERNET promise.** Build the Android release APK and check the merged manifest for the INTERNET permission. Model files must come from the app bundle, never from a download.
3. **Young packages.** Both were published very recently and change quickly. Pin exact versions.
4. **Speed and memory** on the vivo and iPhone 15 are untested. The benchmark app (next) measures them.

## Checked 12 Nov 2026

- Release APK of the benchmark has no INTERNET permission.
- `llamadart` build hook verifies downloaded native archives with SHA-256 (per the package source); versions are pinned exactly.

## Next

Build a benchmark app in `mobile/` (or a separate folder) that loads a local GGUF with `llamadart`, runs the 24 seed SMS and shows accuracy and seconds per SMS. Add `flutter_edge_ai` with Gemma 3 1B `.litertlm` as the second runtime if time allows.
