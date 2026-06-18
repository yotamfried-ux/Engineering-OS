# Post-Mortem: PR #32 — Engineering OS Workflow Bypass

**תאריך:** 2026-06-18
**חומרה:** High — Engineering OS לא יישם על עצמו את ה-workflow שהוא אמור לאכוף
**זמן גילוי:** 2026-06-18 (תחקור PR לפני merge)

---

## מה קרה

ענף `claude/pr-32-status-review-lwljte` (PR #32) צבר 39 commits, 302 קבצים, +32,347 שורות — ללא plan file, tasks.json, Notion spec, spec_loop verification, או תיעוד learning-loop. במקביל, CLAUDE.md קוצר מ-722 שורות (גרסת main הישנה) ל-296 שורות (גרסה מעודכנת), אך project_context נשאר כ-template ריק.

## ניתוח שורש (6 שכבות)

| שכבה | בעיה |
|------|------|
| 0 | CLAUDE.md project_context לא מולא — AI לא יודע שהוא עובד על Engineering OS עצמו |
| 1 | `validate-workflow-state.sh` מחריג `.md` — Engineering OS הוא Markdown, כל הפרויקט עקף אכיפה |
| 2 | Git hooks לא מותקנים ב-`.git/hooks/` — `use-in-project.sh` מסרב לרוץ בתוך Engineering-OS |
| 3 | `<project_context>` ריק, `.claude/plans/` לא קיים בסשנים קודמים |
| 4 | Session task ("review PR #32") הורגש דחוף יותר מהוראות ה-workflow |
| 5 | Pre-commit חוסם ב-commit-time; כתיבה ללא plan לא נחסמת בזמן אמת |

## מה תוקן

1. **project_context מולא** ב-CLAUDE.md
2. **Meta-Rule נוסף** לתחילת `<core_principles>` — workflow גובר על כל session task
3. **Critical dirs enforcement** ב-`validate-workflow-state.sh` — חוסם כתיבה ל-`core/`, `patterns/`, `external-skills/`, `templates/`, `scripts/hooks/` ללא plan
4. **L2 Brainstorm check** — plan file חייב להכיל סעיף Brainstorming לפני כתיבה לנתיבים קריטיים
5. **`scripts/install-self-hooks.sh`** — מתקין git hooks ב-Engineering-OS עצמו
6. **`scripts/setup.sh`** — bootstrapping חד-פעמי אחרי clone
7. **הגנת מחיקת CLAUDE.md** ב-`pre-commit.sh`
8. **`core/maintenance-routine.md`** — נוהל תחזוקה שוטפת

## לקחים

- **Engineering OS חייב להיות לקוח של עצמו.** כל שינוי בו חייב לעבור את אותו workflow שהוא מגדיר לפרויקטים אחרים.
- **אכיפה פיזית (exit 1) > הנחיות טקסט.** כלל שאינו נאכף בקוד אינו כלל — הוא המלצה.
- **CLAUDE.md הוא ה-entry point.** מחיקה או ריקון שלו שקולים להשבתת כל מערכת ה-workflow.
