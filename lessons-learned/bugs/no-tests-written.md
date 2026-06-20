# Bug: אפס טסטים נכתבו לאורך כל הניסוי

**תאריך:** 2026-06
**חומרה:** High — כל ה-codebase הניסויי חסר coverage

## מה קרה

לאורך כל ניסוי Engineering OS SaaS 0.2 לא נכתב **אף טסט אחד**, למרות שהוראת
"כתוב טסטים" הייתה קיימת ב-CLAUDE.md וב-quality-gates.md.

## שורש הבעיה

**לא הייתה חסימה פיזית** שמנעה commit ללא tests. ה-LLM ידע את הכלל אך לא ביצע אותו —
הוראה טקסטואלית בלי גיבוי ב-exit 1 אינה אכיפה.

**שרשרת הכשל:**
1. LLM כותב קוד
2. LLM מבצע commit ללא tests
3. לא הייתה חסימה → commit עובר
4. Pattern מצטבר: "זה עבר פעם, אז OK"

## השערות שנבדקו

- "ההוראה לא הייתה מספיק ברורה" — נשללה, כי הכלל היה מפורש בשני קבצים.
- "אין כוח מניעה פיזי שחוסם commit ללא טסט" — אומתה כשורש: ברגע שנוסף scan פיזי, ההתנהגות השתנתה.

## ראיה

סקירת ה-codebase של הניסוי: אפס קבצי `*.test.*`/`*.spec.*`. הכלל היה כתוב ולא בוצע
לאורך עשרות commits — כלומר טקסט-בלבד לא מנע את ההתנהגות.

## רמת ביטחון

Medium — השורש (היעדר חסימה פיזית) הוכח בכך שתוספת ה-scan שינתה את ההתנהגות; הקשר ניסוי יחיד.

## איך מזהים מוקדם

`find . -name '*.test.*' -o -name '*.spec.*' | head` בתחילת פרויקט — אפס תוצאות = סיכון.

## איך מונעים בעתיד

**pre-commit.sh — Physical Test File Scan:** סקריפט מריץ `find` על ה-filesystem בפועל. אם:
- יותר מ-2 קבצי קוד staged (`.ts/.py/.go` וכו')
- **אפס** קבצי טסט קיימים בכל הפרויקט (`*.test.ts`, `*.spec.py`, `*.test.go` וכו')

→ **exit 1** — commit נחסם. זו בדיקה פיזית של filesystem, לא בדיקת כוונות.

**הבחנה חשובה:** הבדיקה project-wide, לא per-change. פרויקט עם tests קיימים → עובר תמיד
(PROJECT_TESTS > 0). פרויקט ללא tests בכלל → נחסם על commits גדולים.

## טסט רגרסיה

```bash
# אמת שה-hook מותקן ומכיל את ה-scan
ls -la .git/hooks/pre-commit && head -5 .git/hooks/pre-commit
```

## סטטוס הבשלה

Verified Lesson

## תועד ב

`scripts/hooks/pre-commit.sh` + `core/quality-gates.md` › physical enforcement

## Prevented Future Issues: 0
