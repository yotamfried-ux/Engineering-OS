# mcp-servers.md — שרתי MCP של הקונקטורים

> חלק מ-Engineering OS. **מסמך ייחוס — נטען לפי הצורך, לא אוטומטית.**
>
> **מתי לגשת לקובץ הזה:**
> - כשקונקטור אינו עובד דרך קלוד ורוצים **להוריד/לחבר את שרת ה-MCP שלו נקודתית
>   לפרויקט** (שלב 3 בנוהל ה-fallback של [`connector-policy.md`](./connector-policy.md)).

---

## רקע

- שרת MCP מתחבר לפרויקט עם הפקודה `claude mcp add`. ההגדרה נשמרת ב-`~/.claude.json`.
- **שלוש תצורות transport:** `stdio` (תהליך מקומי על המכונה), `http` (שרת מרוחק —
  מומלץ לשירותי ענן), `sse` (ישן, נדחק לטובת http).
- כל קונקטור מסופק או כ-**שרת מרוחק** (URL) או כ-**חבילה מקומית** (npx / docker / uvx).
- **מקור אמת לטוקנים: `.env` בלבד** (ראה [`connector-policy.md`](./connector-policy.md) ›
  `<environment>`). אל תטמיע טוקן בפקודה שנכנסת ל-git — העבר אותו דרך משתנה סביבה.
- **Composio הוא ה-fallback האוניברסלי:** `https://connect.composio.dev/mcp` נותן גישה
  לאלפי כלים דרך URL אחד. אם אין שרת ייעודי מאומת — בדוק שם תחילה.

## איך מוסיפים (כללי)

```bash
# שרת מרוחק (http)
claude mcp add --transport http <name> <url> --header "Authorization: Bearer $TOKEN"

# חבילה מקומית (stdio)
claude mcp add <name> -- npx -y <package>

# scope: --scope project (משותף לצוות דרך git) | --scope user (אישי, כל הפרויקטים)
# אימות שהחיבור עלה: הרץ /mcp בתוך הסשן
```

---

## טבלת הקונקטורים

מקרא: ✅ שרת רשמי מאומת · 🔌 לאמת מול תיעוד הספק / להשיג דרך Composio (אל תנחש כתובת)

### ליבה קבועה

| קונקטור | סטטוס | שרת MCP / איך מוסיפים |
|---|---|---|
| **GitHub** | ✅ | מרוחק: `https://api.githubcopilot.com/mcp/` (דורש PAT). מקומי: Docker `ghcr.io/github/github-mcp-server`. הערה: חבילת ה-npm הישנה `@modelcontextprotocol/server-github` הוצאה משימוש (04/2025). |
| **Context7** | ✅ | `https://mcp.context7.com/mcp` |
| **Sentry** | ✅ | `https://mcp.sentry.dev/mcp` |

### Backend / Data / אחסון

| קונקטור | סטטוס | שרת MCP / איך מוסיפים |
|---|---|---|
| **Supabase** | ✅ | `https://mcp.supabase.com/mcp` |
| **Firebase** | 🔌 | תיעוד Firebase MCP / Composio |
| **Pinecone** | 🔌 | תיעוד Pinecone MCP / Composio |
| **Upstash** | 🔌 | תיעוד Upstash MCP / Composio |
| **Clerk** | 🔌 | תיעוד Clerk MCP / Composio |
| **Prisma** | 🔌 | תיעוד Prisma MCP / Composio |

### פריסה / אירוח

| קונקטור | סטטוס | שרת MCP / איך מוסיפים |
|---|---|---|
| **Vercel** | ✅ | `https://mcp.vercel.com` |
| **Cloudflare** | ✅ | `https://bindings.mcp.cloudflare.com/mcp` (יש ל-Cloudflare כמה שרתים — docs, observability, ועוד) |
| **Expo** | 🔌 | תיעוד Expo MCP / Composio |
| **Azure** | 🔌 | תיעוד Azure MCP / Composio |
| **Google Cloud** | 🔌 | תיעוד Google Cloud MCP / Composio |

### בדיקות UI / API

| קונקטור | סטטוס | שרת MCP / איך מוסיפים |
|---|---|---|
| **Playwright** | ✅ | מקומי (Microsoft הרשמי): `claude mcp add playwright npx @playwright/mcp@latest` |
| **Maestro** | 🔌 | תיעוד Maestro MCP / Composio |
| **Storybook** | 🔌 | תיעוד Storybook MCP / Composio |
| **Chromatic** | 🔌 | תיעוד Chromatic MCP / Composio |
| **Postman** | ✅ | `https://mcp.postman.com/minimal` |
| **Figma** | ✅ | `https://mcp.figma.com/mcp` |

### אנליטיקה / ניטור AI

| קונקטור | סטטוס | שרת MCP / איך מוסיפים |
|---|---|---|
| **PostHog** | 🔌 | תיעוד PostHog MCP / Composio |
| **Arize** | 🔌 | תיעוד Arize MCP / Composio |
| **Braintrust** | 🔌 | תיעוד Braintrust MCP / Composio |

### ניהול פרויקטים ותשתית

| קונקטור | סטטוס | שרת MCP / איך מוסיפים |
|---|---|---|
| **Notion** | ✅ | `https://mcp.notion.com/mcp` |
| **Composio** | ✅ | `https://connect.composio.dev/mcp` (גם ה-fallback האוניברסלי לכל השאר) |

### שרתי MCP של סקילים (ראה [`../external-skills/`](../external-skills/))

חלק מהסקילים החיצוניים מספקים שרת MCP. הם מנוהלים דרך ה-SIP
([`skill-orchestration-policy.md`](./skill-orchestration-policy.md)); כאן רק ערך ה-MCP:

| סקיל | סטטוס | שרת MCP / איך מוסיפים |
|---|---|---|
| **graphify** | ✅ | מקומי (stdio): `claude mcp add --transport stdio graphify -- python -m graphify.serve graphify-out/graph.json`. דורש `uv tool install "graphifyy[mcp]"`. כלים: `query_graph`, `get_node`, `get_pr_impact`… ראה [`../external-skills/graphify/activation.md`](../external-skills/graphify/activation.md). **HTTP transport דורש `GRAPHIFY_API_KEY` ב-`.env` בלבד; טוקן בשיתוף URL = secret אישי, לא לקומיט.** |
| **claude-mem** | ✅ | מותקן עם הפלאגין (`npx claude-mem install`) — רושם את שרת ה-MCP `mcp-search` אוטומטית (כלים: `search`, `timeline`, `get_observations`). worker רץ על פורט 37777. ראה [`../external-skills/claude-mem/activation.md`](../external-skills/claude-mem/activation.md). |
| **nemotron** | ✅ | מקומי (stdio via uv): `claude mcp add --scope project nemotron -- uv run scripts/nemotron-mcp-server.py`. דורש `Nemotron_api_key` כ-Claude Code secret. כלים: `nemotron_generate_code`, `nemotron_review_code`, `nemotron_summarize`, `nemotron_explain`, `nemotron_brainstorm`. ראה [`../external-skills/nemotron/activation.md`](../external-skills/nemotron/activation.md). **API key = Claude Code secret בלבד — לא ב-`.env`, לא ב-git.** |

---

## כלל עבודה

- מצא **שרת רשמי** (✅) תחילה — הוא מתוחזק ומתעדכן אוטומטית.
- ל-🔌: רוב הספקים כיום מספקים שרת MCP — חפש ב**תיעוד ה-MCP של הספק** או ב-**Anthropic
  connector directory**; אם אין, השג דרך **Composio**. **אל תמציא כתובת שרת** — אמת אותה.
- העדף `--scope project` כדי שהחיבור יהיה משותף לצוות דרך git (בלי הטוקן — הטוקן ב-`.env`).
- אחרי ההוספה, אמת ב-`/mcp` שהשרת עלה, לפני שמסתמכים עליו.
