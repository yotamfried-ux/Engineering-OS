# Route Plan — generalize git remote URL to repo-slug parsing

## Route Plan

| Field | Decision |
|---|---|
| Task type | bug fix / telemetry runtime repair |
| Task class | `engineering_os_governance` |
| Domain tags | governance, observability, telemetry, git remotes |
| Plan Scope | standard |
| Planning Mode | approved — user confirmed proceeding with the real fix after the prior session's uncommitted-fix report was found to be inaccurate |
| Target paths | `scripts/monitoring/telemetry_handoff.py`; `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/telemetry_repo_discovery.py`; `scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py`; `.github/workflows/telemetry-handoff-tests.yml`; `lessons-learned/bugs/telemetry-repo-slug-github-com-only.md` |
| Task-router evidence | `core/task-router.md` used to route this as Engineering OS governance / internal bug fix touching `scripts/monitoring/` and CI workflow. |
| Workflow evidence | `core/workflow.md` used for experiment -> fix -> verify loop; `core/coderabbit-policy.md` used for branch -> PR -> CI -> CodeRabbit -> explicit approval before merge. |
| Templates | Not required — no registered template covers telemetry URL-parsing helpers. |
| Architecture guides | Not required — localized bug fix, no architectural change. |
| Patterns | Not required — no registered pattern covers git-remote-URL parsing. |
| External systems/connectors | GitHub |
| Skills | waiver |
| Validation gates | enforcement-tests; telemetry-handoff-tests; run trace; connector evidence; capability evidence; workflow evidence; documentation asset evidence; plan/PR policy; CodeRabbit review |
| Evidence to check | Live execution of the parsing functions against this repo's actual proxied origin; existing `scripts/enforcement/tests/` suite; `core/git-policy.md`; `core/coderabbit-policy.md` |
| User decisions required | none outstanding — user confirmed (a) implement the real fix now, (b) delete the stray `engineering-os-telemetry` branch on `yotamfried-ux/project-8` |

## Context

A prior session's self-report (delivered as the opening message of this session) claimed a fix for this exact bug was already written and only needed to be committed/pushed/merged. Investigation (Explore agent + direct repo reads, confirmed with the user via `AskUserQuestion`) showed that claim was false: no such branch existed, no uncommitted changes existed, no helper function existed anywhere in the repo. The underlying bug diagnosis was accurate, so this plan implements the real fix from scratch.

`sync-telemetry-run.py::repo_slug_from_url` only recognized `github.com/` and `github.com:` markers, so `detect_repo_slug()` (used by both the telemetry `sync()` and `--check` paths) could not determine repository identity on non-github.com origins — including this environment's proxied origin (`http://local_proxy@127.0.0.1:PORT/git/<owner>/<repo>`) — and hard-failed with `HandoffError`. A second, separate implementation in `telemetry_repo_discovery.py::_normalize_repo_slug` was more general (`git@`, `scheme://`) but was independently confirmed (by executing it live) to also fail on the same proxied URL shape, because it required exactly two path segments and the proxy inserts an extra `/git/` segment before `owner/repo`.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | This is Engineering OS governance / an internal bug fix requiring a Route Plan before implementation. |
| `core/workflow.md` | read | Experiment -> fix -> verify loop, with evidence backing every claim. |
| `core/coderabbit-policy.md` | read | Branch -> PR -> CI -> CodeRabbit -> explicit approval before merge; no auto-merge. |
| `core/git-policy.md` | read | Commit format, ready-for-review (non-draft) PR requirement, one-active-branch rule. |
| `scripts/monitoring/telemetry_handoff.py` | read/validated | Shared module; `validate_repo_slug` exists but no URL-parsing helper existed before this change. |
| `scripts/monitoring/sync-telemetry-run.py` | read/validated | `repo_slug_from_url` confirmed github.com-only by live execution against this repo's real origin. |
| `scripts/monitoring/telemetry_repo_discovery.py` | read/validated | `_normalize_repo_slug` confirmed to also fail on the proxied URL shape by live execution. |
| `scripts/enforcement/tests/test-telemetry-repo-attribution.py` | read | Existing regression guard requiring bare 3-component slugs to stay rejected — informed the URL-shape-gated leniency design. |

## Root cause

Two separate, diverging implementations of "git remote URL -> owner/repo" existed:

- `sync-telemetry-run.py::repo_slug_from_url` (github.com-only) — the one that actually determines repo identity for telemetry handoff.
- `telemetry_repo_discovery.py::_normalize_repo_slug` (used for hook-event repo attribution) — more general but still failed on this environment's proxied URL (extra `/git/` path segment).

A naive unconditional fix ("always take the last two path segments") would have broken `test-telemetry-repo-attribution.py`, which requires a bare (non-URL) 3-component string like `"other/example/repo-a"` to be rejected, not lenient-parsed — this guards against spoofable repo attribution from hook payloads. The fix scopes "last two segments" leniency to inputs recognized as URLs (`scheme://...` or scp-style `[user@]host:path`) only.

## Documentation Asset Evidence

- internal: `lessons-learned/bugs/telemetry-repo-slug-github-com-only.md` (new); this plan file.
- context7: not required — no external library, framework, SDK, or API is integrated; this is pure local Python/git-remote parsing logic already present in the repo.
- decision: unify both existing implementations behind one shared helper in `telemetry_handoff.py` rather than adding a third divergent implementation.

## Capability Evidence

- `routing.task-router-read` — routed as Engineering OS governance / internal bug fix.
- `workflow.workflow-read` — plan-first workflow used; this plan exists before the code change lands.
- `plan.route-plan-before-write` — this plan is committed before the fix implementation commit.
- `source.github-repo-read` — GitHub connector used to verify the prior session's claimed branch/PR/uncommitted-changes did not exist, to confirm the real leftover `engineering-os-telemetry` branch on project-8, and to open/monitor this PR.
- `validation.policy-change-has-validator` — this branch adds `scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py` and wires it into CI.
- `validation.actions-checked` — `.github/workflows/telemetry-handoff-tests.yml` is updated to run the new regression test in the `multirepo-dispatch` job.
- `validation.coderabbit-policy` — PR review required before merge; review findings addressed before merge.

## Skill Evidence

- waiver — no external-skill applies to this change: it is a narrow, internal Python git-remote-URL parsing fix with no UI, no new security-sensitive surface beyond what the existing attribution test already guards, and no skill-orchestration integration.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to verify the prior session's claims against real repo/branch/PR state, confirm the stray `engineering-os-telemetry` branch on project-8, open PR #252, and monitor CI/review activity. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: listed branches/PRs to verify (and refute) the prior session's uncommitted-fix claim; confirmed the stray telemetry branch on project-8 via the GitHub API; opened ready-for-review PR #252; subscribed to PR activity; reviewed CodeRabbit/Codex findings.
- result: the prior claim was disproven (no branch, no uncommitted changes existed); the real fix was implemented, tested, committed, and pushed; PR #252 opened against `main`.
- decision: implemented the fix from scratch on the existing branch rather than continuing to search for the prior session's nonexistent work; changed both `sync-telemetry-run.py` and `telemetry_repo_discovery.py` to share one helper instead of keeping the two divergent implementations.
- target: `scripts/monitoring/telemetry_handoff.py`, `scripts/monitoring/sync-telemetry-run.py`, `scripts/monitoring/telemetry_repo_discovery.py`, new regression test, CI workflow, lesson file.

## Claude Run Trace

- goal: make telemetry-handoff repo-slug detection work on any git remote URL shape (not just github.com), fixing a real hard-failure on this environment's proxied origin, without weakening the existing spoofing-resistant strictness of hook-event repo attribution.
- hypothesis: unifying both divergent implementations behind one shared helper in `telemetry_handoff.py`, with URL-recognition-gated "last two path segments" leniency (applied only to recognized URL/scp-style inputs, not bare slug strings), fixes the proxied-origin failure while preserving `test-telemetry-repo-attribution.py`'s existing rejection of bare 3-component slugs like `other/example/repo-a`.
- connectors: GitHub was used to verify the previously-claimed branch/PR/uncommitted-changes did not exist and to confirm a real leftover `engineering-os-telemetry` branch on project-8; no other external connector was needed for this fix (pure local Python/git logic).
- steps: investigated the prior session's claims against actual repo state; confirmed the discrepancy with the user via `AskUserQuestion`; designed the fix, reproducing the bug live against this repo's real proxied origin and checking it against the existing attribution test; implemented `parse_repo_slug_from_remote` in `telemetry_handoff.py`; updated `sync-telemetry-run.py::detect_repo_slug` and `telemetry_repo_discovery.py::_normalize_repo_slug` to delegate to it; added `scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py`; wired it into the `multirepo-dispatch` CI job; ran all existing telemetry test suites plus the full post-merge validation suite; opened PR #252; a CodeRabbit-adjacent automated review (Codex) flagged that the initial `git@`-only scp-style detection missed the general `[user@]host:path` grammar (e.g. `github.com:owner/repo.git` with no `user@` prefix); fixed by generalizing the scp-style branch to detect any `host:path` shape, added regression cases, and re-verified.
- evidence: live execution of `detect_repo_slug(Path('.'))` against this repo's real proxied origin returned `yotamfried-ux/Engineering-OS` (previously raised `HandoffError`); `python3 scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py` passed, including the added scp-style-without-`git@` cases; `python3 scripts/enforcement/tests/test-telemetry-repo-attribution.py` passed (bare 3-component slug still rejected); `test-remote-telemetry-handoff.sh`, `test-telemetry-policy-and-path-overrides.sh`, `test-telemetry-head-advancement.sh`, `test-telemetry-progress-ordering.sh`, `test-multirepo-dispatch.sh`, `test-dispatch-guard-settings.py` all passed unchanged; `scripts/enforcement/run-post-merge-validation-suite.sh` passed.
- rejected: unconditionally taking "the last two path segments" for every input (would have lenient-parsed the bare slug `other/example/repo-a` into a valid slug, breaking the existing attribution security test that requires that input be rejected); matching only literal `git@` prefix for scp-style remotes (missed valid forms like `github.com:owner/repo.git` and `alice@github.com:owner/repo.git`, per the Codex review finding); trusting the prior session's self-report without independent verification; auto-merging without explicit user approval.
- result: `parse_repo_slug_from_remote` added to `telemetry_handoff.py`, handling scheme URLs and the general scp-style `[user@]host:path` grammar; both call sites delegate to it; new regression test added and wired into CI; all existing and new tests pass; PR #252 opened, review finding addressed; nothing merged yet — awaiting CI/CodeRabbit/explicit merge approval.
- follow-up: watch GitHub Actions and CodeRabbit on PR #252, address any further comments, and only merge to `main` after Yotam gives explicit approval. Separately (unrelated to this PR): delete the stray synthetic `engineering-os-telemetry` branch on `yotamfried-ux/project-8` left over from the prior session's hook smoke test, per explicit user confirmation.

## Progress Lifecycle Evidence

- start: this Route Plan is committed before any code/config/test change, recording scope, root cause, and validation approach in advance.
- mid: commit `d466fc0` implements `parse_repo_slug_from_remote`, updates both call sites, adds the new regression test, wires it into CI, and adds the lesson file — all existing and new test suites pass, and a live check against this repo's real proxied origin confirms the fix.
- pre-merge: no further code/config/test changes follow commit `d466fc0` (this and the mid-checkpoint commit are plan-evidence-only). PR #252 is open, ready-for-review; CI and CodeRabbit results are being monitored, with any required fixes to land as additional code commits before merge if needed.

## Definition of Done

- [x] `parse_repo_slug_from_remote` added to `telemetry_handoff.py`, reusing the existing `REPO_SLUG_RE`, and handling scheme URLs plus the general scp-style `[user@]host:path` grammar (not just literal `git@`).
- [x] `sync-telemetry-run.py::repo_slug_from_url` removed; `detect_repo_slug` delegates to the shared helper and preserves its raise-on-failure, case-preserving contract.
- [x] `telemetry_repo_discovery.py::_normalize_repo_slug` reduced to a thin casefolding wrapper over the shared helper; dead `_REPO_COMPONENT_RE`/unused imports removed.
- [x] New regression test `test-telemetry-repo-slug-parsing.py` added and wired into `.github/workflows/telemetry-handoff-tests.yml`.
- [x] All existing telemetry test suites pass unchanged.
- [x] Live sanity check against this repo's real proxied origin returns the correct slug.
- [x] Full post-merge validation suite passes.
- [x] Bare 3-component slug strings (e.g. `other/example/repo-a`) remain rejected by `_normalize_repo_slug` (regression guard for hook-attribution strictness).

## Merge Gates

Merge remains blocked until GitHub Actions pass, CodeRabbit review is complete with findings addressed or explicitly justified, and Yotam gives explicit approval — no auto-merge, per `core/coderabbit-policy.md` and `core/git-policy.md` `<safety>`.
