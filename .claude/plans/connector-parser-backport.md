# Plan: Connector Parser Backport

## Route Plan

| Field | Value |
|---|---|
| Task type | CI policy hardening |
| Domain tags | connectors, route-plan, GitHub Actions |
| Templates | `.github/workflows/connector-evidence-policy.yml` |
| Architecture guides | Engineering OS connector policy |
| Patterns | Connector evidence gate |
| External systems/connectors | none |
| Skills | superpowers-verify |
| Validation gates | GitHub Actions, CodeRabbit |

## Goal

Backport the connector route-plan parser fixes proven in the target project back into Engineering OS.

## Connector Evidence

- [x] External systems/connectors: none.
- [x] This is CI policy hardening only.
- [x] No new external service, credential, API call, or runtime integration is added.

## Validation

- [x] Keep the workflow target-safe.
- [x] Keep code/config changes paired with this Route Plan.
- [x] Run GitHub Actions and CodeRabbit before merge.
