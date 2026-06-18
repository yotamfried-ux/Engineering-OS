# patterns/

ספריית תבניות הקוד של Engineering OS. כל תבנית היא פתרון מוכן לשימוש-חוזר לבעיה חוזרת — עם implementation מלא, security considerations, ו-testing strategy.

## patterns vs. templates

| | patterns/ | templates/ |
|---|---|---|
| **מה** | תבנית קוד ספציפית (פונקציה, class, middleware) | מפרט ארכיטקטורי לפרויקט שלם |
| **מתי** | בזמן כתיבה — כשצריך קוד מוכן לבעיה ידועה | בתחילת פרויקט — לתכנון stack ורכיבים |
| **פורמט** | Problem → Solution → Code → Testing | Checklist + stack recommendations |

## איך בוחרים תבנית

1. **query על `registry.yaml`** — חפש לפי `domain` ו-`status`:
   ```bash
   # תבניות active בתחום auth:
   grep -A5 'domain: auth' patterns/registry.yaml | grep -E 'id:|status:|score:'
   ```
2. **קרא את ה-README של הדומיין** — implementation מלא + common mistakes.
3. **בדוק `status`** — `active` עדיפה; `candidate` תקפה אך טרם אומתה בפרודקשן.

> **כל התבניות כרגע בסטטוס `candidate`** — לא אומתו בפרודקשן עדיין. ה-score יתמלא בשימוש ראשון (ראה `core/scoring-guide.md`).

## דומיינים

| דומיין | תיאור | קובץ |
|---|---|---|
| `api` | Pagination, rate limiting, versioning, validation, error format | [`api/README.md`](./api/README.md) |
| `auth` | JWT, OAuth 2.0, sessions, API keys | [`auth/README.md`](./auth/README.md) |
| `authorization` | RBAC, ABAC, ReBAC, policy engines | [`authorization/README.md`](./authorization/README.md) |
| `billing` | Stripe subscriptions, webhooks, metered billing, trials | [`billing/README.md`](./billing/README.md) |
| `database` | Repository pattern, optimistic locking, soft delete, migrations, pooling | [`database/README.md`](./database/README.md) |
| `deployment` | Blue-green, canary, feature flags, zero-downtime migrations | [`deployment/README.md`](./deployment/README.md) |
| `frontend` | Next.js App Router, optimistic updates, infinite scroll, forms | [`frontend/README.md`](./frontend/README.md) |
| `infrastructure` | Terraform, Docker, Kubernetes, secrets management, Pulumi | [`infrastructure/README.md`](./infrastructure/README.md) |
| `machine-learning` | Train/val/test split, feature store, model registry, shadow mode | [`machine-learning/README.md`](./machine-learning/README.md) |
| `mobile` | Offline-first, deep linking, push notifications, OTA updates | [`mobile/README.md`](./mobile/README.md) |
| `observability` | Structured logging, tracing, health checks, SLO alerting | [`observability/README.md`](./observability/README.md) |
| `security` | Input validation, CSRF, secrets, RLS, rate limiting | [`security/README.md`](./security/README.md) |
| `storage` | Pre-signed uploads, CDN, file processing, tiering | [`storage/README.md`](./storage/README.md) |
| `testing` | Test pyramid, AAA, factories, contract testing, regression | [`testing/README.md`](./testing/README.md) |
| `ui` | Design tokens, component architecture, accessibility, data tables, theming | [`ui/README.md`](./ui/README.md) |
| `ai` | Prompt chaining, tool use, memory, streaming, structured output | [`ai/README.md`](./ai/README.md) |
| `ai-agents` | Multi-agent, orchestration, tool-calling | [`ai-agents/README.md`](./ai-agents/README.md) |
| `background-jobs` | Queue + retry, cron, idempotent workers, DLQ | [`background-jobs/README.md`](./background-jobs/README.md) |
| `integrations/calendar` | Google Calendar, MS Graph, Cal.com, Calendly, unified abstraction, booking state machine | [`integrations/calendar/README.md`](./integrations/calendar/README.md) |
| `integrations/email` | Transactional email (provider-agnostic) | [`integrations/email/README.md`](./integrations/email/README.md) |
| `integrations/notifications` | Push notifications (FCM/APNs), in-app notifications | [`integrations/notifications/README.md`](./integrations/notifications/README.md) |
| `integrations/messaging` | SMS / OTP verification | [`integrations/messaging/README.md`](./integrations/messaging/README.md) |

> **כלל שכבות:** קוד שמתקשר עם ספק חיצוני → `patterns/integrations/`. קוד פנימי → `patterns/<domain>/`. תיעוד API גולמי של ספק → `external-systems/`.

## הוספת תבנית חדשה

1. כתוב ב-README.md של הדומיין הרלוונטי לפי המבנה הסטנדרטי (Problem → Solution → Implementation Notes → Example → Common Mistakes → Security Considerations → Testing → Score).
2. הוסף רשומה ל-[`registry.yaml`](./registry.yaml) עם `status: candidate`.
3. אחרי שימוש ראשון בפרודקשן — עדכן `evidence` וחשב `score` (ראה `core/scoring-guide.md`).
4. לאחר שני שימושים עם ציון ≥60 — שנה ל-`status: active`.
