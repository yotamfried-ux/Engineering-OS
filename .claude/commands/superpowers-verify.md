# Verification Before Completion — /superpowers-verify

Before marking any task as done, run this verification workflow:

1. **DoD check**: Read `.claude/plans/<current-plan>.md` — verify EVERY Definition of Done item.
   For each item: what is the evidence it's complete? (test output, log, UI screenshot, query result).
   "Looks correct" is not evidence — name the tool and the result.
2. **Regression check**: Did any existing tests break? Run the test suite and report pass/fail count.
3. **Edge cases**: Name 2 edge cases for the changes made. Are they handled?
4. **Security check**: Any new inputs, API endpoints, DB writes, or auth flows introduced?
   If yes — was the mandatory security-review **gate** run (`/security-review`)?
   (A bare `mcp__nemotron__nemotron_review_code` call is first-pass review only and does
   NOT satisfy the gate — the gate is the `/security-review` skill, which may itself run on Nemotron.)
5. **Cleanup check**: Dead code, debug logs (`console.log`, `print`), unused imports removed?

Output: checklist with ✅ or ❌ per item. If any ❌ — fix before committing.
Do NOT commit or report "done" until all items are ✅.

---

> This command is the portable equivalent of `superpowers:verification-before-completion`
> (L2 mandatory before done). Works in all environments — with or without the superpowers plugin.
> See `external-skills/superpowers/activation.md` for details.
