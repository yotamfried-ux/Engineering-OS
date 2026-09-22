# Laya-CoreML

## Purpose / trigger
Use when a target running on Apple Silicon needs **local typed decisions** (choice, ordinal score, or boolean/no-unclear-yes style decisions) with probabilities, without autoregressive text generation or a cloud API.

## Do not use / overlap
- Not a general chat or text-generation model.
- The short ANE bundle has a 96-token total input budget; use the general multilingual bundle when longer context is required.
- Do not treat the published short-decision latency as full application/game-loop latency.
- Prefer a platform-neutral or cloud model when Apple Silicon/Core ML is not a target constraint.

## Source and authority
- Upstream: https://github.com/mizorewww/laya-coreml
- Authority tier: **Tier C — community capability**.
- License reported upstream: Apache-2.0.
- This is an independent Core ML port, not an Apple or Convai Innovations release.

## Mechanism / hosts
Python package for Apple Silicon/macOS using Core ML. Upstream provides CPU+GPU and CPU+ANE model bundles, local/offline inference after model download, conversion utilities, tests, benchmarks, and a Snake demonstration.

## Install / activation
Follow the upstream README and pinned release/model instructions. Typical demo path reported upstream:

```bash
pip install 'laya-coreml[demo]'
hf download aac6fef/laya-multilingual-coreml-ane --local-dir models/snake
laya-coreml-snake --model ./models/snake
```

Current upstream requirements state Apple Silicon, macOS 15+, and Python 3.11–3.13.

## Credentials / permissions
No cloud credential is required for inference after the model is present locally. Initial model retrieval from Hugging Face may require whatever network/access policy applies to the host. Do not store access tokens in this repository.

## Verification
Use upstream's own reproducibility material rather than inventing a local benchmark:
1. install the package on supported Apple Silicon;
2. download the pinned model/revision described by upstream;
3. run a representative `predict` call and confirm typed answers/probabilities;
4. for conversion fidelity, run the upstream tests/fixtures;
5. for performance claims, reproduce the upstream benchmark on the actual target hardware and record hardware, OS, model variant, input length, warmup, and measurement boundaries.

## What success proves
A successful target-host check can prove that the selected model loads and returns the documented typed-decision shape locally on that host. Reproducing an upstream benchmark can provide evidence for that exact hardware/workload/measurement method.

## What it does NOT prove
It does not prove general reasoning quality, application correctness, a universal latency/energy advantage, or full-game speed. Upstream explicitly distinguishes conversion-fidelity fixtures from general task accuracy and short single-question measurements from Snake frame/game-loop measurements.

## Security / privacy
Local inference can keep post-download decision inputs on-device, but model download, package installation, logs, surrounding application code, and any telemetry must be assessed separately. Treat model artifacts and package provenance as supply-chain inputs and pin/verify releases where the target requires reproducibility.

## Qualification status
**NOT TESTED in Engineering-OS.** Catalogued from upstream documentation on 2026-09-22. Published benchmark and fidelity numbers remain upstream claims until reproduced on a target host.

## Canonical references
- https://github.com/mizorewww/laya-coreml
- https://github.com/mizorewww/laya-coreml/blob/main/BENCHMARKS.md
- https://github.com/mizorewww/laya-coreml/tree/main/tests
- https://github.com/mizorewww/laya-coreml/blob/main/docs/LAUNCH.md
