# Main Required Checks

This runbook defines the checks that must protect `main`.

## Required workflow names

Keep this list synchronized with `scripts/enforcement/check-merge-readiness.sh`:

- enforcement-tests
- pr-policy
- connector-evidence-policy
- workflow-evidence-policy
- capability-evidence-policy
- plan-policy

## Repository setting

The GitHub repository must require the workflow names above before merging to `main`.

If direct Ruleset / Branch Protection API access is unavailable in the current connector session, configure it manually in GitHub UI and keep this file as the auditable source for the expected check names.

## Agent merge rule

Agents must fetch workflow runs for the PR head SHA and run `scripts/enforcement/check-merge-readiness.sh` before using a merge API.
