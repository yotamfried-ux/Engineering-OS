# Data Frameworks & Platforms

## Overview
Consult this guide when designing a data pipeline, ETL/ELT workflow, or streaming architecture. Understand the layer distinctions before choosing tools — these frameworks operate at different levels and are often used together.

**Layer map:**
- **Orchestration** (schedule, coordinate, monitor pipelines): Airflow, Dagster, Prefect
- **Transformation** (SQL/Python-based data modeling in the warehouse): dbt
- **Batch processing** (large-scale distributed compute): Apache Spark
- **Streaming ingestion/messaging** (event bus, real-time data): Kafka
- **Stream processing** (stateful real-time compute on streams): Flink

**Decision heuristic:**
- Need to schedule + monitor a DAG of jobs → Airflow (established) or Dagster (modern, asset-based) or Prefect (lightweight)
- Transform data already in a warehouse → dbt
- Terabyte-scale batch ETL or ML feature engineering → Spark
- High-throughput event bus between services → Kafka
- Real-time stateful stream computation → Flink

## Frameworks

### Apache Airflow
**Type:** Orchestration  
**Language:** Python  
**Best For:** Scheduling and monitoring complex DAG-based pipelines in mature, large-scale data organizations  
**Official Docs:** https://airflow.apache.org/docs/  
**GitHub:** https://github.com/apache/airflow  
**Key Strengths:**
- Massive ecosystem of providers (500+ integrations with cloud services, databases, APIs)
- Battle-tested in production at thousands of companies
- Rich UI for DAG visualization, task logs, and backfill management
- Strong community and long track record since 2014
**Watch Out For:**
- DAG-centric model (not asset-centric) makes lineage tracking harder
- Local development and testing experience is cumbersome compared to newer tools
- Scheduler can become a bottleneck at very high task volumes
- Dynamic DAG generation is possible but verbose and error-prone

---

### Dagster
**Type:** Orchestration  
**Language:** Python  
**Best For:** Modern data platforms that prioritize software engineering practices, asset lineage, and developer experience  
**Official Docs:** https://docs.dagster.io/  
**GitHub:** https://github.com/dagster-io/dagster  
**Key Strengths:**
- Asset-centric model: pipelines are defined around data assets, not just task execution order
- First-class data lineage and dependency graph across the full platform
- Excellent local development experience with fast feedback loops
- Built-in support for partitioning, incremental materialization, and freshness policies
- Strong typing and integrated testing primitives
**Watch Out For:**
- Smaller ecosystem than Airflow; fewer out-of-the-box integrations
- Steeper learning curve for teams unfamiliar with the asset paradigm
- Dagster+ (managed cloud) adds cost; self-hosted setup requires more operational effort than Prefect

---

### Prefect
**Type:** Orchestration  
**Language:** Python  
**Best For:** Teams that want fast setup, Pythonic workflow definitions, and minimal infrastructure overhead  
**Official Docs:** https://docs.prefect.io/  
**GitHub:** https://github.com/PrefectHQ/prefect  
**Key Strengths:**
- Extremely low friction to get started — workflows are plain Python decorated functions
- Prefect Cloud managed option simplifies operations significantly
- Dynamic, data-driven workflows are natural (no static DAG requirement)
- Good observability UI with flow run history and alerting
- Hybrid execution model: orchestration in cloud, compute stays on your infrastructure
**Watch Out For:**
- Less mature than Airflow for very large-scale, complex dependency graphs
- Asset-centric model is partial/newer compared to Dagster
- Smaller provider/integration library than Airflow; custom connectors often needed
- Prefect 2.x (Orion) was a full rewrite — older Prefect 1.x content is outdated

---

### dbt (data build tool)
**Type:** Transformation  
**Language:** SQL (with Python model support in dbt 1.3+)  
**Best For:** Transforming raw data already loaded into a data warehouse into clean, analytics-ready models  
**Official Docs:** https://docs.getdbt.com/  
**GitHub:** https://github.com/dbt-labs/dbt-core  
**Key Strengths:**
- Brings software engineering practices (version control, testing, documentation) to SQL transformations
- Auto-generates data lineage DAG from model `ref()` dependencies
- Built-in testing framework for data quality assertions
- Seamless integration with major warehouses: BigQuery, Snowflake, Redshift, DuckDB, Databricks
- dbt Cloud adds scheduling, CI/CD, and IDE; dbt Core is fully open-source
**Watch Out For:**
- dbt only transforms — it does not ingest or move data (pair with EL tools like Fivetran, Airbyte, or Spark)
- Pure SQL approach can feel limiting for complex Python-based transformations (Python models help but have adapter restrictions)
- Large dbt projects with hundreds of models can have slow compile/run times without incremental strategies
- Requires data to already be in the target warehouse before dbt can operate on it

---

### Apache Spark
**Type:** Batch processing  
**Language:** Python (PySpark), Scala, Java, R, SQL  
**Best For:** Terabyte-to-petabyte scale distributed data processing, ETL, and ML feature engineering  
**Official Docs:** https://spark.apache.org/docs/latest/  
**GitHub:** https://github.com/apache/spark  
**Key Strengths:**
- Distributed in-memory processing handles datasets that don't fit on a single machine
- Unified engine: batch ETL, SQL queries, ML (MLlib), and structured streaming in one framework
- Runs on all major cloud platforms (EMR, Dataproc, Databricks, HDInsight)
- Catalyst optimizer and Tungsten execution engine provide strong SQL performance
- Broad language support makes it accessible to both data engineers and data scientists
**Watch Out For:**
- High operational complexity — cluster tuning, memory management, and partitioning require expertise
- Overkill for datasets under ~100GB that fit in a single machine (DuckDB or pandas are simpler)
- Spark Streaming (micro-batch) adds latency; true low-latency streaming belongs in Flink
- Cold start times make it poorly suited for lightweight, frequent jobs
- Databricks is the dominant managed offering; self-managed clusters are operationally expensive

---

### Apache Kafka
**Type:** Streaming ingestion / event bus  
**Language:** Java/Scala (clients available in all major languages)  
**Best For:** High-throughput, durable, fault-tolerant event streaming and decoupling between services  
**Official Docs:** https://kafka.apache.org/documentation/  
**GitHub:** https://github.com/apache/kafka  
**Key Strengths:**
- Handles millions of events per second with sub-10ms latency at scale
- Durable log-based storage: consumers can replay events and multiple consumers read independently
- Strong ecosystem: Kafka Connect for ingestion, Kafka Streams for lightweight stream processing
- De facto standard event bus in microservices and data platform architectures
- Managed offerings: Confluent Cloud, Amazon MSK, Redpanda (Kafka-compatible)
**Watch Out For:**
- Operational complexity is high for self-managed clusters (ZooKeeper/KRaft, replication, retention tuning)
- Not a database — Kafka is a log, not a query engine; combine with a stream processor (Flink) or sink (Snowflake, Elasticsearch) for querying
- Small-scale use cases (low event volume, single service) may be better served by simpler queues (SQS, RabbitMQ)
- Schema management requires additional tooling (Schema Registry) to avoid data contract drift

---

### Apache Flink
**Type:** Stream processing  
**Language:** Java, Scala, Python (PyFlink), SQL  
**Best For:** Stateful real-time stream processing, event-time windowing, and complex event pattern detection  
**Official Docs:** https://nightlies.apache.org/flink/flink-docs-stable/  
**GitHub:** https://github.com/apache/flink  
**Key Strengths:**
- True streaming engine (not micro-batch): processes events one at a time with millisecond latency
- Sophisticated state management with exactly-once semantics and fault-tolerant checkpointing
- First-class event-time processing and out-of-order event handling via watermarks
- Native integration with Kafka as both source and sink
- Flink SQL makes stream processing accessible without Java/Scala expertise
**Watch Out For:**
- Steep learning curve, especially for stateful operators, watermarks, and checkpointing configuration
- Operationally complex to run and tune at scale (memory management, parallelism, state backend choice)
- PyFlink lags behind the Java API in features and performance
- For simple streaming use cases, Kafka Streams or KSQL may be sufficient without deploying a full Flink cluster
- Managed options exist (Amazon Kinesis Data Analytics for Flink, Ververica Platform) but add cost

---

## Data Stack Layer Reference

| Layer | Tools | Trigger | Latency |
|---|---|---|---|
| Orchestration | Airflow, Dagster, Prefect | Schedule / event | Minutes–hours |
| Batch processing | Spark | Orchestrator | Minutes–hours |
| Transformation | dbt | Orchestrator / CLI | Minutes |
| Streaming ingest | Kafka | Continuous | Milliseconds |
| Stream processing | Flink | Continuous | Milliseconds–seconds |

## Orchestrator Comparison

| Criterion | Airflow | Dagster | Prefect |
|---|---|---|---|
| Maturity | High | Medium | Medium |
| Asset-centric model | ✗ | ✓ | partial |
| UI/observability | good | excellent | good |
| Local dev experience | moderate | excellent | excellent |
| Self-host complexity | high | medium | low |
| Managed cloud option | MWAA, Astro | Dagster+ | Prefect Cloud |
