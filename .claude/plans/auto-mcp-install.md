# Auto-install MCP servers for governed projects

| Field | Value |
|---|---|
| Task class | mcp_or_connector_config |
| Task type | governance, connector-config |
| Domain tags | mcp, connectors, claude-code, installer, documentation |
| Task-router evidence | core/task-router.md read in this session; task is Engineering OS connector/MCP configuration |
| Workflow evidence | core/workflow.md and core/connector-policy.md read in this session |
| Target paths | templates/connectors/engineering-os-mcp.json, scripts/install-mcp-servers.sh, scripts/use-in-project.sh, scripts/enforcement/tests/test-mcp-auto-install.sh, core/mcp-servers.md, core/capability-registry.yaml, docs/operations/connector-verification-matrix.md |
| Templates | templates/connectors/github-readonly.json checked and reused as the GitHub profile base |
| Patterns | not required |
| External systems/connectors | github, context7 |
| Skills | superpowers |
| Validation gates | bash -n, JSON validation, test-mcp-auto-install.sh, enforcement-tests CI, pr-policy |

## Goal

Make Engineering OS install project-scoped MCP server profiles automatically so any Claude Code / MCP-aware LLM session opened in a governed project has the configured servers available from `.mcp.json` instead of only seeing connector names in documentation.

## Plan

1. Keep the first commit as this Route Plan.
2. Add a canonical MCP profile file under `templates/connectors/engineering-os-mcp.json`.
3. Add `scripts/install-mcp-servers.sh` to merge the profiles into a target project's `.mcp.json` without writing credentials.
4. Wire `use-in-project.sh` to call the MCP installer during normal Engineering OS installation.
5. Keep Engineering OS's root `.mcp.json` unchanged if the platform blocks safe updates; target-project installation is the actual contract.
6. Update connector/MCP documentation to distinguish installed profile, auth-required, Composio-covered, and verified-live.
7. Add deterministic tests for profile shape, merge behavior, idempotency, backup creation, and fail-closed behavior on invalid existing `.mcp.json`.
8. Open a PR and verify CI; no merge without explicit owner approval.

## Alternatives

- Install credentials automatically — rejected. Secrets must remain outside git and must be authenticated through Claude Code `/mcp`, OAuth, environment variables, or local secret stores.
- Install only GitHub MCP — rejected. The user's requirement is broad MCP availability, so the default profiles include native safe profiles plus Composio as fallback coverage.
- Add write-capable GitHub profiles — rejected. The current safe default remains read-only; write profiles require a separate explicit PR and approval.

## Capability Evidence

- `registry.service-connector-selected` — connector inventory and registry were read before changing MCP behavior.
- `registry.mcp-connector-selected` — the registry's 12 MCP connectors are mapped to installed profiles or Composio fallback.
- `validation.no-broad-mcp-default` — GitHub stays read-only and forbids broad toolsets in the test.
- `validation.mcp-opt-in-only` — credentials/approval are still operator-controlled; the project only installs configuration.
- `validation.profile-shape-checked` — `test-mcp-auto-install.sh` validates the profile bundle and installer behavior.

## Connector Evidence

- github: read repository files and prior PR state before editing.
- context7: official Claude Code MCP documentation was checked for project-scoped `.mcp.json`, `/mcp`, approval, and environment-variable behavior.

## Connector Selection Waiver

Notion is normally required for non-trivial governance work, but the Notion MCP is not authenticated for this remote session. This plan file is the approved fallback spec/progress record for the change.

## Connector Usage Evidence

- source: GitHub repository files `.mcp.json`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `scripts/use-in-project.sh`, `templates/connectors/github-readonly.json`, `docs/operations/active-mcp-verification.md`.
- action: checked current project MCP configuration and confirmed `.mcp.json` only contained `nemotron`; checked the GitHub read-only template and active MCP runbook.
- result: GitHub showed `.mcp.json` and `templates/connectors/github-readonly.json` as the concrete existing profiles; `core/capability-registry.yaml` still had `mcp_auto_install_allowed: false`.
- decision: changed the installer and registry so project-scoped MCP profiles are installed automatically while secrets and approval remain manual.
- target: `templates/connectors/engineering-os-mcp.json`, `scripts/install-mcp-servers.sh`, `scripts/use-in-project.sh`, `scripts/enforcement/tests/test-mcp-auto-install.sh`, `core/mcp-servers.md`, `core/capability-registry.yaml`, `docs/operations/connector-verification-matrix.md`.

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
| Claude Code MCP docs | checked |

## Definition of Done

- [x] MCP profile file exists and validates as JSON.
- [x] Installer creates/merges `.mcp.json` without secrets.
- [x] `use-in-project.sh` invokes the MCP installer.
- [x] Docs no longer imply MCP is documentation-only.
- [x] Test covers template shape, merge behavior, repeatability, and invalid-config failure.
- [ ] GitHub Actions pass on the PR.
- [ ] Owner approves merge.
