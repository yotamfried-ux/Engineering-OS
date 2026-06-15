# Admin Dashboard Template

## Overview
Use this template for internal backoffice and operations tools — platforms where staff manage users, orders, content, or system state. Suited for product and operations teams who need rich data tables, bulk operations, charts, and a complete audit trail without building a public-facing product. The primary concerns are access control (wrong person sees or deletes wrong data), performance of large table queries, and safety of bulk operations.

## Recommended Architecture Options
- **Admin panel as a module in the main app** — Fast to build; shares models and auth; risk of leaking admin routes to public if misconfigured; only for small teams.
- **Separate admin app with shared DB read replica** — Clear isolation; admin queries hit replica, not primary; separate deploy surface; recommended for most cases.
- **Low-code admin builder (Retool, Appsmith, Refine)** — Fastest to ship; limited customization; appropriate when internal tooling is not a core competency.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Framework | Refine (React), AdminJS, Retool, Appsmith, custom Next.js |
| UI components | shadcn/ui + TanStack Table, Ant Design, MUI DataGrid |
| Charts | Recharts, Tremor, Apache ECharts |
| Backend | REST API or tRPC over existing app models |
| Database | PostgreSQL (primary) + read replica for heavy queries |
| Export | csv-writer, ExcelJS, PDF (Puppeteer / react-pdf) |
| Auth | Existing app SSO (Auth0, Okta, Supabase) + admin role claim |
| Background jobs | BullMQ / Sidekiq for bulk operations and report generation |

## Required Components
- Data tables: server-side pagination, column sorting, multi-column filtering, column visibility toggle
- Global search: full-text across primary entities (users, orders, etc.)
- Row-level actions: view detail, edit inline or in drawer, soft-delete with confirmation prompt
- Bulk operations: select-all (page or full result set), bulk approve/reject/delete/export with confirmation
- CSV / XLSX export: respects current filters; streams large exports via background job + download link
- Role-based access: SuperAdmin, Admin, Support, Viewer — enforced server-side, not just UI-hidden
- Audit log table: actor, action, entity type, entity ID, before/after diff, timestamp, IP; append-only
- Charts / KPI cards: configurable date range; revenue, signups, churn, active users; auto-refresh
- Impersonation: SuperAdmin can act as any user (for support); every impersonated action logged
- Settings panel: feature flags, system configuration values editable without a deploy
- Notification center: alert ops team on anomalies (spike in errors, fraud signals, payment failures)

## Security Checklist
- [ ] Admin app served on a separate subdomain (`admin.example.com`), not a path of the public app
- [ ] Access restricted by IP allowlist (office VPN / Cloudflare Access) in addition to auth
- [ ] MFA enforced for all admin accounts — no exceptions
- [ ] Every server-side endpoint re-validates the role claim; never trust client-side role check alone
- [ ] Impersonation: session clearly marked as impersonated; exit impersonation removes marker
- [ ] Audit log is append-only — no UPDATE or DELETE permissions on audit table for app role
- [ ] Bulk delete requires two-step confirmation with typed entity name or count
- [ ] Exported files do not include columns the requester's role cannot read
- [ ] Admin sessions expire after 4 hours of inactivity (shorter than standard user sessions)
- [ ] Rate limit on search and export endpoints to prevent data exfiltration

## Testing Checklist
- [ ] Role matrix: Viewer cannot trigger write actions; Support cannot access billing data; Admin cannot access SuperAdmin actions
- [ ] Pagination: page 2 returns correct records when filters are applied; total count matches
- [ ] Bulk export: 100,000-row export completes without timeout; file is valid XLSX
- [ ] Audit log: every tested write action produces an audit entry with correct before/after diff
- [ ] Impersonation: actions taken while impersonating are attributed to the impersonated user in product logs, but to the admin in audit logs
- [ ] Chart date-range filter: KPIs match a direct SQL count for the same period
- [ ] Soft-delete: deleted record disappears from default table view; appears when "show deleted" toggled
- [ ] Feature flag toggle: change takes effect without a redeploy; previous value visible in audit log

## Deployment Checklist
- [ ] Admin subdomain not indexed by search engines (`X-Robots-Tag: noindex` + `robots.txt`)
- [ ] Cloudflare Access or equivalent zero-trust layer in front of admin subdomain
- [ ] Database read replica used for all SELECT queries; write queries target primary
- [ ] Slow-query log enabled on replica; indexes added for all filtered/sorted columns
- [ ] Background job worker for bulk operations deployed separately with concurrency limit
- [ ] Audit log table on a separate schema / DB with no delete grants for the app role
- [ ] Monitoring: admin 5xx rate, bulk job queue depth, slow queries > 2 s
- [ ] Disaster recovery drill: restore audit log from backup; verify append-only constraint

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [refinedev/refine](https://github.com/refinedev/refine) | Open-source Retool/internal tool framework: data grids, CRUD, auth, any data source | ✅ Best pick |
| [marmelab/react-admin](https://github.com/marmelab/react-admin) | React Admin framework with 250+ components for data-driven apps | |
| [shadcn-ui/ui](https://github.com/shadcn-ui/ui) | shadcn/ui dashboard example as a starting point | |

**Best Pick:** [refinedev/refine](https://github.com/refinedev/refine) — 30k+ stars, enterprise features (RBAC, audit log, data providers), actively maintained

## Reference Repositories
- [refinedev/refine](https://github.com/refinedev/refine) — Open-source React admin framework; data providers, CRUD, auth integration
- [marmelab/react-admin](https://github.com/marmelab/react-admin) — Mature React admin framework with extensive component library and data provider pattern
- [appsmithorg/appsmith](https://github.com/appsmithorg/appsmith) — Open-source low-code internal tool builder; self-hostable

## Official Documentation
- [Refine Documentation](https://refine.dev/docs/) — Data providers, auth, access control, table and form components
- [TanStack Table](https://tanstack.com/table/latest/docs/introduction) — Server-side pagination, sorting, filtering for custom admin tables
- [Tremor Components](https://www.tremor.so/docs/getting-started/installation) — Charts and KPI card components for React dashboards
- [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/policies/access/) — Zero-trust access for internal tools
- [React Admin Docs](https://marmelab.com/react-admin/documentation.html) — Data-driven admin framework with 250+ components
