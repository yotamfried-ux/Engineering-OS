# The 20 prelaunch checks — coverage and acceptance evidence

Source: user-provided social-video screenshots; discovery only (Tier C). The checklist is NOT authoritative. Official standards below take precedence. Every item requires an executed test on the target revision; documentation alone is NOT TESTED.

| ID | Check | Required evidence / failure signal | Canonical source |
|---|---|---|---|
| 01 | Exposed API keys | secret scanner + history scan, rotation of discovered secrets; public client keys classified separately | GitHub secret scanning; OWASP ASVS |
| 02 | Row-level security | cross-tenant negative integration tests for each table/role; verify actual policy enforcement | Supabase RLS docs; OWASP ASVS |
| 03 | Missing rate limits | authenticated/anonymous burst and abuse tests; safe 429/retry behavior | OWASP API Security |
| 04 | Database default access | audit grants, anonymous roles, schemas, storage permissions; least privilege | PostgreSQL privileges; Supabase security |
| 05 | Unprotected admin routes | unauthorized and horizontal/vertical privilege escalation tests | OWASP ASVS |
| 06 | Leaked stack traces | production-like error tests; no secrets/stack traces in responses | OWASP ASVS |
| 07 | Server-side validation | invalid payload/ownership/business rule tests bypassing UI | OWASP ASVS |
| 08 | Unhandled errors | fault injection; meaningful response, telemetry, no process crash | Google SRE |
| 09 | Database-down handling | dependency outage, timeout, retry budget, recovery and user-visible fallback | Google SRE |
| 10 | Empty states | UI tests for zero data, loading, error, no access | Apple HIG; Material Design |
| 11 | N+1 queries | query-count and latency comparison under increased collection sizes | PostgreSQL EXPLAIN; ORM official docs |
| 12 | Image optimization | responsive sizes, compression, LCP/network measurements | web.dev |
| 13 | Test under load | representative traffic, latency percentiles, errors, saturation, rollback thresholds | Google SRE |
| 14 | Unnecessary re-renders | production profiler before/after, real interaction metrics | React Profiler official docs |
| 15 | Stripe webhook signatures | invalid/missing/valid signature, replay/idempotency and event ordering tests | Stripe webhook docs |
| 16 | No stored card data | data-flow and database/log scan; hosted payment elements; PCI scope review | Stripe; PCI SSC |
| 17 | Privacy policy | data inventory reconciled with policy, SDKs, retention, deletion, stores and jurisdiction | Israel PPA; Apple; Google |
| 18 | Mobile screen size | device viewport matrix incl. zoom, orientation and accessibility | Apple HIG; Android quality |
| 19 | Every button works | end-to-end core journeys, keyboard/screen-reader actions, error paths | WCAG 2.2; platform UI docs |
| 20 | Prelaunch checklist | signed release gate report with applicability, revision, evidence, failures and owner | NIST SSDF; Apple/Google |

## Additional mandatory review areas
Supply chain and SBOM, CI permissions, backups/restoration, monitoring, deletion requests, accessibility, user-generated content moderation, consent and child safety, release signing, data migrations and rollback. Apply only when relevant, record N/A reasoning.

## Useful official references
https://supabase.com/docs/guides/database/postgres/row-level-security
https://docs.stripe.com/webhooks/signature
https://docs.stripe.com/webhooks
https://owasp.org/API-Security/
https://web.dev/learn/performance
https://react.dev/reference/react/Profiler
https://sre.google/books/
https://www.w3.org/TR/WCAG22/
