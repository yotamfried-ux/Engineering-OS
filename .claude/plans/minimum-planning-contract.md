# Enforce evidence-backed planning contract

Plan Scope: standard

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | policy, workflow, governance |
| Target paths | core/workflow.md, core/task-router.md, scripts/enforcement/enforce-workflow.sh, scripts/enforcement/enforce-bash-entry.sh, scripts/enforcement/tests/test-workflow.sh, scripts/enforcement/tests/test-learning-reuse.sh, scripts/enforcement/tests/test-operational-learning-skills.sh |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | none |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, plan-policy, pr-policy |

## מטרה

חיזוק שער יצירת תוכנית העבודה (`enforce-workflow.sh` + `enforce-bash-entry.sh`) כך
שתוכנית חלשה מדי (רק Goal/Plan/DoD/Alternatives) לא תוכל לעבור עבור greenfield /
project scaffold / architecture change / major feature. הוספת Plan Scope
(simple/standard/project) עם סעיפים נדרשים מדורגים, Evidence Pass, ו-User Approval
מפורש לפני יישום ב-scope `project` — אכוף בעקביות בכל נקודת הכניסה (Write/Edit
וגם Bash).

## תכנון

1. עדכון `core/workflow.md` — סעיף `<evidence_backed_planning>` חדש.
2. עדכון `core/task-router.md` — Route Plan מורחב + כלל greenfield.
3. עדכון `scripts/enforcement/enforce-workflow.sh` — `detect_plan_scope()` +
   `plan_missing_sections()` scope-aware.
4. עדכון `scripts/enforcement/tests/test-workflow.sh` — fixtures + 8 טסטים חדשים.
5. הרצת טסטים ממוקדים, self-review diff, קומיט, פתיחת PR.
6. תגובת ביקורת (CodeRabbit + Codex): תיקון `enforce-bash-entry.sh` (אותה חולשה
   הייתה קיימת שם — שער נפרד לפקודות Bash לא ידע על Plan Scope), עיגון
   `detect_plan_scope` לערך אחרי ה-label (לא סריקת שורה שלמה), הבהרת ניסוח
   User Approval, והוספת טסט לכותרת עברית "סוג התוכנית".
7. תיקון 2 fixtures קיימים (`test-learning-reuse.sh`, `test-operational-learning-skills.sh`)
   ששברו ברגע שהשדה הפך לחובה.

## Affected Surfaces

`core/workflow.md`, `core/task-router.md`, `scripts/enforcement/enforce-workflow.sh`,
`scripts/enforcement/enforce-bash-entry.sh`, `scripts/enforcement/tests/test-workflow.sh`,
`scripts/enforcement/tests/test-learning-reuse.sh`,
`scripts/enforcement/tests/test-operational-learning-skills.sh`. אין שינוי בקבצים אחרים.

## Data/State Impact

אין. שינוי לוגי/תיעודי בלבד בשכבת האכיפה והמדיניות; אין סכמה/מיגרציה/state
client-side.

## Integration Impact

אין קונקטור/שירות חיצוני חדש. אין שינוי בחיווט hooks (`.claude/settings.json`
לא שונה) — רק בלוגיקה הפנימית של `enforce-workflow.sh`/`enforce-bash-entry.sh`
שכבר מחווטים.

## DoD

- [x] `core/workflow.md` כולל `<evidence_backed_planning>` עם שלושת ה-Plan Scopes,
      Evidence Pass, כלל שאלות-למשתמש, וכלל User Approval (עם הבהרת אכיפה מכנית).
- [x] `core/task-router.md` — Route Plan כולל Plan Scope/Planning Mode/Evidence
      to check/User decisions required + כלל greenfield.
- [x] `enforce-workflow.sh` חוסם plan ללא Plan Scope תקף, ואוכף סעיפים לפי scope,
      עם `detect_plan_scope` מעוגן לערך אחרי ה-label.
- [x] `enforce-bash-entry.sh` אוכף את אותו חוזה scope-aware — פקודות Bash
      work-like לא יכולות לעקוף את השער.
- [x] כל הגייטים הקיימים (G1, G3, G4, G6a, G6b, G7, G8, G9a, G9b, G12,
      Context7, tasks.json) עדיין עוברים ללא רגרסיה.
- [x] 8 הטסטים החדשים ב-`test-workflow.sh` עוברים, כולל טסט עברית לכותרת עצמה
      ("סוג התוכנית: פרויקט") וטסט לכותרות עבריות ל-Minimum Planning Contract.
- [x] `bash scripts/enforcement/tests/test-workflow.sh` — 0 נכשלים (64/64).
- [x] מעבר מלא על כל `scripts/enforcement/tests/test-*.sh` — 0 נכשלים (כולל
      תיקון 2 fixtures ששברו).
- [x] `bash scripts/enforcement/check-workflow-evidence.sh` עובר.
- [x] `bash scripts/enforcement/tests/test-capability-registry.sh` עובר.

## Validation Plan

`bash scripts/enforcement/tests/test-workflow.sh` (64/64 עברו), מעבר מלא על כל
`scripts/enforcement/tests/test-*.sh` (0 נכשלים), `bash
scripts/enforcement/check-workflow-evidence.sh` (עבר), `bash
scripts/enforcement/tests/test-capability-registry.sh` (עבר), `git status
--short` לאישור שרק הקבצים המיועדים שונו.

## Open Questions

אין — כל ההחלטות (מיקום הסעיף, project כרשימה עצמאית, תיקוני regex ל-אימות/State,
עיגון detect_plan_scope לערך אחרי label) תועדו במפורש ואושרו ע"י המשתמש/נבדקו מול
ביקורת קוד (CodeRabbit + Codex) בפועל.

## חלופות

- להשאיר את הבדיקה הקיימת (4 כותרות בלבד) — נדחה: זו בדיוק הבעיה שהמשימה נועדה לפתור.
- לדרוש מ-`project` גם את חמשת שדות ה-`standard` תחת השם המדויק שלהם — נדחה: כפילות
  כותרות בלי ערך אכיפה נוסף.
- לדרוש ניתוח סמנטי עמוק של תוכן הסעיפים (לא רק נוכחות) — נדחה במפורש לפי הנחיית
  המשתמש: המטרה לוודא שהשדות קיימים, לא לשפוט את איכות ההחלטה.
- להשאיר את `detect_plan_scope` עם סריקת שורה שלמה (ללא עיגון ל-label) — נדחה אחרי
  ביקורת CodeRabbit: יוצר false positive על placeholder לא-ממולא ועל טקסט הסבר
  שחולק שורה עם הערך האמיתי.

## Capability Evidence

- `routing.task-router-read` — נקרא `core/task-router.md` במלואו לפני התכנון (ראה Source of Truth Checks).
- `workflow.workflow-read` — נקרא `core/workflow.md` במלואו לפני התכנון.
- `plan.route-plan-before-write` — plan זה נכתב ונבדק לפני הקומיט הראשון שנוגע בקוד (ראה Progress Lifecycle Evidence › start).
- `source.github-repo-read` — הריפו נקרא מקומית (Read/Grep) ונבדק דרך GitHub PR checks/logs בפועל (`mcp__github__get_job_logs`, `mcp__github__pull_request_read`) על PR #191.
- `validation.policy-change-has-validator` — שינוי ב-`scripts/enforcement/` מלווה בעדכון הבדיקות התואמות (`test-workflow.sh` + 2 fixtures) ובהרצתן בפועל.
- `validation.coderabbit-policy` — CodeRabbit רץ בפועל על PR #191 (Run ID `81529f82-8151-417c-9549-932364485803`), הממצאים שלו (unanchored detect_plan_scope, enforce-bash-entry.sh bypass, User Approval wording, missing Hebrew test) טופלו בקומיט המתקן.

## Documentation Asset Evidence

- internal: `core/workflow.md`, `core/task-router.md`, `scripts/enforcement/enforce-workflow.sh`, `scripts/enforcement/tests/test-workflow.sh`, `scripts/enforcement/MANIFEST.tsv`, `docs/operations/claude-run-trace.md`, `docs/operations/merge-readiness-checklist.md`, `core/capability-registry.yaml`.
- context7: not required — this change only edits internal Engineering OS markdown policy and bash enforcement scripts; no external library, framework, SDK, or service is integrated, so no Context7 lookup applies.
- decision: reading `docs/operations/claude-run-trace.md` and `docs/operations/merge-readiness-checklist.md` directly shaped this plan's Claude Run Trace, Progress Lifecycle Evidence, and the PR body's Merge Readiness section format; reading `core/capability-registry.yaml`'s `engineering_os_governance` task class decided the exact Capability Evidence IDs listed above.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/workflow.md | checked |
| core/task-router.md | checked |
| scripts/enforcement/enforce-workflow.sh | checked |
| scripts/enforcement/enforce-bash-entry.sh | checked |
| scripts/enforcement/tests/test-workflow.sh | checked |
| docs/operations/claude-run-trace.md | checked |
| scripts/enforcement/MANIFEST.tsv | checked |

## Claude Run Trace

- **Goal:** לחזק את שער התכנון כך ש-project-scope לא יעבור עם plan כללי מדי,
  ולדרוש Evidence Pass + User Approval מפורשים לפני יישום — אכוף בעקביות בכל
  נקודת כניסה (Write/Edit וגם Bash).
- **Hypothesis:** הרחבת `plan_missing_sections()` ל-scope-aware, בתוספת שדה
  חדש `Plan Scope`, תיסגר את הפער בלי לשבור אף גייט קיים; ביקורת קוד אמיתית
  (CodeRabbit/Codex) תחשוף פערי כיסוי (כמו `enforce-bash-entry.sh`) שלא נראו
  מראש.
- **Tools/Connectors used:** Read/Edit/Write על הקבצים המשתנים, Bash להרצת
  טסטים, Plan subagent (Agent tool) לעיצוב ה-regex לפני המימוש, GitHub MCP
  (`create_pull_request`, `get_job_logs`, `pull_request_read`,
  `add_issue_comment`) לניהול PR #191 ולאבחון כשלי CI בפועל.
- **Steps:** (1) קריאת `core/workflow.md`, `core/task-router.md`,
  `enforce-workflow.sh`, `test-workflow.sh`, `MANIFEST.tsv` בפוקוס; (2) עיצוב
  הפתרון דרך Plan agent; (3) יישום; (4) הרצת טסטים; (5) פתיחת PR; (6) איתור
  ותיקון פערים שנחשפו ב-CI (עצם ה-plan file לא היה מחויב ל-git, gate בסדר
  קומיטים, ותיקוני ביקורת קוד); (7) self-review + commit + push.
- **Evidence collected:** 64/64 טסטים ב-`test-workflow.sh`, 0 נכשלים במעבר מלא
  על כל `scripts/enforcement/tests/test-*.sh`, לוגים אמיתיים מ-GitHub Actions
  runs על PR #191 (CheckRunIDs מתועדים בתגובת ה-PR).
- **Rejected attempts:** (א) לדרוש איחוד שדות standard+project תחת אותו plan —
  נדחה כדי למנוע כפילות ללא ערך אכיפה; (ב) `Auth/Roles` עם `אימות` הגולמי כפי
  שהוצע בדוגמה המקורית — נדחה כי יוצר false-positive collision עם Validation
  Plan; (ג) `detect_plan_scope` עם סריקת שורה שלמה ללא עיגון — נדחה אחרי ביקורת
  CodeRabbit שהראתה false positive על placeholder לא-ממולא.
- **Result:** כל הקבצים עודכנו, כל הבדיקות עוברות, ממצאי ביקורת קוד אמיתיים
  טופלו, ואין רגרסיה בגייטים קיימים.
- **Follow-up enforcement/documentation:** אין gap נוסף שדורש תיעוד לימוד נפרד;
  הסעיף `<evidence_backed_planning>` עצמו הוא התיעוד/המדיניות שהמשימה נועדה
  להוסיף.

## Progress Lifecycle Evidence

- start: plan זה (עם Minimum Planning Contract, Capability Evidence, ו-
  Documentation Asset Evidence) נכתב ונבדק לפני שנוגע קוד כלשהו מ-`core/workflow.md`
  או `enforce-workflow.sh`.
- mid: after implementing detect_plan_scope/plan_missing_sections scope-awareness
  in enforce-workflow.sh (Write/Edit path) and enforce-bash-entry.sh (Bash path),
  ran the full scripts/enforcement/tests/test-*.sh sweep and found + fixed 2 broken
  fixtures (test-learning-reuse.sh, test-operational-learning-skills.sh) that built
  ad hoc plan fixtures without a Plan Scope field.
- pre-merge: final validation before requesting merge — full local
  scripts/enforcement/tests/test-*.sh sweep is 0 failures, test-workflow.sh is
  64/64, bash scripts/enforcement/check-workflow-evidence.sh passes, and
  CodeRabbit/Codex review findings on PR #191 (unanchored detect_plan_scope,
  enforce-bash-entry.sh scope bypass, overstated User Approval wording, missing
  Hebrew Plan Scope label test) are all addressed in this branch.
