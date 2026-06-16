# Analytics Integration Patterns

> Part of [`patterns/integrations/`](../README.md). Covers connecting to analytics providers (Segment, Mixpanel, PostHog, Amplitude) for event tracking and data pipeline integration.
>
> See [`core/pattern-lifecycle.md`](../../../core/pattern-lifecycle.md) for scoring and lifecycle rules.

## Status: Placeholder

This domain is reserved. Patterns will be added when analytics integration is implemented in a project, following the standard pattern structure (Problem → Architecture → Implementation Notes → Example Code → Common Mistakes → Security Considerations → Testing Strategy → Score).

---

## Integration Model

Analytics integrations typically span two concerns:

**Client-side event tracking** — instrumenting user interactions (page views, clicks, conversions) via a JavaScript SDK. Key challenge: ensuring consistent event naming and property schemas across the app without coupling component code to the analytics provider.

**Server-side event tracking** — sending backend events (purchase completed, subscription activated, job processed) via HTTP API. Preferred over client-side for revenue events — client-side events can be blocked by ad blockers or lost on tab close.

---

## Architectural Considerations (before implementing)

Before adding patterns here, read the relevant official documentation and consider:

1. **Provider abstraction** — define a `Tracker` interface (`track(event, properties)`, `identify(userId, traits)`, `page(name, properties)`) and inject the provider. This follows the same provider-agnostic principle as all integrations in this domain.
2. **Event schema governance** — centralize event names and required properties in a typed schema (TypeScript enum or Zod schema) to prevent inconsistent naming across teams.
3. **PII handling** — never include raw PII (email, name, address) in analytics event properties without explicit user consent. Pseudonymize user identifiers where possible.
4. **Client-side vs. server-side** — revenue events must be sent server-side to avoid ad-blocker interference. UI interaction events can be client-side.
5. **Batching** — most providers support batching; use it for high-volume server-side tracking to avoid per-event HTTP overhead.

---

## Required Sources Before Implementing

Consult official documentation only (Tier 1):

- [Segment Analytics.js](https://segment.com/docs/connections/sources/catalog/libraries/website/javascript/)
- [PostHog Node.js SDK](https://posthog.com/docs/libraries/node)
- [Mixpanel Node.js SDK](https://developer.mixpanel.com/docs/nodejs)
- [Amplitude SDK](https://www.docs.developers.amplitude.com/analytics/sdks/node-js-sdk/)
