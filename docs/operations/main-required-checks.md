# main — required status checks (branch protection)

> **Owner:** operations runbook. This document is the source of truth for *which*
> CI checks must gate `main`. The list below is kept in sync with the deterministic
> merge gate `scripts/enforcement/check-merge-readiness.sh`
> (`REQUIRED_WORKFLOWS_DEFAULT`) by
> `scripts/enforcement/tests/test-required-workflows-contract.sh` — if the two drift,
> that test fails in CI.

## Status of enforcement

`check-merge-readiness.sh` enforces these checks **client-side / pre-merge** (an agent
or operator must run it against the PR head SHA before merging). That is a deterministic
gate, but it is *not* server-side branch protection: GitHub itself will still allow a
merge if the gate is skipped.

**Server-side branch protection must be applied manually** in the GitHub UI (or via the
GitHub API with sufficient admin scope). The execution environment used to author this
change has **no branch-protection / ruleset write API access**, so this requirement is
documented here as a manual follow-up rather than claimed as already-applied.

## Required status checks for `main`

These are the checks that must be **required to pass before merging** into `main`:

<!-- required-checks:begin -->
enforcement-tests
pr-policy
connector-evidence-policy
workflow-evidence-policy
capability-evidence-policy
plan-policy
<!-- required-checks:end -->

> CodeRabbit is intentionally **not** in this list yet (no active subscription/credits).
> Add it as a required check once the subscription is active.

## Recommended branch-protection / ruleset settings for `main`

Apply via **Settings → Branches → Branch protection rules** (or a repository ruleset):

- **Require a pull request before merging** — no direct pushes to `main`.
- **Require status checks to pass before merging** — select every check in the
  `required-checks` block above.
- **Require branches to be up to date before merging** — re-run checks against the
  latest `main` before allowing merge (enable if the team can tolerate the extra reruns).
- **Block force pushes** to `main`.
- **Block deletion** of `main`.
- (Optional) **Require linear history** / squash-only merges, matching the project's
  squash-merge convention.

## How to apply manually

1. Open the repository on GitHub → **Settings** → **Branches** (or **Rules → Rulesets**).
2. Add/edit a rule targeting `main`.
3. Enable the items in *Recommended settings* above and add each check from the
   `required-checks` block as a required status check.
4. Save. Verify by opening a PR and confirming the merge button is blocked until all
   required checks are green.

## Status-check contexts (what to select in branch protection)

GitHub branch protection identifies a required check by its **check-run / job name**, which is
**not** always the workflow name. Select these contexts (derived from each workflow's job `name:`,
falling back to the job id):

| Workflow (file) | Branch-protection context |
|---|---|
| `enforcement-tests` | `enforcement-tests` |
| `pr-policy` | `Require ready-for-review PR` |
| `connector-evidence-policy` | `Require connector route plan evidence` |
| `workflow-evidence-policy` | `Require Engineering OS workflow evidence` |
| `capability-evidence-policy` | `Require capability evidence in changed plans` |
| `plan-policy` | `Require completed plan checklists` |

`scripts/ops/apply-main-branch-protection.sh` derives this mapping automatically from the workflow
files, so it stays correct if a job is renamed.

## How to apply with the ops scripts

Run from the repo root **with repo-admin credentials** (this is the owner's step — the Engineering
OS agent environment cannot reach the admin API):

```bash
# 1. Branch protection (dry-run prints the exact request; --apply performs it)
bash scripts/ops/apply-main-branch-protection.sh            # preview
bash scripts/ops/apply-main-branch-protection.sh --apply    # apply (needs gh or $GITHUB_TOKEN)

# 2. Prune merged + superseded branches (dry-run lists them; --apply deletes)
bash scripts/ops/prune-merged-branches.sh                   # preview
bash scripts/ops/prune-merged-branches.sh --apply           # delete
```

Both scripts are **dry-run by default**, idempotent, and self-verifying: the protection script
derives the 6 contexts from the workflow files, and the prune script only deletes branches that are
ancestor-merged into `origin/main` or in its explicit superseded allowlist (it never deletes `main`
or the current branch).

## Keeping this in sync

Do **not** edit the `required-checks` block by hand to diverge from
`check-merge-readiness.sh`. The single source of truth for the *set* of required
workflows is `REQUIRED_WORKFLOWS_DEFAULT` in that script; this document mirrors it for
human/operator use, and the contract test asserts they match exactly.
