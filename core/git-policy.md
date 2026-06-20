# git-policy.md — מדיניות Git וקומיטים

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - בכל אינטראקציה עם הריפו — ניהול branches.
> - בשלב 9 ב-workflow — לכתיבת קומיט לפי הפורמט (`<commit_protocol>`).
> - לפני מיזוג ל-main, force-push, או מחיקת branch — דורש אישור משתמש.
> - לפני כל פעולה הרסנית/בלתי-הפיכה (`<safety>`).

---

## GitHub — מדיניות ריפו

**סטטוס: ✅ מחובר**

- **תפקיד:** ניהול הריפו — קוד, branches, PRs, קומיטים, היסטוריה.
- **מתי:** בכל אינטראקציה עם הריפו.

### כלל branch

`main` יציב בלבד. **branch פעיל אחד בלבד** מלבד main בכל זמן נתון. כל פיצ'ר =
branch חדש.

הסיבה: ריבוי branches פעילים מקשה על מעקב מצב ומגדיל סיכוני קונפליקט.

### מיזוג ל-main

מיזוג מתבצע **רק** אחרי:

1. שכל ה-`<definition_of_done>` (ראה [`quality-gates.md`](./quality-gates.md)) מתקיים.
2. **אישור מפורש של המשתמש** — אל תמזג ל-main על דעת עצמך, אף אם כל הבדיקות עברו.

---

## <cadence>

**כל כמה זמן מבצעים כל פעולת git** — תזמון, לא רק "איך". המטרה: היסטוריה קריאה
שאפשר לחזור אליה, וברנץ' אחד נקי בכל זמן.

### קומיט — תכוף וקטן

- **מתי:** אחרי כל יחידת עבודה אטומית שעובדת **ואומתה** — לא בסוף יום ולא אחרי עשרות
  שינויים מצטברים. כלל אצבע: אם אפשר לתאר את ה-diff במשפט אחד והבדיקות עליו ירוקות —
  זה הזמן לקומיט. **קצב מומלץ: קומיט אחד כל שעה-שעתיים בעבודה פעילה.** יותר מ-3 שעות
  ללא קומיט = סימן שהשינוי גדול מדי — פצל.
- **גודל:** שינוי לוגי אחד לכל קומיט, עם הוכחת אימות (ראה `<commit_protocol>`).
- **שער אבטחה לפני קומיט בברנץ':** כשסקיל ה-security מותקן, הרץ `/security-review` על
  השינויים הממתינים לפני הקומיט — כך פגיעות חדשה נחסמת לפני שהיא נכנסת להיסטוריה
  (ראה [`../external-skills/security-review/`](../external-skills/security-review/)).

### ברנץ' חדש — אחד פעיל בכל זמן

- **מתי:** כל משימה/פיצ'ר חדש = ברנץ' חדש מ-main מעודכן, **אחרי שהברנץ' הקודם מוזג**.
  **ברנץ' פעיל אחד בלבד** מלבד main (ראה *כלל branch* למעלה). **אורך חיים מומלץ: 1–5 ימים.**
  ברנץ' שחי יותר מ-5 ימים ללא merge = סימן שהמשימה גדולה מדי — פצל לתת-משימות.
- **לא** ממשיכים עבודה חדשה על ברנץ' שכבר מוזג — פותחים חדש.

### מיזוג ל-main — בסיום ובאישור

- **מתי:** רק כשכל ה-`<definition_of_done>` נסגר, **שער האבטחה עבר**, **ובאישור מפורש
  של המשתמש**. אין מיזוג אוטומטי, אף אם הכל ירוק (ראה `<safety>`).
- **קצב:** מזג כשהמשימה הושלמה ואומתה — אל תצבור ברנצ'ים פתוחים ואל תמזג עבודה חלקית.

### חוק ברנץ' יחיד — נאכף ב-PreToolUse hook (exit 1)

מחוץ ל-main מותר ברנץ' אחד פעיל בלבד. ניסיון ליצור branch שני נחסם אוטומטית:

```
PreToolUse Bash: git checkout -b / git switch -c / git branch →
  counts remote branches (excl. main/master) → if >1: exit 1
```

לפני פרויקט חדש: merge לmain (אישור מפורש) → delete branch → branch חדש.
`commit-msg` hook מאמת פורמט + 🧪 section בכל commit. מותקן ע"י `use-in-project.sh`.

</cadence>

---

## <new_project_checklist>

רשימת בדיקה לפני תחילת פרויקט חדש. **כל סעיף מחויב — אל תתחיל לכתוב קוד לפני שכולם נסגרים.**

- [ ] אין branches פתוחים מלבד main (`git branch -r | grep -v main`)
- [ ] CLAUDE.md › `<project_context>` מולא (owner, goal, stack, stage)
- [ ] `use-in-project.sh` הורץ על הפרויקט (מתקין hooks, graphify, settings.json, SETUP.md)
- [ ] `ENGINEERING_OS_SETUP.md` — כל manual steps בוצעו (Sentry, Notion, secrets)
- [ ] `.claude/plans/<name>.md` נכתב עם DoD מדיד (Write hook אוכף זאת)

</new_project_checklist>

---

## <pull_requests>

**PRs נפתחים תמיד כ-ready for review — לא כ-draft.**

הסיבה: CodeRabbit (וכלי review אוטומטיים אחרים) מדלגים על draft PRs ולא מבצעים review עליהם.

כלל זה גובר על הגדרת ברירת-מחדל של סביבת הריצה (כולל הוראת "Create the pull request as a draft" מה-system prompt של Claude Code on the web).

```bash
# כך יוצרים PR — ללא --draft
gh pr create --title "..." --body "..."

# אסור:
gh pr create --draft ...
```

אם ה-CI דורש בדיקה לפני review — השתמש ב-label כמו `wip` במקום draft.

> **אכיפה דטרמיניסטית** (`scripts/enforcement/enforce-git.sh`, PreToolUse Bash):
> פקודת `gh pr create --draft` נחסמת. bypass: `EOS_BYPASS_DRAFTPR=1`.

</pull_requests>

---

## <safety>

בקש אישור לפני פעולות שקשה להפוך או שמשפיעות על מערכות משותפות:

- מיזוג ל-main (תמיד דורש אישור מפורש)
- מחיקת קבצים/branches, `DROP TABLE`, `rm -rf`
- `git push --force`, `git reset --hard`, תיקון קומיטים שפורסמו
- פריסה לפרודקשן, שליחת הודעות, שינוי תשתית משותפת

פעולות מקומיות והפיכות (עריכת קבצים, הרצת טסטים) — בצע ישירות בלי לשאול.

### אכיפה מול שיפוט

חלק מהגייטים האלה ניתנים לאכיפה דטרמיניסטית ב-hook ולא צריכים להישען על משמעת:
חסימת כתיבה לנתיבים מוגנים, חסימת `--force` / `--no-verify`, וסריקת secrets (ראה
[`hooks-policy.md`](./hooks-policy.md) › `<hooks>`). אבל **מיזוג ל-main, deploy
ופעולות הרסניות-משותפות נשארים אישור-אדם מפורש** — hook יכול לחסום ברירת-מחדל, אך
ההחלטה היא של המשתמש, לא של בדיקה אוטומטית. hooks מתאימים לבדיקות עם פלט pass/fail,
לא להחלטות שיפוט.

> **אכיפה דטרמיניסטית** (`scripts/enforcement/enforce-git.sh`, PreToolUse Bash):
> `git push --force`/`-f` ה-plain נחסם (`--force-with-lease` הבטוח מותר). bypass: `EOS_BYPASS_FORCEPUSH=1`.
> `--no-verify` נחסם ע"י enforce-debugging.sh; one-branch ע"י settings.json. מיזוג ל-main/deploy
> נשארים אישור-אדם מפורש — לא נאכפים אוטומטית.

</safety>

---

## <commit_protocol>

פורמט: conventional commits (`feat:`, `fix:`, `chore:`, `refactor:` …). קומיטים
קטנים ואטומיים.

כל קומיט מתעד **באופן מדויק**, על בסיס הבדיקות שבוצעו ב-
[`quality-gates.md`](./quality-gates.md) › `<pre_commit_review>`, כדי שנדע בדיוק
לאן לחזור אם הקוד נשבר. השתמש בפורמט הקבוע הבא:

<commit_format>
```
<type>: <כותרת קצרה>

✅ עובד:
- <מה עובד> — <הוכחה: הכלי + התוצאה, למשל "Playwright login.spec 3/3 ✓">

❌ לא עובד / הוגבל:
- <מה לא עובד> — <סיבה או "לא מומש">

🔄 השתנה:
- <קבצים/מודולים שנגעת בהם>

📌 נשאר לעשות:
- <משימות פתוחות שנוצרו בנקודה זו>

🧪 בדיקות:
- <רשימת הבדיקות שהורצו והתוצאה, לפי הקונקטורים>
```
</commit_format>

כלל: כל שורה תחת "עובד" / "לא עובד" חייבת להיתמך בהוכחה מבדיקה (tests / logs /
UI / API דרך הקונקטור המתאים). קומיט בלי הוכחות — אינו תקף.

<example>
```
feat: add email/password login flow

✅ עובד:
- התחברות עם credentials תקינים → redirect ל-dashboard — Playwright login.spec 3/3 ✓
- session נשמר ב-DB — אומת ב-query מול Supabase

❌ לא עובד / הוגבל:
- reset password — לא מומש עדיין

🔄 השתנה:
- auth/login.ts, auth/session.ts, login.test.ts

📌 נשאר לעשות:
- לממש reset password
- להוסיף rate-limiting להתחברות

🧪 בדיקות:
- Playwright login.spec: 3/3 ✓
- Supabase query: session row נוצר ✓
```
</example>

</commit_protocol>
