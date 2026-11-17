# ADR 0001: On-device model and extraction approach

Status: **Proposed** (draft 14 Nov 2026). Accepted only when the open checks at the end are closed.

## Context

CLAUDE.md section 3.2 plans one bundled LLM (Gemma 3 1B via `flutter_gemma`) that returns eleven fields per SMS as JSON. Phase 0 had to pick the model and prove it is fast and accurate enough on real phones, with a licence that allows shipping it in the stores.

## Decision (proposed)

1. **Split extraction.** Plain code reads amount, last 4 digits, direction, bank, date, reference and the UPI/NEFT/IMPS/ATM channel. The model returns only merchant, category and channel, as a short JSON reply (60 tokens at most). The model's merchant is used only when no rule finds one, and a bank name is never accepted as a merchant. The amount safety check stays.
2. **Model: Qwen3 1.7B** (GGUF, int4, 1.36 GB), run with `llamadart` 0.19.5 pinned exactly. **Fallback: Gemma 3 1B** (GGUF, 806 MB).
3. **Runtime: `llamadart`.** `flutter_gemma` is discontinued. See `docs/spikes/llm-runtime.md`.

## Why

- Asking the model for all fields took 12.5 s (Gemma) and 60.7 s (Qwen3) per SMS on the vivo. The split cut this to 4.7 s and 6.8 s, and to 1.7 s and 2.4 s on the iPhone 15.
- Qwen3 is the only candidate over the 90% merchant threshold, and its licence has no use restrictions.

## Scorecard

Run 12 Nov 2026 (iPhone) and 17 Nov 2026 (vivo, latest build with the UPI-handle fix) on the 24 synthetic seed SMS, release builds, split design, one run each. Thresholds come from `docs/phases/phase-0-groundwork.md`.

| Criterion | Threshold | iPhone 15 Gemma | iPhone 15 Qwen3 | vivo Gemma | vivo Qwen3 |
|---|---|---|---|---|---|
| Amount correct | 98% | 100% | 100% | 100% | 100% |
| Bank and last 4 | 95% | 100% | 100% | 100% | 100% |
| Merchant | 90% | 87.5% fail | **93.8% pass** | 87.5% fail | **93.8% pass** |
| Speed per SMS | under 3 s | 1.7 s pass | 2.4 s pass | 4.2 s fail | 5.9 s fail |
| Memory after load | none set | 974 MB | 1443 MB | 1522 MB | 2212 MB |
| Direction, reference, date | 98%, 90% | rules read them: 100% on the vivo reports | | 100% | 100% |
| Channel | 90% | not recorded | not recorded | 93.3% pass | 86.7% fail |
| Category within the user list | 80% | not scored | | | |
| Valid JSON | 99% | not scored | not scored | 100% (0 bad replies) | 100% (0 bad replies) |
| Three runs averaged | required | one run | | | |

Amount, bank and last 4 are read by rules, so those 100% results show the rules, not the model. The 24 messages are synthetic and the rules were tuned on them, so these numbers are optimistic.

## Licence (T3)

Details in `docs/spikes/model-licences.md`. Both models can be shipped.
- **Qwen3 1.7B: Apache 2.0.** No use restrictions. Keep the licence text and notice.
- **Gemma 3: Gemma Terms of Use.** Needs a copy of the terms, a notice file, pass-through of its prohibited-use policy, and Google can terminate it. Workable but heavier.

## Size and delivery (bundling check)

| | Size | Limit | Status |
|---|---|---|---|
| Qwen3 1.7B GGUF | 1.36 GB (1.31 GB gzipped) | 1.5 GB per Play asset pack (compressed) | Fits with 195 MB spare; real upload not yet tried |
| Gemma 3 1B GGUF | 806 MB | same | Fits |
| All install-time packs | | 4 GB | Fits |
| Base module | | 500 MB | Model must stay out of it |
| Free space during install | about 2.8 GB for Qwen3 | | Tell users |
| iOS app: 37 MB without model, about 1.4 GB with it | | 4 GB limit; 200 MB mobile-data warning | Measured without a store upload |
| Install-time packs are read through AssetManager, not a file path | | | The runtime needs a file path: first-run copy (needs 2x space) or a fast-follow pack. See `docs/spikes/bundling.md` |

## Risks and consequences

- **Slow on mid-range Android.** Neither model meets 3 s on the vivo. Accepted because processing runs in a background queue. Revisit after real use.
- **Native binaries from one maintainer.** The `llamadart` build hook downloads prebuilt libraries and checks SHA-256 digests. Keep exact versions, commit `pubspec.lock`, re-read the hook on upgrade, consider vendoring before release.
- **Privacy.** Release APK has no INTERNET permission (checked 12 Nov 2026).
- **Spec change.** CLAUDE.md 3.2 and decision 6 change when this ADR is accepted.
- **Fallback if merchant accuracy fails on real SMS.** More merchant rules and learning from user answers (section 3.3), or a larger model on newer phones.

## Open checks before acceptance

1. ~~Rerun both models on the vivo with the latest build (UPI-handle fix).~~ Done 17 Nov 2026: Qwen3 5.9 s, merchant 93.8%; Gemma 4.2 s, merchant 87.5%. The slowest message took 23.3 s (Qwen3) and 18.1 s (Gemma), likely the first one after load.
2. Rerun on real SMS with at least 20 transaction alerts per core bank (only about 6 real alerts now).
3. Score direction, channel, reference, date, category and JSON validity, and average three runs.
4. Record the exact Qwen3 GGUF source file and its hash.
5. Measure the real Play upload size and the iOS app size.
6. Add an open source licences screen (app task).
