# superpowers — Orchestration Policy

## Classification

| Field       | Value                                          |
|-------------|------------------------------------------------|
| Type tags   | planning, review, orchestration, self-correction |
| Source repo | https://github.com/obra/superpowers            |
| Plugin ID   | `superpowers@claude-plugins-official`          |

## Execution Level

**LEVEL 2 — mandatory**

Trigger condition (both must be true):

1. The task is a **non-trivial multi-step development or debugging task** — i.e., it
   involves writing or modifying code, spans more than a trivial one-liner, and has
   a Definition of Done that requires verification.
2. The superpowers plugin is **installed and active** in the current Claude Code session
   (confirmed by `using-superpowers` skill being available).

If either condition is false, superpowers skills are not invoked.

LEVEL 2 means: when the trigger condition is met, using the appropriate superpowers skill
is not optional — it is the required first action before proceeding with the task.

## Composition rules

1. **Planning runs first.** `brainstorming` → `writing-plans` must complete before any
   file-modifying tool is called. Do not skip to `executing-plans` without a written plan.

2. **Never overrides a security-level skill.** If a `patterns/security/` rule or an
   Engineering OS hook (see [`core/hooks-policy.md`](../../core/hooks-policy.md)) conflicts
   with a superpowers workflow step, the security/hook rule wins. Example: a pre-commit
   hook that blocks a commit is not bypassed to satisfy `finishing-a-development-branch`.

3. **Review skills run last.** `requesting-code-review` and `receiving-code-review` are
   terminal-phase skills. They are never invoked before `verification-before-completion`
   confirms a green test suite.

4. **Parallel agents are opt-in.** `dispatching-parallel-agents` is invoked only when the
   plan contains genuinely independent tasks. Do not dispatch parallel agents for tasks
   that share mutable state or have ordering dependencies.

5. **`using-superpowers` is always available.** The SessionStart hook injects it
   automatically; do not manually invoke it as a pre-check — the hook handles that.

## Notes / caveats

- **Overhead on trivial tasks.** The full brainstorm → plan → worktree → TDD pipeline adds
  meaningful overhead. For throwaway scripts, one-liners, or read-only tasks, do not trigger
  LEVEL 2; skip superpowers entirely.

- **Opinionated and mandatory by design.** superpowers describes its workflows as
  "mandatory, not suggestions." This is intentional: the plugin is designed to steer Claude
  away from the most common failure mode (jumping directly to code without a spec). If a
  task feels like the workflow is overkill, reconsider whether it truly qualifies for LEVEL 2
  before skipping the skill.

- **No configuration surface.** superpowers has no env vars, no feature flags, and no
  per-project customization. The only knob is whether the plugin is installed or not.

- **Skills live in `~/.claude/skills/`** when installed. Custom skills that extend or
  override superpowers must also live there; they are not project-local by default.
