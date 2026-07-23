# Engineering OS Operational Readiness Audit

This document is the canonical status map and closure contract for Engineering OS operational readiness. A capable LLM or human reviewer can begin here without prior chat context, understand the system and target repositories, identify the next unresolved gap, and know exactly what evidence is required before a readiness or experiment claim.

## Audit metadata

- **Audit owner:** Yotam Friedman; operational owner group `ops-readiness`
- **Canonical repository:** `yotamfried-ux/Engineering-OS`
- **Target repository:** `yotamfried-ux/project-8`
- **Canonical gap registry:** `docs/operations/known-gaps.tsv`
- **Last verified:** 2026-07-23 America/Panama / 2026-07-23 UTC
- **Intended readers:** LLMs, maintainers, reviewers, and operators with no prior conversation context
- **Snapshot only:** Engineering OS `main` was inspected at `efb36cca413602cde3cd20aa17d32b3379f9eb53`; Project 8 `main` at `f282f5e9889d956e54fc0803938915fd86a58158`; Project 8 PR #9 at `51970629f3c3af32cb73bea0aab676874478248d`. Mutable state must always be re-fetched before a decision.

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
8. Keep one canonical audit, gap registry, pattern registry, readiness definition, required-hook inventory, and telemetry bundle validator.

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

Closure identifies, as applicable: exact repository and path; branch and commit SHA; expected PR head and merge commit; implementation owner; focused positive and negative tests; installed target behavior; named non-self CI on the exact head; latest workflow attempt ordering; review reconciliation; live provider/runtime evidence; merge and post-merge validation; metadata-only secret-safe artifacts; residual risk and rollback.

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
- **Exact-head** — evidence filtered to the current expected PR head SHA.
- **Latest attempt** — the newest run for one workflow on the exact head, selected deterministically by timestamps, run attempt, and run ID.
- **Canonical owner** — the single repository file or registry authorized to define a concept.
- **Audit complete** — the system and every unresolved condition are documented; this does not imply readiness.
- **Implementation complete** — the required code and deterministic tests exist; live evidence may still be missing.
- **Experiment ready** — all pre-start gaps are closed and the strict assertion plus owner approval permit preparation of the prompt.
- **Monitoring metrics sufficient** — one valid run has been imported and shown useful for analysis of that run.
- **Monitoring longitudinally sufficient** — at least two valid runs have been compared reproducibly.
- **Live-state claim** — versioned metadata binding a closed gap to exact repository, PR, reviewed head, merge commit, base branch, workflows, and checks.
- **Full operational readiness** — every gap closed, no Missing/Partially enforced matrix row, fresh live state, strict assertion success, and owner approval.
- **Future workload acceptance contract** — Project 8 outcomes evaluated during the experiment, not a pre-start gap.

## Gap lifecycle and priority

Allowed status: `open`, `blocked`, `mitigated`, `accepted-manual`, `closed`. Only `closed` is experiment-compatible. P0 invalidates safety, audit truth, enforcement trust, merge evidence, or experiment validity; P1 blocks reliable operation or full readiness; P2 blocks evidence quality or reproducible learning; P3 is lower immediate risk but still blocks the experiment under the owner's decision.

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
- **Implementation complete** means code and deterministic tests satisfy the implementation contract but does not close a gap that requires installed, live, merge, post-merge, or real-run evidence.
- **Experiment ready** means every pre-start gap is `closed`, live state is fresh, `--assert-full-ready` passes, and explicit owner approval is recorded.
- **Monitoring metrics sufficient** means one integrity-valid identity-matched run was imported, analyzed, reviewed, and shown to answer a concrete observability question.
- **Monitoring longitudinally sufficient** means at least two valid runs were compared reproducibly and recurring findings were dispositioned.
- **Fully operationally ready** means every gap is `closed`, no row remains Missing or Partially enforced, live state has been rechecked, the strict assertion succeeds, and owner approval is recorded.

Analyzers produce evidence and findings; they do not assign canonical closure status. A complete audit may honestly describe an unready system. Registering a risk is not solving it.

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
| monitoring-metrics-sufficiency | open | P1 | First-run monitoring usefulness. |
| monitoring-longitudinal-sufficiency | open | P2 | Multi-run reproducibility and comparison. |
| project-8-real-run-evidence | open | P1 | Project 8 qualification transport and identity. |
| operational-work-history-foundation | closed | P1 | Operational work history foundation. |
| dispatch-scope-double-record | mitigated | P1 | Dispatch scope double record. |
| multirepo-remote-telemetry-validation | open | P1 | Multirepo remote telemetry validation. |
| eos-repo-boundary-sync-drift | open | P1 | Required-hook parity across settings surfaces. |
| audit-live-state-verification | closed | P0 | Audit live state verification. |
| hard-hook-fail-closed | open | P0 | Hard hook infrastructure failure semantics. |
| bypass-approval-provenance | open | P1 | Bypass authorization and consumption provenance. |
| pattern-registry-canonical-drift | open | P1 | Pattern lifecycle canonical ownership. |
| pattern-evidence-maturity | open | P2 | Real multi-context pattern outcomes. |
| documentation-runtime-state-drift | open | P1 | Active documentation and executable-owner consistency. |
| audit-self-contained-contract | closed | P0 | Audit self contained contract. |
| full-readiness-claim-semantics | open | P1 | Canonical state vocabulary and final assertion. |
| project8-experiment-blindness | open | P0 | Project8 experiment blindness. |
| telemetry-archive-import-integrity | open | P1 | Import-time bundle integrity and identity. |
| merge-readiness-exact-head-and-attempt-ordering | closed | P0 | Exact-head latest-attempt merge evidence. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests. Owner: core-governance. Evidence: entrypoint and orphan fixtures. | Semantic quality is reviewed. |
| Canonical ownership / no policy sprawl | Enforced | Gate: check-documentation-hygiene.sh. Owner: docs-governance. Evidence: hygiene fixtures. | Deep semantics are reviewed. |
| Enforcement coverage inventory | Enforced | Gate: check-readiness-audit.sh. Owner: ops-readiness. Evidence: readiness fixtures. | Closure judgment is reviewed. |
| Audit self-contained contract | Enforced | Gate: check-readiness-audit.sh and context-free fixtures. Owner: ops-readiness. Evidence: merged PR #254, exact head `f74a26d65f6cebf06f29df1d803c192c3efb9694`, merge `c7d32a0b67a836811689d3a2bf80a63d727e1470`, and `docs/operations/live-state-claims.json`. | Closed; the live claim must continue to pass. |
| Audit registry freshness | Enforced | Gate: check-known-gaps.sh, deterministic snapshot validation, and `known-gaps-live-state`. Owner: ops-readiness. Evidence: PR #254 and PR #255 versioned claims; PR #255 head `97d56e2f5743b019145da600cf0914f6d092cd0f`, merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`. | Closed; both live claims must continue to pass. |
| Documentation runtime state and readiness consistency | Partially enforced | Gate: extended `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: capability, inventory, reviewer, manifest, telemetry-plan/analyzer, and terminology comparison. | gap:documentation-runtime-state-drift — PR #256 covered wording/inventory/reviewer reconciliation; this branch (`claude/operational-readiness-eos-c6ykfs`) closes the remaining MANIFEST.tsv and telemetry-terminology checklist items with bidirectional fixtures; exact-head CI, review, owner-approved merge, and post-merge validation remain before closure. |
| Route Plan before writing | Enforced | Gate: workflow write guards and target-aware plan selection. Owner: workflow-governance. Evidence: active-plan fixtures. | Plan intent is reviewed. |
| Route Plan quality | Enforced | Gate: check-workflow-evidence.sh. Owner: workflow-governance. Evidence: semantic-quality fixtures. | Deep source quality is reviewed. |
| DoD completion | Enforced | Gate: plan-policy and check-workflow-evidence.sh. Owner: delivery-governance. Evidence: completion fixtures. | Meaning of completion is reviewed. |
| Progress validation | Enforced | Gate: check-workflow-evidence.sh. Owner: progress-governance. Evidence: ordered lifecycle fixtures. | Evidence truthfulness is reviewed. |
| Connector selection | Enforced | Gate: check-required-connectors.sh. Owner: connector-governance. Evidence: manifest coverage fixtures. | Best connector choice is reviewed. |
| Connector correctness / source-of-truth use | Enforced | Gate: check-connector-evidence.sh. Owner: connector-governance. Evidence: target and identifier fixtures. | Deep result interpretation is reviewed. |
| Template selection | Enforced | Gate: check-required-templates.py. Owner: template-governance. Evidence: coverage and precision fixtures. | Template fit is reviewed. |
| Pattern usage | Enforced | Gate: check-required-patterns.sh. Owner: pattern-governance. Evidence: domain and waiver fixtures. | Pattern fit is reviewed. |
| Pattern lifecycle canonical ownership | Missing enforcement | Gate: documentation hygiene and required-pattern tests. Owner: pattern-governance. Evidence: registry, domain README, ratings TSV, policy, and checker comparison. | gap:pattern-registry-canonical-drift — lifecycle state can disagree across independent owners. |
| Pattern evidence maturity | Missing enforcement | Gate: rating schema exists. Owner: pattern-governance. Evidence: `patterns/registry.yaml`, scoring guide, and real-use records. | gap:pattern-evidence-maturity — no pattern has verified two-context evidence supporting active status. |
| Template/pattern rating lifecycle | Enforced | Gate: check-template-pattern-ratings.sh. Owner: reuse-governance. Evidence: exact-asset feedback fixtures. | Canonical state drift is tracked separately. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: check-documentation-asset-evidence.sh. Owner: asset-governance. Evidence: documentation selection fixtures. | Best source is reviewed. |
| Skill selection | Enforced | Gate: check-required-skills.sh. Owner: skill-governance. Evidence: inventory coverage fixtures. | Skill fit is reviewed. |
| Skill runtime evidence | Enforced | Gate: pre-tool-use-runtime-evidence.sh. Owner: skill-governance. Evidence: runtime fixtures. | Required nested dependency behavior is tracked by hard-hook fail-closed. |
| RTK context optimization | Enforced | Gate: required-skill and session setup checks. Owner: context-governance. Evidence: RTK hardening fixtures. | External effect is reviewed. |
| Graphify context graph | Enforced | Gate: check-plan-scope.sh. Owner: context-governance. Evidence: target-linked graph fixtures. | Graph accuracy is reviewed. |
| Claude memory / context carryover | Manual by design | Gate: manual review. Owner: context-governance. Evidence: Checklist: `docs/operations/memory-context-checklist.md`. | Runtime intent cannot be proven deterministically. |
| Capability registry | Enforced | Gate: capability-evidence-policy and write-gate validation. Owner: capability-governance. Evidence: `runtime_enabled: true` and staged-path fixtures. | MANIFEST and active-document consistency are tracked separately. |
| Learning schema | Enforced | Gate: enforce-learning.sh. Owner: learning-governance. Evidence: schema fixtures. | Content quality is covered separately. |
| Learning reuse | Enforced | Gate: Route Plan lesson-reuse evidence. Owner: learning-governance. Evidence: citation fixtures. | Relevance is reviewed. |
| Learning closure after bug/debug work | Enforced | Gate: enforce-learning-capture.sh. Owner: learning-governance. Evidence: closure fixtures. | Truthfulness is reviewed. |
| Claude run trace / experiment log | Enforced | Gate: enforce-run-trace.sh. Owner: trace-governance. Evidence: significant-scope fixtures. | Trace depth is reviewed. |
| Operational behavior evidence | Enforced | Gate: check-operational-behavior-evidence.sh through pr-policy. Owner: ops-readiness. Evidence: PR-body fixtures. | Evidence truthfulness is reviewed. |
| Positive/negative simulations | Enforced | Gate: check-simulation-coverage.sh. Owner: validation-governance. Evidence: completeness and waiver fixtures. | Scenario quality is reviewed. |
| Tests/lint before commit | Enforced | Gate: enforce-tests.sh. Owner: validation-governance. Evidence: tool-contract fixtures. | Tool selection is reviewed. |
| Cleanup debug leftovers | Enforced | Gate: enforce-quality.sh. Owner: cleanup-governance. Evidence: cleanup fixtures. | Missing required nested enforcement is tracked by hard-hook fail-closed. |
| Cleanup semantic hygiene | Enforced | Gate: semantic-cleanup-policy and import-cleanup-policy. Owner: cleanup-governance. Evidence: cleanup fixtures. | Deep semantics are reviewed. |
| Project install contract | Enforced | Gate: install-policy-gates and generated-target tests. Owner: install-governance. Evidence: downstream behavior fixtures. | Cross-boundary hook parity remains open. |
| Required-hook settings parity | Missing enforcement | Gate: installer patchers and verify modes. Owner: install-governance. Evidence: checked-in, direct-mode, user-dispatcher, and generated-target settings. | gap:eos-repo-boundary-sync-drift — required hooks can differ across four runtime surfaces. |
| Hard-hook blocking semantics | Missing enforcement | Gate: hook classification and wrapper tests. Owner: hooks-governance. Evidence: `hook-criticality.tsv`, wrappers, nested validators, and Claude Code hook semantics. | gap:hard-hook-fail-closed — infrastructure uncertainty can still allow a protected action. |
| Enforcement bypass provenance | Missing enforcement | Gate: evidence ledger records bypass names. Owner: hooks-governance. Evidence: `bypass_active()`. | gap:bypass-approval-provenance — env-only requests are not durable human authorization. |
| Result Loop Contract enforcement | Enforced | Gate: named result-loop CI plus Operational Work History. Owner: ops-readiness. Evidence: fixtures and real positive/negative PRs. | Contract semantics are reviewed. |
| Operational work history evidence | Enforced | Gate: check-operational-work-history-evidence.sh through pr-policy. Owner: ops-readiness. Evidence: fixtures and real PRs. | Human interpretation remains reviewed. |
| Scaling extension enforcement | Enforced | Gate: named scaling CI step. Owner: ops-readiness. Evidence: scaling fixtures and merged evidence. | Deep roadmap quality is reviewed. |
| Registry/manifest coverage | Enforced | Gate: scaling coverage checks. Owner: registry-governance. Evidence: active rows across required manifests. | Documentation/runtime MANIFEST truth is tracked separately. |
| Canonical telemetry trust boundaries | Enforced | Gate: telemetry-handoff-tests. Owner: ops-readiness. Evidence: merged PR #253 and exact-head regressions. | gap:telemetry-archive-import-integrity — direct archive import does not yet prove the same integrity contract. |
| Telemetry archive import integrity | Missing enforcement | Gate: importer schema/privacy checks plus separate handoff validator. Owner: ops-readiness. Evidence: exporter checksums, `telemetry_handoff.validate_bundle()`, and importer behavior. | gap:telemetry-archive-import-integrity — import must invoke shared fail-closed checksum and identity validation before archive mutation. |
| Monitoring metrics first-run sufficiency | Missing enforcement | Gate: exporter, importer, analyzer, identity, and privacy tests exist. Owner: ops-readiness. Evidence: archive tests and runbooks. | gap:monitoring-metrics-sufficiency — one valid qualification bundle must be shown useful; import integrity is a prerequisite. |
| Monitoring longitudinal sufficiency | Missing enforcement | Gate: archive analyzer can compare runs. Owner: ops-readiness. Evidence: analyzer and archive plan. | gap:monitoring-longitudinal-sufficiency — at least two qualification runs must prove repeatability. |
| Project 8 technical qualification evidence | Missing enforcement | Gate: mandatory telemetry preflight exists. Owner: ops-readiness. Evidence: Project 8 preflight and findings runbook. | gap:project-8-real-run-evidence — fresh transport, identity, counts, and boundary evidence are missing. |
| Remote multi-repository telemetry dispatch | Partially enforced | Gate: dispatcher fixtures cover attribution, isolation, policy, failures, and PR matching. Owner: ops-readiness. Evidence: deterministic tests plus failed live attempt. | gap:dispatch-scope-double-record and gap:multirepo-remote-telemetry-validation — a fresh successful qualification session is required. |
| Full-readiness claim semantics | Partially enforced | Gate: merged `--assert-full-ready` and positive/negative fixtures. Owner: ops-readiness. Evidence: canonical checker/test on `main`. | gap:full-readiness-claim-semantics — canonical state vocabulary and terminal live proof remain required. |
| Project 8 behavioral blindness | Missing enforcement | Gate: Project 8 PR #9 adds a product-only Markdown boundary. Owner: ops-readiness. Evidence: current target main and exact PR head. | gap:project8-experiment-blindness — target guidance still coaches and discloses the experiment until merge and fresh-session proof. |
| Git/branch policy | Enforced | Gate: pr-policy. Owner: merge-governance. Evidence: merge readiness artifact. | Machine verification of run recency is tracked separately. |
| PR review / external review | Enforced | Gate: check-pr-review-evidence.sh through pr-policy. Owner: review-governance. Evidence: review fixtures. | Review depth is human. |
| Merge safety exact-head and latest-attempt evidence | Enforced | Gate: `check-merge-readiness.sh` plus exact-head merge procedure. Owner: merge-governance. Evidence: PR #257 reviewed head `fedf8d069a8634085c650ea6381c1c0dabfdc368`, enforcement run 1384, latest `pr-policy` run 1679, owner approval comment `5060947961`, expected-head protected merge `efb36cca413602cde3cd20aa17d32b3379f9eb53`, and `docs/operations/live-state-claims.json`. | Closed; the live claim must continue to verify pull-request and post-merge push workflows. |
| Merge approval | Manual by design | Gate: owner decision. Owner: merge-governance. Evidence: Checklist: `docs/operations/merge-readiness-checklist.md`. | Human approval remains intentional after machine evidence is trustworthy. |
| Post-merge validation | Enforced | Gate: post-merge-validation workflow. Owner: merge-governance. Evidence: repair-path fixtures. | Live failures use the incident checklist. |
| Known gaps register | Enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: schema, ledger, and optional live-snapshot validation. | Closure judgment is reviewed. |

## Dependency-ordered closure plan

Do not skip phases. Parallel work is permitted inside a phase only when files and claims do not conflict.

### Completed foundation

- `gap:audit-self-contained-contract` closed through merged PR #254, exact reviewed head `f74a26d65f6cebf06f29df1d803c192c3efb9694`, merge `c7d32a0b67a836811689d3a2bf80a63d727e1470`, context-free fixtures, and the canonical live-state claim.
- `gap:audit-live-state-verification` closed through merged PR #255, exact reviewed head `97d56e2f5743b019145da600cf0914f6d092cd0f`, merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`, chronological rerun fixtures, metadata-only live artifacts, and the canonical live-state claim.
- `gap:merge-readiness-exact-head-and-attempt-ordering` closed through PR #257, exact reviewed head `fedf8d069a8634085c650ea6381c1c0dabfdc368`, deterministic latest-attempt fixtures, enforcement run 1384, latest `pr-policy` run 1679, two resolved review threads, owner approval comment `5060947961`, expected-head protected merge `efb36cca413602cde3cd20aa17d32b3379f9eb53`, and the canonical live-state claim.

### Phase 0 — make future merge and readiness evidence trustworthy

1. `gap:documentation-runtime-state-drift`

Exit: merge decisions use exact-head latest-attempt evidence and active canonical descriptions agree with executable owners.

### Phase 1 — close deterministic enforcement and integrity defects

1. `gap:hard-hook-fail-closed`
2. `gap:bypass-approval-provenance`
3. `gap:eos-repo-boundary-sync-drift`
4. `gap:pattern-registry-canonical-drift`
5. `gap:telemetry-archive-import-integrity`

Exit: protected actions fail safely, bypasses require durable approval, required hooks are wired consistently, pattern state has one owner, and archive import validates integrity before mutation.

### Phase 2 — remove target coaching

1. Re-verify Project 8 PR #9 exact head, diff, required checks, latest attempts, and all threads.
2. Obtain owner approval and merge with expected-head protection.
3. Run post-merge product-boundary checks.
4. Open a fresh session and prove removed guidance was not loaded.
5. Prove one natural routed action without supplying the future workload prompt.
6. Close `gap:project8-experiment-blindness`.

### Phase 3 — technical qualification, not behavioral experiment

1. Close `gap:dispatch-scope-double-record` and `gap:multirepo-remote-telemetry-validation` with fresh Remote qualification.
2. Close `gap:project-8-real-run-evidence` with an exact Project 8 non-product bundle.
3. Close `gap:monitoring-metrics-sufficiency` after integrity validation, import, analysis, privacy, and usefulness review.
4. Capture real pattern outcomes from readiness work and close `gap:pattern-evidence-maturity` only when thresholds are genuinely met.
5. Run a later qualification and close `gap:monitoring-longitudinal-sufficiency` through reproducible comparison.

### Phase 4 — final readiness declaration

1. Reconcile canonical readiness vocabulary and remaining outputs for `gap:full-readiness-claim-semantics`.
2. Verify every registry row is `closed` and no matrix row is Missing or Partially enforced.
3. Re-fetch live GitHub state and provider-neutral qualification evidence.
4. Run the live-state workflow and `check-known-gaps.sh`.
5. Run normal readiness validation and `--assert-full-ready` on canonical `main`.
6. Obtain explicit owner approval to prepare and send the behavioral experiment prompt.

## Definition of full operational readiness

A full-readiness claim requires every gap exactly `closed`; only terminal acceptable matrix statuses; exact implementation/test/install/CI/review/merge/post-merge evidence; latest-attempt evidence filtered to the expected head; immediate live external reconciliation; no qualification evidence mislabeled as experiment evidence; strict assertion success on canonical `main`; and explicit Yotam approval. The current repository does **not** satisfy this definition.

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

### gap:audit-live-state-verification — P0 — closed

Official basis: GitHub REST pull requests, check runs, workflow runs, compare commits, Actions security hardening, plus official `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description` repositories.

- [x] Extend the canonical known-gaps path rather than create a second registry.
- [x] Define versioned claims binding gap, repository, PR, base, head, merge, named PR workflows, push workflows, and checks.
- [x] Implement a fail-closed REST fetcher that paginates documented endpoints and emits metadata only.
- [x] Implement one deterministic validator shared by offline fixtures and live CI snapshots.
- [x] Reject unmerged, stale-head, stale-merge, diverged-base, older-green/newer-failure, skipped, neutral, missing-workflow, malformed, open-gap, and self-only evidence fixtures.
- [x] Register PR #254 as the first real reconciliation target.
- [x] PR #255 exact head `97d56e2f5743b019145da600cf0914f6d092cd0f` passed `known-gaps-live-state` run 9; artifact `8518895489` was inspected as metadata-only, and all four valid review threads were resolved.
- [x] PR #255 merged after owner approval as `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; the second canonical claim requires successful `enforcement-tests`, `known-gaps-live-state`, and `post-merge-validation` push workflows and fails closed if live GitHub state disagrees.

### gap:merge-readiness-exact-head-and-attempt-ordering — P0 — closed

Official basis: GitHub REST workflow-run metadata, GitHub workflow-attempt metadata, official `actions/github-script` and `octokit/rest.js` examples, and the repository merge-readiness contract.

- [x] `scripts/enforcement/check-merge-readiness.sh` requires a full lowercase `--expected-head-sha` and rejects absent, short, or uppercase values.
- [x] Required workflow records with missing or malformed `head_sha` fail closed; runs from every non-matching head are ignored.
- [x] The checker selects the latest exact-head run by `run_started_at`, otherwise `updated_at`, otherwise `created_at`, then `run_attempt`, then run ID.
- [x] Missing, queued, in-progress, cancelled, skipped, timed-out, neutral, action-required, stale, or failed selected runs are not merge-ready.
- [x] Old-success/new-failure, old-failure/new-success, wrong-head success, missing-head, attempt-2 failure, pending, duplicate-name, malformed-metadata, and reversed-input fixtures pass deterministically in `scripts/enforcement/tests/test-operational-readiness-gates.sh`; the clean-install caller is covered by `scripts/enforcement/tests/test-clean-install-and-usage.sh`.
- [x] `core/git-policy.md` requires the checker before the merge API while preserving explicit owner approval; PR #257 recorded approval comment `5060947961` and merged with expected-head protection.
- [x] PR #257 exact head `fedf8d069a8634085c650ea6381c1c0dabfdc368` passed enforcement run 1384, latest `pr-policy` run 1679, every named non-self policy workflow, and review reconciliation; it merged as `efb36cca413602cde3cd20aa17d32b3379f9eb53`, canonical `main` compared identical, and `docs/operations/live-state-claims.json` requires successful post-merge push workflows.

### gap:documentation-runtime-state-drift — P1

Official basis: <https://code.claude.com/docs/en/memory>, GitHub README guidance and official `github/docs` content-linter code, plus CodeRabbit review/configuration documentation.

- [x] Reconcile CLAUDE capability runtime scope with `core/capability-registry.yaml`: `runtime_enabled: true` and `runtime_scope: plan_level_write_gate` are described as an active plan-level write gate.
- [x] Remove volatile README numeric inventory snapshots and link each maintained category to its canonical live inventory.
- [x] Reconcile CodeRabbit availability with observed live review: current review blocks when present or pending; unavailable review requires structured `Review Fallback Evidence`; fabricated success is prohibited.
- [x] Reconcile `scripts/enforcement/MANIFEST.tsv` with the active capability registry and add a regression that rejects non-runtime wording for an enabled runtime gate: `MANIFEST.tsv` now names `test-capability-registry.sh` and describes the active gate; `check-documentation-hygiene.sh` fails closed in both directions (stale-non-runtime wording while the registry is active, or an overclaimed active enforcer while the registry is inactive).
- [x] Reconcile telemetry plan, preflight, checklist, and analyzer terminology so first-run sufficiency and longitudinal sufficiency remain separate: verified `project8-telemetry-preflight.md`, `runtime-telemetry-archive-plan.md`, `runtime-telemetry-archive-audit-checklist.md`, and `analyze-telemetry-archive.py` already keep the two terms distinct, and added a regression that fails a longitudinal-sufficiency claim lacking multi-run context or a first-run claim that wrongly demands a second run.
- [x] Assign one owner for every active runtime, inventory, review, lifecycle, and readiness claim; derived documents must reference rather than duplicate volatile state: added `enforcer-registry` (owner `hooks-governance`, `scripts/enforcement/MANIFEST.tsv`) and `telemetry-terminology` (owner `observability-governance`, `docs/operations/runtime-telemetry-archive-plan.md`) rows to `docs/operations/documentation-ownership.tsv`.
- [x] Extend bidirectional hygiene fixtures to reject every identified contradiction without rewriting historical plans: `test-documentation-hygiene.sh` gained `manifest_stale_rejects_non_runtime_wording`, `manifest_overclaim_rejects_active_enforcer`, `telemetry_longitudinal_unsupported_fails`, and `telemetry_first_run_overreach_fails`; no historical plan or checkpoint evidence was altered.
- [ ] Complete exact-head focused/full CI, external review and thread reconciliation, owner-approved merge, and post-merge validation before closing this gap.

### gap:hard-hook-fail-closed — P0

Official basis: <https://code.claude.com/docs/en/hooks>.

- [ ] Missing hard enforcer, wrapper, interpreter, required manifest, settings input, nested validator, or dependency blocks instead of returning success or silently skipping.
- [ ] Deny-conversion, malformed JSON, unexpected subprocess status, and runtime failure block with Claude Code's documented deny semantics and a reason.
- [ ] Fail-open remains only for explicitly advisory or recorder units.
- [ ] Every hard manifest row maps to one checked-in and installed settings command; every hard PreToolUse path runs the JSON guard and is not soft-wrapped.
- [ ] Remove conditional `if file exists` skips for required validators or convert them into explicit deny paths.
- [ ] Positive, policy-denial, malformed-input, missing-enforcer, missing-nested-validator, missing-wiring, converter/interpreter failure, unexpected-exit, and success fixtures pass.
- [ ] Installed-target copy, exact-head CI/review, owner-approved merge, and post-merge behavior are verified.

### gap:bypass-approval-provenance — P1

- [ ] Define one canonical waiver record with approval reference, approver, approval time, reason, exact gate, target/action scope, creation, expiry or one-shot semantics, and consumption state.
- [ ] Treat environment variables only as bypass requests; reject truthy variables without a complete matching approval from a source the executing process cannot fabricate in the same operation.
- [ ] Reject blank/generic reason, wrong bypass/gate/target/action, stale or expired scope, reused approval, missing issuer, forged record, and master substitution.
- [ ] Remove weaker local fallback `bypass_active()` implementations so every gate uses the same validator.
- [ ] Record accepted approval and consumption metadata without secrets or conversation content and surface it in Stop/PR evidence.
- [ ] Run positive/negative/install/full suites, exact-head review, owner-approved merge, and post-merge validation.

### gap:eos-repo-boundary-sync-drift — P1

- [ ] Define one canonical manifest for required event, matcher, command identity, criticality, failure mode, and terminal-boundary behavior.
- [ ] Cross-check Engineering OS `.claude/settings.json`, the direct-mode patcher, user-level dispatcher settings, and generated target settings against that manifest.
- [ ] Verify runtime-evidence, connector-selection, template-selection, session guard, event recorder, Stop, StopFailure, SessionEnd, and catch-all `.*` wiring exactly.
- [ ] Fail `--verify` on a missing, mismatched, duplicate, legacy, non-durable, or unregistered command.
- [ ] Prove parity in checked-in Engineering OS and a clean installed target.
- [ ] Pass patcher, trust-boundary, archive, hook-classification, full suites, exact-head review, owner-approved merge, and post-merge validation.

### gap:pattern-registry-canonical-drift — P1

- [ ] Declare `patterns/registry.yaml` canonical for identity, domain, lifecycle status, score, version, usage, evidence, and last validation date.
- [ ] Keep domain READMEs canonical only for implementation, security, testing, and adaptation guidance.
- [ ] Make `docs/operations/template-pattern-ratings.tsv` generated/read-only or remove independent lifecycle state from it.
- [ ] Remove contradictory policy wording and align every consumer.
- [ ] Add fixtures rejecting status, score, usage, evidence, version, unknown-row, and active-below-threshold conflicts across registry and derived views.
- [ ] Migrate current rows without inventing evidence.
- [ ] Complete exact-head review, owner-approved merge, and post-merge validation.

### gap:telemetry-archive-import-integrity — P1

- [ ] Make `import-telemetry-run.py` invoke one shared fail-closed bundle validator before any archive write, index update, or replacement.
- [ ] Require regular non-symlink selected files, exact allowlisted filenames, event and summary checksums, event count, non-empty qualification mode, privacy contract, repository, branch, head, Engineering OS head, run, policy, handoff, and terminal boundary identity.
- [ ] Reject a one-byte events mutation, summary mutation, manifest replacement, symlink/non-regular file, wrong repository, wrong branch/head/run, missing boundary, and invalid policy.
- [ ] Import one valid selected bundle successfully and record the validation result in the archive index.
- [ ] Ensure exporter, selector, validator, importer, and analyzer share the same identity vocabulary.
- [ ] Complete focused/full exact-head CI, review, owner-approved merge, and post-merge validation.

### gap:pattern-evidence-maturity — P2

Official basis: AWS Operational Excellence feedback-loop guidance.

- [ ] Report status, `used_in`, score, version, last validation, and evidence for every pattern from the canonical registry.
- [ ] Identify the minimum patterns needed by remaining readiness and qualification work.
- [ ] Link real independent project/run/PR uses, exact commits, tests, outcomes, incidents, failures, and adaptation cost.
- [ ] Update evidence/version/score only from verified results; apply the canonical scoring guide.
- [ ] Promote only after at least two independent real uses and the required score; record failures, regressions, and downgrades.
- [ ] Add promotion/demotion fixtures rejecting missing or contradictory evidence; no bulk promotion or fixture-only closure.
- [ ] Close only after at least one readiness-relevant pattern satisfies the real evidence threshold and all other pattern states remain honest.

### gap:project8-experiment-blindness — P0

Official basis: <https://code.claude.com/docs/en/memory>.

- [ ] Re-fetch Project 8 PR #9 and verify expected head, exact product-boundary diff, all required latest workflow attempts, and every current/outdated review thread.
- [ ] Classify the legacy Azure failure honestly; never treat it as Vercel success or ignore a required failing workflow.
- [ ] Obtain owner approval and merge with expected-head protection.
- [ ] Verify `project-8/main` contains no tracked local prompt, audit, plan, README, or Engineering OS coaching and blocks reintroduction.
- [ ] Verify machine-readable settings contain no experiment or task-routing prose.
- [ ] Close old sessions, open a fresh session, and prove removed guidance was not loaded.
- [ ] Record one natural routed action without revealing the experiment or supplying the future workload prompt.

### gap:dispatch-scope-double-record and gap:multirepo-remote-telemetry-validation — P1

- [ ] Start a fresh Remote qualification only after exact dispatcher installation verification.
- [ ] Prove managed initialization, unmanaged exclusion, identity agreement, unrelated-activity isolation, distinct run IDs, and host-only correlation.
- [ ] Revoke a marker mid-session and prove attribution/fan-out stop.
- [ ] Complete terminal boundaries and required handoff failure surfacing.
- [ ] Produce exact-match non-empty bundles and prove PR selection cannot cross repositories.
- [ ] Review privacy and record that no product feature or behavioral prompt was used.

### gap:project-8-real-run-evidence — P1

Official basis: Claude Code hooks and GitHub workflow artifacts.

- [ ] Update actual `ENGINEERING_OS_HOME` to exact merged `main`; install and pass `--verify` before session start.
- [ ] Verify Project 8 telemetry policy, close old sessions, and open a fresh post-install session.
- [ ] Require positive session, remote-handoff, event, and terminal-boundary counts.
- [ ] Run one bounded non-product task without `--empty-run`, feature implementation, or future workload prompt.
- [ ] Match session, run, repository, branch, target head, Engineering OS head, policy, handoff, and exact telemetry PR bundle.
- [ ] Select only manifest/events/summary, prove positive counts and metadata-only privacy, and pass shared import-integrity validation.
- [ ] Archive the evidence and label findings as qualification transport/identity evidence only.

### gap:monitoring-metrics-sufficiency — P1

Official basis: Google SRE monitoring and OpenTelemetry instrumentation guidance.

- [ ] After telemetry import integrity is closed, import one exact Project 8 qualification bundle that is non-empty, checksum-valid, identity-matched, boundary-complete, and privacy-safe.
- [ ] Preserve analyzer output while separating runtime events, OWH, qualification outcome, and future product outcomes.
- [ ] Record lifecycle coverage, missing events, tools/connectors/skills, failures, retries, friction, false positives, attribution, privacy, duplicates, and decision usefulness.
- [ ] Demonstrate at least one concrete question the data answers and at least one limitation or blind spot.
- [ ] Obtain independent review and convert material missing coverage into a gap or explicit manual-by-design decision.
- [ ] Do not require a second run or claim longitudinal sufficiency to close this first-run gap.

### gap:monitoring-longitudinal-sufficiency — P2

- [ ] Run at least one later qualification with the same schema, integrity, privacy, and identity contracts and import at least two valid runs.
- [ ] Compare lifecycle coverage, attribution, tools/connectors/skills, failures, retries, duplicates, privacy, archive behavior, and analyzer output.
- [ ] Separate recurring blind spots from one-off failures and record improvement, regression, or no change.
- [ ] Create follow-up enforcement for recurring gaps or justify manual-by-design treatment.
- [ ] Prove reproducibility from archived bundles without making Project 8 workload claims.

### gap:full-readiness-claim-semantics — P1

- [x] Normal audit validation can pass an honestly incomplete audit.
- [x] `--assert-full-ready` fails for every non-closed status and every Missing/Partially enforced row.
- [x] Open, mitigated, accepted-manual, and fully-ready fixtures exist and the assertion is merged on `main` through PR #254.
- [ ] Make audit complete, implementation complete, experiment ready, first-run monitoring sufficient, longitudinal monitoring sufficient, and fully operational ready canonical and non-interchangeable in all active docs and CLI output.
- [ ] Ensure analyzers emit evidence/findings rather than assigning closure and reference canonical gap IDs instead of duplicating thresholds.
- [ ] Add contradictory-vocabulary fixtures covering analyzer, preflight, audit, and readiness outputs.
- [ ] After all other gaps close, run the assertion against fresh canonical files and live-state reconciliation; exact-head merge/post-merge evidence and explicit owner approval support final closure.

## Highest-priority gaps by ROI

1. Documentation/runtime consistency — P1; PR #256 closed part of the expanded contract, while MANIFEST and telemetry semantics remain.
2. Hard-hook fail-closed — P0.
3. Bypass approval provenance and required-hook settings parity — P1.
4. Telemetry archive import integrity and canonical pattern ownership — P1.
5. Project 8 experiment blindness — P0 after deterministic Engineering OS defects.
6. Fresh Remote and Project 8 qualification, then first-run monitoring usefulness — P1.
7. Pattern evidence maturity and second-run reproducibility — P2.
8. Final full-readiness semantics and assertion — terminal P1.

Closed regression surfaces retained by the readiness gate: coverage map hardening; RTK runtime hardening; route plan quality gate; learning closure gate; progress lifecycle; connector correctness; simulation completeness; post-merge validation; documentation hygiene; semantic cleanup; live-state reconciliation.

## Experiment start decision

The Project 8 behavioral experiment is **blocked**. It may begin only when every registered gap is exactly `closed`; no matrix row remains Missing or Partially enforced; required technical qualification is complete and separate from experiment evidence; live GitHub state is re-fetched; `--assert-full-ready` passes on canonical `main`; and explicit owner approval from Yotam is recorded before preparation and delivery of the prompt.

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

PR #254 is merged as `c7d32a0b67a836811689d3a2bf80a63d727e1470` and closes the self-contained audit contract. PR #255 is merged as `0ee2dbee7a9ab58e86a11726021c30baca0faa22` after exact head `97d56e2f5743b019145da600cf0914f6d092cd0f` passed the dedicated live workflow, full enforcement, review, and merge-readiness gates. PR #257 is merged as `efb36cca413602cde3cd20aa17d32b3379f9eb53` after exact head `fedf8d069a8634085c650ea6381c1c0dabfdc368` passed deterministic latest-attempt enforcement, full exact-head CI, review reconciliation, and owner-approved expected-head protection. PR #259 is merged as `df01a8fea10df999572ab11466613e31a8c1a003`, synchronizing the registry/audit/live-claim closure metadata for that same gap; post-merge, `enforcement-tests` run 1388, `known-gaps-live-state` run 32, and `post-merge-validation` run 90 all succeeded on that exact commit. `docs/operations/live-state-claims.json` binds all three underlying closures and fails closed on live drift.

PR #256 is merged as `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`. It reconciled capability wording, README inventory references, and CodeRabbit review policy, but the expanded audit still identified documentation/runtime contradictions in `scripts/enforcement/MANIFEST.tsv` and telemetry readiness semantics. That audit refinement also registered `telemetry-archive-import-integrity`; registration alone does not close it. Branch `claude/operational-readiness-eos-c6ykfs` (based on `main` at `df01a8fea1...`) closes the remaining `documentation-runtime-state-drift` checklist items: it reconciles `scripts/enforcement/MANIFEST.tsv` wording with the active capability registry, verifies and guards first-run-vs-longitudinal telemetry terminology, assigns canonical owners for both surfaces in `docs/operations/documentation-ownership.tsv`, and adds bidirectional regression fixtures — all local focused and full enforcement suites pass. It has not yet gone through exact-head CI, review, owner approval, merge, or post-merge validation, so the gap remains `open` until that evidence exists.

The system is audit-complete but not fully operationally ready. Exact-head merge evidence is closed; hook safety, bypass provenance, settings parity, documentation, pattern ownership/evidence, telemetry import integrity, Project 8 boundary, and qualification gaps remain. The behavioral experiment and its prompt remain prohibited until every gap closes and the strict assertion passes on fresh canonical state.
