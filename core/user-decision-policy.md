# user-decision-policy.md — החלטות משתמש, persistence ו-handoff

> חלק מ-Engineering OS. קרא קובץ זה לפני `AskUserQuestion`, לפני עצירה בגלל החלטת
> משתמש, וכאשר משימה דורשת repository/workspace/session שאינו נגיש כרגע.

## <user_decision_lifecycle>

המערכת חייבת להבדיל בין החלטה שטרם נענתה לבין החלטה שכבר התקבלה. העלאת שאלה למשתמש
אינה לולאה פתוחה; לאחר תשובה יש מעבר state מפורש.

### זהות וסטטוסים

לכל החלטה תן `decision_id` יציב וקצר לפי המשמעות, לא לפי נוסח השאלה. לדוגמה:

```text
project8-telemetry-execution-context
```

הסטטוסים המותרים:

- `unanswered` — נדרש קלט משתמש ועדיין אין תשובה שמאפשרת להמשיך.
- `answered` — המשתמש בחר אפשרות שניתנת לביצוע בהקשר הנוכחי.
- `deferred` — המשתמש החליט לבצע את הפעולה מאוחר יותר או בסשן נפרד.
- `blocked` — ההחלטה ידועה, אך תנאי חיצוני מונע כרגע את הפעולה.
- `superseded` — עובדה חדשה ומהותית ביטלה החלטה קודמת; מצביעים להחלטה החדשה.

`answered`, `deferred` ו-`blocked` הם מצבים סגורים לשאלה. הם אינם `unanswered` רק
מפני שהפעולה עצמה עוד לא בוצעה.

### Ask once

לפני `AskUserQuestion`:

1. חפש בהקשר השיחה, ב-Route Plan הפעיל וב-`.claude/tasks.json` החלטה עם אותה משמעות.
2. אם קיימת תשובה ברורה בסטטוס `answered`, `deferred` או `blocked` — **אל תשאל שוב**.
3. שאל מחדש רק כאשר אחד מהבאים מתקיים:
   - התשובה הקודמת עמומה ואינה בוחרת אפשרות;
   - המשתמש נתן הוראות סותרות ולא ברור איזו עדכנית;
   - עובדה חדשה ומהותית משנה את האפשרויות או הופכת את ההחלטה לבלתי-תקפה.
4. שינוי ניסוח, turn חדש, checklist פתוח, או פעולה שעדיין לא בוצעה אינם סיבה לשאול שוב.

כאשר שואלים מחדש בגלל שינוי מהותי, ציין במשפט אחד מה השתנה וסמן את ההחלטה הקודמת
`superseded` במקום להתייחס אליה כאילו לא נענתה.

### Persistence

לאחר תשובת משתמש:

- המשך מיד לפי התשובה; אל תבקש מהמשתמש לאשר שוב את אותה בחירה.
- כאשר כתיבה מותרת, רשום ב-Route Plan הפעיל תחת `## User Decision Log` או ב-
  `.claude/tasks.json` לפחות:

```text
decision_id: <stable-id>
status: answered|deferred|blocked|superseded
decision: <the selected outcome>
reason: <why this status applies>
next_action: <one concrete handoff or in-scope action>
```

- ב-Plan Mode או בסביבה read-only, תשובת השיחה עצמה היא ה-source of truth לסשן.
  חוסר יכולת לכתוב קובץ **אינו** היתר לשאול שוב. רשום את ההחלטה בקובץ ברגע שכתיבה
  מתאפשרת, בלי לעכב מחקר או עבודה שאינה תלויה בה.
- אחרי compaction/handoff, שחזר את ה-Decision Log לפני העלאת שאלה חדשה.

### Cross-repo / unavailable workspace

כאשר פעולה דורשת repository, directory, connector או session שאינם נגישים כרגע:

1. אל תציג בחירה שכבר נענתה כאילו היא עדיין פתוחה.
2. סמן את הפעולה `deferred` אם המשתמש בחר סשן/שלב עתידי, או `blocked` אם חסר תנאי
   חיצוני שלא הוכרע.
3. תעד `next_action` אחד קונקרטי: לדוגמה "open a fresh session in project-8 and run
   the telemetry preflight".
4. המשך את כל העבודה האפשרית ב-repository ובסשן הנוכחיים.
5. אל תנסה לצרף repository או לשנות workspace בשם המשתמש אם הממשק דורש פעולה ידנית.
6. אל תשאל שוב על אותה בחירה בסיום כל שלב. חזור אליה רק כאשר ה-handoff מתחיל או
   כאשר עובדה מהותית השתנתה.

### Checklist semantics

פריט checklist פתוח מתאר עבודה שלא הושלמה; הוא אינו מוכיח שחסרה החלטת משתמש.
כאשר ההחלטה סגורה אך העבודה עתידית, השאר את הפריט פתוח והוסף לידו סטטוס
`deferred`/`blocked`, decision ID ו-next action. אין להפוך פריט פתוח ללולאת שאלות.

## <required_behavioral_evidence>

במשימות שבהן נדרשת החלטת משתמש, ה-run trace או artifact ההערכה צריך לאפשר לבדוק:

- decision ID יציב;
- מספר הפעמים שהשאלה הועלתה;
- הסטטוס לאחר התשובה;
- ה-handoff או הפעולה הבאה;
- האם עובדה חדשה הצדיקה שאלה חוזרת.

הוכחת "שאל פעם אחת" היא התנהגותית. אין להחליף אותה בטענה עצמית של המודל, ואין
להוסיף hook שמנסה להבין סמנטיקה של תשובות טבעיות ללא source of truth אמין.

</user_decision_lifecycle>
