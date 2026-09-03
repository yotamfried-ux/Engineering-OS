# Bug: ערך "none" תקין תחת checker אחד נפסל כ-placeholder תחת checker אחר על אותו שדה

**תאריך:** 2026-09
**חומרה:** Low — לא גרם לנתונים שגויים, גרם לסבבי CI מיותרים על PR תקין

## מה קרה

ב-PR #287 (auto-archive telemetry runs locally), שדה `External systems/connectors`
ב-Route Plan הוגדר כ-`none`. `check-connector-evidence.sh` קיבל את הערך (הוא
ברשימת ה-`noneish()` המדויקת שלו). באותו ראש (head), אותו ערך `none` נפסל
על ידי `validate-capability-evidence.sh` כ-placeholder (הוא ברשימת ה-`PLACEHOLDER`
regex שלו). שני checkers נפרדים על אותו שדה, עם שתי רשימות "מה נחשב none-ish"
שאינן זהות — ערך אחד לא יכול לספק את שניהם בו-זמנית בלי ניסוי-וטעייה.

אותה תבנית חזרה על שדה `Skills` — גם שם `none` עבר את `check-workflow-evidence.sh`
(שדורש `## Skill Evidence` רק אם הערך *אינו* none-ish) אך נפסל שוב על ידי
`validate-capability-evidence.sh`.

תופעה נוספת מאותו family: ב-`check-pr-review-evidence.sh`, השדה `## Merge
Readiness` → `ci:` עובר cross-check חי מול check-runs אמיתיים — לכל gate token
שמופיע *כמחרוזת* בשורת ה-`ci:`, הבודק דורש שכל ה-check-runs התואמים יהיו
SUCCESS, ללא קשר להקשר המשפט. כתיבת "enforcement-tests עדיין רץ, לא נטען כאן"
בתוך שורת ה-`ci:` נכשלה באותה צורה בדיוק כמו טענת "ירוק" — כי הבודק לא קורא
משמעות, רק מחפש substring.

## שורש הבעיה

1. **regex `none-ish`/`placeholder` לא מאוחד**: לפחות שלושה checkers שונים
   (`check-connector-evidence.sh::noneish()`, `validate-capability-evidence.sh::PLACEHOLDER`,
   `check-workflow-evidence.sh` – הבדיקה הגנרית על שדות Route Plan) מגדירים כל
   אחד רשימת מילים "ריקות/placeholder" משלו, עם חפיפה חלקית בלבד. אין מקור אמת
   יחיד לכך ש-Route Plan field יכול להכריז "לא רלוונטי" בצורה שכל הבודקים
   מקבלים.
2. **cross-check מבוסס substring, לא field-scoped סמנטית**: הבדיקה החיה מול
   check-runs אמיתיים ב-`check-pr-review-evidence.sh` מניחה שכל הופעה של gate
   token בתוך שורת `ci:`/`checks:` היא טענת "ירוק", גם כשההקשר המילולי אומר
   ההפך.

## ראיה

שחזור ישיר, לא הנחה: אותו commit head (`846cb334a6...`) קיבל בו-זמנית
`Require connector route plan evidence: success` (אחרי שהשדה הפך ל-`none`)
ו-`Require capability evidence in changed plans: failure` עם ההודעה
`has placeholder Route Plan field value(s): External systems/connectors`. הערך
`not required` סיפק את שני ה-checkers יחד (נבדק ישירות מול שני הסקריפטים
לוקאלית לפני push חוזר). באותו אופן, השורה `enforcement-tests was still
running... deliberately not claimed here yet` בתוך שדה `ci:` הפילה את
`check-pr-review-evidence.sh` עם `claims "enforcement-tests" is green, but
its real check run... reports IN_PROGRESS` — למרות שהמשפט לא טען שום דבר
ירוק.

## רמת ביטחון

גבוהה. שוחזר ישירות דרך הרצת שלושת הסקריפטים (`check-connector-evidence.sh`,
`validate-capability-evidence.sh`, `check-workflow-evidence.sh`) עם אותם
base/head SHA לוקאלית, ולא רק מקריאת קוד.

## איך מונעים בעתיד

1. לאחד את רשימות ה-`none-ish`/placeholder לקובץ/מודול משותף אחד
   (`scripts/enforcement/lib/`), וכל checker שמריץ בדיקת "האם ערך ריק/placeholder"
   על שדה Route Plan יקרא ממנו, לא יגדיר רשימה עצמאית.
2. ב-`check-pr-review-evidence.sh`, להגביל את ה-substring match ל-tokens
   שמופיעים ליד מילת הקשר positivית (למשל "green"/"passed"/"✅") או, פשוט
   יותר, לדרוש טופס מבני `ci: <token>=<pass|pending|not-claimed>` במקום פרוזה
   חופשית שנסרקת כטקסט גולמי.
3. עד אז: כשכותבים ערך "ריק" בשדה Route Plan, להשתמש ב-`not required` (לא
   `none`) — הוא עבר את כל שלושת ה-checkers בפועל ב-PR #287. וכש-gate עדיין
   `in_progress`, לא להזכיר את שמו כלל בשורת `ci:`/`checks:` — לתאר אותו
   כפרוזה חופשית מחוץ לאותה שורה.

## טסט רגרסיה

לא נוסף טסט ממוקד ל-Engineering OS עצמו כחלק מ-PR #287 (המיקוד של ה-PR הוא
telemetry archiving, לא governance tooling) — זה gap פתוח. הצעה קונקרטית:
`scripts/enforcement/tests/test-none-value-consistency.sh` שמריץ ערך יחיד
("not required") דרך שלושת הבודקים ומוודא שכולם מקבלים אותו, ומריץ ערך
"none" ומוודא שלפחות אחד דוחה אותו (כדי לתעד את חוסר-העקביות הקיים במפורש,
לא רק לתקן אותו בשקט).

## סטטוס הבשלה

לא תוקן ב-Engineering OS עצמה. תועד כאן ובשדה `next_system_improvement` של
PR #287 כהצעה ל-follow-up נפרד וממוקד (איחוד ה-regex-ים); לא בוצע כחלק מה-PR
הנוכחי כדי לא להרחיב את ההיקף שלו.

## Prevented Future Issues: 0
