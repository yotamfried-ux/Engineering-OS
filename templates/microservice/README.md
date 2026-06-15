# Microservice Template

## Overview
Use this template for a single-responsibility backend service deployed independently within a distributed system. Suited for teams practicing domain-driven design who need to scale, deploy, and fault-isolate individual capabilities without coordinating full-system releases. Each service owns its data store, exposes a well-defined contract, and communicates with peers via HTTP/gRPC or an event bus.

## Recommended Architecture Options
- **Synchronous REST/gRPC** — Simple request/response; easy to reason about; tight coupling if overused; best for queries and commands that need an immediate response.
- **Asynchronous event-driven (Kafka / RabbitMQ / SNS+SQS)** — Loose coupling, natural audit log, replay; harder to trace end-to-end; best for workflows that cross multiple services.
- **CQRS + Event Sourcing** — Full audit trail, independent read/write scaling; high complexity; best for financial or compliance-heavy domains.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Runtime | Node.js (Fastify), Go (net/http + chi), Python (FastAPI), Java (Spring Boot) |
| API protocol | REST (OpenAPI 3), gRPC (protobuf), GraphQL (federation) |
| Messaging | Apache Kafka, RabbitMQ, AWS SNS+SQS, Google Pub/Sub |
| Service discovery | Kubernetes DNS, Consul, AWS Cloud Map |
| Database (per service) | PostgreSQL, MySQL, MongoDB, Redis, DynamoDB |
| Observability | OpenTelemetry (traces + metrics), Prometheus, Grafana, Jaeger |
| Container / orchestration | Docker, Kubernetes, Helm |
| CI/CD | GitHub Actions, ArgoCD, Flux |

## Required Components
- Health endpoints: `/healthz` (liveness) and `/readyz` (readiness) with dependency checks
- Structured JSON logging with correlation/trace IDs on every log line
- OpenTelemetry instrumentation: traces propagated via W3C `traceparent` header
- Prometheus metrics endpoint (`/metrics`): request rate, error rate, latency p50/p95/p99
- Circuit breaker around downstream HTTP/gRPC calls (opossum / resilience4j / go-resiliency)
- Graceful shutdown: drain in-flight requests before SIGTERM acknowledgement
- Config via environment variables only (12-factor); secrets via Vault or Kubernetes Secrets
- Idempotency keys on all mutating operations that can be retried
- Dead-letter queue (DLQ) for failed event consumers
- OpenAPI / protobuf schema published to a schema registry on every release

## Security Checklist
- [ ] Service-to-service auth via mTLS or short-lived JWT (SPIFFE/SPIRE, Istio, Linkerd)
- [ ] No secrets in environment variable names visible in process listings — use secret manager
- [ ] Input validation on every endpoint (JSON Schema / protobuf constraints)
- [ ] Rate limiting at ingress (per-client and per-route)
- [ ] Dependency vulnerability scan in CI (`npm audit`, `govulncheck`, `trivy`)
- [ ] Container image scanned for CVEs before push (Trivy, Grype, Snyk)
- [ ] Non-root user in Dockerfile; read-only filesystem where possible
- [ ] Network policy restricting egress to only required services
- [ ] Audit log for every mutating operation (who, what, when, result)

## Testing Checklist
- [ ] Unit tests for domain logic (no I/O, no framework)
- [ ] Integration tests with real DB (testcontainers) and real message broker
- [ ] Contract tests with consumer-driven contracts (Pact)
- [ ] API schema validated against OpenAPI / proto spec in CI
- [ ] Load test for target RPS with acceptable p99 latency (k6 / Gatling)
- [ ] Chaos test: verify circuit breaker and DLQ trigger correctly under downstream failure
- [ ] Health endpoint returns degraded (not 200) when a critical dependency is down

## Deployment Checklist
- [ ] Docker image tagged with git SHA, not `latest`
- [ ] Helm chart / Kubernetes manifests include resource requests and limits
- [ ] HorizontalPodAutoscaler configured on CPU + custom metric (queue depth)
- [ ] PodDisruptionBudget set to maintain minimum availability during rollouts
- [ ] Readiness probe prevents traffic until service is fully initialized
- [ ] Rolling update strategy with `maxUnavailable: 0`
- [ ] Canary or blue/green rollout via Argo Rollouts or Flagger
- [ ] Runbook linked from service README: how to scale, restart, roll back
- [ ] Alerts configured: error rate > 1%, p99 latency > SLO, DLQ depth > 0

## Reference Repositories
- [GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) — Complete polyglot microservices sample with Kubernetes and Istio
- [nestjs/nest](https://github.com/nestjs/nest) — Node.js framework with first-class microservice transport (gRPC, Redis, Kafka)
- [open-telemetry/opentelemetry-demo](https://github.com/open-telemetry/opentelemetry-demo) — Reference observability setup across many services

## Official Documentation
- [OpenTelemetry Docs](https://opentelemetry.io/docs/) — Instrumentation, SDK, exporters for traces/metrics/logs
- [gRPC Documentation](https://grpc.io/docs/) — Protocol Buffers, service definitions, deadlines, streaming
- [Kubernetes Patterns](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) — Deployment, HPA, PDB, rolling updates
- [Pact Contract Testing](https://docs.pact.io/) — Consumer-driven contract tests for service APIs
