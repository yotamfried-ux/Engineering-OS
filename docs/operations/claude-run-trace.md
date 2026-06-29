# Claude Run Trace

Engineering OS already mentions run traces in `core/learning-loop.md`. This guide makes the practice explicit so the user can inspect what Claude tried, what evidence was collected, and what changed in the system afterward.

## When to record a trace

Record a trace for:

- enforcement-loop simulations;
- workflow experiments;
- connector-selection decisions;
- multi-step debugging or validation runs;
- any run that should teach future agents how the system behaved.

## Where traces live

Use the smallest durable location that fits the result:

| Location | Use |
|---|---|
| `.claude/tasks.json` | Active task/agent status. |
| `.claude/plans/<task>.md` | Plan, checkpoints, and DoD. |
| `lessons-learned/bugs/*.md` | Verified reusable bug knowledge. |
| `failed-solutions/*.md` | Tried approach that should not be repeated. |
| `docs/operations/*.md` | Reusable operational procedure or audit summary. |

## Required fields

A useful trace records:

- goal;
- hypothesis;
- tools/connectors used;
- ordered steps;
- evidence collected;
- attempts rejected;
- final result;
- follow-up enforcement or documentation.

## Notion progress validation

For non-trivial work, a Route Plan alone is not enough. Notion must be used as the user-facing progress/spec tracker when available.

Required checkpoints:

1. before implementation — spec/task exists or fallback is documented;
2. during work — status/progress is re-read or updated;
3. before merge — final status and remaining gaps are reflected.

The expected runtime evidence key is `notion_progress_validated`.

## Relationship to learning

A run trace is not a replacement for a lesson. If a run produces verified reusable bug knowledge, create a proper `lessons-learned/bugs/*.md` entry. If it records a rejected approach, create a `failed-solutions/*.md` entry as well.

## Enforcement contract

`enforce-run-trace.sh` blocks staged enforcement, connector, settings, workflow, or simulation changes unless the active Route Plan contains `## Claude Run Trace`.

The trace must include these fields: goal, hypothesis, connectors/tools, steps, evidence, rejected attempts, result, and follow-up enforcement.

Connector-related changes have an extra requirement: the trace must name the connector decision/evidence and mention `notion_progress_validated` when Notion progress tracking is part of the workflow.

The trace can be waived only with a focused `## Run Trace Waiver` section in the active Route Plan, and only when the change is mechanical and produces no reusable experiment/process knowledge.
