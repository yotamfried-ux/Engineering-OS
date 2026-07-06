# workflow.md — תהליך העבודה

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - בתחילת **כל** משימה — כדי לדעת מאיזה שלב מתחילים ומה הסדר.
> - כשמקימים פרויקט חדש (`<onboarding>`, `<project_scaffold>`).
> - לפני מיזוג ל-main — לסגירת `<spec_loop>`.
> - כשעולה צורך בריפקטור (`<refactor_loop>`).
> - כשרוצים להבין איך לנהל turns ו-state (`<agent_loop>`).

---

## <agent_loop>

אתה פועל בלולאה: מקבל הקשר ← מחליט ← קורא לכלים ← מקבל תוצאות ← חוזר, עד שאין עוד צורך בכלים.

- בצע קריאות כלי בלתי-תלויות במקביל; קריאות תלויות בצע ברצף.
- התקדם בצעדים קטנים ומדידים.
- עקוב אחר state דרך git ודרך קבצים מובנים כמו `.claude/tasks.json`.
- תעד run trace: כלים/קונקטורים ששימשו, turns, נקודות כשל, ותוצאות אימות.
- handoff ל-subagent מותר רק למשימה מבודדת; הוא מחזיר מטרה, ממצא/ביצוע, הוכחה, ופתוח שנותר.
- שמור state לפני compaction ונקה הקשר בין משימות לא קשורות.

> **אכיפה:** PreToolUse Agent hook חוסם spawn אם `.claude/tasks.json` לא קיים. צור אותו לפי `core/resource-management.md` לפני שמפעילים agents.

</agent_loop>

---

## <workflow>

כל משימה עוברת אותו pipeline. **לב התהליך:** מתכננים, אוספים מידע אמין, בוחרים route/result path, ורק כשמבינים את הדרישות והארכיטקטורה מתחילים לכתוב.

1. **אפיון ותכנון** — אפיין ותכנן ב-Notion או ב-`.claude/plans/<name>.md`: מטרה, דרישות, מערכות מושפעות, ותוכנית.

   > **Plan Scope:** לפני שלב 2, קבע `Plan Scope: simple|standard|project` וודא שה-plan מכיל את הסעיפים הנדרשים לפי `<evidence_backed_planning>`.

   > **Route Plan + Result Loop:** לכל software/project work, מלא את שדות ה-Route Plan שמוגדרים ב-[`task-router.md`](./task-router.md): `selected_project_type`, `selected_template`, `selected_roadmap`, `selected_result_loop_contract`, `required_user_simulation`, `local_creator_review_path`, `telemetry_export_path`, ו-`evidence_redaction_rule`. אם חסר template/roadmap/contract — אל תתקדם לקוד בלי waiver או known gap מפורש. אם סוג הפרויקט חדש — עבור דרך [`scaling-extension-procedure.md`](../docs/operations/scaling-extension-procedure.md).

2. **חיפוש דוגמאות ואיסוף מידע** — קודם `patterns/` ו-`templates/`, ואז תיעוד רשמי עדכני לפי `connector-policy.md`. לבאגים, בדוק מקור runtime מתאים לפני שינוי.

3. **בחירת כלים והערכת סקילים** — בחר קונקטורים ו-skills לפי המשימה, לא לפי זיכרון. LEVEL 2 חסר הוא gap שצריך להציף, לא לדלג עליו.

4. **תכנון יישום** — 3–5 צעדים קונקרטיים, לפני כתיבה.

   > **שער כניסה לכתיבה:** התחל לכתוב קוד רק כאשר:
   > (א) הדרישות והארכיטקטורה מובנות;
   > (ב) יש מקור אמין ודוגמה רלוונטית;
   > (ג) ה-Route Plan בחר result path: project type, template, roadmap, result-loop contract, user simulation, local creator review, telemetry export, and evidence redaction rule — או waiver/known gap מפורש.
   > אם אחד מאלה חסר, אתה עדיין בתכנון/איסוף מידע, לא בכתיבה.

   > **debug_loop gate:** שגיאת קומפילציה, כשל CI, או runtime error → STOP, זהה root cause מתוך בדיקות/לוגים/טרייסים, הוסף regression test, ורק אז חזור לכתיבה.

5. **כתיבה איטרטיבית** — שינויים קטנים בתוך ה-branch הפעיל.

6. **אימות תוצאה** — אל תסתפק ב-CI אם סוג הפרויקט דורש תוצאה נראית, runtime, או output artifact. אמת לפי ה-Route Plan וה-result-loop fields: בדיקות, user simulation, local creator review, visual/output evidence, monitoring/performance signal, change-impact comparison, and metadata-only telemetry export. CI מספיק רק כשסוג המשימה באמת אינו מייצר משטח תוצאה מעבר לבדיקות, או כשקיים waiver מפורש.

7. **ניקוי קוד** — ראה [`quality-gates.md`](./quality-gates.md) › `<cleanup>`.

8. **בדיקת קוד לפני קומיט** — ראה [`quality-gates.md`](./quality-gates.md) › `<pre_commit_review>`.

9. **קומיט מובנה** — ראה [`git-policy.md`](./git-policy.md) › `<commit_protocol>`.

10. **אימות מול האפיון** — ודא שהתוצר תואם למה שאופיין בשלב 1. סמן את כל DoD items לפני merge.

11. **מיזוג ל-main** — רק אחרי אימות מלא ואישור משתמש מפורש.

12. **תיעוד למידה** — אם נחשף לקח, ראה [`learning-loop.md`](./learning-loop.md).

> משימה טריוויאלית יכולה לדלג על אפיון מלא, אבל לא על אימות ולא על קומיט מתועד.

</workflow>

---

## <evidence_backed_planning>

> **מתי לגשת לסעיף הזה:** בסוף שלב 1, לפני שממשיכים לשלב 2. גם `task-router.md` מפנה לכאן בעת בניית Route Plan.

כל plan file חייב להצהיר `Plan Scope: simple|standard|project`. בלי הצהרה כזו, שער הכתיבה חוסם כתיבת קוד.

### Route Plan Result Loop Contract

לכל `standard` או `project` שעוסק ב-software/project work, ה-plan חייב לכלול לפני כתיבת קוד/קונפיג/בדיקות:

- `selected_project_type`
- `selected_template`
- `selected_roadmap`
- `selected_result_loop_contract`
- `required_user_simulation`
- `local_creator_review_path`
- `telemetry_export_path`
- `evidence_redaction_rule`

השדות האלה אינם Result Loop Contract מלא. הם מחייבים בחירה או waiver לפני כתיבה. אם manifest/gate מלא עדיין לא קיים, כתוב `planned requirement` או `known gap`; אל תטען שההתנהגות נאכפת במלואה. בדיקת ה-PR-level לשדות האלה נמצאת ב-`scripts/enforcement/check-route-plan-contract.py`; gate מלא ל-contracts/manifests נשאר בפריטי audit נפרדים.

### שלושת ה-Plan Scopes

**1. `simple`** — שינוי טריוויאלי. נדרש: Goal/מטרה, Plan/תכנון, DoD/תנאי-סיום, Alternatives/חלופות.

**2. `standard`** — feature, bug fix לא-טריוויאלי, שינוי ב-API/DB/UI קיים, או אינטגרציה עם שירות קיים. נדרש בנוסף: Affected Surfaces, Data/State Impact, Integration Impact, Validation Plan, Open Questions.

**3. `project`** — greenfield, פרויקט חדש, פיצ'ר-על שמשנה ארכיטקטורה, surface עצמאי חדש, או טכנולוגיה/פלטפורמה חדשה. נדרש Minimum Planning Contract מלא: Project Type, User Goal, Target Users/Surfaces, Known Requirements, MVP Features, Non-goals, Architecture, Stack, Data Model/State, Auth/Roles, Integrations/Connectors, Environment/Deployment, Evidence Checked, Open Questions, Validation Plan, User Approval.

> רשימת `project` היא רשימה עצמאית ומלאה בפני עצמה, ואינה דורשת גם את חמשת שדות `standard` בשמות המדויקים.

### Evidence Pass — לפני Final Plan ברמת standard/project

לפני Final Plan ברמת `standard` או `project`, קרא/שלוף בפועל את המקורות הרלוונטיים (`patterns/`, `templates/`, תיעוד רשמי, קוד קיים דרך graphify, ומקורות runtime לבאגים). אל תמלא Architecture/Stack/Data Model מניחוש.

### מתי לשאול את המשתמש לעומת מתי לחקור לבד

- חקור לבד כשהתשובה נגישה ב-repo/תיעוד/graphify.
- שאל שאלה ממוקדת אחת רק כשיש בחירה שוות-ערך, אי-בהירות בדרישה, או חסר template/architecture guide למשימת `project`.
- אל תשאל כדי להימנע מחיפוש.

### User Approval ל-`project`

ל-plan ברמת `project` אסור להתחיל יישום לפני שסעיף **User Approval** מסומן במפורש על ידי המשתמש. זה בנוסף לאישור merge.

> הבהרת אכיפה: `enforce-workflow.sh` בודק נוכחות כותרת `User Approval`/`אישור משתמש`; האיכות של האישור נשארת כלל שיפוט על קלוד.

</evidence_backed_planning>

---

## <onboarding>

לפני כתיבת קוד בפרויקט שאינך מכיר:

1. קרא את `CLAUDE.md` ואת קבצי ההגדרה המרכזיים.
2. אפיין ותכנן את המשימה לפי `<workflow>`.
3. הבן את הארכיטקטורה והספריות ומשוך תיעוד עדכני לפי `connector-policy.md`.
4. זהה שפה, ספריות, וקונקטורים שהפרויקט דורש.
5. אל תניח מבנה — בדוק בפועל איך הקוד מאורגן.
6. הרץ את bootstrap/verification של הסקילים הנדרשים ודווח על חסרים.

</onboarding>

---

## <project_scaffold>

כל פרויקט חדש מתחיל מתשתית קבועה: README, CLAUDE.md, ignore rules, environment example, editor config, lessons/failed-solutions, hooks בסיסיים, ו-CI בסיסי.

לסוגי פרויקט קיימים — העדף תבנית מאושרת מ-`templates/<type>/README.md`. לסוג שאינו ברשימה — אל תוסיף מסלול חד-פעמי; הפעל את [`docs/operations/scaling-extension-procedure.md`](../docs/operations/scaling-extension-procedure.md): template או waiver, roadmap entry, result-loop requirement, official sources, fixtures, telemetry export, and audit linkage.

### כלל עבודה

- העדף תבנית קיימת על פני בנייה מאפס.
- בזמן ההקמה אפיין אילו קבצים תלויי-פרויקט נדרשים.
- אם הפרויקט אמור לעבוד גם עם כלי AI אחרים, החזק הנחיות משותפות ב-`AGENTS.md` וייבא אותן במקום לשכפל.
- אפשר להשתמש ב-`.claude/rules/` לטעינת כללים לפי path.

</project_scaffold>

---

## <spec_loop>

**מתי:** נסגרת בשלב 10 ב-`<workflow>`, אחרי הקומיט ולפני המיזוג ל-main.

המטרה: לוודא שמה שנבנה תואם למה שאופיין — לא רק שהקוד עובד, אלא שהוא עושה את הדבר הנכון.

1. השווה את התוצר מול האפיון.
2. אם יש פער — סגור אותו, או עדכן את האפיון אם הפער מכוון ומוצדק.
3. סמן את המשימה כהושלמה רק כשהתוצר והאפיון תואמים.

</spec_loop>

---

## <refactor_loop>

**מתי:** לא שלב קבוע ב-`<workflow>`. רץ רק כשריפקטור הוא חלק מהמשימה שאופיינה או הכרחי לתיקון.

1. ודא שיש בדיקה שמכסה את ההתנהגות הקיימת לפני השינוי.
2. שנה בצעדים קטנים ושמור על אותה התנהגות חיצונית.
3. אמת אחרי כל צעד שהבדיקות עדיין עוברות.
4. אם ריפקטור גדול עולה תוך כדי משימה אחרת — הצף אותו כמשימה נפרדת.

</refactor_loop>
