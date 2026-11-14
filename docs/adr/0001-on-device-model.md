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

Run 12 Nov 2026 on the 24 synthetic seed SMS, release builds, split design, one run each. Thresholds come from `docs/phases/phase-0-groundwork.md`.

| Criterion | Threshold | iPhone 15 Gemma | iPhone 15 Qwen3 | vivo Gemma | vivo Qwen3 |
|---|---|---|---|---|---|
| Amount correct | 98% | 100% | 100% | 100% | 100% |
| Bank and last 4 | 95% | 100% | 100% | 100% | 100% |
| Merchant | 90% | 87.5% fail | **93.8% pass** | 68.8% fail | 81.3% fail |
| Speed per SMS | under 3 s | 1.7 s pass | 2.4 s pass | 4.7 s fail | 6.8 s fail |
| Peak memory | none set | 974 MB | 1443 MB | not recorded | 2207 MB |
| Debit/credit, channel, reference, date | 98%, 90% | not scored in the report; rules read them and were tuned on this set | | | |
| Category within the user list | 80% | not scored | | | |
| Valid JSON | 99% | not scored | | | |
| Three runs averaged | required | one run | | | |

Amount, bank and last 4 are read by rules, so those 100% results show the rules, not the model. The 24 messages are synthetic and the rules were tuned on them, so these numbers are optimistic.

## Licence (T3)

Details in `docs/spikes/model-licences.md`. Both models can be shipped.
- **Qwen3 1.7B: Apache 2.0.** No use restrictions. Keep the licence text and notice.
- **Gemma 3: Gemma Terms of Use.** Needs a copy of the terms, a notice file, pass-through of its prohibited-use policy, and Google can terminate it. Workable but heavier.

## Size and delivery (bundling check)

| | Size | Limit | Status |
|---|---|---|---|
| Qwen3 1.7B GGUF | 1.36 GB | 1.5 GB per Play asset pack (compressed) | Fits; real upload not yet tried |
| Gemma 3 1B GGUF | 806 MB | same | Fits |
| All install-time packs | | 4 GB | Fits |
| Base module | | 500 MB | Model must stay out of it |
| Free space during install | about 2.8 GB for Qwen3 | | Tell users |
| iOS bundled size and App Store download warning | not measured | | Open |

## Risks and consequences

- **Slow on mid-range Android.** Neither model meets 3 s on the vivo. Accepted because processing runs in a background queue. Revisit after real use.
- **Native binaries from one maintainer.** The `llamadart` build hook downloads prebuilt libraries and checks SHA-256 digests. Keep exact versions, commit `pubspec.lock`, re-read the hook on upgrade, consider vendoring before release.
- **Privacy.** Release APK has no INTERNET permission (checked 12 Nov 2026).
- **Spec change.** CLAUDE.md 3.2 and decision 6 change when this ADR is accepted.
- **Fallback if merchant accuracy fails on real SMS.** More merchant rules and learning from user answers (section 3.3), or a larger model on newer phones.

## Open checks before acceptance

1. Rerun both models on the vivo with the latest build (UPI-handle fix).
2. Rerun on real SMS with at least 20 transaction alerts per core bank (only about 6 real alerts now).
3. Score direction, channel, reference, date, category and JSON validity, and average three runs.
4. Record the exact Qwen3 GGUF source file and its hash.
5. Measure the real Play upload size and the iOS app size.
6. Add an open source licences screen (app task).
