# Bug: L2 Mandatory Skills — טקסט אינו אכיפה

**תאריך:** 2026-06
**חומרה:** High — כשל מערכתי שגרם לכל שאר הבעיות

## מה קרה

Engineering OS הגדיר L2 mandatory skills (superpowers:brainstorming,
verification-before-completion) כ"חובה" — אך האכיפה הייתה טקסטואלית בלבד, וה-LLM דילג עליהם.

## שורש הבעיה

האכיפה הייתה הוראות ב-CLAUDE.md בלבד, בלי כוח מניעה פיזי. **LLM קורא הוראות ≠ LLM מבצע
הוראות** — תחת לחץ זמן, context ארוך, או "ביטחון" שהוא יודע מה לעשות, ה-LLM מדלג על שלבים מחויבים.

**שרשרת הכשל:**
1. LLM ראה "L2 mandatory: superpowers:brainstorming before features"
2. LLM דילג על השלב כי "הוא כבר מבין את המשימה"
3. פיצ'ר נכתב ללא brainstorming ← אפיון לא מלא ← רגרסיה

## השערות שנבדקו

- "צריך לנסח את ההוראה חזק יותר" — נשללה, כי גם הוראות מודגשות דולגו.
- "רק אכיפה דטרמיניסטית (exit 1) משנה התנהגות" — אומתה: כללים שגובו ב-hooks הופסקו מלהידלג; טקסט-בלבד המשיך להידלג.

## ראיה

לאורך הניסוי, כללים עם hook (Write ללא plan, Agent ללא tasks.json, commit ללא 🧪)
נחסמו בפועל; כללים טקסטואליים בלבד (L2 skills) דולגו שוב ושוב — הפרש נצפה בין "מוגדר" ל"קורה".

## רמת ביטחון

High — השורש אומת בראיה וגובה בטסטי רגרסיה אוטומטיים (חבילות `scripts/enforcement/tests/`)
שתופסים עקיפה; חזר על פני כל הכללים בניסוי.

## איך מזהים מוקדם

לכל rule חדש שאל: **"איך זה מגובה ב-exit 1?"** — rule בלי תשובה הוא rule שיידלג.

## איך מונעים בעתיד

כל חוק שניתן לאכוף כ-exit 1 — נאכף כך:
- Write hook חוסם קוד ללא plan file (exit 1)
- Agent hook חוסם spawn ללא tasks.json (exit 1)
- commit-msg hook חוסם commits ללא 🧪 section (exit 1)
- pre-commit hook חוסם commits ללא test files (exit 1)

L2 skills שלא ניתן לאכוף פיזית → session banner + commit-msg evidence requirement.

## הלקח המרכזי

> "הגדרה בטקסט ≠ אכיפה. הפרש בין 'מוגדר' ל'קורה בפועל' הוא כמעט מוחלט."

כל rule חדש ב-Engineering OS חייב לעבור שאלה: **"איך זה מגובה ב-exit 1?"**

## טסט רגרסיה

```bash
# כל אוכף נושא חבילת בדיקות שמוכיחה שהעקיפה נחסמת:
for t in scripts/enforcement/tests/test-*.sh; do bash "$t" | tail -1; done
```

## סטטוס הבשלה

Best Practice

## תועד ב

`core/hooks-policy.md` + כל ה-hooks שנוצרו בניסוי זה

## Prevented Future Issues: 0
