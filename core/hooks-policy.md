# hooks-policy.md — אכיפה דטרמיניסטית (hooks)

> חלק מ-Engineering OS. נטען מתוך [`CLAUDE.md`](../CLAUDE.md).
>
> **מתי לגשת לקובץ הזה:**
> - בהקמת פרויקט — להגדרת שכבת ה-hooks הבסיסית (`<hooks>`).
> - כשכלל חייב לקרות **בכל פעם ללא יוצא מן הכלל** — ולא להישען על כך שקלוד יזכור.
> - כשרוצים לחסום פעולה מסוכנת ברמת הכלי (commit, push, כתיבה לנתיב מוגן).
> - כשרוצים להזריק עיקרון ברמת ה-system prompt (`<system_prompt_injection>`).

---

## <hooks>

הקבצים ב-`core/` הם **הקשר מנחה**, לא קונפיגורציה נאכפת. קלוד קורא אותם ומנסה לציית,
אבל אין ערובה לציות מלא — במיוחד תחת לחץ הקשר (context מתמלא) או כשהוראות מתנגשות.
לכלל שחייב להתקיים תמיד, טקסט אינו מספיק: צריך **hook**.

hook הוא סקריפט שרץ אוטומטית באירוע מחזור-חיים קבוע (לפני קריאת כלי, לפני קומיט,
בסיום turn) ופועל **ללא תלות במה שקלוד מחליט**. זו שכבת האכיפה; הטקסט ב-core מעצב
התנהגות אך אינו חוסם.

### אילו כללים חייבים להיות hook (ולא רק טקסט)

אלה הכללים הבלתי-עבירים שלנו. כל אחד מהם כתוב כטקסט בקובץ ה-core המתאים — וכאן הוא
מקבל גיבוי אכיפתי:

- **אימות לפני קומיט** — הרצת lint + format + טסטים על ה-diff, וחסימת הקומיט אם משהו
  נכשל. מגבה את [`quality-gates.md`](./quality-gates.md) › `<pre_commit_review>`.
- **איסור עקיפת בדיקות** — חסימת `git commit --no-verify` ושאר עקיפות. מגבה את
  [`debugging-policy.md`](./debugging-policy.md) › `<debug_loop>`.
- **חסימת כתיבה לנתיבים מוגנים** — מיגרציות, קבצי תשתית, `.env` — דורש אישור מפורש.
  מגבה את [`git-policy.md`](./git-policy.md) › `<safety>`.
- **סריקת secrets** — חסימת קומיט שמכיל מפתחות/טוקנים. מגבה את
  [`connector-policy.md`](./connector-policy.md) › `<environment>`.
- **סגירת Definition of Done** — בסיום turn, ודא שתנאי הסיום נסגרו לפני סימון משימה
  כגמורה. מגבה את [`quality-gates.md`](./quality-gates.md) › `<definition_of_done>`.
- **דוח שימוש בסוף turn** — Stop hook שמזכיר/מאמת שצורף בלוק "🧰 במה השתמשתי"
  (קונקטורים, MCP, סקילים, patterns, תיעוד). מגבה את [`CLAUDE.md`](../CLAUDE.md) ›
  `<communication>`.
- **bootstrap של סקילים** — SessionStart hook (או שלב הקמה) שמריץ
  [`../scripts/skill-bootstrap.sh`](../scripts/skill-bootstrap.sh) ומדווח על סקילים
  חסרים. מגבה את [`skill-orchestration-policy.md`](./skill-orchestration-policy.md) › `<bootstrap>`.

### אוכפים ייעודיים לכל md — `scripts/enforcement/`

כל קובץ נוהל ב-`core/` מקבל **אוכף ייעודי אחד** ב-[`../scripts/enforcement/`](../scripts/enforcement/)
שמכסה את *כל* מה שאותו md מכתיב — כולל הכלים/הסקילים שהוא מזכיר (לא אוכף נפרד לכל כלי).

- **קונבנציה:** `core/<name>.md` ↔ `scripts/enforcement/enforce-<name>.sh`.
- **פנקס ראיות משותף:** `scripts/enforcement/lib/evidence.sh` — מאפשר לאכוף "השתמש בכלי X"
  ע"י חסימת הפעולה התלויה עד שראיה לשימוש נרשמה (PostToolUse → PreToolUse gate).
- **נוהל סנכרון md↔אוכף (נאכף):** שינוי `core/<name>.md` שיש לו אוכף מחייב עדכון האוכף
  באותו commit. נאכף ע"י `scripts/enforcement/enforce-sync.sh` (נקרא מ-`pre-commit`),
  מול הרישום ב-`scripts/enforcement/MANIFEST.tsv`. md בלי אוכף חייב שורת `NONE` עם נימוק.
  bypass: `EOS_BYPASS_MDSYNC=1`.
- כל gate חוסם ב-`exit 1` עם הודעת `ERROR_FOR_AGENT:` ושם משתנה bypass ייעודי.

**אוכפים שמומשו עד כה:**

- **`enforce-workflow.sh`** (workflow.md) — PreToolUse Write/Edit/Agent/Bash:
  - שער כתיבה (plan existence + sections + freshness)
  - Context7 לפני package install
  - tasks.json schema validation לפני Agent
  - **G7** (graphify): חוסם Write/Edit/Agent אם `graphify-out/graph.json` קיים אך graphify לא רץ בסשן (evidence: `graphify_used` נרשם ב-`post-tool-use-bash.sh` כש-output >30 תווים). bypass: `EOS_BYPASS_GRAPHIFY=1`
  - **G8** (patterns domain): חוסם כתיבה לקובץ בדומיין מוכר (auth/api/billing/...) ללא קריאת `patterns/<domain>/`. evidence: `patterns_read_<domain>`. bypass: `EOS_BYPASS_PATTERNS=1`
  - **G12** (patterns advisory): WARNING_FOR_AGENT בלבד (לא exit 1) כשיוצרים קובץ חדש גנרי ולא נקרא אף pattern בסשן. bypass: `EOS_BYPASS_PATTERNS=1`
  - master bypass: `EOS_BYPASS_WORKFLOW=1`, `EOS_BYPASS_TASKSJSON=1` (לשער tasks.json בלבד)
- **`enforce-debugging.sh`** (debugging-policy.md) — שני נקודות חיווט:
  - PreToolUse → Bash: **D1** חוסם `git commit --no-verify|-n` ו-`git push --no-verify` (`EOS_BYPASS_NOVERIFY=1`); **D3** מזכיר (לא חוסם) לתעד ב-`failed-solutions/` בעת rollback.
  - `commit-msg`: **D2** חוסם קומיט `fix:` ללא קובץ טסט רגרסיה ב-diff (`EOS_BYPASS_FIXTEST=1`). master: `EOS_BYPASS_DEBUG=1`.
  - שאר ה-debug_loop (Sentry-first, השערה, מונה 3 ניסיונות) שיפוטי — לא נאכף.
- **`enforce-quality.sh`** (quality-gates.md) — `pre-commit`: חוסם הוספת שאריות debug ל-diff ה-staged (JS/TS/Python/Ruby: `debugger`/`breakpoint()`/`pdb`/`pry`/`byebug`; Go: `runtime.Breakpoint()`/`debug.PrintStack()`/`spew.Dump()`; Rust: `dbg!()`; Java/Kotlin: `dumpStack()`) + סמני merge-conflict. אזהרה לא-חוסמת: `console.log`/`print`/`fmt.Printf`/`log.Printf`/`eprintln!()`/`System.out.print`/`System.err.print`. bypass: `EOS_BYPASS_CLEANUP=1`, master `EOS_BYPASS_QUALITY=1`. (lint+test וסריקת test-files נשארים ב-pre-commit.sh.)
- **`enforce-resource.sh`** (resource-management.md) — `pre-commit`: R1 חוסם קומיט אם אין `.claudeignore` (`EOS_BYPASS_CLAUDEIGNORE=1`); `commit-msg`: R2 חוסם מזהה-מודל (`claude-<tier>-N`) בהודעת הקומיט (`EOS_BYPASS_MODELID=1`, מוגבל להודעות — לא סורק קוד). master: `EOS_BYPASS_RESOURCE=1`.
- **`enforce-git.sh`** (git-policy.md) — `PreToolUse(Bash)`: G1 חוסם `git push --force`/`-f` ה-plain (`--force-with-lease` מותר; `EOS_BYPASS_FORCEPUSH=1`); G2 חוסם `gh pr create --draft` (`EOS_BYPASS_DRAFTPR=1`). master: `EOS_BYPASS_GIT=1`. (one-branch ב-settings.json, `--no-verify` ב-enforce-debugging, פורמט commit ב-commit-msg — כבר נאכפים בנפרד.)
- **`enforce-connector.sh`** (connector-policy.md) — `pre-commit`: C1 חוסם קובץ `.env` ב-staged (פרט ל-example/sample/template; `EOS_BYPASS_ENVFILE=1`); C2 חוסם ערכי-סוד מובהקים ב-diff (PEM/AWS/GitHub/Slack/OpenAI; `EOS_BYPASS_SECRETS=1`). master: `EOS_BYPASS_CONNECTOR=1`. מממש את הבטחת סריקת ה-secrets שהופיעה ב-md-ים ולא היתה ממומשת.
- **`enforce-learning.sh`** (learning-loop.md) — `pre-commit`: L1 חוסם קובץ `lessons-learned/bugs/*` ב-staged שחסר שדה מ-8 שדות סכמת הלקח (`EOS_BYPASS_LESSON=1`); L2 חוסם `failed-solutions/*` חסר-סכמה (`EOS_BYPASS_FAILSOL=1`). master: `EOS_BYPASS_LEARNING=1`. מאחד את מבנה הלקחים כך שהלולאה ניתנת לשליפה/קידום תוכניתי.
- **`enforce-skill.sh`** (skill-orchestration-policy.md) — `pre-commit`: S1 חוסם `external-skills/<name>/` ב-staged שחסר אחד מ-4 קבצי החוזה (`EOS_BYPASS_SKILLDOC=1`); S2 חוסם סקיל שאינו רשום ב-`external-skills/README.md` (`EOS_BYPASS_SKILLREG=1`). master: `EOS_BYPASS_SKILL=1`. ולידציה index-based.
- **`enforce-documentation.sh`** (documentation-policy.md) — `pre-commit`: D1 חוסם `patterns/<domain>/` או `external-systems/<service>/` ב-staged ללא `README.md` (`EOS_BYPASS_DOCREADME=1`); D2 חוסם היעדר README בשורש (`EOS_BYPASS_ROOTREADME=1`); D3 חוסם placeholder עצמאי (TBD/FIXME/XXX/???) בקובצי `.md` (`EOS_BYPASS_TBD=1`). master: `EOS_BYPASS_DOC=1`. ולידציה index-based.
- **`pre-commit.sh`** — שני שערים חדשים (נוספו על גבי הקיימים):
  - **G10** (DoD completion): חוסם commit כשיש קבצי קוד staged וה-plan הנוכחי מכיל פריטי `- [ ]` בסעיף DoD. evidence: קריאה ישירה מה-plan file (לא תלוי ב-evidence ledger). bypass: `EOS_BYPASS_DOD=1`
  - **G11** (Verification): חוסם commit של >2 קבצי קוד כשגם `superpowers_verify_run` וגם `tests_run` חסרים מה-ledger. מספיק EITHER אחד מהם. evidence: `superpowers_verify_run` נרשם כש-`.claude/commands/superpowers-verify.md` נקרא (PostToolUse Read); `tests_run` נרשם ב-`post-tool-use-bash.sh`. bypass: `EOS_BYPASS_VERIFY=1`

### סיווג קריטיות של hooks

המקור המכונה לסיווג hooks הוא [`../scripts/enforcement/hook-criticality.tsv`](../scripts/enforcement/hook-criticality.tsv), ונבדק ב-CI ע"י `scripts/enforcement/tests/test-hook-classification.sh`.

- **hard** — חייב לחסום פעולה מסוכנת או כתיבה לא תקינה; אסור לעטוף אותו ב-`|| true`. ב-PreToolUse של Bash/Write/Agent חייב לרוץ קודם `pre-tool-use-json-guard.sh`.
- **advisory** — מזריק תזכורת או הקשר בלבד; מותר לו להיכשל רך כי הוא לא מעניק הרשאת כתיבה/מיזוג.
- **recorder** — רושם evidence ל-ledger עבור גייטים עתידיים. קלט JSON שבור חייב להיות `false_evidence_safe`: לא ליצור evidence שקרי. אם recorder לא רשם evidence, ה-hard gate שתלוי בו יחסום בהמשך.
- **lifecycle** — setup/cleanup/reporting. לכל command מוגדרות סמנטיקות משלו.

### כללי bypass ואמינות בסביבות שונות

**כלל אישור bypass:** `EOS_BYPASS_*` קיימים לקצה-מקרה לגיטימי, לא כקיצור-דרך מ-workflow.
לפני הפעלת bypass כלשהו: קבל אישור מפורש ומיידי מהמשתמש בשיחה הנוכחית (הודעה ישירה
כגון "עקוף את הgate" או "דלג על ה-plan הפעם"). **אל תאשר bypass בעצמך** — המנגנון
מיועד למשתמש, לא לסוכן. כלל זה נאכף גם ע"י הודעות ה-`ERROR_FOR_AGENT` שמזכירות
"only with explicit user authorization".

**הערה לסביבת remote (Claude Code on the web):** בסביבות remote container, hooks PreToolUse
אמורים לפעול וחסימת `exit 1` אמורה להישמר. hard hooks חייבים להיכשל סגור אם:
- `python3` אינו מותקן ב-runner.
- מטא-נתוני ה-JSON הנכנסים לא תואמים את ה-schema הצפוי.
- פקודת ה-hook עטופה בטעות ב-`|| true`.

לכן Bash/Write/Agent מתחילים ב-`pre-tool-use-json-guard.sh`. לעומת זאת, PostToolUse recorders
רשאים להיכשל רך כל עוד הם לא מייצרים evidence שקרי; חסר evidence יוביל לחסימה בשער הבא.
אם hook שאמור לחסום לא חסם — **אל תניח שהאכיפה תקינה**; בדוק שהוא מסווג כ-hard ב-`hook-criticality.tsv`, ש`python3` זמין, ושאין `|| true` ב-command החוסם.

### מה נשאר אישור-אדם (לא hook)

לא כל גייט הוא hook. **מיזוג ל-main** ופעולות הרסניות-משותפות (deploy, `DROP TABLE`)
נשארים אישור-אדם מפורש — hook יכול להזכיר או לחסום ברירת-מחדל, אבל ההחלטה היא של
המשתמש (ראה [`git-policy.md`](./git-policy.md) › `<safety>`). hooks מתאימים לבדיקות
אוטומטיות עם פלט pass/fail, לא להחלטות שיפוט.

### סוגי hooks עיקריים

- **PreToolUse** — לפני קריאת כלי; חוסם פעולה לפני שקרתה (כתיבה לנתיב מוגן, פקודה מסוכנת).
- **pre-commit** — לפני קומיט; מריץ את בדיקות האיכות וחוסם קומיט לא תקין.
- **Stop** — בסיום turn; מאמת תנאי סיום וחוסם סגירה עד שהם מתקיימים.

### כלל הקמה

הוסף את שכבת ה-hooks הבסיסית בהקמת **כל** פרויקט (ראה
[`workflow.md`](./workflow.md) › `<project_scaffold>`). אפשר לבקש מקלוד לכתוב את
ה-hook ("כתוב hook שמריץ lint אחרי כל עריכה" / "כתוב hook שחוסם כתיבה לתיקיית
migrations"). אל תסתפק בטקסט עבור כלל שאסור שייכשל אפילו פעם אחת.

</hooks>

---

## <known_gaps>

פערי אכיפה ידועים — מתועדים במפורש כדי שלא יועברו כ"כוונה".

| # | פגם | מיטיגציה | סטטוס |
|---|-----|----------|-------|
| **KG1** | `exit 1` מ-PreToolUse hook **אינו hard block בסביבת web** — קלוד רואה את השגיאה אך יכול לבחור להשתמש ב-bypass var | G3 (חסימת self-bypass דרך Bash) + G4 (audit trail לכל bypass שהופעל) | מיטיגטד |
| **KG2** | JSON parse failure עלול להפוך ל-silent pass אם hard gate קורא stdin ישירות | `pre-tool-use-json-guard.sh` רץ ראשון ב-Bash/Write/Agent; `pre-tool-use-runtime-evidence.sh` נכשל סגור; recorders נבדקים כ-`false_evidence_safe` ולא יוצרים evidence שקרי | מיטיגטד |
| **KG3** | **Bypass vars מחוץ לסשן**: משתמש שמגדיר `EOS_BYPASS_*=1` בטרמינל לפני פתיחת Claude Code עוקף את כל האכיפה | זו פעולה מכוונת של המשתמש — legitimately allowed. G4 (audit) יתעד זאת אחרי הסשן | by design |
| **KG4** | **`core/precedence.md` ו-`core/mcp-servers.md` נשארים NONE** — conflict resolution הוא judgment; reference table אין לו טריגר ברור | מתועד ב-MANIFEST.tsv עם נימוק | by design |
| **KG5** | **שערי evidence (G6) תלויים ב-PostToolUse(Read) hook**: אם ה-hook לא פועל (כשל טעינה), evidence לא נרשם ו-G6 חוסם בלי סיבה | evidence_reset ב-SessionStart מאפס; fallback: `EOS_BYPASS_WORKFLOW=1`; recorders נבדקים שלא יוצרים evidence שקרי על input שבור | מיטיגטד |
| **KG6** | **graphify evidence = הוכחה שרץ, לא שהממצאים שימשו**: `graphify_used` נרשם כש-output >30 תווים — Claude יכול להריץ graphify ולהתעלם מהתוצאות | G7 חוסם אם לא רץ בכלל; MANDATORY reminder ב-Read/Glob מזכיר לשלב ממצאים | by design |
| **KG7** | **Zombie Plan semantic**: plan יכול להיות טרי (age <48h) אבל לא רלוונטי למשימה הנוכחית | אין hook לsemantic relevance — דורש LLM/NLP; `ls -t plans/` מציג שם ו-Claude רואה אותו | by design |
| **KG8** | **G12 advisory בלבד** — קובץ גנרי חדש (utils.ts, helpers.py) יכול להיכתב ללא patterns read | WARNING_FOR_AGENT מוצג; G8 מכסה דומיינים מוכרים; G12 advisory לא blocking | intentional |

**אחריות תיעוד:** כשמתגלה פגם אכיפה חדש — הוסף שורה לטבלה הזו לפני שדנים בתיקון, כדי שהפגם לא יחזור לאחר refactor.

</known_gaps>

---

## <system_prompt_injection>

טקסט ב-CLAUDE.md מועבר כהודעת user אחרי ה-system prompt — לא כחלק ממנו. לעיקרון שאתה
רוצה ברמת ה-system prompt עצמו (למשל עקרון-העל "לאמת, לא לנחש"), השתמש ב-
`--append-system-prompt` בהרצה. זה חזק יותר מטקסט ב-CLAUDE.md, אך יש להעבירו בכל
הרצה — ולכן מתאים לסקריפטים ולאוטומציה (non-interactive) יותר מלשימוש אינטראקטיבי.

</system_prompt_injection>

---

## <hook_examples>

דוגמאות מלאות לכל סוג hook — העתק והתאם לפרויקט.

### PreToolUse (Write/Edit) — חסימת כתיבה ללא plan
קובץ: `.claude/settings.json` (ראה דוגמה מלאה ב-[`../.claude/settings.json`](../.claude/settings.json))
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash \"${ENGINEERING_OS_HOME:-$(pwd)}/scripts/hooks/validate-workflow-state.sh\" 2>&1"
      }]
    }]
  }
}
```
**שים לב:** אסור `|| true` בסוף — הוא מבטל את ה-exit code וה-enforcement לא עובד.

### pre-commit — lint + tests + חסימת no-verify
קובץ: `.git/hooks/pre-commit` (העתק מ-[`../scripts/hooks/pre-commit.sh`](../scripts/hooks/pre-commit.sh))
```bash
#!/bin/bash
set -e
STAGED=$(git diff --cached --name-only)
[ -z "$STAGED" ] && exit 0
# הרץ linter ו-tests לפי stack הפרויקט:
# JS/TS: npm run lint --if-present && npm test --if-present
# Python: ruff check . && pytest --tb=short -q
```
התקנה: `cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
לפרויקטי Engineering OS עצמו: `bash scripts/install-self-hooks.sh`

### commit-msg — אכיפת פורמט commit
קובץ: `.git/hooks/commit-msg` (העתק מ-[`../scripts/hooks/commit-msg.sh`](../scripts/hooks/commit-msg.sh))

### SessionStart — bootstrap + אימות סביבה
```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "bash \"${ENGINEERING_OS_HOME:-$(pwd)}/scripts/session-setup.sh\" 2>&1 | head -50 || true"
      }]
    }]
  }
}
```

</hook_examples>
