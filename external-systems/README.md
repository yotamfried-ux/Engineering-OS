# external-systems/

תיעוד אינטגרציה עם מערכות חיצוניות: API overview, auth model, key objects, setup, rate limits, ומגבלות ידועות.

## external-systems vs. patterns/integrations

| | external-systems/ | patterns/integrations/ |
|---|---|---|
| **מה** | תיעוד API גולמי של ספק ספציפי | קוד + ארכיטקטורה לאינטגרציה |
| **מתי** | בחירת ספק / lookup של API object | כשכותבים קוד שמדבר עם ספק |
| **דוגמה** | "מה השדות של Stripe Subscription?" | "איך מטפלים ב-webhook idempotency?" |

## 3 דרכי שימוש (מ-connector-policy.md)

1. **שילוב מלא** — החיבור מחובר דרך MCP ומשמש ישירות ב-workflow
2. **חילוץ חלקי** — קוראים את הדוקומנטציה ומממשים בקוד ידנית
3. **למידה והשראה** — מבינים את הארכיטקטורה של מערכת לפני בניית משהו דומה

## מערכות זמינות

### תשלומים ובילינג
| מערכת | תיאור |
|---|---|
| [`stripe/`](./stripe/) | תשלומים, subscriptions, billing — ראה גם `patterns/billing/` |

### אימות וזהות
| מערכת | תיאור |
|---|---|
| [`auth0/`](./auth0/) | Identity platform — OAuth, SSO, MFA |
| [`clerk/`](./clerk/) | Auth + user management לאפליקציות React/Next.js |
| [`firebase-auth/`](./firebase-auth/) | Auth כחלק מ-Firebase suite |

### AI ו-LLMs
| מערכת | תיאור |
|---|---|
| [`anthropic/`](./anthropic/) | Claude API — chat, tool use, streaming |
| [`google-gemini/`](./google-gemini/) | Gemini API — multimodal AI |
| [`cohere/`](./cohere/) | Embeddings, RAG, language models |

### וקטור DB ו-RAG
| מערכת | תיאור |
|---|---|
| [`chroma/`](./chroma/) | Open-source vector database |

### Agents ו-Orchestration
| מערכת | תיאור |
|---|---|
| [`autogen/`](./autogen/) | Multi-agent framework (Microsoft) |
| [`crewai/`](./crewai/) | Role-based multi-agent orchestration |

### Analytics ו-Monitoring
| מערכת | תיאור |
|---|---|
| [`amplitude/`](./amplitude/) | Product analytics |
| [`datadog/`](./datadog/) | Infrastructure monitoring, APM |
| [`grafana/`](./grafana/) | Visualization, dashboards |
| [`growthbook/`](./growthbook/) | Feature flags, A/B testing |

### קבצים ומדיה
| מערכת | תיאור |
|---|---|
| [`cloudinary/`](./cloudinary/) | Image/video transformation, CDN |

### Search
| מערכת | תיאור |
|---|---|
| [`algolia/`](./algolia/) | Search-as-a-service |

### זמינות ותזמון
| מערכת | תיאור |
|---|---|
| [`cal-com/`](./cal-com/) | Open-source scheduling — ראה גם `patterns/integrations/calendar/` |

### Evaluation ו-ML
| מערכת | תיאור |
|---|---|
| [`deepeval/`](./deepeval/) | LLM evaluation framework |
| [`dlt/`](./dlt/) | Data load tool — pipelines to warehouses |

### Connectors (Composio)
| מערכת | תיאור |
|---|---|
| [`connectors/`](./connectors/) | Composio-managed connectors: Stripe, Google Calendar, ועוד |

## הוספת מערכת חדשה

1. צור `external-systems/<provider>/README.md`
2. כלול: overview, auth model, key objects, SDK setup, rate limits, known limitations
3. אם יש קוד אינטגרציה — הוסף גם ל-`patterns/integrations/<domain>/`
4. אם יש Composio connector — הוסף ל-`connectors/<provider>/`
