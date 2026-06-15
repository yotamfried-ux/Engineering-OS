# API Service Template

## Overview
Use this template for a standalone backend API — REST or GraphQL — consumed by frontends, mobile apps, or other services. Covers headless backends, microservices, and BFF (Backend for Frontend) layers where the server has no UI and is deployed independently.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Node.js + Fastify + Prisma (REST) | Fast, typed, great DX, large ecosystem | Single-threaded; CPU-heavy work needs worker threads |
| Node.js + GraphQL Yoga + Pothos | Type-safe schema-first GraphQL, composable | GraphQL overhead; N+1 needs DataLoader |
| Python + FastAPI + SQLAlchemy | Excellent for ML-adjacent APIs, async support | Slower cold start than Node for pure API work |
| Go + Chi/Gin | High throughput, low memory, ideal for high-concurrency | Verbose; slower iteration for rapid product work |

## Recommended Frameworks & Platforms

- **Runtime/Framework:** Node.js 20 LTS + Fastify, or Python 3.12 + FastAPI
- **Schema/Validation:** Zod (TS), Pydantic (Python)
- **ORM:** Prisma (Node) or SQLAlchemy 2.x (Python)
- **Database:** PostgreSQL (primary), Redis (cache/queue)
- **Auth:** JWT (access + refresh tokens), or delegated to Auth.js / Clerk / Supabase Auth
- **API documentation:** OpenAPI via `@fastify/swagger` or FastAPI's built-in Swagger
- **Queue/async jobs:** BullMQ (Node + Redis) or Celery (Python + Redis/RabbitMQ)
- **Hosting:** Railway, Render, Fly.io, or AWS ECS/App Runner
- **Observability:** Pino (logging), OpenTelemetry, Sentry

## Required Components

- Input validation on every route (schema-based, not ad-hoc)
- Authentication middleware (JWT verification or API key check)
- RBAC/permission layer
- Rate limiting (per-IP and per-user)
- Health check endpoint (`GET /health`) returning service + DB status
- Structured JSON logging with request IDs
- Global error handler that never leaks stack traces to clients
- Database connection pool with graceful shutdown
- OpenAPI spec auto-generated and served at `/docs`

## Security Checklist

- [ ] All route inputs validated with schema before touching business logic
- [ ] Auth middleware applied globally; routes explicitly opt out, not opt in
- [ ] Rate limiting configured: stricter on auth endpoints, looser on read-only
- [ ] Secrets loaded from environment — no hardcoded credentials anywhere
- [ ] Error responses never include stack traces or internal details
- [ ] SQL injection impossible: ORM used; all raw queries parameterized
- [ ] CORS origin allowlist is explicit (not `*`) for browser-facing APIs
- [ ] Dependency audit (`npm audit` / `pip-audit`) in CI

## Testing Checklist

- [ ] Unit tests for service/business-logic layer (mocked DB)
- [ ] Integration tests for each route against a real test database
- [ ] Auth flow tested: valid token, expired token, missing token, wrong role
- [ ] Rate limiter behavior verified in tests
- [ ] Contract tests if this API is consumed by other services (Pact or OpenAPI diff)
- [ ] Load/smoke test before first production deploy (k6 or autocannon)

## Deployment Checklist

- [ ] Database migrations run as a pre-deploy step (not on startup)
- [ ] All environment variables set and documented in `.env.example`
- [ ] Health check endpoint configured in hosting platform
- [ ] Graceful shutdown implemented (drain in-flight requests before exit)
- [ ] CI pipeline: lint → type-check → unit tests → integration tests → build → deploy
- [ ] Auto-scaling rules or resource limits set
- [ ] Structured logs flowing to a log aggregator (Datadog, Logtail, or CloudWatch)

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template) | FastAPI + SQLModel + Alembic + PostgreSQL, official starter | ✅ Best pick |
| [nestjs/nest/sample](https://github.com/nestjs/nest/tree/master/sample) | Official NestJS sample applications | |
| [trpc/examples-next-prisma-starter](https://github.com/trpc/examples-next-prisma-starter) | tRPC + Next.js + Prisma starter | |

**Best Pick:** [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template) — official from the FastAPI maintainer, comprehensive setup with auth, DB migrations, Docker, and CI included

## Reference Repositories

- [fastify/fastify](https://github.com/fastify/fastify) — core framework with plugin examples
- [tiangolo/fastapi](https://github.com/tiangolo/fastapi) — FastAPI with full async, auth, and OpenAPI examples
- [nicholasgasior/fastify-example](https://github.com/fastify/fastify/tree/main/examples) — Fastify examples in the monorepo

## Official Documentation

- [Fastify Docs](https://fastify.dev/docs/latest/) — plugins, hooks, schema validation
- [FastAPI Docs](https://fastapi.tiangolo.com) — dependency injection, async, OpenAPI
- [NestJS Docs](https://docs.nestjs.com) — TypeScript Node.js framework
- [Prisma Docs](https://www.prisma.io/docs) — schema, migrations, query API
- [BullMQ Docs](https://docs.bullmq.io) — job queues, workers, schedulers
- [OpenTelemetry JS Docs](https://opentelemetry.io/docs/languages/js/) — tracing and metrics
