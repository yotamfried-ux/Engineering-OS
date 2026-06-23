# code-reviewer — Comprehensive AI Code Review Agent

סוכן שסורק ריפו מקצה לקצה ומייצר דוח מלא של כל הבעיות.  
**מטרה:** לתפוס 90%+ מהבעיות בסריקה אחת — מתחביר ועד ארכיטקטורה.

---

## דרישות

```bash
pip install requests pyyaml
```

**API key** (either variable name is accepted):
```bash
export NVIDIA_API_KEY=nvapi-...
```

> **הערה לסביבת Claude Code on the web:** הסוכן צריך גישה ל-`integrate.api.nvidia.com`.  
> בסביבת cloud של Claude Code, הוסף את ה-host ל-[network egress settings](https://code.claude.com/docs/en/claude-code-on-the-web).  
> להרצה מקומית — אין הגבלה.

---

## שימוש

```bash
# סריקה בסיסית
python3 code_reviewer.py --repo /path/to/project

# עם output מוגדר
python3 code_reviewer.py --repo /path/to/project --output ~/reports

# חידוש סריקה שנקטעה
python3 code_reviewer.py --repo /path/to/project --output ~/reports --resume

# בדיקה מהירה (5 קבצים בלבד)
python3 code_reviewer.py --repo /path/to/project --max-files 5 --skip-structure

# הוספת extensions
python3 code_reviewer.py --repo /path/to/project --include-ext .vue .svelte
```

---

## 4 הפאזות

| פאזה | מה קורה | מודל |
|------|----------|-------|
| 1. Context | קורא README, docs, package.json → מסכם | fast model |
| 2. Structure | מפה את עץ הקבצים → מזהה תפקיד כל קובץ | fast model |
| 3. Deep Review | עובר קובץ-קובץ, שורה-שורה → מאתר בעיות | main model |
| 4. Report | מאגד, ממיין לפי severity → markdown | — |

---

## קטגוריות בעיות

| קטגוריה | תיאור |
|----------|--------|
| `SYNTAX` | תחביר שגוי, import חסר, typo במזהה |
| `LOGIC_BUG` | לוגיקה שגויה, off-by-one, תנאי הפוך |
| `SILENT_FAILURE` | קוד שרץ אבל מחזיר תוצאה שגויה בשקט |
| `SECURITY` | injection, auth bypass, חשיפת secrets |
| `ARCHITECTURE` | שכבה לא נכונה, coupling הדוק, הפרת SRP |
| `PERFORMANCE` | N+1 queries, blocking I/O, memory leak |
| `ERROR_HANDLING` | exception בלוע, נתיב שגיאה חסר |
| `AI_SMELL` | קוד שנראה נכון אבל לוגיקתו שגויה (AI pattern) |
| `INCOMPLETE` | TODO שנשאר, feature חצי-מיושם |

---

## תזמון לילי (cron)

```bash
# ערוך crontab
crontab -e

# כל לילה ב-02:00
0 2 * * * NVIDIA_API_KEY=nvapi-... python3 /path/to/code_reviewer.py \
  --repo /path/to/project \
  --output /path/to/reports \
  >> /var/log/code-review.log 2>&1
```

---

## פורמט הדוח

```
reports/
└── myproject_20250623_020000/
    ├── report.md           ← הדוח הראשי (human-readable)
    ├── issues.json         ← כל הבעיות כ-JSON (לעיבוד נוסף)
    ├── context_summary.txt ← סיכום הפרויקט שנבנה בפאזה 1
    └── progress.json       ← קובץ התקדמות (לחידוש סריקה)
```

---

## Flags

| Flag | תיאור | ברירת מחדל |
|------|--------|-------------|
| `--repo` | נתיב לריפו | נדרש |
| `--output` | ספריית הפלט | `./reports` |
| `--model` | מודל Nvidia לסריקה | `nemotron-super-49b` |
| `--fast-model` | מודל לפאזות context/structure | `nemotron-nano-8b` |
| `--resume` | המשך סריקה שנקטעה | `false` |
| `--skip-structure` | דלג על זיהוי תפקידי קבצים | `false` |
| `--max-files` | הגבל מספר קבצים (לבדיקה) | `0` (ללא הגבלה) |
| `--include-ext` | הוסף extensions לסריקה | — |
| `--exclude-dir` | ספריות נוספות לדילוג | — |
