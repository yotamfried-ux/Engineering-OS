# CI Failure Diagnosis — PR #87

**Date:** 2026-06-26  
**Branch investigated:** `route-package-v2`  
**Investigated by:** Claude Code session

## Root Cause

GitHub Actions jobs fail before any runner is assigned.  
**Not a code defect.** Cause: GitHub Actions free-tier minutes quota exhausted (or spending limit at $0).

## Definitive Evidence

| Signal | Value | Meaning |
|---|---|---|
| `billable.UBUNTU.duration_ms` | `0` | No runner time consumed — runner never started |
| `runner_id` / `runner_name` | `0` / `""` | No runner assigned |
| Steps in job API response | absent | No steps executed |
| Log download | HTTP 404 | No log file exists |
| Job wall time | 3–4 s | Immediate queue-level failure |
| Same pattern on PR #86 | yes | Persistent, not transient |

A runner executing even one shell command would register ≥1,000 ms billable time.  
`duration_ms: 0` is definitive proof the runner never started.

## PR #87 Code Quality

All 5 policy checks were traced against the actual PR content and would pass once a runner starts:

- `pr-policy` — PR is not draft ✅
- `plan-policy` — all plan items are `[x]` ✅
- `workflow-evidence-policy` — plan committed before code (commit 1 = plan, commit 2 = SKILL.md); all 6 required fields present ✅
- `connector-evidence-policy` — `## Connector Evidence` section present ✅
- `enforcement-tests` — SKILL.md validates correctly against `test-route-package.sh` ✅

## Required Fix

Manual action in GitHub account settings — no repository changes needed:

1. Go to **github.com → Settings → Billing and plans → Usage this month**
2. Under **GitHub Actions**, check minutes used vs. plan limit (Free: 2,000 min/month for private repos)
3. Choose one:
   - Set spending limit > $0 (requires payment method)
   - Wait for billing cycle to reset (1st of month)
   - Upgrade to GitHub Pro (3,000 min/month)

## Verification

After fixing billing: re-trigger all 5 failed workflows from the Actions tab on PR #87.  
All should produce step logs within 60 s and pass.
