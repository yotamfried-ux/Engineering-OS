# Engineering OS Operational Readiness Audit

This document is the canonical status map and closure contract for Engineering OS operational readiness. A capable LLM or human reviewer can begin here without prior chat context, understand the system and target repositories, identify the next unresolved gap, and know exactly what evidence is required before a readiness or experiment claim.

## Audit metadata

- **Audit owner:** Yotam Friedman; operational owner group `ops-readiness`
- **Canonical repository:** `yotamfried-ux/Engineering-OS`
- **Target repository:** `yotamfried-ux/project-8`
- **Canonical gap registry:** `docs/operations/known-gaps.tsv`
- **Last verified:** 2026-07-21 America/Panama / 2026-07-22 UTC
- **Intended readers:** LLMs, maintainers, reviewers, and operators with no prior conversation context
- **Snapshot only:** Engineering OS `main` was inspected at `c7d32a0b67a836811689d3a2bf80a63d727e1470`; Project 8 `main` at `f282f5e9889d956e54fc0803938915fd86a58158`; Project 8 PR #9 at `51970629f3c3af32cb73bea0aab676874478248d`. Mutable state must always be re-fetched before a decision.

## Purpose and audience

The audit has four jobs:

1. describe Engineering OS and the meaning of operational readiness;
2. expose every unresolved condition without hiding it behind a green structural check;
3. define dependency order and an end-to-end closure checklist for every non-closed gap;
4. prohibit the Project 8 behavioral experiment until the evaluated system is fully ready.

A reader must not need prior chat context, remembered PR history, or undocumented operator knowledge. Linked owner files provide implementation detail; this audit owns readiness status, dependency order, closure bars, and the experiment-start decision. It is not the future Project 8 prompt and must never be copied into the target session as coaching.

## System and repository context

### Engineering OS

Engineering OS is a documentation-as-code and enforcement framework for cross-project LLM engineering. It exists to make an LLM route tasks, use canonical policies and reusable assets, run evidence-backed result loops, preserve learning, and avoid unsupported claims. The entrypoint is `CLAUDE.md`; detailed policy owners live under `core/`; deterministic enforcement lives in `.claude/settings.json`, `scripts/hooks/`, `scripts/enforcement/`, and `.github/workflows/`; reusable knowledge lives in `patterns/`, `templates/`, `external-skills/`, and `external-systems/`; runbooks live in `docs/operations/`.

| Layer | Canonical location | Responsibility |
|---|---|---|
| Always-loaded navigation | `CLAUDE.md` | role, global principles, canonical links |
| Detailed policy | `core/` | workflow, precedence, hooks, quality, git, connectors, skills, learning, capabilities |
| Deterministic enforcement | `.claude/settings.json`, `scripts/hooks/`, `scripts/enforcement/`, `.github/workflows/` | block or validate non-compliance |
| Reusable knowledge | `patterns/`, `templates/`, `external-skills/`, `external-systems/` | reusable solutions and integrations |
| Durable gap state | `docs/operations/known-gaps.tsv` | one row per gap with owner, status, priority, test, closure, evidence |
| Readiness explanation | this file | system map, matrix, dependencies, checklists, readiness and experiment decisions |

### Project 8

Project 8 is the appointment-management product used for the future behavioral experiment. Verified repository evidence identifies a React/Vite client and an Express/Prisma server. The future workload direction is Vercel hosting plus Supabase/PostgreSQL, reuse of valid existing assets and secrets by reference, complete existing-feature behavior, and correct UI/UX including Hebrew UTF-8/RTL. Those are future experiment outcomes, not pre-start Engineering OS gaps.

### Repository boundary

Engineering OS policy, experiment design, audits, plans, and learning belong in Engineering OS. Project 8 should contain product code plus minimum machine-readable runtime and telemetry configuration. Target-side Markdown that identifies the experiment or prescribes internal Engineering OS behavior invalidates a blind run.

## Non-negotiable decisions

1. Validate mutable facts; do not guess.
2. No behavioral experiment or experiment prompt until every registered gap is exactly `closed`, the strict assertion passes on fresh `main`, and Yotam explicitly approves the start.
3. Technical qualification is not the experiment and cannot implement the Project 8 workload.
4. Never expose secret values in source, Markdown, logs, artifacts, screenshots, or browser bundles.
5. A policy statement, checkbox, PR body, local fixture, or self-only check cannot close a live gap.
6. Do not weaken valid tests to obtain green CI.
7. Merge, production deployment, DNS, credential rotation, data deletion, and shared provider changes require explicit owner approval.
8. Keep one canonical audit, gap registry, pattern registry, and readiness definition.

## How an LLM must use this audit

1. **Verify live state.** Fetch current `main`, this audit, `known-gaps.tsv`, relevant pull request state, exact head and merge SHAs, checks, workflow attempts, and review threads. Do not guess from a snapshot or PR description.
2. Read the canonical policy, enforcer, tests, runbook, and official references for the selected gap.
3. Select the next gap from the dependency plan, not easiest-first preference.
4. Create or update the Route Plan before writing.
5. Use a dedicated branch and ready-for-review pull request.
6. Implement every checklist item; green CI does not turn partial work into closure.
7. Run focused positive and negative tests, installed-target checks when applicable, then wider suites.
8. Reconcile every review finding and resolve all threads.
9. Update `known-gaps.tsv`, the ledger, matrix, checklist, and current scope only after matching evidence exists.
10. Require owner approval before merge, deployment, production mutation, or experiment start.
11. Run `bash scripts/enforcement/check-readiness-audit.sh --assert-full-ready` last.

When information is missing, mark it unknown, gather evidence, or register a new gap. Never present an inference as an evidence fact.

## Source-of-truth hierarchy

1. **Live GitHub and provider state** for mutable facts.
2. **Repository code and configuration** at the exact relevant commit.
3. **`known-gaps.tsv`** for canonical gap IDs, owners, statuses, priorities, tests, closure bars, and evidence paths.
4. **`operational-readiness-audit.md`** for context, classification, dependencies, and checklists.
5. Canonical policy and runbooks under `core/` and `docs/operations/`.
6. Official vendor documentation.
7. Plans, PR descriptions, comments, and historical findings as history only.
8. Chat and memory are non-canonical.

Conflicts must be recorded and resolved against the higher source; neither chat nor a stale summary overrides live GitHub or exact repository behavior.

## Evidence and closure standard

Closure identifies, as applicable: exact repository and path; branch and commit SHA; expected PR head and merge commit; implementation owner; focused positive and negative tests; installed target behavior; named non-self CI on the exact head; review reconciliation; live provider/runtime evidence; merge and post-merge validation; metadata-only secret-safe artifacts; residual risk and rollback.

“Passed” means the intended assertion ran and its output was inspected. Skipped, neutral, cancelled, stale-head, old green attempt, unrelated workflow, self-only `pr-policy`, empty telemetry, fabricated fixture, or generic “all checks passed” prose is not closure evidence. End-to-end means the real behavior layers are exercised together.

## Glossary

- **Engineering OS** — cross-project governance, workflow, knowledge, hooks, CI, and evidence framework.
- **Project 8** — future target product repository.
- **Behavioral experiment** — future uncoached Project 8 workload used to evaluate Engineering OS behavior and data capture.
- **Technical qualification session** — bounded non-product proof of installation, hooks, attribution, transport, privacy, archive, and repeatability.
- **Gap** — one unresolved condition with a canonical `gap_id`.
- **Gate** — deterministic hook, script, CI check, runtime check, or manual-by-design checklist.
- **Hard hook** — a protected-action hook whose infrastructure failure must fail closed.
- **Telemetry bundle** — validated metadata-only `manifest.json`, `events.jsonl`, and `latest-summary.md` for one exact run identity.
- **Operational Work History** — CI-generated PR evidence for commits, changes, checks, review, friction, and result-loop selection.
- **Exact-head** — evidence for the current PR head SHA.
- **Canonical owner** — the single repository file or registry authorized to define a concept.
- **Live-state claim** — versioned metadata binding a closed gap to exact repository, PR, reviewed head, merge commit, base branch, workflows, and checks.
- **Full operational readiness** — every gap closed, no Missing/Partially enforced matrix row, fresh live state, strict assertion success, and owner approval.
- **Future workload acceptance contract** — Project 8 outcomes evaluated during the experiment, not a pre-start gap.

## Gap lifecycle and priority

Allowed status: `open`, `blocked`, `mitigated`, `accepted-manual`, `closed`. Only `closed` is experiment-compatible. P0 invalidates safety, audit truth, enforcement trust, or experiment validity; P1 blocks reliable operation or full readiness; P2 blocks evidence quality or reproducible learning; P3 is lower immediate risk but still blocks the experiment under the owner's decision.

## Readiness statuses

- **Enforced** — deterministic hook, CI, or runtime gate blocks non-compliance.
- **Partially enforced** — deterministic subsets exist but material live or judgment evidence is missing; row links a non-closed gap.
- **Manual** — vocabulary only; matrix rows use Manual by design.
- **Manual by design** — intentionally human with an explicit checklist and review evidence.
- **Waiver-gated** — skipping requires explicit scoped waiver evidence.
- **Missing enforcement** — the requirement remains silently skippable and links a gap.
- **Not applicable** — no enforcement is expected.

## Coverage contract

Every matrix row names a Gate, Owner, and Evidence source. Every Partially enforced or Missing enforcement row links at least one non-closed `gap:<gap_id>`. Every non-closed registry row appears in the matrix and has a checklist below. Project 8 workload outcomes remain separate so the experiment is not circularly required before it starts.

## Readiness-claim contract

- **Audit complete** means the system is explained and every unresolved condition is registered with owner, priority, test, closure, evidence, dependency, and checklist.
- **Fully operationally ready** means every gap is `closed`, no row remains Missing or Partially enforced, live state has been rechecked, the strict assertion succeeds, and owner approval is recorded.

A complete audit may honestly describe an unready system. Registering a risk is not solving it.

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| audit-freshness | closed | P0 | Audit freshness. |
| route-plan-semantic-quality | closed | P1 | Route plan semantic quality. |
| connector-semantic-use | closed | P1 | Connector semantic use. |
| progress-semantic-lifecycle | closed | P1 | Progress semantic lifecycle. |
| learning-semantic-closure | closed | P1 | Learning semantic closure. |
| template-pattern-rating-lifecycle | closed | P1 | Template pattern rating lifecycle. |
| documentation-asset-selection-lifecycle | closed | P1 | Documentation asset selection lifecycle. |
| rtk-semantic-use | closed | P2 | Rtk semantic use. |
| graphify-semantic-use | closed | P2 | Graphify semantic use. |
| semantic-cleanup-depth | closed | P2 | Semantic cleanup depth. |
| review-fallback | closed | P2 | Review fallback. |
| post-merge-repair-observation | closed | P3 | Post merge repair observation. |
| connector-selection-coverage | closed | P2 | Connector selection coverage. |
| connector-result-identifiers | closed | P2 | Connector result identifiers. |
| template-selection-coverage | closed | P2 | Template selection coverage. |
| pattern-required-manifest | closed | P2 | Pattern required manifest. |
| skill-selection-coverage | closed | P2 | Skill selection coverage. |
| capability-staged-guard | closed | P1 | Capability staged guard. |
| run-trace-significant-scope | closed | P1 | Run trace significant scope. |
| simulation-waiver-fixtures | closed | P2 | Simulation waiver fixtures. |
| tests-tool-environment-contract | closed | P2 | Tests tool environment contract. |
| active-plan-selection | closed | P1 | Active plan selection. |
| pr-review-quality-schema | closed | P2 | Pr review quality schema. |
| merge-readiness-artifact | closed | P1 | Merge readiness artifact. |
| install-downstream-behavior | closed | P2 | Install downstream behavior. |
| result-loop-contract-enforcement | closed | P1 | Result loop contract enforcement. |
| scaling-extension-enforcement | closed | P1 | Scaling extension enforcement. |
| claude-operational-behavior-evidence | closed | P1 | Claude operational behavior evidence. |
| registry-coverage-backfill | closed | P2 | Registry coverage backfill. |
| canonical-telemetry-hardening-drift | closed | P1 | Canonical telemetry hardening drift. |
| monitoring-metrics-sufficiency | open | P2 | Monitoring metrics sufficiency. |
| monitoring-longitudinal-sufficiency | open | P2 | Monitoring longitudinal sufficiency. |
| project-8-real-run-evidence | open | P1 | Project 8 real run evidence. |
| operational-work-history-foundation | closed | P1 | Operational work history foundation. |
| dispatch-scope-double-record | mitigated | P1 | Dispatch scope double record. |
| multirepo-remote-telemetry-validation | open | P1 | Multirepo remote telemetry validation. |
| eos-repo-boundary-sync-drift | open | P3 | Eos repo boundary sync drift. |
| audit-live-state-verification | open | P0 | Audit live state verification. |
| hard-hook-fail-closed | open | P0 | Hard hook fail closed. |
| bypass-approval-provenance | open | P1 | Bypass approval provenance. |
| pattern-registry-canonical-drift | open | P1 | Pattern registry canonical drift. |
| pattern-evidence-maturity | open | P2 | Pattern evidence maturity. |
| documentation-runtime-state-drift | open | P1 | Documentation runtime state drift. |
| audit-self-contained-contract | closed | P0 | Audit self contained contract. |
| full-readiness-claim-semantics | open | P1 | Full readiness claim semantics. |
| project8-experiment-blindness | open | P0 | Project8 experiment blindness. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests. Owner: core-governance. Evidence: entrypoint and orphan fixtures. | Semantic quality is reviewed. |
| Canonical ownership / no policy sprawl | Enforced | Gate: check-documentation-hygiene.sh. Owner: docs-governance. Evidence: hygiene fixtures. | Deep semantics are reviewed. |
| Enforcement coverage inventory | Enforced | Gate: check-readiness-audit.sh. Owner: ops-readiness. Evidence: readiness fixtures. | Closure judgment is reviewed. |
| Audit self-contained contract | Enforced | Gate: check-readiness-audit.sh and context-free fixtures. Owner: ops-readiness. Evidence: merged PR #254, exact head `f74a26d65f6cebf06f29df1d803c192c3efb9694`, merge `c7d32a0b67a836811689d3a2bf80a63d727e1470`, and `docs/operations/live-state-claims.json`. | Closed; the live claim must continue to pass. |
| Audit registry freshness | Partially enforced | Gate: check-known-gaps.sh plus the new snapshot validator and `known-gaps-live-state` workflow. Owner: ops-readiness. Evidence: offline mismatch fixtures and PR #254 claim. | gap:audit-live-state-verification — this implementation still needs exact-head CI, merge, and push-to-main validation. |
| Documentation runtime state consistency | Missing enforcement | Gate: documentation hygiene exists. Owner: docs-governance. Evidence: `CLAUDE.md`, `README.md`, `core/quality-gates.md`, and executable owners. | gap:documentation-runtime-state-drift — known contradictions remain. |
| Route Plan before writing | Enforced | Gate: workflow write guards and target-aware plan selection. Owner: workflow-governance. Evidence: active-plan fixtures. | Plan intent is reviewed. |
| Route Plan quality | Enforced | Gate: check-workflow-evidence.sh. Owner: workflow-governance. Evidence: semantic-quality fixtures. | Deep source quality is reviewed. |
| DoD completion | Enforced | Gate: plan-policy and check-workflow-evidence.sh. Owner: delivery-governance. Evidence: completion fixtures. | Meaning of completion is reviewed. |
| Progress validation | Enforced | Gate: check-workflow-evidence.sh. Owner: progress-governance. Evidence: ordered lifecycle fixtures. | Evidence truthfulness is reviewed. |
| Connector selection | Enforced | Gate: check-required-connectors.sh. Owner: connector-governance. Evidence: manifest coverage fixtures. | Best connector choice is reviewed. |
| Connector correctness / source-of-truth use | Enforced | Gate: check-connector-evidence.sh. Owner: connector-governance. Evidence: target and identifier fixtures. | Deep result interpretation is reviewed. |
| Template selection | Enforced | Gate: check-required-templates.py. Owner: template-governance. Evidence: coverage and precision fixtures. | Template fit is reviewed. |
| Pattern usage | Enforced | Gate: check-required-patterns.sh. Owner: pattern-governance. Evidence: domain and waiver fixtures. | Pattern fit is reviewed. |
| Pattern lifecycle canonical ownership | Missing enforcement | Gate: documentation hygiene and required-pattern tests. Owner: pattern-governance. Evidence: registry, policy, README, and checker comparison. | gap:pattern-registry-canonical-drift — policy still contradicts the YAML owner used by execution. |
| Pattern evidence maturity | Missing enforcement | Gate: rating schema exists. Owner: pattern-governance. Evidence: `patterns/registry.yaml` and `patterns/README.md`. | gap:pattern-evidence-maturity — all patterns remain unproven candidates. |
| Template/pattern rating lifecycle | Enforced | Gate: check-template-pattern-ratings.sh. Owner: reuse-governance. Evidence: exact-asset feedback fixtures. | Feedback truthfulness is reviewed. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: check-documentation-asset-evidence.sh. Owner: asset-governance. Evidence: documentation selection fixtures. | Best source is reviewed. |
| Skill selection | Enforced | Gate: check-required-skills.sh. Owner: skill-governance. Evidence: inventory coverage fixtures. | Skill fit is reviewed. |
| Skill runtime evidence | Enforced | Gate: pre-tool-use-runtime-evidence.sh. Owner: skill-governance. Evidence: runtime fixtures. | Deep use is reviewed. |
| RTK context optimization | Enforced | Gate: required-skill and session setup checks. Owner: context-governance. Evidence: RTK hardening fixtures. | External effect is reviewed. |
| Graphify context graph | Enforced | Gate: check-plan-scope.sh. Owner: context-governance. Evidence: target-linked graph fixtures. | Graph accuracy is reviewed. |
| Claude memory / context carryover | Manual by design | Gate: manual review. Owner: context-governance. Evidence: Checklist: `docs/operations/memory-context-checklist.md`. | Runtime intent cannot be proven deterministically. |
| Capability registry | Enforced | Gate: capability-evidence-policy and write-gate validation. Owner: capability-governance. Evidence: `runtime_enabled: true` and staged-path fixtures. | Stale descriptive documents are tracked separately. |
| Learning schema | Enforced | Gate: enforce-learning.sh. Owner: learning-governance. Evidence: schema fixtures. | Content quality is covered separately. |
| Learning reuse | Enforced | Gate: Route Plan lesson-reuse evidence. Owner: learning-governance. Evidence: citation fixtures. | Relevance is reviewed. |
| Learning closure after bug/debug work | Enforced | Gate: enforce-learning-capture.sh. Owner: learning-governance. Evidence: closure fixtures. | Truthfulness is reviewed. |
| Claude run trace / experiment log | Enforced | Gate: enforce-run-trace.sh. Owner: trace-governance. Evidence: significant-scope fixtures. | Trace depth is reviewed. |
| Operational behavior evidence | Enforced | Gate: check-operational-behavior-evidence.sh through pr-policy. Owner: ops-readiness. Evidence: PR-body fixtures. | Evidence truthfulness is reviewed. |
| Positive/negative simulations | Enforced | Gate: check-simulation-coverage.sh. Owner: validation-governance. Evidence: completeness and waiver fixtures. | Scenario quality is reviewed. |
| Tests/lint before commit | Enforced | Gate: enforce-tests.sh. Owner: validation-governance. Evidence: tool-contract fixtures. | Tool selection is reviewed. |
| Cleanup debug leftovers | Enforced | Gate: enforce-quality.sh. Owner: cleanup-governance. Evidence: cleanup fixtures. | Novel cases remain review-based. |
| Cleanup semantic hygiene | Enforced | Gate: semantic-cleanup-policy and import-cleanup-policy. Owner: cleanup-governance. Evidence: cleanup fixtures. | Deep semantics are reviewed. |
| Project install contract | Enforced | Gate: install-policy-gates and generated-target tests. Owner: install-governance. Evidence: downstream behavior fixtures. | Live host fidelity is reviewed. |
| Hard-hook blocking semantics | Missing enforcement | Gate: hook classification and wrapper tests. Owner: hooks-governance. Evidence: `hook-criticality.tsv` and Claude Code hook semantics. | gap:hard-hook-fail-closed — missing enforcers and conversion failures can allow protected actions. |
| Enforcement bypass provenance | Missing enforcement | Gate: evidence ledger records bypass names. Owner: hooks-governance. Evidence: `bypass_active()`. | gap:bypass-approval-provenance — no durable approval reference, reason, bounded scope, issuer, or expiry is required. |
| Result Loop Contract enforcement | Enforced | Gate: named result-loop CI plus Operational Work History. Owner: ops-readiness. Evidence: fixtures and real positive/negative PRs. | Contract semantics are reviewed. |
| Operational work history evidence | Enforced | Gate: check-operational-work-history-evidence.sh through pr-policy. Owner: ops-readiness. Evidence: fixtures and real PRs. | Human interpretation remains reviewed. |
| Scaling extension enforcement | Enforced | Gate: named scaling CI step. Owner: ops-readiness. Evidence: scaling fixtures and merged evidence. | Deep roadmap quality is reviewed. |
| Registry/manifest coverage | Enforced | Gate: scaling coverage checks. Owner: registry-governance. Evidence: active rows across required manifests. | Registry content quality is reviewed. |
| Canonical telemetry trust boundaries | Enforced | Gate: telemetry-handoff-tests. Owner: ops-readiness. Evidence: merged PR #253 and exact-head regressions. | Live qualification remains separate. |
| Monitoring metrics first-run sufficiency | Missing enforcement | Gate: exporter, importer, analyzer, checksum, identity, and privacy tests exist. Owner: ops-readiness. Evidence: archive tests and runbooks. | gap:monitoring-metrics-sufficiency — one valid qualification bundle must be proven useful. |
| Monitoring longitudinal sufficiency | Missing enforcement | Gate: archive analyzer can compare runs. Owner: ops-readiness. Evidence: analyzer and archive plan. | gap:monitoring-longitudinal-sufficiency — two qualification sessions must prove repeatability. |
| Project 8 technical qualification evidence | Missing enforcement | Gate: mandatory telemetry preflight exists. Owner: ops-readiness. Evidence: Project 8 preflight and findings runbook. | gap:project-8-real-run-evidence — fresh non-product qualification evidence is missing. |
| Remote multi-repository telemetry dispatch | Partially enforced | Gate: dispatcher fixtures cover attribution, isolation, policy, failures, and PR matching. Owner: ops-readiness. Evidence: deterministic tests plus failed live attempt. | gap:dispatch-scope-double-record and gap:multirepo-remote-telemetry-validation — a fresh successful qualification session is required. |
| Engineering OS repository boundary hook synchronization | Missing enforcement | Gate: exact patcher verification exists. Owner: install-governance. Evidence: patch-settings-telemetry.py. | gap:eos-repo-boundary-sync-drift — checked-in boundary commands remain stale. |
| Full-readiness claim semantics | Partially enforced | Gate: merged `--assert-full-ready` and positive/negative fixtures. Owner: ops-readiness. Evidence: canonical checker/test on `main`. | gap:full-readiness-claim-semantics — the final assertion cannot pass until every other gap is closed and live state is reconciled. |
| Project 8 behavioral blindness | Missing enforcement | Gate: Project 8 PR #9 adds a product-only Markdown boundary. Owner: ops-readiness. Evidence: current target main and exact PR head. | gap:project8-experiment-blindness — target guidance still coaches and discloses the experiment until merge and fresh-session proof. |
| Git/branch policy | Enforced | Gate: pr-policy. Owner: merge-governance. Evidence: merge readiness artifact. | Live state is reviewed. |
| PR review / external review | Enforced | Gate: check-pr-review-evidence.sh through pr-policy. Owner: review-governance. Evidence: review fixtures. | Review depth is human. |
| Merge safety | Manual by design | Gate: owner decision. Owner: merge-governance. Evidence: Checklist: `docs/operations/merge-readiness-checklist.md`. | Human approval is intentional. |
| Post-merge validation | Enforced | Gate: post-merge-validation workflow. Owner: merge-governance. Evidence: repair-path fixtures. | Live failures use the incident checklist. |
| Known gaps register | Enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: schema, ledger, and optional live-snapshot validation. | Closure judgment is reviewed. |

## Dependency-ordered closure plan

Do not skip phases. Parallel work is permitted inside a phase only when files and claims do not conflict.

### Completed foundation

- `gap:audit-self-contained-contract` closed through merged PR #254, exact reviewed head `f74a26d65f6cebf06f29df1d803c192c3efb9694`, merge `c7d32a0b67a836811689d3a2bf80a63d727e1470`, context-free fixtures, and the canonical live-state claim.

### Phase 0 — make readiness truth trustworthy

1. `gap:audit-live-state-verification`
2. `gap:documentation-runtime-state-drift`
3. `gap:full-readiness-claim-semantics`

Exit: stale live claims fail, canonical descriptions agree with runtime, and strict readiness semantics remain valid on `main`.

### Phase 1 — close deterministic enforcement defects

1. `gap:hard-hook-fail-closed`
2. `gap:bypass-approval-provenance`
3. `gap:pattern-registry-canonical-drift`
4. `gap:pattern-evidence-maturity`
5. `gap:eos-repo-boundary-sync-drift`

Exit: protected actions fail safely, bypasses require durable approval, pattern ownership/evidence are honest, and repository hooks match the installer.

### Phase 2 — remove target coaching

1. Re-verify Project 8 PR #9 exact head, diff, checks, and all threads.
2. Obtain owner approval and merge with expected-head protection.
3. Run post-merge product-boundary checks.
4. Open a fresh session and prove removed guidance was not loaded.
5. Close `gap:project8-experiment-blindness`.

### Phase 3 — technical qualification, not behavioral experiment

1. Close `gap:dispatch-scope-double-record` and `gap:multirepo-remote-telemetry-validation` with fresh Remote qualification.
2. Close `gap:project-8-real-run-evidence` with an exact Project 8 non-product bundle.
3. Close `gap:monitoring-metrics-sufficiency` after import, analysis, privacy, and usefulness review.
4. Run a second qualification and close `gap:monitoring-longitudinal-sufficiency` through reproducible comparison.

### Phase 4 — final readiness declaration

1. Verify every registry row is `closed` and no matrix row is Missing or Partially enforced.
2. Re-fetch live GitHub state and provider-neutral qualification evidence.
3. Run the live-state workflow and `check-known-gaps.sh`.
4. Run normal readiness validation and `--assert-full-ready` on canonical `main`.
5. Obtain explicit owner approval to prepare and send the behavioral experiment prompt.

## Definition of full operational readiness

A full-readiness claim requires every gap exactly `closed`; only terminal acceptable matrix statuses; exact implementation/test/install/CI/review/merge/post-merge evidence; immediate live external reconciliation; no qualification evidence mislabeled as experiment evidence; strict assertion success on canonical `main`; and explicit Yotam approval. The current repository does **not** satisfy this definition.

## Mandatory end-to-end closure checklists

A gap moves to `closed` only when every applicable checkbox has an exact file, SHA, PR, workflow run, artifact, provider identifier, or inspected output. PR-body prose alone is insufficient.

### gap:audit-self-contained-contract — P0 — closed

Official basis: <https://code.claude.com/docs/en/memory> and AWS Operational Excellence.

- [x] Metadata, purpose, system architecture, repository boundary, non-negotiable decisions, glossary, hierarchy, evidence rules, and LLM procedure are context-free.
- [x] Qualification, experiment, and future workload boundaries are distinct.
- [x] Dependency phases contain every non-closed gap.
- [x] `check-readiness-audit.sh` requires the context-free contract and negative fixtures reject removal.
- [x] Exact-head CI and seven review threads were reconciled on PR #254.
- [x] PR #254 merged as `c7d32a0b67a836811689d3a2bf80a63d727e1470`; `docs/operations/live-state-claims.json` binds the reviewed head and post-merge workflows.

### gap:audit-live-state-verification — P0

Official basis: GitHub REST pull requests, check runs, workflow runs, compare commits, Actions security hardening, plus official `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description` repositories.

- [x] Extend the canonical known-gaps path rather than create a second registry.
- [x] Define versioned claims binding gap, repository, PR, base, head, merge, named PR workflows, push workflows, and checks.
- [x] Implement a fail-closed REST fetcher that paginates documented endpoints and emits metadata only.
- [x] Implement one deterministic validator shared by offline fixtures and live CI snapshots.
- [x] Reject unmerged, stale-head, stale-merge, diverged-base, older-green/newer-failure, skipped, neutral, missing-workflow, malformed, open-gap, and self-only evidence fixtures.
- [x] Register PR #254 as the first real reconciliation target.
- [ ] Pass the dedicated `known-gaps-live-state` workflow on the implementation PR exact head and inspect its metadata-only artifact.
- [ ] Reconcile all review findings, merge only after owner approval, then pass the same workflow and post-merge validation on `main` before closing this gap.

### gap:documentation-runtime-state-drift — P1

Official basis: <https://code.claude.com/docs/en/memory>.

- [ ] Reconcile CLAUDE capability runtime scope with `core/capability-registry.yaml`.
- [ ] Remove README hard-coded policy counts or generate them.
- [ ] Reconcile CodeRabbit availability statements with policy and observed review.
- [ ] Search all canonical entrypoints for equivalent contradictions.
- [ ] Add negative documentation-hygiene fixtures.
- [ ] Complete exact-head review, merge, and post-merge validation.

### gap:full-readiness-claim-semantics — P1

- [x] Normal audit validation can pass an honestly incomplete audit.
- [x] `--assert-full-ready` fails for every non-closed status and every Missing/Partially enforced row.
- [x] Open, mitigated, accepted-manual, and fully-ready fixtures exist and the assertion is merged on `main` through PR #254.
- [x] The final experiment-start procedure requires the strict assertion.
- [ ] After all other gaps close, run the assertion against fresh canonical files and live-state reconciliation; merge/post-merge evidence must support the final closure.

### gap:hard-hook-fail-closed — P0

Official basis: <https://code.claude.com/docs/en/hooks>.

- [ ] Missing hard enforcer blocks instead of returning success.
- [ ] Deny-conversion, interpreter, and runtime failure block with `exit 2` and reason.
- [ ] Fail-open remains only for explicitly advisory/recorder units.
- [ ] Every hard PreToolUse path runs the JSON guard and is not soft-wrapped.
- [ ] Missing-enforcer, converter-failure, malformed-input, violation, and success fixtures pass.
- [ ] Installed-target copy, exact-head CI/review, merge, and post-merge behavior are verified.

### gap:bypass-approval-provenance — P1

- [ ] Define one canonical waiver record with bypass, approval reference, reason, bounded target/action, issuer, creation, and expiry/one-shot semantics.
- [ ] Reject truthy bypass variables without a complete matching record.
- [ ] Reject blank/generic reason, wrong bypass/target, stale scope, forged record, and master substitution.
- [ ] Record accepted metadata without secrets or conversation content and surface it in Stop/PR evidence.
- [ ] Run positive/negative/install/full suites, review, merge, and post-merge validation.

### gap:pattern-registry-canonical-drift — P1

- [ ] Declare `patterns/registry.yaml` canonical for identity, domain, lifecycle, score, version, use, and evidence.
- [ ] Keep domain READMEs canonical for implementation/security/testing guidance.
- [ ] Remove the contradictory “no YAML registry” statement and align all consumers.
- [ ] Add a documentation-hygiene negative fixture and verify all paths/domains.
- [ ] Complete exact-head review, merge, and post-merge validation.

### gap:pattern-evidence-maturity — P2

Official basis: AWS Operational Excellence feedback-loop guidance.

- [ ] Report status, `used_in`, score, and evidence for every pattern.
- [ ] Identify the minimum patterns needed by remaining readiness and qualification work.
- [ ] Link real project use, exact PR/commit, tests, outcomes, incidents, and adaptation cost.
- [ ] Update evidence/version/score only from verified results; apply the canonical guide.
- [ ] Promote only after documented multi-context thresholds; record failures and downgrades.
- [ ] Add fixtures rejecting status/score without evidence; no bulk promotion.

### gap:eos-repo-boundary-sync-drift — P3

- [ ] Patch Engineering OS `.claude/settings.json` through the canonical direct-mode patcher.
- [ ] Verify catch-all PreToolUse, SessionStart, Stop, StopFailure, and SessionEnd commands exactly.
- [ ] Ensure terminal events synchronize boundaries.
- [ ] Pass patcher, trust-boundary, archive, hook-classification, full suites, review, merge, and post-merge validation.

### gap:project8-experiment-blindness — P0

Official basis: <https://code.claude.com/docs/en/memory>.

- [ ] Re-fetch Project 8 PR #9 and verify expected head, product-boundary-only diff, checks, and every current/outdated thread.
- [ ] Classify the legacy Azure failure honestly; never treat it as Vercel success.
- [ ] Obtain owner approval and merge with expected-head protection.
- [ ] Verify `project-8/main` contains no tracked local prompt/audit/plan/README or Engineering OS coaching and blocks reintroduction.
- [ ] Verify machine-readable settings contain no experiment/task-routing prose.
- [ ] Close old sessions, open a fresh session, and prove removed guidance was not loaded; do not supply the future workload prompt.

### gap:dispatch-scope-double-record and gap:multirepo-remote-telemetry-validation — P1

- [ ] Start a fresh Remote qualification only after exact dispatcher installation verification.
- [ ] Prove managed initialization, unmanaged exclusion, identity agreement, unrelated-activity isolation, distinct run IDs, and host-only correlation.
- [ ] Revoke a marker mid-session and prove attribution/fan-out stop.
- [ ] Complete terminal boundaries and required handoff failure surfacing.
- [ ] Produce exact-match non-empty bundles and prove PR selection cannot cross repositories.
- [ ] Review privacy and record that no product feature or behavioral prompt was used.

### gap:project-8-real-run-evidence — P1

Official basis: Claude Code hooks and GitHub workflow artifacts.

- [ ] Update actual `ENGINEERING_OS_HOME` to exact merged `main`; install and pass `--verify`.
- [ ] Verify Project 8 telemetry policy, close old sessions, and open a fresh post-install session.
- [ ] Require positive session, remote-handoff, and boundary counts before a task.
- [ ] Run one bounded non-product task without `--empty-run`, feature implementation, or future prompt.
- [ ] Match run/repository/branch/head/policy/handoff and exact telemetry PR bundle.
- [ ] Select only manifest/events/summary, prove positive counts and metadata-only privacy.
- [ ] Import, analyze, and label findings as qualification evidence only.

### gap:monitoring-metrics-sufficiency — P2

Official basis: Google SRE monitoring and OpenTelemetry instrumentation guidance.

- [ ] Complete the first Project 8 qualification checklist and import one checksum-valid identity-matched non-empty bundle.
- [ ] Preserve analyzer output and separate runtime, OWH, qualification outcome, and future product outcomes.
- [ ] Record coverage, missing events, tools/connectors, failures, friction, false positives, attribution, privacy, duplicates, and decision usefulness.
- [ ] Demonstrate one question the data answers and one limitation; obtain independent review before closure.

### gap:monitoring-longitudinal-sufficiency — P2

- [ ] Run a later qualification with the same schema/privacy/identity contracts and import at least two runs.
- [ ] Compare coverage, attribution, tools, failures, retries, duplicates, privacy, archive, and analyzer output.
- [ ] Separate recurring blind spots from one-off failures and record improvement/regression/no-change.
- [ ] Create follow-up enforcement for recurring gaps or justify manual-by-design treatment.
- [ ] Prove reproducibility from archived bundles without making Project 8 workload claims.

## Highest-priority gaps by ROI

1. Live-state verification — P0; self-contained audit contract closed by PR #254.
2. Hard-hook fail-closed — P0.
3. Project 8 experiment blindness — P0.
4. Documentation/runtime consistency and final full-readiness assertion — P1.
5. Bypass approval provenance and canonical pattern ownership — P1.
6. Engineering OS boundary synchronization and fresh Remote qualification — P1/P3.
7. Project 8 qualification and first-run monitoring sufficiency — P1/P2.
8. Pattern evidence maturity and second-run repeatability — P2.

Closed regression surfaces retained by the readiness gate: coverage map hardening; RTK runtime hardening; route plan quality gate; learning closure gate; progress lifecycle; connector correctness; simulation completeness; post-merge validation; documentation hygiene; semantic cleanup.

## Experiment start decision

The Project 8 behavioral experiment is **blocked**. It may begin only when every registered gap is exactly `closed`; no matrix row remains Missing or Partially enforced; required technical qualification is complete and separate from experiment evidence; live GitHub state is re-fetched; `--assert-full-ready` passes on canonical `main`; and Yotam explicitly approves preparation and delivery of the prompt.

No prompt is required or authorized at the current stage. Do not draft, store, or send one as readiness-gap work.

## Future Project 8 workload acceptance contract

This contract preserves the eventual experiment objective and must not be supplied to the target model before approval.

Official basis: Vercel environments/variables/Vite/Express/monorepos/domains; Supabase RLS/API keys/secure data/Postgres connections; Prisma with Supabase; Playwright; W3C accessible forms.

### Existing assets and secrets

- Inventory existing Vercel project/team, environments, deployments, aliases, domains, and repo link.
- Inventory Supabase project reference, schemas, migrations, auth/storage use, URL/key presence, and pooled/direct connections.
- Inventory GitHub secret/variable names and scopes without values.
- Reuse valid resources and integrations; create/rotate/remove only with reason and rollback.
- Prove no secret enters source, Markdown, logs, artifacts, screenshots, browser bundles, or public client variables.

### Supabase / PostgreSQL outcome

- Preserve isolated Postgres foundation tests; map and remove active SQL Server/T-SQL assumptions.
- Use one Prisma/Supabase runtime boundary, pooled runtime connection, and direct migration connection.
- Apply versioned migrations and verify live history.
- Enable/force RLS where required; prove least privilege and cross-tenant read/write isolation.
- Keep service-role credentials server-only and validate every existing route/background behavior.

### Vercel outcome

- Reuse the valid existing project and record supported Vite/Express/monorepo roots, build, output, routes, and functions.
- Map variables to Development, Preview, and Production by safe name/scope.
- Deploy exact PR head to a commit-specific Preview and run API/database/browser E2E against it.
- Reuse the production domain; inspect DNS first; prove assets, routes, cookies, CORS, redirects, and DB connectivity.
- Do not deploy production or change DNS without approval.

### Feature, UI/UX, encoding, and end-to-end outcome

- Inventory every actual client/server route, navigation path, test, and integration.
- Give every feature an evidence-backed status and add/repair API/integration/browser tests.
- Cover auth, business setup, public booking, appointments, settings, dashboards, customers, waitlist, cancellation/rescheduling, notifications/integrations, legal/cookies, and error states when present.
- Run critical flows in Chromium, WebKit, Firefox, and mobile where practical.
- Validate Hebrew UTF-8, RTL, translations, timezone, responsiveness, keyboard/focus, labels, validation, and loading/empty/error states.
- Capture exact-Preview screenshots/traces, fix all defects without weakening tests, rerun complete suites, record safe provider/migration/RLS evidence, risk and rollback, and require approval before merge/production plus post-merge smoke validation.

## Current audit scope

PR #254 is merged as `c7d32a0b67a836811689d3a2bf80a63d727e1470`; the self-contained audit contract is closed and represented by a versioned live-state claim. Branch `feat/audit-live-state-verification` implements claim schema, fail-closed GitHub REST acquisition, deterministic snapshot validation, offline regressions, and a dedicated read-only live workflow. That P0 gap remains open until its own PR is exact-head green, reviewed, owner-approved, merged, and validated on `main`.

The system is audit-complete but not fully operationally ready. Runtime, documentation, pattern, Project 8 boundary, and qualification gaps remain. The behavioral experiment and its prompt remain prohibited until every gap closes and the strict assertion passes on fresh canonical state.
