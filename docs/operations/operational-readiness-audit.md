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

- **Audit complete** means every requirement is classified and every unresolved condition is registered with an owner, priority, test, closure bar, and evidence source.
- **Fully operationally ready** means there are no blocking `Missing enforcement` rows, no blocking `Partially enforced` rows, and no blocking `open`, `blocked`, or `mitigated` gaps.
- A registered gap is transparent and accounted for. Registration does not solve it.

Until `gap:full-readiness-claim-semantics` is closed by deterministic negative coverage, the full-readiness claim remains manually prohibited while a blocking gap exists.

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
| Audit registry freshness | Partially enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: ledger-sync fixtures. | gap:audit-live-state-verification — registry and audit can still agree while both are stale relative to GitHub. |
| Route Plan before writing | Enforced | Gate: workflow write guards and target-aware plan selection. Owner: workflow-governance. Evidence: active-plan fixtures. | Plan intent is reviewed. |
| Route Plan quality | Enforced | Gate: check-workflow-evidence.sh. Owner: workflow-governance. Evidence: semantic-quality fixtures. | Deep source quality is reviewed. |
| DoD completion | Enforced | Gate: plan-policy and check-workflow-evidence.sh. Owner: delivery-governance. Evidence: completion fixtures. | Meaning of completion is reviewed. |
| Progress validation | Enforced | Gate: check-workflow-evidence.sh. Owner: progress-governance. Evidence: ordered lifecycle fixtures. | Evidence truthfulness is reviewed. |
| Connector selection | Enforced | Gate: check-required-connectors.sh. Owner: connector-governance. Evidence: manifest coverage fixtures. | Best connector choice is reviewed. |
| Connector correctness / source-of-truth use | Enforced | Gate: check-connector-evidence.sh. Owner: connector-governance. Evidence: target and identifier fixtures. | Deep result interpretation is reviewed. |
| Template selection | Enforced | Gate: check-required-templates.py. Owner: template-governance. Evidence: coverage and precision fixtures. | Template fit is reviewed. |
| Pattern usage | Enforced | Gate: check-required-patterns.sh. Owner: pattern-governance. Evidence: domain and waiver fixtures. | Pattern fit is reviewed. |
| Pattern lifecycle canonical ownership | Missing enforcement | Gate: documentation hygiene and required-pattern tests exist. Owner: pattern-governance. Evidence: registry and README contracts. | gap:pattern-registry-canonical-drift — `core/pattern-lifecycle.md` contradicts the executable registry owner. |
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
| Canonical telemetry trust boundaries | Enforced | Gate: telemetry-handoff-tests. Owner: ops-readiness. Evidence: PR #253 and merge `bc160ee4d2058acd28ae2325d23fcbcb926de888`. | Live Project 8 evidence remains separate. |
| Monitoring metrics first-run sufficiency | Missing enforcement | Gate: exporter, importer, analyzer, and privacy tests exist. Owner: ops-readiness. Evidence: archive tests and OWH-only findings. | gap:monitoring-metrics-sufficiency — requires one valid non-empty target run export, import, analysis, and reviewed findings. |
| Monitoring longitudinal sufficiency | Missing enforcement | Gate: archive analyzer can compare runs. Owner: ops-readiness. Evidence: analyzer tests and archive plan. | gap:monitoring-longitudinal-sufficiency — requires at least two valid runs and does not block the first run. |
| Project 8 real-run evidence | Missing enforcement | Gate: mandatory telemetry preflight exists. Owner: ops-readiness. Evidence: Project 8 first-run findings and preflight runbook. | gap:project-8-real-run-evidence — requires a fresh instrumented Project 8 session and non-empty analyzed bundle. |
| Remote multi-repository telemetry dispatch | Partially enforced | Gate: dispatcher fixtures cover attribution, isolation, policy, failures, and PR matching. Owner: ops-readiness. Evidence: PR #250 and failed live attempt. | gap:dispatch-scope-double-record and gap:multirepo-remote-telemetry-validation — fresh successful Remote evidence is required. |
| Engineering OS repository boundary hook synchronization | Missing enforcement | Gate: exact patcher verification exists. Owner: install-governance. Evidence: patch-settings-telemetry.py. | gap:eos-repo-boundary-sync-drift — checked-in boundary commands remain stale. |
| Full-readiness claim semantics | Missing enforcement | Gate: audit structure is validated. Owner: ops-readiness. Evidence: readiness-claim contract. | gap:full-readiness-claim-semantics — no assertion mode rejects a full-ready claim while blocking gaps remain. |
| Project 8 behavioral blindness | Missing enforcement | Gate: Project 8 PR #9 adds a product-only Markdown boundary. Owner: ops-readiness. Evidence: target main and PR #9. | gap:project8-experiment-blindness — local guidance coaches and discloses the run until PR #9 is merged and post-merge validated. |
| Project 8 workload acceptance | Missing enforcement | Gate: baseline CI and isolated Postgres foundation exist. Owner: product-readiness. Evidence: Project 8 PRs #4/#6/#9. | gap:project8-workload-acceptance — Supabase runtime, Vercel deployment, asset reuse, all-feature E2E, UI/UX, UTF-8/RTL, and post-deploy evidence remain required. |
| Git/branch policy | Enforced | Gate: pr-policy. Owner: merge-governance. Evidence: merge readiness artifact. | Live state is reviewed. |
| PR review / external review | Enforced | Gate: check-pr-review-evidence.sh through pr-policy. Owner: review-governance. Evidence: review fixtures. | Review depth is human. |
| Merge safety | Manual by design | Gate: owner decision. Owner: merge-governance. Evidence: Checklist: `docs/operations/merge-readiness-checklist.md`. | Human approval is intentional. |
| Post-merge validation | Enforced | Gate: post-merge-validation workflow. Owner: merge-governance. Evidence: repair-path fixtures. | Live failures use the incident checklist. |
| Known gaps register | Enforced | Gate: check-known-gaps.sh. Owner: ops-readiness. Evidence: schema and ledger fixtures. | Closure judgment is reviewed. |

## Definition of full operational readiness

A full-readiness claim is permitted only when all of the following are true:

- every matrix row is `Enforced`, `Manual by design` with an existing checklist, `Waiver-gated` with valid scoped evidence, or `Not applicable`;
- no blocking gap remains `open`, `blocked`, or `mitigated`;
- every closure cites exact implementation, positive and negative validation, exact-head CI, review reconciliation, merge evidence, and post-merge validation where relevant;
- live external state is rechecked immediately before the claim;
- Product 8 experiment evidence and product outcome evidence are not conflated with Engineering OS policy-fixture evidence.

The current repository does **not** satisfy this definition.

## Mandatory end-to-end closure checklists

A gap may move to `closed` only when every checkbox in its section is checked with an exact file, commit, PR, workflow run, artifact, provider resource identifier, or test output. A PR-body statement without linked evidence is insufficient.

### gap:audit-live-state-verification — P0

Official basis: GitHub status checks attach to exact commits, and skipped jobs can report success. Reference: <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks>.

- [ ] Extend the canonical known-gaps validation path; do not create a second registry.
- [ ] Bind every closure claim naming a PR, commit, merge, or workflow to an expected repository and exact identifier.
- [ ] In CI, fetch PR state, merged time, merge commit, exact head SHA, and named check conclusions.
- [ ] Fail when registry and audit agree but contradict live GitHub state.
- [ ] Fail for self-only `pr-policy`, skipped-job, stale-head, or generic “all checks passed” evidence.
- [ ] Pass only when the referenced PR/commit is present on `main` and intended non-self checks succeeded.
- [ ] Add offline positive/negative fixtures, including the historical stale #253 case.
- [ ] Run known-gap, readiness, full enforcement, exact-head review, merge, and post-merge validation.

### gap:hard-hook-fail-closed — P0

Official basis: Claude Code documents that `PreToolUse` blocks only with `exit 2` or a valid deny decision. Reference: <https://code.claude.com/docs/en/hooks>.

- [ ] Make a missing hard enforcer block instead of returning success.
- [ ] Make deny-conversion/interpreter/runtime failure block with `exit 2` and a concrete reason.
- [ ] Preserve fail-open behavior only for explicitly advisory, recorder, or soft lifecycle units.
- [ ] Verify every hard PreToolUse path runs the JSON guard first and is not soft-wrapped.
- [ ] Add missing-enforcer, converter-failure, malformed-input, policy-violation, and normal-success fixtures.
- [ ] Exercise the installed target-project copy, not only the source wrapper.
- [ ] Run hook-classification, clean-install, full enforcement, exact-head review, merge, and post-merge validation.

### gap:bypass-approval-provenance — P1

- [ ] Define one canonical waiver record: bypass name, stable decision/approval reference, reason, bounded target/action scope, issuer, creation time, and expiry or one-shot semantics.
- [ ] Reject truthy `EOS_BYPASS_*` without a complete matching record.
- [ ] Reject blank/generic reason, wrong bypass, wrong target, stale scope, forged record, and master-bypass substitution.
- [ ] Record accepted metadata in the evidence ledger without secrets or conversation content.
- [ ] Surface every accepted bypass in Stop and PR evidence and prevent normal completion until reconciled.
- [ ] Add all positive and negative fixtures; run workflow/evidence/install/full suites and post-merge validation.

### gap:pattern-registry-canonical-drift — P1

- [ ] Declare `patterns/registry.yaml` canonical for identity, domain, lifecycle status, score, version, usage count, and evidence.
- [ ] Declare domain README files canonical for implementation, examples, security, and testing guidance.
- [ ] Remove the statement that there is no YAML registry.
- [ ] Align connector policy, patterns README, scoring guide, and required-pattern checker.
- [ ] Add a documentation-hygiene negative fixture for the contradiction.
- [ ] Verify every registry path exists and every domain is non-empty; run all related tests and post-merge validation.

### gap:full-readiness-claim-semantics — P1

- [ ] Add `--assert-full-ready` or equivalent to the canonical readiness checker.
- [ ] Keep normal audit validation capable of passing an honestly incomplete audit.
- [ ] Make full-ready assertion fail for blocking non-closed gaps and missing/partial enforcement.
- [ ] Fixture-test every allowed non-blocking exception; no silent exception.
- [ ] Add a negative fixture where registration is complete but one gap remains open.
- [ ] Add a positive fully-ready fixture and wire the assertion to any release/readiness claim path.
- [ ] Run readiness/known-gap/full suites, exact-head review, merge, and post-merge validation.

### gap:project8-experiment-blindness — P0 and experiment-start blocker

Current evidence: Project 8 main contains `CLAUDE.md`, `docs/engineering-os/project-8-audit.md`, and `docs/engineering-os/claude-project-8-prompt.md`; the prompt explicitly discloses the experiment and prescribes Engineering OS behavior. PR #9 removes tracked Markdown guidance and retains machine-readable runtime telemetry.

- [ ] Verify PR #9 changed paths are limited to the reviewed product-boundary/runtime scope and contain no product behavior change.
- [ ] Verify exact head `51970629f3c3af32cb73bea0aab676874478248d` has successful `pr-policy`, `baseline-ci`, semantic-cleanup, and import-cleanup checks.
- [ ] Classify the failing Azure deploy workflow as obsolete-provider evidence; do not treat it as Vercel success and do not silently ignore it.
- [ ] Verify every current and outdated review thread is resolved and each valid finding has a regression.
- [ ] Obtain explicit owner approval and merge PR #9 with expected head SHA.
- [ ] Verify `project-8/main` contains no tracked Markdown prompt, audit, plan, README, or local Engineering OS coaching file.
- [ ] Verify the product-boundary checker blocks reintroduction.
- [ ] Verify machine-readable settings/policy contain no experiment description or task-routing instructions.
- [ ] Install the current Engineering OS runtime, close old sessions, and open a genuinely fresh Claude session.
- [ ] Prove through `InstructionsLoaded` metadata or equivalent that removed guidance was not loaded.
- [ ] Supply only the product workload prompt; it must not mention experiment, evaluation, telemetry objectives, expected skills/connectors/templates, Route Plan fields, or internal closure criteria.

### gap:project-8-real-run-evidence — P1 and experiment-start blocker

Official basis: `SessionStart` initializes session state; workflow artifacts persist outputs but are transport evidence, not the archive. References: <https://code.claude.com/docs/en/hooks> and <https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts>.

- [ ] Update the actual `ENGINEERING_OS_HOME` checkout to the exact merged Engineering OS main head.
- [ ] Install user-level telemetry hooks from that checkout and pass installer `--verify`.
- [ ] Verify Project 8 required telemetry policy is schema-valid and targets `origin` / `engineering-os-telemetry`.
- [ ] Close every prior Claude session and open a new one after installation.
- [ ] Before product work, run `require-telemetry-session.sh`.
- [ ] Require positive `telemetry session ready` and `telemetry remote handoff ready` counts, including a positive boundary count.
- [ ] Run one bounded real task without `--empty-run` or fabricated events.
- [ ] Match local run ID, repository, branch, head, policy, and handoff state.
- [ ] Match the non-empty telemetry-branch bundle to the exact product PR/head.
- [ ] Require pr-policy to select only `manifest.json`, `events.jsonl`, and `latest-summary.md`.
- [ ] Require positive counts in both session artifact and Operational Work History.
- [ ] Prove metadata-only privacy: no prompt, response, command, path, payload, env value, API key, or secret.
- [ ] Import the exact bundle, run the analyzer, and review `findings.md` for coverage, friction, false positives, decision quality, and product outcome.

### gap:multirepo-remote-telemetry-validation and gap:dispatch-scope-double-record — P1

- [ ] Start a fresh Remote session only after exact dispatcher installation verification.
- [ ] Prove managed repositories initialize and unmanaged siblings create no telemetry state.
- [ ] Prove explicit filesystem/repository identities agree; malformed/conflicting identities remain unattributed.
- [ ] Prove unrelated activity is not attributed or blocked.
- [ ] Prove distinct run IDs and shared host correlation only.
- [ ] Revoke a marker mid-session and prove attribution/fan-out stops.
- [ ] Complete all lifecycle boundaries and surface required handoff failures without suppressing sibling recording.
- [ ] Produce exact-match non-empty bundles and prove PR selection cannot cross repositories.
- [ ] Review all diagnostics against the metadata-only contract before closure.

### gap:monitoring-metrics-sufficiency — P2

- [ ] Complete the fresh Project 8 run checklist.
- [ ] Import one non-empty checksum-valid identity-matched bundle.
- [ ] Run and preserve analyzer output.
- [ ] Separate Engineering OS behavior, Operational Work History, and product outcomes.
- [ ] Record event coverage, missing events, tools/connectors, failures, friction, false positives, and decision quality.
- [ ] Pass privacy and duplicate-run checks.
- [ ] Close only after review confirms the fields answer the first-run research questions.

### gap:monitoring-longitudinal-sufficiency — P2, not a first-run blocker

- [ ] Import at least one later valid run using the same schema/privacy contract.
- [ ] Compare at least two runs across event coverage, tools/connectors, failures, retries, friction, decision quality, and product outcome.
- [ ] Separate recurring blind spots from one-off failures.
- [ ] Record whether Engineering OS changes improved, worsened, or did not change behavior.
- [ ] Create follow-up enforcement or document why the recurring issue is manual by design.
- [ ] Close only when comparison is reproducible from archived bundles.

### gap:eos-repo-boundary-sync-drift — P3

- [ ] Patch Engineering OS `.claude/settings.json` through the canonical direct-mode patcher.
- [ ] Verify catch-all PreToolUse guard/recorder, SessionStart, Stop, StopFailure, and SessionEnd commands exactly.
- [ ] Ensure terminal events record and synchronize boundaries, not only events.
- [ ] Pass patcher verify, trust-boundary, archive, hook-classification, and full suites.
- [ ] Keep this change separate from Product 8 workload implementation.
- [ ] Complete exact-head review, merge, and post-merge validation before enabling telemetry in Engineering OS itself.

### gap:project8-workload-acceptance — P1, experiment workload completion gate

This section does not block opening the instrumented session after the blindness and telemetry prerequisites pass. It blocks declaring the Project 8 workload successful.

Official implementation basis:

- Vercel environments and variables: <https://vercel.com/docs/deployments/environments> and <https://vercel.com/docs/environment-variables>.
- Vercel Vite, Express, monorepos, and domains: <https://vercel.com/docs/frameworks/frontend/vite>, <https://vercel.com/docs/frameworks/backend/express>, <https://vercel.com/docs/monorepos>, and <https://vercel.com/docs/domains/set-up-custom-domain>.
- Supabase RLS, API keys, secure data, and Postgres connections: <https://supabase.com/docs/guides/database/postgres/row-level-security>, <https://supabase.com/docs/guides/getting-started/api-keys>, <https://supabase.com/docs/guides/database/secure-data>, and <https://supabase.com/docs/guides/database/connecting-to-postgres>.
- Prisma with Supabase: <https://www.prisma.io/docs/orm/v6/overview/databases/supabase>.
- Playwright: <https://playwright.dev/docs/intro>.
- W3C accessible forms: <https://www.w3.org/WAI/tutorials/forms/>.

#### Existing assets and secrets

- [ ] Inventory existing Vercel team/project ID, framework/root/build/output settings, environments, deployments, aliases, domains, and linked repository.
- [ ] Inventory existing Supabase project reference, schemas, migrations, auth/storage use, URL/key presence, and pooled/direct connection types.
- [ ] Inventory GitHub Actions secret/variable names, environments, domain configuration, provider workflows, and all application API-key names.
- [ ] Record only name, presence, scope, last validation result, and intended use; never output secret values.
- [ ] Reuse every valid URL, domain, API key, provider resource, and integration; create/rotate/remove only with reason and rollback.
- [ ] Prove no secret enters source, Markdown, logs, artifacts, screenshots, browser bundles, or client-exposed variables.

#### Supabase/Postgres runtime completion

- [ ] Re-run and preserve the isolated Postgres foundation tests before cutover.
- [ ] Map every remaining SQL Server/T-SQL assumption to an exact file and test.
- [ ] Remove active-path `dbo`, `UNIQUEIDENTIFIER`, `NVARCHAR`, `DATETIME2`, bracketed identifiers, SQL Server builders, and Azure SQL defaults unless explicitly isolated for rollback.
- [ ] Select one final Prisma/Supabase runtime boundary; do not retain two active database architectures.
- [ ] Use pooled `DATABASE_URL` for runtime and direct `DIRECT_URL` for migration/introspection without exposing values.
- [ ] Apply versioned migrations to the intended Supabase project and verify live migration history.
- [ ] Enable and force RLS where required on every exposed tenant table.
- [ ] Add least-privilege policies and prove cross-tenant reads/writes fail under non-elevated identities.
- [ ] Prove secret/service-role credentials remain server-only and publishable credentials cannot bypass RLS.
- [ ] Validate every existing server route/background behavior against Supabase/Postgres.
- [ ] Remove/quarantine obsolete Azure SQL runtime only after data, rollback, and live-cutover evidence exists.

#### Vercel deployment completion

- [ ] Link to the valid existing Vercel project instead of creating a duplicate.
- [ ] Select the smallest supported Vite/Express/monorepo shape and record root, build, output, routing, and function boundaries.
- [ ] Map every required variable to Development, Preview, and Production by name/scope without values.
- [ ] Redeploy after environment-variable changes.
- [ ] Deploy the exact PR head to a commit-specific preview URL.
- [ ] Run API, database, and browser E2E against that URL.
- [ ] Reuse and verify the existing production domain/URL; inspect DNS before modifying records.
- [ ] Prove build, functions, static assets, API routing, cookies, CORS, auth redirects, and database connectivity from live logs/checks.
- [ ] Keep Azure only as rollback until Vercel production validation passes; then prevent Azure from silently deploying the active branch.

#### Feature, UI/UX, encoding, and end-to-end validation

- [ ] Build a feature inventory from real server routes, client routes, navigation, tests, and integrations.
- [ ] Give every existing feature one status: passing, failing, externally blocked with evidence, or intentionally removed with owner approval.
- [ ] Add/repair API and integration tests for all provider/database-affected paths.
- [ ] Add/repair Playwright flows for all product features present, including auth, business setup, public booking, appointments, settings, dashboard/statistics, customers, waitlist, cancellation/rescheduling, notifications/integrations, legal/cookies, and error states.
- [ ] Run critical flows in Chromium, WebKit, Firefox, and a mobile viewport.
- [ ] Validate Hebrew UTF-8 integrity, RTL, translations, date/time/timezone, responsiveness, keyboard/focus, labels, validation, loading/empty/error states, and no clipping/overlap.
- [ ] Capture screenshots or traces for every major public and owner flow on the exact preview deployment.
- [ ] Fix all revealed runtime, API, data, UI/UX, and encoding defects; never skip/delete/weaken a failing test to get green CI.
- [ ] Re-run server, client, Supabase/Postgres, build, UTF-8, E2E, security, cleanup, and policy suites after the final fix.
- [ ] Perform exact-diff self-review and reconcile CodeRabbit/review threads when available.
- [ ] Record exact-head CI, preview/production URLs, provider project identifiers, migration/RLS evidence, test counts, screenshots/traces, residual risk, and rollback.
- [ ] Obtain explicit approval before merge/production deployment; merge with expected head SHA and run post-merge plus production smoke validation.

## Highest-priority gaps by ROI

1. Hard-hook fail-closed — P0.
2. Project 8 experiment blindness — P0.
3. Audit live-state verification — P0.
4. Project 8 fresh telemetry and Remote validation — P1.
5. Project 8 Supabase/Vercel and all-feature workload acceptance — P1.
6. Bypass provenance, pattern canonical ownership, and readiness-claim semantics — P1.
7. First-run monitoring sufficiency — P2.
8. Longitudinal monitoring — P2 and not a first-run blocker.
9. Engineering OS boundary synchronization — P3.

Closed regression surfaces retained by the readiness gate: coverage map hardening; RTK runtime hardening; route plan quality gate; learning closure gate; progress lifecycle; connector correctness; simulation completeness; post-merge validation; documentation hygiene; semantic cleanup.

## Experiment start decision

The next Project 8 behavioral run is blocked until every checkbox in `gap:project8-experiment-blindness` and the installation/preflight portion of `gap:project-8-real-run-evidence` is complete.

The prompt supplied to Claude may state the product objective and require verification that the latest Engineering OS version is installed. It must not mention experiment/evaluation, telemetry research, expected Engineering OS behavior, specific internal skills/connectors/templates, Route Plan fields, or these internal checklists.

## Current audit scope

Engineering OS PR #253 is merged and closes canonical telemetry trust-boundary implementation. Current blockers are hard-hook semantics, live audit truth, bypass provenance, canonical pattern ownership, honest full-readiness claims, Project 8 blindness, fresh-session telemetry, Remote observation, and the real Supabase/Vercel/product workload. Project 8 PR #9 is green on its required product/policy checks with resolved review threads but remains unmerged; its failing legacy Azure workflow is not Vercel success evidence and must be explicitly classified.