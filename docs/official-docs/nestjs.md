# NestJS — Official Documentation Index

## Official Documentation
**Primary:** https://docs.nestjs.com/
**GitHub:** https://github.com/nestjs/nest
**Changelog:** https://github.com/nestjs/nest/releases
**API Reference:** https://docs.nestjs.com/

---

## Key Sections (Recommended Reading Order)

1. [Overview — First Steps](https://docs.nestjs.com/first-steps) — CLI scaffold, project structure, and entry point; understand the module tree before adding features.
2. [Modules](https://docs.nestjs.com/modules) — The organizational unit of NestJS; everything must belong to a module. Read before designing folder structure.
3. [Controllers](https://docs.nestjs.com/controllers) — Route handlers using `@Controller()` / `@Get()` / `@Post()`; how request data is extracted with `@Param()`, `@Body()`, `@Query()`.
4. [Providers & Dependency Injection](https://docs.nestjs.com/providers) — Services, repositories, and factories registered in modules and injected via constructor; the core DI pattern.
5. [Pipes](https://docs.nestjs.com/pipes) — Validation and transformation before the handler runs; `ValidationPipe` with `class-validator` is the standard approach.
6. [Guards](https://docs.nestjs.com/guards) — Authorization logic that runs before route handlers; implement `CanActivate` for JWT/role-based access control.
7. [Interceptors](https://docs.nestjs.com/interceptors) — Wrap request/response lifecycle; use for logging, response transformation, caching, and timeout enforcement.
8. [Exception Filters](https://docs.nestjs.com/exception-filters) — Catch thrown exceptions and format error responses consistently across the app.
9. [TypeORM Integration](https://docs.nestjs.com/techniques/database) — `@nestjs/typeorm` module; `forRootAsync()` for config injection, `forFeature()` to register repositories per module.
10. [Testing](https://docs.nestjs.com/fundamentals/testing) — Unit tests with `Test.createTestingModule()`; mock providers with `jest.fn()` and override with `useValue`.

---

## Important APIs / Concepts

- **`@Module({ imports, controllers, providers, exports })`** — Declares what a module owns and what it shares; `exports` makes providers available to importing modules.
- **`@Injectable()`** — Marks a class as a NestJS provider; required for DI to work.
- **`@Controller('prefix')`** / **`@Get(':id')`** — Route prefix is set on the class; method decorators add to it.
- **`@Body()` / `@Param()` / `@Query()`** — Parameter decorators for extracting request data; combine with `ValidationPipe` for automatic DTO validation.
- **`ValidationPipe`** — Enable globally with `app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))`.
- **`CanActivate`** — Guard interface; return `true`/`false` or throw `ForbiddenException`; attach with `@UseGuards(AuthGuard)`.
- **`NestInterceptor`** — Interceptor interface; uses RxJS `Observable` to wrap the handler call — tap into before/after.
- **`forRootAsync()`** — Pass factory functions with `inject: [ConfigService]` to load env-dependent config at startup.
- **`forFeature([Entity])`** — Register TypeORM entities (and their repositories) within a specific feature module.
- **`Test.createTestingModule()`** — Creates an isolated module for unit testing; swap real providers with mocks via `overrideProvider()`.

---

## Common Patterns

- API service structure with modules — see [patterns/api/README.md](../../patterns/api/README.md)
- Auth with Guards and JWT — see [patterns/auth/README.md](../../patterns/auth/README.md)
- Database with TypeORM — see [patterns/database/README.md](../../patterns/database/README.md)

---

## Related External Systems

- see [external-systems/nestjs/README.md](../../external-systems/nestjs/README.md)

---

## Gotchas & Version Notes

- **Circular dependency between modules:** Use `forwardRef(() => ModuleA)` in both modules; a sign of poor module boundaries — refactor when possible.
- **`whitelist: true` in ValidationPipe:** Strips properties not declared in the DTO; always enable to prevent mass assignment vulnerabilities.
- **Global vs scoped providers:** `APP_GUARD` / `APP_PIPE` / `APP_INTERCEPTOR` tokens register global enhancers through DI — prefer this over `app.useGlobalGuards()` so they can inject dependencies.
- **TypeORM `synchronize: true`:** Auto-migrates schema on startup — safe in development, dangerous in production. Always set to `false` in prod and use migrations.
- **Repository injection requires `forFeature()`:** `@InjectRepository(Entity)` only works if `TypeOrmModule.forFeature([Entity])` is imported in the same module.
- **`@Res()` bypasses interceptors:** Injecting the raw Express `Response` object disables NestJS response handling; use `@Res({ passthrough: true })` to keep interceptors active.
- **NestJS v10 vs v9:** v10 drops Node.js 14 support and aligns with RxJS 7; check peer dependency ranges when upgrading.
