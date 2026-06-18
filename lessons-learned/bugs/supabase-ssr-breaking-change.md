# Bug: @supabase/ssr שינוי שובר (breaking change) ב-v0.4

**תאריך:** 2026-06
**חומרה:** High — גרם ל-4 TypeScript errors שעצרו את ה-build
**סטטוס:** מתועד + Context7 injection נוסף

---

## שורש הבעיה

`npm install @supabase/ssr` התקין v0.4 שינה את ה-API של `createServerClient`.
הקוד שנכתב הניח API של v0.3 (כפי שהכיר ה-LLM מ-training data).

**שרשרת הכשל:**
1. LLM מריץ `npm install @supabase/ssr` ללא בדיקת תיעוד עדכני
2. v0.4 עולה אוטומטית
3. 4 TypeScript errors על `createServerClient` — signature השתנה
4. זמן debug מיותר שאפשר היה למנוע

---

## מניעה

**לפני כל `npm install <package>` — חובה:**
1. `mcp__Context7__resolve-library-id` → קבל library ID
2. `mcp__Context7__query-docs` → קרא תיעוד עדכני לגרסה הנוכחית
3. רק אז התקן

PreToolUse hook ב-`.claude/settings.json` מזריק reminder אוטומטי על כל `npm install`.

---

## רגרסיה

**בדיקת רגרסיה:** אחרי כל `npm install` של ספריה חדשה:
```bash
npx tsc --noEmit 2>&1 | head -20
```

---

## תועד ב

`core/workflow.md` שלב 2 — Context7 mandatory לפני npm install
