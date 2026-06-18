# Bug: L2 Mandatory Skills — טקסט אינו אכיפה

**תאריך:** 2026-06
**חומרה:** High — כשל מערכתי שגרם לכל שאר הבעיות
**סטטוס:** מתועד + אכיפה פיזית נוספה

---

## שורש הבעיה

ה-Engineering OS הגדיר L2 mandatory skills (superpowers:brainstorming, verification-before-completion)
כ"חובה" — אך האכיפה הייתה טקסטואלית בלבד (הוראות ב-CLAUDE.md).

**עיקרון שנלמד: LLM קורא הוראות ≠ LLM מבצע הוראות.**

תחת לחץ זמן, context ארוך, או כשה-LLM "בטוח" שהוא יודע מה לעשות — הוא מדלג
על שלבים מחויבים. אין כוח מניעה פיזי שחוסם את ה-skip.

**שרשרת הכשל:**
1. LLM ראה "L2 mandatory: superpowers:brainstorming before features"
2. LLM דילג על השלב כי "הוא כבר מבין את המשימה"
3. פיצ'ר נכתב ללא brainstorming ← אפיון לא מלא ← רגרסיה

---

## מניעה

כל חוק שניתן לאכוף כ-exit 1 — נאכף כך:
- Write hook חוסם קוד ללא plan file (exit 1)
- Agent hook חוסם spawn ללא tasks.json (exit 1)
- commit-msg hook חוסם commits ללא 🧪 section (exit 1)
- pre-commit hook חוסם commits ללא test files (exit 1)

L2 skills שלא ניתן לאכוף פיזית → session banner + commit-msg evidence requirement.

---

## הלקח המרכזי

> "הגדרה בטקסט ≠ אכיפה. הפרש בין 'מוגדר' ל'קורה בפועל' הוא כמעט מוחלט."

כל rule חדש ב-Engineering OS חייב לעבור שאלה: **"איך זה מגובה ב-exit 1?"**

---

## תועד ב

`core/hooks-policy.md` + כל hooks שנוצרו בניסוי זה
