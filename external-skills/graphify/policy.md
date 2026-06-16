# Graphify — Policy

## Classification

| Field | Value |
|---|---|
| **Type tags** | `context-optimization`, `code-intelligence` |
| **Execution Level** | **Level 1 — Recommended default-on** |
| **Composition role** | Context-optimization layer; runs first / cross-cutting |

---

## Execution Level Detail

**Level 1: Recommended default-on for EVERY project.**

Graphify is treated as default-on for every project. The project owner's stated aspiration is to use it on every project to reduce context cost across all work, and that is the standing default here.

"Default-on" means: at the start of a session, build or verify the graph before doing anything else. The skill is **always part of the default profile** — it is never permanently excluded from a project.

**Growing repos — re-evaluate, never permanently skip.** A project that is *currently* tiny may not yet benefit from a graph. In that case, defer **building the graph** only — but keep Graphify in the default profile and **re-evaluate at every bootstrap/onboarding run** (`scripts/skill-bootstrap.sh`). The moment the repo grows past the trivial threshold, the graph gets built on the next run. A project is never marked "tiny" once and excluded forever — the decision is re-made each session against the repo's current size.

When in doubt, build the graph first. The overhead of running `graphify extract .` (or `/graphify .`) once is low compared to the token savings it enables over the course of a session.

---

## Composition Rules

### 1. Run first — build or refresh before querying

Before using any MCP tool (`query_graph`, `get_pr_impact`, etc.) or relying on graph output in planning or coding, confirm the graph exists and is reasonably fresh. If `graphify-out/graph.json` is absent or the repo has had commits since the last extract, run `graphify extract .` (or `/graphify .`) before proceeding.

### 2. Cross-cutting — active throughout the session, not just at start

Graphify is not a one-time setup step. Query the graph at each decision point: before locating code to edit, before assessing PR impact, before choosing which files to read. The graph is the exploration layer; file reads are the confirmation layer.

### 3. Never overrides security skills

Graphify is a context-optimization tool. It has no authority over security policy. If a security review skill (or a security-scoped rule in a `core/` file) requires reading specific files or running specific checks, those requirements take precedence over graph-based shortcuts. Use the graph to find where to look; do not use it to skip required verification steps.

### 4. Keep the graph fresh via the post-commit hook

The post-commit hook (`graphify hook install`) should be installed on any repo where Graphify is in use. This ensures the graph is updated incrementally after each commit, so `get_pr_impact` and related impact queries remain trustworthy.

If the hook is not installed and the graph is stale, annotate any graph-derived claim with "graph may be stale — verify against current file contents."

---

## Notes

### Graph staleness

The graph reflects the state of the code at the time of the last `graphify extract` run. Changes committed after that point (without the post-commit hook running) are invisible to the graph. This is the primary limitation to be aware of when using graph output to reason about current code state.

Mitigation: install the post-commit hook on day one (`graphify hook install`), and re-run `graphify extract .` at the start of any session where the hook may have missed commits.

### Tiny-repo threshold

Graphify enforces a minimum node count before treating the graph as useful. On very small projects the graph will be built but Graphify itself may warn that the threshold has not been reached. The `--force` flag bypasses this check, but there is typically little benefit to using Graphify on a repository small enough to read in full without context pressure.

This threshold governs **whether to build the graph right now**, not whether Graphify is in the project's profile. Graphify stays default-on; on a currently-tiny repo you simply defer the build and let the next bootstrap/onboarding run re-check the repo size. There is no permanent "this project is too small" flag — a prototype that grows into a real codebase picks up the graph automatically on the next session.
