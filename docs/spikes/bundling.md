# Bundling check (Phase 0)

Measured 17 Nov 2026 on the benchmark app (`spikes/llm_bench/`, release builds) and the two GGUF files in `models/`. Nothing was uploaded to Google Play or App Store Connect, so the real store sizes are still to confirm.

## Sizes measured

| Item | Size |
|---|---|
| Qwen3 1.7B GGUF | 1,359 MB (1.36 GB) |
| Qwen3 1.7B GGUF after gzip | 1,305 MB (96% of original) |
| Gemma 3 1B GGUF | 806 MB |
| Gemma 3 1B GGUF after gzip | 786 MB (97.5%) |
| Android release APK, arm64-v8a, no model | 120.5 MB |
| Android release APK, armeabi-v7a, no model | 16.2 MB |
| Android release APK, all ABIs combined | 257 MB |
| iOS release `Runner.app`, no model | 37 MB |

A GGUF file is already quantised, so compression saves only 2 to 4%.

## Android

| Check | Result |
|---|---|
| Qwen3 pack (about 1.31 GB compressed) against the 1.5 GB limit for one asset pack | Fits, 195 MB spare |
| Gemma pack (about 0.79 GB) | Fits easily |
| All install-time packs together, limit 4 GB | Fits |
| Base module, limit 500 MB | Fits: the app without the model is about 120 MB |
| Download size for the user | About 1.4 GB for Qwen3 (app plus pack), about 0.9 GB for Gemma |
| Free space needed during install | About twice the size, so about 2.8 GB for Qwen3 |
| 32-bit phones | **The armeabi-v7a build is only 16 MB and has no model runtime, so the model cannot run on 32-bit phones.** Ship arm64 only, as already decided |

### Finding: install-time packs are not file paths
The Play documentation (checked 17 Nov 2026) says install-time asset packs are read through the Android `AssetManager`. Only fast-follow and on-demand packs give a file path (`getPackLocation`). The model runtime (llama.cpp through `llamadart`) loads the model from a file path. So with an install-time pack the app must **copy the model out of the assets into the app's own storage on first launch**, which needs another 1.4 GB (about 2.8 GB in total until the pack is removed) and a few minutes.

Options for Phase 1A:
1. **Install-time pack plus first-run copy.** Keeps decision 7 ("no separate download step") but uses double the space and needs a progress screen on first launch.
2. **Fast-follow pack.** Play downloads it automatically right after install and gives a file path, so no copy. The user may wait on first open, and a download over 200 MB on mobile data asks for consent. Nothing in the app needs the INTERNET permission, because Play does the download. This slightly changes decision 7.
3. **Try opening the asset with a file descriptor** (uncompressed asset, `openFd`) and pass that to the runtime. Needs a spike, and `llamadart` may not support it.

Recommendation: decide in Phase 1A after a real internal-testing upload on Play. Until then plan for option 1 as the safe default.

### Trimming
The arm64 APK includes libraries for engines we do not use (`libLiteRtLm.so` 31 MB, `libggml-vulkan.so` 26 MB). Check whether `llamadart` lets us drop them to cut about 57 MB.

## iPhone

| Check | Result |
|---|---|
| App without model | 37 MB |
| App with the Qwen3 model bundled | About 1.4 GB |
| App Store limit | 4 GB for the app; no problem |
| Download warning | iOS warns on mobile data for apps over 200 MB; the user can allow it |
| Model location | Bundled files are read-only inside the app; llama.cpp can load them from the bundle path, so no copy is needed |

Not measured: the real App Store size (after Apple's compression and thinning), and install time.

## Still to do
- Upload a test bundle (with a model pack) to Play internal testing, once the developer account exists, and note the real sizes, the install time and whether the pack really reaches 1.3 GB compressed.
- Do the same with TestFlight on the iPhone.
- Measure the first-launch copy time on the vivo if option 1 is chosen.
- Check which unused native libraries can be dropped.
