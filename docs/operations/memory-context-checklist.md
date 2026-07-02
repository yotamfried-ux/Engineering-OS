# Memory / context carryover checklist

Owner: context-governance. Referenced by the `Claude memory / context carryover` row in
[`operational-readiness-audit.md`](./operational-readiness-audit.md).

This area is **Manual by design**: there is no reliable cross-environment runtime signal
that proves memory/context carryover actually informed a session (claude-mem is optional,
environment-dependent, and absent in most remote sessions). Engineering OS therefore does
not fake a runtime check; it requires an auditable manual evidence record instead.

## Required checklist (every `context_or_large_repo_work` task)

1. **Session memory status recorded.** The Route Plan or session notes state whether
   claude-mem (or another memory layer) was available at session start. The SessionStart
   output is the source for this statement — quote its claude-mem line.
2. **Carryover claims cite an artifact.** Any claim that prior-session context influenced
   a decision must cite a concrete artifact: a claude-mem observation id, a
   `lessons-learned/` file, a prior plan file, or a linked PR/issue. Uncited carryover
   claims are treated as unverified and must be removed or waived.
3. **Waiver when unavailable.** When no memory layer is available (typical for remote
   sessions), the plan's Capability Evidence records
   `memory_context_checked_or_waived` with the reason (for example: remote session,
   claude-mem not installed). This is the approved waiver path — do not skip silently.
4. **Reviewer confirmation.** The PR reviewer confirms the memory/context statement is
   present and its cited artifacts exist. This review confirmation is the required
   review evidence for this Manual-by-design row.

## Explicit limitation

Hidden reasoning is not provable. This checklist enforces only auditable external
evidence (recorded availability, cited artifacts, explicit waivers) — it never claims
to verify what the model internally remembered.
