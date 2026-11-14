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

**Decompose first, but do not force hosted delegation.**

When a task contains at least three bounded workstreams, identify independent
read-only slices. Delegation is mandatory only when a ready `none`/local route can
run a slice with deterministic verification and without disproportionate setup.

A hosted subagent is **never required merely to satisfy delegation**. Before
using an included/paid hosted worker, all conditions in
`hosted_delegation_roi_gate` from `EXECUTION-FAST-PATH.json` must hold:

1. deterministic/static tooling cannot answer the residual question;
2. no qualified local worker is ready, or it failed a task-specific quality gate;
3. the worker receives a narrow immutable packet and explicit output contract;
4. expected hosted token/context cost is materially lower than coordinator work;
5. the result will be independently verified.

### Hosted worker context budget

Default worker packet:

- the exact question;
- only the relevant diff/hunks;
- at most five directly relevant files;
- no broad repository history or project recap unless an ROI rationale is recorded.

Keep the default text packet at or below 32 KiB and request at most about 1,200
output tokens. If broader context is needed, split the task, retrieve only the
missing evidence, use a qualified local worker, or keep the work in the
coordinator.

### Documentation consistency

Treat documentation consistency/drift as a deterministic task first: exact
search, schema/contract tests, static assertions, and diff-based checks. A hosted
worker is justified only for a residual semantic question that survives those
checks and passes the hosted ROI gate.

If a hosted worker returns low-confidence or unverified findings, verify them in
the coordinator and do not launch another hosted worker for the same slice.

Record every material routing/delegation decision using
`capability-registry/EXECUTION-TRACE.json`. A whole-project qualification report
is incomplete until its required records are present.

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
- Compact routing evidence: `capability-registry/EXECUTION-TRACE.json`
- Agent tools: `capability-registry/agent-tools.md`
- Context/token tools: `capability-registry/token-context-efficiency.md`
- Local inference: `external-systems/ollama/README.md`
- Multi-agent orchestration: `external-systems/autogen/`, `crewai/`, `langgraph/`
- Specialized prompt assets: `external-skills/agency-agents/`
