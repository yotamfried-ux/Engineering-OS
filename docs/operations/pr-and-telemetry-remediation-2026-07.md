# PR and Telemetry-Gap Remediation Checklist (2026-07)

Tracking plan: `.claude/plans/pr-and-telemetry-remediation.md`

Purpose: track execution of the remediation identified from a direct review of the
Engineering OS open PRs, `docs/operations/operational-readiness-audit.md`, and the
real telemetry data-collection gap. This checklist is not a readiness claim.

Do not run another target-project data-collection experiment (Project 8 or otherwise)
until every item below **other than B3 itself** is checked with real, linked evidence
— matching the existing rule in `docs/operations/project8-first-real-run-findings.md`
that Operational Work History alone cannot close a readiness gap. B3 is deliberately
excluded from this top-level gate because it *is* the target-project experiment: it
can only ever be checked by running it, so requiring it to already be checked before
it can run would make it permanently unsatisfiable.

## Phase A — Unstick the 3 open PRs (complete)

- [x] A1. PR #200 (Remove CV supervision hard gate): fixed a stale review thread and
      a CodeRabbit-flagged symlink-hijack fixture path, updated the branch against
      current `main`, and verified real CI green on the actual head SHA before merge.
      Evidence: PR #200, head `7279f84`, merged.
- [x] A2. PR #199 (Add eval harness): added the required plan-evidence sections,
      simplified the connector field, and amended checkpoints so Progress Lifecycle
      evidence lands at its real chronological points. Evidence: PR #199, head
      `b7158d4`, merged.
- [x] A3. PR #201 (runtime monitoring baseline): closed unmerged because direct
      inspection of the real commit history showed its Route Plan was genuinely
      committed after most of the telemetry code — the plan's own text admitted
      "Route Plan created after initial implementation gap was identified." Per
      explicit user decision, rebasing to fake plan-first ordering was rejected as
      dishonest. The underlying telemetry capability was recreated properly on
      fresh, plan-first branches instead (see Phase B, B2).

## Phase B — Close the real telemetry data-collection gap

- [x] B1. Corrected `docs/operations/project8-telemetry-preflight.md`'s claim that
      "Claude Code loads hooks only at session startup" to the precise reason:
      settings/hook files reload live via Claude Code's file watcher; only
      `SessionStart`-scoped state (run id, telemetry bundle open) actually requires
      a fresh session. The operational instruction (open a fresh session) is
      unchanged — only the stated justification was imprecise.
- [x] B2. The runtime-monitoring telemetry work superseding closed PR #201 was
      recreated on fresh, plan-first branches and is already merged to `main`:
      `scripts/monitoring/eos-telemetry-event.sh`, `eos-telemetry-summary.py`,
      `eos-telemetry-session-start.sh`, `require-telemetry-session.sh`,
      `telemetry_handoff.py`, and the durable remote-handoff/select/import/export
      pipeline all exist on `main` and are wired into `.claude/settings.json` via
      merged PRs #244 (installation/preflight), #245 (remote handoff + live review
      gate), and #246 (fresh-session hook blocker + Stop plan scoping). This item
      was previously left unchecked in error on the prior checklist draft; it is
      corrected here from direct inspection of `main`, not from a PR-body claim.
- [ ] B3. Execute `docs/operations/runtime-telemetry-archive-audit-checklist.md`'s
      "Project 8 telemetry evidence" section end to end, in the order written:
      confirm the durable-handoff implementation and the current Engineering OS
      version are installed in Project 8 → merge updated `pr-policy.yml`/telemetry
      runtime into `project-8/main` → enable required remote handoff → fresh Claude
      session → `require-telemetry-session.sh` passes with positive events → one
      bounded task → non-empty matched telemetry artifact → import/analyze → write
      findings → update the two open audit rows from real evidence only.
      **This item is intentionally left unchecked — it is the gated experiment
      itself and must not run until every other item in this checklist is
      checked.**
      Read-only inspection of `yotamfried-ux/project-8` done in this PR (no
      writes, no experiment run): `pr-policy.yml` and
      `.engineering-os/telemetry-policy.json` (`remote_handoff.mode: required`,
      branch `engineering-os-telemetry`) are already installed, from the merged
      "Sync durable Engineering OS telemetry handoff" PR (#7 on project-8).
      `.claude/settings.json` correctly resolves session-side recorders
      (`eos-telemetry-event.sh`, `require-telemetry-session.sh`) via
      `${ENGINEERING_OS_HOME:-$HOME/.engineering-os}` rather than vendoring them
      into the repo, matching the documented install model. However, the
      vendored CI-side script `scripts/enforcement/check-pr-review-evidence.sh`
      on `project-8/main` predates this PR's C1 stale-check addition (confirmed
      by diff), so before B3 runs, the preflight's own installation sequence
      (merge here → re-install in Project 8 → confirm on `project-8/main`) must
      re-sync it, or the stale-claim check will simply not exist yet for that run.
- [x] B4 (optional, low-risk). Added `gen_ai.*` OpenTelemetry GenAI semantic
      convention attributes (`gen_ai.request.model`, `gen_ai.operation.name`,
      `gen_ai.system`) additively alongside the existing `eos.claude.*` attributes
      in `eos-telemetry-event.sh`, confirmed against the official OpenTelemetry
      GenAI semantic conventions researched in this session. Per-call token usage
      (`gen_ai.usage.input_tokens`/`output_tokens`) is not populated: Claude Code
      hook payloads do not expose token counts, so those fields are documented as
      not-yet-available rather than fabricated.

## Phase C — Close the process gap that let a PR's claims diverge from real CI

- [x] C1. Added a stale-claim check to `check-pr-review-evidence.sh`: when
      `--head-sha` is supplied, the PR body's Merge Readiness `expected-head-sha`
      must match it exactly, or the check fails with an explicit
      `ERROR_FOR_AGENT` telling the agent to re-fetch live check-run state instead
      of trusting the PR body. This directly closes the gap that let PR #199/#200
      sit for ~2 weeks claiming "fix pushed, needs recheck" while stale.
- [x] C2. Documented the DoD-checkbox ordering paradox fix in
      `core/quality-gates.md`: CI-dependent items (e.g. "PR checks pass",
      "CI green") must never appear as a plan `## DoD` checkbox, because G9a
      (DoD items cannot be removed) and G10 (all DoD items must be checked before
      commit) make such an item structurally impossible to satisfy honestly before
      the commit that would trigger that CI run exists. The fix codifies the
      "Live External Gates Before Merge" section — already used ad hoc in
      `.claude/plans/audit-freshness-p0.md` — as the required, documented pattern
      for this class of item. Also added a non-blocking advisory check to
      `enforce-quality.sh` (the required md-sync enforcer for
      `quality-gates.md`) that warns, at commit time, when a staged plan's
      `## DoD` section names CI-outcome language — catching the anti-pattern
      proactively instead of relying on the doc alone.

## Verification

- For each PR item in Phase A: verified via `pull_request_read` (`get_check_runs`)
  on the real, current head SHA — never assumed from the PR body.
- For B2: verified by direct inspection of `main` (`ls scripts/monitoring/`,
  `grep telemetry .claude/settings.json`), not from the prior checklist's claim.
- For C1/C2: verified by running the new/updated test fixtures locally before
  commit (see `scripts/enforcement/tests/test-pr-review-evidence.sh`).
- For B3: the existing telemetry checklist is itself the acceptance test; "done"
  means every box there is checked with a linked real artifact (PR/SHA/telemetry
  bundle id), not aspirational text. It is not attempted in this PR.
- After B3 completes, re-read `docs/operations/operational-readiness-audit.md` and
  confirm the `monitoring-metrics-sufficiency` and `project-8-real-run-evidence`
  rows flip to closed with cited real evidence.

## Gate on the next experiment

Per explicit instruction: do not run another target-project data-collection
experiment until every checkbox above is checked with real evidence. As of this
PR: Phase A is complete, Phase B is complete except the gated B3 experiment
itself, and Phase C is complete. B3 remains the single remaining blocker before
the next experiment.
