# Engineering-OS — Agent Map

This repository is a **knowledge library, not a runtime**. Use this file as a map, not as an encyclopedia.

## Start here

1. Identify the job to be done.
2. Open [capability-registry/ROUTING-MAP.md](capability-registry/ROUTING-MAP.md).
3. Read only the branch of knowledge relevant to the task.
4. Prefer authoritative/current sources according to [SOURCE-POLICY.md](capability-registry/SOURCE-POLICY.md).
5. For installable capabilities, check qualification status before depending on them.
6. For testing/security/release claims, produce evidence on the exact revision/environment; never turn NOT TESTED, BLOCKED or PARTIAL into PASS.

## Main knowledge domains

- Build/architecture: `templates/`, `patterns/`, `docs/architecture-guides/`, `docs/frameworks/`
- Agent capabilities: `capability-registry/`, `external-skills/`
- External services: `external-systems/`
- Testing/qualification: `patterns/testing/`, `templates/testing/`
- Security: `patterns/security/`, `capability-registry/security/`, `templates/security/`
- Troubleshooting: `docs/troubleshooting/`, `lessons-learned/`, `failed-solutions/`
- Reference implementations: `docs/reference-repositories/`
- Official docs: `docs/official-docs/`
- Historical imported Stage 3 knowledge: `improved-stage3/`

## Status vocabulary

For executable/installable capabilities:
- **READY / HOST-DEPENDENT** — wrapper is coherent and upstream exists; live use still depends on host/runtime/credentials.
- **CONDITIONAL** — useful but prerequisites or unresolved qualification gaps remain.
- **REFERENCE ONLY** — knowledge/reference, not an executable capability.
- **STALE** — source or instructions need re-verification.
- **BROKEN** — known active path cannot work as documented.

For project verification evidence use: PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED / FLAKY / NOT APPLICABLE.

## Guardrails

- Do not install every tool by default.
- Do not treat a community repository as an official standard.
- Do not treat a successful agent/tool invocation as proof that the target system works.
- Do not rely on historical paths from the archived runtime.
- Do not commit secrets, share-token query parameters or private credentials.
- If current availability/version matters, verify upstream first.
