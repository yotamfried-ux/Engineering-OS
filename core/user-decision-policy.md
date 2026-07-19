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

1. חפש בהקשר השיחה, ב-Route Plan הפעיל, ב-`.claude/tasks.json`, ובכל durable handoff
   שמיועד ל-repository הנוכחי החלטה עם אותה משמעות.
2. אם קיימת תשובה ברורה בסטטוס `answered`, `deferred` או `blocked` — **אל תשאל שוב**.
3. שאל מחדש רק כאשר אחד מהבאים מתקיים:
   - התשובה הקודמת עמומה ואינה בוחרת אפשרות;
   - המשתמש נתן הוראות סותרות ולא ברור איזו עדכנית;
   - עובדה חדשה ומהותית משנה את האפשרויות או הופכת את ההחלטה לבלתי-תקפה.
4. שינוי ניסוח, turn חדש, checklist פתוח, או פעולה שעדיין לא בוצעה אינם סיבה לשאול שוב.

כאשר שואלים מחדש בגלל שינוי מהותי, ציין במשפט אחד מה השתנה וסמן את ההחלטה הקודמת
`superseded` במקום להתייחס אליה כאילו לא נענתה.

### Session-local persistence

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
- אחרי compaction באותו repository, שחזר את ה-Decision Log לפני העלאת שאלה חדשה.

Route Plan ו-`.claude/tasks.json` הם session/repository-local state בלבד. הם אינם
handoff durable לסשן שנפתח ב-repository אחר, ואסור להציג אותם ככאלה.

### Durable cross-repository handoff

כאשר ההמשך יעבור ל-repository או workspace אחר, החלטה בסטטוס `deferred` נחשבת
מוכנה ל-handoff רק לאחר שנוצר מקור durable שהסשן היעד יכול לגלות ולקרוא.

מקורות מאושרים, לפי סדר עדיפות:

1. issue או PR ב-repository היעד;
2. קובץ committed ב-repository היעד;
3. רשומה ב-tracker משותף שהגישה אליו מאומתת בשני הסשנים.

מקור שנמצא רק ב-Route Plan זמני, `.claude/tasks.json`, working tree מקומי, או טקסט
שלא נשלח ליעד — אינו durable handoff.

ל-handoff חובה לרשום:

```text
decision_id: <stable-id>
status: deferred|blocked
decision: <selected outcome>
source_repo: <owner/repo>
destination_repo: <owner/repo>
next_action: <one concrete first action in the destination session>
source_ref: <PR/commit/run that provides context>
handoff_ref: <destination-readable issue/PR/file/tracker URL>
```

ב-GitHub, ברירת המחדל היא issue ב-repository היעד עם הכותרת:

```text
[Engineering OS handoff] <decision-id>
```

ה-body כולל רק metadata בטוח מהסכמה למעלה, ללא raw conversation, secrets או payloads.
לאחר היצירה, שמור את URL ה-issue כ-`handoff_ref`. בתחילת סשן ב-repository יעד, ולפני
שאלה על עבודה deferred, חפש issues/PRs פתוחים עם prefix זה או עם ה-`decision_id`.

אם אין אפשרות ליצור אף מקור durable, ההחלטה עצמה נשארת סגורה אך ה-handoff מסומן
`blocked`; הצג למשתמש handoff block מוכן להעברה ופעולה אחת ליצירתו. אל תשאל שוב על
הבחירה שכבר התקבלה. אל תסמן cross-repo handoff כ-`deferred` מוכן ללא `handoff_ref`.

### Cross-repo / unavailable workspace

כאשר פעולה דורשת repository, directory, connector או session שאינם נגישים כרגע:

1. אל תציג בחירה שכבר נענתה כאילו היא עדיין פתוחה.
2. סמן את הפעולה `deferred` רק עם `handoff_ref` destination-readable; אחרת סמן את
   persistence של ה-handoff כ-`blocked`, בלי לפתוח מחדש את החלטת המשתמש.
3. תעד `next_action` אחד קונקרטי: לדוגמה "open a fresh session in project-8 and run
   the telemetry preflight".
4. המשך את כל העבודה האפשרית ב-repository ובסשן הנוכחיים.
5. אל תנסה לצרף repository או לשנות workspace בשם המשתמש אם הממשק דורש פעולה ידנית.
6. אל תשאל שוב על אותה בחירה בסיום כל שלב. חזור אליה רק כאשר ה-handoff מתחיל או
   כאשר עובדה מהותית השתנתה.

### Checklist semantics

פריט checklist פתוח מתאר עבודה שלא הושלמה; הוא אינו מוכיח שחסרה החלטת משתמש.
כאשר ההחלטה סגורה אך העבודה עתידית, השאר את הפריט פתוח והוסף לידו סטטוס,
`decision_id`, `next_action` ו-`handoff_ref` אם ההמשך חוצה repository. אין להפוך פריט
פתוח ללולאת שאלות.

## <required_behavioral_evidence>

במשימות שבהן נדרשת החלטת משתמש, ה-run trace או artifact ההערכה צריך לאפשר לבדוק:

- decision ID יציב;
- מספר הפעמים שהשאלה הועלתה;
- הסטטוס לאחר התשובה;
- ה-handoff או הפעולה הבאה;
- `handoff_ref` destination-readable כאשר ההמשך חוצה repository;
- האם עובדה חדשה הצדיקה שאלה חוזרת.

הוכחת "שאל פעם אחת" נאספת מה-tool/conversation trace בפועל על ידי host, harness או
operator — לא מקובץ שהמודל המוערך התבקש לכתוב. אין להחליף אותה בטענה עצמית של המודל,
ואין להוסיף hook שמנסה להבין סמנטיקה של תשובות טבעיות ללא source of truth אמין.

</user_decision_lifecycle>
