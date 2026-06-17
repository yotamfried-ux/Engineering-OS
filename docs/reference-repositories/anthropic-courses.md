# Anthropic Courses

## Repository

**URL:** https://github.com/anthropics/courses
**Owner:** Anthropic (official)
**Purpose:** Official Anthropic curriculum — 5 structured courses in Jupyter notebook format covering the Claude API from fundamentals through advanced multi-agent systems. The recommended learning path before building production Claude integrations.

---

## Courses (Recommended Order)

### 1. Anthropic API Fundamentals
**Path:** `anthropic_api_fundamentals/`  
**What you learn:**
- API setup, authentication, and first request
- The Messages API structure: `role`, content blocks, `stop_reason`
- `max_tokens` and why it must always be set explicitly
- Model selection: when to use Haiku vs. Sonnet vs. Opus
- Token counting and cost estimation before sending requests

### 2. Prompt Engineering Interactive Tutorial
**Repo:** [anthropics/prompt-eng-interactive-tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial) (separate repo)  
**10 chapters — What you learn:**

| Chapter | Topic |
|---|---|
| 1 | Basic prompt structure, role assignment |
| 2 | Being clear and direct — specificity in instructions |
| 3 | Assigning a role / persona to Claude |
| 4 | Separating data from instructions (XML tags) |
| 5 | Formatting output: JSON, lists, structured responses |
| 6 | Precognition — asking Claude to think before answering |
| 7 | Few-shot examples — showing before telling |
| 8 | Avoiding hallucinations and staying grounded |
| 9 | Complex prompts — chaining all techniques |
| 10 | Tool use prompting patterns |

### 3. Tool Use Course
**Path:** `tool_use/`  
**What you learn:**
- Defining tools with JSON Schema (name, description, input_schema)
- The tool use loop: detect `stop_reason: "tool_use"` → execute → return `tool_result`
- Parallel tool calls and merging multiple results in one user turn
- Error handling when a tool call fails
- Chaining tool calls across multiple turns

### 4. Building Effective Agents
**Path:** `building_effective_agents/`  
**What you learn:**
- When NOT to use an agent (simple prompts are often better)
- Prompt chaining: sequential pipelines where each step's output feeds the next
- Routing: classifier decides which specialized agent handles a request
- Parallelization: fan-out to multiple agents, pick best result
- Orchestrator/subagent: one agent plans, others execute
- Human-in-the-loop: when to pause and ask for approval

### 5. Real-World Prompting
**Path:** `real_world_prompting/`  
**What you learn:**
- Production-grade prompt design for customer support, document analysis, code review
- Handling edge cases: ambiguous input, out-of-scope requests, adversarial users
- Evaluation: using Claude as a judge to score outputs from another Claude call
- Iterating on prompts with a systematic test suite

---

## Recommended Reading Order

```
1. Anthropic API Fundamentals  (understand the API)
2. Prompt Engineering Tutorial  (master prompt design)
3. Tool Use Course              (enable agentic capabilities)
4. Building Effective Agents    (compose agents correctly)
5. Real-World Prompting         (production patterns + evaluation)
```

---

## Related

- [anthropics/anthropic-cookbook](https://github.com/anthropics/anthropic-cookbook) — hands-on recipes for specific use cases
- [anthropics/anthropic-quickstarts](https://github.com/anthropics/anthropic-quickstarts) — full production starter applications
- [docs/official-docs/anthropic.md](../official-docs/anthropic.md) — API reference index
- [external-systems/anthropic](../../external-systems/anthropic/README.md) — integration guide
- [docs/architecture-guides/ai/](../architecture-guides/ai/) — AI agent architecture patterns
