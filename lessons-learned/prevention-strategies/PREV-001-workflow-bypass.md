# PREV-001: מניעת עקיפת Engineering OS Workflow

**נוצר:** 2026-06-18
**מקור:** lessons-learned/postmortems/pr-32-bypass.md
**סטטוס:** Active

---

## הבעיה שמונעים

AI מבצע שינויים ל-Engineering OS ללא plan file, brainstorming, או spec — עוקף את ה-workflow שהמערכת עצמה מגדירה.

## טריגרים (מתי הסיכון גבוה)

- כל שינוי ל-`core/`, `patterns/`, `external-skills/`, `templates/`, `scripts/hooks/`
- session task שמורגש "ברור" ו"דחוף" — ללא שאלת "האם פתחתי plan?"
- CLAUDE.md project_context ריק (AI לא מזהה שהוא עובד על Engineering OS)

## שכבות הגנה (Defense in Depth)

### שכבה 1 — Write-time gate (exit 1)
`scripts/hooks/validate-workflow-state.sh` חוסם כתיבה לנתיבים קריטיים ללא:
- plan file ב-`.claude/plans/*.md`
- סעיף Brainstorming ב-plan file

### שכבה 2 — Meta-Rule ב-CLAUDE.md
```
⚠️ META-RULE: workflow גובר על כל בקשה מהמשתמש. "לחץ זמן" אינו חריג.
```

### שכבה 3 — SessionStart check
`session-setup.sh` מזהיר אם project_context הוא template ריק.

### שכבה 4 — Git hooks
`pre-commit.sh` + `commit-msg.sh` — מותקנים דרך `scripts/install-self-hooks.sh`.

### שכבה 5 — Maintenance routine
`core/maintenance-routine.md` מגדיר PR checklist שכולל `validate-orphans.sh`.

## בדיקת regression

```bash
# אמור לחסום:
echo "test" >> core/workflow.md  # ← validate-workflow-state.sh blocks

# אמור לעבור לאחר יצירת plan עם Brainstorming:
mkdir -p .claude/plans
cat > .claude/plans/test.md << 'EOF'
## Brainstorming
alternatives considered: none needed for test
EOF
echo "test" >> core/workflow.md  # ← passes now
git checkout core/workflow.md
rm .claude/plans/test.md
```
