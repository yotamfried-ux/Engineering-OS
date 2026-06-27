# nvidia-nemotron — orchestration.md

> מתי ואיך להשתמש במנוע Nemotron בתוך Engineering OS workflow: חוזה התנהגות,
> classification, ורמת הרצה. Nemotron הוא **מנוע / LLM backend**, לא skill —
> הוא מריץ יכולות (generation, review), אבל אינו יכולת תהליכית בפני עצמו.

---

## מתי לגשת לקובץ הזה

- לפני שמחליטים אם לאצול משימה למנוע Nemotron בתוך משימה.
- לפני שמנסחים קריאה ל-MCP tool או ל-runtime adapter (`nemotron-coder` / `nemotron-code-reviewer`).

---

## עיקרון בסיס

**קלוד הוא ה-orchestrator; Nemotron הוא ה-engine / worker.**

קלוד מאסף הקשר (Read, Grep, graphify), מעביר למנוע Nemotron, מקבל תוצאה,
**מאמת אותה**, ואז מחיל עם Edit/Bash. הפלט של Nemotron לעולם לא מוחל ישירות.
ה-adapters (`.claude/agents/nemotron-*`) הם רק גשר ריצה אל המנוע — הם לא מחליטים
ולא מחילים.

---

## כלים זמינים

### דרך MCP server (`nemotron` server):

| כלי | טריגר לשימוש |
|---|---|
| `nemotron_generate_code` | generation > ~50 שורות output צפוי |
| `nemotron_review_code` | diff > 100 שורות, first-pass לפני security gate |
| `nemotron_summarize` | קובץ/תוכן > ~200 שורות שצריך לתמצת |
| `nemotron_explain` | קוד לא מוכר, או הסבר לצורך העברת ידע |
| `nemotron_brainstorm` | צריך alternatives / גישות לפני בחירה |

### דרך runtime adapters (`.claude/agents/`):

| adapter | מתי להפעיל |
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
| Security gate (`/security-review`) | precedence רמה 3 — חובה, לא ניתן לדלגות. Nemotron הוא first-pass בלבד, לא השער. |
| החלטה מה הצעד הבא | orchestration — קלוד מחליט |
| עריכת קבצים | Edit/Bash הם כלים מקוריים של קלוד |
| debugging עם stack trace | דורש ריצה + context מלא |
| ארכיטקטורה עם trade-offs עמוקים | דורש ידע context של הפרויקט |
| משימה קטנה (<10 שורות output) | overhead של MCP call לא שווה |

---

## Classification (של המנוע)

```
capabilities: generation, review, context-optimization
```

| תג | הסבר |
|---|---|
| `generation` | יצירת קוד, tests, docs |
| `review` | first-pass code review לפני security gate |
| `context-optimization` | חיסכון ב-Claude tokens על generation כבד |

---

## Execution Level

**LEVEL 1** — Recommended (לא mandatory).

- קלוד **צריך** לשקול שימוש ב-Nemotron כשהמשימה תואמת לטריגרים הבאים.
- קלוד **יכול** לדלג אם יש סיבה ברורה (משימה קטנה, context מורכב מדי להעברה).
- אין חובה לדווח על דילוג.

### טריגרים להמלצה חזקה:

- generation task עם output צפוי > ~50 שורות
- code review על diff > 100 שורות (לפני pragmatic-code-review)
- סיכום קובץ/תוכן > 200 שורות
- brainstorming: צריך > 3 alternatives

---

## Composition Order (מקום המנוע ב-SIP pipeline)

```
1. context-optimization (graphify) — ראשון תמיד
2. memory (claude-mem) — passive ב-SessionStart/Stop
3. planning (superpowers) — לפני כתיבה
   ↓
4. [NEMOTRON engine] generation worker — במהלך coding phase
   ↓
5. SECURITY GATE (security-review) — חובה, לא ניתן לדלגות
6. review (claude-code-workflows / pragmatic-code-review)
```

**Nemotron רץ בתוך coding phase** — אחרי planning, לפני security gate.

> הערה: שער ה-security (`/security-review`) **עשוי** לרוץ על מנוע Nemotron כ-engine
> ה-primary שלו (ראה `external-skills/security-review/policy.md`), אבל זה השער עצמו —
> לא קריאת `nemotron_review_code` הגולמית של ה-first-pass. קריאה גולמית למנוע אינה
> מהווה מעבר בשער.

---

## Override Rules

1. **Security gate גובר תמיד** — `security-review` רץ לאחר כל פלט של Nemotron, ללא יוצא מהכלל.
2. **Claude מאמת לפני שמחיל** — אין auto-apply של פלט Nemotron.
3. **Graceful degradation** — אם Nemotron נכשל, קלוד מבצע בעצמו. אין blocking.

---

## Security Scope של המנוע עצמו

- `Nemotron_api_key` נקרא מה-environment בלבד, לא נכתב לקבצים.
- לא שולחים context עם secrets, credentials, או PII ל-Nemotron API.
- Context שנשלח הוא קוד ו-specs בלבד — לא DB passwords, JWT secrets, וכו'.

---

## גרסה ראשונית — מה עדיין לא נתמך

- Nemotron עם tool calling עצמאי (v2 — Nemotron כ-agent שמשתמש ב-graphify/Context7)
- claude-mem summarization ב-Nemotron (claude-mem הוא Anthropic-only כרגע)
- gstack role routing ל-Nemotron (gstack רץ על session model)
