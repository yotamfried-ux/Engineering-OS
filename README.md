# Engineering OS

מערכת הפעלה לפיתוח תוכנה — ריפו מרכזי של כללים, תבניות קוד, ו-workflow שהופכים את Claude לסוכן פיתוח עקבי ואמין בכל פרויקט.

**בעיה שהוא פותר:** בכל פרויקט חדש, Claude מתחיל מאפס — ארכיטקטורה מאולתרת, security שנשכחת, patterns שמומצאים מחדש. Engineering OS מגדיר ברירות מחדל קבועות, patterns מאומתים, וכללים שנאכפים דטרמיניסטית — כך שכל פרויקט מתחיל מ"כבר יודעים".

**עיקרון-העל: לאמת, לא לנחש.** כל קביעה על מצב המערכת — קוד, נתונים, באגים, פריסה — נשענת על בדיקה דרך כלי. ניחוש שגוי על מצב המערכת הוא מקור הבאגים החוזרים מספר אחת.

---

## מבנה הריפו

| שכבה | תוכן | מתי משתמשים |
|---|---|---|
| `CLAUDE.md` | Entry point — תפקיד, עקרונות, מפת ניווט | נטען אוטומטית בכל סשן |
| `core/` | קבצי מדיניות: workflow, git, hooks, quality-gates, debugging, learning, patterns | לפני כל פעולה — גש לקובץ הרלוונטי |
| `patterns/` | תבניות קוד מוכנות לשימוש-חוזר (98 תבניות, 21 דומיינים) | כשכותבים קוד לבעיה ידועה |
| `templates/` | מפרטים ארכיטקטוריים לתחילת פרויקט | בתחילת פרויקט חדש |
| `external-systems/` | תיעוד API של מערכות חיצוניות (Stripe, Auth0, Anthropic, …) | כשמגדירים אינטגרציה |
| `external-skills/` | סקילים שמשנים את ה-workflow של Claude (superpowers, security-review, ui-ux-pro-max, …) | נשלטים ע"י `core/skill-orchestration-policy.md` |
| `scripts/` | כלי bootstrap, session setup, hooks | `skill-bootstrap.sh` להקמת פרויקט חדש |
| `lessons-learned/` | באגים מתועדים, postmortems, prevention strategies | לפני debugging — קרא לפני שמנסים שוב |
| `failed-solutions/` | פתרונות שנוסו ונכשלו | קרא לפני שמנסים גישה דומה |
| `architecture-decisions/` | ADRs — החלטות ארכיטקטוניות מנומקות | לפני שמערערים החלטה קיימת |

---

## הקמת פרויקט חדש

**3 צעדים:**

```bash
# 1. העתק את CLAUDE.md לפרויקט החדש
cp CLAUDE.md /path/to/new-project/CLAUDE.md

# 2. מלא את <project_context> ב-CLAUDE.md
#    Owner, Goal, Type, Stack, Stage, Key services

# 3. הרץ skill-bootstrap.sh לאימות שכל הסקילים מותקנים
bash scripts/skill-bootstrap.sh --install
```

לאחר מכן:
- בחר template מ-`templates/` לפי סוג הפרויקט
- הגדר pre-commit hook: `cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
- התחל בשלב 1 של `core/workflow.md` — אפיון ב-Notion

---

## ניווט מהיר

| צריך | קובץ |
|---|---|
| סדר שלבי עבודה | [`core/workflow.md`](./core/workflow.md) |
| תבניות קוד לפי דומיין | [`patterns/`](./patterns/) |
| תבניות ארכיטקטורה לפי סוג פרויקט | [`templates/`](./templates/) |
| תיעוד API של מערכות חיצוניות | [`external-systems/`](./external-systems/) |
| כללי git, קומיט, branches | [`core/git-policy.md`](./core/git-policy.md) |
| תנאי סיום (DoD) לפני קומיט | [`core/quality-gates.md`](./core/quality-gates.md) |
| debugging — לפני שמנחשים | [`core/debugging-policy.md`](./core/debugging-policy.md) |
| כשהנחיות מתנגשות | [`core/precedence.md`](./core/precedence.md) |
| הגדרת ו-bootstrap של סקילים | [`core/skill-orchestration-policy.md`](./core/skill-orchestration-policy.md) |
