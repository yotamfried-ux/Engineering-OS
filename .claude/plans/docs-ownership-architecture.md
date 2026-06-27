# Docs Ownership Architecture Cleanup Plan

Created: 2026-06-26
Branch: `docs-ownership-architecture`
Status: in progress

## Task type
Engineering OS maintenance / governance.

## Domain tags
`governance`, `documentation`, `workflow`, `connectors`, `skills`, `validation`.

## Problem
Documentation ownership is not explicit enough. `CLAUDE.md` is the entry point, but several Markdown families can accidentally behave like competing sources of truth: core policy, inventory READMEs, connector docs, templates, operational runbooks, and temporary PR plans.

The target state is a single canonical owner per concept, with index files staying index-only and temporary plans staying temporary.

## Canonical route
- Entry point: `CLAUDE.md`
- Workflow: `core/workflow.md`
- Routing: `core/task-router.md`
- Documentation ownership: `core/documentation-policy.md`
- Capability routing vocabulary: `core/capability-registry.yaml`
- Skill integration policy: `core/skill-orchestration-policy.md`
- Connector policy: `core/connector-policy.md`

## Scope
1. Strengthen `core/documentation-policy.md` with an explicit ownership map.
2. Keep `external-systems/README.md` as inventory only and point policy decisions back to `core/`.
3. Keep `external-skills/README.md` as inventory only, separate active skills from deprecated/replaced items and adjacent accelerators.
4. Clarify `CLAUDE.md` navigation so the entry point routes to owners without duplicating detailed policy.
5. Add deterministic documentation ownership validation.

## Out of scope
- No merge to `main` without explicit user approval.
- No deletion of large documentation families in this PR.
- No runtime capability-registry enforcement beyond documentation-boundary validation.
- No vendor documentation rewrite.

## Validation plan
- Add or update shell validators under `scripts/enforcement/tests/`.
- Verify the validators are discoverable from the existing enforcement test structure.
- Open PR for GitHub Actions and CodeRabbit review.
