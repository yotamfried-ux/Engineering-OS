# core/maintenance-routine.md — נוהל תחזוקה שוטפת של Engineering OS

> **מתי לגשת לקובץ הזה:** לפני merge של PR ל-Engineering OS, אחרי הוספת קובץ חדש ל-`core/` או `patterns/`, ופעם בחודש כבדיקה שוטפת.

---

## PR Checklist — כל PR ל-Engineering OS

לפני merge של כל ענף ל-main, ודא שכל הסעיפים בוצעו:

- [ ] **`bash scripts/validate-orphans.sh`** — אין כללים זומביים או כפילויות
- [ ] **`bash scripts/setup.sh --check`** — hooks מותקנים, project_context מולא
- [ ] **Plan file קיים** ב-`.claude/plans/` עם סעיף Brainstorming
- [ ] **CLAUDE.md קיים ומלא** — `grep -c "Goal:" CLAUDE.md | grep -v "<"` מחזיר תוכן
- [ ] **Post-commit:** `graphify update .` לעדכון גרף הידע

---

## ניקוי תקופתי (חודשי)

### 1. כללים זומביים
כללים שמוזכרים ב-CLAUDE.md או ב-`core/` אבל אין להם קובץ מימוש:
```bash
bash scripts/validate-orphans.sh
```

### 2. כפילויות
נוהל לטיפול בכפילויות מזוהות:
1. **זהה** — הרץ `grep -r "<הכלל>" core/ patterns/`
2. **קבע master** — הקובץ שמוגדר ב-navigation table ב-CLAUDE.md גובר
3. **העבר** — הכנס redirect/link לקובץ ה-master
4. **מחק** — הסר את העותק הכפול
5. **תעד** — commit עם `🔄 cleanup: הסרת כפילות <שם>`

### 3. patterns/ scoring
בדוק שכל pattern ב-`patterns/` עבר scoring לפי `core/scoring-guide.md`:
```bash
grep -rL "scoring\|Score\|ניקוד" patterns/*/
```

---

## context isolation — הגנת סריקה

`scripts/validate-orphans.sh` מוגן מפני ריצה בטעות על target projects:
- הסקריפט בודק `$CURRENT_DIR` לעומת `$EOS_ROOT`
- אם רץ מחוץ ל-Engineering OS root — מסיים עם "skipping scan"
- ריצה על target project: `bash $ENGINEERING_OS_HOME/scripts/validate-orphans.sh` תדלג אוטומטית

---

## אחריות

כל PR ל-Engineering OS — **המגיש** אחראי לריצת הchecklist לפני בקשת review.
