# Merge readiness checklist

Owner: merge-governance. Referenced by the `Merge safety` and `Git/branch policy` rows in
[`operational-readiness-audit.md`](./operational-readiness-audit.md).

Merging is **Manual by design**: the merge decision itself is always human and is never
automated. This checklist defines the evidence a human (or an agent preparing evidence
for a human) must capture before any merge to `main`.

## Required evidence before merge

1. **Required workflows green for the exact head SHA.** Run
   [`scripts/enforcement/check-merge-readiness.sh`](../../scripts/enforcement/check-merge-readiness.sh)
   with the workflow-runs JSON for the PR head SHA. It fails closed unless every required
   Engineering OS policy workflow completed with `conclusion=success`. Record the command
   output and the head SHA it validated.
2. **Mergeable state checked live.** The PR reports `mergeable` (no conflicts) against
   the current base. Record the mergeable state and the base branch name.
3. **Expected head SHA pinned.** The SHA that was reviewed and validated is recorded;
   if new commits land after validation, the checklist restarts for the new SHA.
4. **Review threads resolved.** No unresolved review threads remain, or each remaining
   thread is explicitly acknowledged with a reason in the PR conversation.
5. **Review evidence present.** The PR body carries `## External Review Evidence` or
   `## Review Fallback Evidence` per the pr-policy gate, validated deterministically by
   [`scripts/enforcement/check-pr-review-evidence.sh`](../../scripts/enforcement/check-pr-review-evidence.sh)
   (fixtures: `scripts/enforcement/tests/test-pr-review-evidence.sh`). The same script also
   validates a required `## Merge Readiness` PR-body section — `base:`, `expected-head-sha:`,
   `ci:`, `threads:`, and `approval:` fields, with `expected-head-sha:` cross-checked against
   the PR's live head SHA and `checks:`/`ci:` required to name a real gate/workflow. This
   makes items 3 and 5 below deterministic; the `approval:` field records intent (e.g.
   "pending" or the owner's explicit go-ahead) — it documents the merge decision, it does
   not automate it.
6. **Superseded PRs closed.** No other open PR targets the same change; superseded PRs
   are closed or linked with a resolution note.
7. **Human approval captured.** The repository owner's explicit approval to merge is
   recorded in the PR conversation. Time pressure is not approval; silence is not
   approval.

## Explicit limitation

Items 2, 4, 6 require live GitHub state and cannot be proven by repository-local
checks alone; they are review-based by design. Item 1 is deterministic once the
workflow-runs JSON is captured.
