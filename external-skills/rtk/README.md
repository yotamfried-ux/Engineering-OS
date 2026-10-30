# RTK — Rust Token Killer

**מה זה:** CLI proxy חד-קובץ (Rust binary, zero dependencies) שמיירט פלטי Bash
ומכווץ אותם לפני שנכנסים ל-LLM context. חיסכון מצוי: **60–90%** על פלטי dev tools.

**מקור:** https://github.com/rtk-ai/rtk (upstream licensing uses Apache-2.0 / BUSL-1.1 editions; review before adoption)
**גרסה יציבה עדכנית ב-upstream שנבדקה ב-2026-10-30:** `rtk 1.1.0` — גרסת ה-install-once manager המאומתת בנפרד היא `0.49.0` (אין לבלבל בין latest ל-qualified).

---

## מה RTK עושה

ארבע אסטרטגיות אופטימיזציה:
1. **Smart Filtering** — מסיר רעש וboilerplate
2. **Grouping** — מאגד פריטים דומים (קבצים לפי ספרייה, errors לפי סוג)
3. **Truncation** — שומר קונטקסט רלוונטי, גוזר חזרות
4. **Deduplication** — קורס שורות חוזרות עם מונה

**פקודות נתמכות (100+):** `git`, `find`, `grep`, `ls`, `cat`, `diff`, build tools
(cargo, tsc, eslint, ruff), test runners (pytest, jest, go test), containers
(docker ps, kubectl).

---

## מה RTK לא מכסה

Claude Code built-in tools — **Read**, **Grep**, **Glob** — לא עוברים דרך Bash
ולכן אינם מסוננים. RTK פועל רק על Bash tool calls.

---

## התקנה בקצרה

```bash
# macOS
brew install rtk
# Linux / WSL / Windows / כל מקום עם cargo
cargo install --git https://github.com/rtk-ai/rtk
# רישום hook גלובלי (חד-פעמי)
rtk init -g --dry-run    # inspect changes first
rtk init -g              # one-time: approve global hook registration
```

לפרטים מלאים: [`activation.md`](./activation.md).
