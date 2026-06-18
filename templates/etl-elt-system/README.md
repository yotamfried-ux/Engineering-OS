# ETL/ELT System Template

## Overview
Use this template for data integration pipelines that move and transform data between source systems and a destination (data warehouse, data lake, or operational database). Suited for engineering teams building internal data infrastructure, reverse ETL to sync warehouse data back to operational tools, and data quality monitoring. The critical concerns are idempotency (safe to re-run on failure), handling schema drift in sources, enforcing data quality before data reaches consumers, and making failures observable and recoverable without manual intervention.

## Recommended Architecture Options
- **ELT with managed connectors + dbt** — Use Fivetran or Airbyte for extraction and loading; dbt for transformation in the warehouse; fastest to production; lower control over source connectors; best for standard SaaS sources (Salesforce, Stripe, PostgreSQL).
- **Custom ELT pipeline (Python + Airflow/Dagster)** — Full control over extraction logic, incremental loading, and transformation; required for non-standard sources or complex business rules that don't fit dbt; higher maintenance burden.
- **Streaming ELT (Kafka + Flink/Spark Streaming)** — Sub-minute latency; required for real-time analytics or fraud detection; complex infrastructure; use only when batch (hourly/daily) freshness is insufficient.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Orchestration | Apache Airflow, Dagster, Prefect, Temporal |
| Managed connectors | Fivetran, Airbyte (self-hosted or cloud), Stitch |
| Custom extraction | Python (pandas, SQLAlchemy, requests), Singer taps |
| Transformation | dbt Core / dbt Cloud, Apache Spark, DuckDB |
| Destination warehouse | BigQuery, Snowflake, Redshift, ClickHouse |
| Data lake / staging | AWS S3, GCS, Azure Data Lake (Parquet / Delta Lake) |
| Data quality | Great Expectations, Soda, dbt tests |
| Schema registry | AWS Glue, Confluent Schema Registry (for streaming) |
| Streaming | Apache Kafka, AWS Kinesis, Apache Flink, Spark Structured Streaming |
| Reverse ETL | Census, Hightouch |

## Required Components
- Source connectors: extract data from source (API, database CDC, file); emit records with a watermark (updated_at or offset) for incremental loads
- Incremental load pattern: track last successful watermark per source table; extract only records changed since that watermark; upsert into destination using surrogate key
- Idempotency guarantee: every pipeline run can be re-run for the same time window without creating duplicates; use `INSERT ... ON CONFLICT DO UPDATE` or `MERGE`
- Schema evolution handling: detect added/removed/type-changed columns in source; alert on breaking changes; auto-migrate for additive changes (new nullable column)
- Data quality checks: row count validation, null rate, value range, referential integrity, freshness; run after load, before downstream models are refreshed
- Transformation layer: dbt models apply business logic, deduplication, and enrichment; models organized in staging → intermediate → mart layers
- Backfill mechanism: re-extract and reload a historical date range without disrupting the live pipeline; isolated from incremental runs
- Dead-letter storage: records that fail parsing, validation, or loading written to a quarantine table with error reason; surfaced in a monitoring dashboard
- Pipeline metadata store: per-run log of source, destination, records extracted, records loaded, records rejected, duration, status, watermark; queryable for auditing
- Alerting: pipeline failure, data quality check failure, freshness SLA breach — routed to Slack / PagerDuty with enough context to triage without log access

## Security Checklist
- [ ] Source credentials (DB passwords, API keys) stored in secret manager; rotated on schedule; never in DAG code or environment files
- [ ] Database replication user has only `SELECT` and `REPLICATION` grants; no write access to source
- [ ] Data in transit encrypted (TLS for API sources, SSL for DB connections, encrypted S3 transfer)
- [ ] PII columns identified in catalog; masked or excluded in staging models before reaching analysts
- [ ] Access to raw / staging layer restricted to pipeline service account; analysts access only mart layer
- [ ] Audit log: every pipeline run, backfill, and schema migration logged with actor and timestamp
- [ ] Staging files in S3/GCS encrypted at rest; lifecycle policy deletes raw files after N days
- [ ] Webhook sources (e.g., Stripe, Shopify) verify payload signature before ingesting

## Testing Checklist
- [ ] Idempotency test: run the same pipeline twice for the same window; row count in destination is identical both times
- [ ] Incremental correctness: insert a record in source with an old `updated_at`; confirm it is not re-loaded on the next incremental run
- [ ] Schema drift: add a nullable column to source; confirm pipeline does not fail; column appears in destination after next run
- [ ] Breaking schema change: rename a column in source; confirm alert fires and pipeline halts rather than silently loading NULLs
- [ ] Data quality: inject a row violating a not-null check; confirm it lands in dead-letter table with the correct error code
- [ ] Backfill isolation: running a backfill for 2023-01 does not affect the live incremental watermark for 2024
- [ ] dbt tests pass on mart models after a full pipeline run on a production-scale data sample
- [ ] Freshness SLA: pause source and verify alert fires within the expected SLA window

## Deployment Checklist
- [ ] Airflow/Dagster deployed with separate workers for extraction (I/O-bound) and transformation (compute-bound)
- [ ] DAGs / jobs version-controlled; deployed via CI on merge to main; no manual DAG edits in production UI
- [ ] Backfill DAGs / ops isolated from live pipeline; separate pool/queue to avoid starving incremental runs
- [ ] Dead-letter table monitored; non-zero count triggers alert within 15 minutes
- [ ] Warehouse compute costs monitored per pipeline job (BigQuery slot usage, Snowflake credit consumption)
- [ ] Schema migration scripts version-controlled in dbt or Alembic; applied before pipeline runs that depend on them
- [ ] Disaster recovery: document procedure to re-extract full history from each source; retention policy on source allows it
- [ ] Data catalog updated automatically on schema change (DataHub lineage API, dbt docs publish)

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [airbytehq/airbyte](https://github.com/airbytehq/airbyte) | Open-source ELT platform with 300+ connectors to data warehouses | ✅ Best pick |
| [dbt-labs/dbt-core](https://github.com/dbt-labs/dbt-core) | SQL-based data transformation with testing and documentation | |
| [great-expectations/great_expectations](https://github.com/great-expectations/great_expectations) | Data quality validation and pipeline testing framework | |

**Best Pick:** [airbytehq/airbyte](https://github.com/airbytehq/airbyte) — most complete ELT reference platform, 16k+ stars, 300+ source connectors, handles ingestion to any data warehouse

## Reference Repositories
- [dbt-labs/jaffle-shop](https://github.com/dbt-labs/jaffle-shop) — Canonical dbt project showing staging/intermediate/mart conventions and testing patterns
- [airbytehq/airbyte](https://github.com/airbytehq/airbyte) — Open-source EL platform with 300+ connectors; study connector development for custom sources
- [apache/airflow](https://github.com/apache/airflow) — Workflow orchestration; DAG patterns, dynamic task mapping, XCom for watermarks
- [dagster-io/dagster](https://github.com/dagster-io/dagster) — Asset-based orchestration with lineage, partitions, and data quality checks built in
- [meltano/meltano](https://github.com/meltano/meltano) — CLI-driven ELT with Singer ecosystem, config-as-code
- [meltano/sdk](https://github.com/meltano/sdk) — Singer tap/target SDK for building custom ELT connectors
- [dlt-hub/dlt](https://github.com/dlt-hub/dlt) — Python ELT library, no infrastructure required
- [dlt-hub/verified-sources](https://github.com/dlt-hub/verified-sources) — 50+ maintained dlt source templates

## Official Documentation
- [dbt Documentation](https://docs.getdbt.com/) — Incremental models, snapshots (SCD Type 2), generic tests, sources and freshness
- [Airbyte Documentation](https://docs.airbyte.com/) — Connector catalog, incremental sync modes, schema change handling
- [Apache Airflow Documentation](https://airflow.apache.org/docs/) — DAG authoring, pools, sensors, backfill, dynamic task mapping
- [Great Expectations Docs](https://docs.greatexpectations.io/) — Data quality expectations, checkpoints, data docs
- [Dagster Documentation](https://docs.dagster.io/) — Software-defined assets, partitions, schedules, sensors, dbt integration
- [Airbyte Docs](https://docs.airbyte.com) — open-source ELT connectors and orchestration
- [dbt Docs](https://docs.getdbt.com) — data transformation layer
- [Apache Spark Docs](https://spark.apache.org/docs/latest/) — large-scale data processing
- [Meltano Docs](https://docs.meltano.com) — CLI-driven ELT platform
- [dlt Docs](https://dlthub.com/docs) — Python ELT library documentation
- [Singer Specification](https://hub.meltano.com/singer/spec) — tap/target protocol standard
