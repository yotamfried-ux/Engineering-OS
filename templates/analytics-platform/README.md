# Analytics Platform Template

## Overview
Use this template for data analytics platforms where business users, analysts, and data scientists query, visualize, and report on large datasets. Suited for product analytics, business intelligence, and operational reporting tools that need a scalable data warehouse backend, row-level security, scheduled report delivery, and freshness SLAs. The central challenges are query performance at scale, access control that prevents analysts from seeing data outside their scope, and keeping dashboards up-to-date without overloading the warehouse.

## Recommended Architecture Options
- **Managed warehouse + BI tool** — BigQuery / Snowflake / Redshift + Metabase / Looker / Superset; fastest time-to-value; BI tool handles dashboarding; warehouse handles compute; limited custom UX.
- **Warehouse + dbt + embedded charts in product** — dbt defines semantic layer (metrics, dimensions); product queries via a headless BI API (Cube, Lightdash) or direct warehouse; full UX control; higher engineering cost.
- **Streaming analytics** — Kafka → ClickHouse or Apache Pinot for sub-second freshness; suited for real-time ops dashboards; higher infrastructure complexity.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Data warehouse | BigQuery, Snowflake, Redshift, DuckDB (small scale), ClickHouse (real-time) |
| Transformation | dbt Core / dbt Cloud |
| BI / visualization | Metabase, Apache Superset, Looker, Lightdash, Grafana (for ops metrics) |
| Embedded charts | Recharts, Apache ECharts, Observable Plot, Vega-Lite |
| Orchestration | Airflow, Dagster, dbt Cloud scheduler |
| Semantic layer / API | Cube.dev, Lightdash, dbt Metrics |
| Data catalog | DataHub, Atlan, dbt docs |
| Access control | Snowflake row-access policies, BigQuery column-level security, Cube RBAC |
| Caching | Redis (query result cache), Cube Store, Materialized views in warehouse |
| Alerting | Metabase alerts, Grafana alerting, custom scheduler + email/Slack |

## Required Components
- Data ingestion: raw data lands in a staging layer (S3 / GCS / warehouse stage) from source connectors
- Transformation pipeline: dbt models in layers — staging (rename/cast), intermediate (joins/deduplication), mart (aggregated fact and dimension tables for reporting)
- Semantic layer: named metrics and dimensions with consistent definitions; prevents "which revenue number is right?" debates
- Query engine: warehouse executes SQL; results cached for repeated identical queries; query timeout enforced (e.g., 60 s for interactive, 3 h for scheduled)
- Dashboard builder: drag-and-drop charts (bar, line, pie, table, funnel, cohort); filter bar applies to all charts; drill-down from summary to detail
- Access control: users assigned to data groups; row-level filter appended to every query for their group; column-level masking for PII (e.g., email shown only to admin role)
- Scheduled reports: run dashboard or saved query on cron; deliver results via email (PDF/CSV) or Slack; log delivery status
- Data freshness SLA: every dashboard shows data-as-of timestamp; alert if source data not updated within SLA window (e.g., 4 h for daily, 15 min for near-real-time)
- Data catalog / lineage: dbt docs or DataHub shows model lineage, column descriptions, test coverage; linked from every dashboard
- Anomaly detection: automated alerts when a metric moves more than N standard deviations from its rolling baseline

## Security Checklist
- [ ] Row-level security enforced at warehouse query time, not just BI tool filter — bypass via direct SQL must also be blocked
- [ ] PII columns (email, name, phone) masked or excluded for roles that don't require them; masking enforced at warehouse column policy level
- [ ] Service account used by BI tool has only `SELECT` on mart schema; no access to staging or raw layers
- [ ] Scheduled report emails delivered only to verified internal email addresses; no external forwarding
- [ ] Query result cache keyed by role — user A's cached result not served to user B if row-level filter differs
- [ ] Warehouse credentials in secret manager; rotated quarterly
- [ ] Data export restricted by role; bulk exports > N rows require manager approval
- [ ] Audit log: every dashboard view, query, and export logged with user, timestamp, and row count returned

## Testing Checklist
- [ ] dbt tests: `not_null`, `unique`, `accepted_values`, `relationships` on all mart models; run in CI on every PR
- [ ] Metric consistency: same metric queried via BI tool, semantic layer API, and direct SQL returns same value for the same time range
- [ ] Row-level security: user in group A cannot see rows belonging to group B via any query path
- [ ] Scheduled report: fires on schedule; PDF is valid and non-empty; delivery logged; failure triggers alert
- [ ] Data freshness alert: pause source ingestion and verify alert fires within expected window
- [ ] Query performance: p95 dashboard load < 5 s with production data volume (test with EXPLAIN ANALYZE)
- [ ] Cache invalidation: after dbt model rebuild, stale cache entries are purged; next query returns fresh results

## Deployment Checklist
- [ ] dbt project deployed via CI on merge to main; no manual `dbt run` in production
- [ ] dbt tests run in CI; build fails if any test fails on the mart layer
- [ ] Warehouse compute cluster auto-scaled (Snowflake warehouse suspend/resume, BigQuery slots reservation) to control cost
- [ ] Query cost budget alerts configured at warehouse level (BigQuery budget alert, Snowflake spend alert)
- [ ] Materialized views / incremental dbt models used for large fact tables to reduce full-scan cost
- [ ] Data freshness SLA documented per model in dbt `meta`; monitoring dashboard linked from runbook
- [ ] BI tool upgraded in a test environment before production; dashboard regressions checked
- [ ] Disaster recovery: warehouse point-in-time recovery tested; dbt project in version control is source of truth

## Reference Repositories
- [dbt-labs/jaffle-shop](https://github.com/dbt-labs/jaffle-shop) — Reference dbt project showing staging/intermediate/mart layer pattern
- [apache/superset](https://github.com/apache/superset) — Open-source BI tool with RBAC, SQL Lab, and dashboard builder
- [lightdash/lightdash](https://github.com/lightdash/lightdash) — Open-source BI tool built on dbt; uses dbt models as the semantic layer directly

## Official Documentation
- [dbt Documentation](https://docs.getdbt.com/) — Project structure, models, tests, metrics, CI integration
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs) — Partitioning, clustering, row-level security, column-level masking
- [Snowflake Row Access Policies](https://docs.snowflake.com/en/user-guide/security-row-using) — Policy-based row filtering at query time
- [Cube.dev Documentation](https://cube.dev/docs) — Semantic layer, caching, RBAC, API for embedded analytics
- [Dagster Documentation](https://docs.dagster.io/) — Data orchestration with asset-based lineage and dbt integration
