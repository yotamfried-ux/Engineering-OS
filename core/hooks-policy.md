# hooks-policy.md — אכיפה דטרמיניסטית (hooks)

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - בהקמת פרויקט — להגדרת שכבת ה-hooks הבסיסית (`<hooks>`).
> - כשכלל חייב לקרות **בכל פעם ללא יוצא מן הכלל** — ולא להישען על כך שקלוד יזכור.
> - כשרוצים לחסום פעולה מסוכנת ברמת הכלי (commit, push, כתיבה לנתיב מוגן).
> - כשרוצים להזריק עיקרון ברמת ה-system prompt (`<system_prompt_injection>`).

---

## <hooks>

הקבצים ב-`core/` הם **הקשר מנחה**, לא קונפיגורציה נאכפת. קלוד קורא אותם ומנסה לציית,
אבל אין ערובה לציות מלא — במיוחד תחת לחץ הקשר (context מתמלא) או כשהוראות מתנגשות.
לכלל שחייב להתקיים תמיד, טקסט אינו מספיק: צריך **hook**.

hook הוא סקריפט שרץ אוטומטית באירוע מחזור-חיים קבוע (לפני קריאת כלי, לפני קומיט,
בסיום turn) ופועל **ללא תלות במה שקלוד מחליט**. זו שכבת האכיפה; הטקסט ב-core מעצב
התנהגות אך אינו חוסם.

### אילו כללים חייבים להיות hook (ולא רק טקסט)

אלה הכללים הבלתי-עבירים שלנו. כל אחד מהם כתוב כטקסט בקובץ ה-core המתאים — וכאן הוא
מקבל גיבוי אכיפתי:

- **אימות לפני קומיט** — הרצת lint + format + טסטים על ה-diff, וחסימת הקומיט אם משהו
  נכשל. מגבה את [`quality-gates.md`](./quality-gates.md) › `<pre_commit_review>`.
- **איסור עקיפת בדיקות** — חסימת `git commit --no-verify` ושאר עקיפות. מגבה את
  [`debugging-policy.md`](./debugging-policy.md) › `<debug_loop>`.
- **חסימת כתיבה לנתיבים מוגנים** — מיגרציות, קבצי תשתית, `.env` — דורש אישור מפורש.
  מגבה את [`git-policy.md`](./git-policy.md) › `<safety>`.
- **סריקת secrets** — חסימת קומיט שמכיל מפתחות/טוקנים. מגבה את
  [`connector-policy.md`](./connector-policy.md) › `<environment>`.
- **סגירת Definition of Done** — בסיום turn, ודא שתנאי הסיום נסגרו לפני סימון משימה
  כגמורה. מגבה את [`quality-gates.md`](./quality-gates.md) › `<definition_of_done>`.
- **ביקורת עצמית בסוף turn** — Stop hook מציג רשימת-כיול (L2 triggers + נהלים מרכזיים)
  שClaude משווה אליה ומדווח בכנות בסעיף `🔍 ביקורת עצמית (כיול)`: L2 שדולגו, נהלים שלא
  מומשו, פעולות שהופרו. מגבה את [`CLAUDE.md`](../CLAUDE.md) › `<communication>`.
- **bootstrap של סקילים** — SessionStart hook (או שלב הקמה) שמריץ
  [`../scripts/skill-bootstrap.sh`](../scripts/skill-bootstrap.sh) ומדווח על סקילים
  חסרים. מגבה את [`skill-orchestration-policy.md`](./skill-orchestration-policy.md) › `<bootstrap>`.

### מה נשאר אישור-אדם (לא hook)

לא כל גייט הוא hook. **מיזוג ל-main** ופעולות הרסניות-משותפות (deploy, `DROP TABLE`)
נשארים אישור-אדם מפורש — hook יכול להזכיר או לחסום ברירת-מחדל, אבל ההחלטה היא של
המשתמש (ראה [`git-policy.md`](./git-policy.md) › `<safety>`). hooks מתאימים לבדיקות
אוטומטיות עם פלט pass/fail, לא להחלטות שיפוט.

### סוגי hooks עיקריים

- **PreToolUse** — לפני קריאת כלי; חוסם פעולה לפני שקרתה (כתיבה לנתיב מוגן, פקודה מסוכנת).
- **pre-commit** — לפני קומיט; מריץ את בדיקות האיכות וחוסם קומיט לא תקין.
- **Stop** — בסיום turn; מאמת תנאי סיום וחוסם סגירה עד שהם מתקיימים.

### כלל הקמה

הוסף את שכבת ה-hooks הבסיסית בהקמת **כל** פרויקט (ראה
[`workflow.md`](./workflow.md) › `<project_scaffold>`). אפשר לבקש מקלוד לכתוב את
ה-hook ("כתוב hook שמריץ lint אחרי כל עריכה" / "כתוב hook שחוסם כתיבה לתיקיית
migrations"). אל תסתפק בטקסט עבור כלל שאסור שייכשל אפילו פעם אחת.

</hooks>

---

## <system_prompt_injection>

טקסט ב-CLAUDE.md מועבר כהודעת user אחרי ה-system prompt — לא כחלק ממנו. לעיקרון שאתה
רוצה ברמת ה-system prompt עצמו (למשל עקרון-העל "לאמת, לא לנחש"), השתמש ב-
`--append-system-prompt` בהרצה. זה חזק יותר מטקסט ב-CLAUDE.md, אך יש להעבירו בכל
הרצה — ולכן מתאים לסקריפטים ולאוטומציה (non-interactive) יותר מלשימוש אינטראקטיבי.

</system_prompt_injection>

---

## <hook_examples>

דוגמאות מלאות לכל סוג hook — העתק והתאם לפרויקט.

### PreToolUse (Write/Edit) — חסימת כתיבה ללא plan
קובץ: `.claude/settings.json` (ראה דוגמה מלאה ב-[`../.claude/settings.json`](../.claude/settings.json))
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash \"${ENGINEERING_OS_HOME:-$(pwd)}/scripts/hooks/validate-workflow-state.sh\" 2>&1"
      }]
    }]
  }
}
```
**שים לב:** אסור `|| true` בסוף — הוא מבטל את ה-exit code וה-enforcement לא עובד.

### pre-commit — lint + tests + חסימת no-verify
קובץ: `.git/hooks/pre-commit` (העתק מ-[`../scripts/hooks/pre-commit.sh`](../scripts/hooks/pre-commit.sh))
```bash
#!/bin/bash
set -e
STAGED=$(git diff --cached --name-only)
[ -z "$STAGED" ] && exit 0
# הרץ linter ו-tests לפי stack הפרויקט:
# JS/TS: npm run lint --if-present && npm test --if-present
# Python: ruff check . && pytest --tb=short -q
```
התקנה: `cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
לפרויקטי Engineering OS עצמו: `bash scripts/install-self-hooks.sh`

### commit-msg — אכיפת פורמט commit
קובץ: `.git/hooks/commit-msg` (העתק מ-[`../scripts/hooks/commit-msg.sh`](../scripts/hooks/commit-msg.sh))

### SessionStart — bootstrap + אימות סביבה
```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "bash \"${ENGINEERING_OS_HOME:-$(pwd)}/scripts/session-setup.sh\" 2>&1 | head -50 || true"
      }]
    }]
  }
}
```

</hook_examples>
