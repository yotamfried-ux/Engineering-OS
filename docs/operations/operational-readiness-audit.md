# Engineering OS Operational Readiness Audit

This document is the canonical status map and closure contract for Engineering OS operational readiness. A capable LLM or human reviewer can begin here without prior chat context, understand the system and target repositories, identify the next unresolved gap, and know exactly what evidence is required before a readiness or experiment claim.

## Audit metadata

- **Audit owner:** Yotam Friedman; operational owner group `ops-readiness`
- **Canonical repository:** `yotamfried-ux/Engineering-OS`
- **Target repository:** `yotamfried-ux/project-8`
- **Canonical gap registry:** `docs/operations/known-gaps.tsv`
- **Last verified:** 2026-08-05 UTC
- **Intended readers:** LLMs, maintainers, reviewers, and operators with no prior conversation context
- **Snapshot only:** Engineering OS `main` was inspected at `429048199345d5b4836c32626d0094116e5b4c25`; Project 8 `main` at `3ca98089045df7256755bacd4a9a1b8500624874`. Mutable state must always be re-fetched before a decision.

### Qualification findings not yet reflected in the registry

Recorded here when measured, so they are not lost between the run that found them and
the docs-only PR that moves any status. None of these changes a gap status.

- **Required mode had two fail-open routes, not one.** Under `remote_handoff.mode=required`
  a hook command whose Engineering OS root does not resolve exits **127**, and one whose
  wrapper path is a readable directory exits **126**. Claude Code denies at PreToolUse only
  on exit **2**, so both step aside silently. The first was closed on `main` by PR #271; the
  second is closed by PR #272. Measured directly rather than inferred, in both directions.
- **A cancelled terminal boundary blocks the *next* session.** A session whose `SessionEnd`
  hook is cancelled records its boundary locally but never hands it off, and
  `sync-telemetry-run.py --check` then reports "latest completed session boundary was not
  handed off remotely". Under required mode the following session's readiness guard denies
  every tool call. Observed on Project 8: a run recorded 8 local events while the synced
  bundle held 7, and the next run produced `pre_tool_use` with no `post_tool_use`. This is
  the guard behaving correctly — it refuses to proceed when the previous run's evidence did
  not land — but it means qualification sessions cannot chain unless each handoff completes.
  Operators must complete the interrupted handoff before starting the next session.
- **A denial can read as an injection attempt.** In the run above, the fresh session treated
  the guard's `ERROR_FOR_AGENT` text as a possible injected instruction and declined to act
  on it. The denial was legitimate. Worth knowing before the behavioural run, because the
  message shapes how a context-free session interprets being blocked.

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

Analyzers produce evidence and findings; they do not assign canonical closure status. A complete audit may honestly describe an unready syststate can disagree across independent owners. |
| Pattern evidence maturity | Missing enforcement | Gate: rating schema exists. Owner: pattern-governance. Evidence: `patterns/registry.yaml`, scoring guide, and real-use records. | gap:pattern-evidence-maturity — no pattern has verified two-context evidence supporting active status. |
| Template/pattern rating lifecycle | Enforced | Gate: check-template-pattern-ratings.sh. Owner: reuse-governance. Evidence: exact-asset feedback fixtures. | Canonical state drift is tracked separately. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: check-documentation-asset-evidence.sh. Owner: asset-governance. Evidence: documentation selection fixtures. | Best source is reviewed. |
| Skill selection | Enforced | Gate: check-required-skills.sh. Owner: skill-governance. Evidence: inventory coverage fixtures. | Skill fit is reviewed. |
| Skill runtime evidence | Enforced | Gate: pre-tool-use-runtime-evidence.sh. Owner: skill-governance. Evidence: runtime fixtures. | Required nested dependency behavior is enforced by the closed hard-hook contract. |
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
| Cleanup debug leftovers | Enforced | Gate: enforce-quality.sh. Owner: cleanup-governance. Evidence: cleanup fixtures. | Required nested enforcement failure is covered by the closed hard-hook contract. |
| Cleanup semantic hygiene | Enforced | Gate: semantic-cleanup-policy and import-cleanup-policy. Owner: cleanup-governance. Evidence: cleanup fixtures. | Deep semantics are reviewed. |
| Project install contract | Enforced | Gate: install-policy-gates and generated-target tests. Owner: install-governance. Evidence: downstream behavior fixtures. | Cross-boundary hook parity is closed under gap:eos-repo-boundary-sync-drift. Failure behavior inside a wired hard hook is separately scoped and closed under gap:hard-hook-fail-closed. |
| Required-hook settings parity | Enforced | Gate: canonical `hook-criticality.tsv`, registry-driven patcher rendering, `--verify`, `check-hard-hook-contract.py`, and `test-hook-boundary-parity.sh`. Owner: install-governance. Evidence: PR #266 exact head `2ed31c0e6cd9ba52c8540cfdd93f945c27f9772b` passed all 22 exact-head check runs including `enforcement-tests`, `semantic-cleanup-policy`, `import-cleanup-policy` and `pr-policy`; 5 review threads from ChatGPT Codex and CodeRabbit resolved; full enforcement suite 112 suites / 0 failures and `test-hook-boundary-parity.sh` 18/18; merged as `2366333d66946454e0ebdeb83d4afbe34fce88e1`; push workflows `enforcement-tests` 1599 / `30867048831`, `post-merge-validation` `30867048828` job `91861104652`, and `telemetry-handoff-tests` `30867048842`, all `completed/success` on the merge commit. | Closed for wiring parity. Failure behavior inside an already-wired hard hook remains gap:hard-hook-fail-closed. |
| Hard-hook blocking semantics | Enforced | Gate: hook classification, canonical hard/soft wrappers, static contract validation, installed-target regressions, exact-head CI, and live-state reconciliation. Owner: hooks-governance. Evidence: PR #262 exact head `5ee5d9fe51ddd8b9b490fe60424be4ea37cad9b3`; PR workflows `pr-policy` 1770 / `30115981865`; `enforcement-tests` 1463 / `30115055846`; `workflow-evidence-policy` 1230 / `30115055765`; `connector-evidence-policy` 1241 / `30115055853`; `capability-evidence-policy` 1123 / `30115056044`; `documentation-asset-policy` 879 / `30115055789`; `plan-policy` 1242 / `30115055798`; `semantic-cleanup-policy` 903 / `30115055848`; `import-cleanup-policy` 903 / `30115056039`; and `telemetry-handoff-tests` 365 / `30115055914`; 11 resolved review threads; approval comment `5074786377`; merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; push workflows `post-merge-validation` 93 / `30128189835` and `enforcement-tests` 1464 / `30128189839`, both `completed/success` on merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; reconciliation `known-gaps-live-state` 48 / `30130053645`, job `89602353324`, artifact `8610734070` (`sha256:add627ebc6a5475f4d4939cf47f02dd76adea706a70661cd3ceb352352cf2214`). | Closed; queued or `in_progress` required runs and completed non-success conclusions fail closed in the live validator. |
| Enforcement bypass provenance | Enforced | Gate: canonical provider-backed bypass validator and one-shot consumption path. Owner: hooks-governance. Evidence: PR #264 reviewed head `335bd0ba1b92c60e02f0a18a6197587b4c940c0a`, 111/111 local enforcement suites, installed-target validation, exact-head CI, 46 resolved review threads, and merge `f9449e708f9cfaff89458419baea2b96a3af8210` identical to `main`. | Technical implementation closed. Behavioral effectiveness remains an experiment observation, not a pre-experiment blocker. |
| Result Loop Contract enforcement | Enforced | Gate: named result-loop CI plus Operational Work History. Owner: ops-readiness. Evidence: fixtures and real positive/negative PRs. | Contract semantics are reviewed. |
| Operational work history evidence | Enforced | Gate: check-operational-work-history-evidence.sh through pr-policy. Owner: ops-readiness. Evidence: fixtures and real PRs. | Human interpretation remains reviewed. |
| Scaling extension enforcement | Enforced | Gate: named scaling CI step. Owner: ops-readiness. Evidence: scaling fixtures and merged evidence. | Deep roadmap quality is reviewed. |
| Registry/manifest coverage | Enforced | Gate: scaling coverage checks. Owner: registry-governance. Evidence: active rows across required manifests. | Documentation/runtime MANIFEST truth is tracked separately. |
| Canonical telemetry trust boundaries | Enforced | Gate: telemetry-handoff-tests. Owner: ops-readiness. Evidence: merged PR #253 and exact-head regressions. | Direct archive import now proves the same integrity contract through the same validator (PR #268). |
| Telemetry archive import integrity | Enforced | Gate: telemetry archive suite (`test-telemetry-archive.sh`), 14 negative c…4620 tokens truncated…: added `enforcer-registry` (owner `hooks-governance`, `scripts/enforcement/MANIFEST.tsv`) and `telemetry-terminology` (owner `observability-governance`, `docs/operations/runtime-telemetry-archive-plan.md`) rows to `docs/operations/documentation-ownership.tsv`.
- [x] Extend bidirectional hygiene fixtures to reject every identified contradiction without rewriting historical plans: `test-documentation-hygiene.sh` gained `manifest_stale_rejects_non_runtime_wording`, `manifest_overclaim_rejects_active_enforcer`, `telemetry_longitudinal_unsupported_fails`, and `telemetry_first_run_overreach_fails`; no historical plan or checkpoint evidence was altered.
- [x] PR #260 exact head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79` passed focused/full exact-head CI including latest `pr-policy` 1692 and `enforcement-tests` 1391; all seven CodeRabbit/Codex threads were resolved; owner approval comment `5063627361` authorized an expected-head protected merge; PR #260 merged as `105ecd0d0dc72aa847d11b193190689dbda0dda8`; canonical `main` compares identical; and `docs/operations/live-state-claims.json` requires successful post-merge `enforcement-tests`, `known-gaps-live-state`, and `post-merge-validation`.

### gap:hard-hook-fail-closed — P0 — closed

Official basis: <https://code.claude.com/docs/en/hooks>.

- [x] Missing hard enforcer, wrapper, interpreter, required registry/settings input, nested validator, or dependency blocks instead of returning success or silently skipping; focused and installed-target fixtures cover the required chain.
- [x] Deny-conversion, malformed JSON, unexpected subprocess status, signal termination, and runtime failure block with Claude Code's event-specific deny semantics and exit-2 fallback.
- [x] Fail-open remains only for explicitly advisory or recorder units through `soft-hook-gate.sh`, with observable warnings and no fabricated evidence.
- [x] Every hard registry row maps to one checked-in and installed settings command; source and installed settings share `check-hard-hook-contract.py`.
- [x] Required validators and dependencies reject missing, unreadable, symlinked, untrusted, wrong-target, sibling-contaminated, or unavailable infrastructure.
- [x] Full enforcement run 1463 / ID `30115055846` passed the complete positive and negative suite on exact head `5ee5d9fe51ddd8b9b490fe60424be4ea37cad9b3`.
- [x] PR #262 passed all ten required exact-head workflows: `pr-policy` 1770 / `30115981865`; `enforcement-tests` 1463 / `30115055846`; `workflow-evidence-policy` 1230 / `30115055765`; `connector-evidence-policy` 1241 / `30115055853`; `capability-evidence-policy` 1123 / `30115056044`; `documentation-asset-policy` 879 / `30115055789`; `plan-policy` 1242 / `30115055798`; `semantic-cleanup-policy` 903 / `30115055848`; `import-cleanup-policy` 903 / `30115056039`; and `telemetry-handoff-tests` 365 / `30115055914`; reconciled 11 review threads; recorded owner approval comment `5074786377`; and merged with expected-head protection as `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`.
- [x] Observed post-merge evidence: `post-merge-validation` 93 / `30128189835` and `enforcement-tests` 1464 / `30128189839`, both `completed/success` on merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; `known-gaps-live-state` 48 / `30130053645`, job `89602353324`, artifact `8610734070` (`sha256:add627ebc6a5475f4d4939cf47f02dd76adea706a70661cd3ceb352352cf2214`) fetched the metadata-only snapshot and validated the registry, audit, exact PR identity, latest workflow attempts, check run, base containment, and artifact. Queued, `in_progress`, skipped, cancelled, or completed non-success required runs block closure.

### gap:bypass-approval-provenance — P1 — closed

- [x] Canonical approval contract binds approval reference, human issuer, provider time, reason, exact gate/action/surface/target/fingerprint/commit/policy scope, expiry, and durable one-shot consumption.
- [x] `EOS_BYPASS_*` values are requests only; env-only, missing provider, malformed/ambiguous provider state, and master substitution fail closed.
- [x] Blank/generic, wrong-scope, expired, forged, unauthorized, edited, reused, rerun, duplicate/conflicting, and replay cases are covered by negative regressions.
- [x] Weaker local authorization fallbacks were removed and installed targets use the canonical validator.
- [x] Metadata-only accepted/rejected evidence is recorded without secrets or conversation content.
- [x] PR #264 exact reviewed head `335bd0ba1b92c60e02f0a18a6197587b4c940c0a` passed 111/111 local suites, installed-target validation and exact-head CI; all 46 review threads were resolved; owner-approved expected-head merge produced `f9449e708f9cfaff89458419baea2b96a3af8210`; canonical `main` is identical.

Owner decision: **Technical implementation: closed. Behavioral effectiveness remains an experiment observation, not a pre-experiment blocker.**

### gap:eos-repo-boundary-sync-drift — P1 — closed

Official basis: <https://code.claude.com/docs/en/hooks>.

- [x] Define one canonical manifest: `scripts/enforcement/hook-criticality.tsv` is the single owner for event, matcher, unit, criticality, failure semantics, wiring and surface. The competing hardcoded manifest in `patch-settings-telemetry.py:desired_hooks()` was deleted, and ownership markers are derived from the registry instead of a static list.
- [x] Cross-check all four surfaces: the patcher renders checked-in, direct-mode/generated-target and dispatcher settings from the registry with the same gates, so criticality is identical everywhere. `test-hook-boundary-parity.sh` compares unit, argument and gate class per event and matcher across surfaces, accumulating every owned hook in a block rather than only the last.
- [x] Verify wiring exactly, including the catch-all `.*` path and the three terminal events. Two real defects were found and fixed here: Engineering OS settings carried **zero** `record-and-sync-telemetry.sh` boundaries before this change, and the session guard reported correctly-wired gate-wrapped hooks as missing, which **blocks** rather than warns under `remote_handoff.mode = "required"`.
- [x] Fail `--verify` on missing, mismatched, duplicate, legacy and unregistered commands; `check-hard-hook-contract.py` additionally fails when a registered recorder/lifecycle row is unwired, and rejects a soft-gated `propagate_failure` unit. Before the fix `--verify` reported 40+ mismatches against checked-in settings; after, it reports `verified`.
- [x] Prove parity in checked-in Engineering OS and a clean installed target, stated per surface rather than as a single claim. **Field-by-field parity** (unit, argument and gate class for every event/matcher pair) is proven between checked-in settings and a generated target render by `test-hook-boundary-parity.sh` cases 2-3; `check-hard-hook-contract.py --surface source` passes (`direct=13 nested=1`); the `BOUNDARY_READY` probe measures `1` on the checked-in, direct-mode and dispatcher renders. **A real clean install** is covered separately and more narrowly: `test-install-policy-gate-coverage.sh` runs the actual installer and asserts the session guard, session-start and terminal-boundary units are present in the generated settings, and `test-hard-hook-fail-closed.sh` runs `check-hard-hook-contract.py --surface installed` against a clean installed target, which after this change also fails when a registered recorder or lifecycle row is unwired. Full field-by-field parity against a real installed target is not asserted by any single fixture today; that residue is recorded here rather than claimed.
- [x] Pass patcher, trust-boundary, archive, hook-classification and full suites, exact-head review, owner-approved merge, and post-merge validation: PR #266 exact head `2ed31c0e6cd9ba52c8540cfdd93f945c27f9772b` passed all 22 exact-head check runs including `enforcement-tests`, `semantic-cleanup-policy`, `import-cleanup-policy` and `pr-policy`; 5 review threads from ChatGPT Codex and CodeRabbit resolved; full enforcement suite 112 suites / 0 failures and `test-hook-boundary-parity.sh` 18/18; merged as `2366333d66946454e0ebdeb83d4afbe34fce88e1`; push workflows `enforcement-tests` 1599 / `30867048831`, `post-merge-validation` `30867048828` job `91861104652`, and `telemetry-handoff-tests` `30867048842`, all `completed/success` on the merge commit.

Review round: ChatGPT Codex raised a P1 showing that classifying terminal boundaries `lifecycle`/`soft_setup` routed them through `soft-hook-gate.sh`, whose unconditional `exit 0` would have reported a failed required durable handoff as a cleanly closed session with no bundle. Measured directly: the gate-wrapped command returned `0` where the unit returned `2`. `test-dispatch-policy-isolation.sh` already asserted that contract but invoked the unit directly rather than the rendered command, so it could not catch a wiring-level break — recorded in `lessons-learned/bugs/unit-level-contract-passing-while-wiring-violates-it.md`. Terminal boundaries now carry `propagate_failure` semantics and render unwrapped.

Scope: this closes **wiring parity** only. Failure behavior inside an already-wired hard hook belongs to `gap:hard-hook-fail-closed` and was not reopened.

### gap:pattern-registry-canonical-drift — P1

- [ ] Declare `patterns/registry.yaml` canonical for identity, domain, lifecycle status, score, version, usage, evidence, and last validation date.
- [ ] Keep domain READMEs canonical only for implementation, security, testing, and adaptation guidance.
- [ ] Make `docs/operations/template-pattern-ratings.tsv` generated/read-only or remove independent lifecycle state from it.
- [ ] Remove contradictory policy wording and align every consumer.
- [ ] Add fixtures rejecting status, score, usage, evidence, version, unknown-row, and active-below-threshold conflicts across registry and derived views.
- [ ] Migrate current rows without inventing evidence.
- [ ] Complete exact-head review, owner-approved merge, and post-merge validation.

### gap:telemetry-archive-import-integrity — P1 — closed

Official basis: <https://code.claude.com/docs/en/hooks>.

- [x] Make `import-telemetry-run.py` invoke one shared fail-closed bundle validator before any archive write, index update, or replacement. `validate_before_mutation()` delegates to `telemetry_handoff.validate_bundle()`. Review showed the first implementation validated the caller's directory and then copied from it, leaving a window in which the archived bytes were never the validated bytes — so validation and archival now both act on one private snapshot staged outside the archive tree.
- [x] Require regular non-symlink selected files, exact allowlisted filenames, event and summary checksums, event count, non-empty qualification mode, privacy contract, repository, branch, head, Engineering OS head, run, policy, handoff, and terminal boundary identity. Most of this was already implemented in `validate_bundle()` and simply not called on this path; the fix is a call, not a second implementation. Four concerns the shared validator does not own were added importer-side: bundle-directory symlink rejection, the filename allowlist, policy-schema identity, and `engineering_os_head_sha` — which `MANIFEST_REQUIRED` demanded and the index recorded but nothing ever checked.
- [x] Reject a one-byte events mutation, summary mutation, manifest replacement, symlink/non-regular file, wrong repository, wrong branch/head/run, missing boundary, and invalid policy. All present, plus wrong Engineering OS head — 14 negative cases. Each asserts two things: that the archive is byte-identical after the rejection (per-file `sha256sum` fingerprint compared before and after), and **which check fired**, matched against the importer's real stderr rather than recorded in prose.
- [x] Import one valid selected bundle successfully and record the validation result in the archive index. The `runs.jsonl` row carries validator name, `validated_before_mutation`, `snapshot_validated`, and the asserted `expected_*` identities. `checksums_verified` is pinned to the validator's actual set rather than derived from the manifest, so the record cannot claim coverage it does not have.
- [x] Ensure exporter, selector, validator, importer, and analyzer share the same identity vocabulary — the importer reuses `telemetry_handoff` rather than paraphrasing it. Fixtures build synced bundles by calling the real `write_handoff_manifest`, so a change to that writer fails these tests instead of leaving them testing a stale shape.
- [x] Complete focused/full exact-head CI, review, owner-approved merge, and post-merge validation: PR #268 exact head `41e225568d019906c0a1f2b073642a3565442ce4` passed all 21 exact-head check runs including `enforcement-tests`, `semantic-cleanup-policy`, `import-cleanup-policy` and `pr-policy`; 5 review threads from ChatGPT Codex and CodeRabbit resolved; full enforcement suite 112 suites / 0 failures and `test-telemetry-archive.sh` 42 assertions; merged as `d9d65cd88c618416afe246e890a192de8b8ad627`; push workflows `post-merge-validation` `30880041875`, `enforcement-tests` 1608 / `30880041494`, and `telemetry-handoff-tests` `30880041448`, all `completed/success` on the merge commit.

Scope of this closure, stated narrowly: it covers **import-time** integrity. The exporter, the selector, `validate_bundle()` itself and the analyzer are unchanged, and whether an imported bundle is *useful* remains `gap:monitoring-metrics-sufficiency`. Because the importer now shares the handoff path's validator, a defect in `validate_bundle()` would affect both — that is the intended trade against a second, drifting copy.

Review round: ChatGPT Codex raised a P1 TOCTOU between validation and copy and two P2s — `checksums_verified` listing manifest keys the validator never checks, and `engineering_os_head_sha` required and recorded but never validated. CodeRabbit then raised that a negative fixture asserted failure without asserting which check produced it. Its stated premise was wrong (the fixture rejects on the boundary, not the checksum, because `sync_bundle` succeeds on a boundaryless run and reseals the checksums) but the risk was real: the rejection reasons lived in the PR body as hand-written prose that no gate reads. Recorded in `lessons-learned/bugs/negative-test-passing-for-the-wrong-reason.md`, companion to the PR #266 lesson — that one an assertion proving the unit but not the wiring, this one an assertion proving a failure but not which check produced it.

### gap:pattern-evidence-maturity — P2

Official basis: AWS Operational Excellence feedback-loop guidance.

- [ ] Report status, `used_in`, score, version, last validation, and evidence for every pattern from the canonical registry.
- [ ] Identify the minimum patterns needed by remaining readiness and qualification work.
- [ ] Link real independent project/run/PR uses, exact commits, tests, outcomes, incidents, failures, and adaptation cost.
- [ ] Update evidence/version/score only from verified results; apply the canonical scoring guide.
- [ ] Promote only after at least two independent real uses and the required score; record failures, regressions, and downgrades.
- [ ] Add promotion/demotion fixtures rejecting missing or contradictory evidence; no bulk promotion or fixture-only closure.
- [ ] Close only after at least one readiness-relevant pattern satisfies the real evidence threshold and all other pattern states remain honest.

### gap:project8-experiment-blindness — P0 — closed

Official basis: <https://code.claude.com/docs/en/memory>.

- [x] Project 8 PR #9 exact head `8591d2569fb7fcd2481670fe814c5ec46becb8aa` was re-verified with the product-only boundary diff, all relevant exact-head checks green, and 12/12 review threads resolved.
- [x] The legacy Azure workflow was classified as non-required legacy product infrastructure and was green on the final reviewed head; it was not treated as Vercel evidence.
- [x] Owner approval authorized expected-head squash merge; PR #9 merged as `3ca98089045df7256755bacd4a9a1b8500624874`, and Project 8 `main` became identical to that commit.
- [x] Project 8 `main` no longer contains `CLAUDE.md`, local Route Plans, Engineering OS audit/prompt/reference Markdown, or other tracked model-visible coaching; `check-product-boundary.py` blocks reintroduction.
- [x] Machine-readable `.claude/settings.json` retains telemetry/runtime hooks without experiment or task-routing prose.

Owner decision: **Technical implementation: closed. Behavioral effectiveness remains an experiment observation, not a pre-experiment blocker.** Fresh-session blindness and natural uncoached behavior should be measured during the experiment rather than required to authorize its start.

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

1. Canonical pattern ownership — P1. Telemetry archive import integrity closed through PR #268.
2. Fresh Remote and Project 8 qualification, then first-run monitoring usefulness — P1.
3. Pattern evidence maturity and second-run reproducibility — P2.
4. Final full-readiness semantics and assertion — terminal P1.

Required-hook settings parity is no longer listed: it closed through PR #266.

Closed regression surfaces retained by the readiness gate: coverage map hardening; RTK runtime hardening; route plan quality gate; learning closure gate; progress lifecycle; connector correctness; simulation completeness; post-merge validation; documentation hygiene; semantic cleanup; hard-hook fail-closed; live-state reconciliation.

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

PR #256 is merged as `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d` and reconciled capability wording, README inventory references, and CodeRabbit review policy. PR #260 exact head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79` completed the remaining `documentation-runtime-state-drift` contract by reconciling `scripts/enforcement/MANIFEST.tsv` with the active capability registry, enforcing first-run-versus-longitudinal telemetry terminology, assigning canonical ownership rows, and adding bidirectional fixtures. The exact head passed the latest required PR workflows including `pr-policy` 1692 and `enforcement-tests` 1391; all seven review threads were resolved; owner approval comment `5063627361` authorized the expected-head protected merge; PR #260 merged as `105ecd0d0dc72aa847d11b193190689dbda0dda8`; canonical `main` compares identical; and the canonical live-state claim requires successful post-merge workflows. The separate `telemetry-archive-import-integrity` gap was subsequently closed through PR #268 (`d9d65cd`).

PR #262 exact head `5ee5d9fe51ddd8b9b490fe60424be4ea37cad9b3` implemented the canonical hard-hook registry, event-specific fail-closed wrapper, explicit observable soft wrapper, source/installed contract validation, and negative regressions for missing infrastructure, nested dependencies, symlinks, malformed input/output, signals, false evidence, token boundaries, and sibling isolation. Observed PR evidence: `pr-policy` 1770 / `30115981865`; `enforcement-tests` 1463 / `30115055846`; `workflow-evidence-policy` 1230 / `30115055765`; `connector-evidence-policy` 1241 / `30115055853`; `capability-evidence-policy` 1123 / `30115056044`; `documentation-asset-policy` 879 / `30115055789`; `plan-policy` 1242 / `30115055798`; `semantic-cleanup-policy` 903 / `30115055848`; `import-cleanup-policy` 903 / `30115056039`; and `telemetry-handoff-tests` 365 / `30115055914`, all `completed/success`; all 11 review threads were resolved; owner approval comment `5074786377` authorized the expected-head protected merge; PR #262 merged as `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; canonical `main` compares identical. Observed post-merge evidence: `post-merge-validation` 93 / `30128189835` and `enforcement-tests` 1464 / `30128189839`, both `completed/success` on merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; reconciliation `known-gaps-live-state` 48 / `30130053645`, job `89602353324`, artifact `8610734070` (`sha256:add627ebc6a5475f4d4939cf47f02dd76adea706a70661cd3ceb352352cf2214`) completed successfully and preserves the exact metadata-only snapshot.

PR #266 exact head `2ed31c0e6cd9ba52c8540cfdd93f945c27f9772b` made `scripts/enforcement/hook-criticality.tsv` the single canonical owner of the required hook set, deleted the competing hardcoded manifest in `patch-settings-telemetry.py`, rendered every surface from the registry with identical gates, and gave terminal boundaries a distinct `propagate_failure` semantics so a failed required durable handoff can no longer be reported as a cleanly closed session. All 22 exact-head check runs passed, including `enforcement-tests`, `semantic-cleanup-policy`, `import-cleanup-policy` and `pr-policy`; 5 review threads from ChatGPT Codex and CodeRabbit were resolved; the full enforcement suite ran 112 suites with 0 failures and `test-hook-boundary-parity.sh` 18/18. PR #266 merged as `2366333d66946454e0ebdeb83d4afbe34fce88e1` and the merged tree is byte-identical to the reviewed head. Observed post-merge evidence: `enforcement-tests` 1599 / `30867048831`, `post-merge-validation` `30867048828` job `91861104652`, and `telemetry-handoff-tests` `30867048842`, all `completed/success` on the merge commit. Two procedural limitations are recorded rather than assumed: `check-merge-readiness.sh` could not run because the execution environment has no GitHub API credentials, so equivalent state was verified through the check-runs API; and expected-head protection was verified immediately before and after the merge rather than enforced server-side, because the available merge tool accepts no head-SHA parameter.

PR #268 exact head `41e225568d019906c0a1f2b073642a3565442ce4` made `import-telemetry-run.py` delegate to `telemetry_handoff.validate_bundle()` before any archive mutation, against a private snapshot so the bytes validated are the bytes archived, and added the four concerns that validator does not own: bundle-directory symlink rejection, an exact filename allowlist, policy-schema identity, and `engineering_os_head_sha` validation. All 21 exact-head check runs passed on the latest attempt, including `enforcement-tests`, `semantic-cleanup-policy`, `import-cleanup-policy` and `pr-policy`; 5 review threads from ChatGPT Codex and CodeRabbit were resolved; the full enforcement suite ran 112 suites with 0 failures and `test-telemetry-archive.sh` 42 assertions across 14 negative cases, each pinning its own rejection reason against real stderr. PR #268 merged as `d9d65cd88c618416afe246e890a192de8b8ad627`; the merge diff is 566/8 across the same four files the reviewed head carried. Observed post-merge evidence: `post-merge-validation` `30880041875`, `enforcement-tests` 1608 / `30880041494`, and `telemetry-handoff-tests` `30880041448`, all `completed/success` on the merge commit. The same expected-head limitation recorded for PR #266 applies: the head was verified immediately before and after the merge rather than enforced server-side.

The system is audit-complete but not fully operationally ready. Exact-head merge evidence, documentation/runtime consistency, hard-hook safety, bypass provenance, required-hook settings parity, telemetry archive import integrity, and the Project 8 product-only blindness boundary are technically closed. Qualification/first-run monitoring usefulness, pattern ownership/evidence, longitudinal sufficiency, and full-readiness semantics remain open. Behavioral effectiveness of bypass resistance and Project 8 blindness is an experiment observation and does not reopen those technically closed gaps. Under the current canonical Experiment start decision, every remaining open gap still blocks the behavioral experiment; changing that authorization rule around trustworthy telemetry is separate follow-up work and is not claimed by this closure PR.
