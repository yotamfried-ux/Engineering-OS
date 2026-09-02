# Route Plan — Bash suite runtime evidence keys on the work

Plan Scope: standard
Plan Timestamp: 2026-09-02T03:27:26Z
Planning Mode: approved

## Route Plan

| Field | Decision |
|---|---|
| Task type | enforcement correctness fix — operational runtime evidence must key on executed work, not on the invocation mechanism |
| Task class | `engineering_os_governance` |
| Domain tags | testing, observability, workflow, governance, enforcement hooks, runtime evidence, known-gaps registry |
| Plan Scope | standard |
| Plan Timestamp | 2026-09-02T03:27:26Z |
| Planning Mode | approved |
| Task-router evidence | `core/task-router.md` § 7 routes Engineering OS maintenance/governance through CLAUDE.md, workflow, skill-orchestration, connector, learning-loop and hooks policy, and adds the rule that an OS change must strengthen the enforcement layer rather than add explanatory text. This change adds one recorder, one reconciler and one CI gate. |
| Workflow evidence | `core/workflow.md` (plan-first writes, `<evidence_backed_planning>` Plan Timestamp contract), `core/hooks-policy.md` (G11 consumes `tests_run`; recorder units are `false_evidence_safe`), `core/quality-gates.md` (CI-dependent items belong under Live External Gates), `core/git-policy.md` (branch → draft PR → review → owner approval). |
| Target paths | `scripts/enforcement/lib/test-run-evidence.sh`; `scripts/enforcement/lib/bash_test_invocation.py`; `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/post-tool-use-skill-evidence.sh`; `scripts/enforcement/post-tool-use-read-evidence.sh`; `scripts/enforcement/run-enforcement-tests.sh`; `scripts/enforcement/test_evidence.py`; `scripts/enforcement/check-bash-runtime-evidence.sh`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/test-evidence-levels.tsv`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/enforcement/coverage-required-gates.tsv`; `scripts/enforcement/simulation-coverage.tsv`; `scripts/enforcement/tests/test-bash-runtime-evidence.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`; `.claude/settings.json`; `.github/workflows/enforcement-tests.yml`; `core/hooks-policy.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `lessons-learned/bugs/evidence-keyed-on-mechanism.md` |
| Templates | waiver — focused correctness fix inside existing enforcement recorders plus one new reconciler; no project or scaffold template applies (see Template Gap Waiver). |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | `patterns/testing/README.md` |
| External systems/connectors | GitHub |
| Skills | `engineering-route` |
| Validation gates | `scripts/enforcement/tests/test-bash-runtime-evidence.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`; full corpus with execution receipts; `check-bash-runtime-evidence.sh` reconciliation on the exact head in CI; `check-known-gaps.sh`; `check-readiness-audit.sh`; `check-hard-hook-contract.py`. |
| Evidence to check | live reproduction of the wrapped-command miss recorded below; `run-enforcement-tests.sh` receipts; `hook-criticality.tsv` as the canonical hook-set owner. |
| User decisions required | one, asked and answered — how the registry should represent the second instance of the defect class (see Decision Record). |

## Capability Evidence

Task class: `engineering_os_governance` — the change alters deterministic recorder and gate
behaviour under `scripts/enforcement/`, so it runs the full plan → branch → draft PR →
review → owner-approval path with executable positive and negative evidence.

- `routing.task-router-read` — `core/task-router.md` read this session before any write; its
  § 7 rule ("an OS change must strengthen the decision/enforcement layer, not only add
  explanatory text") is why this change ships a recorder, a reconciler and a CI gate rather
  than a documentation note about the gap.
- `workflow.workflow-read` — `core/workflow.md` read this session; `<evidence_backed_planning>`
  fixed this plan's Scope and the `Plan Timestamp` field, and step 6 ("verification through
  the right tool") is the step the second defect instance silently defeats.
- `plan.route-plan-before-write` — this route plan is created and committed before the first
  code change; `check-workflow-evidence.sh` requires the plan commit to precede the first
  code commit on the branch and the branch history is ordered that way.
- `source.github-repo-read` — repository state read through git and the GitHub connector:
  `main` at `aaa2fba184e4847718a94b14e0b605de0739b4e8`, PR #278 as the merged phase-2 work
  with reviewed head `c6ace6f4e2d8d270cc9c14cb47c839a059990b27`, and the live PR opened for
  this branch with its exact-head check runs and review threads.
- `validation.policy-change-has-validator` — `scripts/enforcement/tests/test-bash-runtime-evidence.sh`
  is added as the executable validator for the new contract, including the negative fixture
  that proves a missing runtime record is detected rather than tolerated, and
  `scripts/enforcement/check-bash-runtime-evidence.sh` is the CI-side reconciler.
- `validation.actions-checked` — this change edits `.github/workflows/enforcement-tests.yml`,
  adding the exact-head reconciliation step, so GitHub Actions state is part of the required
  path: the live check runs on this branch's head are read through the GitHub connector, and
  PR #278's 23/23 green checks plus the post-merge runs on `main` (`post-merge-validation`
  run 106, `enforcement-tests` run 1660, `known-gaps-live-state` run 77,
  `telemetry-handoff-tests` run 562) are the evidence used to close the phase-2 gap.
- `validation.coderabbit-policy` — the repository has fewer than 10 stars, so CodeRabbit does
  not auto-review; per `core/coderabbit-policy.md` the fallback is a recorded manual review in
  the PR body, and the PR stays draft and unmerged until review and explicit owner approval.

## Graphify Usage Evidence

- source: graphify query over `graphify-out/graph.json` (1725 nodes), start set
  `post-tool-use-bash.sh`, `evidence.sh`, `test_evidence.py`, `check-runtime-evidence.sh`,
  `run-post-merge-validation-suite.sh`, `test-post-tool-use-bash-evidence.sh`
- action: graphify BFS depth=2 traversal of the evidence-recording surface to find every
  producer and consumer of the session evidence ledger, and to check whether "a Bash suite
  ran" has an owner anywhere other than the PostToolUse command-text matcher
- result: the graph showed `evidence_record` has exactly three Bash-side producers
  (`post-tool-use-bash.sh`, `post-tool-use-read-evidence.sh`, `post-tool-use-mcp.sh`) and that
  `run-enforcement-tests.sh` — the component that actually executes the corpus and already
  writes per-suite receipts — is not connected to the ledger at all; the only path from "a
  suite ran" to "the session knows it ran" is the command string
- decision: the graph finding moved the primary fix off the regex entirely. Instead of only
  widening the matcher, the executing runner becomes the evidence producer
  (`lib/test-run-evidence.sh`), so wrapping the command cannot change what is recorded; the
  command scanner is demoted to covering direct single-suite invocations that never reach the
  runner
- target: scripts/enforcement/lib/test-run-evidence.sh, scripts/enforcement/lib/bash_test_invocation.py, scripts/enforcement/post-tool-use-bash.sh, scripts/enforcement/post-tool-use-skill-evidence.sh, scripts/enforcement/post-tool-use-read-evidence.sh, scripts/enforcement/run-enforcement-tests.sh, scripts/enforcement/test_evidence.py, scripts/enforcement/check-bash-runtime-evidence.sh, scripts/enforcement/hook-criticality.tsv, scripts/enforcement/test-evidence-levels.tsv, scripts/enforcement/patch-settings-runtime-evidence.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/tests, .claude/settings.json, .github/workflows/enforcement-tests.yml, core/hooks-policy.md, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, lessons-learned

## Source of Truth Checks

| Source | Status | What it settled |
|---|---|---|
| core/task-router.md | read | Routed this task to `engineering_os_governance` and fixed the rule that the change must strengthen enforcement, not add prose. |
| core/workflow.md | read | Plan Scope `standard`, the required plan sections, and the `Plan Timestamp` contract. |
| core/capability-registry.yaml | read | Supplied the six required capabilities for `engineering_os_governance`. |
| patterns/testing/README.md | read | Test-pyramid guidance: the new coverage is a fast fixture-level suite plus one integration-level reconciliation, not another end-to-end path. |
| scripts/enforcement/hook-criticality.tsv | validated | The canonical owner of the required hook set; every settings surface derives from it, so the new PostToolUse Skill recorder needs a row here before it can be wired anywhere. |
| scripts/enforcement/post-tool-use-bash.sh | read | `_eos_test_mode` uses `re.fullmatch` over the whole command; confirmed by experiment that a `cd` prefix defeats it. |
| scripts/enforcement/run-enforcement-tests.sh | read | Already executes each suite and writes per-suite receipts, but never touches the evidence ledger — the missing link. |
| scripts/enforcement/check-workflow-evidence.sh | validated | `docs/` is excluded from the "code" classification, which fixes the commit ordering used on this branch. |

## Connector Evidence

- GitHub — the only connector on the required path: reading repository and branch state,
  pushing `claude/bash-suite-runtime-evidence-tk1wp5`, opening the draft PR, and reading its
  exact-head check runs and review threads.
- Context7 — not required and not queried: the change introduces no external library,
  framework, package or version. It uses `git`, `python3` and POSIX shell builtins already
  relied on throughout `scripts/enforcement/`.
- Notion — not on the required path for this task; no Notion decision was taken, so no
  `notion_progress_validated` evidence applies.
- Nemotron MCP — configured but failed to connect this session (`CONNECTION_CLOSED`, proxy
  403 to `integrate.api.nvidia.com`). It is L1 optional and not on this task's required path,
  so the session continued without it per `core/connector-policy.md`'s fallback rule.

## Connector Usage Evidence

- source: GitHub — repository state, branch list, commit history, merged PR #278, and the
  live draft PR opened for this branch
- action: GitHub used to confirm `main` at `aaa2fba184e4847718a94b14e0b605de0739b4e8`, to
  recover PR #278's reviewed head, squash merge and check-run count for the
  `plan-freshness-clone-safety` closure evidence, to push this branch, and to read the live
  exact-head check runs and review threads on this PR
- result: GitHub supplied the exact closure facts the audit needs — PR #278 reviewed head
  `c6ace6f4e2d8d270cc9c14cb47c839a059990b27`, squash merge
  `aaa2fba184e4847718a94b14e0b605de0739b4e8`, 23/23 checks green on that head — none of which
  are derivable from the working tree
- decision: that GitHub evidence changed the work — it is why I updated
  `plan-freshness-clone-safety` from `open` to `closed` in `docs/operations/known-gaps.tsv`
  and changed the audit's "Route plan freshness and selection" row from Partially enforced to
  Enforced. Without the live reviewed head, merge commit, check count and post-merge run
  numbers the row would have been kept open, since none of them are derivable locally
- target: docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement, .github/workflows/enforcement-tests.yml, .claude/settings.json

## Documentation Asset Evidence

- internal: `core/task-router.md`, `core/workflow.md`, `core/hooks-policy.md`,
  `core/quality-gates.md`, `core/capability-registry.yaml`, `patterns/testing/README.md`,
  `scripts/enforcement/hook-criticality.tsv`, `scripts/enforcement/check-hard-hook-contract.py`,
  `scripts/enforcement/test-evidence-levels.tsv`, `docs/operations/known-gaps.tsv`, and
  `docs/operations/operational-readiness-audit.md`
- context7: not queried — no external library, framework, package or version is involved. The
  contract implemented here is defined by this repository's own policy files (hook criticality
  registry, evidence ledger library, test-evidence corpus), not by third-party documentation.
- decision: `hook-criticality.tsv` decided the shape of the second fix — because it is the
  single canonical owner of the required hook set and every settings surface is generated from
  it, the new PostToolUse `Skill` recorder is registered there first and only then wired into
  `.claude/settings.json` and `patch-settings-runtime-evidence.sh`; `test-evidence-levels.tsv`
  decided that the new suite is registered at `fixture` level rather than being left to the
  `static` default, because it drives the real recorder and the real reconciler.

## Template/Pattern Rating Evidence

- asset: `patterns/testing/README.md`
- rating: useful — applied, not merely opened
- outcome: its test-pyramid guidance shaped the shape of the new coverage rather than its
  existence. The bulk of `test-bash-runtime-evidence.sh` is fast, in-process classification
  and ledger assertions; exactly one section pays for a real subprocess corpus, and there is
  no end-to-end path. Its "mocking the thing under test means testing the mock" warning is
  why the disposable corpus copies and runs the *real* runner and the *real* reconciler
  instead of stubbing them.
- decision: kept the suite at one integration-level section over a disposable corpus and
  registered it as `integration` in `test-evidence-levels.tsv`, rather than promoting the
  whole suite or leaving it at the conservative `static` default.
- confidence: high — the guidance is general and was directly actionable here; no adaptation
  cost beyond choosing where the one subprocess-heavy section belongs.

## Skill Evidence

- `engineering-route` — invoked with this task before the first write; produced this plan's
  Route Plan, source-of-truth checks, capability evidence and waiver sections.

## Template Gap Waiver

No project or scaffold template applies: this is a correctness fix inside existing enforcement
recorders plus one new reconciler and its CI wiring. A new template would add surface without
reducing risk.

## Decision Record

- `decision_id: phase3-gap-class-scope` — asked once and answered by the owner: widen
  `bash-runtime-test-evidence` to the defect **class** ("operational evidence keys on an
  incidental mechanism rather than on the work itself") and name both instances in that one
  row, rather than registering the `superpowers_verify_run` instance as a separate gap.
  Status: answered. Not to be reopened without a material change.

## Progress Lifecycle Evidence

- start: Session opened on `main` at `aaa2fba` on branch
  `claude/bash-suite-runtime-evidence-tk1wp5`. Confirmed the corpus is 122 suites (117 Bash +
  5 Python), that `bash-runtime-test-evidence` is registered open and describes only the
  `tests_run` instance, and that `plan-freshness-clone-safety` is still marked `open` in
  `docs/operations/known-gaps.tsv` and in the audit despite PR #278 having merged as
  `aaa2fba`. Reproduced the recorder defect before writing anything: with the phase-2 payload
  shape, `bash scripts/enforcement/tests/test-known-gaps.sh` records `tests_run`, while the
  same command behind a `cd /home/user/Engineering-OS &&` prefix records nothing, and the
  identical miss applies to a pipe, a redirect and backgrounding.
- mid: Implementation landed and three things it exposed were root-caused rather than
  waived. First, the graphify evidence gate refused the first write of this session: the
  earlier graphify call had been piped through `head`, and a `SessionStart:resume` had reset
  the ledger — the defect class blocking the very change that fixes it. Second, the runtime
  evidence view showed `skill_used` had no producer at all outside the superpowers-verify
  Read path, so a plan declaring `engineering-route` could never satisfy its own skill check;
  the new PostToolUse Skill recorder then recorded `skill_used engineering-route` from a real
  invocation, which is the live proof for instance 2. Third, the full corpus run failed six
  checks in the new suite: its disposable corpus inherited `EOS_SUITE_RUN_ACTIVE` from the
  outer runner, so the nesting guard correctly suppressed recording. The fixture was
  corrected and the guard now has its own case rather than being an implicit assumption. A
  fourth finding came from reconciliation itself — the ledger accumulates across runs in one
  session, so a suite that failed and was later fixed still read as failing; the reconciler
  now takes the latest record per suite, with both directions pinned by fixtures.
- pre-merge: Verified from a deleted ledger so nothing could carry over between runs:
  `run-enforcement-tests.sh` green across all 118 Bash suites with execution receipts,
  `run-python-enforcement-tests.py` green across all 5 Python suites, and
  `check-bash-runtime-evidence.sh --require-complete` reporting 118/118 Bash suites
  represented in operational runtime evidence. That last number is the whole point of the
  phase: before this change the same seven green corpus runs produced zero. The PR evidence
  gates were each run locally against `origin/main..HEAD` and each one that failed changed
  the plan rather than being argued away — Connector Usage Evidence needed a decision that
  named what the GitHub evidence actually changed, the `.github/workflows` edit implied the
  `validation.actions-checked` capability, and declaring a `patterns/` asset required rating
  evidence for it. `shellcheck` was installed in this container and passed on all ten touched
  shell scripts rather than waived as it was in phase 2.

## Goal

Every Bash enforcement suite that actually runs must be represented in operational runtime
evidence, regardless of how the command was wrapped, and the verification gate must record on
the verification work rather than on a Read of one file path. A missing runtime record must be
detected by a gate, not silently tolerated.

### Reproduction evidence (recorded before the fix)

Instance 1 — `tests_run`, `scripts/enforcement/post-tool-use-bash.sh` `_eos_test_mode`:

- `bash scripts/enforcement/tests/test-known-gaps.sh` (bare) → `tests_run` recorded
- `cd /home/user/Engineering-OS` + newline + the same command → **not** recorded
- the same miss applies to `| tee`, `> log 2>&1`, `&&` chains and backgrounding
- phase 2 ran the full corpus seven times, all passing, and the ledger showed `tests_run = 0`

The matcher is `re.fullmatch` against the **entire** Bash command, so any wrapper defeats it.
Because virtually every real invocation is wrapped, the miss is the common case, not the edge.

Instance 2 — `superpowers_verify_run`, PostToolUse Read hook in `.claude/settings.json` and
`scripts/enforcement/post-tool-use-read-evidence.sh`: the key is a Read of
`.claude/commands/superpowers-verify.md`. Invoking the same verification as a Skill runs the
identical checklist and records nothing.

Both are one defect class: **operational evidence keys on an incidental mechanism rather than
on the work itself.**

## Plan

1. Add `scripts/enforcement/lib/test-run-evidence.sh` as the single owner of "a corpus suite
   executed": one recording function, one suite-id normalizer, one guard that refuses to
   record for fixture runs, nested runners, or redirected evidence directories.
2. Make `scripts/enforcement/run-enforcement-tests.sh` — the component that actually executes
   the suites — the primary evidence producer, recording `bash_suite_run <path>:<result>` and
   `tests_run <path>` from inside the execution. Wrapping the command cannot change this.
3. Replace `_eos_test_mode`'s whole-command `re.fullmatch` with
   `scripts/enforcement/lib/bash_test_invocation.py`: a quote-aware scanner that splits the
   command into control-operator segments and classifies each one, so `cd &&`, env prefixes,
   pipes and redirects are recognised, while path mentions, substitutions, `||` masking and
   backgrounding stay untrusted.
4. Record on the verification work: add `scripts/enforcement/post-tool-use-skill-evidence.sh`
   (PostToolUse `Skill`) so invoking `superpowers-verify` as a skill records
   `superpowers_verify_run`, and broaden the Read recorder to any `superpowers-verify` asset
   path rather than one hard-coded command file. Register the unit in `hook-criticality.tsv`
   first, then wire `.claude/settings.json` and `patch-settings-runtime-evidence.sh` from it.
5. Add `scripts/enforcement/check-bash-runtime-evidence.sh` plus a `runtime-reconcile` command
   in `test_evidence.py` that reconciles the runtime evidence view against the canonical
   discovered corpus and fails when a discovered Bash suite ran without a runtime record.
6. Add `scripts/enforcement/tests/test-bash-runtime-evidence.sh` with positive fixtures for
   every wrapper shape, negative fixtures for every fabrication shape, and the required
   negative fixture proving a suppressed record is **detected** by the reconciler.
7. Run the reconciliation in `.github/workflows/enforcement-tests.yml` on the exact head,
   after the full corpus run that produces the evidence.
8. Close `plan-freshness-clone-safety` with real post-merge evidence and widen
   `bash-runtime-test-evidence` to the defect class per the owner decision; mirror both in the
   audit's Known gaps freshness ledger and status matrix.
9. Record the generalizable lesson under `lessons-learned/`.

## Alternatives considered

- **Only widen the regex.** Rejected: it keeps the evidence keyed on the command string, so
  the next unanticipated wrapper reintroduces the same blindness. It treats the symptom.
- **Record `tests_run` for any command mentioning a suite path.** Rejected: it fabricates
  evidence from `echo`, from `grep`, and from a masked failure — the exact trust regression
  phase 1 closed.
- **Have each of the 117 suites record its own evidence.** Rejected: 117 edit sites with no
  single owner, and a new suite would silently opt out of the contract.
- **Reconcile from CI receipts alone.** Rejected: receipts only exist for runner-driven runs,
  so a direct single-suite invocation would still be invisible in the session's runtime view.
- **Drop the `superpowers_verify_run` Read key and use the Skill event only.** Rejected: it
  would break the existing, legitimate command-file path and trade one single-mechanism key
  for another.

## Affected Surfaces

The Bash and Read PostToolUse recorders, a new Skill PostToolUse recorder, the canonical
enforcement test runner, the test-evidence Python module, a new reconciliation checker, the
hook criticality registry and both settings surfaces derived from it, the enforcement-tests
workflow, `core/hooks-policy.md`, and the known-gaps/audit registries.

## Data/State Impact

No runtime datastore. The per-session evidence ledger gains two record kinds
(`bash_suite_run`, and `tests_run` values naming the suite); `tests_run` keeps its existing
bare-key semantics, so `evidence_has tests_run` in G11 and the Stop hook is unchanged. The
`.engineering-os/test-evidence/<head>/` receipt layout is unchanged.

## Integration Impact

No connector contract changes. GitHub remains the only required connector, for the
branch/PR/CI/review path. One new hook row is added to the canonical hook set, which both
`.claude/settings.json` and generated target settings must carry.

## Validation Plan

- Targeted: `scripts/enforcement/tests/test-bash-runtime-evidence.sh` and
  `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`.
- Negative: a suite executed with the runtime recorder suppressed must make
  `check-bash-runtime-evidence.sh` fail; path mentions, `||` masking, failed output and
  backgrounding must record nothing.
- Reconciliation: runtime evidence view vs the canonical discovered corpus, run in CI on
  the exact head.
- Repo-wide: `check-hard-hook-contract.py` over both settings surfaces; `check-known-gaps.sh`;
  `check-readiness-audit.sh`; orphan-test check.
- Full: the whole corpus via `run-enforcement-tests.sh` and
  `run-python-enforcement-tests.py` on the final commit. The corpus grows from 122 to
  123 (118 Bash + 5 Python) because this change adds one suite.

## Open Questions

None. The one decision that was genuinely the owner's — how to represent the second instance
in the registry — was asked once and answered (see Decision Record); everything else is fixed
by the repository's own contracts.

## DoD

- [x] Runtime evidence is produced by the executing runner, so no command wrapper can suppress it
- [x] Direct single-suite invocations behind `cd`, env prefixes, pipes and redirects record evidence
- [x] Path mentions, `||` masking, command substitution, failed output and backgrounding still record nothing
- [x] `superpowers_verify_run` records when the verification skill runs, not only on one Read path
- [x] New PostToolUse Skill recorder registered in `hook-criticality.tsv` and derived into both settings surfaces
- [x] Negative fixture proves a suppressed runtime record makes the reconciler fail
- [x] Reconciliation wired into `.github/workflows/enforcement-tests.yml` on the exact head, after the corpus run
- [x] Reconciliation green locally on the full corpus: 118/118 Bash suites represented
- [x] `plan-freshness-clone-safety` closed with real post-merge evidence and mirrored in the audit
- [x] `bash-runtime-test-evidence` widened to the defect class with both instances named
- [x] Full enforcement corpus green: 118 Bash + 5 Python suites with execution receipts

## Claude Run Trace

- **Goal:** make every executed Bash enforcement suite visible in operational runtime evidence
  regardless of command shape, make the verification gate record on the verification work, and
  make a missing record a detected failure rather than a silent one.
- **Hypothesis:** operational evidence in this repository keys on incidental mechanisms — a
  full-command regex for `tests_run`, a single file path for `superpowers_verify_run` — so the
  evidence measures how the work was invoked instead of whether it happened. Any invocation
  that does not match the mechanism is recorded as "did not happen".
- **Connectors:** GitHub only (branch, draft PR, exact-head CI, review reconciliation, and the
  PR #278 closure facts). Context7 not required: no external package or library version is
  involved. Notion was not on the required path for this task, so no
  `notion_progress_validated` evidence applies and no Notion decision was taken. Nemotron MCP
  failed to connect this session (`CONNECTION_CLOSED`) and is L1 optional, so it was not used.
- **Steps:** routed via the `engineering-route` skill; read the router, workflow, capability
  registry and testing patterns; ran a graphify BFS over the evidence-recording surface and
  found the executing runner is not connected to the ledger at all; asked the owner the one
  registry-scope question; wrote this plan; made the runner the evidence producer; replaced
  the whole-command matcher with a segment scanner; added the Skill recorder and registered it
  in the canonical hook set; added the reconciler and its CI gate; added the positive and
  negative fixtures; closed the phase-2 gap with live GitHub evidence.
- **Evidence:** before the change, the same payload recorded `tests_run` for
  `bash scripts/enforcement/tests/test-known-gaps.sh` and recorded nothing for the identical
  command behind a `cd` prefix, a pipe, a redirect or backgrounding — and phase 2's seven
  green corpus runs left `tests_run = 0`. After it, a full corpus run from a deleted ledger
  reports 118/118 Bash suites represented. Instance 2 has live proof rather than a fixture:
  invoking `engineering-route` through the Skill tool recorded `skill_used engineering-route`,
  which no producer in the repository could do before. 67 checks in
  `test-bash-runtime-evidence.sh`, including a negative fixture in which the suites genuinely
  execute with recording suppressed and reconciliation is required to fail. 20 checks in the
  pre-existing recorder suite still pass unmodified, so no trust property from phase 1 was
  traded away.
- **Rejected:** widening the regex alone (keeps the evidence keyed on the command string, so
  the next wrapper reintroduces the blindness); recording on any mention of a suite path
  (fabricates evidence from `echo` and from masked failures); editing all 117 suites (no single
  owner, and new suites opt out silently); reconciling from CI receipts alone (a direct
  single-suite run leaves no receipt); replacing the Read key with a Skill key (trades one
  single-mechanism key for another).
- **Result:** the executing runner owns suite evidence, so no command wrapper can suppress
  it; direct invocations are classified per control-operator segment with an explicit
  `filtered` tier for piped output; verification records on the skill invocation as well as
  on any canonical verification asset; and a missing record now fails a gate in CI on the
  exact head instead of being invisible. `plan-freshness-clone-safety` is closed with live
  post-merge evidence, and `bash-runtime-test-evidence` is widened to the defect class with
  both instances named.
- **Follow-up:** Project 8 qualification (`project-8-real-run-evidence`,
  `monitoring-metrics-sufficiency`) remains the next open readiness work after this phase.

## Live External Gates Before Merge

The items below are **not** checklist items and are deliberately unmarked: they are verified
against the live PR (exact head SHA, live check-runs, live review threads), not by
hand-marking this file.

- Branch pushed and draft PR opened
- Enforcement corpus re-run and green on the exact committed head
- Runtime-evidence reconciliation green on the exact committed head in CI
- Exact-head CI green on the final pushed commit
- Review threads reconciled
- Explicit owner approval before merge
