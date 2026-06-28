# documentation-policy.md — נוהל תיעוד ובעלות קנונית

> חלק מ-Engineering OS. **מסמך ייחוס — נטען לפי הצורך.**
>
> **מתי לגשת לקובץ הזה:**
> - כשכותבים או מעדכנים `README.md` או תיעוד אחר.
> - כשיש חפיפה בין כמה קבצי Markdown ולא ברור מי מקור האמת.
> - בהקמת פרויקט — להגדרת קבצי התיעוד הנדרשים.
> - כשמוסיפים רכיב / חבילה / סקיל / תבנית — לוודא שיש לו README ותפקיד מוגדר.

---

## <canonical_ownership>

**עיקרון:** לכל מושג יש בעלים קנוני אחד. קובץ יכול להפנות למקור האמת, אבל לא לשכפל אותו ולא להמציא גרסה חלקית שלו. אם לא ברור איפה כלל שייך — ברירת המחדל היא `core/`, לא README אינדקסי ולא plan זמני.

| מושג / שאלה | בעלים קנוני | מה לא שייך לשם |
|---|---|---|
| נקודת כניסה ומה תמיד נטען | `CLAUDE.md` | פירוט מלא של נהלים או שכפול policy |
| סדר העבודה הכללי | `core/workflow.md` | החלטות ספציפיות של PR בודד |
| ניתוב משימה לשכבות ידע | `core/task-router.md` | מלאי מפורט של כל כלי או שירות |
| איפה כותבים תיעוד ומה lifecycle שלו | `core/documentation-policy.md` | תיעוד ספציפי של שירות / סקיל |
| vocabulary של יכולות, evidence ו-task classes | `core/capability-registry.yaml` | README תיאורי או דוגמת שימוש |
| מדיניות קונקטורים, מקורות אמת ו-fallback | `core/connector-policy.md` | מדריך setup של קונקטור מסוים |
| מדיניות סקילים ו-SIP | `core/skill-orchestration-policy.md` | טבלת inventory של הסקילים |
| מלאי שירותים וקונקטורים | `external-systems/README.md` | חובה, evidence, validators, או workflow גלובלי |
| חוזה קונקטור מסוים | `external-systems/connectors/<name>/README.md` | מדיניות כללית לכל הקונקטורים |
| מלאי סקילים וסיווג סטטוס | `external-skills/README.md` | מדיניות SIP מלאה או workflow גלובלי |
| חוזה סקיל מסוים | `external-skills/<name>/{README,integration,policy,activation}.md` | כללים גלובליים לכל הסקילים |
| runbook תפעולי חוזר | `docs/operations/*` | מקור אמת למדיניות; אם יש כלל — הפנה ל-`core/` |
| מדריכי ארכיטקטורה / reference docs | `docs/architecture-guides/*`, `docs/official-docs/*`, `docs/reference-repositories/*` | העתקות ארוכות של vendor docs או policy גלובלי |
| תבניות ונכסים לשימוש חוזר | `templates/*` | כלל נורמטיבי חדש; תבנית מממשת policy, לא מגדירה אותו |
| תכנון PR/משימה | `.claude/plans/*` | תיעוד קבוע. אחרי merge — למחוק או להעביר לקח תמציתי ל-`lessons-learned/` |

### כללי boundary נגד Markdown sprawl

1. `CLAUDE.md` נשאר entry point רזה: עיקרון + הפניה, לא policy משוכפל.
2. README אינדקסי (`external-systems/README.md`, `external-skills/README.md`, `templates/README.md`) מציג מה קיים ואיפה, לא מגדיר חובות execution.
3. מסמך ספציפי לקונקטור או סקיל מתאר שימוש באותו רכיב בלבד. כלל שחוצה רכיבים עובר ל-`core/`.
4. `docs/operations/*` נשאר runbook. אם הוא חוזר על policy, מחליפים את החזרה בקישור למקור הקנוני.
5. `.claude/plans/*` הוא ephemeral. כל plan מתעד החלטת עבודה זמנית ואינו מקור אמת לאחר merge.
6. כשיש שינוי שמוסיף מושג governance חדש, מוסיפים גם בדיקת ownership או מסבירים ב-PR למה אי אפשר לאכוף דטרמיניסטית.

</canonical_ownership>

---

## <documentation>

**עיקרון:** תיעוד מתעדכן **יחד עם הקוד, באותו קומיט** — לא אחריו ולא "אחר כך". קוד בלי
README שמסביר מה הוא ואיך מריצים אותו הוא חוב שמאט כל מי שייגע בו בהמשך (כולל קלוד עצמו
בסשן הבא).

### README של פרויקט — מבנה מינימלי

כל פרויקט חייב `README.md` בשורש עם, לכל הפחות:

- **מה זה** — משפט אחד על מטרת הפרויקט + סוג + stack עיקרי.
- **התקנה והרצה** — הפקודות המדויקות מ-clone עד הרצה מקומית.
- **פקודות עיקריות** — `test`, `lint`, `build`, `dev` (מה שרלוונטי).
- **משתני סביבה** — הפניה ל-`.env.example` (לא ערכים אמיתיים; ראה
  [`connector-policy.md`](./connector-policy.md) › `<environment>`).
- **מבנה תיקיות** — התיקיות המרכזיות ומה יש בכל אחת.
- **קישור לתיעוד מורחב** — אם קיים (architecture, ADRs, API docs).

### README של רכיב / חבילה / סקיל

כל תיקייה משמעותית מקבלת README נלווה שמסביר *מה יש בה ומתי להשתמש*:

- **`patterns/<domain>/`** — מבנה ה-pattern (Problem → Architecture → Implementation →
  Example → Common Mistakes → Security → Testing → Score).
- **`external-systems/<service>/`** — סקירת API, auth, אובייקטים מרכזיים, setup, מגבלות.
- **`external-skills/<skill>/`** — ארבעת קבצי ה-SIP (ראה
  [`skill-orchestration-policy.md`](./skill-orchestration-policy.md) › `<skill_structure>`), אלא אם הפריט מסומן במפורש כמנוע/מאיץ סמוך ולא כ-skill פעיל.

### מתי מעדכנים תיעוד

- **כל שינוי בהתנהגות חיצונית** (API, CLI, env, פקודות, התקנה) — עדכן את ה-README
  **באותו קומיט** של שינוי הקוד.
- **כל קובץ/תיקייה חדשים** שצריך הסבר כדי להבין — צרף README.
- **אל תשאיר `TBD`** — או שכותבים תוכן אמיתי, או שלא יוצרים את הקטע. קטע ריק מסמן
  שלמות מדומה.

### סגנון

- תמציתי ומכוון-פעולה. **דוגמת ריצה קונקרטית** עדיפה על תיאור מופשט.
- אנגלית לתיעוד קוד/`patterns`/`external-*`; עברית למדיניות `core/` (כמו בפרויקט הזה).
- diffs ודוגמאות קצרות, לא dumps ענקיים (עקבי עם [`CLAUDE.md`](../CLAUDE.md) › `<communication>`).

### חיבור לאיכות

תיעוד עדכני הוא חלק מ-Definition of Done (ראה [`quality-gates.md`](./quality-gates.md) ›
`<definition_of_done>`): משימה שמשנה התנהגות חיצונית ולא עדכנה תיעוד — אינה גמורה.

> **אכיפה דטרמיניסטית** (`scripts/enforcement/enforce-documentation.sh`, נקרא מ-`pre-commit`):
> D1 — קומיט שנוגע ב-`patterns/<domain>/` או `external-systems/<service>/` נחסם אם אין שם `README.md`
> (`EOS_BYPASS_DOCREADME=1`). D2 — חובה `README.md` בשורש הריפו (`EOS_BYPASS_ROOTREADME=1`).
> D3 — placeholder עצמאי בקובצי `.md` ב-staged (`TBD`/`FIXME`/`XXX`/`???` לבד או ככותרת/ערך) נחסם
> (`EOS_BYPASS_TBD=1`); אזכור באמצע משפט אינו נחסם. master: `EOS_BYPASS_DOC=1`. ולידציה index-based.
> `scripts/enforcement/tests/test-documentation-ownership.sh` מכסה את גבולות הבעלות כדי למנוע חזרת כפילויות.

</documentation>
