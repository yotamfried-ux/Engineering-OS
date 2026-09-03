# Route Plan — Clone-safe plan freshness and selection

Plan Scope: standard
Plan Timestamp: 2026-09-03T07:39:53Z
Planning Mode: approved

## Route Plan

| Field | Decision |
|---|---|
| Task type | enforcement correctness fix + route-plan corpus cleanup |
| Task class | `engineering_os_governance` |
| Domain tags | plan freshness, plan selection, clone safety, filesystem mtime, git history, enforcement hooks, known-gaps registry |
| Plan Scope | standard |
| Plan Timestamp | 2026-09-03T07:39:53Z |
| Planning Mode | approved |
| Task-router evidence | `core/task-router.md` routes Engineering OS enforcement changes through the canonical workflow, quality gates and git policy. |
| Workflow evidence | `core/workflow.md` (plan-first writes), `core/quality-gates.md` (DoD vs live external gates), `core/hooks-policy.md` (KG7 zombie-plan gap), `core/git-policy.md` (branch → PR → review → approval). |
| Target paths | `scripts/enforcement/lib/plan-time.sh`; `scripts/enforcement/lib/evidence.sh`; `scripts/enforcement/enforce-workflow.sh`; `scripts/enforcement/enforce-bash-entry.sh`; `scripts/enforcement/enforce-run-trace.sh`; `scripts/enforcement/enforce-learning-capture.sh`; `scripts/enforcement/pre-tool-use-connector-selection.sh`; `scripts/enforcement/pre-tool-use-learning-reuse.sh`; `scripts/enforcement/pre-tool-use-runtime-evidence.sh`; `scripts/enforcement/check-plan-scope.sh`; `scripts/enforcement/post-stop-hook.sh`; `scripts/enforcement/pre-tool-use-template-selection.py`; `scripts/hooks/pre-commit.sh`; `scripts/session-setup.sh`; `scripts/enforcement/tests/`; `lessons-learned/`; `core/workflow.md`; `core/task-router.md`; `core/quality-gates.md`; `.claude/plans/`; `.gitignore`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Templates | waiver — focused enforcement correctness fix; no project template applies. |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | none reusable — this change defines the canonical plan-time resolution itself. |
| External systems/connectors | GitHub |
| Skills | `engineering-route` |
| Validation gates | targeted freshness/selection regression; full enforcement-corpus run (122 suites) on the final commit; orphan-test check; no-mtime-for-plans check; known-gaps ↔ audit ledger sync; broken-link check after deletion. |
| Evidence to check | live clone reproduction (recorded below); `check-known-gaps.sh` contract; `run-enforcement-tests.sh` receipts. |
| User decisions required | none — scope, keep-list and deletion count were fixed by the user's phase-2 brief. |

## Capability Evidence

Task class: `engineering_os_governance` — the change alters deterministic enforcement
behaviour in `scripts/enforcement/`, so it runs the full plan → branch → PR → review →
approval path with executable positive and negative evidence.

- `routing.task-router-read` — `core/task-router.md` read this session before any write;
  it routes Engineering OS enforcement changes through the canonical workflow, quality
  gates and git policy, and this change also updates its route-plan template with the new
  `Plan Timestamp` field.
- `workflow.workflow-read` — `core/workflow.md` read this session; its
  `<evidence_backed_planning>` contract defines Plan Scope and the required plan sections,
  and this change documents the `Plan Timestamp` rule there.
- `plan.route-plan-before-write` — this route plan was created and committed before the
  code change; `check-workflow-evidence.sh` requires the plan commit to precede the first
  code commit on the branch, and the branch history is ordered that way.
- `source.github-repo-read` — repository state read via the GitHub connector and git:
  `main` at `ba5f8d3`, PR #274 and #277 as the merged phase-1 work, and the live PR #278
  head, checks and review threads for this change.
- `validation.policy-change-has-validator` — `scripts/enforcement/tests/test-plan-freshness-clone-safety.sh`
  added as the executable validator for the new plan-time contract, with 11 of its checks
  demonstrated to fail against the pre-fix implementation.
- `validation.coderabbit-policy` — CodeRabbit reported "Draft PR not reviewed" on #278, so
  automated review has not run yet; per `core/coderabbit-policy.md` the fallback is a
  recorded manual review, and the PR stays draft and unmerged until review and explicit
  owner approval.

## Graphify Usage Evidence

- source: graphify query over `graphify-out/graph.json` (1725 nodes), start set `enforce-workflow.sh`, `evidence.sh`, `check-plan-scope.sh`, `pre-tool-use-connector-selection.sh`, `pre-tool-use-runtime-evidence.sh`
- action: graphify BFS depth=2 traversal of the plan-reading enforcement surface to enumerate every caller that resolves "the active plan"
- result: the graph showed the plan readers are spread across `enforce-workflow.sh`, `lib/evidence.sh`, `check-plan-scope.sh`, `post-stop-hook.sh`, `enforce-bash-entry.sh`, `enforce-run-trace.sh`, `enforce-learning-capture.sh` and three `pre-tool-use-*` hooks, each repeating its own `ls -t` instead of depending on one owner — so the defect has ten independent call sites, not one
- decision: the graph finding changed the write from a local patch of the freshness gate into a shared owner module, `scripts/enforcement/lib/plan-time.sh`, that every one of those callers is routed through
- target: scripts/enforcement/lib/plan-time.sh, scripts/enforcement, scripts, core, docs/operations, .claude/plans, .gitignore, lessons-learned

## Source of Truth Checks

| Source | Status | What it settled |
|---|---|---|
| core/workflow.md | read | The plan-first write gate and the Minimum Planning Contract; this is where the new `Plan Timestamp` rule is documented. |
| core/hooks-policy.md | read | KG7 records the *semantic* zombie-plan gap, so this change is scoped to the *temporal* one and cross-references KG7 instead of redefining it. |
| core/quality-gates.md | read | CI-dependent items belong under `## Live External Gates Before Merge`, never in `## DoD`; the plan's DoD was restructured accordingly. |
| core/task-router.md | read | Routes Engineering OS enforcement work through the canonical workflow; its route-plan template gains the `Plan Timestamp` field. |
| core/capability-registry.yaml | read | Supplied the six required capabilities for task class `engineering_os_governance`. |
| scripts/enforcement/check-known-gaps.sh | validated | The 10-column TSV contract and the mandatory audit ledger mirror; ran it to confirm 50 gaps pass. |
| docs/operations/operational-readiness-audit.md | validated | Non-closed gaps must also appear as status-matrix rows; ran check-readiness-audit.sh to confirm. |

## Connector Evidence

- GitHub — the only connector on the required path for this change: reading repository and
  branch state, pushing `claude/plan-freshness-clone-safety-f1neiv`, opening PR #278, and
  reading its exact-head check runs and review threads.
- Context7 — not required and not queried: the change introduces no external library,
  framework, or package version, and relies only on `git`, `date` and POSIX shell builtins
  already used throughout `scripts/enforcement/`.
- Nemotron MCP — configured but failed to connect this session (`CONNECTION_CLOSED`). It is
  L1 optional and not on this task's required path, so the session continued without it
  per `core/connector-policy.md`'s fallback rule.

## Connector Usage Evidence

- source: GitHub — repository, branch, commit history, PR #274 and #277 (merged phase-1 work), and live PR #278 for this change
- action: GitHub used to read `main` at `ba5f8d3`, confirm the phase-2 branch had never been pushed, push `claude/plan-freshness-clone-safety-f1neiv`, open PR #278 as a draft, and read its check runs and review comments
- result: GitHub showed `main` at `ba5f8d3a2118d17b61bf44e9e3de846b336aa0bd`, that the earlier `fix/clone-safe-plan-freshness` branch does not exist on the remote (so the previous working-tree work was lost with its container), and that PR #278 head `6be9818` failed four evidence gates because `.gitignore` had kept `.claude/plans/clone-safe-plan-freshness.md` untracked
- decision: that GitHub evidence changed the work twice — it showed phase 2 had to be re-implemented from scratch rather than resumed, and the failing checks on #278 led me to add the `.gitignore` negation for `.claude/plans/` and to reorder the branch so the route-plan commit precedes the code commit in `scripts/enforcement/`
- target: scripts/enforcement/lib/plan-time.sh, scripts/enforcement, scripts/hooks/pre-commit.sh, scripts/session-setup.sh, core, docs/operations, .gitignore

## Documentation Asset Evidence

- internal: `core/workflow.md` (`<evidence_backed_planning>`), `core/hooks-policy.md` (`<known_gaps>` KG7), `core/quality-gates.md` (`<definition_of_done>`), `core/task-router.md` (route-plan template), `core/capability-registry.yaml`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, and `scripts/enforcement/check-known-gaps.sh`
- context7: not queried — no external library, framework, or package version is involved. The change uses only `git`, `date`, and POSIX shell builtins already relied on throughout `scripts/enforcement/`, and the contract it implements is defined by this repository's own policy files, not by third-party documentation.
- decision: `core/hooks-policy.md` KG7 showed the repository already documents the *semantic* zombie-plan gap, so I scoped this change to the *temporal* one and cross-referenced KG7 rather than redefining it; `core/quality-gates.md` moved "branch pushed / PR opened" out of the plan's DoD into `## Live External Gates Before Merge`; `check-known-gaps.sh` fixed the exact 10-column row shape and the audit ledger mirror; and `core/workflow.md` is where the new `Plan Timestamp` rule is documented.

## Skill Evidence

- `engineering-route` — invoked with this task before the first write; produced this plan's
  Route Plan, source-of-truth and waiver sections.

## Template Gap Waiver

No project or scaffold template applies: this is a correctness fix inside existing
enforcement scripts plus a corpus deletion. A new template would add surface without
reducing risk.

## Progress Lifecycle Evidence

- start: Final stages 1–3 acceptance audit on `main` at `b64050e` reproduced one
  remaining checkout-mtime bypass in the session-start Existing plans display while the
  blocking freshness resolver and all stage-3 runtime-evidence checks remained sound.
- start: Session opened on `main` at `ba5f8d3` in a fresh container. Confirmed the phase-2
  branch `fix/clone-safe-plan-freshness` was never pushed, so no prior work survived, and
  that neither gap id existed in `docs/operations/known-gaps.tsv`. Reproduced the defect in
  a clean clone before writing anything: 118 tracked plans, one distinct mtime, `ls -t`
  selecting a plan 58 days old, `age_h = 0`.
- mid: After adding `lib/plan-time.sh` and migrating the call sites, ran the targeted
  suites and found 16 real failures in `test-workflow.sh` plus 5 more across
  `test-active-plan-selection.sh`, `test-learning-reuse.sh`,
  `test-operational-learning-skills.sh`, `test-post-tool-use-bash-evidence.sh` and
  `test-readiness-audit.sh`. Each was root-caused rather than waived: fixtures that
  expressed recency through `sleep 1` plus mtime now declare timestamps; `evidence.sh` was
  changed to stop treating a missing plan-time library as fatal to the bypass ledger; the
  two new gaps were added as audit status-matrix rows. One self-inflicted bug was caught
  here too — `$(plan_stamp)` ran in a subshell so the sequence counter never advanced and
  every fixture shared a timestamp.
- pre-merge: Full corpus green on the committed head with execution receipts — 117 Bash
  suites and 5 Python suites, 122 receipts, receipt count equal to corpus count, none
  failing; re-confirmed on the final head `f19c801` after the learning-loop lesson landed.
  Two rounds of CI on this PR each exposed something the local run could not. The first
  pushed head `6be9818` failed four PR evidence gates, which uncovered a real defect:
  `.gitignore` had kept newly created route plans untracked, so no route plan reached the
  gates and the git-history branch of the new resolver could never apply to a new plan.
  The second round showed the PR-body contract is enforced one section per run — Review
  Fallback, then Merge Readiness, then Operational Behavior Evidence, then Operational
  Work History Evidence — and that the job reporting all of it is named
  "Require ready-for-review PR", which sent the first diagnosis to the wrong cause. The
  branch was reordered so the route-plan commit precedes the code commit, and the
  learning loop records the generalizable lesson: mtime describes the checkout, not the
  file. Merge remains blocked on review and explicit owner approval.
## Goal

Plan freshness and plan selection must not depend on filesystem mtime, because a fresh
`git clone` resets every plan's mtime to clone time. Reduce the route-plan corpus to the
three plans that are actually live.

### Reproduction evidence (recorded before the fix)

Fresh `git clone` of this repository into a scratch directory:

- distinct filesystem mtimes across all 118 tracked plans: **1** (every plan identical)
- `ls -t .claude/plans/*.md | head -1` selected `rtk-coverage-fixtures.md` by arbitrary tie-break
- that plan's real last-modified time from git history: **2026-07-06** (58 days old)
- `age_h` computed by the current gate: **0** → the 48h freshness gate passed a 58-day-old plan

Observed a second time in the working repository itself: the entry gate refused a command
because `ls -t` selected `skill-selection-gate.md`, a plan unrelated to this task, purely
from an mtime tie-break.

Both defects follow from one cause: `stat %Y` and `ls -t` describe the checkout, not the plan.

## Plan

1. Add `scripts/enforcement/lib/plan-time.sh` as the single canonical resolver:
   - tracked and clean in git → last-commit time of that path (`git log -1 --format=%ct`);
   - tracked-but-modified, or untracked → the plan's declared `| Plan Timestamp | <ISO-8601 UTC> |`;
   - missing, unparseable, or future-dated declared timestamp → fail closed with a named reason;
   - expose `eos_plans_by_recency` (deterministic sort: resolved time desc, then filename)
     and `eos_newest_plan`.
2. Replace every `ls -t .claude/plans/*.md` call site and every `stat %Y` / `st_mtime` plan
   read with the shared resolver — enforcement hooks, session setup, pre-commit, and the
   Python template-selection path.
3. Add `scripts/enforcement/tests/test-plan-freshness-clone-safety.sh` with regression cases
   that fail against the pre-fix implementation: identical-mtime clone, inverted mtime vs git
   order, missing timestamp, malformed timestamp, future timestamp.
4. Document the `Plan Timestamp` field in `core/workflow.md` and in the route-plan template
   in `core/task-router.md`.
5. Delete the 116 historical route plans, keeping exactly
   `test-evidence-trust-hardening.md`, `bash-tests-run-evidence.md`, and
   `clone-safe-plan-freshness.md`; repoint every document and code comment that referenced
   a deleted plan.
6. Register both canonical gaps in `docs/operations/known-gaps.tsv` and mirror them in the
   audit's `## Known gaps freshness ledger`.
7. Run the targeted regression, then the full enforcement suite on the final commit.

## Alternatives considered

- **Keep mtime, `touch` plans at session start.** Rejected: it manufactures freshness rather
  than measuring it, and makes every plan permanently fresh — the exact failure observed in
  the clone.
- **Use git history only.** Rejected: a brand-new plan is untracked and has no git time, so
  the gate would block every first write.
- **Use the declared timestamp only.** Rejected: it discards the unforgeable committed
  history for plans already in git.
- **Store plan times in a side index file.** Rejected: a second source of truth that can
  drift from both git and the plan itself.

## Affected Surfaces

Enforcement hooks (`enforce-workflow`, `enforce-bash-entry`, `enforce-run-trace`,
`enforce-learning-capture`, `check-plan-scope`, `post-stop-hook`, three `pre-tool-use-*`
hooks), `lib/evidence.sh` plan selection, `scripts/session-setup.sh`,
`scripts/hooks/pre-commit.sh`, the Python template-selection path, the route-plan corpus,
and the known-gaps/audit registries.

## Data/State Impact

No runtime datastore. The route-plan corpus shrinks from 118 files to 3; the deletions stay
recoverable from git history. Plans gain one declared metadata field.

## Integration Impact

No connector contract changes. GitHub remains the only required connector, for the
branch/PR/CI/review path.

## Validation Plan

- Targeted: `scripts/enforcement/tests/test-plan-freshness-clone-safety.sh`,
  `test-active-plan-selection.sh`, `test-workflow.sh`, `test-plan-scope.sh`.
- Negative: each new regression case asserted to fail against the pre-fix code path.
- Repo-wide: no `ls -t` or `stat %Y` remains on a plan path; no orphan tests;
  known-gaps ↔ audit ledger in sync; no reference to a deleted plan survives.
- Full: all 122 suites (117 Bash + 5 Python) via `run-enforcement-tests.sh` on the final commit.

## Open Questions

None. Scope, keep-list and the 116-file deletion count were fixed by the user's phase-2
brief and confirmed against the working tree (118 tracked plans − 2 existing keepers = 116).

## DoD

- [x] Canonical plan-time resolver added and used by every plan reader
- [x] No filesystem mtime remains on any plan path
- [x] Clone-safety and timestamp-validation regression test suite `test-plan-freshness-clone-safety.sh` added and passing
- [x] Regressions demonstrated to fail against the pre-fix implementation
- [x] `Plan Timestamp` documented in workflow and route-plan template
- [x] Exactly 116 plans deleted; exactly 3 remain
- [x] Every reference to a deleted plan repointed or removed
- [x] Both canonical gaps registered and mirrored in the audit ledger
- [x] Full enforcement corpus green before the commit: 122 suites with execution receipts, plus the known-gaps and readiness-audit checkers
- [x] Post-merge audit residual in the session-start plan display removed and covered by a production-wide no-mtime regression

## Claude Run Trace

- **Goal:** make plan freshness and active-plan selection independent of filesystem
  mtime, and cut the route-plan corpus to the three live plans.
- **Hypothesis:** `ls -t` and `stat %Y` describe the checkout rather than the plan, so a
  `git clone` — which rewrites every tracked file's mtime to the checkout time — makes an
  arbitrarily old plan look brand new and lets it pass the 48h freshness gate.
- **Connectors:** GitHub only (branch, draft PR, exact-head CI, review reconciliation).
  Notion was not on the required path for this task, so no `notion_progress_validated`
  evidence applies and no Notion decision was taken. Context7 not required: no external
  package or library version is involved. Nemotron MCP failed to connect this session and
  is L1 optional, so it was not used.
- **Steps:** cloned the repo to a scratch directory and measured the defect; routed via
  the `engineering-route` skill; ran a graphify BFS over the plan-reading surface to
  enumerate the call sites; wrote `lib/plan-time.sh` as the single owner; migrated all ten
  call sites plus the Python selector; added the clone-safety regression suite; deleted
  116 plans and repointed their references; registered both gaps; ran the full corpus.
- **Evidence:** in a fresh clone all 118 tracked plans shared exactly one mtime; `ls -t`
  selected `rtk-coverage-fixtures.md`, last changed 2026-07-06 (58 days earlier), and the
  gate computed `age_h = 0`. The same defect then blocked this very session, with the
  entry gate selecting the unrelated `skill-selection-gate.md` on an mtime tie. After the
  fix the resolver reports the real ages (29h and 2h) for the committed plans. 11 checks
  in `test-plan-freshness-clone-safety.sh` were run against a reconstruction of the
  pre-fix implementation, failed there, and pass against the fix. Full corpus: 117 Bash
  suites plus 5 Python suites green with execution receipts.
- **Rejected:** touching plans at session start (manufactures freshness instead of
  measuring it, and makes every plan permanently fresh); git history alone (a new,
  untracked plan has no git time, so every first write would be blocked); the declared
  timestamp alone (discards unforgeable committed history); a side index of plan times
  (a second source of truth that can drift from both git and the plan).
- **Result:** one canonical resolver owns plan recency; undatable plans fail closed with a
  named reason instead of reporting as fresh; the historical corpus cleanup remains exact.
  A final stages 1–3 audit found one presentation-only `ls -lt` residue in the session-start
  Existing plans list. PR #280 removes it, adds a production-wide bypass scan, and aligns
  KG7 and G11 documentation with the implemented resolver and runtime-evidence producers.
- **Follow-up:** exact-head CI, review reconciliation and explicit owner approval remain
  live external gates for PR #280. Project 8 qualification follows after merge.

## Live External Gates Before Merge

The items below are **not** checklist items and are deliberately unmarked: they are verified
against the live PR (exact head SHA, live check-runs, live review threads), not by
hand-marking this file.

- Branch pushed and draft PR opened
- Enforcement corpus re-run and green on the exact committed head
- Exact-head CI green on the final pushed commit
- Review threads reconciled
- Explicit owner approval before merge
