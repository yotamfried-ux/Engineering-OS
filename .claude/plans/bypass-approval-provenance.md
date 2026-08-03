# Route Plan — Bypass Approval Provenance

## Route Plan

| Field | Decision |
|---|---|
| Task type | security-sensitive Engineering OS authorization hardening |
| Task class | `engineering_os_governance` |
| Domain tags | hooks, authorization, GitHub provider evidence, shell, Python, installer, tests |
| Plan Scope | standard |
| Planning Mode | align PR #264 strictly to the canonical audit gap `bypass-approval-provenance`; remove live-control-plane bootstrap/qualification work that is not part of the gap closure contract |
| Target paths | `.claude/plans/bypass-approval-provenance.md`; `.github/workflows/bypass-*-reusable.yml`; `docs/operations/bypass-control-plane-runbook.md`; `scripts/enforcement/`; `scripts/hooks/`; `templates/bypass-control-plane/` |
| Task-router evidence | `core/task-router.md` routes enforcement/governance changes through the governance workflow and security review. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and `core/hooks-policy.md` require plan-first work, exact-head CI/review, explicit owner approval, protected merge, and post-merge validation. |
| Templates | the control-plane template remains supporting implementation material for future operational enablement; installing or live-qualifying it is not a PR #264 merge prerequisite |
| Architecture guides | `core/hooks-policy.md`; `core/git-policy.md`; `docs/operations/merge-readiness-checklist.md`; canonical audit `docs/operations/operational-readiness-audit.md` |
| Patterns | shared enforcement library, canonical bypass registry, provider-verified approval, fail-closed validation, durable one-shot consumption |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | audit-required bypass positive/negative tests; replay/forgery/fail-closed tests; installed target; full `test-*.sh`; exact-head CI; review reconciliation |
| Evidence to check | canonical audit and `known-gaps.tsv`; current `main`; PR #264 exact head/diff/CI/reviews; bypass policy/config/validator/consumption code and tests |
| User decisions required | explicit owner approval for the final exact head before merge |

## Goal

Close only the canonical `bypass-approval-provenance` implementation gap: a truthy `EOS_BYPASS_*` value is a request, never authorization. A bypass can succeed only with a complete externally verifiable approval bound to the exact gate/action/target and with durable one-shot consumption evidence that the executing process cannot fabricate in the same operation.

## Scope

Implement and verify the audit contract in Engineering OS itself: canonical bypass policy/configuration, provider-backed approval and consumption validation, removal of weaker local fallbacks, enforcement call-site migration, durable metadata-only evidence, focused/full/install tests, exact-head CI and review evidence. Project 8 is unchanged.

A live production deployment of the optional control repository, GitHub App provisioning, credential qualification, manual live approval publication, and a production qualification matrix are **not** prerequisites for merging this implementation. Until an operator later configures such provider infrastructure, the shipped runtime remains fail-closed and bypass authorization is unavailable rather than forgeable.

## Canonical Audit Contract

The source of truth is `docs/operations/known-gaps.tsv` plus the matching checklist in `docs/operations/operational-readiness-audit.md`:

- define one canonical waiver record with approver, approval time, reason, exact gate/target/action scope, expiry or one-shot semantics, and consumption state;
- environment variables may request a bypass but cannot authorize one;
- reject blank/generic, expired, reused, wrong-gate, wrong-target, wrong-scope, missing-issuer, forged, and master-substitution evidence;
- remove weaker local `bypass_active()` fallbacks so every protected gate uses the same validator;
- record accepted approval/consumption metadata without secrets or conversation content;
- run positive/negative/install/full suites, exact-head review, owner-approved merge, and post-merge validation.

No additional live-control-plane readiness claim is part of this gap.

## Root Cause and Architecture

Before this PR, local truthy environment variables could directly activate bypass paths. The implementation replaces that behavior with one canonical policy and validator. Approval identity/scope/freshness are checked against provider evidence; durable claim/marker evidence is written by a separate trusted execution path; repeated or conflicting evidence denies; master bypass requests remain permanently disabled.

The one-shot correction is required by the audit's explicit reused-approval denial. `validate-bypass-approval.py --stage consumed` therefore cannot re-authorize by simply re-reading an old marker; a fresh provider-backed attempt must be tied to the unique durable reservation. This security property remains in scope. The later bootstrap-SHA/live-qualification work was operationalization scope and has been removed from this branch.

## Trust Boundary

- `EOS_BYPASS_*` values are untrusted requests.
- Local ledger evidence is audit-only and never authorizes.
- Provider approval must bind immutable issuer identity, exact protected repository, gate, action, surface, target, fingerprint, target commit, policy digest, creation time and expiry.
- Durable claim/marker evidence is authoritative only when it comes from the pinned trusted writer path; the requesting runtime cannot create that authoritative Issues evidence.
- Missing configuration, missing credentials, provider failure, malformed/ambiguous evidence, replay, wrong binding, rerun, edited evidence, or master substitution fails closed.
- Operational credentials needed to enable legitimate bypasses later are deployment concerns, not a reason to delay merging the anti-forgery enforcement.

## Official Documentation Evidence

- GitHub reusable workflows and least-privilege `GITHUB_TOKEN` semantics support a separate trusted writer path.
- GitHub issue-comment/provider APIs expose immutable provider identity, timestamps and repository bindings needed by the validator.
- GitHub workflow/run metadata supports binding durable consumption evidence to an exact trusted execution.
- Claude hook blocking semantics require enforcement uncertainty to deny rather than silently allow.

## Documentation Asset Evidence

- internal: `CLAUDE.md`; `core/workflow.md`; `core/hooks-policy.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/merge-readiness-checklist.md`.
- context7: not required; this correction is governed by the repository's canonical audit and already-reviewed GitHub provider contract rather than a new vendor integration decision.
- decision: narrowed the PR back to the audit-defined anti-forgery/one-shot enforcement contract and removed live bootstrap/qualification as a merge requirement.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `docs/operations/known-gaps.tsv` | read | `bypass-approval-provenance` requires request-only env vars, complete approval provenance, durable non-local consumption, reused/forged/wrong-scope denial, one valid bounded approval, no weaker local fallback, install/full CI and post-merge validation |
| `docs/operations/operational-readiness-audit.md` | read | checklist matches the registry and does not require GitHub App creation or a live production qualification matrix before merge |
| `scripts/enforcement/lib/evidence.sh` | checked | all bypass requests route to one canonical validator instead of env-only authorization |
| `scripts/enforcement/bypass-policy.tsv` | checked | action-specific requests are explicitly registered and master bypasses are disabled |
| `scripts/enforcement/tests/test-bypass-provider-validation.py` | checked | issuer, binding, expiry, malformed/forged/provider cases are fixture-tested |
| `scripts/enforcement/tests/test-bypass-execution-one-shot.sh` | checked | the regression requires one authorization only and rejects replay |

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-read canonical audit/registry, PR #264 exact head and diff, then force-reset the branch from `eb94bdf4cb52ce9199d2e5a27e67710216e41b51` to clean checkpoint `554ae5b14ec08ddf455325647ab37a3c29eb9333`, removing 11 bootstrap/qualification commits. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, and PR #264.
- action: compared the canonical gap closure contract to the live PR diff and commit history.
- result: the audit requires anti-forgery, exact scope, durable one-shot consumption, fallback removal, tests/CI/review/merge/post-merge; it does not require live control-repository provisioning or GitHub App qualification before merge. The branch was reset by 11 commits to remove that over-scope.
- decision: retained the one-shot/provider trust implementation because reused and forged approval denial are canonical requirements; removed live bootstrap/qualification work and reclassified optional provider deployment as post-merge operational enablement.
- target: PR #264 bypass enforcement implementation and its evidence.

## Capability Evidence

`routing.task-router-read`; `workflow.workflow-read`; `plan.route-plan-before-write`; `source.github-repo-read`; `skill.security-review`; `validation.security-gate-checked`; `validation.actions-checked`; `validation.policy-change-has-validator`; `validation.coderabbit-policy`; `template.project-template-checked`.

## Skill Evidence

- `verification-before-completion` — distinguishes implementation/CI evidence from optional live operational enablement and from post-merge gap closure.
- `security-review` — preserves the actual security properties: request-only env values, exact provider provenance, durable non-local consumption and replay denial.
- `writing-plans` — records the scope correction before the final evidence cycle.

## Definition of Done

- The audit-defined bypass contract is implemented without env-only or local fallback authorization.
- Blank/generic/expired/reused/wrong-gate/wrong-target/wrong-scope/missing-issuer/forged/master-substitution cases deny in deterministic tests.
- One valid bounded approval path passes in the provider-backed test contract.
- Durable one-shot consumption remains required; replay cannot authorize again.
- Accepted authorization records metadata-only evidence without secret/conversation content.
- Installed-target behavior and the full test suite pass.
- Final exact-head required CI is green and review threads are reconciled.
- Explicit owner approval is obtained for the final exact head before merge.
- Post-merge validation and canonical gap closure are separate follow-up lifecycle steps.
- Live control-repository/App provisioning is not a merge requirement; when absent, bypasses fail closed.

## Progress Lifecycle Evidence

- start: plan-first rebuilt implementation started from canonical `main` `6a589971c59561b88cb4abaa0752235b9bb4d5df`.
- mid: provider foundation, canonical policy/validator, call-site migration, fail-closed behavior and installed-target coverage were implemented and reviewed.
- superseded pre-merge: `6855c7d66c08edba02ff9ab9adbcb79c19cc4d1f` had green CI but was later proven to permit repeat authorization from the same approval; that evidence is historical only.
- one-shot regression: `4100a29a4f6a9f65ab0659247531059dd2a90d35` added a regression that failed on the repeat-authorization defect.
- corrected implementation: exact code/docs target `7795c967c1be5ecadd7e31c68da3159067316368` passed 111/111 `test-*.sh`, 0 failures, 0 real timeouts; 192 shell files passed `bash -n`, 42 Python files compiled, 19 YAML files parsed, provider validation/clean install/installed target/one-shot hardening passed. Temporary export workflow was removed in `554ae5b14ec08ddf455325647ab37a3c29eb9333`.
- scope correction: live bootstrap work after `554ae5b14ec08ddf455325647ab37a3c29eb9333` was compared to the canonical audit and removed from the PR branch; final CI/review evidence must now be regenerated on the corrected exact head.

## Claude Run Trace

- goal: prevent forged Engineering OS bypasses and satisfy only `gap:bypass-approval-provenance`.
- hypothesis: one canonical provider-backed validator plus durable trusted one-shot consumption can make env variables request-only without leaving local bypass fallbacks.
- experiment: prove env-only/forged/wrong-scope/replay denial, preserve one valid bounded approval fixture, verify installed behavior, then exact-head CI/review.
- rejected: env/local/Git-tag authorization, requirement weakening, reusable approval, GitHub App provisioning as a merge prerequisite, and live production qualification as part of this PR's closure bar.

## Validation Plan

1. Reconcile the PR diff against the canonical audit/registry — complete.
2. Remove bootstrap/qualification-only commits and update scope evidence — complete/in progress for documentation.
3. Re-run focused bypass/provider/one-shot/fail-closed checks and full exact-head CI.
4. Reconcile fresh CodeRabbit/Codex review on the corrected exact head.
5. Stop for explicit owner approval of that exact head.
6. After merge, run post-merge validation; update canonical gap closure only with matching evidence.

## Remaining External Gates

Exact-head CI; fresh review reconciliation; explicit owner approval for the exact final head; protected merge; post-merge validation; separate canonical gap closure. No live GitHub App/control-repository qualification is required for PR #264 merge readiness.
