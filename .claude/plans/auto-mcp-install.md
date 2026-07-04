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

Install project-scoped MCP server profiles into governed target projects so MCP-aware clients can discover the configured connectors from `.mcp.json`.

## Plan

1. Commit this Route Plan before code/config/test changes.
2. Add a safe MCP profile bundle.
3. Add an installer that merges the bundle into target `.mcp.json`.
4. Wire `use-in-project.sh` to run the installer.
5. Update registry, docs, and verification tests.

## Alternatives

- Install credentials automatically — rejected because credentials stay local.
- Install only GitHub — rejected because the connector registry needs broad discovery.
- Add write-capable GitHub defaults — rejected because GitHub remains read-only by default.

## Capability Evidence

- `registry.service-connector-selected` — connector registry checked.
- `registry.mcp-connector-selected` — MCP registry checked.
- `validation.no-broad-mcp-default` — GitHub default remains read-only.
- `validation.mcp-opt-in-only` — access approval stays operator-controlled.
- `validation.profile-shape-checked` — tests validate profile shape and installer behavior.

## Connector Evidence

- github: repository files and previous PR state checked before editing.
- context7: Claude Code MCP behavior checked before selecting project-scoped `.mcp.json`.

## Connector Selection Waiver

Notion progress tracking is unavailable in this remote session, so this plan file is the workflow fallback record.

## Connector Usage Evidence

- source: `.mcp.json`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `scripts/use-in-project.sh`, `templates/connectors/github-readonly.json`, `docs/operations/active-mcp-verification.md`.
- action: checked existing MCP state and connector policy before changing installer behavior.
- result: the old state had no target-project auto-install contract.
- decision: selected project-scoped MCP profile installation while keeping runtime approval separate.
- target: `templates/connectors/engineering-os-mcp.json`, `scripts/install-mcp-servers.sh`, `scripts/use-in-project.sh`, `scripts/enforcement/tests/test-mcp-auto-install.sh`, `scripts/enforcement/tests/test-active-mcp-verification.sh`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`.

## Skill Evidence

- superpowers: used plan-first, implement, verify, self-review workflow shape.

## Documentation Asset Evidence

- source: `core/mcp-servers.md`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`, `core/capability-registry.yaml`.
- action: checked existing MCP docs and registry before changing connector behavior.
- result: the docs described manual behavior while the new requirement needs auto-install.
- decision: updated docs and registry to match the installer contract.
- target: `core/mcp-servers.md`, `docs/operations/connector-verification-matrix.md`, `docs/operations/active-mcp-verification.md`, `core/capability-registry.yaml`.

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
- rejected: credentials in git, broad GitHub defaults, write-capable GitHub defaults.
- result: lifecycle evidence below records implementation progress.
- follow-up: live MCP approval and smoke checks remain per target project.

## Progress Lifecycle Evidence

- start: Route Plan committed before the first code/config/test change on the clean branch.
- mid: implementation commits added the MCP profile bundle, installer, target wiring, tests, registry update, and connector documentation update after the Route Plan commit.

## Definition of Done

- [x] Route Plan exists before code/config/test changes.
- [x] MCP profile file exists and validates as JSON by test coverage.
- [x] Installer creates and merges `.mcp.json` by test coverage.
- [x] `use-in-project.sh` invokes the MCP installer.
- [x] Docs no longer describe MCP as documentation-only.
- [x] Test covers template shape, merge behavior, repeatability, and invalid-config failure.
- [ ] GitHub Actions pass on the PR.
- [ ] Owner approves merge.
