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

2. **חלץ domain tags** — בחר תגיות שמתארות את המשימה בפועל:
   - `ui`, `api`, `auth`, `database`, `payments`, `notifications`, `files`, `ai-agent`, `mcp`, `mobile`, `testing`, `security`, `observability`, `background-jobs`, `billing`, `workflow`, `governance`

3. **אסוף שכבות ידע לפי הסדר המחייב**
   1. `templates/` — האם יש template מתאים?
   2. `docs/architecture-guides/` — האם יש guide לדומיין?
   3. `patterns/` — אילו patterns נדרשים?
   4. `external-systems/` — אילו services / platforms / libraries ה-OS ממליץ עבור הדומיין?
   5. `external-skills/` — אילו skills חייבים לרוץ על סוג המשימה הזה?
   6. `core/*` — אילו policies מיוחדות רלוונטיות (debugging, git, quality gates, learning loop)?

4. **הפק Route Plan קצר לפני כתיבה**
   - `Task type:`
   - `Domain tags:`
   - `Template(s) to consult:`
   - `Architecture guide(s):`
   - `Pattern(s):`
   - `External system / connector decisions:`
   - `Skills to run:`
   - `Validation gates:`

5. **אם חסר רכיב חובה — אל תמשיך בשקט**
   - חסר template / architecture guide לפרויקט חדש או החלטה ארכיטקטונית → עצור לפי `CLAUDE.template.md` / `workflow.md`
   - חסר pattern → השתמש באנלוגי הקרוב ביותר ותעד את הפער
   - חסר skill LEVEL 2 → דווח על gap והצע bootstrap / התקנה

</routing_algorithm>

---

## <routing_matrix>

### 1) Greenfield scaffold / project bootstrap

**Always consult:**
- `templates/` — template לפרויקט
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
- אין architecture guide מתאים → עצור. אל תקבל החלטת מבנה מה-training data.

### 2) Bug / debugging

**Always consult:**
- `core/debugging-policy.md`
- `docs/troubleshooting/`
- `lessons-learned/`
- patterns / guides של הדומיין שבו הבאג נמצא

**Connectors / systems:**
- Sentry קודם, אם יש אינטגרציה
- אחר כך logs / tests / local repro

**Skills:**
- `superpowers` (systematic debugging)
- `security-review` אם הבאג נוגע ל-auth / secrets / permissions / data exposure

### 3) UI / frontend / UX work

**Always consult:**
- `docs/ui-ux/`
- `patterns/ui/README.md`
- `patterns/auth/README.md` אם יש login / session / protected UI
- `patterns/testing/README.md`

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

**External systems:**
- `external-systems/openai/`, `external-systems/langgraph/`, `external-systems/mcp-sdk/` וכו' לפי המשימה

**Skills:**
- `superpowers`
- `graphify`
- `security-review` אם יש tool access / secrets / external side effects

### 6) Infra / CI / deployment / observability

**Always consult:**
- `patterns/infrastructure/README.md`
- `patterns/observability/README.md`
- `patterns/security/README.md`
- `patterns/testing/README.md`
- רלוונטי: `core/hooks-policy.md`, `core/git-policy.md`, `core/quality-gates.md`

**Skills:**
- `security-review`
- `superpowers`

### 7) Engineering OS maintenance / governance

**Always consult:**
- `CLAUDE.md`
- `core/workflow.md`
- `core/skill-orchestration-policy.md`
- `core/connector-policy.md`
- `core/learning-loop.md`
- `core/hooks-policy.md`

**Extra rule:**
- שינוי ב-OS חייב לחזק את שכבת ההכרעה/האכיפה, לא רק להוסיף עוד טקסט הסברי.

</routing_matrix>

---

## <required_output>

לפני כל משימה לא-טריוויאלית, החזר לעצמך (או למשתמש אם רלוונטי) Route Plan קצר בפורמט:

```md
Task type: <...>
Domain tags: <...>
Templates: <...>
Architecture guides: <...>
Patterns: <...>
External systems / connectors: <...>
Skills: <...>
Validation gates: <...>
```

המטרה אינה verbosity — אלא **להוכיח שהניתוב בוצע** לפני כתיבה.

</required_output>
