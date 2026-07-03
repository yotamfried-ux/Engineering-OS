# Auto-install MCP servers for governed projects

| Field | Value |
|---|---|
| Task class | mcp_or_connector_config |
| Task type | governance, connector-config |
| Domain tags | mcp, connectors, claude-code, installer, documentation |
| Task-router evidence | core/task-router.md read before writes; task is Engineering OS connector/MCP configuration |
| Workflow evidence | core/workflow.md and core/connector-policy.md read before writes |
| Target paths | templates/connectors/engineering-os-mcp.json, scripts/install-mcp-servers.sh, scripts/use-in-project.sh, scripts/enforcement/tests/test-mcp-auto-install.sh, scripts/enforcement/tests/test-active-mcp-verification.sh, core/mcp-servers.md, core/capability-registry.yaml, docs/operations/connector-verification-matrix.md, docs/operations/active-mcp-verification.md |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github, context7 |
| Skills | superpowers |
| Validation gates | bash -n, JSON validation, test-mcp-auto-install.sh, test-active-mcp-verification.sh, enforcement-tests CI, pr-policy |

## Goal

Make Engineering OS install project-scoped MCP server profiles automatically so Claude Code / MCP-aware LLM sessions opened in a governed project can discover configured MCP servers from `.mcp.json`.

## Plan

1. Commit this Route Plan before any code/config/test change.
2. Add `templates/connectors/engineering-os-mcp.json` with safe project-scoped MCP profiles.
3. Add `scripts/install-mcp-servers.sh` to merge the profiles into target `.mcp.json`.
4. Wire `scripts/use-in-project.sh` to run the MCP installer.
5. Update registry and docs so policy matches the new auto-install behavior.
6. Add deterministic tests for template shape, merge behavior, idempotency, backup creation, and invalid-config fail-closed behavior.
7. Update this plan with mid and pre-merge lifecycle evidence after implementation and validation.

## Alternatives

- Install account credentials automatically — rejected. Account access remains outside git and is completed by the operator in Claude Code or local environment setup.
- Install only GitHub MCP — rejected. The requirement is broad MCP availability, so the default profiles include native safe profiles plus fallback coverage.
- Add write-capable GitHub profiles — rejected. The current safe default remains read-only; write profiles require a separate explicit PR and approval.

## Capability Evidence

- `registry.service-connector-selected` — connector inventory and registry were read before changing MCP behavior.
- `registry.mcp-connector-selected` — the registry's 12 MCP connectors are mapped to installed profiles or fallback coverage.
- `validation.no-broad-mcp-default` — GitHub stays read-only and broad toolsets remain forbidden.
- `validation.mcp-opt-in-only` — approval stays operator-controlled; the project installs configuration.
- `validation.profile-shape-checked` — the new test validates profile shape and installer behavior.

## Connector Evidence

- github: read repository files and prior PR state before editing.
- context7: Claude Code MCP documentation was checked for project-scoped `.mcp.json`, `/mcp`, approval, and environment-variable behavior.

## Connector Selection Waiver

Notion is normally required for non-trivial governance work, but the Notion MCP is not authenticated for this remote session. This plan file is the approved fallback spec/progress record for the change.

## Connector Usage Evidence

- source: GitHub repository files `.mcp.json`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `scripts/use-in-project.sh`, `templates/connectors/github-readonly.json`, `docs/operations/active-mcp-verification.md`.
- action: checked current project MCP configuration and confirmed `.mcp.json` only contained `nemotron`; checked the GitHub read-only template and active MCP runbook.
- result: GitHub showed `.mcp.json` and `templates/connectors/github-readonly.json` as the concrete existing profiles; `core/capability-registry.yaml` had `mcp_auto_install_allowed: false`.
- decision: selected a safe project-scoped MCP auto-install change while keeping account approval manual.
- target: `templates/connectors/engineering-os-mcp.json`, `scripts/install-mcp-servers.sh`, `scripts/use-in-project.sh`, `scripts/enforcement/tests/test-mcp-auto-install.sh`, `scripts/enforcement/tests/test-active-mcp-verification.sh`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`.

## Skill Evidence

- superpowers: used the Engineering OS loop shape — plan first, implement, verify, self-review — as the orchestration method for this governance change.

## Documentation Asset Evidence

- source: `core/mcp-servers.md`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`, `core/capability-registry.yaml`.
- action: checked the existing MCP docs and registry before changing connector behavior.
- result: the docs still described manual/opt-in behavior and the active MCP runbook still rejected target `.mcp.json` auto-install.
- decision: updated the docs and registry so the documented contract matches the new installer behavior.
- target: `core/mcp-servers.md`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`, `core/capability-registry.yaml`.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/connector-policy.md | checked |
| core/mcp-servers.md | checked |
| core/capability-registry.yaml | checked |
| .mcp.json | checked |
| templates/connectors/github-readonly.json | checked |
| docs/operations/active-mcp-verification.md | checked |
| scripts/use-in-project.sh | checked |

## Claude Run Trace

- goal: install MCP server profiles automatically into governed target projects while preserving read-only/default-safety boundaries.
- hypothesis: project-scoped `.mcp.json` can provide default MCP discovery for Claude Code without committing account access.
- connectors: github repository reads and Context7/Claude Code MCP docs informed the implementation.
- steps: create plan; add MCP profile template; add installer; wire target installation; update registry/docs/tests; validate; open PR.
- evidence: this plan, installer/test files, registry/docs updates, and PR CI.
- rejected: auto-writing account access, broad GitHub toolsets, write-capable GitHub defaults, and documentation-only connector readiness.
- result: recorded in Progress Lifecycle Evidence.
- follow-up: live `/mcp` authentication and smoke checks remain per target project.

## Progress Lifecycle Evidence

- start: Route Plan committed before the first code/config/test change on `claude/auto-mcp-install-clean`; source files and MCP docs were checked before selecting the implementation path.

## Definition of Done

- [x] Route Plan exists before code/config/test changes.
- [ ] MCP profile file exists and validates as JSON.
- [ ] Installer creates/merges `.mcp.json` safely.
- [ ] `use-in-project.sh` invokes the MCP installer.
- [ ] Docs no longer imply MCP is documentation-only.
- [ ] Test covers template shape, merge behavior, repeatability, and invalid-config failure.
- [ ] GitHub Actions pass on the PR.
- [ ] Owner approves merge.
