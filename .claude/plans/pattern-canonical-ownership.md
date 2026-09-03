# Route Plan — Pattern lifecycle canonical ownership

Plan Scope: standard
Plan Timestamp: 2026-09-03T14:23:52Z
Planning Mode: approved

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance state-ownership repair |
| Task class | `engineering_os_governance` |
| Domain tags | governance, patterns, lifecycle, testing, observability |
| Plan Scope | standard |
| Plan Timestamp | 2026-09-03T14:23:52Z |
| Planning Mode | approved |
| Task-router evidence | `core/task-router.md` routes Engineering OS governance and enforcement changes through source inspection, a canonical validator, and exact-head validation gates. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/hooks-policy.md`, and `core/quality-gates.md` require plan-first history, positive and negative fixtures wired to the canonical runner, exact-head CI, review reconciliation, and explicit approval before merge. |
| Target paths | `patterns/registry.yaml`; `core/pattern-lifecycle.md`; `docs/operations/template-pattern-ratings.tsv`; `patterns/*/README.md`; `scripts/enforcement/check-pattern-canonical-state.sh`; `scripts/enforcement/tests/test-pattern-canonical-state.sh`; `scripts/enforcement/coverage-required-gates.tsv`; `scripts/enforcement/simulation-coverage.d/pattern-canonical-state.tsv`; `scripts/enforcement/MANIFEST.tsv`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Templates | waiver — this repairs existing governance assets and their existing validator suite. |
| Architecture guides | `core/pattern-lifecycle.md`; `core/scoring-guide.md`; `core/hooks-policy.md` |
| Patterns | none — the change makes the pattern registry itself canonical; no domain pattern is implemented. |
| External systems/connectors | GitHub |
| Skills | `engineering-route` |
| Validation gates | new canonical-state validator with positive and negative fixtures; `run-enforcement-tests.sh`; `check-known-gaps.sh`; `check-readiness-audit.sh`; `git diff --check`; exact-head GitHub Actions; live review reconciliation. |
| Evidence to check | registry status/score/used_in distribution; ratings TSV rows; policy ownership sentence; README score lines; consumer scripts. |
| User decisions required | merge requires explicit owner approval for the exact head; Project 8 qualification requires explicit coordination before any access. |

## Source of Truth Checks

| Source | Status | What it settled |
|---|---|---|
| `docs/operations/known-gaps.tsv` | read | `pattern-registry-canonical-drift` closure requires conflicting status, score, usage, evidence, unknown-row, and active-below-threshold fixtures to fail, and all consumers to read the canonical owner. |
| `patterns/registry.yaml` | read | 88 pattern entries, all `status: candidate`, `score: null`, `used_in: 0` — the executable state surface. |
| `docs/operations/template-pattern-ratings.tsv` | read | Independent hand-editable state: `pattern-security` claims `active` with score `4` and `used_count 1`, contradicting the registry, on a 1–5 scale foreign to the registry's 0–100. |
| `scripts/enforcement/check-template-pattern-ratings.sh` | read | Validates the TSV in complete isolation; performs no registry cross-check, which is the drift mechanism. |
| `core/pattern-lifecycle.md` | read | Its `<pattern_registry>` section states the index is managed in policy files "ולא בקובץ yaml נפרד", denying `patterns/registry.yaml` — a third competing owner. |
| `core/scoring-guide.md` | read | Canonical thresholds: `active` requires score ≥60 and ≥2 real uses; 40–59 with ≥1 use stays `candidate`; <40 considers `deprecated`. Line 189 cites `registry.yaml` as owner, contradicting `pattern-lifecycle.md`. |
| `patterns/*/README.md` | read | 55 `**Score:**` lines in four inconsistent formats (`TBD`, `Candidate`, with and without links), all pointing at `pattern-lifecycle.md` rather than the registry — a fourth state surface that also puts a status value in a score field. |
| `scripts/enforcement/run-enforcement-tests.sh` | read | Auto-discovers `scripts/enforcement/tests/test-*.sh`, so a new suite file is wired by placement. |

## Alternatives

| Alternative | Rejected because |
|---|---|
| Make `core/pattern-lifecycle.md` the canonical owner, as its current text claims. | Prose cannot be queried by `check-required-patterns.sh` or any consumer, and it is exactly the surface that drifted. The registry is already the executable read target. |
| Delete `docs/operations/template-pattern-ratings.tsv` entirely. | It also carries `template`-typed rows, which the pattern registry does not model, and `check-template-pattern-ratings.sh` plus two coverage gates depend on it. Deletion would remove template rating coverage to fix a pattern problem. |
| Leave both files hand-editable and add only a comparison check. | The mitigation in the registry explicitly requires that two independently hand-editable lists not remain. A comparison alone would keep re-admitting drift and require manual reconciliation forever. |
| Keep README `**Score:**` lines and cross-validate them too. | READMEs are designated implementation guidance by the gap mitigation. Parsing 55 prose lines as state would add a fifth owner rather than removing one. |

## Affected-Surfaces

- `patterns/registry.yaml` — becomes the sole declared state owner; content unchanged in this step beyond ownership documentation.
- `core/pattern-lifecycle.md` — `<pattern_registry>` rewritten to name the registry as owner and keep policy files owning rules, not state.
- `docs/operations/template-pattern-ratings.tsv` — pattern-typed rows become derived and non-hand-editable; template-typed rows keep their existing owner.
- `patterns/*/README.md` — 55 lifecycle-state lines replaced by a pointer to the canonical owner.
- `scripts/enforcement/` — one new validator, one new test suite, coverage and manifest registration.
- `docs/operations/known-gaps.tsv` and `operational-readiness-audit.md` — status and matrix rows updated only after the validator passes.

## Data/State-Impact

- No runtime or user data is touched; all state is repository governance metadata.
- No pattern's `status`, `score`, `used_in`, or `evidence` value is invented or promoted. All 88 entries remain `candidate` / `null` / `0`, which is their honest current state.
- The two contradictory rating rows are reconciled downward to the registry's truth, never upward, so no pattern gains an unearned `active` claim.
- Reversibility: every change is a tracked file edit on a branch; no history rewrite and no destructive operation.

## Integration-Impact

- `check-required-patterns.sh` continues to read `domain:` from the registry; its contract is unchanged.
- `check-template-pattern-ratings.sh` keeps validating TSV shape; the new validator adds cross-source agreement rather than replacing it.
- `run-enforcement-tests.sh` picks up the new suite by filename glob, so no runner edit is required.
- `coverage-required-gates.tsv` and `simulation-coverage.d/` gain one gate id, satisfying the `coverage-map-hardening` meta-gate.
- Downstream target projects consuming Engineering OS see a documentation and validator change only; no installer or hook behavior changes.

## Validation-Plan

- Positive: a registry and derived TSV that agree pass the new validator.
- Negative: conflicting status fails.
- Negative: conflicting score fails.
- Negative: conflicting usage count fails.
- Negative: conflicting evidence fails.
- Negative: a pattern-typed row with no matching registry id fails as an unknown row.
- Negative: a registry record with `status: active` and score below 60 or fewer than 2 uses fails as active-below-threshold.
- Suite level: `bash scripts/enforcement/run-enforcement-tests.sh` and the known-gaps and readiness-audit checkers must pass.
- Repository level: `git diff --check`, orphan/inventory validation, and known-gaps ↔ audit synchronization.
- Exact head: the required GitHub Actions set on the final PR head, read per-workflow at its latest attempt.

## Open-Questions

- Is another Project 8 Stage 4 qualification session currently active? Boundary rule 5 requires this to be answered by the owner before any Project 8 access, and it gates five of the eight registered gaps.
- If the owner is running qualification, which bundle identifiers, run ids, and archive paths will be handed over for import and analysis?
- These questions do not block this branch, which is scoped to canonical ownership only.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read before selecting the governance route for this enforcement change.
- `workflow.workflow-read` — `core/workflow.md` and `core/git-policy.md` were read before the first branch commit and set the plan → code → progress → PR order.
- `plan.route-plan-before-write` — this Route Plan is committed before any change to registry, policy, ratings, README, or validator files.
- `source.github-repo-read` — `origin/main` was refetched and confirmed identical to the working head `5603787c4b130c56ffe63d5eb850e984443db18f`; live known-gap state was re-read rather than taken from the task snapshot.
- `validation.policy-change-has-validator` — `scripts/enforcement/check-pattern-canonical-state.sh` and its positive/negative fixtures make the canonical-ownership rule executable rather than prose-only.
- `validation.coderabbit-policy` — the PR is opened ready for review per `core/git-policy.md`; exact-head review and threads are reconciled before requesting merge approval.

## Connector Evidence

- GitHub is required to publish the branch, open the PR, read exact-head workflow conclusions, and reconcile review state.
- No external library or package documentation is involved, so Context7 is not queried.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, `origin/main`.
- action: refetched `origin/main` and compared it to the local head before planning; enumerated accessible repositories to establish whether Project 8 qualification is performable from this session.
- result: `origin/main` equals `5603787c4b130c56ffe63d5eb850e984443db18f` with a clean tree; `yotamfried-ux/project-8` is listed as accessible, but a Project 8 qualification requires a genuinely fresh SessionStart rooted in Project 8, which this Engineering-OS-rooted session cannot produce.
- decision: scope this branch to the pattern canonical-ownership repair, which is fully performable here, and route the five qualification-dependent gaps to explicit owner coordination instead of simulating them.
- target: `patterns/registry.yaml` as canonical owner, plus its policy, derived-state, README, and validator consumers.

## Documentation Asset Evidence

- internal: `core/pattern-lifecycle.md`; `core/scoring-guide.md`; `patterns/registry.yaml`; `docs/operations/template-pattern-ratings.tsv`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-template-pattern-ratings.sh`; `scripts/enforcement/check-required-patterns.sh`.
- context7: not queried because no external API, library, or versioned dependency changes.
- decision: encode the ownership rule in an executable validator with fixtures rather than as prose, because prose is precisely what drifted.

## Template Gap Waiver

No scaffold applies to a governance state-ownership repair across existing registry, policy, and validator assets. The existing enforcement suite is the canonical extension point.

## Skill Evidence

- `engineering-route` — applied the repository-native governance route: canonical source inspection, plan-first branch history, executable validator with positive and negative fixtures, exact-head CI, review reconciliation, and explicit owner approval before merge.

## Progress Lifecycle Evidence

- start: `origin/main` refetched and confirmed equal to `5603787c4b130c56ffe63d5eb850e984443db18f`; live registry shows 42 closed, 1 mitigated, 7 open gaps, matching the task snapshot.
- start: `--assert-full-ready` reproduced as failing on exactly the eight named gaps plus seven status-matrix rows.

## Definition of Done

- planned: declare `patterns/registry.yaml` the single canonical state owner in `core/pattern-lifecycle.md`.
- planned: make pattern-typed rows of the ratings TSV derived and non-hand-editable, cross-validated against the registry.
- planned: remove lifecycle state from domain READMEs, leaving them as implementation guidance that points at the canonical owner.
- planned: add a canonical-state validator failing on conflicting status, score, usage, evidence, unknown rows, and active-below-threshold records.
- planned: wire positive and negative fixtures into the canonical runner and coverage manifests.
- external gate: the required workflow set must pass on the final exact PR head before merge.

## Live External Gates Before Merge

- required: branch published and ready-for-review PR opened.
- required before merge: every required workflow succeeds on the final exact PR head.
- required before merge: reviews and unresolved threads reconciled on that exact head.
- required before merge: explicit owner approval obtained for that exact head.

## Claude Run Trace

- goal: give pattern lifecycle state exactly one canonical owner and make divergence executable-detectable.
- evidence: registry status/score/usage distribution, ratings TSV contradiction, policy ownership denial, README format spread, and consumer script reads.
- boundary: this branch closes canonical ownership only. It does not close pattern evidence maturity, any Project 8 or Remote qualification gap, or full-readiness semantics, and it makes no claim about Project 8.
