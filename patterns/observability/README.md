# Observability Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview

Patterns for making distributed systems understandable at runtime. Use these when you need to diagnose production incidents, measure SLO compliance, or understand how requests flow across services. They cover the three pillars of observability — logs, traces, and metrics — and the operational practices that keep alert noise from drowning signal.

---

## Pattern: Structured Logging

**Problem:** Free-form log strings require fragile regex parsing to extract fields, making log queries slow and inconsistent across services.

**Solution:** Emit logs as JSON objects with a fixed set of mandatory fields on every line: `timestamp`, `severity`, `service`, `trace_id`, `user_id`, and `message`. Consumers (log aggregators, dashboards) can then filter and correlate without parsing.

**Implementation Notes:**
- Never interpolate variables directly into the message string; put them in dedicated fields so they are indexable.
- Propagate `trace_id` from the incoming request context; generate one at the entry point if absent.
- Use standard severity levels (`DEBUG`, `INFO`, `WARN`, `ERROR`) and never invent custom levels.
- Redact secrets and PII before logging — scrub authorization headers, passwords, and SSNs at the logger level.

**Example:**
```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  formatters: {
    level: (label) => ({ severity: label.toUpperCase() }),
  },
  base: { service: process.env.SERVICE_NAME ?? 'unknown' },
});

// Bind request-scoped fields once; reuse the child logger throughout the request
export function createRequestLogger(traceId: string, userId?: string) {
  return logger.child({ trace_id: traceId, user_id: userId ?? 'anonymous' });
}

// Usage inside a route handler:
// req.log.info({ order_id: order.id, amount_cents: order.total }, 'order.created');
// → {"severity":"INFO","service":"billing","trace_id":"abc","user_id":"u1","order_id":42,"amount_cents":1999,"msg":"order.created"}
```

**Common Mistakes:**
- Logging inside tight loops — use sampling or aggregate counters instead.
- Emitting different field names for the same concept across services (`userId` vs `user_id` vs `uid`).
- Logging sensitive values such as tokens, passwords, or full request bodies without scrubbing.

**Security Considerations:**
- Treat log output as a potential data leak vector; enforce a scrubber middleware that strips known sensitive field names.
- Restrict log access to appropriate roles — logs often contain internal IDs, email addresses, and behavioral data.

**Testing:**
Capture logger output in tests (redirect to a string buffer) and assert the emitted JSON contains the required fields. Assert that a request containing an `Authorization` header does not appear in the log output.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Distributed Tracing

**Problem:** A slow or failing request that spans multiple services is impossible to diagnose with per-service logs alone because there is no way to correlate which log lines belong to the same user request.

**Solution:** Assign every incoming request a `trace_id` at the entry point. Each service creates child `span`s that record start time, end time, and relevant attributes. Propagate the trace context in HTTP headers (`traceparent`) across all downstream calls.

**Implementation Notes:**
- Use OpenTelemetry (OTel) as the instrumentation layer — it is vendor-neutral and exportable to any backend (Jaeger, Tempo, Honeycomb, Datadog).
- Auto-instrument HTTP clients and DB drivers where possible to avoid manual span creation for every call.
- Add semantic attributes to spans: `http.method`, `http.route`, `db.statement` (sanitized), `user.id`.
- Keep span names static (e.g., `"POST /orders"`, not `"POST /orders/123"`) — dynamic names explode cardinality.

**Example:**
```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { trace, context, SpanStatusCode } from '@opentelemetry/api';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';

// Bootstrap once at process start
const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT }),
  instrumentations: [new HttpInstrumentation()],
});
sdk.start();

// Manual span for business-logic boundaries
const tracer = trace.getTracer('billing-service', '1.0.0');

async function chargeOrder(orderId: string, amountCents: number) {
  return tracer.startActiveSpan('charge_order', async (span) => {
    span.setAttributes({ 'order.id': orderId, 'amount.cents': amountCents });
    try {
      const result = await paymentGateway.charge(orderId, amountCents);
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (err) {
      span.recordException(err as Error);
      span.setStatus({ code: SpanStatusCode.ERROR, message: (err as Error).message });
      throw err;
    } finally {
      span.end();
    }
  });
}
```

**Common Mistakes:**
- Creating a new `trace_id` inside a downstream service instead of extracting it from the incoming `traceparent` header.
- Putting high-cardinality values (raw SQL, full URLs with IDs) in span names instead of attributes.
- Forgetting to call `span.end()` — orphaned spans are never exported and leak memory.

**Security Considerations:**
- Sanitize DB query attributes — strip bind parameters that may contain user data.
- Do not record authentication tokens or credentials as span attributes.

**Testing:**
Use an in-memory OTel span exporter in tests. Assert that calling `chargeOrder` creates a span named `charge_order` with the expected attributes. Assert that a thrown error results in a span with `ERROR` status and a recorded exception event.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Health Check Endpoint

**Problem:** Load balancers and orchestrators (Kubernetes, ECS) need a way to distinguish between a process that is running but unhealthy and one that is genuinely ready to serve traffic.

**Solution:** Expose two separate endpoints. `/health/live` (liveness) returns 200 if the process is running and not deadlocked — it should never depend on external services. `/health/ready` (readiness) returns 200 only when all required dependencies (DB, cache, downstream APIs) are reachable.

**Implementation Notes:**
- Liveness probes must be cheap and always succeed unless the process itself is broken — never check external deps in liveness.
- Readiness probes should check every critical dependency with a short timeout (≤2 s) to avoid slow probe cascades.
- Return a structured JSON body so dashboards can display which dependency is failing.
- Cache dependency check results for a few seconds if your service has a high probe frequency to avoid hammering the DB.

**Example:**
```typescript
import express from 'express';
import { db } from './db';
import { redis } from './cache';

const router = express.Router();

// Liveness — is the process alive?
router.get('/health/live', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Readiness — can we serve traffic?
router.get('/health/ready', async (_req, res) => {
  const checks = await Promise.allSettled([
    db.raw('SELECT 1').then(() => ({ name: 'postgres', ok: true })),
    redis.ping().then(() => ({ name: 'redis', ok: true })),
  ]);

  const results = checks.map((c) =>
    c.status === 'fulfilled' ? c.value : { name: 'unknown', ok: false, error: String(c.reason) }
  );
  const allOk = results.every((r) => r.ok);

  res.status(allOk ? 200 : 503).json({ status: allOk ? 'ok' : 'degraded', checks: results });
});

export default router;
```

**Common Mistakes:**
- Using a single `/health` endpoint for both liveness and readiness — Kubernetes needs them separate to avoid restart loops when a dependency is down.
- Making the liveness check call the database — a DB outage triggers unnecessary pod restarts.
- Returning 200 with `{ status: "error" }` in the body — orchestrators check the HTTP status code, not the body.

**Security Considerations:**
- Do not expose internal dependency URLs, versions, or hostnames in the health response in public-facing services.
- Consider rate-limiting the readiness endpoint if it triggers expensive dependency checks.

**Testing:**
Write an integration test that asserts `/health/live` returns 200 always. Assert `/health/ready` returns 503 when the DB connection is closed. Assert the JSON body contains a `checks` array with per-dependency results.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Error Budgets & Alert Fatigue Prevention

**Problem:** Teams configure alerts on raw error counts or uptime percentages, leading to alert storms during normal traffic spikes and a gradual desensitization that causes engineers to ignore real incidents.

**Solution:** Define SLOs (Service Level Objectives) for each critical user journey. Alert only on error budget burn rate — the rate at which the budget is being consumed — rather than on raw counts. An alert fires only when the burn rate is high enough to exhaust the budget within a predefined window.

**Implementation Notes:**
- Start with a 99.9% availability SLO (43 min/month error budget) and tune from observed baseline.
- Use a multi-window burn rate alert: a fast window (1 h) catches sudden outages; a slow window (6 h) catches slow burns. Require both to fire to reduce false positives.
- Every alert must be actionable — if there is no documented remediation step, delete the alert.
- Route alerts by urgency: page-on-call only for budget-consuming burns; send low-burn alerts to a Slack channel for async review.

**Example:**
```yaml
# Prometheus alerting rules (burn-rate based)
groups:
  - name: slo_api_availability
    rules:
      # Fast burn: >14x rate consumes budget in <2 h → page immediately
      - alert: APIAvailabilityFastBurn
        expr: |
          (
            rate(http_requests_total{status=~"5.."}[1h]) /
            rate(http_requests_total[1h])
          ) > 14 * 0.001
          and
          (
            rate(http_requests_total{status=~"5.."}[5m]) /
            rate(http_requests_total[5m])
          ) > 14 * 0.001
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "API error budget burning fast — page on-call"
          runbook: "https://wiki.internal/runbooks/api-fast-burn"

      # Slow burn: >1x rate over 6 h → Slack notification, no page
      - alert: APIAvailabilitySlowBurn
        expr: |
          (
            rate(http_requests_total{status=~"5.."}[6h]) /
            rate(http_requests_total[6h])
          ) > 1 * 0.001
        for: 60m
        labels:
          severity: warning
        annotations:
          summary: "API error budget draining slowly — review async"
```

**Common Mistakes:**
- Alerting on raw error count thresholds — a spike in traffic increases error count even if the error rate is fine.
- Setting SLO targets without measuring current baseline first — you will alert constantly or never.
- Having alerts without runbooks — engineers dismiss them because there is no defined action.

**Security Considerations:**
- Ensure alert notifications (Slack, PagerDuty) do not include full error messages that may contain PII or secrets.
- Restrict who can silence or delete alerts — accidental silencing during an incident hides the severity.

**Testing:**
Replay synthetic traffic with a controlled error rate in a staging environment. Assert that the fast-burn alert fires when the error rate exceeds the threshold for the required duration. Assert it resolves when the error rate drops. Validate runbook URLs are reachable.

**Score:** TBD (see pattern-lifecycle.md)
