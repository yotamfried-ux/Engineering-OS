# Connector Enforcement — Step 1

Status: required for the next Engineering OS phase.

## Problem

`core/connector-policy.md` defines when connectors such as GitHub, Notion, Context7, Sentry, Figma, Supabase, Vercel and others should be used. Today most of that policy is judgment-based and is not enforced by CI.

## Step 1 enforcement target

Every non-trivial code change must include a Route Plan under `.claude/plans/*.md` with a section named:

```md
## Connector Evidence
```

The section must list either:

```md
- [x] <Connector>: <what was checked / created / updated>
```

or:

```md
- [x] Not required: <why no external connector was needed>
```

## Why this is enforceable

A deterministic gate can check that code-changing PRs also changed a plan file and that the plan contains `Connector Evidence`. Later gates can validate connector-specific proof such as Notion page URLs, Sentry issue IDs, Vercel deployment IDs, or Figma links.

## Done for Step 1

- CI blocks code-changing PRs without a changed plan.
- CI blocks changed plans that do not include `Connector Evidence`.
- Target projects receive the same gate through the Engineering OS installer.
