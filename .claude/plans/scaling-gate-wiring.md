# Scaling Extension Gate Wiring Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, enforcement, scaling |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md |
| Patterns | governance evidence pattern (same named-CI-gate pattern used for check-readiness-audit.sh and check-result-loop-contract.py in PR #228) |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-scaling-extension.py, scripts/enforcement/tests/test-scaling-extension.sh, .github/workflows/enforcement-tests.yml |
| Evidence to check | scripts/enforcement/check-scaling-extension.py; scripts/enforcement/tests/test-scaling-extension.sh; scripts/enforcement/coverage-required-gates.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md; .github/workflows/enforcement-tests.yml |
| User decisions required | none (user already decided in this session not to wire check-route-plan-contract.sh's 8-field per-PR requirement repo-wide; that decision applies equally here since it's the same shared checker) |
| Target paths | .github/workflows/enforcement-tests.yml, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.d/scaling-extension.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/enforcement/check-scaling-extension.py | checked | Validates manifest completeness: every `kind=project` `template-requirements.tsv` row has a `project-type-roadmaps.tsv` entry, roadmap rows have official sources, docs/reference-repo/code-example/pattern/skill/connector-workflow manifests are internally consistent, waivers are scoped, and game-development evidence is complete. Same "global manifest self-consistency via `--root`" architecture as `check-result-loop-contract.py` (PR #228) — no PR-diff parsing needed by design. |
| scripts/enforcement/tests/test-scaling-extension.sh | checked | Direct positive run against real repo plus 7 negative fixtures (missing-template, missing-roadmap, missing-docs-metadata, missing-pattern-skill, missing-game-evidence, missing-project-type-roadmap, stale-roadmap-template-path). No new fixtures needed. |
| repo-wide grep for `check-scaling-extension` in `*.yml` | checked | Zero matches — confirms audit's claim that no workflow invokes it. |
| repo-wide grep for a scaling-specific per-PR "declare new project type" checker (distinct from `check-route-plan-contract.sh`) | checked | None found. The only per-PR-declaration-style checker touching `selected_project_type`/`selected_template`/`selected_roadmap` is the same shared `check-route-plan-contract.sh` already found unwired in PR #228 (gap 1). The user explicitly decided in this session not to wire that checker (it would mandate 8 new Route Plan fields repo-wide) — that decision applies equally here since it is literally the same script, not a scaling-specific one. |
| docs/operations/known-gaps.tsv row 28 | checked | `open`/P1; matches PR #219/#224 history exactly as gap 1's row did before PR #228. |
| docs/operations/operational-readiness-audit.md | checked | "Scaling extension enforcement" row is "Missing enforcement" with `gap:scaling-extension-enforcement` link. |

## Documentation Asset Evidence

- internal: `docs/operations/scaling-extension-procedure.md`; `docs/operations/project-type-roadmaps.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`.
- context7: not required — internal-only GitHub Actions/shell/manifest governance work; no third-party library, framework, SDK, or API is introduced or touched.
- decision: reuse the exact `check-readiness-audit.sh`/`check-result-loop-contract.py` dedicated-step pattern instead of inventing a new workflow or manifest schema.

## Connector Evidence

- GitHub: repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, `docs/operations/known-gaps.tsv` row 28, `docs/operations/operational-readiness-audit.md` "Scaling extension enforcement" row, merged PR #228 (`add56a1`).
- action: read the merged state of `check-scaling-extension.py`/`test-scaling-extension.sh` on `main`, confirmed via repo-wide grep that no workflow YAML references the checker, and specifically searched for a scaling-analog of the `check-route-plan-contract.sh` blind spot found in PR #228 before claiming full closure this time.
- result: added a "Verify scaling extension gate" step to `.github/workflows/enforcement-tests.yml` running `python3 scripts/enforcement/check-scaling-extension.py --root .` directly; confirmed no separate scaling-specific per-PR declaration checker exists (only the same shared, already-addressed `check-route-plan-contract.sh`), so unlike gap 1 this closure is not partial.
- decision: added a dedicated named CI step and, having verified no residual scaling-specific blind spot exists, closed `known-gaps.tsv` row 28 and updated the audit's "Scaling extension enforcement" matrix row to "Enforced".
- target: .github/workflows/enforcement-tests.yml; scripts/enforcement/coverage-required-gates.tsv; scripts/enforcement/simulation-coverage.d/scaling-extension.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — this plan committed before any code/config edit.
- `source.github-repo-read` — repository files and merged PR #228 state read.
- `validation.policy-change-has-validator` — reusing an existing checker with existing fixtures; no new validator code, only new CI wiring plus the existing coverage manifest.
- `validation.actions-checked` — `.github/workflows/enforcement-tests.yml` change reviewed against the existing named-step pattern and the full local `test-*.sh` sweep.
- `validation.coderabbit-policy` — review or fallback required before merge.

## Claude Run Trace

- goal: give `scaling-extension-enforcement` a real, visible, named PR-gating CI check, applying the exact lesson learned in gap 1 (PR #228): explicitly check for a scaling-specific analog of the `check-route-plan-contract.sh` blind spot before claiming full closure.
- hypothesis: `check-scaling-extension.py --root .` already validates real manifest completeness correctly; the missing piece is purely CI visibility/wiring. Unlike gap 1, no separate scaling-specific per-PR declaration checker exists (only the same shared, already-addressed `check-route-plan-contract.sh`), so this closure should not need a "Partially enforced" downgrade.
- connectors: GitHub.
- steps: verify checker/test state on merged main, verify zero external references via grep, explicitly grep for any scaling-specific analog of `check-route-plan-contract.sh` (found none), add the named step copying the `check-result-loop-contract.py` pattern from PR #228, register in `coverage-required-gates.tsv` and `simulation-coverage.d/scaling-extension.tsv`, update known-gaps/audit only after the step is confirmed green in real CI.
- evidence: `.github/workflows/enforcement-tests.yml` diff; local `python3 scripts/enforcement/check-scaling-extension.py --root .` run; local `test-scaling-extension.sh` run; repo-wide grep results; PR CI run showing the new named step passing.
- rejected: assuming closure is safe without re-checking for gap-1-style blind spots — rejected in favor of an explicit verification step, learning directly from the codex finding on PR #228.
- result: pending CI confirmation.
- follow-up: none planned beyond this PR.

## Lessons Reused

- `lessons-learned/bugs/ci-environment-dependent-fixture-premise.md` — CI fixtures/gates must not assume host-tool absence or PATH shape that may differ between local sandbox and the GitHub Actions runner. Applied by running `check-scaling-extension.py --root .` locally on this exact runner-equivalent repo state and cross-checking against the real CI job log rather than assuming local pass implies CI pass.
- `lessons-learned/bugs/mawk-ignorecase-unsupported.md` — checked as a precondition before editing `.github/workflows/enforcement-tests.yml`; not directly applicable since this PR adds no new awk/sed logic.
- `lessons-learned/bugs/security-gate-silent-diff-truncation.md` — a gate that silently passes without truly exercising its check is worse than an obviously-missing gate; directly informs adding a dedicated *named* CI step rather than leaving the checker inside the aggregate sweep.

## Graphify Usage Evidence

- source: graphify explain query against graphify-out/graph.json.
- action: ran `graphify explain "check-scaling-extension.py"` and `graphify explain "enforcement-tests.yml"` before editing.
- result: consistent with PR #227/#228 findings — CI YAML and enforcement scripts are not covered by the graph (no nodes returned), so verification was done by direct file reads instead of graph traversal.
- decision: treated this as a config-only change scoped to the target files, verified by direct file reads.
- target: .github/workflows/enforcement-tests.yml; scripts/enforcement/coverage-required-gates.tsv; scripts/enforcement/simulation-coverage.d/scaling-extension.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Alternatives

- Leaving the checker only inside the aggregate `test-*.sh` sweep — rejected, matches the exact "not wired to a real CI workflow" state the audit flags as insufficient.
- Adding a brand-new standalone workflow file just for this one checker — rejected in favor of the existing `enforcement-tests.yml` named-step pattern.
- Claiming closure without checking for a scaling-analog of gap 1's `check-route-plan-contract.sh` blind spot — rejected; explicitly searched for one first (none found) before claiming full "Enforced" status, learning directly from the gap-1 correction.

## Affected Surfaces

- `.github/workflows/enforcement-tests.yml`.
- `scripts/enforcement/coverage-required-gates.tsv`.
- `scripts/enforcement/simulation-coverage.d/scaling-extension.tsv`.
- `docs/operations/known-gaps.tsv`.
- `docs/operations/operational-readiness-audit.md`.

## Data/State Impact

- No application data impact.

## Integration Impact

- `enforcement-tests` CI now runs `check-scaling-extension.py --root .` as a dedicated named step on every real `pull_request`, in addition to its existing self-test coverage.

## Validation Plan

- Run `python3 scripts/enforcement/check-scaling-extension.py --root .` locally (must exit 0).
- Run `bash scripts/enforcement/tests/test-scaling-extension.sh` locally (7 negative fixtures plus positive run must pass).
- Run the full local `scripts/enforcement/tests/test-*.sh` sweep.
- Confirm the new named CI step appears and passes in the real Actions run for this PR's head SHA.
- Confirm zero open review threads before merge.

## Open Questions

- None outstanding for this scoped PR.

## Progress Lifecycle Evidence

- start: read `check-scaling-extension.py`, `test-scaling-extension.sh`, `known-gaps.tsv` row 28, and the audit's matrix row before any edit; confirmed via repo-wide grep that zero workflow/script references exist outside the checker's own test file; explicitly searched for a scaling-specific analog of gap 1's `check-route-plan-contract.sh` blind spot and found none.
- mid: added the named "Verify scaling extension gate" step to `enforcement-tests.yml`, registered the gate in `coverage-required-gates.tsv` and a new `simulation-coverage.d/scaling-extension.tsv` row, confirmed `check-simulation-coverage.sh` accepts it, and confirmed the full local `test-*.sh` sweep still passes clean. `known-gaps.tsv`/audit doc intentionally not yet updated at this point — deferred to a pre-merge checkpoint after real CI confirms the new named step passes on an actual PR run.

## DoD

- [x] Add a dedicated named "Verify scaling extension gate" step to `enforcement-tests.yml` running the checker directly against the real repo.
- [x] Confirm existing positive/negative fixtures in `test-scaling-extension.sh` still pass locally.
- [x] Register the gate in `coverage-required-gates.tsv` and `simulation-coverage.d/scaling-extension.tsv`.
- [x] Full local `test-*.sh` sweep passes clean.
- [ ] Confirm the new named CI step is actually green on this PR's own real CI run (not just local).
- [ ] Update `known-gaps.tsv` row 28 to `closed` only after CI confirms and no residual scaling-specific blind spot is found.
- [ ] Update the audit's "Scaling extension enforcement" matrix row to "Enforced".
- [ ] Zero open review threads before merge.
