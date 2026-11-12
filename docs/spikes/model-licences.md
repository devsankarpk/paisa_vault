# Model licence review (T3)

Checked 12 Nov 2026 from the publishers' pages. This is an engineering reading, not legal advice. Re-read the live terms before the store submission.

| | Qwen3 1.7B | Gemma 3 1B |
|---|---|---|
| Licence | Apache 2.0 (Hugging Face model card: `Qwen/Qwen3-1.7B`) | Gemma Terms of Use (ai.google.dev/gemma/terms) plus Prohibited Use Policy |
| Bundle in a store app | Allowed | Allowed, with conditions |
| What we must do | Ship the licence text and notices (an in-app "Open source licences" page). | Give every user a copy of the Terms; carry the use restrictions into our own terms of use; include a notice file saying "Gemma is provided under and subject to the Gemma Terms of Use found at ai.google.dev/gemma/terms"; mark any modified files. |
| Termination risk | None | Google can terminate for breach, and we would then have to stop distributing and delete copies. Google may also update Gemma. |
| Fit with our use | No use restrictions | Prohibited Use Policy bans automated decisions about finances and processing sensitive personal data without consent. Our use (on-device sorting of the user's own SMS into categories, no decisions about people) looks fine, but we must not present it as financial advice. |

## Conclusion

Both can be shipped in the apps. Qwen3 is simpler: Apache 2.0 has no use restrictions and no termination clause tied to the model. Gemma carries extra obligations and a use policy we would have to repeat in our terms. This supports the working choice of Qwen3 1.7B.

## To do

1. Confirm the exact Qwen3 GGUF we ship (converted by Ollama or llama.cpp) keeps the Apache 2.0 licence. It should, because the weights are the same; note the source file and its hash in ADR 0001.
2. Add an "Open source licences" screen and a notice file to the app (Qwen3, `llamadart` MIT, llama.cpp MIT).
3. If Gemma ever becomes the choice: add the Gemma notice file and the use restrictions to our terms.
