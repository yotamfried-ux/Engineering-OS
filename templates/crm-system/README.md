# CRM System Template

## Overview
Use this template for a Customer Relationship Management platform where sales, support, or success teams track contacts, deals, and interactions. Suited for product teams building an internal or vertical-specific CRM rather than adopting a generic SaaS tool. Key value is a unified activity timeline, pipeline visibility across the team, and email integration that automatically associates messages with the right contact or deal.

## Recommended Architecture Options
- **Monolith with feature modules (contacts, deals, activities, reports)** — Simplest to start; shared data model avoids cross-join complexity; scale with read replicas before splitting.
- **Backend API (REST/GraphQL) + React SPA** — Clean separation; enables mobile app later; API can be reused by integrations; adds CORS and auth complexity vs. SSR.
- **Event-sourced activity timeline** — Every interaction is an immutable event; enables full audit, undo, and time-travel queries; high complexity, justified only for compliance-heavy industries.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Backend | Node.js (NestJS), Python (Django), Ruby on Rails, Go |
| Frontend | React + TanStack Table, Next.js, Remix |
| Database | PostgreSQL (primary), Redis (sessions, search cache) |
| Full-text search | PostgreSQL `tsvector`, Elasticsearch, Meilisearch |
| Email integration | Google Gmail API, Microsoft Graph Mail API, Nylas |
| File storage | AWS S3 / Cloudflare R2 (attachments, documents) |
| Background jobs | BullMQ, Sidekiq (email sync, report generation) |
| Charts | Recharts, Chart.js, Observable Plot |
| Auth | Auth0, Supabase Auth, NextAuth.js |

## Required Components
- Contact record: name, company, email(s), phone(s), social links, tags, owner (sales rep), custom fields
- Company record: linked to multiple contacts; industry, size, stage, owner
- Deal pipeline: stages (Lead → Qualified → Proposal → Won/Lost), value, close date, probability
- Activity timeline per contact/deal: emails, calls, notes, meetings, tasks — sorted chronologically
- Email integration: OAuth connect Gmail/Outlook; auto-associate inbound/outbound emails by sender/recipient; sync on schedule
- Task management: assign tasks to users with due dates; overdue alerts; linked to contact or deal
- Multi-user with roles: Admin (full), Manager (team view + reports), Rep (own contacts/deals only)
- Pipeline report: deal count and value by stage, conversion rate between stages, average sales cycle
- Activity report: calls/emails/meetings per rep per period; leaderboard
- Bulk actions: import contacts from CSV; bulk reassign owner; bulk add tag
- Notes with @mention: notify team members; stored with timestamp and author
- Search: global search across contacts, companies, deals, notes with relevance ranking

## Security Checklist
- [ ] Row-level security: reps can only read contacts/deals they own (or their team's, for managers)
- [ ] Admin cannot read email content of other users — OAuth tokens are per-user, not shared
- [ ] Email OAuth tokens stored encrypted at rest; scope limited to `mail.readonly` for sync
- [ ] Custom field values sanitized to prevent stored XSS
- [ ] Audit log: every record update logs previous value, new value, actor, and timestamp
- [ ] Bulk import validates and rejects records with dangerous content (formula injection in CSV)
- [ ] API rate limiting per user to prevent scraping of the full contact database
- [ ] MFA enforced for Admin role
- [ ] GDPR: contact deletion cascade removes all PII from timeline, notes, and email copies

## Testing Checklist
- [ ] Role access matrix tested: Rep cannot read another rep's contacts; Manager can; Admin can
- [ ] Email sync: new email to known contact appears on timeline within sync interval
- [ ] Email association: email matched to contact by To/From/CC address, not just subject
- [ ] Pipeline value aggregation correct for deals with null close dates or probability overrides
- [ ] CSV import: duplicate detection (by email), error rows reported, valid rows imported atomically
- [ ] Task overdue alert fires after due date; does not fire for completed tasks
- [ ] Full-text search returns contacts matching name, email, company, and notes
- [ ] Bulk reassign: correctly updates owner on all selected records; audit entries created

## Deployment Checklist
- [ ] Gmail / Outlook OAuth app reviewed and approved for production use (not just dev credentials)
- [ ] Email sync background job runs on a separate worker; rate-limited to respect Gmail API quota
- [ ] Database indexes on `contacts(owner_id)`, `deals(stage, owner_id)`, `activities(contact_id, created_at)`
- [ ] Full-text search index rebuilt on deployment if schema changed
- [ ] Attachment storage bucket private; presigned URLs with expiry used for file access
- [ ] GDPR data export endpoint implemented before launch (right to access)
- [ ] GDPR deletion endpoint tested end-to-end (hard delete, not soft delete for PII)
- [ ] Monitoring: email sync job lag, pipeline report query time, API p99 latency

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [twentyhq/twenty](https://github.com/twentyhq/twenty) | Open-source CRM built with React + NestJS + PostgreSQL, modern Salesforce alternative | ✅ Best pick |
| [Automattic/wp-calypso](https://github.com/Automattic/wp-calypso) | Large-scale React + Node production application reference | |
| [supabase/supabase/examples](https://github.com/supabase/supabase/tree/master/examples) | Supabase-based CRM and data patterns | |

**Best Pick:** [twentyhq/twenty](https://github.com/twentyhq/twenty) — 7k+ stars, complete CRM features (contacts, deals, pipeline, timeline), well-architected with React and NestJS

## Reference Repositories
- [twentyhq/twenty](https://github.com/twentyhq/twenty) — Open-source CRM built with React and NestJS; excellent reference for data model and pipeline UI
- [cortezaproject/corteza](https://github.com/cortezaproject/corteza) — Open-source low-code CRM/business platform with strong role/permission model
- [frappe/crm](https://github.com/frappe/crm) — Open-source CRM by Frappe; clean pipeline and activity timeline implementation
- [twentyhq/twenty](https://github.com/twentyhq/twenty) — open-source CRM built with React + NestJS + GraphQL, 7k+ stars — **best pick**
- [erxes/erxes](https://github.com/erxes/erxes) — open-source CRM + marketing automation platform

## Official Documentation
- [Gmail API Docs](https://developers.google.com/gmail/api/guides) — OAuth scopes, message threading, push notifications via Pub/Sub
- [Twenty CRM Docs](https://twenty.com/developers) — Open-source CRM developer documentation
- [Supabase Row Level Security](https://supabase.com/docs/guides/auth/row-level-security) — Multi-tenant data isolation patterns
- [Microsoft Graph Mail API](https://learn.microsoft.com/en-us/graph/api/resources/mail-api-overview) — Outlook email sync, delta queries
- [Nylas Email API](https://developer.nylas.com/docs/email/) — Unified email API abstracting Gmail and Outlook
- [TanStack Table](https://tanstack.com/table/latest/docs/introduction) — Headless table with sorting, filtering, virtualization for contact lists
- [Twenty CRM Docs](https://twenty.com/developers) — open-source CRM developer documentation
- [HubSpot CRM API](https://developers.hubspot.com/docs/api/crm/crm-overview) — industry-standard CRM API reference
