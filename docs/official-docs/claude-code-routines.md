# Claude Code — four autonomy patterns and official supporting mechanisms

**Source Reel:** https://www.instagram.com/reel/DgG3rhkNUzU/ (full English transcript recovered 2026-11-25).

The creator describes **four conceptual patterns**; these are not necessarily Anthropic's official product modes or mutually exclusive feature switches.

| Creator label | What it means in practice | Grounded implementation |
|---|---|---|
| Turn-based | Agent answers a bounded user request and stops | Normal interactive Claude Code workflow |
| Goal-based | Agent iterates toward a measurable acceptance target | A bounded task instruction plus tests/evaluations, max-cost/max-cycle limits, independent check |
| Time-based | Execute an approved task at an interval | Scheduled tasks/cloud routines where available; do not confuse local `/loop` with server-side scheduling |
| Proactive | A remote event triggers a workflow while user's device is off | Cloud routine/webhook/API trigger, least-privilege connected services and human approval of drafts |

## Official documentation and safety

- https://claude.com/resources/articles/introducing-routines-in-claude-code — cloud routines and automation.
- https://code.claude.com/docs/en/best-practices — official Claude Code task engineering and verification.
- https://support.claude.com/en/articles/14554000-claude-code-power-user-tips — official tips, local and scheduling distinctions.

Example from Reel: new sponsorship email → research company → compose **draft** → owner reviews. This is an architectural workflow, **not** permission to send email or approve a deal autonomously.

For unattended runs, enforce a maximum budget, duration, retries, allowed tools/targets, idempotent event receipt, rate limits, logs, secrets isolation, approval gates for sends/merges/spending, and independent test evidence. Never label a pipeline self-improved solely because it looped to an unverified benchmark.

**Status:** Reference pattern, not an installed agent; actual cloud routine depends on subscription, deployment and connected account. Do not infer that four independent Anthropic buttons exist from the Reel.
