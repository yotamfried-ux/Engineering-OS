# Evidence & Simulation Patterns

## Real boundary before mock confidence
Mocks prove behavior against a model, not that an integration works today. Critical external dependencies should have at least one safe sandbox/test-environment check when available. Label mock-backed evidence.

## Fidelity ladder
1. unit; 2. in-process component; 3. real local dependency/container; 4. provider sandbox/test mode; 5. deployed staging/preview; 6. explicitly safe production read-only synthetic probe.

Use low levels for speed/diagnosis and high levels for boundary confidence.

## Mutation evidence
Capture action, immediate response, authoritative state, downstream consumer state when relevant, and cleanup.

## Failure injection
Exercise invalid/expired auth, permission denial, malformed input, timeout/provider 5xx, duplicate delivery, interruption/restart, and unavailable DB/queue/storage where feasible. Assert the specific expected failure semantics.

## Repeatability
If identical E2E inputs disagree, classify FLAKY. Never cherry-pick a green run.

## Cleanup
Use isolated test data and deterministic cleanup. Never use production customer records as fixtures.
