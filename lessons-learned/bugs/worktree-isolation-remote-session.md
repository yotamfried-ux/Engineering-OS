# Bug: agent isolation worktree נכשל בסשן remote

**תאריך:** 2026-06
**חומרה:** Medium — עצר זרימת עבודה, לא גרם לאובדן נתונים

## מה קרה

`Agent(isolation: "worktree")` בסשן remote (Claude Code on the web) נכשל עם שגיאת
permission/path מסתורית כשניסה ליצור worktree, והסוכן דיווח כשל לא-ברור.

## שורש הבעיה

`isolation: "worktree"` מנסה `git worktree add` ל-path חיצוני, אך הסביבה ה-remote מוגבלת
ואינה מתירה זאת — כך שהפעולה נכשלת לפני שהסוכן מתחיל לעבוד.

**שרשרת הכשל:**
1. LLM מפעיל `Agent(isolation: "worktree", ...)`
2. Claude Code מנסה `git worktree add /tmp/xxx HEAD`
3. הפעולה נכשלת עם permission error או path error
4. הסוכן מדווח כשל מסתורי ולא ברור

## השערות שנבדקו

- "ה-CWD אינו git repo" — נשללה, כי `/home/user/Engineering-OS` הוא git repo תקין.
- "הסביבה remote מגבילה יצירת worktree ב-path חיצוני" — אומתה כשורש.

## ראיה

הפעולה נכשלה דווקא בסשן remote בעוד אותו דפוס עבד מקומית; השגיאה הייתה על שלב
`git worktree add` ל-path חיצוני, לא על ה-CWD.

## רמת ביטחון

Medium — השורש (הגבלת סביבת remote) הוכח בכך שהכשל ייחודי ל-remote; הקשר אחד.

## איך מזהים מוקדם

```bash
git worktree list 2>/dev/null && echo "worktree supported" || echo "SKIP worktree"
```

## איך מונעים בעתיד

לפני שימוש ב-`isolation: "worktree"`, בדוק:
```bash
git rev-parse --git-dir 2>/dev/null && echo "git repo OK" || echo "NOT a git repo"
```

בסביבות remote: **הימנע מ-worktree isolation** — השתמש ב-`isolation: "none"` עם הפרדת scope ידנית.

## טסט רגרסיה

```bash
# לפני שימוש ב-worktree agent בסשן remote:
git worktree list 2>/dev/null && echo "worktree supported" || echo "SKIP worktree"
```

## סטטוס הבשלה

Verified Lesson

## תועד ב

`core/resource-management.md` › `<remote-session-limitations>`

## Prevented Future Issues: 0
