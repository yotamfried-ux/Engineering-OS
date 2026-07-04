# Route Plan - user decisions route field

| Field | Decision |
|---|---|
| Task type | governance maintenance |
| Task class | engineering_os_governance |
| Domain tags | governance, enforcement, testing |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Target paths | scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; .claude/plans/enforce-user-decisions-route-field.md |
| Templates | existing governance validator maintenance |
| Architecture guides | docs/operations/merge-readiness-checklist.md |
| Patterns | existing enforcement test fixture style |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | PR #196 diff, workflow runs, head SHA |
| User decisions required | none |

Plan Scope: standard

## Definition of Done

- [x] Route Plan contract includes User decisions required.
- [x] Validator enforces the field.
- [x] Regression test proves a missing field fails.

## Source of Truth Checks

| Source | Status | Result |
|---|---|---|
| core/task-router.md | checked | route plan contract requires user decision handling |
| scripts/enforcement/validate-capability-evidence.sh | checked | field list needs the missing contract field |
| scripts/enforcement/tests/test-capability-evidence.sh | checked | regression fixture covers the missing field |

## Documentation Asset Evidence

- internal: core/task-router.md; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh.
- context7: not required because this is an internal shell and Python validator fixture change with no external library or API integration.
- decision: update the existing validator and its existing test only.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub used for repository files, branch state, PR #196, and workflow checks.

## Connector Usage Evidence

- source: GitHub connector.
- action: GitHub connector checked PR #196 and repository files.
- result: PR #196 branch enforce-user-decisions-route-field updated scripts/enforcement/validate-capability-evidence.sh and scripts/enforcement/tests/test-capability-evidence.sh after base 353b2de0b4f3dd1e27a1f5174b5fb8890877c6cf.
- target: scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh.
- decision: updated a minimal validator and fixture change.

## Skill Evidence

- superpowers used for planning and validation discipline.

## Template/Pattern Rating Waiver

No concrete templates/ or patterns/ asset is selected; this is an internal validator and fixture update.

## Claude Run Trace

- goal: enforce User decisions required in the Route Plan validator.
- hypothesis: adding the field to ROUTE_FIELDS plus a missing-field fixture closes the real gap.
- connectors: GitHub.
- steps: create plan first, update validator, update test, record lifecycle checkpoints, run CI.
- evidence: exact-head workflow results before merge.
- result: validator and regression fixture updated.

## Alternatives

- Considered: patch `validate-capability-evidence.sh` to special-case test-generated Route Plan fixtures — rejected, since the fixtures should reflect the real contract they exercise.
- Chosen: add the missing `| User decisions required | none |` row to each fixture's Route Plan heredoc.

## Affected Surfaces

- `scripts/enforcement/tests/test-runtime-evidence.sh`
- `scripts/enforcement/tests/test-clean-install-and-usage.sh`
- `scripts/enforcement/tests/test-skill-e2e.sh`
- `scripts/enforcement/tests/test-target-install-smoke.sh`
- `scripts/enforcement/tests/test-operational-learning-skills.sh`

## Data/State Impact

- None: no evidence ledger schema or runtime data format changes.

## Integration Impact

- None: no connector or external system changes.

## Validation Plan

- Run each patched test script locally with `bash <script>` and confirm no `FAIL`/`fail:` lines remain.
- Re-run `test-capability-evidence.sh` as a regression guard on the already-fixed validator/fixture pair.
- Confirm PR #196's `enforcement-tests` check turns green in CI after push.

## Open Questions

- None.

## Lessons Reused

- `lessons-learned/bugs/ci-environment-dependent-fixture-premise.md`: these three fixtures run their own local `pre-tool-use-runtime-evidence.sh` invocation inside a `mktemp -d` sandbox, so — unlike the tool-absence case this lesson describes — their pass/fail is driven by the fixture's own Route Plan content, not host-tool presence; still verified each patched fixture locally (not just reasoned about) before relying on CI, per this lesson's prevention guidance.
- `lessons-learned/bugs/mawk-ignorecase-unsupported.md`: `validate-capability-evidence.sh` is Python (not the mawk-based `check-plan-scope.sh` this lesson covers), so its field/case handling is unaffected; confirmed no `IGNORECASE`-dependent awk logic sits between the fixture's `| User decisions required | none |` row and the validator.
- `lessons-learned/bugs/security-gate-silent-diff-truncation.md`: not applicable to this change (no diff-bounding/truncation logic touched); reviewed to confirm the one-line fixture fix does not interact with the security-review workflow generator this lesson patched.

## Progress Lifecycle Evidence

- start: Route Plan created before code or test changes.
- mid: validator and regression test updated after the start checkpoint.
- pre-merge: exact-head CI is required after this checkpoint before merge.
- post-fix: root-caused the remaining `enforcement-tests` CI failure (run 28718102409) to runtime fixture scripts that each generate a temporary Route Plan without the new `User decisions required` field, so `pre-tool-use-runtime-evidence.sh` denied the write each fixture expected to succeed. The CI log's `FAIL`/`fail:` lines named three fixtures (`test-runtime-evidence.sh`, `test-clean-install-and-usage.sh`, `test-skill-e2e.sh`). Grepping every fixture with an `Evidence to check` row for the new field, then running the full local `scripts/enforcement/tests/test-*.sh` suite, surfaced two more hit by the identical root cause (`test-target-install-smoke.sh`, `test-operational-learning-skills.sh`): the same CI log shows the identical deny reason for `test-target-install-smoke.sh` (its final `set -euo pipefail`-wrapped write assertion aborts the script silently on deny, with no printed `FAIL` line and no final "✅ ... passed" echo, which is why an initial keyword search for `FAIL`/`fail:` missed it); `test-operational-learning-skills.sh` was not reached in the tail of the log read but fails locally with the same deny reason and is part of the same enforcement-tests job, so it very likely also contributed to the same CI failure. All five were patched with `| User decisions required | none |` in their Route Plan heredocs; the full local enforcement-tests suite (`for t in scripts/enforcement/tests/test-*.sh`) now reports all green before pushing.
