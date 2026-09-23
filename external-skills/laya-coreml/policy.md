# Policy — Laya-CoreML

- **type:** local-ai, typed-decisions, Apple-Silicon
- **level:** conditional
- **default install:** no
- **scope:** local structured decision inference on supported Apple hardware

## Rules

1. Prefer Laya-CoreML only when typed decisions are sufficient; use a generative model when the task requires generated text or open-ended reasoning.
2. Respect the selected model's documented context limit, especially the 96-token ANE bundle.
3. Do not generalize upstream benchmark numbers to different hardware, models, inputs, or measurement boundaries.
4. Treat upstream conversion-fidelity fixtures as port-validation evidence, not general task-accuracy evidence.
5. Pin package/model revisions when reproducibility matters.
6. Keep target inputs local only after required model/package artifacts have been obtained; separately assess download, logging, and surrounding application telemetry.
7. Do not turn this capability into an Engineering-OS runtime, router, daemon, database, or orchestration layer.

## Precedence

An existing official application API or a platform-neutral inference backend takes precedence when Apple-specific local execution offers no material benefit.
