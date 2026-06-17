# Observability — Common Bugs & Fixes

> Sources: Datadog Agent troubleshooting, Grafana docs, OpenTelemetry docs, Prometheus best practices

## Metrics

| Symptom | Root Cause | Fix |
|---|---|---|
| Agent not reporting metrics | API key wrong, port 443 blocked, or agent not running | Run `datadog-agent status`; check `datadog-agent configcheck`; test connectivity with `datadog-agent diagnose` |
| Metric cardinality explosion | High-cardinality tags (user_id, session_id, request_id) as metric labels | Never use user/request IDs as metric labels; put them in log fields instead |
| Prometheus scrape failing | `/metrics` endpoint not exposed or wrong port in scrape config | Verify endpoint is accessible; check `up` metric in Prometheus for scrape health |
| Grafana dashboard shows "No data" | Datasource not configured or wrong time range | Check datasource connection in Grafana → Configuration → Data Sources; widen time range |
| Metric gaps during deployment | Service restart drops in-flight metric flushes | Use `SIGTERM` handler to flush metrics before shutdown; or use push-based metrics |

## Logs

| Symptom | Root Cause | Fix |
|---|---|---|
| Logs not indexed in Datadog | Log collection not enabled for the service | Set `logs_enabled: true` in `datadog.yaml`; add `log_processing_rules` for the log source |
| Log parsing fails (grok) | Log format changed or grok pattern mismatch | Use Datadog's grok parser debugger (Logs → Pipelines → Debug); test against a real log sample |
| Structured logs not parsed | Logs sent as a string with embedded JSON instead of native JSON | Set `DD_LOGS_INJECTION=true` for structured logging; emit logs as JSON directly |
| Log volume costs too high | Debug logs shipped to log management | Use `log_processing_rules` to exclude debug level logs; filter before shipping |

## Traces / APM

| Symptom | Root Cause | Fix |
|---|---|---|
| Traces not appearing | Tracer not initialized before framework imports | Initialize `dd-trace` (or OTel SDK) at the very top of the entrypoint, before any `require`/`import` |
| Trace not connected to logs | Trace/span ID not injected into log fields | Enable automatic log injection: `DD_LOGS_INJECTION=true`; or manually add `trace_id` to log context |
| Spans missing for async operations | Async context not propagated | Use the SDK's context propagation API; don't create spans manually without binding them to the active trace |
| Sampling drops important traces | Default sampling rate too low | Use priority sampling (`DD_TRACE_SAMPLE_RATE=1` for critical paths); set sampling rules per service |

## Alerting

| Symptom | Root Cause | Fix |
|---|---|---|
| Alert fires for every small spike | Threshold too sensitive, no smoothing | Use rolling average or percentile monitors instead of raw value; add minimum evaluation period |
| Alert resolves before on-call notified | Auto-recovery too fast | Set recovery threshold higher than alert threshold; require sustained recovery before resolving |
| No-data alert fires on deploy | Service restarts → metric gap → no-data alert | Set no-data alert evaluation window to > deploy duration; or suppress during deploy |

## Sources
- [Datadog Agent Troubleshooting](https://docs.datadoghq.com/agent/troubleshooting/)
- [Grafana Troubleshooting](https://grafana.com/docs/grafana/latest/troubleshooting/)
- [OpenTelemetry SDK Docs](https://opentelemetry.io/docs/)
- [Prometheus Naming Best Practices](https://prometheus.io/docs/practices/naming/)
- [Datadog Log Collection](https://docs.datadoghq.com/logs/log_collection/)
