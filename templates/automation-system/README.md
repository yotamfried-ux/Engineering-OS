# Automation / Workflow System Template

## Overview
Use this template for systems driven by schedules, events, or external triggers — not by user interaction. Covers cron-based automation, webhook-driven workflows, integration glue between SaaS products, and background job systems where reliability, idempotency, and observability are critical.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Python scripts + APScheduler / cron | Simple, zero dependencies for basic schedules | No visibility, no retries, hard to scale |
| Temporal (workflows as code) | Durable execution, retries, versioning, replay | Infra overhead; learning curve |
| BullMQ (Node + Redis) | Fast, reliable job queue with priorities and retries | Redis dependency; no long-running workflow state |
| n8n / Zapier / Make (low-code) | Fast for simple integrations; non-technical maintainers | Limited custom logic; can hit rate/plan limits |

## Recommended Frameworks & Platforms

- **Language:** TypeScript/Node.js (event-driven) or Python (scripting/ML-adjacent)
- **Job queue:** BullMQ (Node + Redis) or Celery (Python + Redis/RabbitMQ)
- **Durable workflows:** Temporal, or Inngest (managed Temporal-like)
- **Scheduling:** cron via APScheduler, node-cron, or Temporal schedules
- **Webhook handling:** Svix (managed webhook delivery), or custom endpoint with HMAC verification
- **Event bus:** Redis Pub/Sub, AWS EventBridge, or Google Pub/Sub
- **Integrations:** Zapier/n8n for SaaS glue; custom code for complex logic
- **Hosting:** Railway, Fly.io, or AWS Lambda (for event-triggered, short-lived functions)
- **Observability:** Pino/Winston (logging), Sentry (error tracking), BullMQ Bull Board (queue UI)

## Required Components

- Idempotent job handlers: same message delivered twice produces the same result
- Retry policy with exponential backoff and dead-letter queue (DLQ)
- Job deduplication to prevent duplicate runs on overlapping schedules
- Webhook signature verification for all inbound webhook endpoints
- Structured logging for every job: job ID, trigger, duration, outcome, error
- Alerting on DLQ depth, job failure rate, and missed schedule
- Admin interface or CLI to inspect queues, retry failed jobs, and cancel stuck jobs
- Circuit breaker for external API calls within job handlers

## Security Checklist

- [ ] Webhook endpoints verify HMAC signature before processing payload
- [ ] External API keys loaded from secrets manager — not hardcoded or in committed `.env`
- [ ] Job payloads do not contain secrets — pass IDs and fetch data inside the handler
- [ ] DLQ payloads stored securely and access-controlled (may contain sensitive data)
- [ ] Automation accounts use service accounts with minimum required permissions
- [ ] Outbound HTTP calls use a timeout and respect the external service's rate limits
- [ ] Admin/monitoring UI is authenticated and not publicly accessible

## Testing Checklist

- [ ] Unit tests for each job handler with mocked external calls
- [ ] Idempotency test: job handler called twice with same input produces no side effects on second call
- [ ] Retry behavior test: handler fails on first call, succeeds on second; side effects occur exactly once
- [ ] Webhook signature test: invalid signature returns 401 without processing
- [ ] Schedule test: verify cron expression fires at expected times
- [ ] DLQ test: job that exhausts retries lands in DLQ and triggers an alert

## Deployment Checklist

- [ ] All secrets in secrets manager; `.env.example` documents required keys with no values
- [ ] Worker process monitored by process manager (PM2, systemd, or container restart policy)
- [ ] Queue metrics (depth, throughput, error rate) exported to monitoring system
- [ ] DLQ alert configured: fires if any job lands in DLQ
- [ ] Graceful shutdown: worker drains in-progress jobs before exit
- [ ] Schedule runs validated in staging before production cutover
- [ ] Runbook documented: how to manually trigger, retry, and cancel jobs

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [temporalio/samples-python](https://github.com/temporalio/samples-python) | Temporal workflow samples in Python | ✅ Best pick |
| [n8n-io/n8n](https://github.com/n8n-io/n8n) | Open-source workflow automation platform (self-hostable Zapier alternative) | |
| [prefecthq/prefect/examples](https://github.com/PrefectHQ/prefect/tree/main/examples) | Prefect automation flow examples | |

**Best Pick:** [temporalio/samples-python](https://github.com/temporalio/samples-python) — production-grade, fault-tolerant, reliable workflows with durable execution and replay built in

## Reference Repositories

- [taskforcesh/bullmq](https://github.com/taskforcesh/bullmq) — job queue with examples for queues, workers, schedulers
- [temporalio/samples-typescript](https://github.com/temporalio/samples-typescript) — durable workflow patterns
- [inngest/inngest](https://github.com/inngest/inngest) — event-driven durable functions, good patterns for background jobs

## Official Documentation

- [Temporal Docs](https://docs.temporal.io) — durable workflow execution
- [n8n Docs](https://docs.n8n.io) — workflow automation platform
- [BullMQ Docs](https://docs.bullmq.io) — queues, workers, schedulers, DLQ
- [Inngest Docs](https://www.inngest.com/docs) — event-driven background jobs
- [Svix Docs](https://docs.svix.com) — managed webhook delivery and verification
- [Celery Docs](https://docs.celeryq.dev) — Python distributed task queue
