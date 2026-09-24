# Agent & Execution Fast Path

Use this before spawning agents or choosing an LLM-backed workflow. The goal is
to finish the task with the **lowest reliable execution cost and context load**.

## Cost classes

| Class | Meaning | Examples |
|---|---|---|
| `none` | no model call | RTK, Graphify queries, tests, linters, ffmpeg, GitHub Actions |
| `local` | no per-call hosted API fee; uses local hardware/energy | Ollama + supported open model |
| `included` | uses a plan/credit bucket; verify current allowance | host-native/Agent SDK execution when available |
| `paid` | provider/API usage is billed or quota-metered | hosted OpenAI/Anthropic/Gemini/etc. |
| `unknown` | cost cannot be assumed | any unverified MCP/provider/model |

**Local is not literally costless**: hardware, RAM/VRAM, electricity, latency,
model license and quality constraints still apply. Never label a provider/model
"free" without verifying its current terms.

## Selection order

1. **Deterministic/no-LLM first.** If tests, static analysis, Graphify, RTK,
   scripts or CI can answer the question, use them.
2. **Reuse an already-ready capability.** Do not reinstall or rediscover.
3. **Local model for bounded, parallelizable cognition** when quality is adequate.
4. **Included-credit/host-native agent** when local quality is insufficient.
5. **Paid hosted model** only when its capability materially improves the result.

## When to delegate

Delegate only if the subtask has a clear input, output and acceptance check.

Good local/parallel candidates:
- classify or summarize independent files/logs;
- generate candidate tests that deterministic CI will validate;
- inspect several independent modules for the same invariant;
- triage static-analysis findings;
- draft documentation from already-grounded project facts;
- compare alternatives before the main agent makes the final decision.

Keep on the main/high-confidence path:
- destructive changes;
- security conclusions without independent evidence;
- release/merge decisions;
- migrations or production-data changes;
- final correctness claims;
- ambiguous architectural decisions requiring project-wide context.

## Agent asset compatibility

- **Portable prompt/role assets:** Agency Agents can be adapted to a compatible
  local agent runtime after inspecting the exact prompt/tool requirements.
- **Local-model orchestration frameworks:** AutoGen, CrewAI, LangGraph and
  Pydantic AI can use local/OpenAI-compatible model endpoints when supported.
- **Local model runtime:** Ollama is the first-stop local runtime currently
  catalogued by Engineering-OS.
- **Provider-selectable runtimes:** OpenHands/Hermes may be useful for delegated
  coding, but qualification must verify the selected model/provider and sandbox.
- **Claude-Code-specific skills:** Superpowers, gstack and Claude Code workflow
  assets are not automatically portable to a local model merely because their
  prompts are visible. Use their documented host integration unless explicitly
  adapted and re-qualified.

## Parallelism rule

Parallelize **independent state**. Do not fan out agents that mutate the same
files, database rows, emulator, branch or environment without isolation.

For N independent tasks:
1. share one immutable revision/input set;
2. give each worker a bounded output contract;
3. collect outputs;
4. validate with deterministic checks;
5. let one coordinator integrate/reconcile.

## Evidence rule

An agent answer is a proposal, not proof. Pair model work with deterministic
evidence wherever possible.

Examples:
- generated test -> run it;
- code review finding -> reproduce or point to exact code;
- local-model bug hypothesis -> failing test/log;
- UI exploration -> authoritative backend evidence for side effects.

## Deeper routes

- Machine-readable routing: `capability-registry/EXECUTION-FAST-PATH.json`
- Agent tools: `capability-registry/agent-tools.md`
- Context/token tools: `capability-registry/token-context-efficiency.md`
- Local inference: `external-systems/ollama/README.md`
- Multi-agent orchestration: `external-systems/autogen/`, `crewai/`, `langgraph/`
- Specialized prompt assets: `external-skills/agency-agents/`
