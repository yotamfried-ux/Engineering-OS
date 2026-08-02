# Route Plan — Bypass Approval Provenance

## Route Plan

| Field | Decision |
|---|---|
| Task type | security-sensitive Engineering OS authorization hardening |
| Task class | `engineering_os_governance` |
| Domain tags | hooks, authorization, GitHub Actions, shell, Python, installer, tests |
| Plan Scope | standard |
| Planning Mode | rebuild from canonical `main`; commit this plan before replaying the verified candidate; old PR commits remain evidence sources only |
| Target paths | `.claude/plans/bypass-approval-provenance.md`; `.github/workflows/bypass-*-reusable.yml`; `docs/operations/bypass-control-plane-runbook.md`; `scripts/enforcement/`; `scripts/hooks/`; `templates/bypass-control-plane/` |
| Task-router evidence | `core/task-router.md` routes enforcement/governance changes through the governance workflow and security review. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, `core/hooks-policy.md` require plan-first work, ordered evidence, exact-head CI/review, explicit owner approval and protected merge. |
| Templates | not required as input; existing enforcement conventions are reused and the bypass-control-plane template is an output |
| Architecture guides | `core/hooks-policy.md`; `core/git-policy.md`; `docs/operations/merge-readiness-checklist.md`; `docs/operations/bypass-control-plane-runbook.md` |
| Patterns | shared enforcement library, canonical registry, fail-closed provider adapter, reusable workflow |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | bypass/provider/fail-closed tests; source/template parity; installed target; all `test-*.sh`; exact-head CI; review; live qualification |
| Evidence to check | canonical `main`; PR #264 head/tree/CI; bypass policy/config/consumers/tests; official GitHub and Claude hook docs |
| User decisions required | manual human approval during live qualification and explicit owner approval before merge |

## Goal

Make every `EOS_BYPASS_*` request-only. Authorization requires provider-verified human approval with exact scope/target binding, freshness, issuer authority and unique durable one-shot consumption.

## Scope

Own bypass registry/config, provider validation/consumption, shared enforcement migration, workflows, tests, installed target, control-plane template/runbook and PR evidence. Project 8, merge and closure are excluded.

## Rebuild Evidence Boundary

Old PR history is an evidence source, not claimed as current-lifecycle-compliant. Base `6a589971c59561b88cb4abaa0752235b9bb4d5df`; candidate `9a2eb7b6c900da43654b716a5203aed45d723344` / tree `039753e82e72a02d1264ccd9c20cf7f1aaf7e3b7`; `enforcement-tests` run `30715280921` succeeded. Export run `30720627257` / artifact `8824733672` reproduced that head/tree and checksum locally. Final evidence is regenerated after rebuild.

## Root Cause and Architecture

Environment/local evidence previously authorized bypasses and fallback consumers could fail open. Canonical policy + contract + GitHub provider + shared `lib/evidence.sh` now own authorization; a private control repository writes durable claim/marker evidence and master requests are disabled.

## Trust Boundary

Runtime may read metadata/dispatch only; consumer `GITHUB_TOKEN` is `contents: read`, `actions: read`, `issues: write`; `PROTECTED_REPOSITORY_READ_TOKEN` is separate read-only identity/permission verification. Missing verifier, invalid issuer/binding, edited/malformed/replay/duplicate/conflict/rerun/ambiguous or Git-tag evidence fails closed.

## Official Documentation Evidence

- GitHub reusable workflows: `https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations` — permissions cannot be elevated; use immutable SHA pins.
- GitHub token/auth: `https://docs.github.com/en/actions/tutorials/authenticate-with-github_token` — least privilege and separate credentials.
- GitHub collaborator API: `https://docs.github.com/en/rest/collaborators/collaborators` — provider-readable effective role.
- Claude hooks: `https://code.claude.com/docs/en/hooks` — `PreToolUse` exit 2 blocks; enforcement uncertainty must become blocking denial.

## Documentation Asset Evidence

- internal: `CLAUDE.md`; `core/workflow.md`; `core/hooks-policy.md`; `docs/operations/known-gaps.tsv`; `docs/operations/merge-readiness-checklist.md`.
- context7: the official GitHub Actions/API and Claude hooks URLs above were checked directly because current vendor semantics define this authorization boundary.
- decision: selected immutable workflow pins, least-privilege separated credentials, provider role verification and blocking fail-closed behavior; mutable refs, shared credentials and payload role claims are rejected.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | governance/security route confirmed |
| `core/workflow.md` | read | ordered plan/result/review lifecycle confirmed |
| `core/hooks-policy.md` | checked | hard enforcement blocking semantics confirmed |
| `scripts/enforcement/bypass-policy.tsv` | checked | candidate has 42 explicit bypass mappings |
| `scripts/enforcement/tests/test-bypass-provider-validation.py` | checked | provider/replay/ambiguity fixtures exist |
| `scripts/enforcement/tests/test-bypass-request-fail-closed.sh` | checked | env-only/missing-dependency denial exists |

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-read PR #264, canonical `main`, candidate head/tree/CI and exact export artifact before rebuilding. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #264, commits, workflows and repository files.
- action: verified `main` `6a589971c59561b88cb4abaa0752235b9bb4d5df`, candidate `9a2eb7b6c900da43654b716a5203aed45d723344`, exported run `30720627257`, then restored the PR branch.
- result: artifact `8824733672` embeds head `9a2eb7b6c900da43654b716a5203aed45d723344` and tree `039753e82e72a02d1264ccd9c20cf7f1aaf7e3b7`; checksum matched locally.
- decision: selected a clean-history rebuild and blocked lifecycle backfill or policy weakening.
- target: `.claude/plans/bypass-approval-provenance.md`; `scripts/enforcement/`; `.github/workflows/bypass-*-reusable.yml`; `templates/bypass-control-plane/`.

## Capability Evidence

`routing.task-router-read`; `workflow.workflow-read`; `plan.route-plan-before-write`; `source.github-repo-read`; `skill.security-review`; `validation.security-gate-checked`; `validation.actions-checked`; `validation.policy-change-has-validator`; `validation.coderabbit-policy`; `template.project-template-checked`.

## Skill Evidence

- `writing-plans` — plan precedes replay.
- `verification-before-completion` — validation, CI, review, qualification, merge and closure remain separate.
- `security-review` — credentials, issuer, provenance, replay and fail-closed denial are explicit.

## Definition of Done

- Plan-first ordering: verified; the rebuilt Route Plan is the first PR commit above canonical `main`.
- Implementation replay: verified against the prior candidate, with deliberate immutable-pin updates and no transfer/export artifacts in the candidate tree.
- Local validation: every earlier run is superseded by the exact-head review reconciliation. On the last code/config/test commit `5a3f5bc4eed501d2be4fd3d7488e7b019020a2e0`, a full rerun of all 110 current `test-*.sh` files passed 110/110 with 0 failures and 0 timeouts in 204 seconds, alongside strict 42/42 bypass contract, provider validation, `bash -n`, `py_compile`, and `git diff --check`. The preceding commit `b383e9b4a3df5751f3e2eddae7dc1c410e900917` independently passed 110/110 in 191 seconds.
- Exact-head CI/review: external gate; must be green/reconciled before owner approval.
- Live control-plane qualification: external gate; must be proven before owner approval.
- Merge/post-merge/closure: prohibited until explicit owner approval and subsequent durable evidence.

## Progress Lifecycle Evidence

- start: this clean-history Route Plan is the first PR commit above canonical `main` `6a589971c59561b88cb4abaa0752235b9bb4d5df` and precedes every implementation replay commit owned by this rebuilt history.
- mid: remote foundation `d45a8bbf56702f00cea091bf38814b2bdb44b66a` replayed 51 verified paths; bypass contract is 42/42 (11 master-disabled, 31 action-specific), fail-closed/provider/approval tests pass, hard-hook is 15/15, hook classification 10/10, and clean installed-target passes including env-only `EOS_BYPASS_FIXTEST` denial.
- superseded pre-merge: `e8abb45f29b00d096318efe2cb8900dd038f571f` reached green exact-head CI and 110/110 local tests, but a subsequent security review found direct `${{ inputs.* }}` / `${{ github.* }}` interpolation inside reusable-workflow shell and ungated hidden fixture/time overrides. That evidence is not final.
- review correction: remote security commit `9bc3ce72c7f6f15018e4fc8bce19266de9df582b` / tree `1dc2d93f8c5de1e806693e5a74c152babf0f66f0` moves GitHub expressions into step environment values consumed as quoted shell variables, rejects direct GitHub-context interpolation in reusable-workflow `run:` blocks, and gates fixture/time overrides behind explicit `ENGINEERING_OS_BYPASS_TEST_MODE=1`. Focused strict, approval, fail-closed, hard-hook, classification, provider, and clean installed-target checks passed before publication.
- superseded pre-merge: `923bda7b5723f141580af4711b7d6a382f8f01d3` repinned the control-plane template to the hardened reusable-workflow commit, but the subsequent exact-head CodeRabbit and Codex review of `e8abb45f29b00d096318efe2cb8900dd038f571f` raised 19 findings that were not yet reconciled. That evidence is not final.

- review reconciliation: remote commit `b383e9b4a3df5751f3e2eddae7dc1c410e900917` binds `approval_comment_id`/`approval_created_at` from the provider envelope instead of the authored body, which is what made a real human approval constructible at all; enforces the canonical policy `target_type`/`fingerprint_contract`/`target_commit_contract` columns that were previously parsed and discarded; makes the remote-head lookup fail closed; refuses provider redirects that would replay the `Authorization` header; traverses issue-comment pagination instead of rejecting it; coerces numeric path IDs; and decides schema relevance from the parsed object. Full suite 110/110, 0 failures, 0 timeouts, 191s.

- pre-merge: remote last code/config/test commit `5a3f5bc4eed501d2be4fd3d7488e7b019020a2e0` moves claims from the Approval Registry to the Consumption Ledger so the documented two-issue contract is real, aligns the git-ref request parser with the `skip_git_globals` rule in `enforce-git.sh`, scopes the workflow test's authorization assertion to its own request, and records the residual limits of an issue-backed ledger in the runbook. Full suite 110/110, 0 failures, 0 timeouts, 204s; strict 42/42 contract; source and template copies byte-identical. All 19 review threads were reconciled against this content and resolved. No implementation, config, or test change follows this checkpoint.

## Claude Run Trace

- goal: finish PR #264 with provider-backed fail-closed authorization and truthful lifecycle evidence.
- hypothesis: separate credentials + human provider approval + exact binding + unique claim/marker consumption remove env-only authorization.
- candidate: `9a2eb7b6c900da43654b716a5203aed45d723344` / tree `039753e82e72a02d1264ccd9c20cf7f1aaf7e3b7`.
- experiment: plan-first rebuild, replay, regenerate local/CI/review/live evidence.
- rejected: lifecycle backfill, own-history exemption, policy weakening, env/local/Git-tag authorization.

## Validation Plan

1. Commit this plan alone and validate evidence policy.
2. Replay provider foundation; run focused provider/fail-closed/installed checks; commit `mid` evidence.
3. Add template callers pinned to the new immutable foundation SHA plus hardening test.
4. Run full local validation and all `test-*.sh`; commit `pre-merge` evidence after the last code change; re-run final validation.
5. Publish exact head, collect latest-attempt CI, update PR body, reconcile and refresh reviews.
6. Create/verify the private control repository, execute denial/success qualification, stop for manual approval publication, then later for owner merge approval.

## Remaining External Gates

Exact-head CI/review; live control-plane qualification; manual approval publication; explicit owner approval; expected-head merge; post-merge proof; separate closure.
