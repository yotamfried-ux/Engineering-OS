# התקנה אוטומטית של Claude Code plugins ממסקריפט bash

## מה קרה

ניסינו להגדיר superpowers כ-L2 mandatory skill שמותקן אוטומטית כחלק מ-`use-in-project.sh`.
הגישה הראשונה (`claude /plugin install superpowers@claude-plugins-official`) נכשלה —
הפקודה כלל לא קיימת ב-CLI.

## שורש הבעיה

`/plugin install` הוא **slash command** שרץ בתוך ממשק Claude Code — לא פקודת מעטפת.
אי-אפשר לקרוא לו מ-bash, CI, Docker, או כל הקשר לא-אינטראקטיבי.

הפקודה הנכונה היא `claude plugin install` (ללא slash), שהיא פקודת CLI רגילה ועובדת
באופן לא-אינטראקטיבי.

## השערות שנבדקו

- `claude /plugin install superpowers@claude-plugins-official` — נשללה: לא קיימת ב-CLI
- `claude plugin install superpowers@claude-plugins-official` — נשללה: marketplace לא מוכר
- `claude plugin marketplace add obra/superpowers-marketplace` + `claude plugin install superpowers@superpowers-marketplace` — **אומתה כפתרון**

## ראיה

מחקר שבחן:
1. מבנה הריפו `https://github.com/obra/superpowers-marketplace` — קובץ `.claude-plugin/marketplace.json`
2. תיקיית `~/.claude/plugins/` אחרי ההתקנה: `cache/superpowers-marketplace/superpowers/5.1.0/` נוצרה
3. `installed_plugins.json` ו-`known_marketplaces.json` עודכנו אוטומטית
4. `claude plugin list` החזיר את superpowers אחרי ההתקנה

## רמת ביטחון

High — הפתרון נחקר, אומת, ונפרס ב-`skill-bootstrap.sh`

## איך מזהים מוקדם

כשמוסיפים plugin חדש לרשימת L2 default skills ורוצים auto-install — לבדוק קודם
אם קיים marketplace entry (קובץ `.claude-plugin/marketplace.json` בריפו של ה-plugin).

## תבנית להתקנת Claude Code plugin באופן אוטומטי

כל plugin שמופץ דרך marketplace בנוי כך:

```
<org>/<marketplace-repo>/
└── .claude-plugin/
    └── marketplace.json   ← רשימת plugins עם GitHub URLs וגרסאות
```

**שלב 1:** רשום את ה-marketplace:
```bash
claude plugin marketplace add <org>/<marketplace-repo>
```

**שלב 2:** התקן את ה-plugin:
```bash
claude plugin install <plugin-name>@<marketplace-name>
```

**דוגמה (superpowers):**
```bash
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
```

שתי הפקודות:
- לא-אינטראקטיביות (ללא prompts)
- אידמפוטנטיות (בטוח להריץ פעמים)
- עובדות מ-bash, CI/CD, Docker, cron
- מעדכנות את `~/.claude/plugins/installed_plugins.json` אוטומטית

## איך מונעים בעתיד

לפני הגדרת plugin חדש כ-`fn:_install_<name>` ב-`skill-bootstrap.sh`:
1. מצא את ה-marketplace repo של ה-plugin
2. וודא שיש `.claude-plugin/marketplace.json`
3. העתק את התבנית מ-`_install_superpowers()` ב-`scripts/skill-bootstrap.sh`
4. שנה רק: `<marketplace-repo>` ו-`<plugin-name>@<marketplace-name>`

## טסט רגרסיה

```bash
# אחרי הרצת use-in-project.sh על פרויקט נקי:
claude plugin list | grep -i superpowers
# צפוי: superpowers v5.1.0 (enabled)
```

## סטטוס הבשלה

Verified Lesson

## Prevented Future Issues: 0
