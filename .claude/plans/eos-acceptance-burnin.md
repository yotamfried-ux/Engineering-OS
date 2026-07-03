# Route Plan — Engineering OS Operational Acceptance / Burn-In Experiment

## Route fields

| Field | Value |
|---|---|
| Task type | Engineering OS governance — operational acceptance test of the merged A–E readiness program, spanning EOS-repo verification and a downstream clean-install burn-in |
| Task class | engineering_os_governance (primary — verifying/exercising CLAUDE.md, core/*, scripts/enforcement/*, use-in-project.sh); downstream code changes performed inside the burn-in target follow `code_change` for that sub-scope |
| Domain tags | governance, workflow, testing, ci, hooks |
| Task-router evidence | `core/task-router.md` read (`<routing_algorithm>`); classified per §7 "Engineering OS maintenance / governance" — consult CLAUDE.md, workflow.md, skill-orchestration-policy.md, connector-policy.md, learning-loop.md, hooks-policy.md; extra rule: this experiment must strengthen or verify the enforcement layer, not just add explanatory text |
| Workflow evidence | `core/workflow.md` read in full (`<agent_loop>`, `<workflow>` steps 1–12, `<onboarding>`, `<project_scaffold>`, `<spec_loop>`); this plan is being written before any script run beyond read-only preflight checks (`git status`/`git fetch`), consistent with the write gate in step 4 |
| Target paths | Read/verify only in `yotamfried-ux/Engineering-OS` (this repo): `docs/operations/*`, `scripts/enforcement/*`, `core/*`. Write target: `/tmp/eos-burnin-target` (clean downstream project, outside this repo) plus a small real-code PR inside it. No writes to Engineering-OS core files unless a genuine defect is root-caused during the experiment (tracked separately if it happens). |
| Templates | Not applicable for the EOS-repo verification itself (no scaffold). For the downstream burn-in target: evaluate `templates/desktop-application/` (closest fit for a tiny CLI script) per `core/task-router.md` §1 Greenfield scaffold, or explicitly waive if the task is too trivial for a full template. |
| Patterns | `patterns/testing/README.md` (test discipline for the downstream task), consulted per task-router §1/§4. No auth/api/billing domain touched, so no domain-specific pattern required beyond testing. |
| Skills | superpowers (planning/verification, default in every project — used here via `/superpowers-verify` conceptually for the downstream task); security-review not required (no production-bound surface, no auth/secrets/payments touched); graphify/rtk/claude-mem are session-infrastructure skills, not applicable to a governance/audit task with no local session tooling installed in this remote container (documented as unavailable in Part C, not silently skipped) |
| External systems/connectors | GitHub (primary connector — repo state, PR/CI evidence in both `yotamfried-ux/Engineering-OS` and the downstream target if pushed to GitHub); Context7 (not required — no library/API usage in this task); others per full Part C connector matrix below |
| Validation gates | `scripts/enforcement/check-known-gaps.sh`, `scripts/enforcement/check-readiness-audit.sh`, full `enforcement-tests` suite, `scripts/enforcement/tests/test-clean-install-and-usage.sh` (install contract), `scripts/enforcement/tests/test-post-merge-validation-contract.sh`, `scripts/enforcement/tests/test-pr-review-evidence.sh` (merge-readiness evidence); downstream: installed pre-commit/commit-msg hooks, PreToolUse Write/Edit/Bash gates |

## Goal / מטרה

Verify — with tool-backed evidence, not assertion — that Engineering OS is not only green in
its own CI but operationally works end-to-end: (1) main is genuinely at 0 open known gaps and a
fully classified readiness matrix; (2) a clean downstream project installed via
`use-in-project.sh` receives working hooks, commands, templates, patterns, and policy-gate
dependencies; (3) the connector inventory is honestly classified for this environment; (4) a real
small code change can travel through the full Route Plan → connector evidence → tests → commit →
PR pipeline in the downstream target; (5) at least 18 controlled bypass attempts are correctly
blocked by the installed gates, or are documented as new gap candidates if they are not.

## Plan / תכנון

1. Part A — run the deterministic readiness checks on `main` (`check-known-gaps.sh`,
   `check-readiness-audit.sh`, enforcement-tests, install-contract tests, post-merge-validation
   contract tests, PR-review-evidence tests) and record exact output.
2. Part B — create `/tmp/eos-burnin-target`, run `use-in-project.sh` against it, and verify every
   installed artifact against the documented install contract.
3. Part C — classify every connector in the inventory (available+used / available-not-relevant
   with waiver / unavailable-with-error / manual-by-design), including the 15 named in scope.
4. Part D — perform one small real code change (tiny CLI script + test) inside the downstream
   target through the full workflow, ending in a draft-avoided (per git-policy §pull_requests,
   ready-for-review) PR with Merge Readiness + Review Fallback Evidence sections. Do not merge
   without explicit owner approval.
5. Part E — run the 18 controlled negative bypass attempts against the installed target and
   record blocker pass/fail for each.
6. Part F — conditional on owner merge approval only.
7. Part G — produce the final evidence-rich report in the exact required structure.

## Alternatives / חלופות

- Use a temporary GitHub repo instead of `/tmp/eos-burnin-target` for the downstream install.
  Rejected as the primary path: creating a new GitHub repo is a shared/visible action requiring
  explicit user confirmation per `<safety>`, and the task explicitly allows a local `/tmp` target
  as the primary example. If GitHub-hosted evidence (PR/CI) is later required for Part D, ask the
  user before creating a new repo, or reuse an already-in-scope repo if suitable.
- Skip Part C's live connector probing and rely on documentation alone. Rejected: connector-policy
  explicitly requires "do not fake connector use" — every connector must be probed with a real
  tool call where a client is available in this session, and marked unavailable-with-exact-error
  otherwise.

## Source of Truth Checks

| Source | Status |
|---|---|
| `CLAUDE.md` (this repo) | read |
| `core/task-router.md` | read |
| `core/workflow.md` | read |
| `core/connector-policy.md` | read |
| `core/quality-gates.md` | read |
| `core/git-policy.md` | read |
| `core/hooks-policy.md` | read |
| `core/learning-loop.md` | read |
| `core/skill-orchestration-policy.md` | read |
| `core/resource-management.md` | read |
| `docs/operations/known-gaps.tsv` | read — 0 open (all rows `status=closed`) |
| `docs/operations/operational-readiness-audit.md` | read — every matrix row Enforced or Manual by design, no bare `Manual`, no unlinked gaps |
| `docs/operations/merge-readiness-checklist.md` | read |
| `docs/operations/post-merge-incident-checklist.md` | read |
| `use-in-project.sh` / installer script location | to verify in Part B |
| `scripts/enforcement/policy-gate-dependencies.tsv` | to verify in Part B |

## Capability Evidence

Required capabilities for task class `engineering_os_governance`:

- `routing.task-router-read` — `core/task-router.md` read; routed under §7 Engineering OS
  maintenance/governance (this experiment validates the enforcement layer itself).
- `workflow.workflow-read` — `core/workflow.md` read in full before any action beyond read-only
  git preflight; this Route Plan is being written before Part A commands execute.
- `plan.route-plan-before-write` — this file, committed/present before any write action in Part B
  onward.
- `source.github-repo-read` — `git status`, `git fetch origin main`, `git log`, `git rev-parse`
  run against `yotamfried-ux/Engineering-OS` before proceeding (see Claude Run Trace).
- `validation.policy-change-has-validator` — no EOS core policy is being changed by this plan; if
  a genuine defect is found and fixed during the experiment, the fix will add/update a validator
  per the same gate this audit is testing, and this Capability Evidence block will be amended.
- `validation.coderabbit-policy` — not triggered: this branch does not modify Engineering OS core
  files as of plan authoring; if it later does (root-cause fix), the coderabbit-policy branch→PR→
  review→merge sequence applies before that specific change merges.

## Connector Evidence

- [x] GitHub: repo state read (`git status`, `git fetch origin main`, `git log`) on
  `yotamfried-ux/Engineering-OS`; full connector matrix probed in Part C.
- [x] Not required beyond GitHub for writing this plan file itself — the downstream Part D task
  will carry its own Connector Evidence section scoped to that sub-task.

## Claude Run Trace

- **Goal:** Determine, with tool evidence, whether Engineering OS is operationally ready — not
  just CI-green in its own repo — by exercising install, connectors, and gates in a clean
  downstream target.
- **Hypothesis:** Given the A–E readiness program merged and `known-gaps.tsv`/readiness-audit both
  report closed/enforced, the deterministic gates should hold in a freshly installed downstream
  project and correctly block the 18 negative bypass attempts; any gate that silently passes a
  bypass is a genuine new gap, not a pre-existing "by design" limitation.
- **Connectors:** GitHub (primary, used throughout); Context7/Sentry/Notion/Vercel/Postman/Google
  Drive probed for real availability in Part C; Slack/Linear/Jira/Stripe/Postgres/Google
  Sheets/Discord/Expo documented per their actual MCP-tool availability in this session, not
  assumed.
- **Steps:** read all required governance files → confirm known-gaps=0 and audit fully classified
  → write this Route Plan → run Part A deterministic checks → build downstream target → install →
  verify install contract → connector matrix → positive workflow → negative bypass suite →
  (conditional) post-merge validation → final report.
- **Evidence:** captured inline in each Part's task output and cited by exact command + log
  excerpt in the final report (section 2–6).
- **Rejected:** creating a new hosted GitHub repo as the default downstream target (shared/visible
  action, needs explicit confirmation) — using local `/tmp/eos-burnin-target` instead, consistent
  with the task's own stated preference.
- **Result:** pending — filled in at experiment completion.
- **Follow-up:** any negative-attempt successes or install-contract mismatches become new
  known-gap candidates per Part E instructions, not silent notes.

## Progress Lifecycle Evidence

- **start:** Route Plan authored; `known-gaps.tsv` confirmed 0 open; readiness audit confirmed
  fully classified; `main` and experiment branch both at SHA `8cb774d030ed6c6f5f8d17ac89f421980f31a615`.
- **mid:** to be recorded after Part B/C/D complete (downstream install verified, connector matrix
  classified, positive workflow PR opened).
- **pre-merge:** to be recorded before any merge decision — N/A for this plan file itself (it is
  not merged into product code), applies to the Part D downstream PR only, gated on explicit owner
  approval.

## Definition of Done / תנאי סיום

- [ ] Part A: known-gaps check, readiness-audit check, enforcement-tests, install-contract test,
      post-merge-validation-contract test, PR-review-evidence test all run with exact output
      recorded — signal: command exit codes + captured stdout/stderr.
- [ ] Part B: downstream target installed and every listed artifact (CLAUDE.md, settings.json,
      hooks, commands, templates, patterns, policy-gate-dependencies, executable bits,
      commit-msg EOS_HOME resolution, missing-manifest fail-closed) verified with a concrete
      file-existence/permission/behavior check — signal: `ls -la`, `test -x`, hook dry-run output.
- [ ] Part C: connector matrix complete for all 15 named connectors + inventory extras, each with
      a real attempted action or a documented absence signal — signal: tool call result or
      explicit "no matching MCP tool" statement.
- [ ] Part D: one real code change in the downstream target goes through Route Plan → routing →
      connector evidence → tests → commit → PR, with Merge Readiness section — signal: test run
      output, commit hash, PR number/diff if pushed to GitHub.
- [ ] Part E: all 18 negative bypass attempts executed against the installed target with recorded
      expected vs. actual blocker — signal: hook exit code / gate output per attempt.
- [ ] Part F: only if a PR is merged after explicit approval — signal: merged SHA + post-merge
      workflow result.
- [ ] Part G: final report delivered in the exact required message structure.

## Rollback plan

- Nothing in this experiment writes to `yotamfried-ux/Engineering-OS` main or core files by
  default. If a root-cause fix to EOS itself becomes necessary, it follows `coderabbit-policy.md`
  (dedicated branch → PR → CI → review → explicit approval before merge) and can be abandoned by
  simply not merging that PR.
- The downstream target lives at `/tmp/eos-burnin-target`, ephemeral to this container; deleting
  the directory fully rolls back Part B/D/E with no effect on any persistent system.
- Any PR opened in a GitHub-hosted downstream target (if one is created) is closed, not merged, if
  the experiment concludes it should not persist.
- This experiment branch (`claude/eos-acceptance-burnin-o1birt`) is never merged to
  `Engineering-OS:main` without explicit owner approval, per the meta-rule and `<safety>`.

## Known limitations (declared up front)

- This is a remote container session: no `graphify`/`rtk`/`claude-mem` binaries are installed, and
  several MCP connectors in the full inventory (Slack, Linear, Jira, Stripe, Postgres, Google
  Sheets, Discord, Expo, Firebase, Pinecone, Upstash, Clerk, Prisma, Cloudflare, Azure, Playwright,
  Maestro, Storybook, Chromatic, PostHog, Arize, Braintrust) have no connected MCP server in this
  session. Part C documents each truthfully as unavailable-in-this-environment rather than
  fabricating usage, per `<connectors>` fallback procedure.
- Merging any PR requires the repository owner's explicit approval; this experiment will not
  self-merge under any circumstance, consistent with `git-policy.md` `<safety>`.
