# Operational Work History

Status: foundation (Stage 1 of `docs/operations/operational-work-history-rollout.md`)
Owner: ops-readiness
Tracking gap: `operational-work-history-foundation` in `docs/operations/known-gaps.tsv`

Purpose: answer the operational questions Engineering OS needs about a PR — what ran, what tools
and connectors were used, what CI did, where friction happened — from **automatic sources**
wherever possible, instead of forcing Claude to manually restate data that tool calls, hooks, CI,
and git metadata already contain. This document is the source-of-truth schema and architecture. It
does not claim monitoring sufficiency; see `docs/operations/runtime-telemetry-archive-plan.md` for
that separate, still-open gap.

## Decision this document records

`docs/operations/known-gaps.tsv` row 27 (`result-loop-contract-enforcement`) left one dimension
open: whether `check-route-plan-contract.sh` — which would require every Route Plan touching
code/config/test targets to manually declare 8 fields (`selected_project_type`,
`selected_template`, `selected_roadmap`, `selected_result_loop_contract`,
`required_user_simulation`, `local_creator_review_path`, `telemetry_export_path`,
`evidence_policy_rule`) — should be wired into CI. The decision: **no**. That checker stays unwired,
by design, not by oversight. Route Plan is not expanded into a heavier manual-reporting burden.

A real `chatgpt-codex-connector` review on PR #237 correctly found that, at that point, this document's
artifact/gate did **not** actually cover the per-PR `selected_result_loop_contract` declaration
dimension — it only covered `automatic_sources:` and learning-loop routing, so closing
`operational-work-history-foundation` had not closed `result-loop-contract-enforcement`. The
"Result-loop contract selection" section below is the fix for that specific finding: one deterministic,
mostly-derived, machine-readable field — not a revival of the 8-field Route Plan requirement.

## Two existing layers this builds on, not replaces

1. **Telemetry** (`docs/operations/runtime-telemetry-archive-plan.md`,
   `scripts/monitoring/eos-telemetry-event.sh`) — already captures tool/command/session/hook facts
   from Claude Code hooks, metadata-only, into `.engineering-os/telemetry/events.jsonl`. This
   document does not duplicate that recorder; it correlates its output with a specific PR.
2. **Learning loop** (`core/learning-loop.md`) — already the schema-enforced surface for judgment
   that cannot be observed: root cause, evidence, confidence, prevention, lessons learned. This
   document does not add a second free-text judgment field; it routes to this existing surface (see
   "Learning-loop routing" below).

## Question-to-source mapping

| Operational question | Source | Where it lives |
|---|---|---|
| What task was attempted? | git | commit count plus hashed commit-subject metadata; raw commit subjects are only used transiently for friction heuristics |
| Which PR/branch/commit/gap? | git + GitHub | `pr_head_sha`, `checked_out_sha`, `base_sha`, branch, best-effort `gap_id` in the artifact |
| Which files were read? | telemetry (when available) | `.engineering-os/telemetry/events.jsonl` tool/path counters, same-workspace only |
| Which files were edited? | git | changed-file count plus hashed/bucketed path metadata in the artifact; raw paths are only used transiently for counts/hashes |
| Which tools were called? | telemetry (when available) | `eos.tool.name` counters reused from `eos-telemetry-summary.py` |
| Which MCP/connectors were used? | telemetry (when available) | `mcp__` prefixed tool names in the same counters |
| Which skills were activated? | telemetry (when available) | tool/command-category counters; best-effort, not a dedicated skill signal yet |
| Which shell commands were run? | telemetry (when available) | `eos.tool.command.category` counters (hashed, not raw commands) |
| Which tests were run? | telemetry (when available) | `test` command category counter |
| Which CI jobs failed or passed? | GitHub | `ci.json` snapshot (job name + conclusion), point-in-time, `pending`/`in_progress` allowed |
| How many cycles before green? | git | fix/retry/revert commit-message heuristic (friction signal), computed from raw subjects transiently and stored only as a count |
| Which review comments affected the work? | GitHub | `reviews.json` snapshot; `review_metadata_unavailable=true` if unfetchable |
| Which gates fired? | CI | `ci.json` job list |
| Which gates were missing/unwired? | this doc + known-gaps.tsv | not automatic — tracked as a governance gap, not an artifact field |
| Where did the model encounter friction? | git + CI (computed) + learning loop | friction signals computed in the artifact; interpretation routed to `learning_loop_artifact`/`learning_loop_result` |
| False positives/negatives | learning loop | `lessons-learned/bugs/*.md` or `failed-solutions/*.md`, referenced via `learning_loop_artifact:` |
| What system improvement should be fed back? | learning loop | same lesson/failed-solution file's prevention/next-improvement content |

Every "automatic" row above is computed by `scripts/monitoring/collect-pr-work-history.py` and
written to `.engineering-os/work-history/latest.json` (never committed — see below). Every
"learning loop" row is answered by an existing, schema-enforced file under `lessons-learned/` or
`failed-solutions/`, referenced from the PR body — never restated as new free-text.

## The artifact (source of truth, not the PR body)

`.engineering-os/work-history/latest.json` + `latest-summary.md` are generated fresh, in the CI
workspace, on every `pr-policy` run (see `.github/workflows/pr-policy.yml`). They are **build
products**: `.gitignore`d, never committed, and the gate hard-fails if a PR diff ever touches them.
The PR body only carries a pointer:

```
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_artifact: lessons-learned/bugs/<file>.md
```

or, when no reusable lesson resulted from this PR:

```
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_result: none-with-reason — <short, concrete reason>
```

The checker (`scripts/enforcement/check-operational-work-history-evidence.sh`) reads the artifact
directly and computes every count itself — Claude never hand-types `changed_files=<n>` or
`telemetry_events=<n>` in prose. See `scripts/enforcement/check-operational-work-history-evidence.sh`
for the full validation rules, including `pr_head_sha` matching, dummy/placeholder detection,
artifact count matching against workflow changed-file metadata, and fail-closed behavior when
changed-file metadata is unavailable or empty.

## Exemption policy

Stage 1 intentionally has **no automatic filename-only exemption**. A previous design considered a
single-file non-governance exemption for typo-only changes, but filename-only classification is too
weak: a real code/config change can also be a single non-governance file. Until Engineering OS has a
reliable diff-aware classifier that proves a change is genuinely non-normative wording/comment-only,
any PR with changed files requires Operational Work History Evidence. This keeps the gate scalable
by making the evidence cheap and automatic rather than by allowing bypass paths that cannot be
verified.

## Learning-loop routing

Observable facts live in the artifact automatically. Non-observable judgment (reasoning, lessons
learned, calibration notes, false-positive interpretation, next system improvement) already has a
dedicated, schema-enforced surface: `core/learning-loop.md`. The gate computes **friction signals**
from the artifact — CI failures, `fix`/`retry`/`revert` commit-message patterns, unavailability
markers, waiver mentions — and when any are present, requires either a real
`learning_loop_artifact:` (an existing file satisfying the required-heading schema already enforced
by `enforce-learning.sh`) or a `learning_loop_result: none-with-reason` whose reason concretely
addresses the observed signal. This is additive to, not a replacement for, the existing local
`enforce-learning-capture.sh` pre-commit gate (which stays keyed off Route Plan task class); this
PR-level check is keyed off what the artifact actually observed.

## Privacy contract

Identical to the existing telemetry privacy contract in `runtime-telemetry-archive-plan.md`:
metadata-only. No raw model/user text, file contents, raw shell commands, raw repository paths,
connector payloads, environment values, or credentials/secrets anywhere in the artifact. Repository
paths and commit subjects are used transiently inside the CI workspace to compute counts, hashes,
buckets, and friction heuristics; the persisted artifact stores hashed/bucketed path metadata and
commit-subject hashes, not the raw values.

## Result-loop contract selection

`docs/operations/known-gaps.tsv` row 27 (`result-loop-contract-enforcement`) stayed open after a real
`chatgpt-codex-connector` review on PR #237 found that everything above — `automatic_sources:` and
`learning_loop_artifact:`/`learning_loop_result:` — never asked a PR to declare **which result-loop
contract governs the change** (`selected_result_loop_contract`). This section closes that specific
blind spot without reintroducing `check-route-plan-contract.sh`'s 8-field Route Plan requirement.

**When it is required.** Any PR with changed files requires a resolved `selected_result_loop_contract`,
with exactly one narrow exception: a true empty diff (`empty_run`/zero changed files). This mirrors
Stage 1's own no-automatic-filename-exemption rule above — there is no broad `docs/*` or filename-only
carve-out for this dimension either.

**How it is resolved.** `scripts/monitoring/collect-pr-work-history.py` classifies every changed path
into one of three buckets, deliberately **not** a blanket "anything that isn't `templates/<id>/` is
governance" rule — this same collector is also installed into downstream target projects
(`policy-gate-dependencies.tsv`), where ordinary application source (e.g. `src/App.tsx`) must not
silently resolve to Engineering OS's own governance sentinel instead of that project's real contract:

1. A path under `templates/<alias>/...` where `<alias>` is a real template alias of some
   `project_type_id` in `project-type-roadmaps.tsv`'s `template_path` column (a project type can list
   more than one alias — e.g. `ai-agent` claims both `templates/ai-agent` and `templates/rag-system` —
   and a template shared across types, like `templates/web-application` under both `web-application`
   and `full-stack`, resolves to the type that claims it exclusively) maps to that project type.
2. A path matching a known Engineering OS governance/tooling prefix (`scripts/`, `core/`, `docs/`,
   `.github/`, `.claude/`, `templates/` itself, `external-skills/`, `external-systems/`, `patterns/`,
   `lessons-learned/`, `failed-solutions/`, `architecture-decisions/`, `evals/`, or
   `README.md`/`CHANGELOG.md`/`LICENSE`/`CLAUDE.md`) maps to one non-scaffolded sentinel id,
   `engineering-os-governance` (added to `result-loop-requirements.tsv` and `project-type-roadmaps.tsv`
   with `status=exempt`, so it registers a real, non-placeholder contract row without pulling
   `check-scaling-extension.py`'s active-project documentation/pattern/skill coverage requirements onto
   a project type that isn't actually scaffolded).
3. Anything else — most importantly, ordinary application source that isn't under a recognized
   template or governance path — is left **unclassified** rather than folded into either bucket.

- If every changed path resolves to bucket 1 or 2, and they all agree on exactly **one** candidate id,
  the collector **derives** the contract — no PR-body field needed. This covers the overwhelming
  majority of real PRs, including every PR in this repository's own governance-tooling surface.
- If changed paths imply **more than one** candidate, or include any unclassified (bucket 3) path (for
  example a PR that touches both `templates/web-application/...` and an Engineering OS enforcement
  script, or a downstream target project's own `src/` alongside its copied policy-gate scripts), the
  collector looks for a minimal structured field under `## Operational Work History Evidence`:

  ```yaml
  selected_result_loop_contract: <contract-id>
  ```

  Whenever the candidate set is fully known (no unclassified path), the declared id must be a real
  `project_type_id` from `result-loop-requirements.tsv` **and** one of the actual candidates implied by
  the diff — a valid-but-unrelated id (e.g. declaring `cli-tool` on a PR that only touches
  `web-application`/governance paths) is rejected, not just any known id. When an unclassified path
  exists, the candidate set is incomplete by construction, so any real, non-placeholder manifest id is
  accepted — the same trust boundary the old, never-wired 8-field Route Plan checker used. Missing,
  placeholder (`todo`/`tbd`/`unknown`/`n/a`/`none`/`later`/...), or unknown-id declarations all fail
  closed with a concrete `ERROR_FOR_AGENT`.

**How it is validated.** `scripts/enforcement/check-operational-work-history-evidence.sh` reads the
artifact's `result_loop_contract` object directly — it never re-parses the PR body for this field. This
is what guarantees a PR body cannot override the checker: only the CI-regenerated artifact (already
SHA-matched against the real PR head) decides.

**Artifact shape** (`.engineering-os/work-history/latest.json`):

```json
"result_loop_contract": {
  "required": true,
  "selection_source": "derived",
  "selected_result_loop_contract": "engineering-os-governance",
  "validation_status": "valid",
  "matched_manifest_row": "scripts/enforcement/result-loop-requirements.tsv#engineering-os-governance",
  "reason": "deterministically derived: all N changed path(s) map to exactly one result-loop contract (engineering-os-governance)."
}
```

`selection_source` is one of `derived` / `declared` / `ambiguous` (no declaration found) /
`not_required` (empty diff) / `manifest_unavailable` (defensive — the manifest was not found next to
the collector script, e.g. an installed downstream target project that has not re-run
`install-policy-gates.sh` since this dimension shipped). `validation_status` is one of `valid` /
`missing` / `unknown_id` / `placeholder` / `invalid` (declared but unrelated to the diff) /
`not_applicable` (not required) / `unavailable`. Only ids, short reason sentences, and a manifest row
reference are stored — no raw paths or prose, consistent with the metadata-only privacy contract above.

**What this does not claim.** `check-route-plan-contract.sh` stays unwired by design — this is not a
disguised revival of its 8-field requirement, only one machine-readable field, required only when
derivation is ambiguous. Deep judgment about whether the *content* of a result-loop contract is truly
adequate for a given change stays out of scope, same as every other "structural, not semantic" gate in
this repository; this only proves a PR names a real, diff-relevant contract id.

## What this does NOT claim

- Does not claim `monitoring-metrics-sufficiency` (open) or `project-8-real-run-evidence` (blocked)
  are closed — those require a real target-project run, not this foundation.
- Does not, by itself, close `result-loop-contract-enforcement` — this document is the design and
  implementation description; closure requires real positive **and** real negative PR evidence per
  `docs/operations/operational-work-history-rollout.md`'s evidence-log convention, tracked in
  `docs/operations/known-gaps.tsv` row 27.
- Does not claim universal automatic tools/connectors/skills capture: CI can always compute
  git/GitHub facts, but seeing Claude's local telemetry requires the same-workspace handoff
  described in `docs/operations/operational-work-history-rollout.md` (Stage 1.5), which only works
  when Claude's environment and the CI runner share a channel.
- Does not close `operational-work-history-foundation` after this PR — see the closure bar recorded
  in `docs/operations/known-gaps.tsv`.

## Official documentation referenced

| Source | Why it matters | Design implication |
|---|---|---|
| Claude Code monitoring/OpenTelemetry: `https://code.claude.com/docs/en/monitoring-usage` | Documents usage/cost/tool-activity/metrics/event/log/trace telemetry Claude Code can export. | Confirms the existing `eos.telemetry.v1` OTel-shaped schema is the right foundation to correlate, not replace. |
| Claude Code hooks: `https://code.claude.com/docs/en/hooks` | Hooks run on session lifecycle and every tool call (PreToolUse/PostToolUse), receiving JSON input. | Confirms hook-layer capture (already wired in `.claude/settings.json`) is the correct place for automatic tool/session facts, not scraping generated text. |
| OpenAI Agents SDK tracing: `https://openai.github.io/openai-agents-python/tracing/` | Traces/spans as the standard way to understand agent run behavior. | Reinforces the artifact's span/trace-shaped structure over free-text self-reporting. |
| Microsoft Foundry tracing: `https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/trace-application` | OpenTelemetry-based application tracing pattern for AI apps. | Same pattern applied here: correlate trace/session data with the concrete unit of work (a PR), not just log it locally. |
| Google ADK observability: `https://adk.dev/observability/` | Process-level observability (not just final-output checking) is the correct pattern for agent systems. | Directly motivates gating on the artifact (process evidence) instead of a PR-body claim (output-only self-report). |

Related internal docs: `docs/operations/runtime-telemetry-archive-plan.md` (telemetry capture/export/
import this artifact correlates), `docs/operations/result-loop-contract-plan.md` (the Route Plan
decision this document supersedes for the per-PR declaration dimension), `core/learning-loop.md`
(the judgment-routing surface).