# חוזה אימות שדורש זהות שהספק מקצה בתוך payload בלתי-ניתן-לעריכה הוא בלתי-ניתן לקיום

## מה קרה

מנגנון ה-bypass approval עבר 110/110 טסטים מקומיים ו-CI ירוק על exact head, אבל
לא היה ניתן להשתמש בו כלל מול GitHub אמיתי. `validate-bypass-approval.py` דרש
שגוף הערת האישור יכיל את `approval_comment_id` ואת `approval_created_at` של עצמה,
בעוד אותו validator דוחה כל הערה שנערכה. GitHub מקצה את שני הערכים האלה רק
**אחרי** הפרסום, ולכן שום בעל הרשאה לא יכול היה לחבר גוף אישור תקף: כל אישור אמיתי
היה נכשל closed. הבאג התגלה רק בסקירת Codex חיצונית, לא על ידי אף שער אכיפה.

## שורש הבעיה

החוזה ערבב שתי שכבות שחייבות להישאר נפרדות: **מה שהאדם מצהיר** (binding לגייט,
למאגר, ליעד, לתפוגה) לעומת **מה שהספק קובע** (מזהה ההערה וזמן היצירה). ברגע
שהצהרת האדם חייבת להכיל ערך שהספק יקצה רק בעתיד, ובמקביל אסור לערוך את ההצהרה,
החוזה סותר את עצמו. זו סתירה לוגית בהגדרת החוזה — לא באג מימוש.

## השערות שנבדקו

- "אפשר לפרסם ואז לערוך כדי למלא את הערכים" — נשללה: שורה 170 ב-validator דוחה
  `updated_at != created_at`, כלומר עריכה אוסרת במפורש.
- "אפשר לחשב את מזהה ההערה מראש" — נשללה: המזהה מוקצה על ידי GitHub בעת POST ואינו
  ניתן לחיזוי.
- "החוזה מפריד בין גוף authored לבין envelope" — אומתה כשורש: הפרדה כזו **לא**
  הייתה קיימת; `APPROVAL_FIELDS` יחיד שימש גם לגוף שהאדם כותב וגם לאובייקט המאומת.

## ראיה

`scripts/enforcement/validate-bypass-approval.py` לפני התיקון:

```
if comment.get("updated_at") != created_at:
    raise ContractError("edited approval comments are forbidden")
...
if approval["approval_comment_id"] != approval_comment_id:
    raise ContractError("approval payload comment ID mismatch")
if approval["approval_created_at"] != created_at:
    raise ContractError("approval time must equal provider created_at")
```

הרצת חבילת ה-provider אחרי הפרדת השכבות הוכיחה את הסתירה ישירות — ה-fixture הקיים
נכשל מיד עם:

```
{"authorized": false, "error": "authored approval fields mismatch:
 missing=[], extra=['approval_comment_id', 'approval_created_at']"}
```

כלומר ה-fixture תיאר גוף אישור שאדם לא יכול היה לפרסם.

## רמת ביטחון

High

## איך מזהים מוקדם

עבור כל שדה בחוזה אימות, שאל: **מי מייצר את הערך ומתי, יחסית לרגע שבו הוא נחתם?**
אם המייצר הוא הספק והחתימה קודמת להקצאה — החוזה בלתי-ניתן לקיום. סימן אזהרה
ספציפי: אותה רשימת שדות משמשת גם ל-payload שאדם כותב ידנית וגם לאובייקט שהמערכת
מאמתת. שתי המטרות האלה כמעט תמיד דורשות שתי רשימות.

הסימן המערכתי החשוב יותר: **fixture שנבנה על ידי אותו מפתח שכתב את החוזה אינו
ראיה לשמישות.** ה-fixture נבנה עם ערכי הספק כבר בפנים, ולכן הוא מקודד את ההנחה
השגויה במקום לחשוף אותה. 110 טסטים ירוקים לא זיהו זאת.

## איך מונעים בעתיד

1. הפרד במפורש `AUTHORED_*_FIELDS` (מה שאדם כותב) מ-`*_FIELDS` (האובייקט המאומת),
   וקשור ערכי ספק דרך פונקציית binding ייעודית (`bind_provider_approval`).
2. אכוף שהגוף ה-authored **לא** מכיל שדות שהספק מקצה — כך זיוף ערך מוקדם נדחה,
   ובמקביל הזרימה האנושית נשארת אפשרית.
3. כלל כללי: כל חוזה שמסתמך על זהות מספק חיצוני חייב live qualification מול הספק
   האמיתי לפני שנטען שהוא עובד. fixtures מוכיחים עקביות פנימית בלבד, לא שמישות.

## טסט רגרסיה

`scripts/enforcement/tests/test-bypass-provider-validation.py` — המקרה שמזריק כל אחד
משני שדות הספק לגוף ה-authored ומוודא דחייה עם `authored approval`, לצד המסלול
החיובי שבו הגוף משמיט אותם והאימות מצליח. הטסט נכשל על המימוש שקדם לתיקון.

## סטטוס הבשלה

Verified Lesson

## Prevented Future Issues: 0
