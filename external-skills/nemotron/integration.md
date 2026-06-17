# nemotron — integration.md

> מתי ואיך להשתמש. חוזה התנהגות מלא לשימוש ב-Engineering OS workflow.

---

## מתי לגשת לקובץ הזה

- לפני שמחליטים אם לקרוא ל-Nemotron בתוך משימה.
- לפני שמנסחים קריאה ל-MCP tool או לsub-agent.

---

## עיקרון בסיס

**קלוד הוא ה-orchestrator; Nemotron הוא ה-worker.**

קלוד מאסף הקשר (Read, Grep, graphify), מעביר ל-Nemotron, מקבל תוצאה,
**מאמת אותה**, ואז מחיל עם Edit/Bash. הפלט של Nemotron לעולם לא מוחל ישירות.

---

## כלים זמינים

### דרך MCP server (`nemotron` server):

| כלי | טריגר לשימוש |
|---|---|
| `nemotron_generate_code` | generation > ~50 שורות output צפוי |
| `nemotron_review_code` | diff > 100 שורות, לפני security gate |
| `nemotron_summarize` | קובץ/תוכן > ~200 שורות שצריך לתמצת |
| `nemotron_explain` | קוד לא מוכר, או הסבר לצורך העברת ידע |
| `nemotron_brainstorm` | צריך alternatives / גישות לפני בחירה |

### דרך sub-agents (`.claude/agents/`):

| agent | מתי להפעיל |
|---|---|
| `nemotron-code-reviewer` | diff גדול, first-pass לפני pragmatic-code-review |
| `nemotron-coder` | generation task עם context ברור |

---

## ניסוח קריאה נכונה — context-first

לפני כל קריאה ל-Nemotron, אסוף:
1. **מה לבצע** — task ברור, לא עמום
2. **ההקשר הרלוונטי** — קוד קיים, patterns, spec
3. **השפה/פורמט** — TypeScript, Python, Hebrew, וכו'

❌ לא: `nemotron_generate_code(task="write tests")` — context חסר.
✅ כן: `nemotron_generate_code(task="write unit tests for UserService.createUser()", context=<קוד הפונקציה + interfaces רלוונטיות>, language="TypeScript", output_type="tests")`

---

## מה **לא** להעביר ל-Nemotron

| משימה | למה נשארת ב-Claude |
|---|---|
| Security gate (security-review) | precedence רמה 3 — חובה, לא ניתן לדלגות |
| החלטה מה הצעד הבא | orchestration — קלוד מחליט |
| עריכת קבצים | Edit/Bash הם כלים מקוריים של קלוד |
| debugging עם stack trace | דורש ריצה + context מלא |
| ארכיטקטורה עם trade-offs עמוקים | דורש ידע context של הפרויקט |
| משימה קטנה (<10 שורות output) | overhead של MCP call לא שווה |

---

## workflow מייצג

```
1. Claude מקבל בקשה לכתיבת module חדש (גדול)
2. Claude קורא קבצים רלוונטיים (Read/graphify) — אוסף context
3. Claude קורא: nemotron_generate_code(task, context, language, output_type="code")
4. Nemotron מחזיר implementation
5. Claude קורא את הקוד, מאמת correctness
6. Claude מחיל עם Edit
7. Claude מריץ /security-review לפני merge (חובה)
```

---

## גרסה ראשונית — מה עדיין לא נתמך

- Nemotron עם tool calling עצמאי (v2 — Nemotron כ-agent שמשתמש ב-graphify/Context7)
- claude-mem summarization ב-Nemotron (claude-mem הוא Anthropic-only כרגע)
- gstack role routing ל-Nemotron (gstack רץ על session model)
