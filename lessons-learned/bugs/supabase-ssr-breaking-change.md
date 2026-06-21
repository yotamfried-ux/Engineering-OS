# Bug: @supabase/ssr שינוי שובר (breaking change) ב-v0.4

**תאריך:** 2026-06
**חומרה:** High — גרם ל-4 TypeScript errors שעצרו את ה-build

## מה קרה

`npm install @supabase/ssr` התקין v0.4, שבה ה-API של `createServerClient` שונה.
הקוד שנכתב הניח API של v0.3, וה-build נעצר עם 4 שגיאות TypeScript על `createServerClient`.

## שורש הבעיה

הקוד נכתב לפי API של v0.3 (כפי שהכיר ה-LLM מ-training data), בעוד `npm install` העלה
את v0.4 אוטומטית — בלי בדיקת תיעוד עדכני לפני הכתיבה.

**שרשרת הכשל:**
1. LLM מריץ `npm install @supabase/ssr` ללא בדיקת תיעוד עדכני
2. v0.4 עולה אוטומטית
3. 4 TypeScript errors על `createServerClient` — signature השתנה
4. זמן debug מיותר שאפשר היה למנוע

## השערות שנבדקו

- "שגיאת קוד מקומית" — נשללה, כי הקוד תאם את התיעוד שה-LLM הכיר (v0.3).
- "שינוי API בין v0.3 ל-v0.4" — אומתה כשורש, כי signature של `createServerClient` שונה ב-v0.4.

## ראיה

4 שגיאות TypeScript על `createServerClient` מיד אחרי ההתקנה; השוואת ה-signature
בתיעוד v0.4 מול הקוד שנכתב הראתה אי-התאמה ישירה.

## רמת ביטחון

Medium — השורש הוכח בראיה ישירה (build errors + diff מול התיעוד), אך נצפה בהקשר אחד.

## איך מזהים מוקדם

`npx tsc --noEmit` מיד אחרי כל `npm install` של ספרייה חדשה — תופס breaking change לפני המשך עבודה.

## איך מונעים בעתיד

**לפני כל `npm install <package>` — חובה:**
1. `mcp__Context7__resolve-library-id` → קבל library ID
2. `mcp__Context7__query-docs` → קרא תיעוד עדכני לגרסה הנוכחית
3. רק אז התקן

PreToolUse hook ב-`.claude/settings.json` מזריק reminder אוטומטי על כל `npm install`.

## טסט רגרסיה

אחרי כל `npm install` של ספרייה חדשה:
```bash
npx tsc --noEmit 2>&1 | head -20
```
(אין כשל TypeScript = ה-API תואם.)

## סטטוס הבשלה

Verified Lesson

## תועד ב

`core/workflow.md` שלב 2 — Context7 mandatory לפני npm install

## Prevented Future Issues: 0
