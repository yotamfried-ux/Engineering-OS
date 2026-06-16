# Integration Patterns

> The unified integration domain for Engineering OS. This is the single source of truth for patterns that connect the application to external third-party systems.
>
> See [`pattern-lifecycle.md`](../../core/pattern-lifecycle.md) for scoring and lifecycle rules.

## What belongs here vs. elsewhere

| Layer | Purpose | When to use |
|---|---|---|
| `patterns/integrations/*` | **Implementation patterns** — how to connect, authenticate, normalize, and build on top of external systems | When writing code that integrates with a third-party API or service |
| `external-systems/*` | **Reference documentation** — API overview, auth model, key objects, setup, rate limits, known limitations | When choosing a provider or looking up API structure before implementation |
| `patterns/*` (other domains) | **Core patterns** — database, API, auth, observability, testing, infrastructure | When building application internals that do not cross external system boundaries |
| `templates/*` | **Project scaffolds** — full-stack architecture checklists and starter kit recommendations | When starting a new project type |

**Rule:** If the code or architecture is about communicating with an external provider, it belongs in `patterns/integrations/`. If it is about how an internal system behaves (queue, DB, API shape), it belongs in the relevant `patterns/<domain>/` folder.

---

## Integration domains

| Domain | Path | Status |
|---|---|---|
| Calendar & Scheduling | [`calendar/`](./calendar/README.md) | Active |
| Email | [`email/`](./email/README.md) | Active (migrated from `patterns/communication/`) |
| Notifications | [`notifications/`](./notifications/README.md) | Active (migrated from `patterns/communication/`) |
| Messaging | [`messaging/`](./messaging/README.md) | Active (migrated from `patterns/communication/`) |
| CRM | [`crm/`](./crm/README.md) | Placeholder |
| Analytics | [`analytics/`](./analytics/README.md) | Placeholder |

---

## Design principles

**Provider-agnostic first:** Define a typed interface for the capability (send an email, list calendar events, create a CRM contact). Implement one provider per concrete class. Business logic depends on the interface; only the DI layer knows which provider is active.

**Normalize at the boundary:** Convert provider-specific types to internal models at the integration layer. Never let provider-specific types leak into service or business logic layers.

**Webhooks as the update path:** For all state changes in external systems, treat webhooks as the authoritative update mechanism, not polling. Verify webhook signatures before processing.

**Secrets at runtime:** Never store API keys, OAuth tokens, or webhook secrets in code or config files. Fetch from secrets management at startup. See [`patterns/infrastructure/`](../infrastructure/README.md) — Secrets Management pattern.

---

## Adding a new integration domain

1. Create `patterns/integrations/<domain>/README.md`
2. Follow the standard pattern structure (Problem → Architecture → Implementation Notes → Example Code → Common Mistakes → Security Considerations → Testing Strategy → Score)
3. Add a corresponding `external-systems/<provider>/README.md` for each provider's raw API reference
4. Add the domain to the table above
5. Update [`CLAUDE.md`](../../CLAUDE.md) navigation table if it is a significant new domain

---

## Migration note

The patterns previously in `patterns/communication/` (Transactional Email, Push Notifications, In-App Notifications, SMS Verification) have been migrated to this domain. `patterns/communication/README.md` now redirects here.
