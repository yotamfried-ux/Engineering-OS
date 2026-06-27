# resource-management.md — ניהול משאבים

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - לפני בחירת מודל ל-LLM call או sub-agent.
> - לפני הפעלת sub-agent — לבדוק אם צריך agent כלל.
> - כשכותבים תשובה — לקרוא את מדיניות הפלט.
> - בתחילת פרויקט חדש — ליצור `.claudeignore`.
> - כשמוסיפים AI agent לאפליקציה — לקרוא `<ai-agent-quotas>`.

**עיקרון-העל:** כל טוקן מיותר הוא עלות ישירה. חיסכון ברמת ה-OS מצטבר על פני
כל פרויקט ותורם לאיכות העבודה (פחות context clutter = התמקדות טובה יותר).

---

## <model-selection>

**ברירת מחדל: `claude-sonnet-4-6`** — לרוב המשימות. אל תחליף בלי סיבה מפורשת.

| סוג משימה | מודל מומלץ | model ID |
|---|---|---|
| ארכיטקטורה, security review, debugging מורכב, multi-step reasoning | Opus | `claude-opus-4-8` |
| קוד, refactoring, PR review, debug רגיל, **ברירת מחדל** | Sonnet | `claude-sonnet-4-6` |
| lookup מהיר, summarization, monitoring agents, sub-agents פשוטים | Haiku | `claude-haiku-4-5-20251001` |

**כללים:**
- **אל תעלה מודל** (Sonnet → Opus) ללא טריגר מפורש: יותר מ-3 שלבים תלויים, security gate, ארכיטקטורה.
- **Haiku לsub-agents**: כל agent שמטרתו בלבד חיפוש/lookup — דווח ב-model override.
- **לעולם אל תציין מודל ב-commit messages, PR bodies, או comments בקוד.**

> **אכיפה דטרמיניסטית** (`scripts/enforcement/enforce-resource.sh`, נקרא מ-`commit-msg`):
> הודעת קומיט שמכילה מזהה-מודל (`claude-<tier>-N`) נחסמת. מוגבל להודעות commit בלבד —
> קוד שמציין מודל לגיטימית (AI apps) אינו נסרק. bypass: `EOS_BYPASS_MODELID=1`.

</model-selection>

---

## <nemotron-routing>

**Nemotron (Nvidia) — מתי לאצול משימה במקום לבצע ב-Claude:**

| משימה | לאן | טריגר |
|---|---|---|
| יצירת קוד / boilerplate | `nemotron_generate_code` | output צפוי > ~50 שורות |
| כתיבת unit tests | `nemotron_generate_code` (output_type=tests) | test suite שלם |
| כתיבת docs/docstrings | `nemotron_generate_code` (output_type=documentation) | docs גדולים |
| first-pass code review | `nemotron_review_code` / agent `nemotron-code-reviewer` | diff > 100 שורות |
| סיכום קובץ/PR/log | `nemotron_summarize` | תוכן > 200 שורות |
| הסבר קוד לא מוכר | `nemotron_explain` | כל גודל |
| brainstorming גישות | `nemotron_brainstorm` | צריך > 3 alternatives |

**כללי אצבע:**
- generation קטנה (<10 שורות) — Claude ישירות, overhead של MCP call לא שווה.
- **לעולם אל תעביר** ל-Nemotron: security gate, orchestration, edit קבצים, context עם secrets.
- **תמיד** אמת פלט Nemotron לפני שמחיל עם Edit.
- graphify non-code extraction — אוטומטי דרך `OPENAI_API_KEY` שמוגדר ב-`session-setup.sh`.

**כשאין `Nemotron_api_key` — fallback מותר ואסור:**
- ✅ מותר: Claude Code ישירות (in-session generation/review)
- ✅ מותר: graphify עם `--no-label` (ללא LLM naming)
- ❌ **אסור בהחלט: `ANTHROPIC_API_KEY`** — אף skill, graphify, או כלי אחר לא יופנה ל-Claude API כ-fallback. אם כלי מנסה לגלות `ANTHROPIC_API_KEY` אוטומטית — חסום אותו (למשל `--no-label` ב-graphify).

ראה: [`../external-systems/nvidia-nemotron/orchestration.md`](../external-systems/nvidia-nemotron/orchestration.md)

</nemotron-routing>

---

## <sub-agents>

Sub-agents (Agent tool) מתאימים כשיש עבודה שאפשר להקביל או שתאסוף context רב
מדי בשיחה הראשית. השאלה לפני spawn: "האם Grep/Read אחד-שניים מספיקים?"

### מתי כן להפעיל

| מצב | סוג |
|---|---|
| חקירת קוד פתוחה (לא יודעים מה נמצא) | Explore agent, foreground |
| שתי חקירות **עצמאיות** שצריך את שתיהן | 2 Explore agents במקביל |
| תוצאת החקירה נחוצה לפני שממשיכים | foreground |
| בנייה/tests שאינה תלויה בקוד שנכתב כרגע | background |

### מתי לא

- **שאלה אחת ממוקדת** — Grep/Read ישיר מהיר יותר ולא מבזבז context.
- **פחות מ-3 שאלות** — כתוב בשיחה הראשית.
- **agent תלוי בתוצאת agent אחר** — הפעל בסדרה (sequential), לא מקביל.

### כללי הפעלה

```
מקסימום מקבילי: 3 agents
מודל: Haiku לlookup; Sonnet לקוד/ניתוח; Opus לארכיטקטורה (נדיר)
foreground vs. background: foreground כשצריך תוצאה לפני המשך
```

**בכל prompt לsub-agent**: ציין context מינימלי — קבצים ספציפיים, לא "קרא הכל".

</sub-agents>

---

## <token-output>

**מדיניות ברירת מחדל: קצר ומדויק.**

| סיטואציה | כלל |
|---|---|
