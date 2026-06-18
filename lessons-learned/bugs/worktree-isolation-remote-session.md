# Bug: agent isolation worktree נכשל בסשן remote

**תאריך:** 2026-06
**חומרה:** Medium — עצר זרימת עבודה, לא גרם לאובדן נתונים
**סטטוס:** מתועד + מנוהל

---

## שורש הבעיה

`Agent(isolation: "worktree")` מייצר worktree זמני שמניח שה-CWD הוא git repo.
בסשן remote (Claude Code on the web), ה-CWD הוא `/home/user/Engineering-OS` — שהוא git repo.
אבל כשהסקריפט מנסה ליצור worktree ב-path חיצוני, הפעולה נכשלת כי הסביבה remote מוגבלת.

**שרשרת הכשל:**
1. LLM מפעיל `Agent(isolation: "worktree", ...)`
2. Claude Code מנסה `git worktree add /tmp/xxx HEAD`
3. הפעולה נכשלת עם permission error או path error
4. הסוכן מדווח כשל מסתורי ולא ברור

---

## מניעה

לפני שימוש ב-`isolation: "worktree"`, בדוק:
```bash
git rev-parse --git-dir 2>/dev/null && echo "git repo OK" || echo "NOT a git repo"
```

בסביבות remote: **הימנע מ-worktree isolation** — השתמש ב-`isolation: "none"` עם הפרדת scope ידנית.

---

## רגרסיה

**בדיקת רגרסיה:** לפני כל שימוש ב-worktree agent בסשן remote:
```bash
git worktree list 2>/dev/null && echo "worktree supported" || echo "SKIP worktree"
```

---

## תועד ב

`core/resource-management.md` › `<remote-session-limitations>`
