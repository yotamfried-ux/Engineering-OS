# Readiness PR D — PR-review quality schema + merge-readiness artifact

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance |
| Domain tags | readiness, enforcement, governance |
| Task-router evidence | core/task-router.md checked; routed via routing_matrix section 7 |
| Workflow evidence | core/workflow.md checked; plan-file fallback carries the spec |
| Target paths | .github/workflows/pr-policy.yml, scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/tests/test-pr-review-evidence.sh, scripts/enforcement/check-merge-readiness.sh, scripts/enforcement/tests/test-merge-readiness.sh, scripts/install-policy-gates.sh, scripts/enforcement/tests/test-clean-install-and-usage.sh, docs/operations/merge-readiness-checklist.md, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, documentation-asset-policy, plan-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

PR D closes the two remaining P1/P2 governance gaps from the readiness program: `gap:pr-review-quality-schema` (the PR-review evidence validator is inline workflow python with no fixture coverage, so shallow/vague review evidence is not tested) and `gap:merge-readiness-artifact` (no deterministic PR-body artifact records base, expected head SHA, CI, threads, and approval before merge). Both are extraction-plus-hardening: behavior-preserving extraction first (matching the PR A extraction pattern), then a strictly additive strengthening pass, then fixtures for every new deterministic claim.

## Alternatives

- Leave the review-evidence validator as inline workflow YAML python — rejected: unfixture-testable, so shallow/vague review evidence regressions would go undetected exactly as `gap:pr-review-quality-schema` states.
- Automate the merge decision itself once the artifact is present — rejected: `core/git-policy.md` and `docs/operations/merge-readiness-checklist.md` require the merge decision to stay human; the artifact records evidence for that decision, it does not replace it.
- Validate `checks:`/`evidence:` fields only for non-empty length — rejected: length-only checks would not catch a `checks:` field naming no real gate, which is the exact quality gap this PR closes.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read this session before writes.
- `workflow.workflow-read` — core/workflow.md read this session before writes.
- `plan.route-plan-before-write` — this plan is committed before the first code change of PR D.
- `source.github-repo-read` — GitHub MCP read merged main state (PR #181/#182 merge commits, known-gaps.tsv, operational-readiness-audit.md, merge-readiness-checklist.md) before branching for PR D.
- `validation.policy-change-has-validator` — the extracted PR-review-evidence validator and the new merge-readiness-artifact validator both ship with fixture suites.
- `validation.actions-checked` — pr-policy.yml changes and CI results for the head SHA are verified before merge readiness.
- `validation.coderabbit-policy` — dedicated branch, draft PR, review evidence in PR body, merge only on explicit approval.

## Connector Evidence

- github: read merged main state (PR #181/#182 merge commits, known-gaps.tsv, operational-readiness-audit.md) via MCP before branching.

## Connector Selection Waiver

Notion is required for governance-class work by connector policy, but the Notion MCP connector is unavailable in this remote session environment; the approved fallback from core/workflow.md stage 1 applies — this plan file under .claude/plans/ carries the spec and progress validation.

## Connector Usage Evidence

- source: github repository yotamfried-ux/Engineering-OS — docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, docs/operations/merge-readiness-checklist.md, .github/workflows/pr-policy.yml, scripts/enforcement/check-merge-readiness.sh.
- action: github MCP get_file_contents confirmed the merged PR B/C state and the exact open-gap rows (pr-review-quality-schema, merge-readiness-artifact, install-downstream-behavior) before branching from main.
- result: the two gap rows and the existing merge-readiness-checklist.md narrative fixed the exact field set required (base, expected-head-sha, ci, threads, approval) and confirmed check-merge-readiness.sh already exists as the workflow-run validator this artifact must cross-check against.
- decision: github findings selected the PR D scope — extract+harden check-pr-review-evidence.sh from pr-policy.yml's inline python, add the `## Merge Readiness` PR-body schema to the same validator, and closure bookkeeping in docs/operations/known-gaps.tsv and operational-readiness-audit.md.
- target: .github/workflows/pr-policy.yml, scripts/enforcement/check-pr-review-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: docs/operations/merge-readiness-checklist.md, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/check-merge-readiness.sh, .github/workflows/pr-policy.yml.
- context7: not required because this change edits internal Engineering OS governance enforcement (a bash/python validator extracted from workflow YAML) and does not implement or integrate any external library, framework, SDK, or API.
- decision: the existing merge-readiness-checklist.md narrative fixed the exact Merge Readiness field set (base, expected-head-sha, ci, threads, approval), and the existing pr-policy.yml inline python fixed the review-evidence field set (reviewer/scope/checks/risks/decision/evidence or source/result/decision) that the extraction must preserve byte-for-byte before strengthening.

## Graphify Usage Evidence

- source: graphify query over graphify-out/graph.json for pr-policy/merge-readiness gate wiring.
- action: graphify query oriented the workflow-to-checker dependency map before reading pr-policy.yml and check-merge-readiness.sh.
- result: the graph confirmed check-merge-readiness.sh has no sibling test-merge-readiness.sh yet and pr-policy.yml has no extracted script sibling, consistent with the two open gap rows.
- decision: graph finding confirmed both extractions are genuinely new (not a rename of existing tested code), so this PR must ship both scripts with full fixture suites rather than only adding cases to an existing test file.
- target: .github/workflows, scripts/enforcement, scripts/enforcement/tests, scripts/install-policy-gates.sh, docs/operations

## Template Gap Waiver

No project template applies: this is internal governance/enforcement maintenance inside Engineering OS itself; templates/ entries cover application project scaffolds and are out of scope for validator and workflow edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| .github/workflows/pr-policy.yml | checked |
| scripts/enforcement/check-merge-readiness.sh | checked |
| docs/operations/merge-readiness-checklist.md | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/git-policy.md | checked |

## Claude Run Trace

- goal: close gap:pr-review-quality-schema and gap:merge-readiness-artifact with fixture-tested, behavior-preserving-then-hardened validators.
- hypothesis: extracting the inline pr-policy.yml python into a standalone script first (no behavior change) makes it fixture-testable, then adding a `checks:` real-gate-name requirement and a `## Merge Readiness` schema closes both gaps without weakening the existing review-evidence contract.
- connectors: github MCP confirmed merged main state and the exact open-gap rows before branching; notion_progress_validated: waived — Notion unavailable in this environment, plan-file fallback carries progress validation per the Connector Selection Waiver.
- steps: extract check-pr-review-evidence.sh behavior-preserving from pr-policy.yml; add shallow/vague-checks negative fixtures; add the checks-name-a-real-gate requirement; add the Merge Readiness schema (base/expected-head-sha/ci/threads/approval) to the same validator; cross-check expected-head-sha against github.event.pull_request.head.sha in the workflow; update merge-readiness-checklist.md's cross-reference; flip both gaps to closed with concrete artifacts; update audit rows; fix a Codex-flagged downstream install gap where the extracted script was not copied to installed target projects; fix a CodeRabbit-flagged vague-value detection bug and real-gate-token narrowness that this very PR's own CI run hit.
- evidence: scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/tests/test-pr-review-evidence.sh, .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/install-policy-gates.sh, scripts/enforcement/tests/test-clean-install-and-usage.sh.
- rejected: automating the merge decision itself, and length-only field validation, were rejected as violating the human-merge-decision rule and as insufficient to catch the quality gap respectively.
- result: the extraction and hardening landed; CI and reviewer feedback caught four real gaps (missing capability evidence, missing downstream install copy, an overbroad vague-value regex, a too-narrow real-gate token matcher), all fixed and re-verified.
- follow-up: PR E covers install-downstream-behavior comprehensively across the other pre-existing workflow/script dependencies (connector-evidence-policy.yml, workflow-evidence-policy.yml, capability-evidence-policy.yml, documentation-asset-policy.yml all have the same latent installer gap, not introduced by this PR and out of this PR's scope).

## Progress Lifecycle Evidence

- start: plan committed on claude/engineering-os-readiness-pr-b (reused for PR D after branch-deletion was blocked at the git-proxy level; see Scope note below) before any checker, workflow, or doc edits for PR D.
- mid: check-pr-review-evidence.sh extracted and hardened, test-pr-review-evidence.sh (13 fixtures) added, pr-policy.yml rewired, merge-readiness-checklist.md cross-referenced, and both gaps flipped to closed in commit 513fb0b; targeted and full suites re-ran green after the step.
- pre-merge: after the last code/config/test change the full enforcement suite ran green except the pre-existing test-plan-scope environment case that fails identically on pristine main in this container; check-known-gaps.sh, check-readiness-audit.sh, and range-level workflow/documentation-asset/capability evidence policies re-verified before push.
- pre-merge: after CI caught two real gaps (missing source.github-repo-read capability evidence; install-policy-gates.sh not copying check-pr-review-evidence.sh to installed targets, flagged by Codex on PR #183), both were fixed with a regression fixture and the full suite was re-verified green.
- pre-merge: after CodeRabbit flagged the vague-value detection regex (now anchored to the whole field value, since substring matching rejected legitimate answers containing common generic words) and the real-gate token matcher (broadened to enforce-*.sh with word-boundary matching, deduplicated into a shared helper) plus a persist-credentials hardening nitpick on the Checkout step, all four were fixed and the full suite plus test-pr-review-evidence.sh were re-verified green.

## Lessons Reused

- lessons-learned/bugs/ci-environment-dependent-fixture-premise.md
  - Applied because: this PR adds a new fixture suite (test-pr-review-evidence.sh) under scripts/enforcement/tests, the exact path this lesson's environment-dependent-premise mitigation covers; new fixtures must construct any tool/environment assumptions hermetically rather than assuming host inventory.
  - Prevention: build shallow/vague-evidence fixtures as static PR-body text inputs (no live GitHub state, no host tool dependency) so they run identically in CI and locally.

## DoD

- [x] check-pr-review-evidence.sh extracted from pr-policy.yml with byte-for-byte preserved existing behavior — verified by test-pr-review-evidence.sh positive fixtures (external_review_with_merge_readiness_passes, fallback_with_real_gate_and_concrete_evidence_passes).
- [x] checks: field must name a real gate/workflow token (cross-checked against .github/workflows/*.yml names or check-*/enforce-*/enforcement-tests script basenames, word-boundary matched) — verified by fallback_shallow_checks_fails and merge_readiness_ci_not_real_gate_fails.
- [x] evidence: field must contain a concrete artifact reference (path, run URL, or #<PR/issue number>) — verified by fallback_vague_evidence_fails.
- [x] `## Merge Readiness` PR-body section required with base/expected-head-sha/ci/threads/approval fields, cross-checked against github.event.pull_request.head.sha — verified by missing_merge_readiness_section_fails, merge_readiness_placeholder_approval_fails, merge_readiness_non_sha_value_fails, merge_readiness_sha_mismatch_fails.
- [x] merge-readiness-checklist.md cross-reference updated to point at the new deterministic validator.
- [x] Two gaps flipped to closed with concrete artifacts; audit rows (PR review / external review, Merge safety, Git/branch policy) updated; check-readiness-audit.sh and check-known-gaps.sh green.
- [x] Full local enforcement suite green except the known pre-existing test-plan-scope environment case.
- [x] Draft PR opened with review evidence; merge deferred to explicit approval.
- [x] install-policy-gates.sh copies check-pr-review-evidence.sh to installed target projects so pr-policy.yml stays runnable downstream (Codex review finding on PR #183) — verified by test-clean-install-and-usage.sh's installed-target smoke check.
- [x] Vague-value detection anchored to the whole field value so substantive answers containing generic words in passing are not rejected (CodeRabbit critical finding, confirmed by this PR's own first CI failure) — verified by re-running test-pr-review-evidence.sh and a targeted repro of the shallow-checks fixture's error message.
- [x] Real-gate token matcher broadened to all enforce-*.sh gates with word-boundary matching, deduplicated into require_real_gate() (CodeRabbit major + nitpick findings) — verified by the full test-pr-review-evidence.sh suite.
- [x] Checkout step sets persist-credentials: false (CodeRabbit security nitpick).

## Scope note — branch reuse

PR A's branch was deleted after explicit authorization; PR B and PR C's merged branches could not be deleted (`git push origin --delete` returned HTTP 403 from the git proxy after three retries, even with explicit user authorization to delete). Per explicit user decision, `claude/engineering-os-readiness-pr-b` was reset to fresh `main` (`git checkout -B ... main` + `git push --force-with-lease`) and reused for PR D instead of creating a new branch name, satisfying the one-branch policy without a policy bypass.

## Completed Work

(none yet — plan committed before first code change)

## Remaining Validation Outside This Plan

- PR E covers install-downstream-behavior per the approved program, including the broader pre-existing installer gap shared by connector-evidence-policy.yml, workflow-evidence-policy.yml, capability-evidence-policy.yml, and documentation-asset-policy.yml.
