# Post-merge incident checklist

Owner: merge-governance. Referenced by the `Post-merge validation` row in
[`operational-readiness-audit.md`](./operational-readiness-audit.md).

The post-merge validation workflow and its fake-gh repair-issue simulation are enforced
deterministically. **Live** negative runs on `main` are reviewed by a human — this
checklist defines the triage evidence required when a real post-merge failure occurs.

## Required triage evidence for a live main failure

1. **Repair issue link.** The auto-opened repair issue (from
   [`.github/workflows/post-merge-validation.yml`](../../.github/workflows/post-merge-validation.yml))
   is linked; if the automation failed to open one, open it manually and note the
   automation failure as its own finding.
2. **Failing run link.** The exact failing workflow run URL and the commit SHA on `main`
   that triggered it.
3. **Root cause statement.** What actually broke — the defect, not the symptom. If the
   root cause is unknown at triage time, the issue says so explicitly and stays open.
4. **Repair PR link.** The fix lands through a PR subject to the full gate suite; direct
   pushes to `main` are not a repair path.
5. **Lesson link.** A `lessons-learned/` entry (or an explicit waiver per
   [`core/learning-loop.md`](../../core/learning-loop.md)) is linked before the repair
   issue is closed — the learning-capture gate applies to repair work like any bug work.
6. **Reviewer confirmation.** A human confirms items 1–5 are present before closing the
   repair issue. This confirmation is the required review evidence for the
   review-based part of this row.
