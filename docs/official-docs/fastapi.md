# FastAPI — Official Documentation Index

## Official Documentation
**Primary:** https://fastapi.tiangolo.com/
**GitHub:** https://github.com/fastapi/fastapi
**Changelog:** https://fastapi.tiangolo.com/release-notes/
**API Reference:** https://fastapi.tiangolo.com/reference/

---

## Key Sections (Recommended Reading Order)

1. [First Steps](https://fastapi.tiangolo.com/tutorial/first-steps/) — Minimal app with one route; shows the relationship between the function, decorator, and auto-generated schema.
2. [Path Parameters](https://fastapi.tiangolo.com/tutorial/path-params/) and [Query Parameters](https://fastapi.tiangolo.com/tutorial/query-params/) — How FastAPI converts function signatures into validated HTTP params automatically.
3. [Request Body with Pydantic](https://fastapi.tiangolo.com/tutorial/body/) — Defining request schemas with `BaseModel`; covers validation, defaults, and nested models.
4. [Dependency Injection](https://fastapi.tiangolo.com/tutorial/dependencies/) — `Depends()` for shared logic (auth, DB sessions, config); the primary tool for keeping path operations thin.
5. [Async & Concurrency](https://fastapi.tiangolo.com/async/) — When to use `async def` vs `def`; how FastAPI runs sync functions in a thread pool.
6. [Security / Auth](https://fastapi.tiangolo.com/tutorial/security/) — OAuth2 with Password Bearer and JWT; use `Depends(get_current_user)` pattern throughout.
7. [Middleware](https://fastapi.tiangolo.com/tutorial/middleware/) — CORS, custom request/response logging, and timing; applied globally via `app.add_middleware()`.
8. [Background Tasks](https://fastapi.tiangolo.com/tutorial/background-tasks/) — Run work after returning a response; for heavier jobs, prefer a task queue (Celery, ARQ).
9. [OpenAPI & Auto Docs](https://fastapi.tiangolo.com/tutorial/metadata/) — Swagger UI at `/docs`, ReDoc at `/redoc`; customize tags, descriptions, and examples.
10. [Testing](https://fastapi.tiangolo.com/tutorial/testing/) — `TestClient` wraps `httpx`; override dependencies with `app.dependency_overrides` for unit-testable handlers.

---

## Important APIs / Concepts

- **`@app.get()` / `@app.post()`** — Route decorators; return type annotation drives the response model and schema generation.
- **`BaseModel` (Pydantic v2)** — All request bodies and response schemas; validation happens automatically at the framework boundary.
- **`Depends()`** — Declare shared logic as a dependency; supports async, generators (for DB sessions), and nested dependencies.
- **`APIRouter`** — Group related routes into a module; include with `app.include_router(router, prefix="/api/v1")`.
- **`HTTPException`** — Raise with `status_code` and `detail` for structured error responses; caught by FastAPI's default handler.
- **`response_model=`** — Controls which fields are serialized in the response; use to exclude internal fields even if the return type includes them.
- **`lifespan`** — Context manager for startup/shutdown events (replaces deprecated `@app.on_event`); use to open DB pools and load models.
- **`BackgroundTasks`** — Injected into path operation functions; call `.add_task(fn, *args)` to schedule post-response work.

---

## Common Patterns

- API service structure with routers — see [patterns/api/README.md](../../patterns/api/README.md)
- Auth with JWT + Depends — see [patterns/auth/README.md](../../patterns/auth/README.md)
- Database session dependency — see [patterns/database/README.md](../../patterns/database/README.md)

---

## Related External Systems

- see [external-systems/fastapi/README.md](../../external-systems/fastapi/README.md)

---

## Gotchas & Version Notes

- **Pydantic v1 vs v2:** FastAPI 0.100+ uses Pydantic v2 by default; `orm_mode = True` is now `model_config = ConfigDict(from_attributes=True)`.
- **`async def` with sync DB drivers:** Using `async def` with a synchronous driver (e.g., `psycopg2`) blocks the event loop; either use `def` or switch to an async driver (`asyncpg`, `aiosqlite`).
- **`response_model` strips extra fields:** Fields returned by your function but absent from `response_model` are silently dropped — useful for security, easy to miss.
- **`Depends` generators need `yield`:** DB session dependencies must `yield` the session and close it in the `finally` block after the yield.
- **CORS must be added before other middleware:** `CORSMiddleware` must be the first middleware added or preflight responses may be intercepted.
- **`TestClient` is synchronous:** Even for async endpoints; for true async tests use `httpx.AsyncClient` with `ASGITransport`.
- **`@app.on_event` is deprecated:** Use the `lifespan` parameter on `FastAPI()` constructor instead (available since v0.93).
