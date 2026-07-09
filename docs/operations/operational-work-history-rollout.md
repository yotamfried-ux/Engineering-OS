# Operational Work History Rollout

Tracking plan: `docs/operations/operational-work-history.md`
Tracking gap: `operational-work-history-foundation` in `docs/operations/known-gaps.tsv`

Purpose: track the staged rollout of the Operational Work History layer. This checklist is not a
readiness claim — the stages below are implementation maturity, not manual reporting.

## Stage 1 — CI-generated git/GitHub/CI artifact (this PR)

- [x] Define the schema and question-to-source mapping (`docs/operations/operational-work-history.md`).
- [x] Add `scripts/monitoring/collect-pr-work-history.py` — always writes
      `.engineering-os/work-history/latest.json` + `latest-summary.md` in the CI workspace, never
      committed.
- [x] Add `scripts/enforcement/check-operational-work-history-evidence.sh` — validates the artifact
      directly (`pr_head_sha` match, changed-file count match, dummy/placeholder detection,
      artifact-never-in-diff rule, fail-closed changed-file metadata) and the learning-loop routing
      fields.
- [x] Wire the checker into `scripts/enforcement/check-pr-review-evidence.sh`, run by the existing
      `pr-policy.yml` job.
- [x] Wire real GitHub/PR data into `pr-policy.yml`: pinned head-SHA checkout, least-privilege
      permissions/token, `ci.json`/`reviews.json` snapshot collection, artifact-generation step,
      fail-closed changed-files collection, step-summary + pinned artifact-upload step.
- [x] Add positive/negative/dummy/placeholder/no-exemption/friction-signal fixtures.
- [x] Add a dedicated regression test (`test-pr-policy-workflow-wiring.sh`) proving the real workflow
      file — not just the checker script — actually wires the artifact generation before the
      evidence check and does not fail-open changed-file collection.
- [x] Redefine the Route Plan decision: `check-route-plan-contract.sh`'s per-PR declaration
      dimension is superseded by this artifact, not by 8 new Route Plan fields.

This stage is fully automatic and always available — it only depends on git and the GitHub API,
both of which the `pr-policy` CI runner always has. Stage 1 deliberately has no filename-only
"typo" exemption; future low-risk exemptions must be based on a real diff-aware classifier, not a
single changed-file path.

## Stage 1.5 — same-workspace local telemetry handoff (this PR, best-effort)

- [x] Add `scripts/monitoring/export-current-work-history.sh` — lets Claude copy
      `.engineering-os/telemetry/{events.jsonl,latest-summary.md,run_id}` into a location the
      collector can pick up, when Claude's working environment and the CI runner share a
      filesystem/artifact channel (e.g. a self-hosted runner, or an explicit
      `upload-artifact`/`download-artifact` pairing a target project sets up).
- [ ] This does **not** work automatically when Claude's session runs in a different environment
      than the `pr-policy` runner (the common case, including Claude Code web/remote sessions). In
      that case the artifact still contains full git/GitHub/CI facts, but
      tool/connector/skill/telemetry fields record `telemetry_available=false` rather than a false
      zero. Closing this gap fully requires either a documented per-target-project handoff wiring or
      Stage 3 (below).

## Stage 2 — broader Claude Code hook wiring (documented, not enabled)

Already wired as real hooks in `.claude/settings.json`: `SessionStart`, `PreToolUse` (Bash,
Read/Glob, Write/Edit, Agent), `PostToolUse` (mcp, Context7, Bash, Read, Notion), `Stop`.

Documented but **not** enabled by default (per `core/hooks-policy.md`'s `<hook_examples>` pattern —
copy and adapt per project, don't turn on globally without a decision):

- [ ] `UserPromptSubmit` — would let the recorder correlate a run with a specific user turn.
- [ ] `PostToolUseFailure` — would let the recorder capture tool-call failures directly instead of
      only inferring failure from commit-message heuristics.
- [ ] `PostToolUseBatch` — would let the recorder batch multiple tool events per turn.
- [ ] `SessionEnd` — would let the recorder close out a run distinctly from `Stop`.
- [ ] `StopFailure` — would let the recorder capture a failed turn-completion distinctly from a
      normal `Stop`.

## Stage 3 — OpenTelemetry/OTLP export (open, not started)

- [ ] Add a real OTLP exporter alongside the existing local-file recorder.
- [ ] Support a local console exporter or an OTLP collector target.
- [ ] Correlate prompt/session/tool/CI/PR data across the exporter boundary, not just within one
      repo's local files.
- [ ] Add a dashboard/export format if useful once real data exists.

Do not build this before Stage 1/1.5 have real-PR evidence — see the closure bar in
`docs/operations/known-gaps.tsv`.

## Stage 4 — formal Route Plan field deprecation (decision recorded now)

- [x] Decision recorded: `check-route-plan-contract.sh`'s 8-field per-PR declaration requirement is
      superseded, not mandated. Route Plan is not expanded into a heavier manual-reporting burden.
- [ ] Nothing to physically remove: the 8-field checker was never wired into real PR-diff CI gating
      in the first place (self-tested only), so there is no live behavior to deprecate — only the
      residual-gap wording in `known-gaps.tsv`/the audit doc, which this PR updates.

## Closure bar for `operational-work-history-foundation`

This gap does **not** close from this PR's scaffolding alone. It closes only once real PRs
demonstrate, across multiple runs:

1. The artifact is CI-generated (never hand-written or committed) on every run.
2. The artifact's facts (`pr_head_sha`, changed-file count, CI checks) match the real PR they claim
   to describe.
3. The gate has actually blocked a real missing/placeholder-evidence case on a real PR, not only
   fixtures.
4. Judgment stayed routed through the learning loop with no creeping re-addition of a free-text
   judgment field.
5. There is no relapse into a disguised manual Route Plan.

Until all five hold across several real PRs, this gap stays `open`/"Partially enforced" in
`docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md`.

## Real-PR evidence log

Tracks the real, merged PRs (and any real blocked-case PR) that exercised the
Operational Work History gate end to end — the CI-generated artifact validated
against real PR facts, not fixture coverage. This is the evidence the closure bar
above requires. Every row is filled in from a **later PR**, after the row's own PR
has completed CI and merged (or, for a blocked case, closed) — never by a
follow-up commit on the same PR the row describes. A same-PR follow-up commit
would change that PR's head SHA and trigger a new CI run, so any facts written
into that same commit would describe an already-superseded head rather than the
final merged PR, which would undermine the closure bar's requirement that
recorded facts match the real PR they claim to describe.

| Pass | PR | Surface | pr_head_sha (short) | Changed files | CI checks observed | Blocked-case? | Notes |
|---|---|---|---|---|---|---|---|
| 1 | pending | doc-only: this section (`operational-work-history-rollout.md`) | pending | pending | pending | no | To be filled in by a later PR once this PR has merged. |
| 2 | pending | doc-accuracy: `runtime-telemetry-archive-plan.md` checklist sync | pending | pending | pending | no | To be filled in by a later PR once that PR has merged. |
| 3 | pending | negative validation: PR intentionally missing `## Operational Work History Evidence` | pending | pending | pending | yes | Not merged; closed after capturing the real failing check/reason, then recorded by a later PR. |