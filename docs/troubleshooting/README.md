# Troubleshooting Guides

Common bugs, error messages and fixes organized by domain. Each guide should be cross-checked against current authoritative documentation before applying exact commands or product behavior.

## Guides

| Domain | File |
|---|---|
| AI / LLM | [ai-llm.md](./ai-llm.md) |
| Auth | [auth.md](./auth.md) |
| Payments | [payments.md](./payments.md) |
| Database | [database.md](./database.md) |
| Search & Vector | [search-vector.md](./search-vector.md) |
| Observability | [observability.md](./observability.md) |
| Web / Frontend | [web.md](./web.md) |
| API | [api.md](./api.md) |
| Realtime | [realtime.md](./realtime.md) |
| MCP Servers | [mcp.md](./mcp.md) |

## Evidence-driven debugging route

1. Identify the failing capability/domain.
2. Search the matching troubleshooting guide.
3. Search `../../lessons-learned/` and `../../failed-solutions/` for prior evidence before rediscovering the same failure.
4. Reproduce the symptom on the exact target revision/environment.
5. Establish the cause with logs/traces/state or another authoritative observation; do not patch from symptom alone.
6. Apply the smallest justified fix.
7. Add/run a regression check using the target project's authoritative test runner or framework.
8. For a negative/regression test, verify it fails for the **expected reason** before the fix and passes after the fix where practical.
9. Re-run the affected capability/integration path and record evidence. A green isolated unit test does not prove production wiring.

For project-level evidence/status semantics, use `../../patterns/testing/project-qualification.md` and `../../patterns/testing/evidence-and-simulation.md`.

## Related

- `../../lessons-learned/` — project-specific postmortems and regression knowledge.
- `../../failed-solutions/` — approaches that were tried and discarded.
- `../../patterns/testing/` — evidence-driven qualification and authoritative testing sources.
