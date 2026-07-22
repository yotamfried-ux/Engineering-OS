# Engineering OS Operational Readiness Audit

This audit is the source-of-truth status map for Engineering OS operational readiness.

## Readiness statuses

- **Enforced** — a deterministic hook, CI check, or runtime gate blocks non-compliance.
- **Partially enforced** — deterministic cases are covered but important live or judgment evidence remains; the row links a non-closed gap.
- **Manual** — vocabulary term only; matrix rows must use Manual by design instead.
- **Manual by design** — intentionally human, with an explicit checklist and review evidence.
- **Waiver-gated** — skipping is allowed only with explicit waiver evidence.
- **Missing enforcement** — policy or tooling exists but the requirement can still be skipped; the row links a non-closed gap.
- **Not applicable** — no enforcement is expected for the area.

## Coverage contract

Every matrix row names a Gate, Owner, and Evidence source. Every partial or missing row links a non-closed `gap:<gap_id>`, and every non-closed registered gap appears in the matrix.

## Readiness-claim contract

Two claims are intentionally different:

- **Audit complete** means every requirement is classified and every unresolved condition is registered with an owner, priority, test, closure bar, and evidence source.
- **Fully operationally ready** means there are no blocking `Missing enforcement` rows, no blocking `Partially enforced` rows, and no blocking `open` or `mitigated` gaps. A registered gap is transparent and accounted for; registration does not solve it.

Until `gap:full-readiness-claim-semantics` is closed by deterministic negative coverage, this distinction is policy-level and must be checked manually before any full-readiness statement.

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
| canonical-telemetry-hardening-drift | closed | P1 | Canonical trust-boundary hardening merged in PR #253. |
| monitoring-metrics-sufficiency | open | P2 | First valid target run must be imported and analyzed. |
| monitoring-longitudinal-sufficiency | open | P2 | At least two valid target runs are required for comparative learning. |
| project-8-real-run-evidence | open | P1 | Project 8 requires a fresh instrumented run. |
| operational-work-history-foundation | closed | P1 | CI-generated operational work history. |
| dispatch-scope-double-record | mitigated | P1 | Native direct hooks versus parent-session dispatcher scope. |
| multirepo-remote-telemetry-validation | open | P1 | Fresh successful Remote multi-repository validation. |
| eos-repo-boundary-sync-drift | open | P3 | Engineering OS repository-local boundary hook drift. |
| audit-live-state-verification | open | P0 | Audit closure claims are not yet checked against live GitHub truth. |
| hard-hook-fail-closed | open | P0 | Hard Claude Code hook infrastructure failures can currently fail open. |
| bypass-approval-provenance | open | P1 | `EOS_BYPASS_*` lacks durable human-approval provenance. |
| pattern-registry-canonical-drift | open | P1 | Pattern lifecycle policy contradicts the executable registry owner. |
| full-readiness-claim-semantics | open | P1 | Audit completeness can still be confused with full readiness. |
| project8-experiment-blindness | open | P0 | Project 8 local guidance discloses and coaches the experiment. |
| project8-workload-acceptance | open | P1 | Supabase/Vercel, asset reuse, full feature, UI/UX, and deployment evidence remain incomplete. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests. Owner: core-governance. Evidence: entrypoint and orphan fixtures. | Semantic quality is reviewed. |
| Canonical ownership / no policy sprawl | Enforced | Gate: check-documentation-hygiene.sh. Owner: docs-governance. Evidence: hygiene fixtures. | Deep semantics are reviewed. |
| Enforcement coverage inventory | Enforced | Gate: check-readiness-audit.sh. Owner: ops-readiness. Evidence: readiness fixtures. | Closure judgment is reviewed. |
| Audit registry freshness | Enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: ledger-sync fixtures. | Registry and audit can still agree while both are stale relative to GitHub; gap:audit-live-state-verification. |
| Route Plan before writing | Enforced | Gate: workflow write guards and target-aware plan selection. Owner: workflow-governance. Evidence: active-plan fixtures. | Plan intent is reviewed. |
| Route Plan quality | Enforced | Gate: check-workflow-evidence.sh. Owner: workflow-governance. Evidence: semantic-quality fixtures. | Deep source quality is reviewed. |
| DoD completion | Enforced | Gate: plan-policy and check-workflow-evidence.sh. Owner: delivery-governance. Evidence: completion fixtures. | Meaning of completion is reviewed. |
| Progress validation | Enforced | Gate: check-workflow-evidence.sh. Owner: progress-governance. Evidence: ordered lifecycle fixtures. | Evidence truthfulness is reviewed. |
| Connector selection | Enforced | Gate: check-required-connectors.sh. Owner: connector-governance. Evidence: manifest coverage fixtures. | Best connector choice is reviewed. |
| Connector correctness / source-of-truth use | Enforced | Gate: check-connector-evidence.sh. Owner: connector-governance. Evidence: target and identifier fixtures. | Deep result interpretation is reviewed. |
| Template selection | Enforced | Gate: check-required-templates.py. Owner: template-governance. Evidence: coverage and precision fixtures. | Template fit is reviewed. |
| Pattern usage | Enforced | Gate: check-required-patterns.sh. Owner: pattern-governance. Evidence: domain and waiver fixtures. | Pattern fit is reviewed. |
| Pattern lifecycle canonical ownership | Missing enforcement | Gate: documentation hygiene and required-pattern tests exist. Owner: pattern-governance. Evidence: `patterns/registry.yaml`, `patterns/README.md`, and `check-required-patterns.sh`. | gap:pattern-registry-canonical-drift — `core/pattern-lifecycle.md` still contradicts the executable registry owner. |
| Template/pattern rating lifecycle | Enforced | Gate: check-template-pattern-ratings.sh. Owner: reuse-governance. Evidence: exact-asset feedback fixtures. | Feedback truthfulness is reviewed. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: check-documentation-asset-evidence.sh. Owner: asset-governance. Evidence: documentation selection fixtures. | Best source is reviewed. |
| Skill selection | Enforced | Gate: check-required-skills.sh. Owner: skill-governance. Evidence: inventory coverage fixtures. | Skill fit is reviewed. |
| Skill runtime evidence | Enforced | Gate: pre-tool-use-runtime-evidence.sh. Owner: skill-governance. Evidence: runtime fixtures. | Deep use is reviewed. |
| RTK context optimization | Enforced | Gate: required-skill and session setup checks. Owner: context-governance. Evidence: RTK hardening fixtures. | External effect is reviewed. |
| Graphify context graph | Enforced | Gate: check-plan-scope.sh. Owner: context-governance. Evidence: target-linked graph fixtures. | Graph accuracy is reviewed. |
| Claude memory / context carryover | Manual by design | Gate: manual review. Owner: context-governance. Evidence: Checklist: `docs/operations/memory-context-checklist.md`. | Runtime intent cannot be proven deterministically. |
| Capability registry | Enforced | Gate: capability-evidence-policy. Owner: capability-governance. Evidence: staged-path fixtures. | Stale declarations are tolerated deliberately. |
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
| Hard-hook blocking semantics | Missing enforcement | Gate: hook classification and wrapper tests exist. Owner: hooks-governance. Evidence: `hook-criticality.tsv` and Claude Code hooks contract. | gap:hard-hook-fail-closed — missing enforcers and deny-conversion failures can allow the protected action. |
| Enforcement bypass provenance | Missing enforcement | Gate: evidence ledger records bypass names. Owner: hooks-governance. Evidence: `bypass_active()`. | gap:bypass-approval-provenance — no approval reference, reason, bounded scope, or expiry is required. |
| Result Loop Contract enforcement | Enforced | Gate: named result-loop CI step plus Operational Work History contract validation. Owner: ops-readiness. Evidence: fixtures and real PRs #239/#240. | Contract semantics are reviewed. |
| Operational work history evidence | Enforced | Gate: check-operational-work-history-evidence.sh through pr-policy. Owner: ops-readiness. Evidence: fixtures and real PRs #234/#235/#236. | Human interpretation remains reviewed. |
| Scaling extension enforcement | Enforced | Gate: named scaling CI step. Owner: ops-readiness. Evidence: scaling fixtures and PR #229. | Deep roadmap quality is reviewed. |
| Registry/manifest coverage | Enforced | Gate: scaling coverage checks. Owner: registry-governance. Evidence: active rows across all required manifests. | Registry content quality is reviewed. |
| Canonical telemetry trust boundaries | Enforced | Gate: telemetry-handoff-tests. Owner: ops-readiness. Evidence: PR #253, merge `bc160ee4d2058acd28ae2325d23fcbcb926de888`, exact-head CI, and resolved review threads. | Live Project 8 evidence remains separate. |
| Monitoring metrics first-run sufficiency | Missing enforcement | Gate: exporter, importer, analyzer, and privacy tests exist. Owner: ops-readiness. Evidence: telemetry archive tests and Project 8 OWH-only findings. | gap:monitoring-metrics-sufficiency — requires one valid non-empty target run export, import, analysis, and reviewed findings. |
| Monitoring longitudinal sufficiency | Missing enforcement | Gate: archive analyzer can compare projects and recurring missing coverage. Owner: ops-readiness. Evidence: analyzer tests and archive plan. | gap:monitoring-longitudinal-sufficiency — requires at least two valid target runs; it does not block the first Project 8 experiment. |
| Project 8 real-run evidence | Missing enforcement | Gate: mandatory telemetry preflight exists. Owner: ops-readiness. Evidence: Project 8 first-run findings and preflight runbook. | gap:project-8-real-run-evidence — requires a fresh instrumented Project 8 session and non-empty analyzed bundle. |
| Remote multi-repository telemetry dispatch | Partially enforced | Gate: telemetry-handoff-tests exercises installer, managed-only discovery, attribution, scoped guard, isolation, policy, failures, and PR matching. Owner: ops-readiness. Evidence: PR #250 fixtures plus the real failed Remote attempt. | gap:dispatch-scope-double-record and gap:multirepo-remote-telemetry-validation — deterministic repairs exist, but fresh successful Remote closure evidence is still required. |
| Engineering OS repository boundary hook synchronization | Missing enforcement | Gate: exact patcher verification exists, but the checked-in repository-local boundary commands have not been synchronized. Owner: install-governance. Evidence: patch-settings-telemetry.py and PR #250 finding. | gap:eos-repo-boundary-sync-drift — repair separately before enabling required or best-effort telemetry in this repository. |
| Full-readiness claim semantics | Missing enforcement | Gate: audit structure is validated, but no assertion mode rejects a full-ready claim while blocking gaps remain. Owner: ops-readiness. Evidence: this audit's readiness-claim contract. | gap:full-readiness-claim-semantics. |
| Project 8 behavioral blindness | Missing enforcement | Gate: Project 8 PR #9 adds a product-only Markdown boundary. Owner: ops-readiness. Evidence: current `project-8/main` guidance and PR #9 exact-head CI. | gap:project8-experiment-blindness — local `CLAUDE.md` and `docs/engineering-os/claude-project-8-prompt.md` coach and disclose the experiment until the product-only boundary is merged and post-merge validated. |
| Project 8 workload acceptance | Missing enforcement | Gate: baseline CI and isolated Postgres foundation exist. Owner: product-readiness. Evidence: Project 8 merged PRs #4/#6 and open PR #9. | gap:project8-workload-acceptance — Supabase runtime cutover, Vercel live deployment, existing-asset reuse, all-feature E2E, UI/UX, UTF-8/RTL, and post-deploy evidence remain required. |
| Git/branch policy | Enforced | Gate: pr-policy. Owner: merge-governance. Evidence: merge readiness artifact. | Live state is reviewed. |
| PR review / external review | Enforced | Gate: check-pr-review-evidence.sh through pr-policy. Owner: review-governance. Evidence: review fixtures. | Review depth is human. |
| Merge safety | Manual by design | Gate: owner decision. Owner: merge-governance. Evidence: Checklist: `docs/operations/merge-readiness-checklist.md`. | Human approval is intentional. |
| Post-merge validation | Enforced | Gate: post-merge-validation workflow. Owner: merge-governance. Evidence: repair-path fixtures. | Live failures use the incident checklist. |
| Known gaps register | Enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: schema and ledger fixtures. | Closure judgment is reviewed. |

## Mandatory end-to-end closure checklists

A gap may move to `closed` only when every checkbox in its section is checked with an exact file, commit, PR, workflow run, artifact, provider resource identifier, or test output. A PR body statement without the linked evidence is not sufficient.

### gap:audit-live-state-verification — P0

Official basis: GitHub status checks are attached to exact commits and GitHub Actions produces checks; a skipped job can report success, so the validator must inspect the intended named checks and exact head rather than trust prose. Reference: <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks>.

- [ ] Add a live-state input contract to `check-known-gaps.sh` or a directly invoked helper; do not create a second canonical gap registry.
- [ ] Parse every non-closed/closure claim that names a PR, merge requirement, commit, or workflow and bind it to an expected repository plus exact identifier.
- [ ] In CI, obtain live PR state, `merged_at`, merge commit, exact head SHA, and named workflow conclusions through GitHub's API.
- [ ] Fail when the audit and registry agree with each other but contradict live GitHub state.
- [ ] Fail when a closure cites only `pr-policy`, a skipped job, a stale head, or an unnamed “all checks passed” claim.
- [ ] Pass when the exact referenced PR is merged, the expected merge commit is present on `main`, and required named checks are successful.
- [ ] Add offline positive and negative fixtures so repository tests do not depend solely on network access.
- [ ] Reconcile the real historical #253 stale-claim case in a test fixture.
- [ ] Run `bash scripts/enforcement/tests/test-known-gaps.sh`, `bash scripts/enforcement/check-known-gaps.sh`, and the full enforcement suite.
- [ ] Open a ready-for-review PR, verify exact-head CI and zero unresolved review threads, obtain owner approval, merge with expected head SHA, and verify `main` post-merge.

### gap:hard-hook-fail-closed — P0

Official basis: Claude Code documents that `PreToolUse` is blocked only by `exit 2` or a valid deny decision; exit code `1` and other nonzero codes are non-blocking for most hook events. Reference: <https://code.claude.com/docs/en/hooks>.

- [ ] Change the hard-hook wrapper so a missing enforcer cannot return success.
- [ ] Change deny-conversion/runtime failures so they block with `exit 2` and a concrete stderr reason.
- [ ] Keep fail-open behavior only for units classified `advisory`, `recorder`, or explicitly soft lifecycle behavior in `hook-criticality.tsv`.
- [ ] Confirm every hard `PreToolUse` setting runs the JSON guard first and is not wrapped in `|| true`.
- [ ] Add a missing-enforcer negative fixture and prove the protected tool call is denied.
- [ ] Add a converter/interpreter failure fixture and prove the protected tool call is denied.
- [ ] Add malformed-input, genuine-policy-violation, and normal-success fixtures.
- [ ] Exercise the generated target-project installation, not only the source wrapper.
- [ ] Run `bash scripts/enforcement/tests/test-hook-classification.sh`, `bash scripts/enforcement/tests/test-clean-install-and-usage.sh`, and the full enforcement suite.
- [ ] Complete exact-head self-review focused on accidental bricking, false positives, and parity between git hooks and Claude Code hooks; then merge only after all CI/review gates and owner approval.

### gap:bypass-approval-provenance — P1

Official basis: Claude Code project settings are shareable and hooks inherit process environment, so an environment flag alone cannot prove an owner decision. Reference: <https://code.claude.com/docs/en/hooks>.

- [ ] Define one canonical waiver record containing bypass name, stable decision ID or durable approval reference, concrete reason, bounded target/action scope, issuer, and creation time.
- [ ] Require the approval reference and reason before `bypass_active()` returns true.
- [ ] Reject a truthy `EOS_BYPASS_*` with no approval record.
- [ ] Reject an approval record for another bypass, another target, an expired scope, or a blank/generic reason.
- [ ] Record accepted bypass metadata in the evidence ledger without secrets or raw conversation content.
- [ ] Ensure master bypasses cannot silently authorize child bypasses without the same provenance.
- [ ] Add positive, missing-field, wrong-scope, stale, and forged-record fixtures.
- [ ] Verify the Stop/PR evidence surfaces every accepted bypass and prevents a normal completion claim unless the waiver is explicitly reconciled.
- [ ] Run workflow, evidence, install, and full enforcement tests; complete exact-head review and post-merge validation.

### gap:pattern-registry-canonical-drift — P1

- [ ] Update `core/pattern-lifecycle.md` to state that `patterns/registry.yaml` owns pattern identity, domain, lifecycle status, score, version, usage count, and evidence.
- [ ] State that `patterns/<domain>/README.md` owns implementation guidance, examples, security considerations, and testing instructions.
- [ ] Remove text claiming there is no YAML registry.
- [ ] Ensure `core/connector-policy.md`, `patterns/README.md`, `core/scoring-guide.md`, and `check-required-patterns.sh` use the same ownership model.
- [ ] Add a documentation-hygiene negative fixture that reintroduces the contradictory sentence and must fail.
- [ ] Verify registry paths resolve, domains are non-empty, and every registry `code_path` exists.
- [ ] Run documentation hygiene, required-pattern, scoring/registry, orphan, and full enforcement tests.
- [ ] Complete exact-head review, merge, and post-merge validation.

### gap:full-readiness-claim-semantics — P1

- [ ] Add an explicit `--assert-full-ready` or equivalent mode to the canonical readiness checker.
- [ ] Keep the normal checker able to validate an honestly incomplete audit.
- [ ] Make full-ready assertion fail for blocking `open` or `mitigated` gaps and for `Missing enforcement` or blocking `Partially enforced` rows.
- [ ] Define and fixture-test any non-blocking exception; no silent exception is allowed.
- [ ] Add a negative fixture where every gap is registered but one remains open; the audit-complete check must pass and full-ready assertion must fail.
- [ ] Add a positive fixture with only Enforced, Manual by design with checklist, Waiver-gated with valid evidence, or Not applicable rows.
- [ ] Wire the assertion into any workflow or release path that can publish a full-readiness claim.
- [ ] Run readiness, known-gap, documentation, and full enforcement tests; complete exact-head review and post-merge validation.

### gap:project8-experiment-blindness — P0 and experiment-start blocker

Current evidence: `project-8/main` contains `CLAUDE.md`, `docs/engineering-os/project-8-audit.md`, and `docs/engineering-os/claude-project-8-prompt.md`; the prompt explicitly describes the experiment and prescribes Engineering OS behavior. Project 8 PR #9 removes tracked Markdown guidance and retains machine-readable runtime telemetry.

- [ ] Verify PR #9 changed paths contain only the reviewed product-boundary/runtime migration scope and no product behavior change.
- [ ] Verify the exact PR #9 head has successful `pr-policy`, `baseline-ci`, semantic-cleanup, and import-cleanup checks; classify the legacy Azure workflow separately and do not treat an obsolete provider deploy as target success.
- [ ] Verify all current and outdated review threads are resolved and every valid finding has a regression.
- [ ] Obtain explicit owner approval and merge PR #9 using its expected head SHA.
- [ ] Verify `project-8/main` contains no tracked Markdown guidance, prompt, plan, audit, or local Engineering OS coaching file.
- [ ] Verify the product-boundary workflow/checker blocks reintroduction of tracked Markdown guidance after merge.
- [ ] Verify `.claude/settings.json` and `.engineering-os/telemetry-policy.json` retain only machine-readable runtime/telemetry behavior and contain no experiment description or task-routing instructions.
- [ ] Start a genuinely new Claude Code session after the merge and after installing the current Engineering OS runtime; do not resume a session that loaded the old files.
- [ ] Inspect `InstructionsLoaded` telemetry or equivalent metadata and prove no removed Project 8 guidance file was loaded.
- [ ] Supply the experiment workload prompt only through the user message; it must not mention experiment, evaluation, telemetry objectives, expected tool/skill choices, Route Plan fields, or how Engineering OS should behave.
- [ ] Do not begin the behavioral run until every item above has exact linked evidence.

### gap:project-8-real-run-evidence — P1 and experiment-start blocker

Official basis: Claude Code `SessionStart` initializes session-scoped state; `SessionEnd` cannot block termination. GitHub workflow artifacts persist run outputs but are transport evidence, not a longitudinal archive. References: <https://code.claude.com/docs/en/hooks> and <https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts>.

- [ ] Update the actual `ENGINEERING_OS_HOME` checkout to the exact merged Engineering OS `main` head.
- [ ] Install user-level telemetry hooks from that exact checkout and run installer `--verify` successfully.
- [ ] Verify Project 8's required telemetry policy is schema-valid, points to `origin` / `engineering-os-telemetry`, and is owned by the trusted base.
- [ ] Close every prior Claude session and open a new session after installation.
- [ ] Before product work, run `bash "$ENGINEERING_OS_HOME/scripts/monitoring/require-telemetry-session.sh"`.
- [ ] Require both positive output lines: `telemetry session ready: events=N` and `telemetry remote handoff ready: events=N boundary=N`, with every `N > 0`.
- [ ] Run one bounded real Project 8 task; do not use `--empty-run` and do not fabricate events.
- [ ] Confirm local events, run ID, repository, branch, head, policy, and handoff state all match the session.
- [ ] Confirm the telemetry branch contains a non-empty metadata-only bundle for the exact product head.
- [ ] Confirm `pr-policy` selects the exact bundle for the exact PR/head and uploads only `manifest.json`, `events.jsonl`, and `latest-summary.md`.
- [ ] Confirm Operational Work History and the session artifact both report positive event counts.
- [ ] Confirm no raw prompt, response, command, file path, connector payload, environment value, API key, or secret appears.
- [ ] Import the exact bundle into `telemetry-archive`, run the analyzer for `project-8`, and write reviewed `findings.md` covering missing coverage, friction, false positives, decision quality, and product outcome.

### gap:multirepo-remote-telemetry-validation and gap:dispatch-scope-double-record — P1

- [ ] Open a fresh Remote session only after the merged dispatcher is installed and exactly verified.
- [ ] Prove managed repositories initialize at SessionStart and unmanaged siblings create no telemetry state.
- [ ] Prove explicit path/repository identities agree and conflicting or malformed identities remain unattributed.
- [ ] Prove unrelated activity is neither attributed nor blocked even when the parent cwd contains a managed repository.
- [ ] Prove each managed repository has a distinct run ID and shared host correlation only.
- [ ] Remove or invalidate a policy marker mid-session and prove further attribution and lifecycle fan-out stop.
- [ ] Complete boundaries for all managed repositories and prove required handoff failures surface without suppressing sibling recording.
- [ ] Produce non-empty exact-match bundles and prove repository/branch/head/PR selection cannot cross repositories.
- [ ] Review diagnostics against the metadata-only privacy contract.
- [ ] Link the fresh session evidence before moving `dispatch-scope-double-record` from mitigated or closing the Remote validation gap.

### gap:monitoring-metrics-sufficiency — P2

- [ ] Complete the exact fresh Project 8 run checklist above.
- [ ] Import one non-empty, checksum-valid, identity-matched bundle into the canonical archive.
- [ ] Run the analyzer successfully and preserve its output.
- [ ] Write reviewed findings that distinguish Claude/Engineering OS behavior, PR/CI Operational Work History, and Project 8 product outcomes.
- [ ] Record event-type coverage, missing events, connector/tool coverage, failures, friction, false positives, and decision-quality evidence.
- [ ] Confirm privacy checks and duplicate-run handling pass.
- [ ] Close only after a reviewer confirms the collected fields are sufficient to answer the first-run research questions.

### gap:monitoring-longitudinal-sufficiency — P2, not a first-run blocker

- [ ] Import at least one later valid Project 8 or other target-project run using the same schema and privacy contract.
- [ ] Compare at least two runs by event coverage, tool/connector usage, failures, retries, friction, decision quality, and product outcome.
- [ ] Identify recurring blind spots separately from one-off failures.
- [ ] Record whether Engineering OS changes improved, worsened, or did not affect the measured behavior.
- [ ] Create concrete follow-up enforcement or explain why a recurring issue is manual by design.
- [ ] Review and close only when the comparison is reproducible from archived bundles.

### gap:eos-repo-boundary-sync-drift — P3

- [ ] Run the canonical telemetry settings patcher against Engineering OS `.claude/settings.json` in direct mode.
- [ ] Verify catch-all PreToolUse guard/recorder, SessionStart, Stop, StopFailure, and SessionEnd commands exactly match the patcher contract.
- [ ] Ensure Stop/StopFailure/SessionEnd use boundary recording and synchronization rather than event-only recording.
- [ ] Run patcher `--verify`, trust-boundary tests, archive tests, hook-classification tests, and the full suite.
- [ ] Keep this focused change separate from the Project 8 product workload.
- [ ] Complete exact-head review, merge, and post-merge validation before enabling required/best-effort telemetry in Engineering OS itself.

### gap:project8-workload-acceptance — P1, experiment workload completion gate

This section does not block opening the instrumented session after the blindness and telemetry preconditions pass. It blocks declaring the Project 8 work successful.

Official basis and implementation decisions:

- Vercel separates Local, Preview, and Production environments and scopes environment variables per environment; changed values apply only to new deployments. References: <https://vercel.com/docs/deployments/environments> and <https://vercel.com/docs/environment-variables>.
- Vercel supports Vite, Express, and monorepo deployment shapes; select the smallest shape that preserves the current product and validate the actual linked project. References: <https://vercel.com/docs/frameworks/frontend/vite>, <https://vercel.com/docs/frameworks/backend/express>, and <https://vercel.com/docs/monorepos>.
- Existing custom domains must be inspected and reused before creating or changing DNS. Reference: <https://vercel.com/docs/domains/set-up-custom-domain>.
- Supabase requires RLS on exposed-schema tables; publishable keys are client-safe while secret/service-role keys are backend-only and bypass RLS. References: <https://supabase.com/docs/guides/database/postgres/row-level-security>, <https://supabase.com/docs/guides/getting-started/api-keys>, and <https://supabase.com/docs/guides/database/secure-data>.
- Supabase/Prisma serverless runtime should use the pooled connection while migrations and introspection use a direct connection. References: <https://supabase.com/docs/guides/database/connecting-to-postgres> and <https://www.prisma.io/docs/orm/v6/overview/databases/supabase>.
- Playwright is the required browser-level E2E evidence layer and supports Chromium, WebKit, Firefox, CI, and mobile emulation. Reference: <https://playwright.dev/docs/intro>.
- Forms must have accessible labels, grouping, and instructions. Reference: <https://www.w3.org/WAI/tutorials/forms/>.

#### Existing assets and secrets

- [ ] Inventory the existing Vercel project/team/project ID, framework/root/build/output settings, environments, preview/production deployments, domains, and aliases through the live connector or CLI.
- [ ] Inventory the existing Supabase project reference, database, schemas, migrations, auth/storage use, URL, publishable/anon key presence, secret/service-role key presence, and connection-string types through the live connector or dashboard/API.
- [ ] Inventory GitHub Actions secrets, variables, environments, existing application API-key names, domain-related configuration, and current provider workflows.
- [ ] Record only names, presence, scope, last validation result, and intended use; never print or commit secret values.
- [ ] Reuse every valid existing URL, domain, API key, provider resource, and integration configuration; create/rotate/remove only with a documented reason and rollback path.
- [ ] Prove no secret moved into source, Markdown, logs, screenshots, artifacts, browser bundles, or client-exposed variables.

#### Supabase/Postgres runtime completion

- [ ] Confirm the merged isolated Postgres foundation still passes before modifying the active runtime.
- [ ] Map every remaining SQL Server/T-SQL assumption to an exact file and test; no untracked `dbo`, `UNIQUEIDENTIFIER`, `NVARCHAR`, `DATETIME2`, bracketed identifiers, SQL Server connection builder, or Azure SQL default may remain in the active path.
- [ ] Select and document the final Prisma/Supabase access boundary; do not maintain two active database architectures after cutover.
- [ ] Configure pooled `DATABASE_URL` for runtime/serverless traffic and direct `DIRECT_URL` for migrations/introspection without exposing either value.
- [ ] Apply versioned Postgres migrations to the intended Supabase project and verify migration history from the live database.
- [ ] Enable and force RLS where required on every exposed tenant table and create least-privilege policies for authenticated roles.
- [ ] Prove cross-tenant reads/writes are denied using a non-superuser/non-service-role identity.
- [ ] Prove server-only secret/service-role credentials never enter the Vite client bundle and publishable credentials cannot bypass RLS.
- [ ] Validate all existing server routes and background behaviors against Supabase/Postgres, including auth, business/settings, appointments, reports, public booking, cookies/legal, integrations, payments, invoices, accounting, notifications, and waitlist.
- [ ] Remove or explicitly quarantine obsolete Azure SQL runtime configuration only after rollback and data-migration evidence exists.

#### Vercel deployment completion

- [ ] Link the repository to the existing Vercel project rather than creating a duplicate when a valid project already exists.
- [ ] Choose the smallest documented Vercel deployment shape for the current Vite client and Express server/monorepo; record root directories, build commands, output directories, routing, and function boundaries.
- [ ] Map every required variable to Development, Preview, and Production; prove preview and production values exist by name and scope without exposing values.
- [ ] Redeploy after every environment-variable change because older deployments do not receive new values.
- [ ] Produce a preview deployment for the exact PR head and run API, database, and browser E2E tests against its commit-specific URL.
- [ ] Reuse and verify the existing production domain/URL; inspect required DNS before changing any record.
- [ ] Prove production build, server functions, static assets, API routing, cookies, CORS, auth redirects, and database connectivity from deployment logs and HTTP checks.
- [ ] Keep Azure deployment as rollback only until Vercel production validation passes; after cutover, ensure Azure is not the active provider and cannot silently deploy the same branch.

#### Feature, UI/UX, encoding, and end-to-end validation

- [ ] Build a feature inventory from actual server routes, client routes, navigation, tests, and provider integrations; every existing feature receives one status: passing, failing, blocked with concrete external reason, or intentionally removed with owner approval.
- [ ] Add or repair API/integration tests for every server feature and edge case affected by the database/provider cutover.
- [ ] Add or repair Playwright E2E flows for registration/login, business setup, public booking, appointment management, settings, dashboard/statistics, customers, waitlist, cancellation/rescheduling, notifications/integrations, legal/cookie flows, and not-found/error states as present in the product.
- [ ] Run the critical E2E suite against Chromium, WebKit, and Firefox, plus a mobile viewport for the public booking flow.
- [ ] Validate Hebrew UTF-8 source integrity, RTL direction, translated labels/messages, date/time/timezone behavior, responsive layout, keyboard navigation, focus, form labels, validation messages, loading/empty/error states, and no clipped/overlapping content.
- [ ] Capture screenshots or traces for each major public and owner flow on the exact preview deployment.
- [ ] Fix existing product defects revealed by tests, including UI/UX, encoding, runtime, API, and data issues; do not suppress, skip, delete, or weaken a failing test to obtain green CI.
- [ ] Re-run the complete server, client, Postgres/Supabase, build, UTF-8, E2E, security, semantic-cleanup, import-cleanup, and policy suites after the final fix.
- [ ] Perform structured self-review of the exact diff; use CodeRabbit when available and reconcile every live thread.
- [ ] Record exact-head CI, preview URL, production URL/domain, provider project identifiers, migration/RLS evidence, test counts, screenshots/traces, known residual risks, and rollback steps in the PR.
- [ ] Obtain explicit owner approval before merge/deploy, merge with expected head SHA, and run post-merge plus production smoke validation.

## Highest-priority gaps by ROI

1. Hard-hook fail-closed — P0; deterministic enforcement can currently permit actions when its infrastructure is missing or cannot produce a deny.
2. Project 8 experiment blindness — P0; the current target repository coaches and discloses the experiment until PR #9 is merged and validated.
3. Audit live-state verification — P0; canonical documents can agree while both are stale relative to GitHub.
4. Project 8 fresh telemetry run and Remote multi-repository validation — P1; both require a genuinely fresh post-install session and non-empty exact-match evidence.
5. Project 8 workload acceptance — P1; the run must preserve existing assets while completing Supabase/Vercel and all-feature E2E evidence.
6. Bypass approval provenance, pattern canonical drift, and full-readiness claim semantics — P1 governance repairs.
7. Monitoring first-run sufficiency — closes from the same valid Project 8 bundle after import and analysis.
8. Longitudinal monitoring — requires a later second run and does not block the first experiment.
9. Engineering OS repository boundary synchronization — P3 focused repair outside the Project 8 workload.

## Experiment start decision

The next Project 8 behavioral run is **blocked** until every checkbox in both `gap:project8-experiment-blindness` and the installation/preflight portion of `gap:project-8-real-run-evidence` is complete. The product migration and feature checklist is the workload acceptance contract inside that run, not prior coaching for Claude.

The prompt supplied to Claude must state only the product objective and the requirement to verify that the latest Engineering OS version is installed. It must not mention that the session is an experiment, the telemetry research objective, expected Engineering OS routing behavior, specific skills/connectors/templates to choose, or the internal closure checklist.

## Current audit scope

Engineering OS PR #253 is merged and closes the canonical telemetry trust-boundary implementation gap. Current blockers are live enforcement semantics, honest readiness claims, Project 8 experiment blindness, fresh-session telemetry evidence, Remote multi-repository observation, and the real Supabase/Vercel/product acceptance workload. Project 8 PR #9 is green on its latest required policy/baseline checks and has zero unresolved review threads, but it remains unmerged and its legacy Azure deployment workflow is failing; that legacy workflow is not Vercel success evidence and must be classified explicitly during merge readiness.