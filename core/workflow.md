# workflow.md — תהליך העבודה

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - בתחילת **כל** משימה — כדי לדעת מאיזה שלב מתחילים ומה הסדר.
> - כשמקימים פרויקט חדש (`<onboarding>`, `<project_scaffold>`).
> - לפני מיזוג ל-main — לסגירת `<spec_loop>` (אימות מול אפיון).
> - כשעולה צורך בריפקטור (`<refactor_loop>`).
> - כשרוצים להבין איך לנהל את לולאת ה-turns וה-state (`<agent_loop>`).

---

## <agent_loop>

אתה פועל בלולאה: מקבל הקשר ← מחליט ← קורא לכלים ← מקבל תוצאות ← חוזר, עד שאין
עוד צורך בכלים. כל סבב כזה הוא "turn". נצל זאת כך:

- **בצע קריאות כלי בלתי-תלויות במקביל.** קריאת כמה קבצים או כמה בדיקות שאינן תלויות
  זו בזו — בו-זמנית, לא בזה אחר זה. קריאות תלויות (שהפלט של אחת מזין את השנייה) —
  ברצף.
- **התקדם בצעדים קטנים ומדידים.** עדיף סדרת turns קטנים שכל אחד מאומת, על פני קפיצה
  גדולה אחת.
- **עקוב אחר state דרך git ודרך קבצים מובנים.** ל-state מובנה (תוצאות טסטים, סטטוס
  משימות) השתמש ב-JSON (`tasks.json`); להערות התקדמות חופשיות — טקסט פשוט.

  > **אכיפה:** PreToolUse Agent hook חוסם spawn אם `.claude/tasks.json` לא קיים (exit 1).
  > צור `tasks.json` לפי הסכמה ב-`core/resource-management.md` › `<remote-session-limitations>` לפני שמפעילים agents.
- **תעד את מהלך הריצה (run trace).** לצד ה-state, רשום ב-`tasks.json` אילו
  קונקטורים/כלים שימשו, מספר ה-turns, ונקודות כשל. זה זול, וזה מה שמאפשר ל-
  [`learning-loop.md`](./learning-loop.md) לזהות כשל או כלי שחוזר על פני ריצות (תצפית
  חוזרת) ולשפר את **התהליך** — לא רק את הקוד. בלי תיעוד כזה הסוכן "עיוור לעצמו".
- **handoff ל-subagent — מתי ומה מחזירים.** למשימה מבודדת, ארוכה, או קריאה-כבדה
  (חקירה על פני קבצים רבים), העבר אותה ל-subagent שרץ בקונטקסט נקי. הוא מחזיר **רק
  סיכום קצר בפורמט קבוע**: מטרה · מה נמצא/בוצע · הוכחה (כלי + תוצאה) · פתוח שנותר. כך
  הקונטקסט הראשי נשאר רזה, וההחלטה אם להעביר נשענת על קריטריון ולא על תחושה.
- **שמור state לפני שהקונטקסט מתכווץ.** כשמתקרבים לגבול חלון הקונטקסט: שמור את
  ההתקדמות והמצב (git commit + `tasks.json`) לפני שההיסטוריה מתכווצת (compaction),
  כך שאפשר להמשיך מאותה נקודה בלי לאבד עבודה. ראה `<summary_instructions>` ב-CLAUDE.md
  למה לשמר.
- **נקה הקשר בין משימות לא קשורות.** הקשר שמתמלא בשיחה לא-רלוונטית, תכני קבצים ופלטי
  פקודות פוגע בביצועים. בין משימות שאינן קשורות — אפס את ההקשר (`/clear`). ואם תיקנת
  את עצמך פעמיים על אותה בעיה — ההקשר מזוהם בגישות שנכשלו; אפס והתחל מ-prompt טוב יותר
  שמשלב את מה שלמדת, במקום להמשיך להיאבק באותו הקשר.

</agent_loop>

---

## <workflow>

כל משימה עוברת את אותו pipeline. **לב התהליך:** מתכננים, אוספים מידע אמין, ורק כשמבינים
את כל הדרישות והארכיטקטורה ויש מקור ודוגמה לעבוד מולם — מתחילים לכתוב.

> **סקילי תשתית — לפני ה-workflow ולאורכו (לא חלק מהשלבים, אלא שכבת בסיס):**
> - **graphify** — בונה גרף קוד בתחילת כל סשן; שולף תת-גרף רלוונטי לפני כל צעד במקום
>   קריאת קבצים שלמים. חוסך קונטקסט לאורך כל ה-workflow. רץ תמיד, לא דורש שלב ייעודי.
> - **claude-mem** — משחזר הקשר מסשנים קודמים ב-SessionStart; מסכם ב-Stop. פסיבי.
>
> שאר הסקילים (superpowers, security-review, ui-ux-pro-max) הם **כלי עזר לשלבים**
> ומופעלים בשלב 3. כלל הברזל: **השלב חייב לקרות; הסקיל הוא האמצעי, לא התחליף.**

1. **אפיון ותכנון** — השלב הראשון בכל פרויקט/משימה. אפיין ותכנן ב-**Notion**
   (או בקונקטור ניהול פרויקטים ייעודי): מטרה, דרישות, מערכות מושפעות, תוכנית. אם יש
   בחירה בין פלטפורמות (ענן / DB / auth / אירוח) — אבחן אותה והכרע עם המשתמש כאן
   (ראה [`connector-policy.md`](./connector-policy.md) › `<connectors>`).
   *כלי:* `mcp__Notion__notion-create-pages` ליצירת spec · `mcp__Notion__notion-fetch` לקריאה · `mcp__Notion__notion-update-page` לסגירת הלולאה (שלב 10).
   *סקיל שיכול לסייע:* `superpowers:brainstorming` לגיבוש הרעיון, `superpowers:writing-plans` לפירוק לשלבים — הפלט נכתב ב-Notion.

   > **Fallback מאושר:** `.claude/plans/<name>.md` הוא חלופה לגיטימית ל-Notion כשהוא אינו מחובר.
   > Write/Edit hook בודק שקובץ plan קיים לפני כתיבת קוד (exit 1 אם לא). צור plan file לפני שמתחילים.

   > **התוכנית היא מסמך חי — לא סימון V חד-פעמי.** האפיון נוצר בשלב 1 אבל **מתעדכן לאורך כל
   > המשימה**, לא רק בתחילתה ובסיומה. החזק בתוכנית (Notion + `.claude/plans/<name>.md`) סעיף
   > **`## Progress` / `## סטטוס`** ועדכן אותו בכל אבן-דרך ולפני קומיט של שלב: מה הושלם, מה הבא,
   > מה חסום, ואילו DoD items נסגרו. הסיבה: תוכנית שנכתבת פעם אחת ולא נקראת/מתעדכנת שווה לתוכנית
   > שלא קיימת — היא לא משקפת מצב ולא משמשת למעקב.
   > *כלי עדכון:* `mcp__Notion__notion-update-page` (Notion) + עריכת ה-`## Progress` ב-plan file.
   > **אכיפה (לא-חוסמת):** enforce-workflow מזכיר ב-PreToolUse אם חסר `## Progress`; pre-commit מזהיר
   > כששינויים חדשים מהתוכנית; post-commit מזכיר לעדכן אחרי כל קומיט (ראה [`hooks-policy.md`](./hooks-policy.md)).

2. **חיפוש דוגמאות ואיסוף מידע** — משוך פתרון קיים ומקור אמין לפי `<information_sources>`
   (ראה [`connector-policy.md`](./connector-policy.md)): קודם `patterns/`/`templates/`,
   ואז **Context7** לתיעוד רשמי עדכני של הספריות/הגרסאות בהן תשתמש.
   **אם לאחר כל החיפושים אין כיסוי** — הפעל את נוהל הפער לפני כתיבה
   (ראה [`connector-policy.md`](./connector-policy.md) › `<pattern_gap>`).
   *כלי (Context7):* built-in ב-Claude app — השתמש בו ישירות; fallback ל-CLI/remote: `mcp__Context7__resolve-library-id` → `mcp__Context7__query-docs`.
   לבאגים: Sentry ראשון (ראה [`debugging-policy.md`](./debugging-policy.md) › `<debug_loop>`).
   *סקיל שיכול לסייע:* graphify (גרף כבר בנוי — שלוף תת-גרף רלוונטי).

   > **⚠️ חובה לפני כל `npm install` / `pip install`:** Context7 (built-in ב-app, או `mcp__Context7__resolve-library-id` → `mcp__Context7__query-docs` ב-CLI/remote).
   > PreToolUse hook מזריק reminder אוטומטי, אך האחריות היא שלך לבצע.
   > דוגמה: `@supabase/ssr` v0.4 שבר 4 TypeScript types — ראה [`lessons-learned/bugs/supabase-ssr-breaking-change.md`](../lessons-learned/bugs/supabase-ssr-breaking-change.md).
3. **בחירת כלים והערכת סקילים** — בחר את הקונקטורים המתאימים **לפי המשימה**, והעדף כלי
   שכבר בשימוש בפרויקט אם הוא מספק את היכולת (ראה [`connector-policy.md`](./connector-policy.md)).
   **באותו שלב — הערך אילו סקילי-משימה חיצוניים חלים** לפי סוג המשימה, רמת ההרצה והסדר
   (ראה [`skill-orchestration-policy.md`](./skill-orchestration-policy.md) › `<selection_rule>`):
   planning ראשון · security gate שלא ניתן לעקיפה · review אחרון. סקיל LEVEL 2 שחסר —
   הצֵף דרך ה-bootstrap, אל תדלג בשקט.
4. **תכנון יישום** — 3–5 צעדים קונקרטיים, לפני כתיבה.
   *סקיל שיכול לסייע:* `superpowers:writing-plans` לפירוק משימה, `superpowers:subagent-driven-development` לביצוע מקבילי.

   > **שער כניסה לכתיבה (אל תדלג):** התחל לכתוב קוד רק כאשר —
   > (א) הדרישות והארכיטקטורה **מובנות במלואן**;
   > (ב) יש **מקור אמין** להתבסס עליו לפי סגנון הפרויקט (`patterns`/`templates`/Context7)
   >     **ודוגמה** קונקרטית לעבוד מולה.
   > אם אחד מאלה חסר — אתה עדיין בשלב 1–3 (תכנון/איסוף), לא בכתיבה. כתיבה בלי מקור
   > ודוגמה היא ניחוש ארכיטקטורה — בדיוק מה שעקרון-העל אוסר.

   > **debug_loop gate:** שגיאת קומפילציה, כשל CI, או runtime error בשלב זה → STOP.
   > (1) בדוק Sentry ראשון; (2) זהה root cause — אל תתקן תסמין; (3) הוסף regression test.
   > רק אז חזור לכתיבה. `post-commit` hook מזכיר learning_loop אחרי `fix:` commits.
   > ראה [`debugging-policy.md`](./debugging-policy.md) › `<debug_loop>`.

5. **כתיבה איטרטיבית** — שינויים קטנים בתוך ה-branch הפעיל.
   *סקיל שיכול לסייע:* `superpowers:test-driven-development`; `ui-ux-pro-max` לממשק (ראה [`external-skills/ui-ux-pro-max/`](../external-skills/ui-ux-pro-max/)).
6. **אימות** — דרך הכלי המתאים למשימה.
   *סקיל שיכול לסייע:* `superpowers:verification-before-completion` — מריץ פקודות ומאמת לפני הצהרת הצלחה.
7. **ניקוי קוד** — ראה [`quality-gates.md`](./quality-gates.md) › `<cleanup>`.
8. **בדיקת קוד לפני קומיט** — ראה [`quality-gates.md`](./quality-gates.md) ›
   `<pre_commit_review>`.
   *סקיל שיכול לסייע:* `superpowers:requesting-code-review`; security-review (L2 — חובה לפני main).
9. **קומיט מובנה** — ראה [`git-policy.md`](./git-policy.md) › `<commit_protocol>`.
10. **אימות מול האפיון** — ודא שהתוצר תואם למה שאופיין בשלב 1 (ראה `<spec_loop>`).
    רשימת תנאי הסיום המלאה: [`quality-gates.md`](./quality-gates.md) › `<definition_of_done>`.

    > **אכיפה:** Stop hook מציג תזכורת spec_loop + DoD אם יש staged changes. סמן ✅ על **כל** DoD item ב-plan file לפני merge. `spec_loop_verified: true` ב-tasks.json אם עבדת עם agents.
11. **מיזוג ל-main** — רק אחרי אימות מלא ו**אישור המשתמש** (ראה
    [`git-policy.md`](./git-policy.md)).
    *סקיל שיכול לסייע:* `superpowers:finishing-a-development-branch` לבחירת אופן המיזוג.
12. **תיעוד למידה** — אם נחשף לקח, ראה [`learning-loop.md`](./learning-loop.md).

> **מתי לדלג על אפיון מלא:** אפיון ותכנון (שלבים 1–4) הם חובה למשימה שמשנה כמה קבצים,
> כשהגישה לא ברורה, או בקוד לא מוכר. אבל הם מוסיפים תקורה — למשימה טריוויאלית שאפשר
> לתאר את ה-diff שלה במשפט אחד (תיקון typo, הוספת שורת לוג, שינוי שם משתנה), דלג על
> האפיון ובצע ישירות. **אל תדלג** על האימות (שלב 6) ועל הקומיט המתועד (שלב 9) — לעולם.

</workflow>

---

## <onboarding>

### 0. Prerequisites (חובה לפני שלב 1)

לפני שמתחילים לעבוד עם Engineering OS בפרויקט חדש, ודא שכל הכלים והחיבורים הבאים קיימים:

**כלים נדרשים:**
- `uv` — מנהל חבילות Python (נדרש לgraphify): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `node` / `npm` — נדרש לrtk ולסקילים נוספים
- `git` — ברמה 2.x לפחות

**הגדרת `.env`** — צור קובץ `.env` בשורש הפרויקט עם הטוקנים הנדרשים:
```
Nemotron_api_key=nvapi-...          # ראשי — לgraphify (semantic) ולsecurity-review (Nemotron MCP)
# ANTHROPIC_API_KEY — לא נדרש; security-review רץ על Nemotron, לא Anthropic API
NOTION_TOKEN=secret_...             # לניהול spec ואפיון (שלב 1 בworkflow)
GITHUB_TOKEN=ghp_...                # לGitHub MCP ולpull requests
```
> **אבטחה:** `.env` חייב להיות ב-`.gitignore`. לעולם אל תעשה commit לטוקנים.

**חיבור שרתי MCP** (פעם אחת לכל מכונה, בתוך Claude Code CLI):
```bash
# Notion — לניהול spec ואפיון
claude mcp add notion https://mcp.notion.com/mcp

# Context7 — לתיעוד ספריות עדכני
claude mcp add context7 https://mcp.context7.com/mcp
```
אמת חיבור: `/mcp` בתוך Claude Code — שני השרתים חייבים להופיע כ-connected לפני שממשיכים.

**התקנה ידנית של `superpowers`** (פעם אחת לכל מכונה, בתוך Claude Code CLI):
```
/plugin install superpowers@claude-plugins-official
```
אמת: `/plugin list` — צריך להופיע `superpowers`.

---

### שלבי Onboarding

לפני כתיבת קוד בפרויקט שאינך מכיר:

1. קרא את `CLAUDE.md` ואת קבצי ההגדרה (`package.json`, `pyproject.toml`, `.env.example`).
2. אפיין ותכנן את המשימה (שלב 1 ב-`<workflow>`).
3. הבן את הארכיטקטורה והספריות ומשוך תיעוד עדכני (ראה
   [`connector-policy.md`](./connector-policy.md) › `<information_sources>` — קודם
   `patterns`/`templates`, ואז Context7).
4. זהה שפה, ספריות, וקונקטורים שהפרויקט דורש — והפעל את אלה תלויי-הפרויקט המתאימים.
5. אל תניח מבנה — בדוק בפועל איך הקוד מאורגן.
6. **הרץ את ה-bootstrap של הסקילים** — `scripts/skill-bootstrap.sh` כדי לוודא שהסקילים
   הנדרשים קיימים בפרויקט; דווח על חסרים (ראה [`skill-orchestration-policy.md`](./skill-orchestration-policy.md) › `<bootstrap>`).
   - `superpowers`, `security-review`, `claude-mem` דורשים התקנה ידנית — ראה
     `external-skills/<skill>/activation.md` לפירוט.

</onboarding>

---

## <project_scaffold>

כדי לא לחזור על הגדרות בסיס בכל פרויקט, כל פרויקט חדש מתחיל מתשתית קבועה. כשמקימים
פרויקט — צור את הקבצים החסרים מהרשימה לפי השפה/הפריימוורק; אל תמציא הגדרות חדשות
לכל פרויקט מאפס.

### קבצי בסיס בכל פרויקט (ללא תלות בשפה)

- `README.md` — מה הפרויקט, איך מריצים, פקודות עיקריות.
- `CLAUDE.md` — קובץ ההנחיות.
- `.gitignore` — לכל הפחות: `.env`, תיקיות build/dist, תלויות (`node_modules` וכו'),
  קבצי IDE, לוגים.
- `.env.example` — שמות כל המשתנים עם ערכי דמה (ראה
  [`connector-policy.md`](./connector-policy.md) › `<environment>`).
- `.editorconfig` — כללי עריכה אחידים (קידוד, indent, סוף שורה).
- `lessons-learned/` ו-`failed-solutions/` — תיקיות ללולאת הלמידה.
- **שכבת hooks בסיסית** — אכיפה דטרמיניסטית של הכללים הבלתי-עבירים (ראה
  [`hooks-policy.md`](./hooks-policy.md) › `<hooks>`): pre-commit שמריץ lint+טסטים,
  חסימת `--no-verify`, חסימת כתיבה לנתיבים מוגנים, סריקת secrets.
- **bootstrap של סקילים** — הרץ `scripts/skill-bootstrap.sh` כדי לוודא שהסקילים החיצוניים
  הנדרשים (LEVEL 1/2) מותקנים בפרויקט, והתקן את החסרים באישור (ראה
  [`skill-orchestration-policy.md`](./skill-orchestration-policy.md) › `<bootstrap>`).

### לפי סוג פרויקט

- **JS / TS** — `package.json`, הגדרת linter+formatter (ESLint + Prettier),
  `tsconfig.json` ל-TypeScript, קונפיג טסטים (Vitest/Jest).
- **Python** — `pyproject.toml`, הגדרת linter+formatter (Ruff), קונפיג טסטים
  (pytest), `.python-version`.
- **כל פרויקט** — הגדרת pre-commit כ-**hook אוכף** (lint + format + טסטים; ראה
  [`hooks-policy.md`](./hooks-policy.md)) ו-CI בסיסי ב-GitHub Actions שמריץ את אותן בדיקות.

לסוגי פרויקט נוספים — ראה תבנית מוכנה ב-`templates/<type>/README.md`:

| סוג פרויקט | תבנית |
|------------|-------|
| ML / Data Science | [`templates/machine-learning/`](../templates/machine-learning/) |
| AI Agent / Multi-Agent | [`templates/multi-agent-system/`](../templates/multi-agent-system/) |
| Mobile (iOS/Android/RN) | [`templates/mobile-application/`](../templates/mobile-application/) |
| CLI tool / Library | [`templates/desktop-application/`](../templates/desktop-application/) |
| Microservice | [`templates/microservice/`](../templates/microservice/) |
| RAG / LLM system | [`templates/rag-system/`](../templates/rag-system/) |
| ETL / Data pipeline | [`templates/etl-elt-system/`](../templates/etl-elt-system/) |

לסוג שאינו ברשימה — הוסף קבצי בסיס מקובלים לאותו סוג (מבנה תיקיות, ניהול תלויות,
seed לשחזוריות), באותו עיקרון של תשתית קבועה במקום הגדרה מאפס בכל פעם.

### כלל עבודה

- העדף **תבנית מאושרת מ-[`templates/`](../templates/)** (ראה
  [`connector-policy.md`](./connector-policy.md) › `<information_sources>`) על פני
  בנייה מאפס. הקמת פרויקט = clone של התבנית המתאימה והתאמה.
- בזמן ההקמה אפיין (שלב 1 ב-`<workflow>`) אילו מהקבצים תלויי-הפרויקט נדרשים.
- **תאימות לכלים אחרים (AGENTS.md):** אם הפרויקט אמור לעבוד גם עם כלי AI אחרים
  (Codex, Cursor וכו'), החזק את ההנחיות המשותפות ב-`AGENTS.md` וייבא אותן ל-`CLAUDE.md`
  עם `@AGENTS.md` במקום לשכפל. הנחיות ספציפיות לקלוד נכתבות מתחת לייבוא.
- **כללים תלויי-נתיב (`.claude/rules/`):** במקום להישען על כך שקלוד יזכור לגשת לקובץ
  core לפי המשימה, אפשר להגדיר rule עם frontmatter של `paths:` שנטען אוטומטית רק כשנוגעים
  בקבצים תואמים (למשל כללי API שנטענים רק ב-`src/api/**`). חוסך הקשר ומבטיח טעינה בזמן הנכון.

</project_scaffold>

---

## <spec_loop>

**מתי:** נסגרת בשלב 10 ב-`<workflow>`, אחרי הקומיט ולפני המיזוג ל-main.

המטרה: לוודא שמה שנבנה תואם למה שאופיין — לא רק שהקוד "עובד", אלא שהוא עושה את
הדבר הנכון. קוד תקין שלא תואם לדרישה הוא עדיין כישלון.

האפיון נכתב בתחילת המשימה ב-Notion (שלב 1 ב-`<workflow>`): מטרה, דרישות, קריטריוני
סיום. סגירת הלולאה:

1. השווה את התוצר מול האפיון: האם כל דרישה מולאה? האם יש סטיות?
2. אם יש פער — סגור אותו, או (אם הפער מכוון/מוצדק) עדכן את האפיון ב-Notion ויידע
   את המשתמש על השינוי.
3. סמן את המשימה כהושלמה ב-Notion רק כשהתוצר והאפיון תואמים.

הסיבה לסגירת הלולאה מול האפיון: בלי השוואה חוזרת קל "להיסחף" ולבנות משהו עובד אך
שגוי, והפער מתגלה מאוחר ויקר.

**טיפ הקשר:** אחרי שהאפיון נכתב, שקול להתחיל הקשר נקי לביצוע. האפיון הכתוב משמש כייחוס,
והקשר נקי שממוקד כולו ביישום מפיק תוצאה טובה יותר מהקשר שכבר התמלא בשלב התכנון. אפיון
טוב הוא עצמאי: שמות הקבצים והממשקים המעורבים, מה מחוץ להיקף, וצעד אימות מקצה-לקצה.

</spec_loop>

---

## <refactor_loop>

**מתי:** לא שלב קבוע ב-`<workflow>`. רץ רק כשריפקטור הוא חלק מהמשימה שאופיינה,
או הכרחי לתיקון — לא יוזמה עצמאית. זה מתיישב עם עקרון ה-minimal change ב-
`<core_principles>` (ב-CLAUDE.md): אל תנקה או "תשפר" קוד שלא נגעת בו.

כשריפקטור מוצדק:

1. ודא שיש בדיקה שמכסה את ההתנהגות הקיימת **לפני** השינוי (אחרת אין מול מה לאמת).
2. שנה בצעדים קטנים — שמור על אותה התנהגות חיצונית.
3. אמת אחרי כל צעד שהבדיקות עדיין עוברות (אותה התנהגות, מבנה טוב יותר).
4. אם ריפקטור גדול עולה תוך כדי משימה אחרת — אל תבצע אותו אגב; הצף למשתמש כמשימה נפרדת.

</refactor_loop>
