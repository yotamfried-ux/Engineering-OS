# API Frameworks & Platforms

## Overview
Consult this guide when selecting an API framework for a new service or microservice. Key decision factors: team language, performance requirements, type safety, OpenAPI generation capability, and ecosystem maturity.

**Decision heuristic:**
- Python team + auto OpenAPI + async → FastAPI
- Node.js team + enterprise patterns + DI → NestJS
- Node.js team + minimal + high throughput → Fastify
- Edge/multi-runtime + ultralight → Hono
- Java/JVM enterprise → Spring Boot
- .NET team → ASP.NET Core
- Go team + high concurrency → Go Fiber
- Full-stack TypeScript + end-to-end type safety (no REST layer) → tRPC

## Frameworks

### FastAPI
**Type:** Async web framework  
**Language:** Python 3.8+  
**Best For:** Data-heavy APIs, ML model serving, teams already in the Python ecosystem who need automatic OpenAPI docs with zero boilerplate  
**Official Docs:** https://fastapi.tiangolo.com  
**GitHub:** https://github.com/fastapi/fastapi  
**Key Strengths:**
- Auto-generates OpenAPI (Swagger UI + ReDoc) from type hints — no extra config
- Pydantic v2 provides fast runtime validation and serialization
- Native async/await with Starlette under the hood; handles concurrent I/O well
- Excellent Python type-hint ergonomics; editors give full autocomplete on request/response models
- Dependency injection system is clean and testable
**Watch Out For:**
- Python GIL limits CPU-bound parallelism; use multiple workers (Uvicorn + Gunicorn) or offload to task queues
- Pydantic v1 → v2 migration can be breaking for existing codebases
- Not a good fit if the team is not already Python-fluent — ecosystem lock-in is real

---

### NestJS
**Type:** Progressive Node.js framework (MVC + DI)  
**Language:** TypeScript (primary)  
**Best For:** Enterprise-grade REST or GraphQL APIs, teams that want Angular-style structure, large codebases that need strong conventions  
**Official Docs:** https://docs.nestjs.com  
**GitHub:** https://github.com/nestjs/nest  
**Key Strengths:**
- Opinionated module/controller/service architecture reduces bike-shedding on large teams
- First-class dependency injection container; easy unit testing with mocked providers
- OpenAPI generation via `@nestjs/swagger` decorators — stays in sync with code
- Supports REST, GraphQL, WebSockets, microservices, and gRPC in one framework
- Strong TypeScript support; class-validator + class-transformer for runtime validation
**Watch Out For:**
- Decorator-heavy boilerplate can feel verbose for small services
- DI container adds startup overhead; cold starts matter in serverless contexts
- Learning curve is steep for developers not familiar with Angular patterns
- `@nestjs/swagger` requires keeping decorators in sync with DTOs — partial automation, not full

---

### Express / Fastify
**Type:** Minimalist HTTP framework (Express) / High-performance HTTP framework (Fastify)  
**Language:** JavaScript / TypeScript  
**Best For:** Express — quick prototypes, legacy codebases, maximum ecosystem compatibility; Fastify — high-throughput APIs where raw performance and schema-driven validation matter  
**Official Docs:** https://expressjs.com (Express) · https://fastify.dev (Fastify)  
**GitHub:** https://github.com/expressjs/express (Express) · https://github.com/fastify/fastify (Fastify)  
**Key Strengths:**
- Express: largest middleware ecosystem in Node.js; virtually every library has an Express adapter; zero opinions means total flexibility
- Fastify: benchmarks consistently faster than Express (2–4×) due to compiled JSON serialization and optimized routing
- Fastify has built-in JSON Schema validation and OpenAPI support via `@fastify/swagger`
- Both support TypeScript via community types (`@types/express`) or native generics (Fastify)
- Fastify's plugin system enforces encapsulation, reducing accidental global state
**Watch Out For:**
- Express has no built-in input validation or OpenAPI generation — must be bolted on (express-validator, swagger-jsdoc)
- Express middleware order is imperative and error-prone; async error handling requires explicit `next(err)` forwarding
- Fastify's JSON Schema validation uses AJV under the hood — schema errors can be cryptic
- Neither framework enforces project structure; discipline required on large teams

---

### Hono
**Type:** Ultralight multi-runtime web framework  
**Language:** TypeScript  
**Best For:** Edge functions (Cloudflare Workers, Deno Deploy, Bun), serverless APIs, situations where bundle size and cold-start time are critical  
**Official Docs:** https://hono.dev  
**GitHub:** https://github.com/honojs/hono  
**Key Strengths:**
- Runs on Cloudflare Workers, Deno, Bun, Node.js, AWS Lambda — one codebase, many runtimes
- Tiny bundle size (under 14 kB); near-zero cold start on edge runtimes
- `hono/zod-openapi` middleware provides Zod-based validation + auto OpenAPI spec generation
- RPC mode (`hono/client`) gives partial end-to-end type safety between server and client without a full tRPC setup
- First-class TypeScript generics on routes; context is fully typed
**Watch Out For:**
- Ecosystem is young compared to Express/Fastify; some middleware may be missing or immature
- RPC client type safety is partial — not as tight as tRPC's end-to-end inference
- Edge runtime constraints (no Node.js built-ins like `fs`, `crypto` node module) can surprise developers
- Not a good fit for long-running processes or stateful workloads

---

### Spring Boot
**Type:** Convention-over-configuration Java application framework  
**Language:** Java (primary), Kotlin supported  
**Best For:** JVM enterprise services, organizations with existing Java/Spring expertise, services requiring deep integration with enterprise infrastructure (JPA, Spring Security, Spring Batch)  
**Official Docs:** https://docs.spring.io/spring-boot/docs/current/reference/html  
**GitHub:** https://github.com/spring-projects/spring-boot  
**Key Strengths:**
- Massive, mature ecosystem; virtually every enterprise pattern has a first-party Spring library
- `springdoc-openapi` generates OpenAPI 3 specs from code annotations with minimal config
- Spring Security provides battle-tested auth (OAuth2, JWT, SAML) out of the box
- Spring Data JPA, R2DBC (reactive), and MongoDB starters reduce boilerplate dramatically
- GraalVM native image support (Spring Native) for fast startup in container environments
**Watch Out For:**
- JVM startup time and memory footprint are high compared to Go or Node alternatives — plan container sizing accordingly
- Annotation magic can obscure what the framework is doing; debugging requires understanding Spring's proxy model
- Kotlin support is good but not as idiomatic as a Kotlin-first framework (e.g., Ktor)
- Build times with Maven/Gradle can be slow on large projects without incremental compilation tuning

---

### ASP.NET Core
**Type:** Cross-platform high-performance web framework  
**Language:** C#  
**Best For:** .NET teams building REST APIs or minimal APIs, organizations already in the Microsoft ecosystem (Azure, SQL Server, Active Directory)  
**Official Docs:** https://learn.microsoft.com/en-us/aspnet/core  
**GitHub:** https://github.com/dotnet/aspnetcore  
**Key Strengths:**
- Built-in OpenAPI generation via `Microsoft.AspNetCore.OpenApi` (stable from .NET 9) — no third-party package required
- Minimal APIs (introduced in .NET 6) allow Express-style routing with far less ceremony than controllers
- Top-tier raw performance in TechEmpower benchmarks; among the fastest server-side frameworks across all languages
- Unified model binding, validation (Data Annotations / FluentValidation), and middleware pipeline
- First-class dependency injection container built in; no external DI library needed
**Watch Out For:**
- C# and the .NET toolchain are prerequisites; not accessible to non-.NET teams
- Controller-based APIs accumulate boilerplate; Minimal APIs trade boilerplate for less structure
- Azure-centric ecosystem means some integrations (App Service, Azure AD) are smoother than alternatives (AWS, GCP)
- OpenAPI tooling matured slowly — older .NET versions required Swashbuckle or NSwag

---

### Go Fiber
**Type:** Express-inspired HTTP framework for Go  
**Language:** Go  
**Best For:** High-concurrency microservices, Go teams that want familiar Express-like ergonomics, services where low memory footprint and high throughput are non-negotiable  
**Official Docs:** https://docs.gofiber.io  
**GitHub:** https://github.com/gofiber/fiber  
**Key Strengths:**
- Built on Fasthttp (not net/http), delivering among the highest throughput benchmarks in the Go ecosystem
- Low memory footprint; goroutine model handles massive concurrency with minimal overhead
- Middleware ecosystem covers JWT, CORS, rate limiting, caching, WebSocket
- OpenAPI generation via `fiber-swagger` (wraps swaggo/swag annotations)
- Simple deployment: single static binary, no runtime dependencies
**Watch Out For:**
- Fasthttp is not fully `net/http` compatible — some standard library middleware and clients cannot be used directly
- OpenAPI generation relies on code comments parsed by `swag`; comments and code can drift out of sync
- Go's type system lacks generics-based runtime validation; input validation must be done manually or via third-party libraries (go-playground/validator)
- Less opinionated than NestJS or Spring; large teams need to establish their own structure conventions

---

### tRPC
**Type:** End-to-end typesafe RPC framework (not REST)  
**Language:** TypeScript  
**Best For:** Full-stack TypeScript monorepos where the client and server are developed together and a REST/OpenAPI contract is not a hard requirement  
**Official Docs:** https://trpc.io/docs  
**GitHub:** https://github.com/trpc/trpc  
**Key Strengths:**
- True end-to-end type inference: changing a server procedure immediately surfaces type errors in the client — no code generation step
- Zod schemas serve as both runtime validation and TypeScript type source; single source of truth
- Zero network layer abstraction to maintain; no hand-written fetch calls or OpenAPI clients
- Adapters for Next.js, Express, Fastify, AWS Lambda, Fetch — plugs into existing servers
- Subscriptions and WebSocket support built in via `@trpc/server/adapters/ws`
**Watch Out For:**
- Not REST — external consumers (mobile apps by third parties, other language services) cannot consume tRPC procedures without a dedicated client or a REST adapter
- No native OpenAPI output; `trpc-openapi` plugin exists but is community-maintained and lags behind tRPC releases
- Tightly couples client and server; works best in a monorepo. Across separate repos, type sharing requires publishing shared packages
- Not a fit when a public API contract (OpenAPI spec) is a deliverable requirement

---

## Type Safety & OpenAPI Matrix

| Framework | Native TypeScript | Auto OpenAPI | Runtime Validation | End-to-End Types |
|---|---|---|---|---|
| FastAPI | ✗ (Python) | ✓ (built-in) | ✓ (Pydantic) | ✗ |
| NestJS | ✓ | ✓ (decorator) | ✓ (class-validator) | partial |
| Express | ✗ (TS via types) | manual | manual | ✗ |
| Fastify | ✓ | ✓ (JSON Schema) | ✓ | ✗ |
| Hono | ✓ | ✓ (zod-openapi) | ✓ (Zod) | partial |
| Spring Boot | ✗ (Java) | ✓ (springdoc) | ✓ | ✗ |
| ASP.NET Core | ✗ (C#) | ✓ (built-in) | ✓ | ✗ |
| Go Fiber | ✗ (Go) | ✓ (swagger) | manual | ✗ |
| tRPC | ✓ | ✗ (not REST) | ✓ (Zod) | ✓ |

## Official Starter Templates

| Framework | Starter Repository | Stars |
|---|---|---|
| FastAPI | [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template) | 30k+ |
| NestJS | [nestjs/nest/sample](https://github.com/nestjs/nest/tree/master/sample) | 70k+ |
| Hono | [honojs/hono/examples](https://github.com/honojs/hono/tree/main/examples) | 22k+ |
| tRPC | [trpc/examples-next-prisma-starter](https://github.com/trpc/examples-next-prisma-starter) | 35k+ |
| Go Fiber | [gofiber/recipes](https://github.com/gofiber/recipes) | 3k+ |
