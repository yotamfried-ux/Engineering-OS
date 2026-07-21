# Route Plan — Experiment Readiness Telemetry Hardening

## Route Plan

| Field | Decision |
|---|---|
| Task type | bug fix / security hardening / observability readiness |
| Task class | `engineering_os_governance` |
| Domain tags | governance, observability, security, testing, workflow |
| Plan Scope | standard |
| Planning Mode | approved — the user authorized closing readiness blockers; merge still requires separate explicit approval |
| Target paths | `scripts/monitoring/telemetry_handoff.py`; `scripts/monitoring/select-pr-telemetry.py`; `scripts/enforcement/tests/test-telemetry-trust-boundaries.py`; `.github/workflows/telemetry-handoff-tests.yml`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-telemetry-preflight.md` |
| Task-router evidence | `core/task-router.md` routes governance scripts, hooks, workflows, and adoption documents as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md` and `core/coderabbit-policy.md` require plan-first work, experiment → fix → verify, exact-head CI/review, and owner approval before merge. |
| Templates | waiver — no project template owns an existing telemetry transport hardening change |
| Architecture guides | `docs/operations/remote-multirepo-telemetry-hooks.md`; `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | `patterns/observability/README.md`; `patterns/security/README.md`; `patterns/testing/README.md` |
| External systems/connectors | GitHub |
| Skills | `security-review`; `verification-before-completion` |
| Validation gates | telemetry-handoff-tests; enforcement-tests; pr-policy; workflow/connector/capability/documentation/cleanup policies; CodeRabbit or exact-head fallback review |
| Evidence to check | canonical telemetry helpers; Project 8 hardened copies; PRs #252/#253 and Project 8 #7/#9; official Claude Code, Git, GitHub Actions, and OpenTelemetry documentation; exact-head Actions and live review threads |
| User decisions required | explicit Yotam approval before merge to `main` |

## Goal

Remove deterministic blockers before the first Project 8 telemetry experiment:

1. promote Project 8's reviewed trust controls into canonical Engineering OS;
2. prevent PR-controlled policy fallback when the trusted base has no policy;
3. reject symlinked `runs/` or run directories before bundle files are read;
4. copy only validated required files into the selected CI artifact;
5. keep code readiness, first-run evidence, and longitudinal sufficiency as separate claims.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | The change is Engineering OS governance affecting canonical monitoring and CI. |
| `core/workflow.md` | read | Plan-first lifecycle and exact-head verification apply. |
| `core/coderabbit-policy.md` | read | Review reconciliation and explicit owner approval remain mandatory. |
| `scripts/monitoring/telemetry_handoff.py` | validated | Explicit trusted policies fail closed and ignore environment overrides. |
| `scripts/monitoring/select-pr-telemetry.py` | validated | Selection now rejects symlinked directory boundaries and copies only required files. |
| `.github/workflows/pr-policy.yml` | validated | A missing base policy produces a trusted schema-valid disabled policy that is always passed explicitly. |
| `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh` | validated | The workflow contract requires trusted-default generation and unconditional explicit policy use. |
| `scripts/enforcement/tests/test-telemetry-trust-boundaries.py` | validated | Negative fixtures cover PR policy override, required-file symlinks, `runs/` symlinks, run-directory symlinks, and extra-file exclusion. |
| `yotamfried-ux/project-8/scripts/monitoring/telemetry_handoff.py` | compared | Project 8 provided the reviewed fail-closed policy behavior promoted upstream. |
| `yotamfried-ux/project-8/scripts/monitoring/select-pr-telemetry.py` | compared | The rejected full-sync evidence led to canonical selected-file allowlisting. |
| `.claude/plans/fix-repo-slug-url-parsing.md` | checked | PR #252 recorded the prerequisite Git remote parser and official Git rationale. |
| `docs/operations/known-gaps.tsv` | checked | Live Project 8, Remote validation, and first-run archive evidence remain open and separate. |

## Official Documentation Evidence

- Claude Code hooks: `https://code.claude.com/docs/en/hooks`
  - `SessionStart` initializes the run; `StopFailure` cannot enforce via output/exit; `SessionEnd` cannot block termination.
  - Decision: hook execution alone is not durable-delivery proof.
- Git URL syntax: `https://git-scm.com/docs/git-clone.html#_git_urls`
  - Scheme URLs and `[user@]host:path` scp-style forms support PR #252's parser scope.
- GitHub workflow artifacts: `https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts`
  - Artifacts persist workflow evidence but do not replace the Engineering OS archive.
- OpenTelemetry GenAI registry: `https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/`
  - Provider attribute modernization remains a non-blocking follow-up because current transport consumers use stable `eos.*` fields.

## Documentation Asset Evidence

- internal: `docs/operations/project8-telemetry-preflight.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`.
- official external: Claude Code hooks, Git URL syntax, GitHub workflow artifacts, and OpenTelemetry GenAI semantic conventions.
- context7: not required — no external library or SDK is integrated.
- decision: retain Git handoff plus archive, use an explicit trusted disabled policy for absent-base adoption, and require a real exact-match bundle before experiment success.

## Capability Evidence

- `routing.task-router-read` — routed as `engineering_os_governance` before implementation.
- `workflow.workflow-read` — plan-first experiment/fix/verify workflow applied.
- `plan.route-plan-before-write` — plan commit `dd3439312dc03fd7e81df6236226b6b006bc3b43` predates every code/config/test commit on the rebuilt branch.
- `source.github-repo-read` — GitHub provided repository, PR, commit, Actions, artifact, and review-thread truth.
- `validation.policy-change-has-validator` — focused policy, directory-boundary, allowlist, and workflow regressions cover the changed controls.
- `validation.actions-checked` — telemetry-handoff-tests run 216 and enforcement-tests run 1314 passed on code head `d1c596084ca112c12f30b408d603994a18155665`.
- `validation.coderabbit-policy` — CodeRabbit/Codex findings were verified and merge remains owner-gated.

## Skill Evidence

- `security-review` — applied to trusted policy ownership, environment isolation, symlink traversal, directory containment, metadata-only validation, allowlisted copying, and exact repository/PR identity.
- `verification-before-completion` — implementation, exact-head validation, merge, and fresh live Project 8 evidence remain separate claims.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Source of truth for both repositories, PRs, squash history, exact-head CI, CodeRabbit/Codex findings, and live thread state. |

## Connector Usage Evidence

- source: GitHub connector for Engineering OS PRs #252/#253 and Project 8 PRs #7/#9.
- action: compared canonical and target helpers; inspected the rejected full sync; merged #252 after approval; rebuilt #253 on squash commit `5759cac6b0a1602ff225ba789cfaf2536de0a693`; diagnosed CI and review findings; verified code head `d1c596084ca112c12f30b408d603994a18155665`.
- result: eleven PR files are present — this plan plus the ten Target paths; telemetry-handoff-tests run 216 and enforcement-tests run 1314 passed, while `scripts/monitoring/select-pr-telemetry.py`, `.github/workflows/pr-policy.yml`, and `scripts/enforcement/tests/test-telemetry-trust-boundaries.py` contain the final security repairs.
- decision: merging PR #252 enabled the clean rebuild; Project 8 PR #9's rejected full-sync evidence caused selected-file allowlisting; CodeRabbit/Codex policy and symlink findings caused explicit trusted-default and directory-boundary checks; exact-head status kept PR #253 blocked until every finding and thread was reconciled.
- target: `scripts/monitoring/select-pr-telemetry.py`, `.github/workflows/pr-policy.yml`, `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`, and `scripts/enforcement/tests/test-telemetry-trust-boundaries.py`.

## Template/Pattern Rating Evidence

- asset: `patterns/observability/README.md`.
- rating: 4.
- confidence: high.
- outcome: metadata-only correlation and measurable transport boundaries were reused successfully.
- decision: prefer this pattern for future telemetry transport changes.

- asset: `patterns/security/README.md`.
- rating: 5.
- confidence: high.
- outcome: fail-closed policy ownership, symlink rejection, containment, and allowlisting were reused successfully.
- decision: require this pattern for installer and cross-workspace telemetry changes.

- asset: `patterns/testing/README.md`.
- rating: 5.
- confidence: high.
- outcome: negative fixtures exposed and closed policy-fallback and directory-symlink risks before a live experiment.
- decision: require focused negative fixtures for security-sensitive governance changes.

## Template Gap Waiver

reason: this is a focused repair to existing governance and telemetry helpers; no project template owns or improves the change.

## Data / State Impact

No product data or telemetry schema changes. Telemetry remains metadata-only.

## Integration Impact

- Explicit trusted policy cannot be replaced by environment overrides.
- A present base policy must be a regular non-symlink file.
- An absent base policy generates and explicitly passes a trusted schema-valid `disabled` policy; the PR checkout policy is ignored.
- Active selection rejects a symlinked handoff root, `runs/`, or run directory and verifies lexical and resolved containment.
- Required bundle files remain regular non-symlink files.
- Selected output remains limited to `manifest.json`, `events.jsonl`, and `latest-summary.md`.
- No Project 8 product, database, authentication, or deployment code changes.

## Validation Plan

- explicit trusted policy missing when explicitly requested → reject;
- absent base policy plus PR-controlled `required` policy → trusted explicit `disabled` policy wins;
- present base policy symlink/non-file → reject before selection;
- explicit trusted policy ignores mode/remote/branch environment overrides;
- required bundle-file symlink → reject;
- symlinked `runs/` root → reject;
- symlinked run directory → reject;
- directory resolving outside the handoff root → reject;
- extra files and symlinks → excluded from selected artifact;
- exact repository/branch/head/run/PR matching → preserved;
- telemetry and aggregate enforcement suites → pass on the exact code head;
- live review thread gate → zero unresolved before merge.

## Alternatives

- Blind full installer sync into Project 8 — rejected because review proved it regresses trust controls.
- Omit `--policy-file` when base has no policy — rejected because it lets the PR checkout control policy.
- Accept directory symlinks while checking child files — rejected because child `is_file()` can hide ancestor traversal.
- Permanent Project 8-only fork — rejected because future projects would receive weaker canonical code.
- External backend before first evidence — rejected; existing Git handoff and archive are sufficient.
- Claim readiness from fixtures — rejected; the fresh Project 8 bundle remains mandatory.

## Claude Run Trace

- goal: remove deterministic canonical telemetry blockers before the first valid Project 8 experiment.
- hypothesis: combine #252's Git parser, Project 8's reviewed trust controls, an explicit trusted disabled adoption policy, and directory-boundary checks without changing telemetry schema.
- connectors: GitHub for repository, PR, CI, artifacts, and review truth; official vendor documentation read directly.
- steps: audit; compare target/canonical code; create plan-first branch; add hardening and regressions; reconcile audits; merge #252; rebuild #253 on the squash commit; fix test-root and evidence defects; fix trusted-policy fallback and symlinked directory traversal; run focused and aggregate suites.
- evidence: PR #253, code head `d1c596084ca112c12f30b408d603994a18155665`, telemetry-handoff-tests run 216, enforcement-tests run 1314, CodeRabbit/Codex review threads, Project 8 #7/#9, Engineering OS #252, and official documentation above.
- rejected: blind sync; target-only fork; PR-controlled fallback; symlinked directories/files; whole-directory copy; weakened required mode; duplicate stacked history; OWH-only success.
- result: deterministic code and workflow blockers are closed; live Project 8 evidence remains the post-merge gate.

## Definition of Done

- [x] Canonical policy loading preserves trusted explicit paths and ignores environment overrides.
- [x] PR policy cannot override the trusted disabled default when the base owns no policy.
- [x] Required bundle files reject symlinks and non-regular files.
- [x] `runs/` and run-directory symlinks or containment escapes are rejected before reading bundle files.
- [x] Canonical selector copies only the validated three-file allowlist.
- [x] `scripts/enforcement/tests/test-telemetry-trust-boundaries.py` covers policy fallback, environment override, file symlink, directory symlink, and allowlist fixtures.
- [x] `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh` enforces trusted-default generation and unconditional explicit policy use.
- [x] telemetry-handoff-tests run 216 and enforcement-tests run 1314 pass on code head `d1c596084ca112c12f30b408d603994a18155665`.
- [x] Audit/checklist documents distinguish implementation, first-run evidence, and longitudinal comparison.
- [x] Project 8 preflight defines smoke, exact selection, artifact, import, and findings evidence.

## Live External Gates Before Merge

- all required workflows succeed on the final evidence head;
- every valid CodeRabbit/Codex finding is replied to and resolved;
- zero unresolved review threads remain;
- `pr-policy` succeeds with the final PR body;
- Yotam explicitly approves the second merge.

## Progress Lifecycle Evidence

- start: plan commit `dd3439312dc03fd7e81df6236226b6b006bc3b43` is the first commit above main squash commit `5759cac6b0a1602ff225ba789cfaf2536de0a693`.
- mid: implementation commit `95f3ad7809251690a6272f17e927fd62453a618b` and evidence commit `f1d4cb634792f0779c76fc0720bfbb274f56478a` recorded the original eleven-file hardening set and successful focused validation.
- pre-merge: final code commit `d1c596084ca112c12f30b408d603994a18155665` closed trusted-policy fallback and directory-symlink findings; telemetry-handoff-tests run 216 and enforcement-tests run 1314 succeeded, `pr-policy` executed the trusted-policy selection step successfully, and merge stayed blocked by unresolved review threads for explicit reconciliation.