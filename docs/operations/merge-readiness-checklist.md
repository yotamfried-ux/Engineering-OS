# Merge readiness checklist

Owner: merge-governance. Referenced by the `Merge safety` and `Git/branch policy` rows in
[`operational-readiness-audit.md`](./operational-readiness-audit.md).

Merging is **Manual by design**: the merge decision itself is always human and is never
automated. This checklist defines the evidence a human, or an agent preparing evidence
for a human, must capture before any merge to `main`.

## Required evidence before merge

1. **Required workflows green on the exact reviewed head.** Resolve the live full head
   SHA, capture GitHub workflow-run JSON, and run:

   ```bash
   bash scripts/enforcement/check-merge-readiness.sh \
     --runs-json /tmp/workflow-runs.json \
     --expected-head-sha "$expected_head_sha"
   ```

   Every required run must retain `name`, `head_sha`, `run_attempt`, `id`, `status`, and
   `conclusion`, plus at least one non-empty provider timestamp among `run_started_at`,
   `updated_at`, and `created_at`. Either a top-level array or an object containing a
   `workflow_runs` array is accepted.

   The checker does not trust API list order or the first matching workflow name. It:

   - rejects a missing or malformed expected SHA;
   - rejects required-workflow entries with missing head identity;
   - filters candidates to the exact expected head;
   - selects the latest candidate by `run_started_at`, otherwise `updated_at`, otherwise
     `created_at`, followed by `run_attempt` and run `id` tie-breakers;
   - fails closed on missing or malformed exact-head ordering metadata; and
   - accepts only a selected run with `status=completed` and `conclusion=success`.

   A success from another head, an older successful attempt followed by a failure, or a
   latest pending attempt cannot satisfy this item. Record the command output and the
   exact SHA it validated.

2. **Mergeable state checked live.** The PR reports `mergeable` with no conflicts against
   the current base. Record the mergeable state and base branch.

3. **Expected head SHA pinned.** The SHA that was reviewed and validated is recorded. If
   any new commit lands after validation, restart this checklist for the new SHA.

4. **Review threads resolved.** No unresolved review threads remain, or each remaining
   thread is explicitly acknowledged with a reason in the PR conversation.

5. **Review evidence present.** The PR body carries `## External Review Evidence` or
   `## Review Fallback Evidence` per the pr-policy gate, validated deterministically by
   [`scripts/enforcement/check-pr-review-evidence.sh`](../../scripts/enforcement/check-pr-review-evidence.sh)
   (fixtures: `scripts/enforcement/tests/test-pr-review-evidence.sh`). The same script
   validates the required `## Merge Readiness` fields `base:`, `expected-head-sha:`,
   `ci:`, `threads:`, and `approval:`. The approval field records the human decision; it
   does not create or substitute for approval.

6. **Superseded PRs closed.** No other open PR targets the same change; superseded PRs
   are closed or linked with a resolution note.

7. **Human approval captured.** The repository owner's explicit approval to merge is
   recorded in the PR conversation. Time pressure is not approval; silence is not
   approval.

8. **Merge uses expected-head protection.** The merge operation must bind to the same
   head SHA that passed this checklist. If the provider rejects the expected SHA because
   the head changed, do not retry with the new head until the full checklist is rerun.

9. **Post-merge validation completed.** Re-fetch canonical `main`, verify the merge
   commit and required checks, and run any closure assertion required by the owning gap.
   Pre-merge success is not post-merge evidence.

## Explicit limitation

Items 2, 4, 6, 7, 8, and 9 depend on live GitHub state or human intent and cannot be
proven by repository-local fixtures alone. Item 1 is deterministic only after fresh,
complete workflow-run metadata has been captured for the exact reviewed head. The
checker validates machine evidence; it never authorizes a merge.
