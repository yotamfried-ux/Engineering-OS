# resource-management.md — ניהול משאבים

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - לפני בחירת מודל ל-LLM call או sub-agent.
> - לפני הפעלת sub-agent — לבדוק אם צריך agent כלל.
> - כשכותבים תשובה — לקרוא את מדיניות הפלט.
> - בתחילת פרויקט חדש — ליצור `.claudeignore`.
> - כשמוסיפים AI agent לאפליקציה — לקרוא `<ai-agent-quotas>`.

**עיקרון-העל:** כל טוקן מיותר הוא עלות ישירה. חיסכון ברמת ה-OS מצטבר על פני
כל פרויקט ותורם לאיכות העבודה (פחות context clutter = התמקדות טובה יותר).

---

## <model-selection>

**ברירת מחדל: `claude-sonnet-4-6`** — לרוב המשימות. אל תחליף בלי סיבה מפורשת.

| סוג משימה | מודל מומלץ | model ID |
|---|---|---|
| ארכיטקטורה, security review, debugging מורכב, multi-step reasoning | Opus | `claude-opus-4-8` |
| קוד, refactoring, PR review, debug רגיל, **ברירת מחדל** | Sonnet | `claude-sonnet-4-6` |
| lookup מהיר, summarization, monitoring agents, sub-agents פשוטים | Haiku | `claude-haiku-4-5-20251001` |

**כללים:**
- **אל תעלה מודל** (Sonnet → Opus) ללא טריגר מפורש: יותר מ-3 שלבים תלויים, security gate, ארכיטקטורה.
- **Haiku לsub-agents**: כל agent שמטרתו בלבד חיפוש/lookup — דווח ב-model override.
- **לעולם אל תציין מודל ב-commit messages, PR bodies, או comments בקוד.**

</model-selection>

---

## <nemotron-routing>

**Nemotron (Nvidia) — מתי לאצול משימה במקום לבצע ב-Claude:**

| משימה | לאן | טריגר |
|---|---|---|
| יצירת קוד / boilerplate | `nemotron_generate_code` | output צפוי > ~50 שורות |
| כתיבת unit tests | `nemotron_generate_code` (output_type=tests) | test suite שלם |
| כתיבת docs/docstrings | `nemotron_generate_code` (output_type=documentation) | docs גדולים |
| first-pass code review | `nemotron_review_code` / agent `nemotron-code-reviewer` | diff > 100 שורות |
| סיכום קובץ/PR/log | `nemotron_summarize` | תוכן > 200 שורות |
| הסבר קוד לא מוכר | `nemotron_explain` | כל גודל |
| brainstorming גישות | `nemotron_brainstorm` | צריך > 3 alternatives |

**כללי אצבע:**
- generation קטנה (<10 שורות) — Claude ישירות, overhead של MCP call לא שווה.
- **לעולם אל תעביר** ל-Nemotron: security gate, orchestration, edit קבצים, context עם secrets.
- **תמיד** אמת פלט Nemotron לפני שמחיל עם Edit.
- graphify non-code extraction — אוטומטי דרך `OPENAI_API_KEY` שמוגדר ב-`session-setup.sh`.

ראה: [`../external-skills/nemotron/integration.md`](../external-skills/nemotron/integration.md)

</nemotron-routing>

---

## <sub-agents>

Sub-agents (Agent tool) מתאימים כשיש עבודה שאפשר להקביל או שתאסוף context רב
מדי בשיחה הראשית. השאלה לפני spawn: "האם Grep/Read אחד-שניים מספיקים?"

### מתי כן להפעיל

| מצב | סוג |
|---|---|
| חקירת קוד פתוחה (לא יודעים מה נמצא) | Explore agent, foreground |
| שתי חקירות **עצמאיות** שצריך את שתיהן | 2 Explore agents במקביל |
| תוצאת החקירה נחוצה לפני שממשיכים | foreground |
| בנייה/tests שאינה תלויה בקוד שנכתב כרגע | background |

### מתי לא

- **שאלה אחת ממוקדת** — Grep/Read ישיר מהיר יותר ולא מבזבז context.
- **פחות מ-3 שאלות** — כתוב בשיחה הראשית.
- **agent תלוי בתוצאת agent אחר** — הפעל בסדרה (sequential), לא מקביל.

### כללי הפעלה

```
מקסימום מקבילי: 3 agents
מודל: Haiku לlookup; Sonnet לקוד/ניתוח; Opus לארכיטקטורה (נדיר)
foreground vs. background: foreground כשצריך תוצאה לפני המשך
```

**בכל prompt לsub-agent**: ציין context מינימלי — קבצים ספציפיים, לא "קרא הכל".

</sub-agents>

---

## <token-output>

**מדיניות ברירת מחדל: קצר ומדויק.**

| סיטואציה | כלל |
|---|---|
| תשובה שאינה קוד | משפט אחד–שניים אלא אם יש צורך אמיתי ביותר |
| עריכת קוד | diff בלבד — לא קבצים שלמים |
| comments בקוד | רק כש-WHY לא מובן; אף פעם לא WHAT |
| דוח בסוף משימה | 🧰 בלוק (חובה), ללא הרחבה נוספת |
| "הסבר לי" / "פרט" | הרחב — המשתמש ביקש |
| TODO / ניתוח פרויקט | 3–5 bullets; לא דוח מלא |

**אסור:**
- להחזיר קובץ שלם כשהשינוי הוא 3 שורות.
- להסביר מה הקוד עושה (שמות מייצגים).
- לספק "אלטרנטיבות" שלא התבקשו.
- לסיים ב"האם יש עוד שאלות?"

</token-output>

---

## <claudeignore>

**כל פרויקט חייב `.claudeignore`** — הגדרת מה Claude אינו קורא.

קובץ baseline: [`../.claudeignore`](../.claudeignore) בריפו של Engineering OS.

**מה תמיד לכלול:**
- `node_modules/`, `vendor/`, `.git/`
- Lock files (`package-lock.json`, `yarn.lock`, `Cargo.lock`)
- Build outputs (`dist/`, `build/`, `.next/`)
- Binary assets (`*.png`, `*.pdf`, `*.mp4`)
- Secrets (`.env`, `*.pem`, `*.key`)
- Generated files (`*.min.js`, `__snapshots__/`, `coverage/`)

**מה לשקול לפי פרויקט:**
- קבצי migration ישנים (מעל 6 חודשים)
- Generated types (`*.generated.ts`)
- Storybook stories אם לא רלוונטי לשאלה

**כלל**: אם Claude שאל על קובץ שאינו רלוונטי לשאלה — הוסף אותו ל-`.claudeignore`.

</claudeignore>

---

## <graphify-pre-code>

### כשאין קוד בריפו (שלבים מוקדמים)

graphify תמיד רץ — גם אם הגרף ריק. Graphify עצמו מתריע אם הריפו קטן מדי.
**לא מדלגים עליו, לא מוסיפים תנאי "אם יש מספיק קוד".**

| שלב | מקור חיסכון עיקרי |
|---|---|
| לפני commit ראשון | `.claudeignore`, claude-mem, RTK, CLAUDE.md תמציתי |
| אחרי commit ראשון | הגרף קיים; קאש post-commit hook |
| ריפו בשל | graphify query במקום grep/read רגיל |

**אחרי כל commit**: hook מריץ `graphify update .` אוטומטית (AST-only, ללא API key).

**Engineering OS ספציפי:** הריפו הוא בעיקר `.md` — graphify עובד על ה-scripts בלבד.
ה-`.graphifyignore` מוגדר בהתאם.

</graphify-pre-code>

---

## <rtk>

RTK (Rust Token Killer) — proxy CLI שמיירט פלטי Bash ומכווץ אותם לפני שנכנסים
ל-LLM context. חיסכון: **60–90%** על פלטי `git`, `grep`, `find`, `test`, build.

### מה מכוסה / לא מכוסה

| מכוסה (דרך Bash tool) | לא מכוסה |
|---|---|
| `git status/log/diff` | Read tool |
| `find`, `grep`, `ls` | Grep tool |
| test runners (pytest, jest, cargo test) | Glob tool |
| build tools (cargo build, tsc, eslint) | MCP tools |
| `docker ps`, `kubectl` | |

### שימוש

RTK רץ **שקוף** דרך PreToolUse hook — אין שינוי בנוהל.
פקודות Bash שוכתבות אוטומטית ל-`rtk <cmd>`.

```bash
rtk gain          # ניתוח חיסכון מצטבר
rtk gain --history  # היסטוריה פר פקודה
rtk discover      # זיהוי הזדמנויות חיסכון שהוחמצו
```

### התקנה (חד-פעמית)

```bash
# macOS
brew install rtk
# Linux / WSL
curl -fsSL https://rtk.ai/install.sh | sh
# מכל מקום עם cargo
cargo install --git https://github.com/rtk-ai/rtk
# לאחר מכן — רישום hook גלובלי
rtk init -g
```

גם `session-setup.sh` מטפל בזה אוטומטית.

</rtk>

---

## <ai-agent-quotas>

**רלוונטי כשהאפליקציה שאנחנו בונים כוללת AI agents שמשתמשים עושים בהם שימוש.**

### עקרון

כל user session שמפעיל LLM calls מייצר עלות. ללא caps, עלות בלתי-מבוקרת.

### ארכיטקטורה מומלצת

```
User request → rate limiter → token counter → LLM call
                                 ↓
                        Supabase/Upstash tracking
```

**Per-user tracking**:
```sql
-- Supabase example schema
CREATE TABLE token_usage (
  user_id UUID REFERENCES auth.users,
  date    DATE DEFAULT CURRENT_DATE,
  tokens  INTEGER DEFAULT 0,
  PRIMARY KEY (user_id, date)
);
```

**Tiers** (לדוגמה):
| Tier | Daily cap | Monthly cap |
|---|---|---|
| Free | 50K tokens | 500K tokens |
| Pro | 500K tokens | 5M tokens |
| Enterprise | custom | custom |

**Hard cap**: דחה request עם `429 Too Many Requests` + `Retry-After`.
**Soft cap (80%)**: הזהר במסרת status header.

**Pattern location**: `patterns/ai-agents/quotas.md` (נוצר כשנדרש).

</ai-agent-quotas>

---

## <remote-session-limitations>

מגבלות ידועות בסביבת remote (Claude Code on the web / GitHub Actions):

| כלי | מגבלה | Workaround |
|---|---|---|
| `agent isolation: "worktree"` | נכשל כש-CWD לא git repo תקין | בדוק `git rev-parse --git-dir` לפני שימוש; השתמש ב-`isolation: "none"` |
| `claude-mem worker` | לא מובטח ב-remote sessions | best-effort; session-setup מנסה אוטומטית |
| `settings.json` user-level | לא קיים ב-remote | הכל ב-`.claude/settings.json` פרויקטלי |
| SSH clone | אין SSH agent ב-web sessions | session-setup מגדיר HTTPS override אוטומטית |

ראה גם: [`lessons-learned/bugs/worktree-isolation-remote-session.md`](../lessons-learned/bugs/worktree-isolation-remote-session.md)

### tasks.json — פורמט מחייב (Agent hook בודק שקיים לפני spawn)

```json
{
  "task_id": "YYYY-MM-DD-task-name",
  "agents": {
    "agent-1": {
      "goal": "תיאור המטרה",
      "files": ["paths/to/relevant/files"],
      "status": "pending|running|done|failed",
      "result": ""
    }
  },
  "spec_loop_verified": false,
  "tools_used": [],
  "failures": []
}
```

**כלל:** `spec_loop_verified` מוגדר ל-`true` רק אחרי שוידאת כל DoD item ב-plan file מול התוצר בפועל.

</remote-session-limitations>

---

## חיבור לשאר המערכת

- **session-setup.sh** — מריץ graphify ו-RTK בתחילת כל סשן ([`../scripts/session-setup.sh`](../scripts/session-setup.sh))
- **skill-orchestration-policy.md** — RTK ו-graphify רשומים כסקילים ([`skill-orchestration-policy.md`](./skill-orchestration-policy.md))
- **.claudeignore** — baseline ignore file ([`../.claudeignore`](../.claudeignore))
- **hooks-policy.md** — hooks שמאכפים את הכללים האלה ([`hooks-policy.md`](./hooks-policy.md))
