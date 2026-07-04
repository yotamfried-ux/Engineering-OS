# Auto-install MCP servers for governed projects

| Field | Value |
|---|---|
| Task class | mcp_or_connector_config |
| Task type | governance, connector-config |
| Domain tags | mcp, connectors, claude-code, installer, documentation |
| Task-router evidence | core/task-router.md read before writes |
| Workflow evidence | core/workflow.md and core/connector-policy.md read before writes |
| Target paths | templates/connectors/engineering-os-mcp.json, scripts/install-mcp-servers.sh, scripts/use-in-project.sh, scripts/enforcement/tests/test-mcp-auto-install.sh, scripts/enforcement/tests/test-active-mcp-verification.sh, core/mcp-servers.md, core/capability-registry.yaml, docs/operations/connector-verification-matrix.md, docs/operations/active-mcp-verification.md |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github, context7 |
| Skills | superpowers |
| Validation gates | bash -n, JSON validation, test-mcp-auto-install.sh, test-active-mcp-verification.sh, enforcement-tests CI, pr-policy |

## Goal

Install project-scoped MCP server profiles into governed target projects so MCP-aware clients can discover configured connectors from `.mcp.json`.

## Capability Evidence

- `registry.service-connector-selected` — connector registry checked.
- `registry.mcp-connector-selected` — MCP registry checked.
- `validation.no-broad-mcp-default` — GitHub default remains read-only.
- `validation.mcp-opt-in-only` — runtime approval stays separate.
- `validation.profile-shape-checked` — tests validate profile shape and installer behavior.
- `validation.policy-change-has-validator` — `scripts/enforcement/tests/test-mcp-auto-install.sh` and `scripts/enforcement/tests/test-active-mcp-verification.sh` validate this policy/config change.

## Connector Evidence

- github: repository files and previous PR state checked before editing.
- context7: Claude Code MCP behavior checked before selecting project-scoped `.mcp.json`.

## Connector Selection Waiver

Notion progress tracking is unavailable in this remote session, so this plan file is the workflow fallback record.

## Connector Usage Evidence

- source: github repository `yotamfried-ux/Engineering-OS` files and context7 Claude Code MCP documentation.
- action: github file reads checked `.mcp.json`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `scripts/use-in-project.sh`, `templates/connectors/github-readonly.json`, and `docs/operations/active-mcp-verification.md`; context7 checked project-scoped MCP behavior.
- result: github showed paths `templates/connectors/github-readonly.json`, `scripts/use-in-project.sh`, `core/capability-registry.yaml`, and `docs/operations/active-mcp-verification.md`; context7 confirmed `.mcp.json` as the project-scoped MCP configuration file.
- decision: selected and implemented project-scoped MCP profile installation through `scripts/install-mcp-servers.sh`, updated registry/docs, and kept runtime approval separate.
- target: `templates/connectors/engineering-os-mcp.json`, `scripts/install-mcp-servers.sh`, `scripts/use-in-project.sh`, `scripts/enforcement/tests/test-mcp-auto-install.sh`, `scripts/enforcement/tests/test-active-mcp-verification.sh`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`.

## Skill Evidence

- superpowers: used plan-first, implement, verify, self-review workflow shape.

## Documentation Asset Evidence

- internal: `core/mcp-servers.md`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`, `core/capability-registry.yaml`, `scripts/use-in-project.sh`, `templates/connectors/github-readonly.json`.
- context7: Claude Code MCP documentation for project-scoped `.mcp.json`, server list/status commands, and local approval behavior.
- decision: internal docs and Context7 confirmed that the correct contract is project-scoped MCP configuration plus per-project runtime approval, so the docs and registry were updated to match the new installer behavior.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/connector-policy.md | checked |
| core/mcp-servers.md | checked |
| core/capability-registry.yaml | checked |
| templates/connectors/github-readonly.json | checked |
| docs/operations/active-mcp-verification.md | checked |
| scripts/use-in-project.sh | checked |

## Claude Run Trace

- goal: install MCP server profiles automatically into governed target projects.
- hypothesis: project-scoped `.mcp.json` provides connector discovery without storing credentials.
- connectors: github and context7 informed the implementation.
- steps: plan, profile bundle, installer, use-in-project wiring, docs, tests, PR validation.
- evidence: installer files, test files, registry docs, PR CI.
- rejected: broad GitHub defaults and write-capable GitHub defaults.
- result: lifecycle evidence below records implementation progress.
- follow-up: live MCP approval and smoke checks remain per target project.

## Progress Lifecycle Evidence

- start: Route Plan committed before the first code/config/test change on the clean branch.
- mid: implementation commits added the MCP profile bundle, installer, target wiring, tests, registry update, and connector documentation update after the Route Plan commit.
- pre-merge: branch history checked after the profile/test alignment fix and scoped to MCP installer, registry, documentation, and verification test files.

## Definition of Done

- [x] Route Plan exists before code/config/test changes.
- [x] MCP profile file exists and validates as JSON by test coverage.
- [x] Installer creates and merges `.mcp.json` by test coverage.
- [x] `use-in-project.sh` invokes the MCP installer.
- [x] Docs no longer describe MCP as documentation-only.
- [x] Test covers template shape, merge behavior, repeatability, and invalid-config failure.
