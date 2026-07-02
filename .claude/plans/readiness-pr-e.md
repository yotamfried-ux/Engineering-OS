# Readiness PR E — install downstream behavior

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance |
| Domain tags | readiness, enforcement, governance, install |
| Task-router evidence | core/task-router.md checked; routed via routing_matrix section 7 |
| Workflow evidence | core/workflow.md checked; plan-file fallback carries the spec |
| Target paths | scripts/install-policy-gates.sh, scripts/enforcement/policy-gate-dependencies.tsv, scripts/enforcement/tests/test-clean-install-and-usage.sh, scripts/enforcement/tests/test-install-policy-gate-coverage.sh, scripts/use-in-project.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, documentation-asset-policy, plan-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

PR E closes the final open gap, `gap:install-downstream-behavior`: the install contract validates output shape (files exist, settings.json has the right hook wiring), but downstream runtime behavior in a generated target project is untested — and PR D's review just proved this concretely: `install-policy-gates.sh` copied only `pr-policy.yml`'s new script dependency, leaving `connector-evidence-policy.yml`, `workflow-evidence-policy.yml`, `capability-evidence-policy.yml`, and `documentation-asset-policy.yml` with the identical latent bug (each calls a `scripts/enforcement/*.sh` script that is never copied to the installed target, so the CI step exits 127 before validating anything). This PR:

1. Replaces the one-off hardcoded copy (added ad hoc in PR D for `check-pr-review-evidence.sh`) with a manifest-driven mechanism (`policy-gate-dependencies.tsv`) that copies every script/data dependency each installed workflow needs — so a future new gate dependency is a manifest row, not a forgotten copy block.
2. Extends `test-clean-install-and-usage.sh` with downstream-behavior fixtures per the gap's own description: tool fallbacks (RTK/graphify absent from PATH), slash commands present and parseable, the learning-loop gate fires in the generated target, templates/patterns are reachable, and `enforce-tests.sh`'s missing-tool environment contract (from PR C) behaves correctly inside the target.
3. Adds a coverage fixture that fails closed if a workflow's `bash scripts/enforcement/...` dependency is not listed in the manifest, so this specific bug class cannot silently recur.

## Alternatives

- Keep the one-off `check-pr-review-evidence.sh` copy from PR D and add three more hardcoded copy blocks for the other three scripts — rejected: same failure mode as the original bug (a fifth gate added later would again be silently forgotten); a manifest with a coverage fixture makes the omission itself a test failure.
- Have each installed workflow `curl`/fetch its script from the Engineering OS GitHub repo at CI time instead of copying at install time — rejected: adds a network dependency and a supply-chain surface to every downstream CI run; copying at install time keeps the target repo self-contained, matching the existing pattern for workflow YAMLs themselves.
- Skip the RTK/graphify/learning-loop/templates downstream-behavior fixtures and only fix the manifest-copy bug — rejected: `gap:install-downstream-behavior`'s own closure criteria in `known-gaps.tsv` requires fallback, commands, learning loop, and gates to be covered, not just the script-copy issue found in PR D's review.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read this session before writes.
- `workflow.workflow-read` — core/workflow.md read this session before writes.
- `plan.route-plan-before-write` — this plan is committed before the first code change of PR E.
- `source.github-repo-read` — GitHub MCP read merged main state (PR #181/#182/#183 merge commits, known-gaps.tsv, operational-readiness-audit.md) before branching for PR E.
- `validation.policy-change-has-validator` — the manifest-driven install-copy mechanism and every new downstream-behavior claim ship with fixture tests.
- `validation.actions-checked` — CI results for the head SHA are verified before merge readiness.
- `validation.coderabbit-policy` — dedicated branch, draft PR, review evidence in PR body, merge only on explicit approval.

## Connector Evidence

- github: read merged main state (PR #181/#182/#183 merge commits, known-gaps.tsv, operational-readiness-audit.md) via MCP before branching.

## Connector Selection Waiver

Notion is required for governance-class work by connector policy, but the Notion MCP connector is unavailable in this remote session environment; the approved fallback from core/workflow.md stage 1 applies — this plan file under .claude/plans/ carries the spec and progress validation.

## Connector Usage Evidence

- source: github repository yotamfried-ux/Engineering-OS — docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/install-policy-gates.sh, scripts/use-in-project.sh, .github/workflows/*.yml.
- action: github MCP get_file_contents confirmed the merged PR D state, the single remaining open gap row, and re-read every policy workflow YAML to enumerate their `scripts/enforcement/*` dependencies.
- result: four workflows (connector/workflow/capability/documentation-asset-evidence-policy) share the exact install-copy gap PR D's reviewers found in pr-policy.yml; capability-evidence-policy.yml alone depends on two scripts plus a TSV manifest plus core/capability-registry.yaml.
- decision: github findings selected the PR E scope — a manifest-driven copy mechanism covering all five dependency sets, a coverage fixture, and the four downstream-behavior categories named in the gap's closure criteria.
- target: scripts/install-policy-gates.sh, scripts/enforcement/policy-gate-dependencies.tsv, scripts/enforcement/tests/test-clean-install-and-usage.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/install-policy-gates.sh, scripts/use-in-project.sh, all six .github/workflows/*.yml policy files.
- context7: not required because this change edits internal Engineering OS governance/install tooling (bash scripts and a TSV manifest) and does not implement or integrate any external library, framework, SDK, or API.
- decision: the existing per-workflow `bash scripts/enforcement/...` call sites fixed the exact dependency list for the manifest (enumerated directly from each workflow's steps, not guessed), and the existing test-clean-install-and-usage.sh fixture structure fixed the shape of the new downstream-behavior assertions.

## Graphify Usage Evidence

- source: graphify query over graphify-out/graph.json for install/use-in-project/policy-gate wiring.
- action: graphify query oriented the installer-to-workflow dependency map before reading install-policy-gates.sh, use-in-project.sh, and all policy workflow YAMLs.
- result: the graph confirmed install-policy-gates.sh and use-in-project.sh have no shared dependency-manifest concept yet — the PR D fix was a standalone hardcoded block, consistent with the gap being genuinely unaddressed until now.
- decision: graph finding confirmed a manifest file is a new artifact (not a rename), so this PR must add both the manifest and its own coverage fixture rather than only extending an existing list.
- target: scripts, scripts/enforcement, scripts/enforcement/tests, .github/workflows

## Template Gap Waiver

No project template applies: this is internal governance/enforcement maintenance inside Engineering OS itself; templates/ entries cover application project scaffolds and are out of scope for installer edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/install-policy-gates.sh | checked |
| scripts/use-in-project.sh | checked |
| .github/workflows/pr-policy.yml | checked |
| .github/workflows/connector-evidence-policy.yml | checked |
| .github/workflows/workflow-evidence-policy.yml | checked |
| .github/workflows/capability-evidence-policy.yml | checked |
| .github/workflows/documentation-asset-policy.yml | checked |
| .github/workflows/plan-policy.yml | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |

## Claude Run Trace

- goal: close gap:install-downstream-behavior with a manifest-driven install-copy mechanism plus fixture coverage for tool fallbacks, commands, learning loop, and gates in a generated target.
- hypothesis: a TSV manifest mapping workflow → dependency paths, read by install-policy-gates.sh and copied alongside each workflow YAML, generalizes the PR D one-off fix and closes the same bug class for the other three affected workflows; a coverage fixture that cross-checks every workflow's actual `bash scripts/enforcement/...` call against the manifest prevents a fifth occurrence.
- connectors: github MCP confirmed merged main state and the single remaining open gap before branching; notion_progress_validated: waived — Notion unavailable in this environment, plan-file fallback carries progress validation per the Connector Selection Waiver.
- steps: enumerate every workflow's scripts/enforcement dependency; write policy-gate-dependencies.tsv; rewrite install-policy-gates.sh's copy loop to be manifest-driven (replacing the PR D hardcoded block); add a coverage fixture; extend test-clean-install-and-usage.sh with an installed-target smoke check per workflow, RTK/graphify PATH-absence fallback, command-file parse checks, a learning-loop-gate-fires-in-target fixture, templates/patterns reachability, and the enforce-tests.sh missing-tool contract inside the target; flip the gap to closed; update the audit row.
- evidence: scripts/install-policy-gates.sh, scripts/enforcement/policy-gate-dependencies.tsv, scripts/enforcement/tests/test-clean-install-and-usage.sh, scripts/enforcement/tests/test-install-policy-gate-coverage.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.
- rejected: per-request script fetching over the network, and fixing only the copy bug without the gap's own closure criteria (fallback/commands/learning-loop/gates), were rejected as adding a supply-chain surface and as an incomplete closure respectively.
- result: pending — recorded once the manifest, installer rewrite, and fixtures land and the full suite is green.
- follow-up: none — this is the final PR in the A–E readiness program; closure completes docs/operations/known-gaps.tsv with 0 open rows.

## Progress Lifecycle Evidence

- start: plan committed on claude/engineering-os-readiness-pr-c (reused for PR E after branch-deletion was blocked at the git-proxy level, same as PR D's branch reuse on pr-b; see Scope note below) before any script, manifest, or test edits.

## Lessons Reused

- lessons-learned/bugs/ci-environment-dependent-fixture-premise.md
  - Applied because: this PR adds new fixtures under scripts/enforcement/tests exercising tool-absence (RTK/graphify not on PATH) and missing-tool CI contracts inside a generated target — exactly the environment-dependent-premise class this lesson covers.
  - Prevention: construct PATH-absence and missing-tool scenarios hermetically (a scoped PATH override in the fixture, not assuming the host container's actual tool inventory) so the fixtures run identically in CI and in this local container.

## DoD

- [ ] policy-gate-dependencies.tsv lists every scripts/enforcement/* and core/* dependency each installed workflow YAML actually calls, enumerated from the workflow files themselves — verified by test-install-policy-gate-coverage.sh cross-checking manifest rows against live `bash scripts/enforcement/...` call sites in .github/workflows/*.yml.
- [ ] install-policy-gates.sh copies every manifest-declared dependency for each installed workflow, preserving directory structure and executable bits — verified by an installed-target smoke check per workflow in test-clean-install-and-usage.sh.
- [ ] RTK/graphify absence from PATH does not crash installed hooks (they warn/no-op per contract) — verified by a PATH-absence fixture in test-clean-install-and-usage.sh.
- [ ] Installed slash-command files exist and parse (non-empty, valid markdown with the expected command structure) — verified by a command-parse fixture.
- [ ] The learning-loop gate fires in the generated target: a fixture bug-fix commit without a lesson citation is blocked by the installed hooks — verified by a learning-loop fixture.
- [ ] templates/ and patterns/ are reachable from the installed target via the reference path recorded in CLAUDE.md's managed block — verified by a reachability fixture.
- [ ] enforce-tests.sh's missing-tool environment contract (hard-fail in CI, named-waiver locally) behaves correctly when invoked inside the generated target — verified by a fixture reusing the PR C contract.
- [ ] gap:install-downstream-behavior flipped to closed with concrete artifacts; audit row "Project install contract" updated; check-readiness-audit.sh and check-known-gaps.sh green.
- [ ] Full local enforcement suite green except the known pre-existing test-plan-scope environment case.
- [ ] Draft PR opened with review evidence; merge deferred to explicit approval.

## Scope note — branch reuse

PR A's branch was deleted after explicit authorization; PR B/PR C's merged branches could not be deleted (`git push origin --delete` returns HTTP 403 from the git proxy, confirmed on repeated attempts across this session even with explicit user authorization to delete). PR D reused `claude/engineering-os-readiness-pr-b` (reset to fresh main) under explicit user decision. PR E reuses `claude/engineering-os-readiness-pr-c` the same way, under a separate explicit user decision for this specific branch, satisfying the one-branch policy without a policy bypass.

## Completed Work

(none yet — plan committed before first code change)

## Remaining Validation Outside This Plan

- None — this closes the final open gap in the A–E readiness program. `docs/operations/known-gaps.tsv` should show 0 open rows after this PR merges.
