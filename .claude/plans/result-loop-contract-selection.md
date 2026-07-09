# Result Loop Contract Selection Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, enforcement, result-loop, operational-work-history, learning-loop |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | docs/operations/result-loop-contract-plan.md, docs/operations/operational-work-history.md, docs/operations/operational-work-history-rollout.md, docs/operations/result-loop-contract-audit-checklist.md |
| Patterns | governance evidence pattern (same CI-generated-artifact pattern as operational-work-history) |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-result-loop-contract.py, scripts/enforcement/check-scaling-extension.py, scripts/enforcement/check-operational-work-history-evidence.sh, scripts/enforcement/tests/test-collect-pr-work-history.sh, scripts/enforcement/tests/test-operational-work-history-evidence.sh, scripts/enforcement/tests/test-result-loop-contract.sh, scripts/enforcement/tests/test-scaling-extension.sh, .github/workflows/pr-policy.yml, .github/workflows/enforcement-tests.yml |
| Evidence to check | docs/operations/known-gaps.tsv row 27; docs/operations/operational-readiness-audit.md; scripts/enforcement/check-route-plan-contract.sh; scripts/enforcement/result-loop-requirements.tsv; scripts/enforcement/project-type-roadmaps.tsv; scripts/monitoring/collect-pr-work-history.py; scripts/enforcement/check-operational-work-history-evidence.sh |
| User decisions required | none — user explicitly chose extending Operational Work History with a deterministic `selected_result_loop_contract` dimension over wiring `check-route-plan-contract.sh`'s 8-field Route Plan requirement |
| selected_project_type | engineering-os-governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | scripts/enforcement/project-type-roadmaps.tsv#engineering-os-governance |
| selected_result_loop_contract | engineering-os-governance (scripts/enforcement/result-loop-requirements.tsv#engineering-os-governance) |
| required_user_simulation | fixture PR bodies/artifacts in scripts/enforcement/tests/test-collect-pr-work-history.sh and test-operational-work-history-evidence.sh |
| local_creator_review_path | local `scripts/enforcement/tests/test-*.sh` sweep plus real PR CI job logs |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_policy_rule | Operational Work History Evidence schema in the PR body, validated against the CI-generated artifact |
| Target paths | scripts/enforcement/result-loop-requirements.tsv, scripts/enforcement/project-type-roadmaps.tsv, scripts/enforcement/policy-gate-dependencies.tsv, scripts/monitoring/collect-pr-work-history.py, scripts/enforcement/check-operational-work-history-evidence.sh, scripts/enforcement/tests/test-collect-pr-work-history.sh, scripts/enforcement/tests/test-operational-work-history-evidence.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.d/operational-work-history.tsv, docs/operations/operational-work-history.md, docs/operations/operational-work-history-rollout.md, docs/operations/result-loop-contract-plan.md, docs/operations/result-loop-contract-audit-checklist.md, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, templates/web-application/README.md, scripts/enforcement/check-known-gaps.sh |

## Task 5 addendum — negative-evidence throwaway branch

`templates/web-application/README.md` and `scripts/enforcement/check-known-gaps.sh` are touched only
on the throwaway `test/work-history-result-loop-negative-evidence-do-not-merge` branch, as a deliberate
negative fixture proving a real PR with an ambiguous (two-candidate) diff and no declared
`selected_result_loop_contract:` field is blocked by real CI with the expected `ERROR_FOR_AGENT`. Both
edits are trivial (a comment) and reverted by closing the branch's PR unmerged — this is evidence
generation, not a real change to either file's behavior.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| docs/operations/known-gaps.tsv row 27 | checked | Open: manifest-completeness dimension is enforced, but per-PR `selected_result_loop_contract` declaration is not — a real chatgpt-codex-connector review on PR #237 found this. |
| docs/operations/operational-work-history.md | checked | Documents the CI-generated artifact/gate that already covers automatic_sources + learning-loop routing, but not any result-loop-contract field. |
| docs/operations/operational-work-history-rollout.md | checked | Stage 1 has no automatic filename-only exemption; real-PR evidence log for PRs #234/#235/#236 established the closure-bar pattern this task extends. |
| scripts/enforcement/check-result-loop-contract.py | checked | Validates result-loop-requirements.tsv/project-type-roadmaps.tsv manifest completeness for `status in {active,required}` rows only; `exempt`-status rows are skipped by both the forward per-project loop and (for project-type-roadmaps.tsv coverage) require no docs/pattern/skill coverage. |
| scripts/enforcement/check-scaling-extension.py | checked | Scans ALL result-loop-requirements.tsv rows (any status) against project-type-roadmaps.tsv's full row set (any status) for the reverse "referenced without roadmap" check, so a new `engineering-os-governance` row needs a companion roadmap row of any status, not just active ones. Its forward active-only coverage loop (docs/pattern/skill/template) does not fire for `status=exempt`. |
| scripts/enforcement/check-route-plan-contract.sh | checked | Confirmed via repo-wide grep: still referenced only by its own `test-required-gates-map.sh`; stays unwired by explicit design in this task. |
| scripts/monitoring/collect-pr-work-history.py | checked | Collector already reads `--pr-body-file`; extending it to also derive/validate `selected_result_loop_contract` keeps the same "collector computes, checker enforces" architecture. |
| scripts/enforcement/check-operational-work-history-evidence.sh | checked | Already reads the artifact as sole source of truth for OWH facts; extending it to read a new `result_loop_contract` key follows the same pattern, without re-parsing the PR body for this new field. |
| templates/web-application/README.md | checked | Confirmed to exist — usable as the `templates/<id>/` fixture path for ambiguity tests and the real negative-evidence PR. |

## Documentation Asset Evidence

- internal: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/operational-work-history.md`; `docs/operations/operational-work-history-rollout.md`; `docs/operations/result-loop-contract-plan.md`; `docs/operations/result-loop-contract-audit-checklist.md`.
- context7: not required — internal-only governance/checker/test/manifest/workflow work; no third-party library, framework, SDK, or API is introduced or touched.
- decision: extend the existing CI-generated Operational Work History artifact/gate with one new deterministic dimension instead of wiring the old 8-field Route Plan checker or inventing a parallel gate/workflow.

## Connector Evidence

- GitHub: repository reads/writes, real PR creation/CI inspection for the positive and negative evidence PRs (Tasks 4/5).

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, `docs/operations/known-gaps.tsv` row 27, PR #237's real `chatgpt-codex-connector` review finding, PR #228/#233's prior plans (`.claude/plans/result-loop-gate-wiring.md`, `.claude/plans/operational-work-history.md`) read for precedent.
- action: read the merged main state of every source-of-truth file above via GitHub-backed local checkout before any edit; opened real ready-for-review PR #239 exercising the new gate on its own real diff (Task 4); a real throwaway ready-for-review PR proving the negative case (Task 5) follows once #239 is green.
- result: opened PR #239 (`yotamfried-ux/Engineering-OS`); `chatgpt-codex-connector` and CodeRabbit real reviews on PR #239 found two valid classification bugs plus one markdown-lint issue, fixed in commit 36b85c2.
- decision: implemented the fix by reusing the existing `pr-policy.yml` / `check-pr-review-evidence.sh` / `check-operational-work-history-evidence.sh` call chain and adding no new workflow, no new top-level checker script, no new manifest file beyond the two required rows in the existing result-loop-requirements.tsv / project-type-roadmaps.tsv manifests; changed the path-classification logic per the real review findings on PR #239.
- target: scripts/enforcement/result-loop-requirements.tsv; scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/policy-gate-dependencies.tsv; scripts/monitoring/collect-pr-work-history.py; scripts/enforcement/check-operational-work-history-evidence.sh.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — this plan committed before edits.
- `source.github-repo-read` — repository files and prior merged PR state read.
- `validation.policy-change-has-validator` — extends existing checker/collector with existing and extended fixtures; no unvalidated new behavior.
- `validation.actions-checked` — no `.github/workflows/*.yml` changes in this task (pr-policy.yml already wires the two extended scripts); if that assumption changes during implementation this evidence will be updated.
- `validation.coderabbit-policy` — review or fallback required before merge.

## Capability Waiver

- `template.project-template-checked` — the Task 5 negative-evidence branch adds a single throwaway
  comment line to `templates/web-application/README.md` purely to create a real ambiguous two-candidate
  diff for the result-loop-contract negative fixture; it is not a real template selection, extension, or
  usage decision, so the full template-checked evidence (architecture review, stack selection, etc.)
  does not apply. The branch is closed unmerged once the negative CI evidence is captured.

## Claude Run Trace

- goal: close the per-PR declaration blind spot in `gap:result-loop-contract-enforcement` without reintroducing the 8-field Route Plan requirement or a broad docs exemption.
- hypothesis: a collector-side deterministic derivation (changed-path classification against the existing result-loop-requirements.tsv project_type_id set, plus a new non-scaffolded `engineering-os-governance` sentinel id for Engineering OS's own governance/tooling surface) covers the real-world case with zero new required PR-body fields for the overwhelming majority of PRs, falling back to one minimal declared field only when genuinely ambiguous.
- connectors: GitHub.
- steps: read all source-of-truth docs/checkers/manifests/tests; verified `check-scaling-extension.py`'s cross-manifest requirements to choose a `status=exempt` sentinel row (avoiding new documentation-sources/pattern/skill manifest coverage); implement collector derivation + checker validation; extend fixtures; open real positive PR (Task 4) and real negative PR (Task 5); close the gap only if both hold.
- evidence: local checker/test runs; real CI job logs on both evidence PRs.
- rejected: wiring `check-route-plan-contract.sh`'s 8 fields; adding an `active` roadmap row for a governance contract (would require documentation-sources.tsv/pattern-requirements.tsv/skill-requirements.tsv coverage); a broad `docs/*` required-false exemption (rejected per the task's explicit "do not add a broad docs exemption" and Stage 1's existing "no automatic filename-only exemption" precedent).
- result: (updated once implementation and both evidence PRs are complete).
- follow-up: none planned beyond this task's scope.

## Graphify Usage Evidence

- source: graphify explain query against graphify-out/graph.json.
- action: ran `graphify explain "result-loop-requirements.tsv"`, `graphify explain "collect-pr-work-history.py"`, `graphify explain "check-operational-work-history-evidence.sh"`, `graphify explain "check-pr-review-evidence.sh"`, `graphify explain "check-known-gaps.sh"`, and `graphify explain "templates/web-application/README.md"` before editing.
- result: no graph node exists for the TSV manifests, for `collect-pr-work-history.py`/`check-operational-work-history-evidence.sh`, or for `templates/web-application/README.md` (untracked/unindexed in this graph snapshot, consistent with prior plans' finding that TSV manifests, docs, and some enforcement scripts have no graph coverage); `check-pr-review-evidence.sh` and `check-known-gaps.sh` each have a node with a single `[contains]` edge to itself, confirming both are small, self-contained call sites with no wider blast radius from this change.
- decision: since graph coverage does not extend to the primary target files, verified the actual call chain and schema directly by reading `check-pr-review-evidence.sh`, `check-operational-work-history-evidence.sh`, and `collect-pr-work-history.py` source instead of relying on graph traversal; the two Task-5 negative-fixture files (`check-known-gaps.sh`, `templates/web-application/README.md`) receive only a trivial, reverted-on-close comment edit, not a real behavior change.
- target: scripts/enforcement/result-loop-requirements.tsv; scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/policy-gate-dependencies.tsv; scripts/monitoring/collect-pr-work-history.py; scripts/enforcement/check-operational-work-history-evidence.sh; scripts/enforcement/tests/test-collect-pr-work-history.sh; scripts/enforcement/tests/test-operational-work-history-evidence.sh; scripts/enforcement/coverage-required-gates.tsv; scripts/enforcement/simulation-coverage.d/operational-work-history.tsv; docs/operations/operational-work-history.md; docs/operations/operational-work-history-rollout.md; docs/operations/result-loop-contract-plan.md; docs/operations/result-loop-contract-audit-checklist.md; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md; templates/web-application/README.md; scripts/enforcement/check-known-gaps.sh

## Lessons Reused

- `lessons-learned/bugs/ci-environment-dependent-fixture-premise.md` — enforcement-script fixtures/gates must not assume host-tool absence or PATH shape that differs between the local sandbox and the GitHub Actions runner. Applied here: the new `derive_result_loop_contract` logic and its fixtures in `scripts/enforcement/tests/test-collect-pr-work-history.sh` are constructed via explicit test inputs (temp repos, explicit changed-path lists), never by assuming a runner tool is absent.
- `lessons-learned/bugs/mawk-ignorecase-unsupported.md` — new case-insensitive/placeholder matching must not rely on gawk-only extensions since CI runners may use a different `awk`. Applied here: all new matching logic is implemented in Python (inside `collect-pr-work-history.py` and `check-operational-work-history-evidence.sh`'s existing Python heredoc), not new awk/sed.
- `lessons-learned/bugs/security-gate-silent-diff-truncation.md` — a gate that silently passes without truly exercising its check is worse than an obviously-missing gate. Directly informs this task's design: the new `result_loop_contract` dimension fails closed (ambiguous-without-declaration, unknown id, placeholder id, missing manifest) rather than defaulting to a silent pass, and Task 5 proves a real negative case blocks for the intended reason.

## Alternatives

- Wiring `check-route-plan-contract.sh`'s 8-field per-PR declaration into real PR-diff CI gating — rejected per explicit user decision.
- Adding a new `active`-status roadmap row for a governance project type — rejected: would cascade into requiring `documentation-sources.tsv`/`pattern-requirements.tsv`/`skill-requirements.tsv` coverage via `check-scaling-extension.py`, a large blast radius into the already-closed `scaling-extension-enforcement`/`registry-coverage-backfill` gaps for no real benefit.
- A broad `docs/*` or filename-only "no contract required" exemption — rejected per the task's explicit instruction and Stage 1's existing no-exemption precedent; the only `required:false` path is a true empty diff (`empty_run`).
- A brand-new standalone checker script/workflow for this dimension — rejected in favor of extending the existing collector/checker pair already wired into `pr-policy.yml`, avoiding workflow/gate sprawl.

## Affected Surfaces

- `scripts/enforcement/result-loop-requirements.tsv`
- `scripts/enforcement/project-type-roadmaps.tsv`
- `scripts/enforcement/policy-gate-dependencies.tsv`
- `scripts/monitoring/collect-pr-work-history.py`
- `scripts/enforcement/check-operational-work-history-evidence.sh`
- `scripts/enforcement/tests/test-collect-pr-work-history.sh`
- `scripts/enforcement/tests/test-operational-work-history-evidence.sh`
- `scripts/enforcement/coverage-required-gates.tsv`
- `scripts/enforcement/simulation-coverage.d/operational-work-history.tsv`
- `docs/operations/operational-work-history.md`
- `docs/operations/operational-work-history-rollout.md`
- `docs/operations/result-loop-contract-plan.md`
- `docs/operations/result-loop-contract-audit-checklist.md`
- `docs/operations/known-gaps.tsv`
- `docs/operations/operational-readiness-audit.md`

## Data/State Impact

- No application data impact. `.engineering-os/work-history/` stays a gitignored, CI-workspace-only build product; the new `result_loop_contract` key is metadata-only (ids, short reasons, counts — no raw paths or prose).

## Integration Impact

- `pr-policy.yml`'s existing artifact-generation and evidence-validation steps now also compute and enforce `selected_result_loop_contract` for PRs with changed files, with no new workflow steps.
- Downstream target projects that install Engineering OS's policy gates (`install-policy-gates.sh`) get `result-loop-requirements.tsv` copied via a new `policy-gate-dependencies.tsv` row, so the collector can resolve the manifest post-install.
- No existing gate is weakened; `check-route-plan-contract.sh` stays unwired.

## Validation Plan

- `python3 scripts/enforcement/check-result-loop-contract.py --root .`
- `python3 scripts/enforcement/check-scaling-extension.py --root .`
- `bash scripts/enforcement/tests/test-collect-pr-work-history.sh`
- `bash scripts/enforcement/tests/test-operational-work-history-evidence.sh`
- `bash scripts/enforcement/tests/test-result-loop-contract.sh`
- `bash scripts/enforcement/tests/test-scaling-extension.sh`
- `bash scripts/enforcement/check-known-gaps.sh` / `check-readiness-audit.sh` / `check-simulation-coverage.sh`
- Full local `scripts/enforcement/tests/test-*.sh` sweep
- Real CI on the positive evidence PR (Task 4) and the negative evidence PR (Task 5)

## Open Questions

- None outstanding — user approved the design in plan-mode review.

## Progress Lifecycle Evidence

- start: read all source-of-truth docs/checkers/manifests/tests listed above before any edit; this plan committed before implementation.
- mid: as of commit a79c1af, added the `engineering-os-governance` status=exempt rows to `result-loop-requirements.tsv`/`project-type-roadmaps.tsv` (verified `check-result-loop-contract.py --root .` and `check-scaling-extension.py --root .` both still pass, confirming zero blast radius into those closed gates); implemented `derive_result_loop_contract` in `collect-pr-work-history.py` and validation of the new `result_loop_contract` artifact key in `check-operational-work-history-evidence.sh`; extended `test-collect-pr-work-history.sh` and `test-operational-work-history-evidence.sh` with derived/declared/ambiguous/unknown-id/placeholder/declared-unrelated/PR-body-cannot-override/route-plan-contract-stays-unwired fixtures; updated `coverage-required-gates.tsv`/`simulation-coverage.d/operational-work-history.tsv` notes; updated the six design docs (`operational-work-history.md`, `operational-work-history-rollout.md`, `result-loop-contract-plan.md`, `result-loop-contract-audit-checklist.md`, `known-gaps.tsv` row 27, `operational-readiness-audit.md`) describing the new mechanism while `known-gaps.tsv` row 27 stays `status=open` (real PR evidence is a separate, not-yet-satisfied closure requirement). Full local `test-*.sh` sweep (83 suites) passes clean. Opened PR #239 as the intended real positive-evidence PR (its own diff is entirely governance-surface, so it should self-derive to `engineering-os-governance`).
- pre-merge: after commit 36b85c2, the last code/config/test change on the implementation branch, a real `chatgpt-codex-connector` review on PR #239 found two valid classification bugs (`templates/rag-system` not resolving through its `ai-agent` alias; ordinary downstream-app paths silently defaulting to `engineering-os-governance`) and CodeRabbit found one markdown-lint issue; all three fixed in commit 36b85c2 with two new regression fixtures. Full local `scripts/enforcement/tests/test-*.sh` sweep (83 suites) passes clean; `check-known-gaps.sh`, `check-readiness-audit.sh`, `check-simulation-coverage.sh`, `check-result-loop-contract.py --root .`, and `check-scaling-extension.py --root .` all pass locally. PR #239's real CI went fully green on head SHA 380098c after cancelling and re-running a runner-congestion-stuck pr-policy job, confirmed by real job logs printing "operational work history evidence passed" against real, non-fixture PR content — this is the Task 4 real positive evidence.
- pre-merge: on the throwaway `test/work-history-result-loop-negative-evidence-do-not-merge` branch, after commit 6455944 (the last code/config/test change on that branch), the deliberate two-candidate-no-declaration fixture is ready for a real negative-evidence PR; expect the real `pr-policy` job to fail with an `ERROR_FOR_AGENT` about a missing `selected_result_loop_contract:` declaration, captured as the Task 5 real negative evidence, then the PR is closed without merging.

## DoD (this implementation commit)

- [x] Add `engineering-os-governance` rows to `result-loop-requirements.tsv` and `project-type-roadmaps.tsv` (status=exempt, all cells non-empty and concrete).
- [x] Add `pr-policy.yml -> scripts/enforcement/result-loop-requirements.tsv` to `policy-gate-dependencies.tsv`.
- [x] Implement `derive_result_loop_contract` in `collect-pr-work-history.py` and add the `result_loop_contract` artifact key.
- [x] Implement validation of `result_loop_contract` in `check-operational-work-history-evidence.sh`.
- [x] Extend `test-collect-pr-work-history.sh` and `test-operational-work-history-evidence.sh` with the required positive/negative fixtures.
- [x] Update `coverage-required-gates.tsv` and `simulation-coverage.d/operational-work-history.tsv` notes.
- [x] Update design docs (Task 1 list) describing the new mechanism truthfully, keeping `known-gaps.tsv` row 27 status `open`.
- [x] Full local `test-*.sh` sweep passes clean (83/83).

## Remaining before `result-loop-contract-enforcement` can close (tracked, not part of this commit's DoD)

These genuinely cannot be true until after this implementation is pushed and real CI runs against it, so
they are intentionally not checkboxes in this commit's DoD (per `quality-gates.md`'s DoD-completion
gate, which reads this plan file's own state):

1. Open a real positive-evidence PR (this implementation, ready for review), confirm real CI green.
2. Open a real negative-evidence PR/branch, ready for review, confirm real CI fails with the expected
   `ERROR_FOR_AGENT`, close without merging.
3. Update `known-gaps.tsv` row 27 and `operational-readiness-audit.md` to `closed`/`Enforced` only once
   1 and 2 both hold, in a later commit/checkpoint.
4. Zero open review threads before merge.
