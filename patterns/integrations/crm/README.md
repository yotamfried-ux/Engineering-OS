# CRM Integration Patterns

> Part of [`patterns/integrations/`](../README.md). Covers connecting to CRM systems (HubSpot, Salesforce, Pipedrive) for contact sync, deal tracking, and activity logging.
>
> See [`core/pattern-lifecycle.md`](../../../core/pattern-lifecycle.md) for scoring and lifecycle rules.

## Status: Placeholder

This domain is reserved. Patterns will be added when CRM integration is implemented in a project, following the standard pattern structure (Problem → Architecture → Implementation Notes → Example Code → Common Mistakes → Security Considerations → Testing Strategy → Score).

---

## Integration Model

CRM integrations typically span three concerns:

**Contact sync** — bidirectional sync of user/lead records between the application DB and the CRM. Key challenge: conflict resolution when both systems update the same record concurrently.

**Activity logging** — pushing application events (form submissions, purchases, support tickets) to the CRM as activities or timeline entries. One-directional; CRM is the consumer.

**Webhook-driven updates** — reacting to CRM-side changes (deal stage changes, contact owner reassignment, task completion) via webhooks. Same signature verification principles apply as all other integrations in this domain.

---

## Architectural Considerations (before implementing)

Before adding patterns here, read the relevant official documentation and consider:

1. **Sync direction** — unidirectional (app → CRM) is simpler; bidirectional requires a conflict resolution strategy (last-write-wins, source-of-truth per field, or manual resolution queue).
2. **Identity mapping** — maintain a `crm_contact_mappings` table keyed by `(appUserId, crmContactId, provider)` to avoid duplicate contact creation.
3. **Rate limits** — all major CRMs impose per-day and per-second API limits; batch writes and queue outbound requests rather than calling synchronously on user actions.
4. **Field mapping** — normalize CRM-specific field names to internal models at the integration boundary, not in business logic.
5. **Webhooks** — use as the authoritative update path for CRM-side changes; do not poll.

---

## Required Sources Before Implementing

Consult official documentation only (Tier 1):

- [HubSpot API Reference](https://developers.hubspot.com/docs/api/overview)
- [Salesforce REST API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/)
- [Pipedrive API Reference](https://developers.pipedrive.com/docs/api/v1)
