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
   *כלי:* Notion MCP ליצירת spec, קריאה, וסגירת הלולאה (שלב 10).
   *סקיל שיכול לסייע:* `superpowers:brainstorming` לגיבוש הרעיון, `superpowers:writing-plans` לפירוק לשלבים — הפלט נכתב ב-Notion.

   > **Fallback מאושר:** `.claude/plans/<name>.md` הוא חלופה לגיטימית ל-Notion כשהוא אינו מחובר.
   > Write/Edit hook בודק שקובץ plan קיים לפני כתיבת קוד (exit 1 אם לא). צור plan file לפני שמתחילים.

   > **Plan Scope:** לפני שממשיכים לשלב 2, קבע את ה-Plan Scope של המשימה (`simple`/`standard`/`project`)
   > וודא שה-plan מכיל את הסעיפים הנדרשים לרמה הזו — ראה `<evidence_backed_planning>` למטה.

   > **Route Plan + Result Loop:** לכל software/project work, מלא גם את שדות ה-Route Plan
   > שמוגדרים ב-[`task-router.md`](./task-router.md): `selected_project_type`, `selected_template`,
   > `selected_roadmap`, `selected_result_loop_contract`, `required_user_simulation`,
   > `local_creator_review_path`, `telemetry_export_path`, ו-`evidence_redaction_rule`.
   > אם חסר template/roadmap/contract — אל תתקדם לקוד בלי waiver או known gap מפורש.
   > אם סוג הפרויקט חדש — עבור דרך [`scaling-extension-procedure.md`](../docs/operations/scaling-extension-procedure.md).

2. **חיפוש דוגמאות ואיסוף מידע** — משוך פתרון קיים ומקור אמין לפי `<information_sources>`
   (ראה [`connector-policy.md`](./connector-policy.md)): קודם `patterns/`/`templates/`,
   ואז **Context7** לתיעוד רשמי עדכני של הספריות/הגרסאות בהן תשתמש.
   **אם לאחר כל החיפושים אין כיסוי** — הפעל את נוהל הפער לפני כתיבה
   (ראה [`connector-policy.md`](./connector-policy.md) › `<pattern_gap>`).
   *כלי (Context7):* built-in ב-Claude app או Context7 MCP/CLI זמין.
   לבאגים: Sentry ראשון (ראה [`debugging-policy.md`](./debugging-policy.md) › `<debug_loop>`).
   *סקיל שיכול לסייע:* graphify (גרף כבר בנוי — שלוף תת-גרף רלוונטי).

   > **⚠️ חובה לפני כל `npm install` / `pip install`:** Context7 (built-in ב-app או Context7 MCP/CLI זמין).
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
   >     **ודוגמה** קונקרטית לעבוד מולה;
   > (ג) ה-Route Plan בחר result path: project type, template, roadmap, result-loop contract,
   >     user simulation, local creator review, telemetry export, and evidence redaction rule —
   >     או שהוא כולל waiver/known gap מפורש ומוצדק.
   > אם אחד מאלה חסר — אתה עדיין בשלב 1–3 (תכנון/איסוף), לא בכתיבה. כתיבה בלי מקור,
   > דוגמה, או מסלול תוצאה היא ניחוש ארכיטקטורה — בדיוק מה שעקרון-העל אוסר.

   > **debug_loop gate:** שגיאת קומפילציה, כשל CI, או runtime error בשלב זה → STOP.
   > (1) בדוק Sentry ראשון; (2) זהה root cause — אל תתקן תסמין; (3) הוסף regression test.
   > רק אז חזור לכתיבה. `post-commit` hook מזכיר learning_loop אחרי `fix:` commits.
   > ראה [`debugging-policy.md`](./debugging-policy.md) › `<debug_loop>`.

5. **כתיבה איטרטיבית** — שינויים קטנים בתוך ה-branch הפעיל.
   *סקיל שיכול לסייע:* `superpowers:test-driven-development`; `ui-ux-pro-max` לממשק (ראה [`external-skills/ui-ux-pro-max/`](../external-skills/ui-ux-pro-max/)).
6. **אימות תוצאה** — אל תסתפק ב-CI אם סוג הפרויקט דורש תוצאה נראית, runtime, או output artifact.
   אמת לפי ה-Route Plan וה-result-loop fields שנבחרו: בדיקות, user simulation, local creator review,
   visual/output evidence, monitoring/performance signal, change-impact comparison, and metadata-only telemetry export.
   CI מספיק רק כשסוג המשימה באמת אינו מייצר משטח תוצאה מעבר לבדיקות, או כשקיים waiver מפורש.
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

## <evidence_backed_planning>

> **מתי לגשת לסעיף הזה:** בסוף שלב 1 (אפיון ותכנון), לפני שממשיכים לשלב 2 — כדי לקבוע
> את **Plan Scope** של המשימה ואת רשימת הסעיפים שה-plan חייב להכיל בהתאם. גם
> `task-router.md` מפנה לכאן בעת בניית ה-Route Plan.

כל plan file (Notion או `.claude/plans/<name>.md`) חייב להצהיר **Plan Scope** מפורש —
שדה `Plan Scope: simple|standard|project` (או המקבילה בעברית: `סוג התוכנית: פשוט|רגיל|פרויקט`).
בלי הצהרה כזו, שער הכתיבה (`enforce-workflow.sh`) חוסם כתיבת קוד — ראה
[`hooks-policy.md`](./hooks-policy.md).

### Route Plan Result Loop Contract

לכל `standard` או `project` שעוסק ב-software/project work, ה-plan חייב לכלול את שדות
הניתוב הבאים לפני כתיבת קוד/קונפיג/בדיקות:

- `selected_project_type`
- `selected_template`
- `selected_roadmap`
- `selected_result_loop_contract`
- `required_user_simulation`
- `local_creator_review_path`
- `telemetry_export_path`
- `evidence_redaction_rule`

השדות האלה אינם מחליפים את Result Loop Contract המלא. הם מחייבים את המודל לבחור או לתעד
את המסלול לפני כתיבה. אם manifest/gate מלא עדיין לא קיים, כתוב `planned requirement` או
`known gap` מפורש — אל תטען שההתנהגות נאכפת במלואה. בדיקת ה-PR-level לשדות האלה נמצאת
ב-`scripts/enforcement/check-route-plan-contract.py`; gate מלא ל-contracts/manifests עדיין
נשאר בפריטי audit נפרדים.

### שלושת ה-Plan Scopes

**1. `simple`** — משימה טריוויאלית: תיקון typo, שינוי שם משתנה, הוספת שורת לוג, עדכון
תיעוד מקומי — כל שינוי שניתן לתאר את ה-diff שלו במשפט אחד. **סעיפים נדרשים:**
Goal/מטרה, Plan/תכנון, DoD/תנאי-סיום, Alternatives/חלופות (ארבעת הסעיפים הבסיסיים,
ללא תוספת).

**2. `standard`** — רוב המשימות: feature, bug fix לא-טריוויאלי, שינוי ב-API/DB/UI קיים,
אינטגרציה עם שירות קיים. **סעיפים נדרשים (בנוסף לארבעת הבסיסיים):**
- **Affected Surfaces / משטחים מושפעים** — אילו קבצים/מודולים/endpoints משתנים.
- **Data/State Impact / השפעה על דאטה ומצב** — האם סכמה, מיגרציה, cache, state
  client-side משתנים.
- **Integration Impact / השפעה על אינטגרציות** — האם קונקטור/שירות חיצוני/webhook מושפע.
- **Validation Plan / תוכנית בדיקות** — איך תאמת שהפתרון עובד (בדיקות, לוגים, UI, API).
- **Open Questions / שאלות פתוחות** — מה עדיין לא ברור (כתוב "אין" אם באמת אין).

**3. `project`** — greenfield, פרויקט חדש, פיצ'ר-על שמשנה ארכיטקטורה, מוסיף surface
עצמאי חדש, או מכניס טכנולוגיה/פלטפורמה חדשה. **סעיפים נדרשים — "Minimum Planning
Contract" מלא (בנוסף לארבעת הבסיסיים):**
Project Type, User Goal, Target Users/Surfaces, Known Requirements, MVP Features,
Non-goals, Architecture, Stack, Data Model/State, Auth/Roles, Integrations/Connectors,
Environment/Deployment, Evidence Checked, Open Questions, Validation Plan,
**User Approval**.

> **הבהרה מכוונת:** רשימת ה-`project` היא רשימה עצמאית ומלאה בפני עצמה — היא **אינה**
> דורשת גם את חמשת השדות של `standard` תחת השם המדויק שלהם. ה-Architecture/Stack/Data
> Model/Integrations של `project` מכסים את אותו תוכן ברמת עומק גבוהה יותר. אכיפת שני
> הסטים במקביל הייתה רק כופה כפילות כותרות בלי ערך אכיפה נוסף.

### Evidence Pass — לפני Final Plan ברמת standard/project

לפני כתיבת Final Plan ברמת `standard` או `project`, עברו **Evidence Pass**: קראו/שלפו
בפועל את המקורות הרלוונטיים (`patterns/`/`templates` קיימים, Context7, קוד קיים דרך
graphify, Sentry לבאגים) **לפני** שמנסחים את הסעיפים הארכיטקטוניים. אל תמלאו
Architecture/Stack/Data Model מניחוש או מזיכרון — זה בדיוק מה שעקרון "לאמת, לא לנחש"
אוסר. תעדו מה נבדק תחת **Evidence Checked** (project) או בציטוט המקור ליד הסעיף
הרלוונטי (standard).

### מתי לשאול את המשתמש לעומת מתי לחקור לבד

- **חקרו לבד** כשהתשובה נגישה ב-repo/תיעוד/Context7/graphify — אל תשאלו שאלה שיש לה
  תשובה דטרמיניסטית בקוד או בתיעוד.
- **שאלו שאלה ממוקדת אחת** כש: (א) יש **בחירה בין חלופות שוות-ערך** מבחינת המידע
  שברשותכם (ענן/DB/auth/hosting — ראה [`connector-policy.md`](./connector-policy.md));
  (ב) יש **אי-בהירות בדרישה עצמה** (לא רק בפרטי מימוש); או (ג) חסר **template/architecture
  guide** למשימת `project` (ראה [`task-router.md`](./task-router.md) › Greenfield).
- אל תשאלו כדי להימנע מחיפוש — קודם חפשו בפועל; רק אם אחרי חיפוש אמיתי עדיין יש פער,
  שאלו.

### User Approval ל-`project`

> **⚠️ כלל בל-יעבור (judgment, לא רק מכני):** ל-plan ברמת `project` **אסור** להתחיל
> יישום (שלב 5 ואילך ב-`<workflow>`) לפני שסעיף **User Approval** מסומן במפורש ע"י
> המשתמש (למשל "מאושר" / "Approved" בתגובת צ'אט, מצוטט בסעיף עם תאריך). זה **בנוסף**
> לאישור-מיזוג (שלב 11) — כאן האישור הוא **על התוכנית עצמה**, לפני שנכתבת שורת קוד
> אחת. אם אין אישור — מותר לערוך את קובץ ה-plan בלבד, לא לכתוב קוד.
>
> **הבהרת אכיפה:** `enforce-workflow.sh` בודק רק **שהכותרת `User Approval`/`אישור
> משתמש` קיימת** בסעיף (בהתאם לעקרון 6-ז — נוכחות שדה, לא איכות תוכן). מילוי placeholder
> תחת הכותרת ("pending"/"TBD") **יעבור מכנית** את הגייט הדטרמיניסטי. האכיפה בפועל של
> "אין אישור אמיתי = אין קוד" היא **כלל שיפוט על קלוד** — לא רק מנגנון אוטומטי.

</evidence_backed_planning>

---

## <onboarding>

### 0. Prerequisites (חובה לפני שלב 1)

לפני שמתחילים לעבוד עם Engineering OS בפרויקט חדש, ודא שכל הכלים והחיבורים הנדרשים קיימים לפי `connector-policy.md`, `skill-orchestration-policy.md`, ו-`external-skills/<skill>/activation.md`.

**כלים נדרשים:**
- `uv` — מנהל חבילות Python (נדרש לgraphify).
- `node` / `npm` — נדרש לrtk ולסקילים נוספים.
- `git` — ברמה 2.x לפחות.

**הגדרת environment מקומית** — צור קובץ environment מקומי שאינו נשלח ל-git, עם שמות המשתנים הנדרשים לקונקטורים ולסקילים.

אמת חיבורי MCP דרך `/mcp` בתוך Claude Code לפני שממשיכים.
אמת התקנת `superpowers` דרך `/plugin list` כאשר הוא נדרש.

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
- `.gitignore` — לכל הפחות: environment מקומי, תיקיות build/dist, תלויות (`node_modules` וכו'),
  קבצי IDE, לוגים.
- `.env.example` — שמות כל המשתנים עם ערכי דמה (ראה
  [`connector-policy.md`](./connector-policy.md) › `<environment>`).
- `.editorconfig` — כללי עריכה אחידים (קידוד, indent, סוף שורה).
- `lessons-learned/` ו-`failed-solutions/` — תיקיות ללולאת הלמידה.
- **שכבת hooks בסיסית** — אכיפה דטרמיניסטית של הכללים הבלתי-עבירים (ראה
  [`hooks-policy.md`](./hooks-policy.md) › `<hooks>`): pre-commit שמריץ lint+טסטים,
  חסימת `--no-verify`, חסימת כתיבה לנתיבים מוגנים, וסריקת ערכים אסורים.
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

לסוג שאינו ברשימה — אל תוסיף אותו כמסלול חד-פעמי. פתח את נתיב ההרחבה לפי
[`docs/operations/scaling-extension-procedure.md`](../docs/operations/scaling-extension-procedure.md): template או waiver,
roadmap entry, result-loop requirement, official sources, fixtures, telemetry export, and audit linkage.

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
