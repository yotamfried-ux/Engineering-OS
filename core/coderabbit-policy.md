# coderabbit-policy.md — external review gate

This policy defines the external-review and fallback gate for changes to Engineering OS itself.
CodeRabbit is the preferred automated reviewer when a live PR shows that it is installed,
eligible, and reviewing that exact head. Its availability must be observed from the current
pull request; it must never be inferred from old reviews, repository prose, or the presence or
absence of one configuration file.

## When to use

Read this file before changing Engineering OS governance files, including:

- `CLAUDE.md`
- `CLAUDE.template.md`
- `core/`
- `scripts/`
- `.github/workflows/`
- `patterns/`
- `templates/`
- `external-skills/`

## Policy

Every non-trivial Engineering OS change must use this flow:

1. Work on a dedicated branch.
2. Open a pull request into `main` ready for review.
3. Wait for the required GitHub Actions on the exact PR head.
4. Inspect the live PR review state, review threads, check runs, and reviewer output for that exact head.
5. If CodeRabbit review is present, requested, pending, or otherwise active for the PR, wait for its current review cycle and address every valid comment. A pending or unresolved observed CodeRabbit review blocks merge.
6. If CodeRabbit is unavailable, not installed for the repository, ineligible for the PR, or produces no review after the live status check, do not claim that CodeRabbit reviewed. Record structured `Review Fallback Evidence` with reviewer/source, scope, checks, risks, decision, and a concrete artifact/PR/SHA; perform an exact-head self-review or another available external review.
7. Re-fetch all current and outdated review threads and resolve or justify every valid finding.
8. Ask Yotam for explicit approval before merging into `main`.

Do not merge into `main` without explicit approval, even if all checks and reviews pass.
Do not wait indefinitely for a reviewer that live evidence shows is unavailable, and do not
convert missing reviewer evidence into an invented success claim.

## Required PR checklist

Every pull request should include:

```md
## Validation
- [ ] Required GitHub Actions passed on the exact head
- [ ] Live reviewer availability and status checked
- [ ] CodeRabbit feedback addressed when present, or structured Review Fallback Evidence recorded when unavailable
- [ ] All current and outdated valid review threads resolved or explicitly justified
- [ ] Yotam approved merge to main
```

## CodeRabbit feedback loop

When CodeRabbit leaves comments:

1. Read all comments before making targeted fixes.
2. Classify each comment as correctness, security, maintainability, test coverage, documentation, or false positive.
3. Fix correctness, security, and test coverage issues first.
4. Update or add validation when the comment reveals an uncovered failure mode.
5. If a comment is a false positive, leave a short explanation in the PR discussion.
6. Re-run exact-head checks after code changes and re-fetch the thread state before claiming readiness.

## Fallback evidence contract

Fallback is valid only after a live availability check. The PR body must use the existing
`## Review Fallback Evidence` contract and include concrete values for:

- `reviewer:` — who or what performed the fallback review;
- `scope:` — exact changed paths and review boundary;
- `checks:` — named test, checker, CI, or workflow signals;
- `risks:` — specific failure modes reviewed;
- `decision:` — fixes, accepted limitations, or clean-review outcome;
- `evidence:` — a PR URL, commit SHA, artifact path, workflow run, or equivalent identifier.

Fallback does not waive GitHub Actions, thread reconciliation, exact-head self-review, or
explicit owner approval. If CodeRabbit later becomes active on the same PR, its pending or
new valid findings re-enter the completion gate.
