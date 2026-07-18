# PR and Telemetry-Gap Remediation Checklist (2026-07)

Tracking plan: `.claude/plans/pr-and-telemetry-remediation.md`

Purpose: track execution of the remediation identified from a direct review of the
3 open Engineering OS PRs, `docs/operations/operational-readiness-audit.md`, and the
real telemetry data-collection gap. This checklist is not a readiness claim.

Do not run another target-project data-collection experiment (Project 8 or otherwise)
until every item below is checked with real, linked evidence — matching the existing
rule in `docs/operations/project8-first-real-run-findings.md` that OWH alone cannot
close a readiness gap.

## Phase A — Unstick the 3 open PRs

- [x] A1. PR #200 (Remove CV supervision hard gate): ran the over-blocking safety
      check on the full diff (confirmed it only relaxes a gate and leaves no
      dangling references), fixed a stale review thread and a CodeRabbit-flagged
      symlink-hijack fixture path, updated the branch against current `main`, and
      verified real CI green on the actual head SHA before merge. Evidence: PR #200,
      head `7279f84`.
- [x] A2. PR #199 (Add eval harness): added the plan-evidence sections
      `check-workflow-evidence.sh`/`check-connector-evidence.sh` required (Source of
      Truth Checks, Skill Evidence, Connector Usage Evidence), simplified the
      connector field, and — with explicit user approval — amended 2 already-pushed
      commits so Progress Lifecycle checkpoints land at their real chronological
      points (the plan genuinely was committed before the code on this PR, unlike
      #201). Evidence: PR #199, head `9ba8203`.
- [x] A3. PR #201 (runtime monitoring baseline / reopen readiness gaps): direct
      inspection of the real commit history showed the Route Plan was genuinely
      committed after most of the telemetry code, and the plan's own text admitted
      "Route Plan created after initial implementation gap was identified." Per
      explicit user decision, rebasing this to look plan-first was rejected as
      dishonest (would require deleting that admission). PR #201 is closed and the
      telemetry work is recreated on a fresh branch (see Phase B).

## Phase B — Close the real telemetry data-collection gap

- [ ] B1. Correct `docs/operations/project8-telemetry-preflight.md`'s claim that
      "Claude Code loads hooks only at session startup" to the precise, officially
      verified reason: settings/hook files reload live via Claude Code's file
      watcher; only `SessionStart`-scoped state (run id, telemetry bundle open) is
      what actually requires a fresh session. Keep the operational instruction
      (open a fresh session) — only the stated justification needs precision.
- [ ] B2. Recreate the runtime-monitoring telemetry work on a fresh branch with a
      genuine plan-first commit (superseding closed PR #201), reusing the
      already-sound underlying script logic where applicable.
- [ ] B3. Execute `docs/operations/runtime-telemetry-archive-audit-checklist.md`'s
      "Project 8 telemetry evidence" section end to end, in the order written:
      merge the durable-handoff implementation → install the exact version in
      Project 8 → merge updated `pr-policy.yml`/telemetry runtime into
      `project-8/main` → enable required remote handoff → fresh Claude session →
      `require-telemetry-session.sh` passes with positive events → one bounded
      task → non-empty matched telemetry artifact → import/analyze → write
      findings → update the two open audit rows from real evidence only.
- [ ] B4 (optional, low-risk). Align the local telemetry JSONL field names with
      OpenTelemetry's GenAI semantic conventions (`gen_ai.request.model`,
      `gen_ai.usage.input_tokens`/`output_tokens`, `invoke_agent`/`execute_tool`
      span kinds) so a future export to a real OTel backend needs no reshaping.

## Phase C — Close the process gap that let a PR's claims diverge from real CI

- [ ] C1. Add a lightweight check (in `check-pr-review-evidence.sh` or similar) that
      flags a PR body's "Merge Readiness" section when it is stale relative to the
      actual current head SHA's CI result — so a PR can't sit for days claiming
      "fix pushed, needs recheck" while its real CI is still red on that exact SHA.
- [ ] C2. Fix the DoD-checkbox ordering paradox generally: an item like "PR checks
      pass before merge" cannot be truthfully pre-checked. Either drop such items
      from the plan template or make them CI-computed rather than manually ticked.

## Verification

- For each PR item above: verified via `pull_request_read` (`get_check_runs`) on
  the real, current head SHA after every push — never assumed from the PR body.
- For Phase B: the existing telemetry checklist is itself the acceptance test;
  "done" means every box there is checked with a linked real artifact (PR/SHA/
  telemetry bundle id), not aspirational text.
- After B3 completes, re-read `docs/operations/operational-readiness-audit.md` and
  confirm the `monitoring-metrics-sufficiency` and `project-8-real-run-evidence`
  rows flip to closed with cited real evidence.
