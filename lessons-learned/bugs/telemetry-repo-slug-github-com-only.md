# Bug: זיהוי repo-slug בטלמטריה נכשל על remotes שאינם github.com

**תאריך:** 2026-07
**חומרה:** Medium — עצר handoff טלמטריה בסביבות עם git remote מתווך (proxy), לא גרם לאובדן נתונים

## מה קרה

`sync-telemetry-run.py::repo_slug_from_url` זיהה רק URLs שמכילים את המחרוזת
`github.com/` או `github.com:`. בסביבה עם git remote מתווך (למשל
`http://local_proxy@127.0.0.1:PORT/git/<owner>/<repo>`, כפי שקורה בסביבת ה-remote
execution הזו), הפונקציה החזירה `""`, וללא `--repo`/`GITHUB_REPOSITORY` מפורשים
`detect_repo_slug()` זרק `HandoffError("cannot determine canonical repository
identity...")` — handoff הטלמטריה נכשל לגמרי.

## שורש הבעיה

שתי מימושים נפרדים ומתפצלים ל"git remote URL → owner/repo" חיו בקוד:

1. `sync-telemetry-run.py::repo_slug_from_url` — github.com-only (המימוש שבפועל
   קובע את זהות ה-repo ל-handoff).
2. `telemetry_repo_discovery.py::_normalize_repo_slug` — כללי יותר (`git@`,
   `scheme://`), אך גם הוא נכשל על אותה צורת URL מתווכת, כי דרש בדיוק שני
   path-segments בעוד ה-proxy מוסיף segment נוסף (`/git/`) לפני `owner/repo`.

אף אחד מהם לא היה מקושר לפרודקשן טסט שבודק את הנתיב הזה בפועל: כל הטסטים
הקיימים ב-`.sh` מעבירים `--repo` באופן מפורש, כך שאף אחד מהם לא הפעיל את נתיב
ה-fallback (`git remote get-url origin` → parsing) — זו הסיבה שהבאג לא נתפס
קודם.

## השערות שנבדקו

- "צריך רק להוסיף עוד marker ל-`repo_slug_from_url` (כמו `gitlab.com/`)" —
  נדחתה: הפתרון הכללי (כל host, כולל proxy) עדיף ואינו מסובך יותר.
- "אפשר להעתיק את `_normalize_repo_slug` כמו שהוא כ'הפתרון הכללי'" — נדחתה
  אחרי בדיקה חיה: גם הוא נכשל על ה-URL המתווך בסביבה הזו (path segment נוסף).
- "לקיחת שני ה-segments האחרונים תמיד (ללא תנאי)" — נדחתה: זה היה משנה את
  ההתנהגות הקיימת של `_normalize_repo_slug` על bare slugs (למשל
  `"other/example/repo-a"`), ומפר טסט regression קיים
  (`test-telemetry-repo-attribution.py`) שדורש דחיית קלט כזה כדי למנוע spoofing
  של attribution מ-payload של hook.

## ראיה

הרצה חיה (command) של `detect_repo_slug(Path('.'))` כנגד ה-origin האמיתי של
הריפו הזה (`http://local_proxy@127.0.0.1:.../git/yotamfried-ux/Engineering-OS`)
נכשלה עם `HandoffError` לפני התיקון, ועברה בהצלחה והחזירה
`"yotamfried-ux/Engineering-OS"` אחרי התיקון. `_normalize_repo_slug` על אותו
URL החזיר ערך ריק (falsy) לפני התיקון (אומת בהרצה ישירה ב-Python), ו-
`"yotamfried-ux/engineering-os"` (casefolded) אחרי התיקון. בנוסף, הרצת
`python3 scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py` עברה
(passed) עם כל התרחישים לעיל.

## רמת ביטחון

High — השורש אומת בהרצה חיה כנגד ה-origin האמיתי של הסביבה (לא רק תיאורטית),
ותוקן על ידי מימוש משותף יחיד עם כיסוי טסטים חדש שמכסה את שני נתיבי הקריאה.

## איך מזהים מוקדם

```bash
cd <repo>
git remote get-url origin
python3 -c "
import sys; sys.path.insert(0, 'scripts/monitoring')
import telemetry_handoff as h
print(h.parse_repo_slug_from_remote('$(git remote get-url origin)'))
"
# אם מחזיר None על origin תקין — הבעיה חוזרת.
```

## איך מונעים בעתיד

- כל פונקציית URL→slug חדשה בקוד הטלמטריה חייבת לעבור בדיקה (test) כנגד:
  github.com https/ssh, `ssh://`, כל host אחר, ובמיוחד כל צורת proxy/מתווך
  שנצפתה בסביבת ה-remote execution בפועל — לא רק github.com. הבדיקה הזו
  מורצת עכשיו כחלק מ-CI (`test-telemetry-repo-slug-parsing.py`), כך שרגרסיה
  חוסמת (block) merge.
- טסטים (tests) שקוראים ל-`sync-telemetry-run.py` צריכים לכלול לפחות תרחיש
  אחד בלי `--repo` מפורש, כדי לכסות את נתיב ה-fallback בפועל (זה שהחסיר את
  הבאג ולא נתפס ע"י בדיקות existing).
- ריכוז לוגיקת parsing כזו במודול משותף יחיד (`telemetry_handoff.py`) במקום
  לשכפל אותה בכל סקריפט — מפחית סיכון ל-drift שאף בדיקה לא תתפוס.

## טסט רגרסיה

```bash
cd /home/user/Engineering-OS
python3 scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py
python3 scripts/enforcement/tests/test-telemetry-repo-attribution.py
```

## סטטוס הבשלה

Verified Lesson

## Prevention/Enforcement Update

Added `scripts/enforcement/tests/test-telemetry-repo-slug-parsing.py`, a regression
test covering github.com https/ssh, `ssh://`, this environment's real proxied origin
shape, gitlab-style subgroup paths, and rejection of bare multi-component slugs; wired
it into the `multirepo-dispatch` job of `.github/workflows/telemetry-handoff-tests.yml`
so any future regression in `parse_repo_slug_from_remote` blocks CI.

## תועד ב

`scripts/monitoring/telemetry_handoff.py` (`parse_repo_slug_from_remote`),
`.claude/plans/fix-repo-slug-url-parsing.md`

## Prevented Future Issues: 0
