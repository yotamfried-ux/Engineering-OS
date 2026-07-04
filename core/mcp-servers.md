# mcp-servers.md — שרתי MCP של הקונקטורים

> חלק מ-Engineering OS. נטען כשצריך להבין, להפעיל או לאמת שרתי MCP.
>
> **מתי לגשת לקובץ הזה:**
> - כשמחברים פרויקט ל-Engineering OS ורוצים להבין מה נכנס ל-`.mcp.json`.
> - כשקונקטור אינו עובד דרך Claude Code וצריך לאבחן auth / approval / server URL.
> - כשמוסיפים, משנים או מאמתים פרופיל MCP.

---

## עיקרון חדש: התקנת MCP אוטומטית, אימות והרשאות ידניים

`use-in-project.sh` מריץ את `scripts/install-mcp-servers.sh` ומתקין בפרויקט היעד קובץ
`.mcp.json` project-scoped. המשמעות: כל Claude Code / LLM שתומך ב-MCP ונטען מתוך אותו
פרויקט רואה את פרופילי השרתים כברירת מחדל.

ההתקנה **לא כותבת secrets** ולא מעניקה הרשאות בשם המשתמש. היא כותבת הגדרות שרת בלבד.
השלב הידני שנשאר הוא approval/auth בתוך Claude Code:

```bash
claude mcp list
claude mcp get <server>
# או בתוך הסשן:
/mcp
```

אם שרת דורש OAuth או token, מאשרים ומתחברים דרך Claude Code, משתני סביבה מקומיים, או secret
store מקומי. אסור להכניס tokens ל-git.

## מקור ההתקנה

| קובץ | תפקיד |
|---|---|
| `templates/connectors/github-readonly.json` | פרופיל GitHub read-only קשיח ובטוח |
| `templates/connectors/engineering-os-mcp.json` | bundle של פרופילי MCP לכל פרויקט יעד |
| `scripts/install-mcp-servers.sh` | ממזג את הפרופילים לתוך `.mcp.json` בפרויקט היעד |
| `scripts/enforcement/tests/test-mcp-auto-install.sh` | בדיקות צורה, merge, idempotency ו-fail-closed |

## מה מותקן אוטומטית

| שרת | מצב התקנה | הערות |
|---|---|---|
| `github-readonly` | מותקן אוטומטית | Docker image הרשמי של GitHub MCP; read-only; toolsets מצומצמים: context, repos, pull_requests, issues, actions |
| `context7` | מותקן אוטומטית | תיעוד רשמי עדכני; דורש approval לפי סביבת Claude |
| `notion` | מותקן אוטומטית | דורש OAuth/approval וגישה לעמודים/DB הרלוונטיים |
| `supabase` | מותקן אוטומטית | דורש auth לפרויקט Supabase הנבחר |
| `stripe` | מותקן אוטומטית | דורש auth; לעבוד ב-test mode כברירת מחדל עד החלטת משתמש |
| `playwright` | מותקן אוטומטית | stdio דרך `npx -y @playwright/mcp@latest` |
| `nemotron` | מותקן אוטומטית | stdio דרך `uv`; דורש `Nemotron_api_key` או `NEMOTRON_API_KEY` מקומי |
| `figma` | מותקן אוטומטית עם URL משתנה | משתמש ב-`${FIGMA_MCP_URL}` כדי לאפשר tenant/endpoint נכון בלי לקודד הרשאה |
| `sentry` | מותקן אוטומטית עם URL משתנה | משתמש ב-`${SENTRY_MCP_URL}`; auth נשאר בסביבת Claude/המשתמש |
| `postman` | מותקן אוטומטית עם URL משתנה | משתמש ב-`${POSTMAN_MCP_URL}` |
| `composio` | מותקן אוטומטית עם URL משתנה | fallback אוניברסלי לקונקטורים שאין להם פרופיל ישיר בפרויקט |

## כיסוי 12 קונקטורי ה-MCP מה-registry

| קונקטור registry | שרת שמספק גישה אחרי ההתקנה |
|---|---|
| github | `github-readonly` |
| notion | `notion` |
| slack | `composio` fallback או פרופיל ייעודי עתידי |
| linear | `composio` fallback או פרופיל ייעודי עתידי |
| jira | `composio` fallback או פרופיל ייעודי עתידי |
| stripe | `stripe` |
| supabase | `supabase` |
| postgres | `composio` fallback או פרופיל project-specific עם connection string מקומי |
| google-drive | `composio` fallback או פרופיל ייעודי עתידי |
| google-sheets | `composio` fallback או פרופיל ייעודי עתידי |
| figma | `figma` |
| discord | `composio` fallback או פרופיל ייעודי עתידי |

## כללי אבטחה

1. **אסור לכתוב secrets ל-`.mcp.json`** — רק placeholders או URL לא-סודי.
2. **GitHub נשאר read-only כברירת מחדל** — פרופיל write-capable דורש PR נפרד ואישור מפורש.
3. **אין broad toolsets** — אסור `all`, `default`, `git`, `copilot`, `notifications`, `gists`, `dependabot`, `code_security`, או `discussions` בברירת המחדל.
4. **פרופילים project-scoped** — הקובץ נמצא בשורש הפרויקט כדי שכל LLM/Claude Code שרץ שם יקבל את אותה תצורה.
5. **אימות live עדיין חובה** — לפני שמסתמכים על קונקטור במשימה, ודא שהוא visible/approved ב-`/mcp` או תעד fallback/waiver ב-Route Plan.

## נוהל אימות אחרי התקנה

```bash
bash ~/.engineering-os/scripts/use-in-project.sh
claude mcp list
claude mcp get github-readonly
```

בתוך Claude Code:

```text
/mcp
```

רשומת אימות מינימלית ב-Route Plan:

```md
## Connector Usage Evidence
- source: /mcp server list in the target project.
- action: verified the required server was visible and approved.
- result: <server-name> was available for <task>.
- decision: used <server-name> as source of truth for <target>.
- target: <file/path or service checked>.
```

## כלל עבודה

- ההתקנה האוטומטית נותנת ל-Claude גישה לשרתים מבחינת configuration/discovery.
- authentication, approval, permissions ו-live data access עדיין חייבים אימות פר-פרויקט ופר-משימה.
- אם שרת לא עובד, קודם בדוק `/mcp`, אחר כך auth/env, אחר כך fallback דרך `composio`, ורק אז פנה למשתמש.
