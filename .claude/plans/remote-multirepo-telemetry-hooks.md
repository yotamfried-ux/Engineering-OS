# Route Plan — Remote multi-repository telemetry hooks

## Route Plan

| Field | Decision |
|---|---|
| Task type | infrastructure / telemetry runtime repair |
| Task class | `engineering_os_governance` |
| Domain tags | governance, observability, privacy, cross-repository, Claude Code hooks |
| Plan Scope | project |
| Planning Mode | approved — the owner approved the architecture and later explicitly authorized completing and merging PR #250 once exact-head CI and review are clean |
| Target paths | `scripts/monitoring/`; dispatcher test suites; telemetry workflow; operational runbook; known-gaps and readiness audit |
| Templates | waiver — no Engineering OS template owns a Claude Code user-level hook dispatcher |
| Architecture guides | `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`; `docs/operations/managed-settings-deployment-proof.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | waiver — no registered pattern covers cross-repository Claude hook attribution; existing per-repository telemetry entry points are reused instead |
| External systems/connectors | GitHub; Claude Code settings/hooks runtime |
| Skills | security review and verification-before-completion behavior are required by the privacy-sensitive runtime scope |
| Validation gates | telemetry-handoff-tests; enforcement-tests; pr-policy; plan/workflow/connector/capability/documentation/cleanup policies |
| Evidence to check | PR #250, its exact-head Actions runs and review threads; official Claude Code settings/hooks documentation; live Remote experiment evidence; test fixtures |
| User decisions required | none outstanding — implementation and conditional squash merge are authorized |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| Official Claude Code settings/hooks documentation | checked through the dedicated documentation agent before implementation | User-level `$HOME/.claude/settings.json` applies across sessions, while project settings are tied to the project/session scope; hooks from settings scopes merge rather than override. |
| `scripts/monitoring/require-telemetry-session.sh` | read | The guard is intentionally fail-closed for a managed repository without a matching current SessionStart and therefore must never run globally before repository attribution. |
| `scripts/monitoring/eos-telemetry-session-start.sh` | read and fixture-tested | It owns per-repository run initialization and rotation; the dispatcher should delegate rather than duplicate this state model. |
| `scripts/monitoring/eos-telemetry-event.sh` | read and fixture-tested | It retains the metadata-only privacy contract and repository-local event schema. |
| `scripts/monitoring/record-and-sync-telemetry.sh` and downstream handoff scripts | read and compatibility-tested | Push, manifest, branch/head and PR matching stay per-repository and are not redesigned by this change. |
| PR #250 live Remote experiment | partially validated | User-level installation and dynamic hook loading were observed in a real Remote host. The experiment found two real defects before the session became correctly blocked and required restart. A fresh successful end-to-end session is still required. |

## Root Cause

A Claude Code Remote session may begin from a parent directory rather than inside
`project-8` or `Engineering-OS`. In that shape, repository-local hook settings are
not active, so telemetry never starts. A user-level hook is therefore required,
but a user-level hook has no single repository identity of its own.

The first implementation had two unsafe assumptions:

1. It treated project-local hook entries found on disk as if they were active in
   the current session. Parent-started sibling repositories were skipped even
   though their project settings had never loaded.
2. When exactly one managed repository was discovered, it attributed any event
   without a successful in-repo match to that repository. An explicit outside
   path such as an unmanaged file could therefore inherit the managed repo's hard
   guard and block every tool call in the host session.

The repair separates **presence on disk** from **active hook scope**, and treats an
explicit outside-repository signal as evidence against repository attribution,
not as permission to use a sole-repository fallback.

## Architecture

### User-level bootstrap

`scripts/monitoring/install-user-level-telemetry-hooks.sh` safely merges
Engineering-OS-owned commands into `$HOME/.claude/settings.json` without sudo.
Installation is idempotent, preserves unrelated settings/hooks, verifies exact
commands and runtime paths, writes atomically with backups, and supports dry-run
and uninstall.

The user-level PreToolUse guard is not invoked directly. It runs as:

`eos-telemetry-dispatch.sh guard`

The dispatcher first proves the repository target. An unattributed or unmanaged
event is not blocked by another repository's policy. A safely attributed managed
repository still receives the existing fail-closed guard unchanged.

### Managed repository discovery

1. If the event/session cwd is inside a Git repository with a valid
   `.engineering-os/telemetry-policy.json`, discover that repository.
2. Otherwise scan immediate child directories only; never recursively scan the
   user's home directory.
3. Require each candidate to be its own Git root with a valid non-escaping policy
   marker.
4. Resolve and deduplicate real paths, then sort deterministically.

Project-local direct hooks are suppressed only for the native repository of an
**actual SessionStart** inside that repository. A sibling's settings file merely
existing on disk does not make those hooks active in a parent-started session.
A non-SessionStart cache miss also does not infer active project-local hooks.

### Event attribution

Evidence order:

1. Explicit path-like tool input, realpath-resolved.
2. Hook payload cwd.
3. Explicit GitHub/MCP repository identifier matched to the discovered repo's
   real `origin` slug.
4. Sole-repository fallback only when the payload contains no routing signal at
   all.

Any explicit path, cwd or repository identifier that points outside the managed
set makes the event unattributed. The dispatcher never replaces that evidence
with the sole discovered repository. Unattributed diagnostics contain event type,
host correlation and timestamp only — no raw command, prompt, path or payload.

### Per-repository isolation

The dispatcher changes cwd to the resolved root and invokes the existing
per-repository SessionStart, recorder, guard or boundary script. Each repository
keeps its own run id, events file, policy, branch/head and handoff state. A shared
host correlation id is additive and never substitutes for a repository run id.
The existing push, manifest and PR-matching pipeline remains unchanged.

### Failure behavior

- A managed, attributed repository retains existing required/best-effort/disabled
  semantics.
- Unmanaged and unattributed activity is outside enforcement scope.
- Resolver failures are distinguishable from normal unattributed events through a
  metadata-only `dispatch-errors.jsonl` record containing a diagnostic hash rather
  than raw stderr or hook payload.
- Dispatch-session cache files are pruned on SessionStart after a bounded retention
  period instead of growing indefinitely.

## Privacy and Security

- Only explicit Engineering-OS policy markers opt repositories in.
- No recursive filesystem monitoring is introduced.
- Raw prompts, responses, tool inputs, commands, paths, file contents, environment
  values and secrets are not written to telemetry or diagnostics.
- Marker and event paths are resolved before boundary checks; symlink/path traversal
  cannot make an outside target appear inside a managed repo.
- A user-level guard cannot convert one repository's required policy into a global
  host-session blocker.

## Validation Matrix

- Existing in-repository telemetry behavior and downstream handoff remain covered
  by the pre-existing telemetry suites.
- Parent discovery proves managed siblings are found and unmanaged siblings are not
  touched.
- Installer tests cover new/existing settings, exact verification, stale path
  detection, idempotent update, malformed JSON refusal, dry-run, uninstall and
  actionable missing-runtime failures.
- Coexistence tests distinguish native active project hooks from inactive sibling
  settings and mid-session cache misses.
- Attribution tests cover explicit file paths, cwd, GitHub repository identifiers,
  outside-repository rejection, ambiguous events and cross-repository isolation.
- Guard tests prove an unmanaged explicit path is not blocked, an attributed managed
  path is blocked before SessionStart, and that same path passes after a matching
  SessionStart.
- Failure tests cover malformed policies/payloads, path traversal, run-id rotation
  and empty lifecycle fan-out.
- Downstream compatibility tests retain repository/branch/head/PR matching isolation.

## Live Claude Code Remote Evidence

A real Remote host experiment was started before merge:

- the dispatcher was installed into the real `$HOME/.claude/settings.json`;
- installer verification passed;
- hooks were observed loading dynamically during the existing session;
- the project-local-scope defect was reproduced, diagnosed and corrected;
- after that correction, the managed-repository guard correctly detected that the
  installation occurred after the current session began and required a restart;
- the sole-repository fallback defect then made that correct guard apply to an
  unrelated file operation, locking the session as a whole and proving the need for
  repository-scoped guard dispatch.

This is real failure evidence, not a simulation, but it is not a successful closure
run. `multirepo-remote-telemetry-validation` remains open until a genuinely fresh
session proves successful discovery, attribution, unmanaged exclusion, bundle
creation and PR matching after the merged repair.

## Documentation Asset Evidence

- internal: `docs/operations/remote-multirepo-telemetry-hooks.md`, `docs/operations/project8-telemetry-preflight.md`, `docs/operations/managed-settings-deployment-proof.md`, `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- context7: not required — no third-party library, framework or SDK is integrated; the external behavior is Claude Code itself and was checked against its official settings/hooks documentation.
- decision: use the narrower user-level bootstrap rather than sudo-managed machine settings, while preserving explicit repository opt-in and existing downstream telemetry contracts.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS governance and telemetry runtime work.
- `workflow.workflow-read` — followed plan-first, evidence checkpoints, exact-head validation and merge authorization rules.
- `source.docs-read` — official Claude Code hook/settings behavior was checked before design decisions.
- `source.github-repo-read` — PR #250 files, Actions diagnostics and live review threads were inspected through GitHub.
- `validation.policy-change-has-validator` — dispatcher, installer, attribution, guard, policy, failure and downstream compatibility fixtures exercise every changed contract.
- `validation.coderabbit-policy` — Codex and CodeRabbit findings are fixed or explicitly reviewed before resolution and merge.

## Connector Evidence

- GitHub was required to inspect and update `yotamfried-ux/Engineering-OS`, read PR #250 review findings, examine exact workflow failures and validate the final reviewed head.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`.
- action: inspected PR #250 at original head `aaa498b7587cefc6653c49320877c4d1ed9ec87c`, its review threads and Actions run `29705789876`, then updated the dispatcher, resolver, attribution, installer and regression tests on the PR branch.
- result: commits from `aae837411da5f530e8d9d35e7153f5e90c9a2049` through `a4f2e4c1b8949e10043096c59c7249e5f61efb6e` implement evidence-safe attribution, actual-SessionStart hook coexistence, repository-scoped guard dispatch, exact installer verification and live-bug regressions.
- decision: fix the root attribution/scope contracts rather than weaken `require-telemetry-session.sh` or bypass its correct restart requirement.
- target: `scripts/monitoring/telemetry_repo_discovery.py`, `scripts/monitoring/eos-telemetry-dispatch-resolve.py`, `scripts/monitoring/eos-telemetry-dispatch.sh`, `scripts/monitoring/patch-settings-telemetry.py`, installer and dispatcher test suites.

## Claude Run Trace

- goal: collect reliable per-repository telemetry in parent-started Claude Code Remote sessions without monitoring unmanaged work or globally blocking the host session.
- hypothesis: a user-level bootstrap plus evidence-first repository attribution can reuse the existing per-repository telemetry pipeline safely.
- connectors: GitHub; official Claude Code documentation agent during the source-of-truth phase.
- steps: verify settings scope; create plan-first commit; implement installer/discovery/attribution/isolation; add tests and docs; open PR #250; run live Remote experiment; diagnose two live defects; read CI and review findings; scope project-local suppression to actual SessionStart; route guard through attribution; reject explicit outside signals; add MCP repo matching, exact verification and regressions; rerun exact-head gates.
- evidence: PR #250, plan-first commit `9c10bae`, live Remote session report, review threads, dispatcher test files and GitHub Actions.
- rejected: disabling the hard guard globally — rejected because it would hide missing SessionStart evidence inside managed repositories; treating on-disk project settings as active — rejected by the live parent-started experiment; sole-repo fallback after explicit outside evidence — rejected because it caused the session-wide deadlock.
- result: deterministic fixes and regressions are implemented; fresh-session success remains a separately tracked live validation step.

## Progress Lifecycle Evidence

- start: Route Plan commit `9c10bae` preceded implementation.
- mid: implementation/test commits built installer, discovery, attribution, isolation, policy and downstream compatibility before PR review; the live Remote experiment then produced two concrete failures rather than a false success claim.
- pre-merge: commits `aae837411da5f530e8d9d35e7153f5e90c9a2049` through `a4f2e4c1b8949e10043096c59c7249e5f61efb6e` repair the live and review findings; the final exact-head SHA and Actions/review evidence will be recorded after the last correction.

## Definition of Done

- [x] User approved the architecture and implementation.
- [x] User-level installation is idempotent, exact-verifiable and reversible.
- [x] Discovery is managed-only, bounded, deterministic and symlink-safe.
- [x] Per-repository telemetry state and host correlation remain isolated.
- [x] Native active project hooks are deduplicated without suppressing inactive siblings.
- [x] Explicit outside-repository evidence cannot trigger sole-repo fallback.
- [x] The hard telemetry guard is applied only after safe repository attribution.
- [x] Explicit GitHub/MCP repository identifiers are supported for discovered repos.
- [x] Diagnostics retain the metadata-only privacy contract.
- [x] Existing downstream handoff and PR matching remain in scope for regression validation.
- [x] A real Remote attempt was documented honestly and the successful fresh-session closure gap remains open.
- [ ] All required workflows pass on the exact final head.
- [ ] All valid review findings are fixed and every thread is resolved.
- [ ] The PR body records final Operational Work History, Operational Behavior, review and Merge Readiness evidence.
- [x] The repository owner authorized squash merge once the preceding exact-head gates are clean.
