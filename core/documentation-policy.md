# documentation-policy.md — נוהל תיעוד

> חלק מ-Engineering OS. **מסמך ייחוס — נטען לפי הצורך.**
>
> **מתי לגשת לקובץ הזה:**
> - כשכותבים או מעדכנים `README.md` או תיעוד אחר.
> - כשיש חפיפה בין כמה קבצי Markdown ולא ברור מי מקור האמת.
> - בהקמת פרויקט — להגדרת קבצי התיעוד הנדרשים.
> - כשמוסיפים רכיב / חבילה / סקיל / תבנית — לוודא שיש לו README.

---

## <canonical_ownership>

Every durable governance idea has one canonical owner. Other files may link to that owner, but must not duplicate or redefine the rule.

| Area | Canonical owner |
|---|---|
| Always-loaded entrypoint | `CLAUDE.md` |
| Workflow order | `core/workflow.md` |
| Task routing | `core/task-router.md` |
| Documentation ownership and lifecycle | `core/documentation-policy.md` |
| Capability vocabulary | `core/capability-registry.yaml` |
| Connector policy and fallback | `core/connector-policy.md` |
| Skill orchestration policy | `core/skill-orchestration-policy.md` |
| External systems inventory | `external-systems/README.md` |
| External skills inventory | `external-skills/README.md` |
| Temporary route plans | `.claude/plans/*` |
| Operational runbooks | `docs/operations/*` |
| Reusable templates | `templates/*` |

Boundary rules:

1. `CLAUDE.md` stays a slim entrypoint and points to canonical owners.
2. Inventory README files list what exists and where it lives; they do not own global workflow rules.
3. Connector-specific or skill-specific files describe one component only. Cross-component rules belong in `core/`.
4. `.claude/plans/*` is temporary PR/task evidence, not durable documentation.
5. New governance concepts should add or update a regression test when deterministic enforcement is possible.

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
  [`skill-orchestration-policy.md`](./skill-orchestration-policy.md) › `<skill_structure>`).

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

</documentation>
