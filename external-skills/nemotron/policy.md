# nemotron — policy.md

> כללי תזמור, classification, ורמת הרצה.
> חלק מה-SIP (Skill Integration Protocol).

---

## Classification

```
type: generation, review, context-optimization
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

## Composition Order (מקומו ב-SIP pipeline)

```
1. context-optimization (graphify) — ראשון תמיד
2. memory (claude-mem) — passiveב-SessionStart/Stop
3. planning (superpowers) — לפני כתיבה
   ↓
4. [NEMOTRON] generation worker — במהלך coding phase
   ↓
5. SECURITY GATE (security-review) — חובה, לא ניתן לדלגות
6. review (claude-code-workflows / pragmatic-code-review)
```

**nemotron רץ בתוך coding phase** — אחרי planning, לפני security gate.

---

## Override Rules

1. **Security gate גובר תמיד** — `security-review` רץ לאחר כל פלט של Nemotron, ללא יוצא מהכלל.
2. **Claude מאמת לפני שמחיל** — אין auto-apply של פלט Nemotron.
3. **Graceful degradation** — אם Nemotron נכשל, קלוד מבצע בעצמו. אין blocking.

---

## Security Scope של הסקיל עצמו

- `Nemotron_api_key` נקרא מה-environment בלבד, לא נכתב לקבצים.
- לא שולחים context עם secrets, credentials, או PII ל-Nemotron API.
- Context שנשלח הוא קוד ו-specs בלבד — לא DB passwords, JWT secrets, וכו'.
