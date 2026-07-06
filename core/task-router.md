# task-router.md — משימתוב → בחירת תבניות / patterns / skills / connectors

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - בתחילת **כל** משימה, לפני תכנון מפורט ולפני כתיבת קוד.
> - כשצריך להחליט **אילו** templates / patterns / external-skills / connectors רלוונטיים.
> - כשיש כמה כלים אפשריים לאותה משימה וצריך בחירה עקבית במקום הסתמכות על זיכרון.
>
> המטרה של הקובץ הזה היא להפוך את Engineering OS מ"אוסף ידע" ל-**decision engine**:
> המשימה מנותבת באופן דטרמיניסטי לשכבות הרלוונטיות, במקום לקוות שה-LLM יזכור לבד.
> למשימות software/project work, הניתוב כולל גם בחירת project type, roadmap, Result Loop
> Contract, וסימולציית משתמש נדרשת — כדי שהמודל יהיה מחויב למסלול תוצאה ולא רק למציאת מסמכים.

---

## <routing_algorithm>

לפני כל משימה, הפעל את האלגוריתם הבא **בסדר הזה**:

1. **סווג את סוג המשימה**
   - bug / debugging
   - greenfield scaffold
   - feature implementation
   - refactor / architecture change
   - UI / design / frontend flow
   - backend / API / auth / DB / payments
   - AI / agents / MCP / automation
   - mobile
   - infra / CI / deployment / observability
   - docs / governance / Engineering OS maintenance

2. **בחר `selected_project_type` לכל software/project work**
   - השתמש ב-project type קיים מתוך `docs/operations/project-type-roadmaps.md` או template קיים.
   - אם סוג הפרויקט חדש — אל תמציא מסלול חד-פעמי. הפעל את `docs/operations/scaling-extension-procedure.md` ורשום זאת ב-Route Plan.
   - שינוי governance של Engineering OS עצמו יכול להשתמש ב-waiver מפורש, אבל target-project work חייב לבחור סוג פרויקט ממשי.

3. **בחר Task class מתוך `core/capability-registry.yaml`**
   - אם יש task class מתאים — השתמש בשם שלו במפורש ב-Route Plan.
   - אם אין task class מתאים — רשום `Task class: unclassified` והוסף `Capability Waiver` עם נימוק.
   - אל תבחר capability לפי זיכרון; ה-registry הוא מקור האמת.

4. **חלץ domain tags** — בחר תגיות שמתארות את המשימה בפועל:
   - `ui`, `api`, `auth`, `database`, `payments`, `notifications`, `files`, `ai-agent`, `mcp`, `mobile`, `testing`, `security`, `observability`, `background-jobs`, `billing`, `workflow`, `governance`

5. **אסוף שכבות ידע לפי הסדר המחייב**
   1. `templates/` — האם יש template מתאים? רשום `selected_template`.
   2. `docs/operations/project-type-roadmaps.md` — האם יש roadmap entry מתאים? רשום `selected_roadmap`.
   3. `docs/operations/result-loop-contract-plan.md` או manifest קיים — האם יש Result Loop Contract מתאים? רשום `selected_result_loop_contract`.
   4. `docs/architecture-guides/` — האם יש guide לדומיין?
   5. `patterns/` — אילו patterns נדרשים?
   6. `external-systems/` — אילו services / platforms / libraries ה-OS ממליץ עבור הדומיין?
   7. `external-skills/` — אילו skills חייבים לרוץ על סוג המשימה הזה?
   8. `core/*` — אילו policies מיוחדות רלוונטיות (debugging, git, quality gates, learning loop)?

6. **הפק Route Plan קצר לפני כתיבה**
   - `Task type:`
   - `Task class:` — מתוך `core/capability-registry.yaml` או `unclassified` + waiver
   - `Domain tags:`
   - `selected_project_type:`
   - `selected_template:`
   - `selected_roadmap:`
   - `selected_result_loop_contract:`
   - `required_user_simulation:`
   - `local_creator_review_path:`
   - `telemetry_export_path:`
   - `evidence_redaction_rule:`
   - `Template(s) to consult:`
   - `Architecture guide(s):`
   - `Pattern(s):`
   - `External system / connector decisions:`
   - `Skills to run:`
   - `Validation gates:`
   - `Capability Evidence:` — capability IDs שנבחרו + evidence/waiver

7. **אם חסר רכיב חובה — אל תמשיך בשקט**
   - חסר template / architecture guide לפרויקט חדש או החלטה ארכיטקטונית → עצור לפי `CLAUDE.template.md` / `workflow.md`.
   - חסר roadmap / Result Loop Contract / template לסוג פרויקט קיים → אל תתקדם לקוד בלי `known gap` או `waiver` מפורש ב-Route Plan.
   - סוג פרויקט חדש → חייב לעבור דרך `docs/operations/scaling-extension-procedure.md` לפני קוד.
   - חסר pattern → השתמש באנלוגי הקרוב ביותר ותעד את הפער.
   - חסר skill LEVEL 2 → דווח על gap והצע bootstrap / התקנה.
   - capability לא רלוונטי למרות שהוא מופיע ב-registry → רשום `Capability Waiver` עם נימוק.

</routing_algorithm>

---

## <routing_matrix>

### 1) Greenfield scaffold / project bootstrap

**Always consult:**
- `templates/` — template לפרויקט
- `docs/operations/project-type-roadmaps.md` — roadmap entry לסוג הפרויקט
- `docs/operations/result-loop-contract-plan.md` — Result Loop Contract או planned requirement/gap עד שה-manifest נאכף
- `docs/operations/scaling-extension-procedure.md` — חובה אם סוג הפרויקט חדש
- `docs/architecture-guides/` — guide לדומיין
- `patterns/testing/README.md`
- `patterns/security/README.md`
- `core/workflow.md`
- `core/quality-gates.md`

**Skills:**
- `superpowers` — חובה
- `graphify` — חובה
- `security-review` — חובה לפרויקטים production-bound
- `ui-ux-pro-max` — חובה אם יש UI surface

**If missing:**
- אין template מתאים → עצור. אל תסקפלד מהזיכרון.
- אין roadmap או Result Loop Contract מתאים → רשום waiver/known gap לפני קוד; אל תטען שיש enforcement מלא.
- אין architecture guide מתאים → עצור. אל תקבל החלטת מבנה מה-training data.

**Plan Scope:**
- Greenfield הוא **תמיד** `Plan Scope: project`. Route Plan קצר (השדות למעלה) **אינו
  מספיק** בשלב זה — חובה **Final Plan** מלא לפי ה-Minimum Planning Contract
  (ראה [`workflow.md`](./workflow.md) › `<evidence_backed_planning>`), כולל **User
  Approval** מפורש, לפני תחילת יישום.
- אם חסר template מתאים או architecture guide לדומיין — אל תנחשו מבנה. תעדו את הפער
  במפורש תחת `User decisions required` ב-Route Plan **וגם** תחת Open Questions ב-Final
  Plan, והסלימו למשתמש לקבלת החלטה מפורשת (בחירת template קרוב + עדכון, או ארכיטקטורה
  חדשה) לפני שממשיכים.

### 2) Bug / debugging

**Always consult:**
- `core/debugging-policy.md`
- `docs/troubleshooting/`
- `lessons-learned/`
- patterns / guides של הדומיין שבו הבאג נמצא
- roadmap/result-loop fields אם התיקון משנה התנהגות משתמש, runtime, performance, או output artifact

**Connectors / systems:**
- Sentry קודם, אם יש אינטגרציה
- אחר כך logs / tests / local repro

**Skills:**
- `superpowers` (systematic debugging)
- `security-review` אם הבאג נוגע ל-auth / permissions / data exposure

### 3) UI / frontend / UX work

**Always consult:**
- `docs/ui-ux/`
- `patterns/ui/README.md`
- `patterns/auth/README.md` אם יש login / session / protected UI
- `patterns/testing/README.md`
- roadmap/result-loop fields שמגדירים user simulation, visual evidence, local creator review, telemetry, and redaction

**Skills:**
- `ui-ux-pro-max` — LEVEL 2 למשימות UI
- `superpowers`
- `security-review` אם יש auth / PII / payments

### 4) Backend / API / auth / DB / payments

**Always consult:**
- `patterns/api/README.md`
- `patterns/auth/README.md` / `patterns/authorization/README.md`
- `patterns/database/README.md`
- `patterns/billing/README.md` אם יש payments
- `patterns/security/README.md`
- guide ארכיטקטורה מתאים ב-`docs/architecture-guides/`
- roadmap/result-loop fields שמגדירים health/integration tests, monitoring, performance thresholds, and telemetry export

**External systems:**
- חפש קודם `external-systems/` לשירותים כמו auth, DB, payments, email

**Skills:**
- `superpowers`
- `security-review` — חובה

### 5) AI / agents / MCP / automation

**Always consult:**
- `patterns/ai/README.md`
- `patterns/ai-agents/README.md`
- `docs/architecture-guides/ai/`
- `docs/architecture-guides/mcp/README.md`
- `core/mcp-servers.md`
- roadmap/result-loop fields שמגדירים eval set, trace/eval artifacts, latency/cost/error metrics, repair loop, and telemetry export

**External systems:**
- `external-systems/openai/`, `external-systems/langgraph/`, `external-systems/mcp-sdk/` וכו' לפי המשימה

**Skills:**
- `superpowers`
- `graphify`
- `security-review` אם יש tool access / external side effects

### 6) Infra / CI / deployment / observability

**Always consult:**
- `patterns/infrastructure/README.md`
- `patterns/observability/README.md`
- `patterns/security/README.md`
- `patterns/testing/README.md`
- רלוונטי: `core/hooks-policy.md`, `core/git-policy.md`, `core/quality-gates.md`
- roadmap/result-loop fields אם השינוי משפיע על monitoring, telemetry export, CI artifacts, or runtime evidence

**Skills:**
- `security-review`
- `superpowers`

### 7) Engineering OS maintenance / governance

**Always consult:**
- `CLAUDE.md`
- `core/workflow.md`
- `core/task-router.md`
- `core/skill-orchestration-policy.md`
- `core/connector-policy.md`
- `core/learning-loop.md`
- `core/hooks-policy.md`
- `docs/operations/result-loop-contract-plan.md` ו-`docs/operations/scaling-extension-procedure.md` כאשר שינוי governance נוגע ל-result loops או scaling

**Extra rule:**
- שינוי ב-OS חייב לחזק את שכבת ההכרעה/האכיפה, לא רק להוסיף עוד טקסט הסברי.

</routing_matrix>

---

## <required_output>

לפני כל משימה לא-טריוויאלית, החזר לעצמך (או למשתמש אם רלוונטי) Route Plan קצר בפורמט:

```md
Task type: <...>
Task class: <task class from core/capability-registry.yaml, or unclassified + waiver>
Domain tags: <...>
Plan Scope: <simple|standard|project>          # ראה workflow.md <evidence_backed_planning>
Planning Mode: <discovery|evidence-pass|final-for-approval|approved>
selected_project_type: <project type id, or explicit waiver for Engineering OS governance work>
selected_template: <templates/<id>, or waiver/known gap>
selected_roadmap: <docs/operations/project-type-roadmaps.md entry, or waiver/known gap>
selected_result_loop_contract: <contract/manifest row, or planned requirement/known gap until gate exists>
required_user_simulation: <required simulation path for this project type>
local_creator_review_path: <local URL/device/simulator/app/output path, or explicit non-UI reason>
telemetry_export_path: <metadata-only telemetry export path>
evidence_redaction_rule: <how sensitive evidence is redacted or excluded before export>
Templates: <...>
Architecture guides: <...>
Patterns: <...>
External systems / connectors: <...>
Skills: <...>
Validation gates: <...>
Evidence to check: <...>                        # מקורות ל-Evidence Pass: patterns/templates/Context7/graphify/Sentry
User decisions required: <...>                  # שאלות שדורשות תשובת משתמש, או "none"

## Capability Evidence

- `<capability-id>` — selected/checked evidence, or why it applies.
```

**Planning Mode — משמעות הערכים:**
- `discovery` — עדיין אוספים מידע; אין plan סופי.
- `evidence-pass` — המקורות נקראו בפועל (patterns/templates/Context7/graphify), עדיין לא final.
- `final-for-approval` — plan מלא לפי ה-Minimum Planning Contract לרמת ה-Scope; ממתין
  לאישור מפורש של המשתמש (**חובה** ל-`Plan Scope: project`).
- `approved` — המשתמש אישר במפורש; מותר להתחיל יישום (שלב 5 ב-`<workflow>`).

אם capability או task class אינו רלוונטי, השתמש ב-`## Capability Waiver` עם סיבה מפורשת.
המטרה אינה verbosity — אלא **להוכיח שהניתוב בוצע** לפני כתיבה.

</required_output>
