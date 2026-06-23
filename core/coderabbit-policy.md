# coderabbit-policy.md — CodeRabbit review gate

This policy defines the review gate for changes to Engineering OS itself.

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
2. Open a pull request into `main`.
3. Wait for GitHub Actions.
4. Wait for CodeRabbit review.
5. Address CodeRabbit comments, or document why a comment is not applicable.
6. Ask Yotam for explicit approval before merging into `main`.

Do not merge into `main` without explicit approval, even if all checks pass.

## Required PR checklist

Every pull request should include:

```md
## Validation
- [ ] GitHub Actions passed
- [ ] CodeRabbit reviewed
- [ ] CodeRabbit comments addressed or explicitly justified
- [ ] Yotam approved merge to main
```

## CodeRabbit feedback loop

When CodeRabbit leaves comments:

1. Read all comments before making targeted fixes.
2. Classify each comment as correctness, security, maintainability, test coverage, documentation, or false positive.
3. Fix correctness, security, and test coverage issues first.
4. Update or add validation when the comment reveals an uncovered failure mode.
5. If a comment is a false positive, leave a short explanation in the PR discussion.
