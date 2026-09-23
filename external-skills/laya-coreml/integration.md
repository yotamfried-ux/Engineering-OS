# Integration — Laya-CoreML

## Purpose

Use Laya-CoreML when an Apple Silicon target needs local, structured typed decisions — choice, ordinal score, or boolean `noul` — with probabilities and without autoregressive text generation or a cloud inference API.

## Upstream interface

Canonical upstream: `mizorewww/laya-coreml`. The package exposes the Python API `laya_coreml.load(...)`, `agent.predict(...)`, and the `laya-coreml` / `laya-coreml-snake` CLIs. Model bundles are downloaded from Hugging Face before local inference.

## When to use

Use it for small, explicit decision schemas where on-device execution, structured probabilities, and Apple Silicon/Core ML are useful constraints. The short ANE model has a 96-token total budget; use the general multilingual bundle for longer inputs.

Do not use it as a general chat/text-generation model, and do not treat conversion-fidelity or short-decision benchmarks as evidence of general reasoning quality or whole-application performance.

## Workflow

1. Select the upstream model bundle that matches language, context length, and compute target.
2. Install the official Python package on a supported Apple Silicon/macOS host.
3. Load the model and issue explicit typed questions.
4. Consume the returned structured answers/probabilities directly.
5. Use `local_files_only=True` when the model must already be cached and network retrieval is not allowed.
6. Reproduce upstream tests/benchmarks only when the target project needs evidence for those specific claims.

## Composition

Laya-CoreML is an optional local decision backend. Planning/review/orchestration skills may decide when such a backend is appropriate, but Engineering-OS does not wrap it in a runtime or route requests to it automatically.
