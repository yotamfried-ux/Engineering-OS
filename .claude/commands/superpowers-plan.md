# Writing Plans — /superpowers-plan

Before writing any non-trivial code, create a plan:

1. **Goal**: One sentence — what will be done and why.
2. **Scope**: List the files that will change. What will NOT change (explicitly stated).
3. **Steps**: Numbered implementation steps, each small enough to be a single atomic commit.
4. **Definition of Done**: Measurable criteria — what does "done" look like?
   Each item must be verifiable by a tool (test output, DB query, log line, UI screenshot).
5. **Risks**: What could go wrong? How to detect it and recover?

Save this to `.claude/plans/<task-name>.md` before writing code.
The Write/Edit hook enforces this — code files are blocked without a plan file.

---

> This command is the portable equivalent of `superpowers:writing-plans`.
> Works in all environments — with or without the superpowers plugin installed.
> See `external-skills/superpowers/activation.md` for details.
