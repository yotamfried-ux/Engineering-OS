---
name: engineering-route
description: Use before Engineering OS repository changes to route the task, identify required sources, and create a plan before editing files.
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Engineering Route

Use this package before implementation work in an Engineering OS repository or target project.

This package does not replace runtime gates. It packages the routing workflow in a standard Claude skill shape so the route workflow can load selectively.

## Required inputs

- The user's current task.
- The target repository or project name.
- Any known PR, branch, issue, or spec reference.

## Procedure

1. Read `core/task-router.md`.
2. Read `core/workflow.md`.
3. Check `docs/research/official-patterns-adoption-audit.md` when the work changes skills, hooks, connectors, evals, or managed settings.
4. Identify the task class and domain tags.
5. Identify required source-of-truth checks.
6. Identify required connectors and skills, or document an explicit waiver.
7. Create a route plan under `.claude/plans/` before editing implementation files.
8. Keep unfinished validation outside the plan checklist unless it has already been completed.

## Output contract

Create or update a plan that includes these sections:

- Route Plan
- Source of Truth Checks
- Connector Evidence
- Skill Evidence
- Template Gap Waiver, if no template is required
- Scope
- Completed Work
- Remaining Validation Outside This Plan

## Safety rules

- Do not treat a detailed user prompt as a complete spec by itself.
- Do not write code before route planning.
- Do not mark work complete unless evidence exists.
- Do not add broad tool, connector, or skill adoption without a concrete observed failure.
