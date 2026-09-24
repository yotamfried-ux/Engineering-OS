# AI Capability & Connector Registry

Purpose: answer **what capability can I use for this task, where is its source of truth, and what must I verify before depending on it?**

Start with [ROUTING-MAP.md](./ROUTING-MAP.md). It routes by job and keeps context small. Use [SOURCE-POLICY.md](./SOURCE-POLICY.md) to distinguish official/canonical evidence from maintained references, community tools and historical material.

## Navigation index

The registry is a map of available knowledge and capabilities, not an execution
policy. Useful entry points include:

- `ROUTING-MAP.md` for task-to-knowledge navigation;
- `connectors.md` for external data/actions;
- `token-context-efficiency.md` for context/token tools;
- `application-testing/README.md` for web/mobile testing capabilities;
- `security/` and `../patterns/security/` for security knowledge;
- `agent-tools.md` and `../external-skills/` for optional agent capabilities.

Entries record availability, provenance, prerequisites and verification evidence
where known so the active worker can choose how to proceed.

## Normalized capability contract

New executable/installable capability entries should record:
- purpose / trigger
- **do-not-use / overlap guidance**
- canonical upstream and source tier
- supported host/surface and mechanism (app/plugin/MCP/skill/hook/CLI/API)
- read/write scope
- installation/connection
- authentication/secrets/permissions
- verification path
- **what successful verification proves**
- **what it does not prove**
- limitations/security/privacy
- qualification status and last live verification date when actually tested

Older assets may predate this contract. Presence in the library is not a LIVE qualification.

## Status semantics

- **READY / HOST-DEPENDENT** — wrapper/upstream is coherent; live use still requires the target host/runtime.
- **CONDITIONAL** — prerequisites or qualification gaps remain.
- **REFERENCE ONLY** — useful knowledge, not an executable capability.
- **STALE** — current upstream/instructions need re-verification.
- **BROKEN** — known active path cannot work as documented.

For target-project evidence, use the separate testing vocabulary: PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED / FLAKY / NOT APPLICABLE.

## Audit/evaluation

- [NORMALIZATION-AUDIT.md](./NORMALIZATION-AUDIT.md) — current library-level findings and remaining debt.
- [QUALIFICATION-REPORT.md](./QUALIFICATION-REPORT.md) — prior capability qualification evidence.
- [EVALUATION-BANK.md](./EVALUATION-BANK.md) — representative routing scenarios for evaluating Engineering-OS itself.

**Freshness rule:** exact product/API/install/release behavior changes. Verify current canonical upstream documentation when exact current behavior matters.
