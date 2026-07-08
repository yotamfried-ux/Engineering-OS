# Result Loop Contract Gate Wiring Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, enforcement, result-loop |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | docs/operations/result-loop-contract-plan.md, docs/operations/result-loop-contract-audit-checklist.md |
| Patterns | governance evidence pattern (same named-CI-gate pattern as check-readiness-audit.sh) |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-result-loop-contract.py, scripts/enforcement/tests/test-result-loop-contract.sh, .github/workflows/enforcement-tests.yml |
| Evidence to check | scripts/enforcement/check-result-loop-contract.py; scripts/enforcement/tests/test-result-loop-contract.sh; scripts/enforcement/coverage-required-gates.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md; .github/workflows/enforcement-tests.yml |
| User decisions required | none |
| Target paths | .github/workflows/enforcement-tests.yml, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.d/result-loop-contract.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/enforcement/check-result-loop-contract.py | checked | Validates that every `active`/`required` `project-type-roadmaps.tsv` row has a complete, non-placeholder `result-loop-requirements.tsv` row. Repo-wide grep confirms zero references outside its own test file — audit's claim is accurate. |
| scripts/enforcement/tests/test-result-loop-contract.sh | checked | Already has real positive/negative fixtures (missing-contract-row, placeholder-field, mobile-no-local-review, api-no-performance, missing-telemetry-export, game-no-playable) by copying the repo to temp dirs and breaking specific manifest rows. No new fixtures needed. |
| .github/workflows/enforcement-tests.yml | checked | `check-readiness-audit.sh` already has a dedicated named step ("Verify operational readiness audit coverage") separate from the aggregate `test-*.sh` sweep — this is the exact pattern to copy for `check-result-loop-contract.py`. |
| docs/operations/known-gaps.tsv | checked | Row 27 `result-loop-contract-enforcement` is `open`/P1; will close only once the named CI step is real and verified green. |
| docs/operations/operational-readiness-audit.md | checked | "Result Loop Contract enforcement" matrix row is "Missing enforcement" with `gap:result-loop-contract-enforcement` link; will update to "Enforced" only after the gate is verified real. |

## Documentation Asset Evidence

- internal: `docs/operations/result-loop-contract-plan.md`; `docs/operations/result-loop-contract-audit-checklist.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`.
- context7: not required — internal-only GitHub Actions/shell/manifest governance work; no third-party library, framework, SDK, or API is introduced or touched.
- decision: reuse the exact `check-readiness-audit.sh` dedicated-step pattern already in `enforcement-tests.yml` instead of inventing a new workflow or a new manifest schema.

## Connector Evidence

- GitHub: repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, `docs/operations/known-gaps.tsv` row 27, `docs/operations/operational-readiness-audit.md` "Result Loop Contract enforcement" row, PR #227 (merged `17243d2`).
- action: read the merged state of `check-result-loop-contract.py`/`test-result-loop-contract.sh` on `main`, confirmed via repo-wide grep that no workflow YAML references the checker, and copied the exact named-step pattern already used for `check-readiness-audit.sh`.
- result: added a "Verify result loop contract gate" step to `.github/workflows/enforcement-tests.yml` running `python3 scripts/enforcement/check-result-loop-contract.py --root .` directly, so every real `pull_request` now runs it as a visible, named, tamper-evident check distinct from the aggregate `test-*.sh` sweep.
- decision: added a dedicated named CI step instead of only relying on the aggregate test-file sweep, and kept `known-gaps.tsv` row 27 and the audit's "Result Loop Contract enforcement" matrix row unchanged pending confirmation that the new named step passes green on this PR's own CI run against real PR content.
- target: .github/workflows/enforcement-tests.yml; scripts/enforcement/coverage-required-gates.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — this plan committed before edits.
- `source.github-repo-read` — repository files and merged PR #227 state read.
- `validation.policy-change-has-validator` — reusing an existing checker with existing fixtures; no new validator code, only new CI wiring plus the existing coverage manifest.
- `validation.actions-checked` — `.github/workflows/enforcement-tests.yml` change reviewed against the existing named-step pattern and the full local `test-*.sh` sweep.
- `validation.coderabbit-policy` — review or fallback required before merge.

## Claude Run Trace

- goal: give `result-loop-contract-enforcement` a real, visible, named PR-gating CI check instead of only being reachable through the aggregate test-file sweep.
- hypothesis: the checker (`check-result-loop-contract.py --root .`) already validates real manifest completeness correctly against the real repo state; the missing piece was purely CI visibility/wiring, not new validator logic.
- connectors: GitHub.
- steps: verify checker/test state on merged main, verify zero external references via grep, add the named step copying the `check-readiness-audit.sh` pattern, register in `coverage-required-gates.tsv`, update known-gaps/audit only after the step is confirmed green in real CI.
- evidence: `.github/workflows/enforcement-tests.yml` diff; local `python3 scripts/enforcement/check-result-loop-contract.py --root .` run; local `test-result-loop-contract.sh` run; PR CI run showing the new named step passing.
- rejected: building new Route-Plan-to-manifest linkage logic (the deeper integration abandoned in PRs #214/#216) — out of scope; reusing the existing checker's manifest-completeness validation as a real named gate honestly closes what the audit describes as missing.
- result: pending CI confirmation.
- follow-up: none planned beyond this PR.

## Operational Behavior Evidence

- behavior_summary: wired an existing, already-correct manifest-completeness checker into a real, named, visible PR-gating CI step instead of leaving it reachable only through the aggregate test-file sweep.
- engineering_os_influence: the audit's own precise wording ("no CI workflow invokes the checker against a real PR") and the existing `check-readiness-audit.sh` named-step precedent in `enforcement-tests.yml` directly determined the fix shape.
- efficiency_signals: reused an existing checker, existing fixtures, and an existing CI-step pattern; no new script or new manifest schema was written.
- friction_or_false_positives: none yet recorded for this PR.
- quality_signals: existing `test-result-loop-contract.sh` positive/negative fixtures re-verified locally before wiring; full local `test-*.sh` sweep re-run after the workflow change.
- usage_surrogate: exact_token_usage_available=no; tool_calls=GitHub operations plus local shell/test runs; wall_clock_minutes=not_metered.
- next_system_improvement: consider whether `test-install-policy-gate-coverage.sh`-style coverage checking should also verify that every `check-*.py`/`check-*.sh` with real-PR semantics has a dedicated named `enforcement-tests.yml` step, not just an entry in its own test file.

## Lessons Reused

- `lessons-learned/bugs/ci-environment-dependent-fixture-premise.md` — CI fixtures/gates must not assume host-tool absence or PATH shape that may differ between local sandbox and the GitHub Actions runner. Applied here by running `check-result-loop-contract.py --root .` locally on this exact runner-equivalent repo state and cross-checking against the real CI job log rather than assuming local pass implies CI pass.
- `lessons-learned/bugs/mawk-ignorecase-unsupported.md` — shell/awk logic added to enforcement scripts must not rely on gawk-only extensions since CI runners may use a different `awk` implementation. Not directly touched by this PR (no new awk/sed logic is added — this PR only adds a `python3 ...` step and TSV/doc rows), but checked as a precondition before editing `.github/workflows/enforcement-tests.yml`.
- `lessons-learned/bugs/security-gate-silent-diff-truncation.md` — a gate that silently passes without truly exercising its check is worse than an obviously-missing gate. Directly informs this PR's whole premise: adding a dedicated *named* CI step (not just leaving the checker inside the aggregate test-file sweep) so the gate cannot be silently deleted/skipped without a visible, named check disappearing from the PR.

## Graphify Usage Evidence

- source: graphify explain query against graphify-out/graph.json.
- action: ran `graphify explain "enforcement-tests.yml"` before editing the workflow file.
- result: no graph node exists for `enforcement-tests.yml` (untracked config, consistent with the earlier `policy-gate-dependencies.tsv` finding in PR #227) — graph coverage does not extend to CI YAML files, so the change was verified directly by reading the existing `check-readiness-audit.sh` named-step block in the same file and copying its exact pattern instead.
- decision: treated this as a config-only change scoped to the 4 target files, verified by direct file reads rather than graph traversal.
- target: .github/workflows/enforcement-tests.yml; scripts/enforcement/coverage-required-gates.tsv; scripts/enforcement/simulation-coverage.d/result-loop-contract.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Alternatives

- Building deeper Route-Plan-to-manifest per-PR linkage (what PRs #214/#216 attempted and abandoned) — rejected as out of scope for this focused gap-closure PR.
- Leaving the checker only inside the aggregate `test-*.sh` sweep — rejected because that is exactly the "not wired to a real CI workflow" state the audit flags as insufficient.
- Adding a brand-new standalone workflow file just for this one checker — rejected in favor of the existing `enforcement-tests.yml` named-step pattern, avoiding workflow sprawl.

## Affected Surfaces

- `.github/workflows/enforcement-tests.yml`.
- `scripts/enforcement/coverage-required-gates.tsv`.
- `docs/operations/known-gaps.tsv`.
- `docs/operations/operational-readiness-audit.md`.

## Data/State Impact

- No application data impact.

## Integration Impact

- `enforcement-tests` CI now runs `check-result-loop-contract.py --root .` as a dedicated named step on every real `pull_request`, in addition to its existing self-test coverage.

## Validation Plan

- Run `python3 scripts/enforcement/check-result-loop-contract.py --root .` locally (must exit 0 against current repo state).
- Run `bash scripts/enforcement/tests/test-result-loop-contract.sh` locally (existing positive/negative fixtures must still pass).
- Run the full local `scripts/enforcement/tests/test-*.sh` sweep.
- Confirm the new named CI step appears and passes in the real Actions run for this PR's head SHA.
- Confirm zero open review threads before merge.

## Open Questions

- None outstanding for this scoped PR.

## Progress Lifecycle Evidence

- start: read `check-result-loop-contract.py`, `test-result-loop-contract.sh`, `known-gaps.tsv` row 27, and the audit's matrix row before any edit; confirmed via repo-wide grep that zero workflow/script references exist outside the checker's own test file.
- mid: added the named "Verify result loop contract gate" step to `enforcement-tests.yml`, registered the gate in `coverage-required-gates.tsv` and a new `simulation-coverage.d/result-loop-contract.tsv` row, confirmed `check-simulation-coverage.sh` accepts it (30 gates), and confirmed the full local `test-*.sh` sweep (80 suites) still passes clean. `known-gaps.tsv`/audit doc intentionally not yet updated — deferred to a pre-merge checkpoint after real CI confirms the new named step passes on an actual PR run, per the task's truthfulness requirement.

## DoD

- [x] Add a dedicated named "Verify result loop contract gate" step to `enforcement-tests.yml` running the checker directly against the real repo.
- [x] Confirm existing positive/negative fixtures in `test-result-loop-contract.sh` still pass locally.
- [x] Register the gate in `coverage-required-gates.tsv` and `simulation-coverage.d/result-loop-contract.tsv`.
- [x] Full local `test-*.sh` sweep passes clean.
- [ ] Update `known-gaps.tsv` row 27 to `closed` only after the new named CI step is confirmed green in a real PR run.
- [ ] Update the audit's "Result Loop Contract enforcement" matrix row to "Enforced" with an honest residual note.
- [ ] Zero open review threads before merge.
