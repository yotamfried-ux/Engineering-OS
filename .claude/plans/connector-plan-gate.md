# Plan: Connector Route Plan Gate

## Route Plan

| Field | Value |
|---|---|
| Task type | CI policy / connector enforcement |
| Domain tags | connectors, governance, GitHub Actions, Route Plan |
| Templates | `.github/workflows/connector-evidence-policy.yml` |
| Architecture guides | Engineering OS connector policy |
| Patterns | Policy gate / explicit external-system declaration |
| External systems/connectors | none |
| Skills | `superpowers-verify` |
| Validation gates | `scripts/enforcement/tests/test-connector-evidence.sh`, GitHub Actions |

## Goal

Close the main connector-enforcement bypass: code-changing PRs must not be able
to avoid declaring external connector usage simply by omitting a Route Plan.

## Connector Evidence

- [x] External systems/connectors: none.
- [x] This change modifies Engineering OS policy gates and tests only.
- [x] No new external API, credential, MCP, SaaS, or runtime integration is introduced.
- [x] GitHub Actions is the existing enforcement surface already used by Engineering OS.

## Requirements

- [x] If a PR changes code/config/script files, it must include a changed `.claude/plans/*.md` Route Plan.
- [x] Every changed Route Plan must include an `External systems/connectors` field.
- [x] If `External systems/connectors` is anything other than an explicit no-connector value, the plan must include a real `## Connector Evidence` heading.
- [x] A loose mention such as `TODO: add Connector Evidence` must not pass.
- [x] The policy must remain target-safe and self-contained in the workflow.

## Validation

- [x] Add/update shell tests for positive and negative cases.
- [x] Confirm GitHub Actions pass on the PR.
- [x] Confirm CodeRabbit has no actionable comments before merge.
