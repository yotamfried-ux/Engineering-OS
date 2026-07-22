# Engineering OS Operational Readiness Audit

This document is the canonical status map and closure contract for Engineering OS operational readiness. It is written so a capable LLM or human reviewer can begin here without prior chat context, understand the system and target, identify the next unresolved gap, and know exactly what evidence is required before any readiness or experiment claim.

## Audit metadata

- **Audit owner:** Yotam Friedman; operational owner group `ops-readiness`
- **Canonical repository:** `yotamfried-ux/Engineering-OS`
- **Target repository:** `yotamfried-ux/project-8`
- **Canonical gap registry:** `docs/operations/known-gaps.tsv`
- **Last verified:** 2026-07-21 America/Panama / 2026-07-22 UTC
- **Intended readers:** LLMs, maintainers, reviewers, and operators with no prior conversation context
- **Snapshot only:** Engineering OS `main` was inspected at `bc160ee4d2058acd28ae2325d23fcbcb926de888`; Project 8 `main` at `f282f5e9889d956e54fc0803938915fd86a58158`; Project 8 PR #9 at `51970629f3c3af32cb73bea0aab676874478248d`. Mutable state must always be re-fetched before a decision.

## Purpose and audience

The audit has four jobs:

1. describe what Engineering OS is and what “operationally ready” means;
2. expose every known unresolved condition without hiding it behind a green structural check;
3. give an exact, dependency-ordered checklist for closing each gap end to end;
4. prevent the Project 8 behavioral experiment from starting before the system that will be evaluated is itself fully ready.

A reader must not need prior chat context, a remembered PR history, or undocumented operator knowledge. When this audit links another file, that file provides implementation detail; this audit still owns the readiness status, dependency order, closure bar, and experiment decision.

This document is not the future Project 8 prompt and must never be copied into the target session as coaching.

## System and repository context

### Engineering OS

Engineering OS is a documentation-as-code and enforcement framework used across software projects. Its purpose is to make an LLM follow a repeatable engineering workflow instead of guessing. The canonical entrypoint is `CLAUDE.md`; detailed policy owners live under `core/`; deterministic enforcement lives in hooks, scripts, manifests, and GitHub Actions; reusable implementation knowledge lives in `patterns/`, `templates/`, `external-skills/`, and `external-systems/`; operational evidence is recorded through PR artifacts and telemetry.

Primary layers:

| Layer | Canonical location | Responsibility |
|---|---|---|
| Always-loaded navigation | `CLAUDE.md` | role, global principles, and links to canonical owners |
| Detailed policy | `core/` | workflow, precedence, hooks, quality, git, connectors, skills, learning, capabilities |
| Deterministic enforcement | `.claude/settings.json`, `scripts/hooks/`, `scripts/enforcement/`, `.github/workflows/` | block or validate non-compliance |
| Reusable knowledge | `patterns/`, `templates/`, `external-skills/`, `external-systems/` | reusable solutions and integrations |
| Operational runbooks | `docs/operations/` | installation, telemetry, recovery, and evidence procedures |
| Durable gap state | `docs/operations/known-gaps.tsv` | one row per gap, owner, status, priority, tests, closure, evidence |
| Readiness explanation | this file | system map, matrix, dependencies, checklists, readiness and experiment decisions |

### Project 8

Project 8 is the target appointment-management product used for the future behavioral experiment. Verified repository evidence identifies a React/Vite client and an Express/Prisma server. The intended final provider direction for the future workload is:

- cloud hosting and deployment: **Vercel**;
- database: **Supabase / PostgreSQL**;
- reuse valid existing domains, URLs, provider projects, environment variables, API-key configuration, and integrations instead of creating duplicates;
- make every existing product feature work end to end, including UI/UX, Hebrew UTF-8/RTL, and deployed behavior.

Those product requirements are the workload the future experiment will evaluate. They are preserved later in this audit as an acceptance contract, not misclassified as a pre-start Engineering OS gap.

### Repository boundary

Engineering OS policy, experiment design, audits, plans, and learning artifacts belong in the Engineering OS repository. Project 8 should contain product code plus the minimum machine-readable runtime and telemetry configuration needed to use the external system. Target-side Markdown that tells Claude it is in an experiment or prescribes internal Engineering OS behavior invalidates a blind behavioral run.

## Non-negotiable decisions

1. **Validate, do not guess.** Every mutable claim must be checked through the relevant repository, CI, provider, file, or runtime tool.
2. **No behavioral experiment yet.** The Project 8 behavioral experiment and its prompt remain blocked until every registered gap is `closed`, `check-readiness-audit.sh --assert-full-ready` passes on fresh state, and the owner explicitly approves the start.
3. **Qualification is not the experiment.** Bounded technical qualification sessions may verify installation, attribution, telemetry transport, archive import, privacy, and repeatability. They must not implement Product 8 features, receive the future workload prompt, or be counted as experiment outcomes.
4. **No secret disclosure.** Record names, identifiers, presence, scope, and validation outcomes; never store secret values in source, Markdown, logs, artifacts, screenshots, or browser bundles.
5. **No false closure.** A policy statement, checkbox, PR body, local test, or fixture alone cannot close a gap that requires installed, live, merged, or post-merge evidence.
6. **No test weakening.** Do not skip, delete, soften, or rewrite a valid failing test merely to obtain green CI.
7. **Owner-gated irreversible actions.** Merge to `main`, production deployment, DNS changes, credential rotation, data deletion, and shared provider-resource changes require explicit owner approval.
8. **One canonical owner.** Do not create a competing audit, gap registry, pattern registry, or readiness definition.

## How an LLM must use this audit

A new LLM must follow this sequence:

1. **Verify live state.** Fetch current `main`, this audit, `known-gaps.tsv`, relevant PRs, exact head SHAs, checks, and review threads. Do not guess from this snapshot or a PR description.
2. **Read canonical owners.** For the selected area, read the exact policy, enforcer, tests, runbook, and official references named by the matrix and checklist.
3. **Select the next gap by dependency.** Use `Dependency-ordered closure plan`, not personal preference or easiest-first ordering.
4. **Create or update the Route Plan before writing.** Name exact targets, validators, evidence, dependencies, and owner decisions.
5. **Use a dedicated branch and ready-for-review pull request.** Do not write directly to `main`.
6. **Implement every checklist item.** A partial implementation stays open even when CI is green.
7. **Run focused positive and negative tests, then the wider suites.** Verify the installed target copy and live behavior when required.
8. **Reconcile review.** Fix or explicitly reject every relevant finding with evidence; all threads must be resolved.
9. **Update status only after closure evidence exists.** Keep `known-gaps.tsv`, the freshness ledger, matrix, checklist, and current scope synchronized.
10. **Require owner approval.** Do not merge, deploy, change production state, or start the behavioral experiment without explicit approval.
11. **Run the full-readiness assertion last.** The behavioral experiment is prohibited unless `bash scripts/enforcement/check-readiness-audit.sh --assert-full-ready` succeeds against fresh canonical files.

When information is missing, mark it unknown, gather evidence, or register a new gap. Never fill an evidence field with an inference presented as fact.

## Source-of-truth hierarchy

When sources disagree, use this order and record the conflict:

1. **Live GitHub and provider state** for mutable facts: current branch heads, PR state, checks, reviews, deployments, domains, database migrations, environment scopes, and provider identifiers.
2. **Exact repository code and configuration** at the relevant commit for implemented behavior.
3. **`docs/operations/known-gaps.tsv`** for canonical gap IDs, owners, statuses, priorities, tests, closure bars, and evidence paths.
4. **`docs/operations/operational-readiness-audit.md`** for system context, readiness classification, dependency order, and complete closure checklists.
5. **Canonical policy and runbooks** under `core/` and `docs/operations/` for detailed rules and procedures.
6. **Official vendor documentation** for external behavior and supported implementation contracts.
7. **Plans, PR descriptions, comments, and historical findings** as evidence history only; they do not override current code or live state.
8. **Chat and memory** are non-canonical. A decision that must survive must be written into the repository owner file.

## Evidence and closure standard

Every gap closure must identify, as applicable:

- exact repository, file path, branch, and commit SHA;
- expected PR head SHA and merge commit;
- exact implementation behavior and the canonical owner file;
- focused positive and negative tests that fail before the fix and pass after it;
- installed target behavior, not only source-repository behavior;
- named non-self CI checks on the exact head;
- all review findings and thread resolution;
- live provider or runtime evidence when the claim concerns an external system;
- post-merge validation on `main`;
- metadata-only, secret-safe evidence artifacts;
- residual risks and rollback where shared or production state is affected.

“Passed” means the intended assertion was exercised and its output was inspected. A skipped job, unrelated green workflow, self-referential `pr-policy`, old head, empty telemetry run, fabricated fixture, or generic “all checks passed” statement is not closure evidence.

End-to-end means the real layers used by the behavior are exercised together. For Product 8 this can include browser, client, API, authentication, database, provider configuration, and deployed Preview URL—not merely a unit test or local page load.

## Glossary

- **Engineering OS** — the cross-project governance, workflow, knowledge, hook, CI, and evidence framework in `yotamfried-ux/Engineering-OS`.
- **Project 8** — the appointment-management product in `yotamfried-ux/project-8`, used as the future experiment target.
- **Behavioral experiment** — the future uncoached Product 8 workload used to evaluate whether Engineering OS changes LLM behavior and collects useful data.
- **Technical qualification session** — a bounded non-product session used only to prove installation, hook execution, attribution, transport, privacy, archive import, and repeatability before the behavioral experiment.
- **Gap** — an unresolved condition with one canonical `gap_id` in `known-gaps.tsv`.
- **Gate** — a deterministic hook, script, CI check, runtime check, or manual-by-design checklist that validates or blocks a requirement.
- **Hard hook** — a hook classified to block the protected action; infrastructure failure must not silently allow the action.
- **Advisory/recorder hook** — a non-blocking unit that records or warns and may fail open only when explicitly classified that way.
- **Telemetry bundle** — the validated metadata-only files `manifest.json`, `events.jsonl`, and `latest-summary.md` associated with one exact run identity.
- **Operational Work History (OWH)** — the CI-generated PR artifact summarizing commits, changed files, checks, reviews, friction, and selected result-loop contract.
- **Exact-head** — evidence produced for the current PR head SHA, not an earlier commit or merge preview unless the claim explicitly targets it.
- **Canonical owner** — the single repository file or registry authorized to define a concept.
- **Fully operationally ready** — every registered gap is closed, no matrix row remains Missing or Partially enforced, live state is fresh, and the strict assertion passes.
- **Future workload acceptance contract** — the Product 8 outcomes to evaluate during the behavioral experiment; it is not a pre-start readiness gap.

## Gap lifecycle and priority

Allowed gap statuses:

- `open` — unresolved and not sufficiently mitigated;
- `blocked` — unresolved and waiting on a named dependency;
- `mitigated` — deterministic risk is reduced but required closure evidence is still missing;
- `accepted-manual` — intentionally manual risk recorded with explicit ownership; under the current owner decision it still blocks the behavioral experiment;
- `closed` — every closure requirement has exact evidence and post-merge validation where applicable.

Priority:

- `P0` — invalidates safety, audit truth, enforcement trust, or experiment validity;
- `P1` — blocks reliable operation, target qualification, or a full-readiness claim;
- `P2` — blocks evidence quality, maturity, or reproducible learning;
- `P3` — lower immediate risk but still must close before the behavioral experiment under the current decision.

A gap may change status only in the same change that updates its exact evidence. Reclassification must explain why the old category was wrong; it may not be used to avoid required work.

## Readiness statuses

- **Enforced** — a deterministic hook, CI check, or runtime gate blocks non-compliance.
- **Partially enforced** — deterministic cases are covered but important live or judgment evidence remains; the row links a non-closed gap.
- **Manual** — vocabulary term only; matrix rows must use Manual by design instead.
- **Manual by design** — intentionally human, with an explicit checklist and review evidence.
- **Waiver-gated** — skipping is allowed only with explicit scoped waiver evidence.
- **Missing enforcement** — policy or tooling exists but the requirement can still be skipped; the row links a non-closed gap.
- **Not applicable** — no enforcement is expected for the area.

## Coverage contract

Every matrix row names a Gate, Owner, and Evidence source. Every Partially enforced or Missing enforcement row links at least one non-closed `gap:<gap_id>`. Every non-closed registered gap appears in the matrix and has a mandatory checklist below. The future Product 8 workload acceptance contract is intentionally separate from the gap ledger so the work being evaluated is not circularly required before the experiment starts.

## Readiness-claim contract

Two claims are different:

- **Audit complete** means the system is explained, every requirement is classified, and every unresolved condition is registered with an owner, priority, test, closure bar, evidence source, dependency, and checklist.
- **Fully operationally ready** means every registered gap is `closed`, no row remains Missing enforcement or Partially enforced, current live state has been rechecked, the strict assertion succeeds, and owner approval is recorded.

A complete audit may honestly describe an unready system. Registering a gap makes the risk visible; it does not solve it.

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| audit-freshness | closed | P0 | Registry-to-audit schema and status synchronization. |
| route-plan-semantic-quality | closed | P1 | Route Plan source quality. |
| connector-semantic-use | closed | P1 | Connector correctness and target impact. |
| progress-semantic-lifecycle | closed | P1 | Ordered progress validation. |
| learning-semantic-closure | closed | P1 | Learning closure after debugging. |
| template-pattern-rating-lifecycle | closed | P1 | Reusable-asset feedback lifecycle. |
| documentation-asset-selection-lifecycle | closed | P1 | Documentation asset selection. |
| rtk-semantic-use | closed | P2 | RTK impact evidence. |
| graphify-semantic-use | closed | P2 | Graphify target-linked use. |
| semantic-cleanup-depth | closed | P2 | Semantic and import cleanup. |
| review-fallback | closed | P2 | Structured review fallback. |
| post-merge-repair-observation | closed | P3 | Post-merge repair-path observation. |
| connector-selection-coverage | closed | P2 | Connector selection coverage. |
| connector-result-identifiers | closed | P2 | Concrete connector result identifiers. |
| template-selection-coverage | closed | P2 | Template selection coverage. |
| pattern-required-manifest | closed | P2 | Required pattern manifest. |
| skill-selection-coverage | closed | P2 | Skill selection coverage. |
| capability-staged-guard | closed | P1 | Staged capability guard. |
| run-trace-significant-scope | closed | P1 | Significant-scope run trace. |
| simulation-waiver-fixtures | closed | P2 | Simulation waiver fixtures. |
| tests-tool-environment-contract | closed | P2 | Test-tool environment contract. |
| active-plan-selection | closed | P1 | Target-aware active plan selection. |
| pr-review-quality-schema | closed | P2 | PR review evidence quality. |
| merge-readiness-artifact | closed | P1 | Structured merge readiness. |
| install-downstream-behavior | closed | P2 | Installed-target behavior. |
| result-loop-contract-enforcement | closed | P1 | Result Loop Contract enforcement. |
| scaling-extension-enforcement | closed | P1 | Scaling extension enforcement. |
| claude-operational-behavior-evidence | closed | P1 | Operational behavior evidence. |
| registry-coverage-backfill | closed | P2 | Registry and manifest coverage. |
| canonical-telemetry-hardening-drift | closed | P1 | Canonical telemetry trust-boundary hardening merged. |
| monitoring-metrics-sufficiency | open | P2 | First valid qualification bundle must be imported and shown useful. |
| monitoring-longitudinal-sufficiency | open | P2 | Two qualification sessions must prove repeatable capture and analysis. |
| project-8-real-run-evidence | open | P1 | Fresh Project 8 technical qualification evidence is missing. |
| operational-work-history-foundation | closed | P1 | CI-generated operational work history. |
| dispatch-scope-double-record | mitigated | P1 | Direct-hook and dispatcher coexistence awaits fresh observation. |
| multirepo-remote-telemetry-validation | open | P1 | Fresh successful Remote qualification evidence is missing. |
| eos-repo-boundary-sync-drift | open | P3 | Engineering OS repository-local boundary hooks are stale. |
| audit-live-state-verification | open | P0 | Audit closure claims are not checked against live GitHub truth. |
| hard-hook-fail-closed | open | P0 | Hard hook infrastructure failures can currently fail open. |
| bypass-approval-provenance | open | P1 | Bypass variables lack durable scoped approval proof. |
| pattern-registry-canonical-drift | open | P1 | Pattern policy contradicts the executable registry owner. |
| pattern-evidence-maturity | open | P2 | No pattern has mature scored multi-project evidence. |
| documentation-runtime-state-drift | open | P1 | Canonical docs contradict current runtime and review state. |
| audit-self-contained-contract | open | P0 | Context-free audit structure is implemented on this PR but not merged. |
| full-readiness-claim-semantics | open | P1 | Strict all-gaps-closed assertion is implemented on this PR but not merged. |
| project8-experiment-blindness | open | P0 | Target-side guidance still discloses and coaches the experiment. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests. Owner: core-governance. Evidence: entrypoint and orphan fixtures. | Semantic quality is reviewed. |
| Canonical ownership / no policy sprawl | Enforced | Gate: check-documentation-hygiene.sh. Owner: docs-governance. Evidence: hygiene fixtures. | Deep semantics are reviewed. |
| Enforcement coverage inventory | Enforced | Gate: check-readiness-audit.sh. Owner: ops-readiness. Evidence: readiness fixtures. | Closure judgment is reviewed. |
| Audit self-contained contract | Missing enforcement | Gate: expanded checker and fixtures exist on PR #254. Owner: ops-readiness. Evidence: `check-readiness-audit.sh` and `test-readiness-audit.sh`. | gap:audit-self-contained-contract — merge and post-merge proof remain. |
| Audit registry freshness | Partially enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: ledger-sync fixtures. | gap:audit-live-state-verification — both canonical files can still agree while stale relative to GitHub. |
| Documentation runtime state consistency | Missing enforcement | Gate: documentation hygiene exists. Owner: docs-governance. Evidence: `CLAUDE.md`, `README.md`, `core/quality-gates.md`, and executable owners. | gap:documentation-runtime-state-drift — known contradictions remain. |
| Route Plan before writing | Enforced | Gate: workflow write guards and target-aware plan selection. Owner: workflow-governance. Evidence: active-plan fixtures. | Plan intent is reviewed. |
| Route Plan quality | Enforced | Gate: check-workflow-evidence.sh. Owner: workflow-governance. Evidence: semantic-quality fixtures. | Deep source quality is reviewed. |
| DoD completion | Enforced | Gate: plan-policy and check-workflow-evidence.sh. Owner: delivery-governance. Evidence: completion fixtures. | Meaning of completion is reviewed. |
| Progress validation | Enforced | Gate: check-workflow-evidence.sh. Owner: progress-governance. Evidence: ordered lifecycle fixtures. | Evidence truthfulness is reviewed. |
| Connector selection | Enforced | Gate: check-required-connectors.sh. Owner: connector-governance. Evidence: manifest coverage fixtures. | Best connector choice is reviewed. |
| Connector correctness / source-of-truth use | Enforced | Gate: check-connector-evidence.sh. Owner: connector-governance. Evidence: target and identifier fixtures. | Deep result interpretation is reviewed. |
| Template selection | Enforced | Gate: check-required-templates.py. Owner: template-governance. Evidence: coverage and precision fixtures. | Template fit is reviewed. |
| Pattern usage | Enforced | Gate: check-required-patterns.sh. Owner: pattern-governance. Evidence: domain and waiver fixtures. | Pattern fit is reviewed. |
| Pattern lifecycle canonical ownership | Missing enforcement | Gate: documentation hygiene and required-pattern tests exist. Owner: pattern-governance. Evidence: registry, policy, README, and checker comparison. | gap:pattern-registry-canonical-drift — the policy still denies the YAML owner used by execution. |
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
| Hard-hook blocking semantics | Missing enforcement | Gate: hook classification and wrapper tests exist. Owner: hooks-governance. Evidence: `hook-criticality.tsv` and Claude Code hook semantics. | gap:hard-hook-fail-closed — missing enforcers and conversion failures can allow the protected action. |
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
| Full-readiness claim semantics | Missing enforcement | Gate: `--assert-full-ready` and fixtures exist on PR #254. Owner: ops-readiness. Evidence: canonical checker/test. | gap:full-readiness-claim-semantics — merge, post-merge, and final live pass remain. |
| Project 8 behavioral blindness | Missing enforcement | Gate: Project 8 PR #9 adds a product-only Markdown boundary. Owner: ops-readiness. Evidence: current target main and exact PR head. | gap:project8-experiment-blindness — target guidance still coaches and discloses the experiment until merge and fresh-session proof. |
| Git/branch policy | Enforced | Gate: pr-policy. Owner: merge-governance. Evidence: merge readiness artifact. | Live state is reviewed. |
| PR review / external review | Enforced | Gate: check-pr-review-evidence.sh through pr-policy. Owner: review-governance. Evidence: review fixtures. | Review depth is human. |
| Merge safety | Manual by design | Gate: owner decision. Owner: merge-governance. Evidence: Checklist: `docs/operations/merge-readiness-checklist.md`. | Human approval is intentional. |
| Post-merge validation | Enforced | Gate: post-merge-validation workflow. Owner: merge-governance. Evidence: repair-path fixtures. | Live failures use the incident checklist. |
| Known gaps register | Enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: schema and ledger fixtures. | Closure judgment is reviewed. |

## Dependency-ordered closure plan

Do not skip phases. Work may be parallelized inside a phase only when files and claims do not conflict.

### Phase 0 — make readiness truth trustworthy

1. `gap:audit-self-contained-contract`
2. `gap:audit-live-state-verification`
3. `gap:documentation-runtime-state-drift`
4. `gap:full-readiness-claim-semantics`

Exit: a new LLM can navigate the audit, stale live claims fail, canonical docs agree, and strict readiness mode exists on `main`.

### Phase 1 — close deterministic enforcement defects

1. `gap:hard-hook-fail-closed`
2. `gap:bypass-approval-provenance`
3. `gap:pattern-registry-canonical-drift`
4. `gap:pattern-evidence-maturity`
5. `gap:eos-repo-boundary-sync-drift`

Exit: protected actions fail safely, bypasses require durable approval, pattern ownership and evidence are honest, and installed boundary hooks match the canonical patcher.

### Phase 2 — remove target coaching

1. Re-verify Project 8 PR #9 exact head, checks, diff, and threads.
2. Obtain owner approval and merge it.
3. Run post-merge product-boundary checks.
4. Open a fresh session and prove removed guidance was not loaded.
5. Close `gap:project8-experiment-blindness`.

Exit: Project 8 is product-only and cannot reveal or prescribe the experiment through tracked guidance.

### Phase 3 — technical qualification, not behavioral experiment

1. Close `gap:dispatch-scope-double-record` and `gap:multirepo-remote-telemetry-validation` with a fresh Remote qualification session.
2. Close `gap:project-8-real-run-evidence` with an exact Project 8 non-product qualification bundle.
3. Close `gap:monitoring-metrics-sufficiency` after import, analysis, privacy, and usefulness review.
4. Run a second qualification session and close `gap:monitoring-longitudinal-sufficiency` through reproducible comparison.

Exit: telemetry installation, attribution, transport, archive, privacy, and repeatability are proven without performing the future Product 8 workload.

### Phase 4 — final readiness declaration

1. Verify every `known-gaps.tsv` row is `closed`.
2. Verify the matrix has no Missing enforcement or Partially enforced row.
3. Re-fetch live GitHub state and provider-neutral qualification evidence.
4. Run `bash scripts/enforcement/check-known-gaps.sh`.
5. Run `bash scripts/enforcement/check-readiness-audit.sh`.
6. Run `bash scripts/enforcement/check-readiness-audit.sh --assert-full-ready`.
7. Obtain explicit owner approval to begin the behavioral experiment.

Exit: only then may the future Project 8 prompt be prepared and supplied.

## Definition of full operational readiness

A full-readiness claim is permitted only when all of the following are true:

- every registered gap is exactly `closed`; `open`, `blocked`, `mitigated`, and `accepted-manual` all block the claim;
- every matrix row is `Enforced`, `Manual by design` with an existing checklist, `Waiver-gated` with valid scoped evidence, or `Not applicable`;
- every closure cites exact implementation, positive and negative validation, installed-target behavior where relevant, exact-head CI, review reconciliation, merge evidence, and post-merge validation;
- live external state is rechecked immediately before the claim;
- technical qualification evidence is not presented as behavioral-experiment evidence;
- `bash scripts/enforcement/check-readiness-audit.sh --assert-full-ready` succeeds on the canonical `main` files;
- Yotam explicitly approves the behavioral experiment start.

The current repository does **not** satisfy this definition.

## Mandatory end-to-end closure checklists

A gap may move to `closed` only when every checkbox in its section has an exact file, commit, PR, workflow run, artifact, provider identifier, or inspected test output. A PR-body statement without linked evidence is insufficient.

### gap:audit-self-contained-contract — P0

Official basis: Anthropic recommends specific, concise, structured, consistent project instructions and periodic removal of stale or conflicting rules: <https://code.claude.com/docs/en/memory>. AWS Operational Excellence emphasizes shared standards and knowledge: <https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/operational-excellence.html>.

- [ ] Audit metadata names owner, repositories, registry, verification time, readers, and snapshot limitations.
- [ ] Purpose, system architecture, repository boundary, non-negotiable decisions, glossary, source hierarchy, evidence standard, and LLM procedure are independently understandable.
- [ ] Qualification sessions and the behavioral experiment are unambiguously different.
- [ ] The Product 8 workload contract is separated from pre-start gaps.
- [ ] Dependency phases contain every non-closed gap exactly once or explicitly group coupled gaps.
- [ ] `check-readiness-audit.sh` requires the context-free sections and key concepts.
- [ ] Negative fixtures fail when context, terminology, evidence rules, or experiment blocking rules disappear.
- [ ] A context-free reviewer can answer: what the system is, what blocks the experiment, what to fix next, and what closes each gap.
- [ ] Exact-head CI and review pass; merge and post-merge validation preserve the contract.

### gap:audit-live-state-verification — P0

Official basis: GitHub status checks and branch protections apply to exact commits and branch rules: <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks> and <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches>.

- [ ] Extend the canonical known-gaps validation path; do not create a second registry.
- [ ] Bind every closure claim naming a PR, commit, merge, or workflow to repository and exact identifier.
- [ ] In CI, fetch PR state, merged time, merge commit, exact head SHA, and named check conclusions.
- [ ] Fail when registry and audit agree but contradict live GitHub state.
- [ ] Fail for self-only `pr-policy`, skipped-job, stale-head, or generic “all checks passed” evidence.
- [ ] Pass only when the referenced change is present on `main` and intended non-self checks succeeded.
- [ ] Add offline positive and negative fixtures, including the historical stale PR #253 case.
- [ ] Prove one real merged-PR reconciliation, exact-head review, merge, and post-merge validation.

### gap:documentation-runtime-state-drift — P1

Official basis: Anthropic states that conflicting project instructions reduce reliable adherence and should be reviewed periodically: <https://code.claude.com/docs/en/memory>.

- [ ] Change the CLAUDE capability row from `runtime planned` to the exact active Route Plan/write-gate scope in `core/capability-registry.yaml`.
- [ ] Replace the README hard-coded `14 policy files` claim with an accurate generated or non-stale inventory statement.
- [ ] Reconcile the `core/quality-gates.md` claim that CodeRabbit is not connected with `core/coderabbit-policy.md` and live review behavior.
- [ ] Search all canonical entrypoints and policies for equivalent stale claims.
- [ ] Add documentation-hygiene fixtures for each contradiction or a generic owner-versus-summary drift rule.
- [ ] Verify the owner file remains canonical and summaries link rather than redefine.
- [ ] Run documentation, entrypoint, capability, full enforcement, exact-head review, merge, and post-merge validation.

### gap:full-readiness-claim-semantics — P1

- [ ] Keep normal audit validation capable of passing an honestly incomplete audit.
- [ ] Make `--assert-full-ready` fail for every non-closed gap, including mitigated and accepted-manual.
- [ ] Make it fail for every Missing enforcement or Partially enforced matrix row.
- [ ] Add a negative fixture where registration is complete but one gap remains open.
- [ ] Add negative fixtures for mitigated and accepted-manual gaps.
- [ ] Add a positive fully-ready fixture.
- [ ] Wire the assertion to the final experiment-start procedure.
- [ ] Merge, run post-merge validation, and execute the assertion on live canonical files before closing.

### gap:hard-hook-fail-closed — P0

Official basis: Claude Code documents that `PreToolUse` blocks with `exit 2` or a valid deny decision: <https://code.claude.com/docs/en/hooks>.

- [ ] Make a missing hard enforcer block instead of returning success.
- [ ] Make deny-conversion, interpreter, and runtime failure block with `exit 2` and a concrete reason.
- [ ] Preserve fail-open behavior only for explicitly advisory, recorder, or soft lifecycle units.
- [ ] Verify every hard PreToolUse path runs the JSON guard first and is not soft-wrapped.
- [ ] Add missing-enforcer, converter-failure, malformed-input, policy-violation, and normal-success fixtures.
- [ ] Exercise the installed target-project copy, not only the source wrapper.
- [ ] Run hook-classification, clean-install, full enforcement, exact-head review, merge, and post-merge validation.

### gap:bypass-approval-provenance — P1

- [ ] Define one canonical waiver record: bypass name, stable approval reference, reason, bounded target/action scope, issuer, creation time, and expiry or one-shot semantics.
- [ ] Reject truthy `EOS_BYPASS_*` without a complete matching record.
- [ ] Reject blank/generic reason, wrong bypass, wrong target, stale scope, forged record, and master-bypass substitution.
- [ ] Record accepted metadata in the evidence ledger without secrets or conversation content.
- [ ] Surface every accepted bypass in Stop and PR evidence and prevent normal completion until reconciled.
- [ ] Add positive and negative fixtures and exercise installed-target behavior.
- [ ] Run workflow, evidence, install, full suites, exact-head review, merge, and post-merge validation.

### gap:pattern-registry-canonical-drift — P1

- [ ] Declare `patterns/registry.yaml` canonical for identity, domain, lifecycle status, score, version, usage count, and evidence.
- [ ] Declare domain README files canonical for implementation, examples, security, and testing guidance.
- [ ] Remove the statement that there is no YAML registry.
- [ ] Align connector policy, patterns README, scoring guide, and required-pattern checker.
- [ ] Add a documentation-hygiene negative fixture for the contradiction.
- [ ] Verify every registry path exists and every domain is non-empty.
- [ ] Run all pattern, documentation, full enforcement, exact-head review, merge, and post-merge validation.

### gap:pattern-evidence-maturity — P2

Official basis: AWS Operational Excellence requires feedback loops, validated insights, metrics reviews, and shared lessons rather than inventory-only confidence: <https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/learn-share-and-improve.html>.

- [ ] Produce an exact registry report of status, `used_in`, score, and evidence for every pattern.
- [ ] Identify the minimum patterns required by the remaining readiness and qualification work.
- [ ] For each selected pattern, link real project use, exact commit/PR, tests, outcome, incidents or absence of incidents, and adaptation cost.
- [ ] Update `used_in`, evidence, version, and score only from verified results.
- [ ] Apply the canonical scoring guide without inventing values.
- [ ] Promote to active only after the documented multi-context threshold is satisfied.
- [ ] Record failures and lower/deprecate patterns when evidence requires it.
- [ ] Add fixtures that reject score/status claims without matching evidence.
- [ ] No bulk promotion is allowed; review each transition and run exact-head/post-merge validation.

### gap:eos-repo-boundary-sync-drift — P3

- [ ] Patch Engineering OS `.claude/settings.json` through the canonical direct-mode patcher.
- [ ] Verify catch-all PreToolUse guard/recorder, SessionStart, Stop, StopFailure, and SessionEnd commands exactly.
- [ ] Ensure terminal events record and synchronize boundaries, not only events.
- [ ] Pass patcher verify, trust-boundary, archive, hook-classification, and full suites.
- [ ] Keep this change separate from Project 8 workload implementation.
- [ ] Complete exact-head review, merge, and post-merge validation before qualification sessions.

### gap:project8-experiment-blindness — P0

Official basis: Claude Code loads project `CLAUDE.md` instructions into session context and provides `InstructionsLoaded` diagnostics: <https://code.claude.com/docs/en/memory>.

- [ ] Re-fetch Project 8 PR #9 and verify the expected head before acting.
- [ ] Verify changed paths are limited to reviewed product-boundary/runtime scope and contain no product behavior change.
- [ ] Verify required product/policy checks on the exact head.
- [ ] Explicitly classify the legacy Azure deploy failure; never treat it as Vercel success.
- [ ] Verify every current and outdated review thread is resolved and every valid finding has a regression.
- [ ] Obtain explicit owner approval and merge with expected head SHA.
- [ ] Verify `project-8/main` contains no tracked Markdown prompt, audit, plan, README, or local Engineering OS coaching file.
- [ ] Verify the product-boundary checker blocks reintroduction.
- [ ] Verify machine-readable settings and policy contain no experiment description or task-routing instructions.
- [ ] Close prior sessions, open a genuinely fresh session, and prove through `InstructionsLoaded` metadata or equivalent that removed guidance was not loaded.
- [ ] Do not supply the future workload prompt during this validation.

### gap:dispatch-scope-double-record and gap:multirepo-remote-telemetry-validation — P1

- [ ] Start a fresh Remote technical qualification session only after exact dispatcher installation verification.
- [ ] Prove managed repositories initialize and unmanaged siblings create no telemetry state.
- [ ] Prove explicit filesystem and repository identities agree; malformed or conflicting identities remain unattributed.
- [ ] Prove unrelated activity is neither attributed nor blocked.
- [ ] Prove distinct run IDs and shared host correlation only.
- [ ] Revoke a marker mid-session and prove attribution and fan-out stop.
- [ ] Complete lifecycle boundaries and surface required handoff failures without suppressing sibling recording.
- [ ] Produce exact-match non-empty bundles and prove PR selection cannot cross repositories.
- [ ] Review diagnostics against the metadata-only contract.
- [ ] Record that no Product 8 feature was changed and no behavioral prompt was supplied.

### gap:project-8-real-run-evidence — P1

Official basis: `SessionStart` initializes session state, while GitHub workflow artifacts are transport evidence rather than the longitudinal archive: <https://code.claude.com/docs/en/hooks> and <https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts>.

- [ ] Update the actual `ENGINEERING_OS_HOME` checkout to the exact merged Engineering OS `main` head.
- [ ] Install user-level telemetry hooks from that checkout and pass installer `--verify`.
- [ ] Verify Project 8 telemetry policy is schema-valid and targets the intended handoff branch.
- [ ] Close every prior session and open a new one after installation.
- [ ] Before any task, run `require-telemetry-session.sh` and require positive session, remote handoff, and boundary counts.
- [ ] Run one bounded non-product task that exercises real tools without `--empty-run`, feature implementation, or the future workload prompt.
- [ ] Match run ID, repository, branch, head, policy, and handoff state.
- [ ] Match the non-empty telemetry-branch bundle to the exact qualification PR/head.
- [ ] Require selection of only `manifest.json`, `events.jsonl`, and `latest-summary.md`.
- [ ] Prove positive counts in session artifact and OWH.
- [ ] Prove metadata-only privacy: no prompt, response, command, payload, environment value, API key, secret, or unnecessary raw path.
- [ ] Import, analyze, and preserve findings while labeling them qualification evidence, not experiment results.

### gap:monitoring-metrics-sufficiency — P2

Official basis: Google SRE says monitoring should enable rational decisions about changes, and OpenTelemetry requires emitted signals rather than configuration alone: <https://sre.google/sre-book/monitoring-distributed-systems/> and <https://opentelemetry.io/docs/concepts/instrumentation/>.

- [ ] Complete the first Project 8 qualification checklist.
- [ ] Import one non-empty checksum-valid identity-matched bundle.
- [ ] Run and preserve analyzer output.
- [ ] Separate Engineering OS runtime behavior, OWH, qualification task outcome, and future product outcomes.
- [ ] Record event coverage, missing events, tools/connectors, failures, friction, false positives, attribution, and decision usefulness.
- [ ] Pass privacy and duplicate-run checks.
- [ ] Demonstrate at least one concrete readiness question the data can answer and one limitation it cannot answer.
- [ ] Close only after independent review confirms the bundle is decision-useful.

### gap:monitoring-longitudinal-sufficiency — P2

- [ ] Run at least one later technical qualification session using the same schema, privacy, and identity contracts.
- [ ] Import at least two valid qualification runs.
- [ ] Compare event coverage, attribution, tools/connectors, failures, retries, duplicates, privacy, archive behavior, and analyzer output.
- [ ] Separate recurring blind spots from one-off failures.
- [ ] Record whether Engineering OS changes improved, worsened, or did not change qualification behavior.
- [ ] Create follow-up enforcement for recurring technical blind spots or document why a condition is manual by design.
- [ ] Prove the comparison is reproducible from archived bundles.
- [ ] Do not claim conclusions about the future Product 8 workload from qualification sessions.

## Highest-priority gaps by ROI

1. Audit self-contained contract and live-state verification — P0.
2. Hard-hook fail-closed — P0.
3. Project 8 experiment blindness — P0.
4. Documentation/runtime consistency and full-readiness assertion — P1.
5. Bypass approval provenance and canonical pattern ownership — P1.
6. Engineering OS boundary synchronization and fresh Remote qualification — P1/P3.
7. Project 8 qualification bundle and first-run monitoring sufficiency — P1/P2.
8. Pattern evidence maturity and second-run repeatability — P2.

Closed regression surfaces retained by the readiness gate: coverage map hardening; RTK runtime hardening; route plan quality gate; learning closure gate; progress lifecycle; connector correctness; simulation completeness; post-merge validation; documentation hygiene; semantic cleanup.

## Experiment start decision

The Project 8 behavioral experiment is **blocked**.

It may begin only when:

1. every registered gap in `docs/operations/known-gaps.tsv` is exactly `closed`;
2. no matrix row remains Missing enforcement or Partially enforced;
3. every required technical qualification session is complete and clearly separated from experiment evidence;
4. live GitHub state is re-fetched and consistent with the audit;
5. `bash scripts/enforcement/check-readiness-audit.sh --assert-full-ready` passes on canonical `main`;
6. Yotam gives explicit owner approval to prepare and send the behavioral experiment prompt.

No prompt is required or authorized at the current stage. Do not draft, store, or send one as part of readiness-gap work.

## Future Project 8 workload acceptance contract

This contract is preserved now so the eventual experiment objective is not lost. It is not a registered pre-start gap and must not be given to the target model until the experiment is approved.

Official implementation basis:

- Vercel environments and variables: <https://vercel.com/docs/deployments/environments> and <https://vercel.com/docs/environment-variables>.
- Vercel Vite, Express, monorepos, and domains: <https://vercel.com/docs/frameworks/frontend/vite>, <https://vercel.com/docs/frameworks/backend/express>, <https://vercel.com/docs/monorepos>, and <https://vercel.com/docs/domains/set-up-custom-domain>.
- Supabase RLS, API keys, secure data, and Postgres connections: <https://supabase.com/docs/guides/database/postgres/row-level-security>, <https://supabase.com/docs/guides/getting-started/api-keys>, <https://supabase.com/docs/guides/database/secure-data>, and <https://supabase.com/docs/guides/database/connecting-to-postgres>.
- Prisma with Supabase: <https://www.prisma.io/docs/orm/v6/overview/databases/supabase>.
- Playwright: <https://playwright.dev/docs/intro>.
- W3C accessible forms: <https://www.w3.org/WAI/tutorials/forms/>.

### Existing assets and secrets

- Inventory existing Vercel project/team IDs, settings, environments, deployments, aliases, domains, and repository link.
- Inventory existing Supabase project reference, schemas, migrations, auth/storage use, URL/key presence, and pooled/direct connection types.
- Inventory GitHub Actions secret and variable names, environments, provider workflows, domains, and application API-key names.
- Record only safe names, presence, scope, intended use, and validation outcome.
- Reuse valid URLs, domains, API keys, provider resources, and integrations; create, rotate, or remove only with reason and rollback.
- Prove no secret enters source, Markdown, logs, artifacts, screenshots, browser bundles, or client-exposed variables.

### Supabase / PostgreSQL outcome

- Re-run and preserve the isolated Postgres foundation tests before cutover.
- Map every remaining SQL Server or T-SQL assumption to an exact file and test.
- Remove active-path SQL Server-specific types, builders, namespaces, and defaults unless isolated solely for rollback.
- Use one final Prisma/Supabase runtime boundary, pooled runtime connection, and direct migration/introspection connection.
- Apply versioned migrations to the intended Supabase project and verify live migration history.
- Enable and force RLS where required on every exposed tenant table.
- Prove least-privilege and cross-tenant read/write isolation under non-elevated identities.
- Keep service-role or secret credentials server-only and prove publishable credentials cannot bypass RLS.
- Validate every existing server route and background behavior against Supabase/PostgreSQL.

### Vercel outcome

- Reuse the valid existing Vercel project instead of creating a duplicate.
- Record the supported Vite/Express/monorepo shape, roots, build, output, routing, and function boundaries.
- Map required variables to Development, Preview, and Production by name and scope without values.
- Deploy the exact PR head to a commit-specific Preview URL and redeploy after variable changes.
- Run API, database, and browser E2E against that URL.
- Reuse and verify the existing production domain; inspect DNS before modifications.
- Prove build, functions, assets, API routes, cookies, CORS, auth redirects, and database connectivity through live evidence.
- Do not deploy production or change DNS without explicit owner approval.

### Feature, UI/UX, encoding, and end-to-end outcome

- Build a feature inventory from actual server routes, client routes, navigation, tests, and integrations.
- Give every existing feature one status: passing, failing and repaired, externally blocked with evidence, or intentionally removed with approval.
- Add or repair API and integration tests for provider and database paths.
- Add or repair browser flows for every existing feature, including authentication, business setup, public booking, appointments, settings, dashboards/statistics, customers, waitlist, cancellation/rescheduling, notifications/integrations, legal/cookies, and error states when present.
- Run critical flows in Chromium, WebKit, Firefox, and a mobile viewport where practical.
- Validate Hebrew UTF-8, RTL, translations, date/time/timezone, responsiveness, keyboard/focus, labels, validation, loading/empty/error states, and clipping/overlap.
- Capture screenshots or traces for major public and owner flows on the exact Preview deployment.
- Fix all revealed runtime, API, data, UI/UX, and encoding defects without weakening valid tests.
- Re-run server, client, database, build, UTF-8, E2E, security, cleanup, and policy suites after the final fix.
- Record exact-head CI, Preview/production URLs, safe provider identifiers, migration/RLS evidence, test counts, screenshots/traces, residual risk, and rollback.
- Require explicit approval before merge or production deployment and run post-merge plus production smoke validation.

## Current audit scope

Engineering OS PR #254 now expands the audit, registry, checker, and readiness fixtures. It does not implement the remaining runtime, documentation, pattern, Project 8 boundary, or qualification gaps. The current system is audit-complete only after this PR passes and merges; it is not fully operationally ready.

The future behavioral experiment remains prohibited until every registered gap closes through the dependency plan and the strict assertion passes on live canonical state. The future Product 8 workload acceptance contract is retained solely to preserve the experiment objective and must not be mistaken for present readiness or supplied as coaching.
