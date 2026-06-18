# Bug: אפס טסטים נכתבו לאורך כל הניסוי

**תאריך:** 2026-06
**חומרה:** High — כל ה-codebase הניסויי חסר coverage
**סטטוס:** מתועד + pre-commit physical scan נוסף

---

## שורש הבעיה

לאורך כל ניסוי Engineering OS SaaS 0.2, לא נכתב **אף טסט אחד**.
הסיבה: **לא הייתה חסימה פיזית** שמנעה commit ללא tests.

הוראת "כתוב טסטים" הייתה קיימת ב-CLAUDE.md ו-quality-gates.md.
ה-LLM ידע את הכלל. ה-LLM לא ביצע אותו.

**שרשרת הכשל:**
1. LLM כותב קוד
2. LLM מבצע commit ללא tests
3. לא הייתה חסימה → commit עובר
4. Pattern מצטבר: "זה עבר פעם, אז OK"

---

## מניעה

**pre-commit.sh — Physical Test File Scan:**

סקריפט מריץ `find` על ה-filesystem בפועל. אם:
- יותר מ-2 קבצי קוד staged (`.ts/.py/.go` וכו')
- **אפס** קבצי טסט קיימים בכל הפרויקט (`*.test.ts`, `*.spec.py`, `*.test.go` וכו')

→ **exit 1** — commit נחסם.

זה לא בדיקת כוונות. זה בדיקה פיזית של filesystem.

**הבחנה חשובה:** הבדיקה היא project-wide, לא per-change.
פרויקט עם tests קיימים → עובר תמיד (PROJECT_TESTS > 0).
פרויקט ללא tests בכלל → נחסם על commits גדולים.

---

## רגרסיה

לאחר התקנת hook:
```bash
# אמת שה-hook מותקן
ls -la .git/hooks/pre-commit && head -5 .git/hooks/pre-commit
```

---

## תועד ב

`scripts/hooks/pre-commit.sh` + `core/quality-gates.md` › physical enforcement
