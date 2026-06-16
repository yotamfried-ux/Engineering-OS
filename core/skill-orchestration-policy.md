# skill-orchestration-policy.md — פרוטוקול אינטגרציית סקילים (SIP)

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - **לפני כל משימה** — להעריך אילו סקילים חיצוניים רלוונטיים, באיזו רמת חובה, ובאיזה סדר.
> - לפני הוספת סקיל/פלאגין/MCP/ריפו חיצוני חדש למערכת — דרך שכבת ההתאמה האחידה.
> - כשמקימים פרויקט חדש — להריץ את נוהל ה-bootstrap שמוודא שהסקילים קיימים.
> - כששני סקילים רלוונטיים לאותה משימה ולא ברור מי רץ ראשון.
>
> הקובץ הזה הופך את Engineering OS מ-**מערכת ידע** ל-**Skill Orchestration Framework**:
> שכבת אינטליגנציה שמחליטה *איך* משתמשים ביכולות חיצוניות, *מתי*, ו*באיזה סדר*.

---

## <skill_integration_protocol>

**הגדרה:** כל יכולת חיצונית — ריפו, skill, plugin, MCP server, מערכת agents — נכנסת
ל-OS **רק** דרך שכבת התאמה אחידה. אין "להדביק כלי" ישירות.

```
Skill = External Capability + Integration Contract + Execution Rules
```

- **External Capability** — מה הכלי באמת עושה (מאומת מול הריפו עצמו, לא מהשערה).
- **Integration Contract** — מתי משתמשים, מתי אסור, ואיך הוא משפיע על ה-workflow.
- **Execution Rules** — סיווג, רמת חובה, וסדר הרצה ביחס לסקילים אחרים.

עקרון-העל של הקובץ נשען על **"לאמת, לא לנחש"**: לפני שכותבים wrapper לסקיל, **סורקים
את הריפו האמיתי** (מבנה, מניפסטים, פקודות/כלים אמיתיים) ולא מסתמכים על תיאור שיווקי.
תיאור שגוי של כלי = החלטות תזמור שגויות.

</skill_integration_protocol>

---

## <skill_structure>

כל סקיל מקבל תיקייה תחת [`../external-skills/`](../external-skills/):

```
external-skills/<skill-name>/
├── README.md        # כרטיס זהות: מה זה, מה הוא מספק, install summary, רישיון
├── integration.md   # החוזה ההתנהגותי: מה עושה / מתי / מתי אסור / השפעה על ה-workflow / הכלים האמיתיים
├── policy.md        # מטא-תזמור: סיווג + רמת חובה + כללי קומפוזיציה + הערות אבטחה
└── activation.md    # התקנה + אימות נוכחות + secrets + הסרה
```

ארבעת הקבצים אינם כפילות זה של זה — לכל אחד תפקיד נפרד:

| קובץ | עונה על השאלה |
|---|---|
| `README.md` | *מה זה הכלי?* — זהות, מבנה אמיתי, התקנה בקצרה |
| `integration.md` | *איך ומתי משתמשים?* — החוזה ההתנהגותי + הכלים/הפקודות האמיתיים שמפעילים |
| `policy.md` | *איך הוא משתלב בתזמור?* — סיווג, רמה, קומפוזיציה, override |
| `activation.md` | *איך מתקינים ומוודאים שהוא קיים?* — פקודות מדויקות + אימות + secrets |

</skill_structure>

---

## <classification>

כל סקיל מקבל **תגיות סוג** (`type`). הסיווג הוא מה שמאפשר אוטומציה — התאמת סקיל
למשימה לפי סוג, לא לפי זיכרון.

```
type:
  - planning              # תכנון, אפיון, פירוק משימה
  - coding                # מימוש
  - ui-ux                 # עיצוב ממשק
  - review                # סקירת קוד/עיצוב
  - security              # אבטחה — תמיד גוברת (ראה <override_rule>)
  - memory                # זיכרון/המשכיות הקשר בין סשנים
  - orchestration         # תזמור, סימולציית תפקידים, ניהול pipeline
  - context-optimization  # צמצום עלות קונטקסט (חיפוש סלקטיבי במקום קריאת קבצים)
```

סקיל יכול לשאת כמה תגיות (למשל gstack הוא `orchestration` + `planning` + `review` +
`security`). הסיווג נקבע ב-`policy.md` של הסקיל ומסוכם ב-[`../external-skills/README.md`](../external-skills/README.md).

</classification>

---

## <execution_levels>

לכל סקיל **רמת חובה** שמונעת כאוס — מתי הוא רץ אוטומטית ומתי זו בחירה:

| רמה | משמעות |
|---|---|
| **LEVEL 0 — optional** | קלוד מחליט אם להפעיל לפי שיקול דעת. |
| **LEVEL 1 — recommended** | ברירת מחדל פעילה, אלא אם יש סיבה מפורשת לוותר. |
| **LEVEL 2 — mandatory** | חובה — תמיד רץ כשתנאי ההפעלה שלו מתקיימים. |

### הבהרה קריטית — "mandatory" מותנה בזמינות ובטריגר

LEVEL 2 **אינו** אומר "רוץ בכל משימה ללא קשר". הוא אומר:

> **חובה כש (א) תנאי הטריגר של הסקיל מתקיימים, ו-(ב) הסקיל מותקן בפרויקט.**

- אם תנאי הטריגר לא מתקיימים (למשל security-review על משימת תיעוד גרידא) — הוא לא רץ.
- אם הסקיל **לא מותקן** — זו אינה עילה לדלג בשקט. נוהל ה-[`<bootstrap>`](#bootstrap)
  חייב להציף את החֶסֶר ולהציע התקנה. סקיל LEVEL 2 חסר = פער שמדווחים עליו, לא
  מתעלמים ממנו.

כך נפתר המתח בין "חובה תמיד" לבין מציאות שבה כלי חיצוני עלול להיעדר.

</execution_levels>

---

## <default_activation>

**שני צירים נפרדים** — אל תבלבל ביניהם:

- **רמת הרצה (Execution Level)** — *מתי הסקיל רץ על משימה נתונה* (LEVEL 0/1/2 למעלה).
- **ברירת מחדל פר-פרויקט (Default install)** — *האם ה-bootstrap מתקין אותו בכל פרויקט*.

הטבלה למטה עונה ישירות על "אילו סקילים פעילים כברירת מחדל בכל פרויקט, ואם לא — למה":

| סקיל | ברירת מחדל פר-פרויקט | נימוק |
|---|---|---|
| **superpowers** | ✅ **כן, בכל פרויקט** | מתודולוגיה שמונעת את כשל ה-#1 (קפיצה לקוד בלי spec). ה-SessionStart hook טוען אותה תמיד; *עומק* התהליך מתכוונן לפי מורכבות המשימה, אבל הנוכחות קבועה. |
| **security-review** | ✅ **כן, בכל פרויקט שמגיע לפרודקשן** | אבטחה היא baseline, לא תוספת. diff-aware ולכן זול להריץ. רץ לפני כל קומיט בברנץ' (אזהרה מוקדמת) **ושער חובה לפני מיזוג ל-main**. |
| **graphify** | ✅ **כן, בכל פרויקט, תמיד** | חוסך עלות קונטקסט בכל סשן. **L2 חובה** — בונים גרף בתחילת כל סשן ללא יוצא מן הכלל. אם הריפו זעיר, Graphify עצמו יתריע — זו תגובת הכלי, לא תנאי לדילוג. אין הדרה קבועה, אין "אחר כך". |
| **claude-mem** | ✅ **כן, כשהסביבה מאפשרת** | המשכיות הקשר בין סשנים מועילה כמעט לכל פרויקט רב-סשני. opt-out רק בסביבה נעולה/חולפת, או כשאסור לשמור נתונים לדיסק. |
| **frontend-design** | ⚠️ **מותנה — רק לפרויקט עם UI** | מיותר ב-backend טהור / CLI / library. מותקן כשיש משטח UI (web/mobile). |
| **claude-code-workflows** | ⚠️ **מומלץ כשיש review מבוסס-PR** | מספק subagents + GitHub Actions ל-PR review. ערך מלא רק בזרימת PR. |
| **gstack** | ➖ **לא ברירת מחדל — opt-in** | כבד (Bun + 59 SKILL.md), משטח גדול של סימולציית-תפקידים שחופף ל-superpowers/security/review. ערך עיקרי לפרויקטים מורכבים רב-תפקידיים או למייסד-יחיד שרוצה תפקידים מובנים. בוחרים אותו במודע, לא בברירת מחדל. |

**פרופיל ברירת המחדל** (מה ש-`scripts/skill-bootstrap.sh` מצפה למצוא בפרויקט סטנדרטי):
superpowers · security-review · graphify · claude-mem. הסקריפט מסמן את אלה כ-`default`,
את frontend-design/claude-code-workflows כ-`conditional`, ואת gstack כ-`opt-in`.

</default_activation>

---

## <selection_rule>

**לפני ביצוע משימה, קלוד חייב להעריך את הסקילים הזמינים.** זו אינה המלצה — זו דרישת
פתיחה, באותה רמה כמו איסוף המידע ב-[`workflow.md`](./workflow.md) › `<workflow>`.

### Execution Pipeline

```
1. Detect task type      → איזה סוג משימה? (planning / coding / ui / review / security / debug …)
2. Match by classification → אילו סקילים נושאים תגית שמתאימה לסוג המשימה?
3. Select by level       → LEVEL 2 שתנאיו מתקיימים = חובה; LEVEL 1 = ברירת מחדל; LEVEL 0 = שיקול דעת
4. Order by composition   → סדר ההרצה לפי <composition>
5. Execute in order      → הפעלה; אם סקיל חסר → <bootstrap>
```

</selection_rule>

---

## <composition>

כשכמה סקילים רלוונטיים לאותה משימה, הם רצים ב-**pipeline** קבוע. הסדר אינו שרירותי —
הוא משקף את סדר העבודה ההנדסי הנכון:

```
┌─ context-optimization ─┐   (graphify) — בונה/מרענן גרף קוד; רץ ראשון, חוצה-שלבים
│                        │
│   memory layer         │   (claude-mem) — משחזר הקשר ב-SessionStart, מסכם ב-Stop; פסיבי, מתחת לכל ה-pipeline
│                        │
│   1. planning   ───────┤   (superpowers brainstorm/plan, gstack /autoplan /plan-*) — לפני קוד
│   2. coding     ───────┤   (frontend-design ל-UI, superpowers TDD) — מימוש
│   3. SECURITY GATE ────┤   (security-review, gstack /cso) — חוסם לפני פרודקשן; לא ניתן לעקיפה
│   4. review     ───────┘   (claude-code-workflows, gstack /review, superpowers receiving-code-review) — אחרון
└────────────────────────┘
```

### שלושת כללי הקומפוזיציה

1. **Planning first** — סקילי תכנון רצים לפני סקילי קוד. אסור "לקפוץ לקוד".
2. **Security always overrides** — סקיל אבטחה הוא שער חוסם; שום סקיל אחר לא דוחק אותו
   הצידה ולא מקצר אותו (ראה [`<override_rule>`](#override_rule)).
3. **Review runs last** — סקילי סקירה רצים בסוף, אחרי קוד ואחרי שער האבטחה.

שכבת ה-context-optimization (graphify) רצה **ראשונה וכחוצת-שלבים**: בונים/מרעננים את
גרף הקוד בתחילת העבודה, ואז שולפים תת-גרף רלוונטי במקום לקרוא קבצים שלמים — זה מוזיל
קונטקסט לאורך כל ה-pipeline. שכבת ה-memory (claude-mem) רצה **מתחת** לכל ה-pipeline
כמערכת פסיבית בגבולות הסשן.

</composition>

---

## <override_rule>

```
No skill can override a security-level skill.
```

- שער אבטחה (`type: security`, למשל security-review או `/cso` של gstack) **חייב לעבור**
  לפני מיזוג ל-main או פריסה לפרודקשן.
- אסור לסקיל אחר — ולא ללחץ "לסיים מהר" — לעקוף, לקצר, או לדחות את שער האבטחה.
- כלל זה הוא הרחבה ישירה של היררכיית ה-[`precedence.md`](./precedence.md): דרגה 1
  (אל תגרום נזק בלתי-הפיך/משותף בלי אישור) ודרגה 3 (אל תעקוף אכיפה דטרמיניסטית).
  אבטחה אינה "סקיל אחד מני רבים" — היא שכבת-על.

</override_rule>

---

## <bootstrap>

**נוהל שמוודא שהסקילים קיימים בכל פרויקט — ואם לא, מציף ומציע לחבר.**

המנגנון: הסקריפט [`../scripts/skill-bootstrap.sh`](../scripts/skill-bootstrap.sh).
הוא **מזהה ומדווח** (ברירת מחדל) או **מתקין לפי בקשה מפורשת** (`--install`).

### למה זיהוי-ודיווח ולא התקנה אוטומטית

התקנת כלים חיצוניים היא פעולה שמשנה סביבה וקשה להפיך (gstack מריץ `./setup`,
claude-mem מרים worker ופורט 37777, graphify דורש uv). לפי [`git-policy.md`](./git-policy.md)
› `<safety>`, פעולות כאלה דורשות אישור. לכן ברירת המחדל היא:

```
1. סרוק כל סקיל ב-external-skills/ → קרא את ה-activation.md שלו
2. בדוק נוכחות לפי בדיקת ה-"Verify presence" של הסקיל (plugin / CLI / MCP / קובץ)
3. דווח: ✅ מותקן  |  ⚠️ חסר (LEVEL <n>)  |  ➖ לא רלוונטי
4. עבור כל סקיל חסר ברמה LEVEL 1/2 — הצג את פקודת ההתקנה המדויקת מ-activation.md
5. התקן רק עם --install ואישור מפורש של המשתמש
```

### מתי מריצים את ה-bootstrap

- **בהקמת פרויקט חדש** — שלב מחייב ב-[`workflow.md`](./workflow.md) › `<project_scaffold>`.
- **בתחילת עבודה על פרויקט קיים** (onboarding) — לוודא שאין פער בין הנדרש למותקן.
- כש-`<selection_rule>` בוחר סקיל LEVEL 2 שמתברר כחסר.

</bootstrap>

---

## <skill_registry>

האינדקס המלא של הסקילים — סיווג, רמה, ושיטת התקנה — מוחזק ב-
[`../external-skills/README.md`](../external-skills/README.md). תקציר:

| Skill | type | Level | ברירת מחדל | מנגנון |
|---|---|---|---|---|
| [superpowers](../external-skills/superpowers/) | planning, review, orchestration | **L2** (עומק לפי מורכבות) | ✅ כל פרויקט | Claude Code plugin |
| [security-review](../external-skills/security-review/) | security, review | **L2** לפני קומיט + שער לפני main | ✅ כל פרויקט (פרודקשן) | GitHub Action + `/security-review` |
| [graphify](../external-skills/graphify/) | context-optimization | **L2** | ✅ כל פרויקט (בונים גרף תמיד; Graphify עצמו יתריע אם ריפו זעיר) | `uv tool install` + MCP |
| [claude-mem](../external-skills/claude-mem/) | memory, context-persistence | **L2** (פסיבי) | ✅ כשהסביבה מאפשרת | plugin + MCP + hooks + worker |
| [frontend-design](../external-skills/frontend-design/) | ui-ux, coding | **L2** ל-UI / L1 אחרת | ⚠️ מותנה (UI) | skill ב-plugin marketplace |
| [claude-code-workflows](../external-skills/claude-code-workflows/) | review, orchestration | L1 / **L2** לריפקטור גדול | ⚠️ מותנה (PR review) | העתקת קבצים ידנית |
| [gstack](../external-skills/gstack/) | orchestration, role-simulation | L1 | ➖ opt-in | git clone + `./setup` |

נימוקי ברירת המחדל: ראה [`<default_activation>`](#default_activation).
ערכי MCP של graphify ו-claude-mem מתועדים גם ב-[`mcp-servers.md`](./mcp-servers.md).

</skill_registry>

---

## <integration_procedure>

**נוהל הוספת סקיל חדש למערכת** — כל יכולת חיצונית נכנסת דרך אותם שבעה צעדים, אף פעם
לא "מודבקת" ישירות:

```
1. סרוק את הריפו האמיתי   — מבנה, מניפסטים, פקודות/כלים אמיתיים (לא תיאור שיווקי)
2. צור external-skills/<skill-name>/ עם ארבעת קבצי החוזה (README/integration/policy/activation)
3. הקצֵה type tags + Execution Level + ברירת-מחדל ב-policy.md
4. הוסף שורה ל-registry (כאן וב-external-skills/README.md)
5. הוסף בדיקת זיהוי ל-scripts/skill-bootstrap.sh (ואת פרופיל ברירת המחדל)
6. אם זה שרת MCP — רשום גם ב-mcp-servers.md
7. אם זו יכולת משמעותית — הוסף ל-CLAUDE.md ניווט
```

הצעד הראשון (סריקה אמיתית) הוא בלתי-עביר: הוא היישום של "לאמת, לא לנחש" על סקילים.
דוגמה למה זה חשוב — בסריקה התגלה ש-claude-code-workflows אינו "5 סוכנים מקבילים" כפי
שמתואר ברשת, אלא ריפו תבניות עם 2 subagents; ה-wrapper מתעד את המבנה האמיתי.

הנוהל המלא עם הסבר לכל צעד: [`../external-skills/README.md`](../external-skills/README.md)
› *Adding a new skill*.

</integration_procedure>

---

## חיבור לשאר המערכת

- **workflow** — שלב הערכת הסקילים נכנס לפתיחת כל משימה ([`workflow.md`](./workflow.md)).
- **precedence** — שער האבטחה נשען על היררכיית ההכרעה ([`precedence.md`](./precedence.md)).
- **patterns** — סקילי קוד (frontend-design) משלימים את ספריות ה-`patterns/` (למשל `patterns/ui/`).
- **hooks** — סקילים שמביאים hooks משלהם (superpowers SessionStart, claude-mem lifecycle)
  מתועדים ב-activation.md שלהם; אין להחליף בהם את ה-hooks הדטרמיניסטיים של המערכת
  ([`hooks-policy.md`](./hooks-policy.md)).
