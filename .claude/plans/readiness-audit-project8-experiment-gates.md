# Route Plan — Readiness Audit and Project 8 Experiment Gates

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance audit / documentation correction / experiment-readiness planning |
| Task class | `engineering_os_governance` |
| Domain tags | governance, workflow, observability, security, testing, documentation |
| Plan Scope | standard |
| Planning Mode | user-authorized audit update; merge remains subject to separate explicit owner approval |
| Target paths | `.claude/plans/readiness-audit-project8-experiment-gates.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Task-router evidence | `core/task-router.md` was read; changes to Engineering OS policy, audit, enforcement status, and target-project adoption are routed as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, and `core/coderabbit-policy.md` require plan-first work, source-of-truth checks, result loops, exact-head CI/review, and owner approval before merge. |
| Templates | waiver — no project scaffold owns a focused update to the existing canonical readiness audit and gap registry |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | `patterns/observability/README.md`; `patterns/security/README.md`; `patterns/testing/README.md` |
| External systems/connectors | GitHub; official Anthropic, GitHub, Vercel, Supabase, Prisma, Playwright, and W3C documentation |
| Skills | `security-review`; `verification-before-completion`; `writing-plans` |
| Validation gates | enforcement-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy; telemetry-handoff-tests |
| Evidence to check | Engineering OS main and PR #253; Project 8 main and PRs #1/#4/#6/#7/#8/#9; exact-head Actions; review threads; canonical audit/registry; official vendor contracts |
| User decisions required | explicit Yotam approval before merge to `main`; separate approval before any production deployment or destructive provider change |

## Goal

Update the canonical operational-readiness audit and known-gaps registry with the current enforcement defects and every prerequisite for a valid Project 8 behavioral and telemetry run, without changing Product 8 code or inventing a parallel tracker.

## Plan

1. Reconcile merged Engineering OS state and open gaps.
2. Inspect Project 8 main, open PRs, local guidance, telemetry/runtime policy, CI, and provider-migration state.
3. Add exact end-to-end closure checklists and official-documentation references to the audit.
4. Keep `known-gaps.tsv` synchronized with every non-closed audit gap.
5. Run deterministic audit/registry/documentation tests through GitHub Actions.
6. Fix every real CI or review finding, perform exact-head self-review, and leave merge owner-gated.

## Alternatives

- Keep findings only in chat — rejected because they would not become canonical or enforceable.
- Add a separate checklist document — rejected because duplicate ownership would create drift.
- Mix Product 8 migration implementation into this PR — rejected; this PR is governance/audit only.
- Give Claude the internal experiment checklist — rejected because it would coach the behavior being evaluated.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | The task is Engineering OS governance and operational-readiness work. |
| `core/workflow.md` | read | Plan-first, evidence-backed result loops and post-merge validation apply. |
| `core/quality-gates.md` | read | Tool output, tests, exact current code, and self-review are required; prose is not proof. |
| `core/git-policy.md` | read | Ready-for-review PR, expected head SHA, named CI checks, threads, and owner approval are required. |
| `core/coderabbit-policy.md` | read | External review or a documented structured fallback must be reconciled before merge. |
| `docs/operations/known-gaps.tsv` | checked | It still described merged PR #253 as open and lacked seven current gaps. |
| `docs/operations/operational-readiness-audit.md` | checked | It conflated audit completeness with readiness and lacked end-to-end closure checklists. |
| `scripts/enforcement/lib/hook-gate.sh` | checked | Missing enforcers and deny-conversion failures can return success despite hard/fail-closed classification. |
| `scripts/enforcement/lib/evidence.sh` | checked | `bypass_active()` logs a bypass variable but does not prove explicit human approval. |
| `core/pattern-lifecycle.md` and `patterns/registry.yaml` | compared | The policy contradicts the executable YAML registry ownership model. |
| `yotamfried-ux/project-8/CLAUDE.md` | checked | Local target guidance prescribes Engineering OS behavior. |
| `yotamfried-ux/project-8/docs/engineering-os/claude-project-8-prompt.md` | checked | It explicitly discloses that the work is part of an experiment and coaches exact behavior. |
| Project 8 PR #9 | checked | It removes tracked Markdown guidance and preserves machine-readable telemetry; exact-head product/policy checks passed and review threads are resolved, but it remains unmerged. |
| Project 8 merged PRs #4 and #6 | checked | Baseline functionality and an isolated Postgres foundation exist; active runtime cutover and Vercel deployment remain incomplete. |

## Official Documentation Evidence

- Claude Code hooks: `https://code.claude.com/docs/en/hooks`
  - `PreToolUse` blocking requires `exit 2` or a valid deny decision; other nonzero exits generally do not block.
  - `SessionStart` owns session initialization and terminal events have different blocking semantics.
  - Decision: hard hook infrastructure errors must fail closed, and the Project 8 run must start in a genuinely fresh session.
- GitHub status checks: `https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks`
  - Checks attach to exact commits; skipped jobs can report success.
  - Decision: audit closure must name intended non-self checks on the exact head and cannot trust generic PR prose.
- GitHub workflow artifacts: `https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts`
  - Decision: session artifacts are transport/evidence and must still be imported into the canonical longitudinal archive.
- Vercel environments, environment variables, domains, Vite, Express, and monorepos: official URLs embedded in the audit.
  - Decision: reuse the existing linked project/domain, scope variables by environment, redeploy after changes, and validate the smallest supported deployment shape.
- Supabase RLS, API keys, secure data, and database connections plus Prisma's Supabase guide: official URLs embedded in the audit.
  - Decision: RLS is mandatory on exposed tenant tables, elevated keys stay server-only, runtime uses pooled connection, and migrations/introspection use direct connection.
- Playwright: `https://playwright.dev/docs/intro`; W3C forms: `https://www.w3.org/WAI/tutorials/forms/`.
  - Decision: browser-level cross-browser/mobile E2E and accessible form/UI evidence are required for Product 8 workload acceptance.

## Documentation Asset Evidence

- internal: `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `docs/operations/project8-telemetry-preflight.md`, `docs/operations/remote-multirepo-telemetry-hooks.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`.
- target: Project 8 `CLAUDE.md`, local prompt/audit files, merged preparation/migration PRs, and open PR #9.
- official external: Anthropic Claude Code, GitHub Actions/status checks, Vercel, Supabase, Prisma, Playwright, and W3C references listed above and in the audit.
- decision: retain one canonical audit owner, register all unresolved conditions, and keep the target workload prompt free of experiment internals.

## Template Gap Waiver

reason: this task updates existing canonical governance records and does not create or scaffold an application; no project template would improve or own the change.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read and the task was routed as `engineering_os_governance`.
- `workflow.workflow-read` — `core/workflow.md` was read and plan-first evidence/result-loop behavior was applied.
- `plan.route-plan-before-write` — plan commit `aad4519e27386c33d5d49f635776e9c78e8e8e04` predates the audit and registry edits.
- `source.github-repo-read` — GitHub supplied live repository, PR, commit, Actions, and review-thread evidence for both repositories.
- `validation.policy-change-has-validator` — every new gap names a concrete checker/test target and the audit includes positive/negative closure requirements.
- `validation.actions-checked` — Project 8 PR #9 exact-head checks and Engineering OS PR #254 first-run Actions were inspected; real failures are being corrected rather than waived.
- `validation.coderabbit-policy` — CodeRabbit/Codex findings and exact-head structured fallback review remain merge gates.

## Skill Evidence

- `security-review` — applied to hard-hook failure semantics, bypass provenance, secrets/key boundaries, RLS, telemetry privacy, and exact provider identity requirements.
- `verification-before-completion` — implementation closure, fresh live evidence, provider migration, product acceptance, and longitudinal sufficiency remain separate claims.
- `writing-plans` — this Route Plan was committed before the audit changes and records ordered lifecycle evidence.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Source of truth for Engineering OS and Project 8 files, PR state, exact head SHAs, workflow conclusions, changed paths, merged history, and review threads. |

## Connector Usage Evidence

- source: GitHub connector for Engineering OS main/PRs #247/#249/#253/#254 and Project 8 main/PRs #1/#4/#6/#7/#8/#9.
- action: inspected canonical and target files, reconciled merged state, checked exact-head workflows and all review threads, closed superseded Engineering OS PR #247, and opened ready-for-review PR #254.
- result: canonical telemetry hardening is merged; seven current gaps are now registered; Project 8 main still contains experiment-coaching Markdown; PR #9 is product/policy green with zero unresolved threads but unmerged; Supabase runtime cutover, Vercel deployment, and complete feature/UI evidence remain incomplete.
- decision: block the next run on product-only convergence and fresh telemetry preflight, while keeping provider/product acceptance as the workload completion contract.
- target: `.claude/plans/readiness-audit-project8-experiment-gates.md`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.

## Template/Pattern Rating Evidence

- asset: `patterns/observability/README.md`; rating: 4; confidence: high; outcome: metadata-only telemetry boundaries and separate evidence layers were reused; decision: retain for telemetry readiness.
- asset: `patterns/security/README.md`; rating: 5; confidence: high; outcome: fail-closed hooks, secret boundaries, RLS, and trusted provider identity shaped the closure bars; decision: require for enforcement and provider migration.
- asset: `patterns/testing/README.md`; rating: 5; confidence: high; outcome: positive/negative fixtures, exact-head CI, browser E2E, and post-merge smoke are required for every closure claim; decision: retain as the validation baseline.

## Data / State Impact

Documentation and governance registry only. No telemetry bundle, secret, Product 8 database, provider resource, deployment, runtime hook implementation, or application feature is changed.

## Integration Impact

- GitHub live state becomes a registered future audit input rather than an assumed truth.
- Project 8 experiment start is explicitly blocked on removal of local coaching and fresh telemetry initialization.
- Product 8 provider/feature completion is separated from telemetry collection success.
- Existing canonical audit and registry remain the only durable owners.

## Validation Plan

- `bash scripts/enforcement/check-known-gaps.sh`
- `bash scripts/enforcement/check-readiness-audit.sh`
- `bash scripts/enforcement/check-documentation-hygiene.sh`
- `bash scripts/enforcement/tests/test-known-gaps.sh`
- `bash scripts/enforcement/run-all-tests.sh`
- exact-head GitHub Actions, changed-path, PR-body, and review-thread inspection
- negative self-review for duplicate ownership, unsupported closure, experiment leakage, secret exposure, and accidental Product 8 scope

## Claude Run Trace

- goal: make the readiness source of truth honest and make the next Project 8 run valid without coaching Claude.
- hypothesis: reconciling live GitHub truth, registering the enforcement defects, removing target-side experiment guidance before the run, and requiring a fresh exact-match telemetry bundle will separate system behavior evidence from product outcomes.
- connectors: GitHub; official vendor documentation read directly.
- steps: inspect both repositories; reconcile #253; identify hard-hook/bypass/pattern/readiness defects; inspect Project 8 guidance and PR #9; create plan-first branch; update registry and audit; open PR; inspect first CI failures; correct the plan and registry contracts; rerun exact-head validation.
- evidence: Engineering OS PR #254 and its commit/run history; merged #253; Project 8 main and PRs #4/#6/#7/#8/#9; exact-head Actions and review threads; official references above.
- rejected: chat-only tracking; parallel checklist; blind Project 8 run with local coaching; telemetry-only success claim; new provider resources without inventory; MongoDB adoption; secret disclosure; generic “all checks passed” evidence.
- result: audit and closure contracts are implemented on the PR branch; exact-head result-loop validation and owner-gated merge remain.

## Definition of Done

- [x] Every newly identified gap has one registry row and one audit matrix/checklist entry.
- [x] Every closure checklist requires code/config evidence, positive and negative tests, exact-head CI, review, merge, and post-merge validation where applicable.
- [x] Project 8 experiment blockers include prompt/guidance contamination, PR #9 convergence, fresh-session telemetry, exact bundle selection, provider asset preservation, Supabase/Vercel direction, and product E2E evidence.
- [x] Official documentation URLs and the decision derived from each are embedded in the audit.
- [x] The first exact-head CI result was inspected and its real plan/registry failures were routed into the next fix loop.

## Live External Gates Before Merge

The task is not complete and this PR must not merge until all named exact-head checks pass, every live review thread is resolved or reconciled, structured self-review is recorded on the final head, the PR body names the final expected head SHA and evidence, and Yotam gives explicit merge approval.

## Progress Lifecycle Evidence

- start: `aad4519e27386c33d5d49f635776e9c78e8e8e04` created the plan before audit/registry edits.
- middle: `27a0c5a5cf2bfc2d1f171101098d4e43620d2b42` and `1e5f49491b521b69cd0f79f4147ec7d5eef3c252` synchronized the registry and audit; first-run CI on `a467f8f2906c236c29adc448547973882b9d3749` exposed missing Route Plan evidence and invalid registry artifact paths, which this result loop corrects.
- pre-merge: pending after the final exact-head CI, review, and evidence-only checkpoint.