# AI Agent Patterns

> Pattern library for orchestrating and managing AI agent systems. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.
>
> **Scope:** These patterns govern agent-level behavior — how agents coordinate, manage state, recover from failures, and get evaluated. For LLM API-level patterns (prompt chaining, tool calling, structured output, streaming, memory), see [`../ai/README.md`](../ai/README.md).

## Overview

Patterns for building reliable, observable, and testable AI agent systems. The core failure modes in agent systems are different from regular software: agents fail silently when a tool returns a plausible but wrong result, they can loop infinitely when stuck, context windows fill up in long-running sessions, and multi-agent coordination introduces race conditions and inconsistent state. Apply these patterns to address those failure modes systematically.

---

## Pattern: Orchestrator-Subagent Coordination

**Problem:** A single agent trying to handle a complex multi-step task in one context window degrades in quality as the context fills, and cannot parallelize independent subtasks.

**Solution:** Split work into an orchestrator that plans and dispatches, and specialist subagents that execute. The orchestrator receives a high-level goal, decomposes it into subtasks, routes each subtask to the right subagent, and aggregates results.

**Architecture:**
```
User request
    ↓
Orchestrator agent
  → plans subtasks (structured output)
  → dispatches independent subtasks in parallel
  → dispatches sequential subtasks in order
  → aggregates subagent results
  → returns final response
    ↓
Specialist subagents (each in a clean context):
  - Research agent (web search, document retrieval)
  - Code agent (read/write files, run tests)
  - Data agent (query databases, transform results)
```

**Implementation Notes:**
- Give each subagent a clean, focused context — do not pass the orchestrator's full history into subagents.
- Subagents should return a structured summary (goal · what was done · evidence · open items), not raw output.
- Run independent subagents in parallel; use `Promise.all` or `asyncio.gather`. Track dependencies explicitly.
- Cap total orchestration depth at 2–3 levels. Deeper hierarchies are harder to debug and risk amplifying errors.
- The orchestrator must set a `max_turns` guard per subagent to prevent runaway execution.

**Example:**
```python
import asyncio
from anthropic import Anthropic

client = Anthropic()

async def run_subagent(system: str, task: str, tools: list) -> str:
    """Run a focused subagent with a clean context and return a summary."""
    response = client.messages.create(
        model="claude-opus-4-8",
        max_tokens=2048,
        system=system,
        messages=[{"role": "user", "content": task}],
        tools=tools,
    )
    return response.content[-1].text if response.content[-1].type == "text" else ""

async def orchestrate(user_goal: str) -> str:
    # Step 1: Orchestrator plans subtasks (structured output)
    plan_response = client.messages.create(
        model="claude-opus-4-8",
        max_tokens=512,
        system="You are a task planner. Return JSON: {subtasks: [{id, description, depends_on: []}]}",
        messages=[{"role": "user", "content": f"Plan subtasks for: {user_goal}"}],
    )
    import json
    plan = json.loads(plan_response.content[0].text)

    # Step 2: Execute independent subtasks in parallel
    results = {}
    independent = [t for t in plan["subtasks"] if not t["depends_on"]]
    parallel_results = await asyncio.gather(
        *[run_subagent("You are a specialist agent.", t["description"], []) for t in independent]
    )
    for task, result in zip(independent, parallel_results):
        results[task["id"]] = result

    # Step 3: Execute dependent subtasks sequentially
    dependent = [t for t in plan["subtasks"] if t["depends_on"]]
    for task in dependent:
        context = "\n".join(f"Task {dep}: {results[dep]}" for dep in task["depends_on"])
        results[task["id"]] = await run_subagent(
            "You are a specialist agent.",
            f"{task['description']}\n\nContext from prior steps:\n{context}",
            [],
        )

    # Step 4: Aggregate
    aggregation_response = client.messages.create(
        model="claude-opus-4-8",
        max_tokens=1024,
        messages=[{"role": "user", "content": f"Synthesize these results for: {user_goal}\n\n{json.dumps(results)}"}],
    )
    return aggregation_response.content[0].text
```

**Common Mistakes:**
- Passing the orchestrator's full message history into subagents — bloats context and leaks irrelevant state.
- No `max_turns` guard — one stuck subagent can loop indefinitely and consume budget.
- Running all subtasks sequentially when they are independent — wastes wall-clock time.

**Security Considerations:**
- Subagents should not inherit the orchestrator's permission scope. Grant each subagent only the tools it needs.
- Results from external tools passed between agents are untrusted — validate before injecting into the next agent's context.

**Testing:**
Mock subagent responses and assert the orchestrator correctly identifies parallel vs sequential tasks, runs parallel ones concurrently (check timing or call order), and correctly passes dependency context. Test that a subagent returning an error does not silently propagate — the orchestrator must surface it.

**Score:** Validated (see pattern-lifecycle.md)

---

## Pattern: Context Budget Management

**Problem:** Long-running agents fill the context window with tool results, intermediate reasoning, and conversation history, causing quality degradation and eventually hitting the model's context limit.

**Solution:** Track token count throughout the agent loop. When approaching the budget limit, compress history (summarize old turns), drop low-value tool results, and if needed, checkpoint state and hand off to a fresh agent context.

**Implementation Notes:**
- Track token count after every turn using the `usage` field in the API response.
- Define three thresholds: `warn` (75% of limit), `compress` (85%), `handoff` (95%).
- At `compress`: summarize the oldest 50% of messages into a single system context block and drop the originals.
- At `handoff`: checkpoint all state to a structured JSON object, end the current agent, and start a fresh agent with the checkpoint injected as context.
- Never let the agent discover the context limit via an API error — that loses the current turn's work.

**Example:**
```python
MAX_TOKENS = 150_000  # model context limit
WARN_AT = int(MAX_TOKENS * 0.75)
COMPRESS_AT = int(MAX_TOKENS * 0.85)
HANDOFF_AT = int(MAX_TOKENS * 0.95)

def manage_context(messages: list, used_tokens: int, checkpoint: dict) -> list:
    if used_tokens >= HANDOFF_AT:
        # Serialize state and restart in fresh context
        raise AgentHandoffRequired(checkpoint=checkpoint)

    if used_tokens >= COMPRESS_AT:
        # Summarize oldest half of messages
        mid = len(messages) // 2
        old = messages[:mid]
        summary = summarize_messages(old)  # LLM call or extractive summary
        return [{"role": "system", "content": f"[Prior context summary]: {summary}"}] + messages[mid:]

    return messages  # within budget
```

**Common Mistakes:**
- Only checking token count at the end of a turn — tool results within a turn can push past the limit.
- Summarizing too aggressively — losing key facts that the model needs to complete the task.
- Not persisting the checkpoint before handoff — if the handoff fails, work is lost.

**Security Considerations:**
- The checkpoint JSON may contain sensitive data retrieved by tools. Encrypt at rest if stored between sessions.

**Testing:**
Unit-test `manage_context` with a messages list and a `used_tokens` value above each threshold. Assert the correct action (no-op, compress, handoff). Test that summarization preserves the key facts needed to complete a canonical task.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Agent Error Recovery

**Problem:** Agents operating in the real world encounter tool failures (network errors, malformed responses, permission denied) and need to recover gracefully rather than crashing or silently ignoring the failure.

**Solution:** Distinguish between retriable errors (transient), recoverable errors (try a different approach), and terminal errors (stop and report). Implement recovery logic at the tool dispatcher layer, not inside the LLM prompt.

**Architecture:**
```
Tool call attempt
    ↓
Dispatcher catches error
    ├─ Transient (network, rate limit) → retry with exponential backoff (max 3)
    ├─ Recoverable (wrong args, not found) → return structured error to agent
    │     → agent decides: try different tool, ask user for clarification, or skip
    └─ Terminal (auth failure, quota exceeded) → halt, surface to user
```

**Implementation Notes:**
- Return structured errors to the agent as tool results, not exceptions: `{"error": "not_found", "message": "File X does not exist"}`.
- The agent can then decide to try a different approach — this is preferable to hard-coding recovery logic outside the loop.
- Apply retry logic only for transient errors identifiable by status code or error type. Do not retry `403 Forbidden` — it will not succeed.
- After 3 consecutive tool failures in the same turn, halt the agent and surface the error rather than letting it spiral.

**Example:**
```python
import asyncio
from enum import Enum

class ErrorKind(Enum):
    TRANSIENT = "transient"  # retry
    RECOVERABLE = "recoverable"  # return to agent
    TERMINAL = "terminal"  # halt

def classify_error(exc: Exception) -> ErrorKind:
    if isinstance(exc, (TimeoutError, ConnectionError)):
        return ErrorKind.TRANSIENT
    if hasattr(exc, "status_code"):
        if exc.status_code in (429, 503, 504):
            return ErrorKind.TRANSIENT
        if exc.status_code in (400, 404, 422):
            return ErrorKind.RECOVERABLE
        if exc.status_code in (401, 403):
            return ErrorKind.TERMINAL
    return ErrorKind.RECOVERABLE  # default: let agent decide

async def dispatch_tool(name: str, args: dict) -> dict:
    for attempt in range(3):
        try:
            return await execute_tool(name, args)
        except Exception as exc:
            kind = classify_error(exc)
            if kind == ErrorKind.TRANSIENT and attempt < 2:
                await asyncio.sleep(2 ** attempt)
                continue
            if kind == ErrorKind.TERMINAL:
                raise AgentTerminalError(f"Terminal error in tool {name}: {exc}") from exc
            # RECOVERABLE or exhausted retries → return error to agent
            return {"error": kind.value, "tool": name, "message": str(exc)}
```

**Common Mistakes:**
- Retrying recoverable errors (e.g., a `404`) — wastes budget and confuses the agent with repeated failures.
- Returning empty string `""` on error — the agent interprets silence as success.
- Catching all exceptions with bare `except` and swallowing them — makes debugging impossible.

**Security Considerations:**
- Do not include stack traces or internal system paths in error messages returned to the agent — they may be reflected to the user.
- Log all tool errors server-side with full context for post-incident review.

**Testing:**
Mock the tool to raise each error type. Assert: transient errors trigger retry; recoverable errors return a structured error dict to the agent; terminal errors halt execution. Test that 3 consecutive transient failures eventually return a recoverable error to the agent rather than looping forever.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Agent Evaluation (Evals)

**Problem:** Agent behavior is non-deterministic and changes with model versions, prompt updates, and tool changes. Without systematic evaluation, regressions go undetected until users report them.

**Solution:** Build an eval harness that runs the agent against a fixed set of tasks with known expected outcomes, scores each run on a rubric (LLM-as-judge or deterministic checks), and gates deploys on a minimum pass rate.

**Architecture:**
```
Eval suite (JSONL):
  { task_id, input, expected_output, rubric }

Eval runner:
  for each task:
    → run agent with task.input
    → score output against task.rubric
      (deterministic: exact match, regex, JSON schema)
      (LLM-as-judge: correctness, safety, format)
    → record pass/fail + latency + token cost

Report:
  pass_rate, avg_latency, avg_cost, regressions_vs_baseline
```

**Implementation Notes:**
- Start with 10–20 hand-authored golden tasks that cover the most common paths and known failure modes.
- Use deterministic checks where possible (JSON schema, regex, exact match) — LLM-as-judge is slower and costlier.
- For LLM-as-judge: use a separate, capable model (not the one being evaluated) with a rubric that outputs a structured score.
- Track evals as part of CI — run on every prompt change and before every model version upgrade.
- Maintain a "regression budget": if pass rate drops more than 5% from baseline, block the deploy.

**Example:**
```python
import json
from pathlib import Path
from anthropic import Anthropic

judge_client = Anthropic()

def score_with_llm_judge(task: dict, actual_output: str) -> dict:
    rubric = task["rubric"]
    response = judge_client.messages.create(
        model="claude-opus-4-8",
        max_tokens=256,
        system="You are an evaluator. Score the output strictly on the rubric. Return JSON: {pass: bool, score: 0-10, reason: str}",
        messages=[{
            "role": "user",
            "content": f"Rubric: {rubric}\n\nExpected: {task['expected_output']}\n\nActual: {actual_output}"
        }],
    )
    return json.loads(response.content[0].text)

def run_evals(eval_suite_path: str, agent_fn) -> dict:
    tasks = [json.loads(l) for l in Path(eval_suite_path).read_text().splitlines()]
    results = []
    for task in tasks:
        actual = agent_fn(task["input"])
        score = score_with_llm_judge(task, actual)
        results.append({"task_id": task["task_id"], **score})

    pass_rate = sum(1 for r in results if r["pass"]) / len(results)
    return {"pass_rate": pass_rate, "results": results}
```

**Common Mistakes:**
- Only running evals manually before a release — too slow; behavioral regressions accumulate between runs.
- Using the same model for evaluation and judging — circular; the judge shares the same biases as the model being evaluated.
- Evaluating on the same tasks used to develop the agent (overfitting to the test set).

**Testing:**
The eval harness itself should be tested: mock the agent to return a known bad output and assert the rubric scores it as failing. Mock a known good output and assert it passes. Assert `pass_rate` calculation is correct.

**Score:** TBD (see pattern-lifecycle.md)

## Official References
- [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) — Anthropic's authoritative agent design guide
- [LangGraph Docs](https://langchain-ai.github.io/langgraph/) — stateful multi-agent orchestration
- [Anthropic Cookbook — multi-agent](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents) — reference implementations
