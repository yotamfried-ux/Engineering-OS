# Auto-install MCP servers for governed projects

| Field | Value |
|---|---|
| Task class | mcp_or_connector_config |
| Task type | governance, connector-config |
| Domain tags | mcp, connectors, claude-code, installer, documentation |
| Task-router evidence | core/task-router.md read before writes |
| Workflow evidence | core/workflow.md and core/connector-policy.md read before writes |
| Target paths | templates/connectors/engineering-os-mcp.json, scripts/install-mcp-servers.sh, scripts/install-policy-gates.sh, scripts/capability-verify.sh, scripts/enforcement/tests/test-mcp-auto-install.sh, scripts/enforcement/tests/test-active-mcp-verification.sh, scripts/enforcement/tests/test-capability-registry.sh, core/mcp-servers.md, core/capability-registry.yaml, docs/operations/connector-verification-matrix.md, docs/operations/active-mcp-verification.md |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github, context7 |
| Skills | superpowers |
| Validation gates | bash -n, JSON validation, test-mcp-auto-install.sh, test-active-mcp-verification.sh, test-capability-registry.sh, capability report generator, enforcement-tests CI, pr-policy |

## Goal

Install project-scoped MCP server profiles into governed target projects so MCP-aware clients can discover configured connectors from `.mcp.json`.

## Capability Evidence

- `registry.service-connector-selected` — connector registry checked.
- `registry.mcp-connector-selected` — MCP registry checked.
- `validation.no-broad-mcp-default` — GitHub default remains read-only.
- `validation.mcp-opt-in-only` — runtime approval stays separate.
- `validation.profile-shape-checked` — tests validate profile shape and installer behavior.
- `validation.policy-change-has-validator` — `scripts/enforcement/tests/test-mcp-auto-install.sh`, `scripts/enforcement/tests/test-active-mcp-verification.sh`, `scripts/enforcement/tests/test-capability-registry.sh`, and `scripts/capability-verify.sh` validate this policy/config change.

## Connector Evidence

- github: repository files and PR state were checked before editing.
- context7: Claude Code MCP behavior was checked before selecting project-scoped `.mcp.json`.

## Connector Selection Waiver

Notion progress tracking is unavailable in this remote session, so this plan file is the workflow fallback record.

## Connector Usage Evidence

- source: github repository `yotamfried-ux/Engineering-OS` files and context7 Claude Code MCP documentation.
- action: github file reads checked `.mcp.json`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `scripts/use-in-project.sh`, `scripts/install-policy-gates.sh`, `scripts/capability-verify.sh`, `templates/connectors/github-readonly.json`, and `docs/operations/active-mcp-verification.md`; context7 checked project-scoped MCP behavior.
- result: github showed concrete paths `templates/connectors/github-readonly.json`, `scripts/use-in-project.sh`, `scripts/install-policy-gates.sh`, `scripts/capability-verify.sh`, `scripts/enforcement/tests/test-capability-registry.sh`, `core/capability-registry.yaml`, and `docs/operations/active-mcp-verification.md`; context7 confirmed `.mcp.json` as the project-scoped MCP configuration file.
- decision: selected project-scoped MCP profile installation through `scripts/install-mcp-servers.sh`, wired it through `scripts/install-policy-gates.sh` to preserve the main `use-in-project.sh` contract, updated registry/docs/tests, and updated `scripts/capability-verify.sh` so the capability report reads the MCP bundle.
- target: `templates/connectors/engineering-os-mcp.json`, `scripts/install-mcp-servers.sh`, `scripts/install-policy-gates.sh`, `scripts/capability-verify.sh`, `scripts/enforcement/tests/test-mcp-auto-install.sh`, `scripts/enforcement/tests/test-active-mcp-verification.sh`, `scripts/enforcement/tests/test-capability-registry.sh`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`.

## Skill Evidence

- superpowers: used plan-first, implement, verify, self-review workflow shape.

## Documentation Asset Evidence

- internal: `core/mcp-servers.md`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`, `core/capability-registry.yaml`, `scripts/use-in-project.sh`, `scripts/install-policy-gates.sh`, `scripts/capability-verify.sh`, `scripts/enforcement/tests/test-capability-registry.sh`, `templates/connectors/github-readonly.json`.
- context7: Claude Code MCP documentation for project-scoped `.mcp.json`, server list/status commands, and local approval behavior.
- decision: internal docs and Context7 confirmed that the correct contract is project-scoped MCP configuration plus per-project runtime approval, so the docs, registry, installer, target setup wiring, capability report generator, and registry validator were updated to match the new behavior.

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
| scripts/install-policy-gates.sh | checked |
| scripts/capability-verify.sh | checked |
| scripts/enforcement/tests/test-capability-registry.sh | checked |

## Claude Run Trace

- goal: install MCP server profiles automatically into governed target projects.
- hypothesis: project-scoped `.mcp.json` provides connector discovery without storing credentials.
- connectors: github and context7 informed the implementation.
- steps: plan, profile bundle, installer, target setup wiring, docs, tests, capability report generator fix, PR validation.
- evidence: installer files, test files, capability generator, registry docs, PR CI.
- rejected: broad GitHub defaults, elevated GitHub defaults, and rewriting `use-in-project.sh` beyond the minimal install contract.
- result: lifecycle evidence below records implementation progress.
- follow-up: live MCP approval and smoke checks remain per target project.

## Progress Lifecycle Evidence

- start: Route Plan committed before the first code/config/test change on the clean branch.
- mid: implementation commits added the MCP profile bundle, installer, target wiring, tests, registry update, and connector documentation update after the Route Plan commit.
- pre-merge: restored-contract branch preserves the main `use-in-project.sh` contract; MCP auto-install is wired through `scripts/install-policy-gates.sh`, the capability registry validator was aligned, and the capability report generator was updated to read the MCP bundle after the last code/config/test change.

## Definition of Done

- [x] Route Plan exists before code/config/test changes.
- [x] MCP profile file exists and validates as JSON by test coverage.
- [x] Installer creates and merges `.mcp.json` by test coverage.
- [x] Target setup path invokes the MCP installer through `install-policy-gates.sh`, which is called by `use-in-project.sh`.
- [x] Docs no longer describe MCP as documentation-only.
- [x] Test covers template shape, merge behavior, repeatability, invalid-config failure, registry policy alignment, and capability report bundle coverage.
