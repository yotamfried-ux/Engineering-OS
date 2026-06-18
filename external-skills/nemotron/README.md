# nemotron — Nvidia Nemotron LLM Integration

> חלק מה-Engineering OS Skill Registry.
> קובץ זה הוא ה-identity card של הסקיל. ראה `integration.md` לחוזה ההתנהגות,
> `policy.md` לכללי התזמור, ו-`activation.md` להתקנה ואימות.

## מה זה

חיבור ל-Nemotron-Ultra-253B ו-Nemotron-Super-49B של Nvidia דרך MCP server מקומי.
מאפשר לקלוד לאצול משימות generation ו-review כבדות ל-Nvidia API (חינמי, OpenAI-compatible)
תוך שמירה על קלוד כ-orchestrator ומפקח.

## מה הסקיל כולל

| רכיב | תיאור |
|---|---|
| `scripts/nemotron-mcp-server.py` | MCP server עם 5 כלים (uv inline deps, ללא install נפרד) |
| `.mcp.json` | רישום project-scoped של השרת |
| `.claude/agents/nemotron-coder.md` | Sub-agent לgeneration (קוד / tests / docs) |
| `.claude/agents/nemotron-code-reviewer.md` | Sub-agent לfirst-pass code review |

## מודלים

| מודל | שימוש | הערות |
|---|---|---|
| `nvidia/nemotron-ultra-253b-v1` | generation, review, brainstorm | הכי חזק, 128K context |
| `nvidia/nemotron-super-49b-v1` | summarize, explain | מהיר יותר, מספיק לטקסט |

## Source / License

- API: [Nvidia Build](https://build.nvidia.com) — free tier
- OpenAI-compatible endpoint: `https://integrate.api.nvidia.com/v1`
- API Key: `Nemotron_api_key` (Claude Code secret)
- License: NIM API terms of service

## גרסה

ראשונית. רמת הרצה: **L1** (recommended, לא mandatory).
