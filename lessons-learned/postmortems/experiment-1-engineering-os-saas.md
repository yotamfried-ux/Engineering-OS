# Post-Mortem: Engineering OS Experiment — Expiriens SaaS 0.2

**תאריך:** 2026-06
**משך:** ~1 ניסוי
**חומרה:** System-level — Engineering OS עצמו דרש תיקון
**סטטוס:** תועד + תוכנית תיקון מלאה בוצעה

---

## מה קרה

הניסוי ביקש לבנות פרויקט SaaS (Expiriens) תוך שימוש ב-Engineering OS.
המטרה: לבדוק שכל ה-loops (spec, debug, learning, agent) עובדים.

**מה שקרה בפועל:**
- spec_loop: לא פעל — אפיון ב-Notion לא הומר לתוצאה מאומתת
- debug_loop: לא פעל — LLM תיקן תסמינים ללא root cause
- learning_loop: לא פעל — אפס lessons-learned נכתבו
- agent_loop: לא פעל — agents ללא tasks.json, ללא state tracking
- tests: **אפס טסטים** לאורך כל הניסוי
- branches: 14+ branches פתוחים (חלקם בוטלו, main מעודכן)

---

## ניתוח שורש

**כשל שורשי יחיד: text-based enforcement ≠ enforcement.**

כל כלל שהיה מוגדר ב-CLAUDE.md היה ידוע ל-LLM.
אף כלל לא היה מגובה בחסימה פיזית (exit 1).
תחת לחץ זמן ו-context ארוך — כל הכללים נדלגו.

הפרש בין "מוגדר" ל"קורה בפועל" = ~100%.

---

## תיקונים שיושמו

| בעיה | תיקון פיזי |
|------|------|
| קוד ללא plan | validate-workflow-state.sh → exit 1 |
| agents ללא tasks.json | Agent PreToolUse hook → exit 1 |
| commits ללא format | commit-msg.sh → exit 1 |
| commits ללא tests | pre-commit.sh physical scan → exit 1 |
| branches מרובים | branch count check → exit 1 |
| L2 skills דילוג | session banner + stop hook awareness |
| Nemotron לא נבדק | smoke test בkStartup |
| worktree isolation כשל | תועד + remote limitations documented |

---

## לקחים לניסוי הבא

1. **כל חוק חדש → שאל: "מה ה-exit 1?"** אם אין תשובה, זה reminder, לא חוק.
2. **מדוד מה קורה בפועל**, לא מה שהוגדר. ניסוי ≠ יישום הצלחה.
3. **tasks.json = state machine** — parallel agents ללא state הם chaotic.
4. **Context7 לפני כל dependency** — LLM training data מיושן ביחס לגרסאות.
5. **Learning loop = חובה ב-fix: commits** — post-commit hook מזכיר.

---

## מדדי הצלחה לניסוי הבא

- [ ] לפחות 1 טסט לכל קובץ קוד חדש
- [ ] כל fix: commit ← lessons-learned entry
- [ ] 0 branches פתוחים שלא הוזכרו ב-tasks.json
- [ ] spec_loop: כל DoD item מסומן ✅ לפני merge
- [ ] commit-msg hooks לא הופרו
