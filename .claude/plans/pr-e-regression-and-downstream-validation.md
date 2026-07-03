# PR E follow-up — missing-manifest fail-closed regression test + real downstream validation

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance |
| Domain tags | readiness, enforcement, governance, install, testing |
| Task-router evidence | core/task-router.md checked; routed via routing_matrix section 7 |
| Workflow evidence | core/workflow.md checked; plan-file fallback carries the spec |
| Target paths | scripts/enforcement/tests/test-install-policy-gate-coverage.sh, scripts/skill-bootstrap.sh, scripts/enforcement/tests/test-security-review-workflow-generator.sh, docs/operations/connector-verification-matrix.md, docs/operations/skill-verification-matrix.md, docs/README.md |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, documentation-asset-policy, plan-policy, semantic-cleanup-policy, import-cleanup-policy |

## Goal

Close the two follow-up obligations left after PR #184 (PR E) merged:

1. PR #184 made `scripts/install-policy-gates.sh` fail closed when
   `scripts/enforcement/policy-gate-dependencies.tsv` is missing, but no test anywhere
   exercises that installer behavior — the error string
   `missing policy-gate dependency manifest:` appears only in the installer itself, and the
   knowledge graph confirms `test-install-policy-gate-coverage.sh` is the installer's only
   test-side neighbor and it never invokes the installer. Add a hermetic regression test
   proving install succeeds when the manifest exists and fails closed (non-zero exit,
   explicit error, no dependency copies) when it is missing.
2. Prove the merged install contract works in a real downstream project, not only in the
   generated-target fixtures: install Engineering OS into `yotamfried-ux/Expiriens-saas-0.9`,
   run positive/negative/waiver/routing experiments through the actually-installed hooks and
   gates, and record durable connector and skill verification matrices under
   `docs/operations/` classifying every inventory entry by verified status.

## Plan

1. Commit this Route Plan alone, before any code change (start checkpoint).
2. Extend `scripts/enforcement/tests/test-install-policy-gate-coverage.sh` with a hermetic
   installer-behavior section: build a fake `ENGINEERING_OS_HOME` in a temp dir containing
   only the installed workflow YAMLs (derived from the installer's own `for name in` line),
   the dependency manifest, and every manifest-declared dependency file; assert the positive
   install path (exit 0, all deps copied with executable bits) and the negative path
   (manifest removed → non-zero exit, stderr carries the explicit missing-manifest error, no
   `scripts/enforcement/*` dependency lands in the target). Verify the negative case catches
   the pre-#184 silent-skip behavior by temporarily reverting the installer guard locally.
3. Run the full downstream validation program in the real Expiriens-saas-0.9 clone on its
   designated branch: clean install, reinstall idempotency, positive gate path, negative
   bypass attempts, waiver behavior, connector routing, skill routing, gap inventory.
4. Record `docs/operations/connector-verification-matrix.md` and
   `docs/operations/skill-verification-matrix.md` from the real inventory
   (external-systems/README.md, capability-registry.yaml, external-skills/README.md) plus
   live checks — no invented entries; classify honestly (verified / documented-only /
   manual-by-design / unsupported-in-env / gap).
5. Full local validation, push, ready-for-review PRs in both repos with Review Fallback
   Evidence and Merge Readiness sections; merge deferred to explicit owner approval.

## Alternatives

- Put the missing-manifest regression case in `test-clean-install-and-usage.sh` instead —
  rejected: that suite exercises the full `use-in-project.sh` contract per run and its
  experiments assume a successful install; manifest correctness and installer fail-closed
  behavior are the exact ownership of `test-install-policy-gate-coverage.sh`, which the task
  contract also names as the preferred home.
- Test the negative path by temporarily renaming the real repo manifest during the test —
  rejected: mutating the repo under test is not hermetic and races with parallel test runs;
  a disposable fake ENGINEERING_OS_HOME keeps the repo read-only and the fixture
  deterministic on any machine.
- Record connector/skill verification only in this plan file instead of durable
  `docs/operations/` matrices — rejected: plan files are temporary per-PR artifacts by the
  conceptual-ownership table, while verification state must stay auditable next to
  known-gaps.tsv and the readiness audit; the matrices are the durable owner.
- Reuse the burn-in session's Expiriens branch (`claude/eos-acceptance-burnin-o1birt`, PR #1)
  and extend it — rejected: that branch belongs to another open PR pending owner review;
  this session's designated branch starts from clean `main`, which is exactly the controlled
  clean-install state Experiment 1 requires.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read this session before writes.
- `workflow.workflow-read` — core/workflow.md read this session before writes.
- `plan.route-plan-before-write` — this plan is committed before the first code change.
- `source.github-repo-read` — GitHub MCP read PR #184 (merged, head 4f0b137), open PRs
  #185/#186, Expiriens-saas-0.9 PR #1 and branch list before branching this work.
- `validation.policy-change-has-validator` — the change IS a validator: a regression test
  for the installer's fail-closed contract; the matrices ship with the coverage validators
  (`check-required-connectors.sh --check-coverage`, `check-required-skills.sh --check-coverage`)
  re-run as proof.
- `validation.coderabbit-policy` — dedicated branch, ready-for-review PR, review evidence in
  PR body, merge only on explicit owner approval.

## Connector Evidence

- github: read merged/open PR state (#184 merged, #185/#186 open, Expiriens #1 open) and
  branch inventories in both repos via MCP before branching.

## Connector Selection Waiver

Notion is required for governance-class work by connector policy, but the Notion MCP
connector round-trip is not authenticated for spec management in this remote session; the
approved fallback from core/workflow.md stage 1 applies — this plan file under
.claude/plans/ carries the spec and progress validation.

## Connector Usage Evidence

- source: github repositories yotamfried-ux/Engineering-OS and yotamfried-ux/Expiriens-saas-0.9 —
  PR #184 body/state, open PR list (#185, #186), Expiriens PR #1, branch lists.
- action: github MCP pull_request_read confirmed PR #184 is merged with the installer
  fail-closed fix already on main at scripts/install-policy-gates.sh; list_pull_requests and
  list_branches confirmed the prior burn-in session's open artifacts so this work does not
  duplicate or disturb them.
- result: scripts/install-policy-gates.sh on main (merge commit 8cb774d) already fails closed
  with `missing policy-gate dependency manifest:`; no test in scripts/enforcement/tests/
  exercises that path; PRs #185/#186 and Expiriens PR #1 are open on other branches pending
  owner approval.
- decision: selected and limited this PR's scope based on the github findings — (a) added the
  missing regression test in test-install-policy-gate-coverage.sh, (b) added the
  real-downstream validation matrices, and (c) later added the skill-bootstrap.sh chunking fix
  from the Codex finding on Expiriens PR #2 — while explicitly keeping the installer itself
  and the open PRs' (#185/#186/Expiriens #1) fixes out of scope.
- target: scripts/enforcement/tests/test-install-policy-gate-coverage.sh,
  docs/operations/connector-verification-matrix.md, docs/operations/skill-verification-matrix.md

## Documentation Asset Evidence

- internal: scripts/install-policy-gates.sh, scripts/enforcement/policy-gate-dependencies.tsv,
  scripts/enforcement/tests/test-install-policy-gate-coverage.sh,
  scripts/enforcement/tests/test-clean-install-and-usage.sh, scripts/use-in-project.sh,
  external-systems/README.md, external-skills/README.md, core/capability-registry.yaml,
  core/connector-policy.md, core/skill-orchestration-policy.md, docs/operations/known-gaps.tsv,
  docs/operations/operational-readiness-audit.md.
- context7: not required because this change edits internal Engineering OS enforcement tests
  and operations documentation (bash and markdown) and does not implement or integrate any
  external library, framework, SDK, or API.
- decision: the installer's own `for name in` line and the manifest rows fix the exact fixture
  contents for the hermetic fake home (enumerated, not guessed); the existing pass/fail +
  mktemp idioms in test-install-policy-gate-coverage.sh fix the shape of the new cases; the
  inventory files fix the exact row set of both matrices.

## Graphify Usage Evidence

- source: graphify query over graphify-out/graph.json for install-policy-gates wiring.
- action: graphify query traversed from install-policy-gates.sh and installed_workflows()
  before editing the test file.
- result: the graph shows test-install-policy-gate-coverage.sh as the installer's only
  test-side neighbor and confirms no node invokes the installer as a subject under test —
  the fail-closed behavior is genuinely uncovered.
- decision: graph finding confirmed the regression test belongs in
  test-install-policy-gate-coverage.sh (extending the existing neighborhood) rather than a
  new test file.
- target: scripts/enforcement/tests/test-install-policy-gate-coverage.sh

## Template Gap Waiver

No project template applies: this is internal governance/enforcement test maintenance and
operations documentation inside Engineering OS itself; templates/ entries cover application
project scaffolds and are out of scope.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/install-policy-gates.sh | checked |
| scripts/enforcement/policy-gate-dependencies.tsv | checked |
| scripts/enforcement/tests/test-install-policy-gate-coverage.sh | checked |
| scripts/enforcement/tests/test-clean-install-and-usage.sh | checked |
| scripts/use-in-project.sh | checked |
| external-systems/README.md | checked |
| external-skills/README.md | checked |
| core/capability-registry.yaml | checked |
| core/connector-policy.md | checked |
| core/skill-orchestration-policy.md | checked |
| core/hooks-policy.md | checked |
| core/git-policy.md | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |

## Claude Run Trace

- goal: add regression coverage proving the installer fails closed without the dependency
  manifest, and prove the merged install contract in the real Expiriens-saas-0.9 repo with
  durable connector/skill verification matrices.
- hypothesis: a hermetic fake ENGINEERING_OS_HOME lets the real installer run both paths
  deterministically on any machine; the real downstream repo will reproduce the generated-target
  fixture results, and any divergence is a genuine new gap for known-gaps.tsv.
- connectors: github MCP confirmed merged/open PR state in both repos before branching;
  notion_progress_validated: waived — Notion unavailable for spec management in this
  environment, plan-file fallback carries progress validation per the Connector Selection Waiver.
- steps: commit plan; write the two installer-behavior cases; prove the negative case catches
  the pre-#184 silent skip via a temporary local revert; run the eight downstream experiments
  in Expiriens-saas-0.9; write both matrices from the real inventories plus live checks;
  full-suite validation; push and open ready-for-review PRs in both repos.
- evidence: scripts/enforcement/tests/test-install-policy-gate-coverage.sh,
  docs/operations/connector-verification-matrix.md,
  docs/operations/skill-verification-matrix.md, this plan file.
- rejected: testing against the real repo manifest via rename (not hermetic), putting the
  regression case in test-clean-install-and-usage.sh (wrong owner), plan-only verification
  records (not durable), reusing the burn-in branch (belongs to an open PR).
- result: recorded per checkpoint below as the work completes.
- follow-up: merge decisions for this PR, #185/#186, and Expiriens #1 stay with the owner.

## Scope addition — Codex finding from the downstream validation PR

Codex review on Expiriens-saas-0.9 PR #2 found that the security-review skill's generated CI
workflow (`security-review-nemotron.yml`, emitted by `scripts/skill-bootstrap.sh`) sliced the
PR diff to `diff[:12000]` before sending it to Nemotron — silently omitting everything past
12000 characters while the security gate stayed green. Root cause lives in this repo's
generator, not in the downstream copy, so the fix lands here per the learning-loop promotion
protocol: the generated workflow now reviews the whole diff in 12000-character chunks (hard
cap 25 chunks) and exits 1 above the cap instead of truncating. Downstream copies refresh on
the next bootstrap run. shellcheck finding count on skill-bootstrap.sh verified identical
before/after the edit (25 pre-existing, none added).

## Progress Lifecycle Evidence

- start: plan committed on claude/engineering-os-pr-e-readiness-6a7v3v before any code,
  config, or test edits.
- mid: the hermetic installer-behavior regression cases landed in bbb1bac (9/9 ok; negative
  case proven to fail on an emulated pre-#184 silent-skip installer via a temporary local
  revert and pass on the real one); the branch was rebased onto main after PR #186 merged mid-run (picking up the mawk check-plan-scope fix; commit ids in this plan are post-rebase); the downstream validation ran in the real
  Expiriens-saas-0.9 repo — clean install verified item-by-item, reinstall idempotent, the
  full installed runtime gate chain exercised positively and negatively, six negative bypass
  paths blocked, six waiver scenarios correct, connector/skill routing correct with both
  coverage validators green — and its PR #2 went through three real CI-gate rejections
  (plan-with-config ordering, checkpoint outside the lifecycle section, non-canonical
  checkpoint marker), each diagnosed, reproduced locally 1:1, and fixed without bypass; the
  Codex review round produced the skill-bootstrap.sh truncation fix (175b2b2, with
  test-security-review-workflow-generator.sh proven bidirectionally and lesson
  security-gate-silent-diff-truncation.md) and the downstream healthcheck deleted-cwd fix;
  the connector and skill verification matrices landed in 44e7434.
- pre-merge: after the last code/config/test change and the rebase onto main (post-#186), the
  FULL enforcement suite ran green — 71/71 test files pass with zero failures, including the
  previously-failing test-plan-scope environment case now fixed by the merged #186; range-level
  gates over origin/main..HEAD re-verified (workflow-evidence, connector-evidence after
  tightening the decision line to impact verbs, documentation-asset, capability
  staged-changes); check-known-gaps.sh 25/25 closed and check-readiness-audit.sh 34 rows pass;
  maintenance-routine PR checklist ran (validate-orphans clean, setup --check ok, graphify
  update ran); ready-for-review PR opened with Merge Readiness evidence; merge stays with the
  owner.

## Lessons Reused

- lessons-learned/bugs/ci-environment-dependent-fixture-premise.md
  - Applied because: the new installer-behavior fixture must run identically in this
    container and on the CI runner — exactly the environment-dependent-premise class this
    lesson covers.
  - Prevention: the fixture constructs its entire ENGINEERING_OS_HOME input set inside
    mktemp space from repo-relative sources only, with no assumption about host tool
    inventory, ~/.engineering-os state, or network.

## DoD

- [x] Route Plan committed before the first code/config/test change of this task.
- [x] Hermetic installer regression cases added to test-install-policy-gate-coverage.sh —
  signal: 9/9 ok on current code; installer_fails_closed_when_manifest_missing fails (exit 1)
  on an emulated pre-#184 silent-skip installer and passes after restore.
- [x] Eight downstream experiments executed in the real Expiriens-saas-0.9 repo — signal:
  experiment outputs recorded in the downstream plan's Progress Lifecycle Evidence and PR #2
  body; gap inventory outcome folded into the matrices (no new open gap rows warranted).
- [x] Connector and skill verification matrices recorded under docs/operations/ — signal:
  check-required-connectors.sh --check-coverage, check-required-skills.sh --check-coverage,
  and test-capability-registry.sh all green; 59/59 registry entries have owner READMEs.
- [x] Codex finding fixed at the root — signal: test-security-review-workflow-generator.sh
  7/7 ok on the fixed generator, exit 1 on the pre-fix generator; lesson file passes the
  learning gate.

## Completed Work

- Route Plan committed alone (3b10fe2); installer fail-closed regression test (bbb1bac);
  skill-bootstrap.sh chunking fix + its regression test (175b2b2); lesson file (a68a4b0);
  verification matrices (44e7434).
- Real downstream validation completed in Expiriens-saas-0.9 (PR #2, ready-for-review).

## Remaining Validation Outside This Plan

- Full local enforcement suite + CI green on the exact head SHA of both PRs.
- CodeRabbit review on both PRs once its rate-limit window reopens.
- Owner merge approval (explicitly out of agent scope).
