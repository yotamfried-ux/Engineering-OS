# Data Pipeline / ETL Template

## Overview
Use this template for systems that ingest data from multiple sources, transform it, and load it into a destination store — data warehouses, lakes, or analytical databases. Covers batch ETL, streaming pipelines, and reverse-ETL workflows where data movement, quality, and scheduling are the primary concerns.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| dbt + Airflow + warehouse (BigQuery/Snowflake) | Industry standard, SQL-native, great lineage | Warehouse cost at scale; Airflow needs infra |
| dbt + Dagster | Modern orchestration with asset-based thinking, great DX | Smaller community than Airflow |
| Airbyte + dbt + Metabase | Low-code ingestion, fast to stand up | Less control over custom connectors |
| Python + Prefect + DuckDB (lightweight) | Minimal infra, excellent for small-medium data | DuckDB not suited for concurrent writes at scale |

## Recommended Frameworks & Platforms

- **Language:** Python 3.12+, SQL
- **Transformation:** dbt Core or dbt Cloud
- **Orchestration:** Dagster, Prefect, or Apache Airflow 2.x
- **Ingestion:** Airbyte (managed connectors), Singer taps, or custom Python extractors
- **Warehouse/destination:** BigQuery, Snowflake, or Redshift; DuckDB for local/small-scale
- **Streaming:** Apache Kafka + Flink, or Redpanda + Materialize for real-time
- **Data quality:** Great Expectations or dbt tests
- **Catalog/lineage:** OpenMetadata, DataHub, or dbt docs
- **Storage (lake):** AWS S3, GCS, or Cloudflare R2 + Apache Parquet/Delta Lake
- **Secrets:** HashiCorp Vault, AWS Secrets Manager, or Doppler

## Required Components

- Idempotent pipelines: re-running a job produces the same result (no duplicate rows)
- Incremental load strategy: full refresh only when necessary
- Schema change detection and alerting
- Data quality checks at ingestion and after transformation
- Source-to-destination lineage documentation
- Dead-letter queue or error table for records that fail validation
- Job metadata logging: run time, rows processed, rows failed, duration
- Alerting on pipeline failure, SLA breach, and data quality failures

## Security Checklist

- [ ] Source credentials stored in secrets manager — not in DAG code or environment files committed to repo
- [ ] Warehouse access uses service accounts with least-privilege (read-only on source, write only to target schema)
- [ ] PII fields identified in data catalog and masked or tokenized before loading into analytics layer
- [ ] Network access to warehouse restricted by IP allowlist or VPC peering
- [ ] Audit log enabled on warehouse to track who queried or modified data
- [ ] dbt project does not contain raw credentials or connection strings in `profiles.yml` committed to repo

## Testing Checklist

- [ ] dbt tests: `not_null`, `unique`, `accepted_values`, and `relationships` on all key columns
- [ ] Custom data quality tests for business rules (e.g., revenue never negative)
- [ ] Integration test: full pipeline run against a test dataset in a staging environment
- [ ] Idempotency test: run the pipeline twice with the same source data and verify no duplicates
- [ ] Schema drift test: pipeline detects and handles an unexpected new column in source
- [ ] Volume anomaly check: alert fires when row count deviates significantly from historical average

## Deployment Checklist

- [ ] All source and destination credentials in secrets manager; `.env` not committed
- [ ] Staging environment mirrors production schema and is used for all pipeline testing
- [ ] CI pipeline runs dbt compile + dbt test on every pull request
- [ ] Backfill strategy documented and tested before first production run
- [ ] Schedule defined in orchestrator with retry policy and alerting on failure
- [ ] Warehouse partitioning and clustering configured for cost optimization
- [ ] Data retention and deletion policy implemented (GDPR / CCPA compliance)

## Reference Repositories

- [dbt-labs/jaffle_shop](https://github.com/dbt-labs/jaffle_shop) — canonical dbt project structure and testing patterns
- [dagster-io/dagster](https://github.com/dagster-io/dagster) — asset-based orchestration examples
- [airbytehq/airbyte](https://github.com/airbytehq/airbyte) — connector catalog and custom connector development

## Official Documentation

- [dbt Docs](https://docs.getdbt.com) — models, tests, sources, lineage
- [Dagster Docs](https://docs.dagster.io) — assets, jobs, schedules, sensors
- [Airflow Docs](https://airflow.apache.org/docs/) — DAG authoring, operators, connections
- [Great Expectations Docs](https://docs.greatexpectations.io) — data quality suites and checkpoints
- [Apache Kafka Docs](https://kafka.apache.org/documentation/) — streaming architecture reference
