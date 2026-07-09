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

## Stage 1.6 — result-loop contract selection (this PR)

- [x] Add `derive_result_loop_contract` to `scripts/monitoring/collect-pr-work-history.py`: classifies
      changed paths into `templates/<project_type_id>/...` candidates or the `engineering-os-governance`
      sentinel, derives when unambiguous, and validates a declared
      `selected_result_loop_contract:` PR-body field (against both the real manifest id set and the
      actual diff candidates) only when ambiguous.
- [x] Add `engineering-os-governance` as a `status=exempt` row to both
      `scripts/enforcement/result-loop-requirements.tsv` and `scripts/enforcement/project-type-roadmaps.tsv`
      — registers a real, non-placeholder contract for Engineering OS's own governance/tooling surface
      without pulling `check-scaling-extension.py`'s active-project coverage requirements onto a project
      type that isn't actually scaffolded (verified: `check-result-loop-contract.py --root .` and
      `check-scaling-extension.py --root .` both still pass).
- [x] Add `scripts/enforcement/check-operational-work-history-evidence.sh` validation of the artifact's
      new `result_loop_contract` object — required+invalid fails closed with the collector-computed
      `ERROR_FOR_AGENT` reason; the checker never re-parses the PR body for this field, so a PR body
      cannot override what the CI-regenerated, SHA-matched artifact says.
- [x] Add `pr-policy.yml -> scripts/enforcement/result-loop-requirements.tsv` to
      `scripts/enforcement/policy-gate-dependencies.tsv` so downstream `install-policy-gates.sh`
      installs copy the manifest the collector needs.
- [x] Extend `scripts/enforcement/tests/test-collect-pr-work-history.sh` and
      `scripts/enforcement/tests/test-operational-work-history-evidence.sh` with derived/declared/
      ambiguous/unknown-id/placeholder/declared-unrelated-to-diff/not-required/stale-artifact/
      PR-body-cannot-override fixtures, plus a regression assertion that
      `check-route-plan-contract.sh` remains referenced only by its own test file.
- [ ] Real positive-evidence PR: the PR implementing this stage exercises the new gate on its own real,
      non-fixture diff (governance-surface-only changes → single candidate → derived,
      `engineering-os-governance`). Row added to the Real-PR evidence log below once merged.
- [ ] Real negative-evidence PR/branch: a throwaway PR touching both `templates/web-application/...`
      and an Engineering OS governance file, with no `selected_result_loop_contract:` declared, proving
      the real `pr-policy` job fails with the expected `ERROR_FOR_AGENT`. Closed without merging once
      captured; row added to the Real-PR evidence log below.

This stage does not close `result-loop-contract-enforcement` by itself — see
`docs/operations/known-gaps.tsv` row 27 for the closure bar (implementation + fixtures + one real
positive PR + one real negative PR + review resolution + green CI).

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
`docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md`. **Update:**
all five now hold, evidenced by the Real-PR evidence log below (PRs #234, #235, #236) — see the
closure bar evaluation after the log.

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
| 1 | [#234](https://github.com/yotamfried-ux/Engineering-OS/pull/234) (merged) | doc-only: this section (`operational-work-history-rollout.md`) | `52186af` | 1 | pr-policy (`Require ready-for-review PR`): success; `enforcement-tests`: success | no | Real job log confirmed `pr_head_sha` matched, `operational work history evidence passed`. Bonus real evidence beyond the plan: a review-driven fix commit produced one real transient CI failure (stale `expected-head-sha`), and once fixed the artifact's real `ci_failure_count` correctly triggered the friction-signal path, requiring (and getting) a concrete `learning_loop_result` reason — proving the friction-routing logic against real CI history, not a fixture. |
| 2 | [#235](https://github.com/yotamfried-ux/Engineering-OS/pull/235) (merged) | doc-accuracy: `runtime-telemetry-archive-plan.md` checklist sync | `0e80d3e` | 2 | pr-policy (`Require ready-for-review PR`): success; `enforcement-tests`: success | no | Real job log confirmed `pr_head_sha` matched, `operational work history evidence passed` — first-attempt clean pass, proving the gate generalizes beyond pass #1's surface. |
| 3 | [#236](https://github.com/yotamfried-ux/Engineering-OS/pull/236) (closed, not merged) | negative validation: PR intentionally missing `## Operational Work History Evidence` | `c3fb003` | 1 | pr-policy (`Require ready-for-review PR`): **failure** (intended) | yes | Real job log: `PR review and merge-readiness evidence passed` → `operational behavior evidence passed` → `ERROR_FOR_AGENT: PR body must include ## Operational Work History Evidence for any PR with changed files; no filename-only exemption is allowed.` The gate blocked a real missing-evidence case, isolated to this one failing reason (verified — a real chatgpt-codex-connector review flagged an earlier, now-fixed compounding failure, confirmed stale against the final run in the PR thread). PR closed without merging, per design. |

### Closure bar evaluation

All five closure-bar items above are satisfied by the three real PRs in this log:

1. **CI-generated, never committed** — confirmed structurally: no `.engineering-os/work-history/*` exists anywhere in the repo, and the gate itself rejects any diff touching that path (exercised, though not triggered, across all three real PRs).
2. **Artifact facts match the real PR** — confirmed via real job logs for #234 (matched after a review-driven fix) and #235 (matched on the first real run).
3. **Gate blocked a real bad case** — confirmed via #236's real, isolated CI failure.
4. **Judgment stayed routed through the learning loop** — both #234 and #235 used `learning_loop_result: none-with-reason`; no new free-text judgment field was introduced anywhere in this evidence-gathering sequence.
5. **No relapse into a disguised manual Route Plan** — no PR in this sequence added Route Plan fields; `check-route-plan-contract.sh` remains unwired.

Per this evaluation, `operational-work-history-foundation` closes — see `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md` for the corresponding status update.