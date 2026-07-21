# Route Plan — Experiment Readiness Telemetry Hardening

## Route Plan

| Field | Decision |
|---|---|
| Task type | bug fix / security hardening / observability readiness |
| Task class | `engineering_os_governance` |
| Domain tags | governance, observability, security, testing, workflow |
| Plan Scope | standard |
| Planning Mode | approved — the user authorized closing the remaining readiness work; merge remains separately blocked on explicit owner approval |
| Target paths | `scripts/monitoring/telemetry_handoff.py`; `scripts/monitoring/select-pr-telemetry.py`; `scripts/enforcement/tests/test-telemetry-trust-boundaries.py`; `.github/workflows/telemetry-handoff-tests.yml`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-telemetry-preflight.md` |
| Task-router evidence | `core/task-router.md` routes changes to governance scripts, hooks, workflows, and adoption documents as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md` and `core/coderabbit-policy.md` require plan-first work, evidence-backed experiment/fix loops, a ready-for-review PR, exact-head CI/review, and explicit owner approval before merge. |
| Templates | waiver — no project template owns an existing telemetry transport hardening change |
| Architecture guides | `docs/operations/remote-multirepo-telemetry-hooks.md`; `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | `patterns/observability/README.md`; `patterns/security/README.md`; `patterns/testing/README.md` |
| External systems/connectors | GitHub |
| Skills | `security-review`; `verification-before-completion` |
| Validation gates | telemetry-handoff-tests; enforcement-tests; pr-policy; workflow/connector/capability/documentation/cleanup policies; CodeRabbit or documented exact-head fallback review |
| Evidence to check | `scripts/monitoring/telemetry_handoff.py`; `scripts/monitoring/select-pr-telemetry.py`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`; `scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py`; Project 8's corresponding hardened monitoring files; official Claude Code hooks, Git URL, GitHub artifact, and OpenTelemetry GenAI documentation; exact-head Actions and live review threads |
| User decisions required | explicit Yotam approval before merge to `main` |

## Goal

Remove the remaining deterministic canonical-source risks before the first successful Project 8 telemetry experiment:

1. promote Project 8's reviewed policy and bundle hardening into Engineering OS;
2. copy only validated required files into the PR-selected telemetry artifact;
3. preserve fail-closed trusted base policy semantics without making a repository that has no base policy impossible to validate;
4. distinguish implementation readiness, first-run evidence, and later longitudinal sufficiency;
5. keep the fresh Project 8 Remote run as the final evidence gate.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | This is Engineering OS governance affecting canonical monitoring scripts, CI, and operational documentation. |
| `core/workflow.md` | read | Plan-first, experiment → fix → verify, exact-head evidence, and progress checkpoints apply. |
| `core/coderabbit-policy.md` | read | Ready-for-review PR, review reconciliation, green CI, zero unresolved threads, and explicit owner approval are mandatory. |
| `scripts/monitoring/telemetry_handoff.py` | compared | Canonical code lacked Project 8's reviewed trusted-policy and regular-file hardening. |
| `scripts/monitoring/select-pr-telemetry.py` | compared | Canonical selector copied the entire validated directory instead of only validated required files. |
| `.github/workflows/pr-policy.yml` | validated | The workflow previously passed a nonexistent explicit trusted policy path; it now passes `--policy-file` only when the base contains a regular non-symlink policy, while an invalid present entry fails closed. |
| `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh` | updated | The workflow contract now verifies conditional policy passing and fail-closed regular-file checks. |
| `yotamfried-ux/project-8/scripts/monitoring/telemetry_handoff.py` | compared | Project 8 contains fail-closed explicit policy loading, environment isolation, and regular-file validation from PR #7. |
| `yotamfried-ux/project-8/scripts/monitoring/select-pr-telemetry.py` | compared | Project 8 copies only the validated three-file allowlist; PR #9 preserved it after rejecting a regressive full sync. |
| `.claude/plans/fix-repo-slug-url-parsing.md` | checked | PR #252's prerequisite parser scope and official Git URL rationale are recorded plan-first. |
| `scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py` | checked | Scheme and general scp-style Git URL forms have executable regression coverage. |
| `docs/operations/known-gaps.tsv` | checked | Canonical drift remains open until merge; live Project 8, Remote validation, and first-run archive evidence remain separate open gaps. |

## Official Documentation Evidence

- Claude Code hooks: `https://code.claude.com/docs/en/hooks`
  - `SessionStart` initializes the run; `StopFailure` output/exit are ignored; `SessionEnd` cannot block and has a short timeout.
  - Decision: terminal-hook execution alone is not durable-delivery proof.
- Git URL syntax: `https://git-scm.com/docs/git-clone.html#_git_urls`
  - Scheme URLs and `[user@]host:path` scp-style forms support PR #252's parser scope.
- GitHub workflow artifacts: `https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts`
  - Artifacts persist workflow output for transport/evidence but do not replace the Engineering OS archive.
- OpenTelemetry GenAI registry: `https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/`
  - `gen_ai.system` is deprecated in favor of `gen_ai.provider.name`.
  - Decision: defer this non-blocking schema modernization because current transport/archive consumers use stable `eos.*` fields.

## Documentation Asset Evidence

- internal: `docs/operations/project8-telemetry-preflight.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, and the three selected pattern guides.
- official external: Claude Code hooks, Git URL syntax, GitHub workflow artifacts, and OpenTelemetry GenAI semantic conventions.
- context7: not required — no external library or SDK is integrated; primary official documentation was read directly.
- decision: retain the existing Git handoff plus archive, promote proven target hardening upstream, preserve trusted-base behavior conditionally, and require a real non-empty exact-match bundle rather than adding a backend or weakening required mode.

## Capability Evidence

- `routing.task-router-read` — task routed as `engineering_os_governance` before implementation.
- `workflow.workflow-read` — plan-first and experiment/fix/verify workflow applied.
- `plan.route-plan-before-write` — this plan is committed before every implementation write on the rebuilt branch.
- `source.github-repo-read` — Engineering OS #252/#253 and Project 8 #7/#9, files, commits, Actions, and reviews were inspected through GitHub.
- `validation.policy-change-has-validator` — focused telemetry regressions and the PR-policy wiring contract cover every changed trust boundary.
- `validation.actions-checked` — exact-head Actions are inspected after the clean branch rebuild.
- `validation.coderabbit-policy` — review and explicit owner approval remain merge gates.

## Skill Evidence

- `security-review` — applied to trusted policy selection, environment override isolation, symlink/regular-file boundaries, metadata-only validation, selected-file allowlisting, exact repository/PR identity, and conditional base-policy bootstrap.
- `verification-before-completion` — implementation, exact-head validation, merge, and fresh live evidence remain separate claims.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Source of truth for both repositories, PRs, branch dependency, file contents, Actions, workflow artifacts, review findings, and live thread state. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` PRs #252/#253 and `yotamfried-ux/project-8` PRs #7/#9.
- action: compared canonical and target helpers; inspected rejected sync evidence; created and updated PR #253; diagnosed exact CI failures; merged #252 after approval; rebuilt #253 cleanly on the squash commit.
- result: the rebuilt branch preserves exactly the eleven intended files while removing duplicated #252 history.
- decision: keep the proven hardening, preserve plan-first history, and rerun every gate against `main` before requesting the second merge approval.
- target: canonical telemetry helpers, `pr-policy.yml`, the two focused test files, telemetry CI, and the four readiness documents listed in Target paths.

## Template/Pattern Rating Evidence

- asset: `patterns/observability/README.md`.
- rating: 4 high confidence.
- outcome: reused successfully to preserve metadata-only evidence, explicit correlation, and measurable operational boundaries.
- decision: prefer this pattern for future telemetry transport and archive changes.

- asset: `patterns/security/README.md`.
- rating: 5 high confidence.
- outcome: reused successfully for fail-closed trusted configuration, symlink rejection, environment isolation, allowlisted copying, conditional trusted-base ownership, and exact identity boundaries.
- decision: require this pattern for future installer or cross-workspace telemetry changes.

- asset: `patterns/testing/README.md`.
- rating: 4 high confidence.
- outcome: reused successfully to add positive and negative trust-boundary fixtures plus a static workflow contract for the bootstrap path.
- decision: prefer focused negative fixtures before live experiments for security-sensitive governance changes.

## Template Gap Waiver

reason: this is a focused repair to existing governance and telemetry helpers; no project template owns or improves this change.

## Data / State Impact

No product data or schema changes. Telemetry remains metadata-only. Existing event and archive schemas remain unchanged.

## Integration Impact

- Explicit trusted policy cannot be silently replaced by environment overrides.
- A present trusted base policy must be a regular non-symlink file and is passed explicitly.
- A repository whose trusted base has no telemetry policy retains the existing disabled default rather than failing on an invented explicit path.
- Required bundle files must be regular non-symlink files.
- The exact PR selector copies only `manifest.json`, `events.jsonl`, and `latest-summary.md`.
- No Project 8 product, database, authentication, or deployment files change.

## Validation Plan

- explicit trusted policy missing when explicitly requested → reject;
- workflow with no base policy → omit `--policy-file` and preserve disabled default;
- present base policy symlink/non-file → reject before selector;
- explicit trusted policy ignores mode/remote/branch environment overrides;
- required bundle symlink → reject;
- selector excludes extra files and symlinks;
- exact repo/branch/head/run/PR matching remains intact;
- telemetry, enforcement, and evidence policies pass on one exact head;
- zero unresolved review threads before merge.

## Alternatives

- Blind full installer sync into Project 8 — rejected because a real review proved it regresses four security properties.
- Always pass an absent explicit policy path — rejected because fail-closed validation correctly makes that impossible.
- Fall back to a PR-controlled policy when the base owns a policy — rejected; an existing base policy is isolated and passed explicitly.
- Permanent Project 8-only fork — rejected because future projects would receive weaker canonical code.
- External telemetry backend before first evidence — rejected; existing Git handoff and archive are sufficient.
- OpenTelemetry attribute modernization in this PR — rejected as non-blocking scope expansion.
- Readiness from fixtures — rejected; the fresh Project 8 bundle remains mandatory.

## Claude Run Trace

- goal: remove deterministic canonical telemetry blockers before the first valid Project 8 experiment.
- hypothesis: merge #252's Git parser, promote Project 8's reviewed trust controls upstream, and condition the trusted policy argument on actual base ownership without changing telemetry schema.
- connectors: GitHub for repository, PR, CI, artifacts, and review truth; official vendor documentation was read directly.
- steps: audit current state; compare Project 8 hardening; create plan-first branch; add regressions; promote policy/regular-file/allowlist behavior; wire CI; reconcile audit layers; define live gate; fix test-root; correct plan evidence; restore audit regression terms; fix absent-policy bootstrap; merge #252; rebuild #253 on the squash commit.
- evidence: PR #253 clean branch diff, exact-head Actions, review threads, Project 8 #7/#9, Engineering OS #252, and official documentation above.
- rejected: blind sync; target-only fork; backend expansion; environment override of trusted policy; symlinked required files; whole-directory selector copy; unconditional missing policy argument; weakened required mode; duplicate stacked history; OWH-only success.
- result: deterministic repairs are preserved on a clean plan-first branch; exact-head CI/review and live Project 8 evidence remain separate gates.

## Definition of Done

- [x] Canonical policy loading preserves trusted explicit paths and ignores environment overrides for them.
- [x] Canonical bundle validation rejects symlink/non-regular required files.
- [x] Canonical selector copies only the validated bundle allowlist.
- [x] `scripts/enforcement/tests/test-telemetry-trust-boundaries.py` covers missing-policy, environment-override, symlink, and allowlist fixtures.
- [x] `.github/workflows/pr-policy.yml` conditionally passes only a valid present base policy, and `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh` enforces that contract.
- [x] Audit/checklist documents distinguish implementation, first-run evidence, and longitudinal comparison.
- [x] Project 8 preflight defines smoke, exact selection, artifact, import, and findings evidence.

## Live External Gates Before Merge

- all required workflows succeed on one exact head;
- CodeRabbit or allowed exact-head fallback review is complete;
- valid findings are fixed or justified;
- zero unresolved review threads remain;
- Yotam explicitly approves merge after final validation against `main`.

## Progress Lifecycle Evidence

- start: this plan commit is the first commit on the clean branch rebuilt from `main` squash commit `5759cac6b0a1602ff225ba789cfaf2536de0a693`.
- mid: implementation commit(s) follow this plan and preserve the previously validated eleven-file change set.
- pre-merge: recorded only after exact-head CI and review complete on the rebuilt branch.