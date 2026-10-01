# Execution Capability Reference

This document describes execution options available in Engineering-OS. It is a
reference, not a workflow contract. The active AI/agent may choose any approach
that fits the task, including approaches not listed here.

## Cost classes

| Class | Meaning | Examples |
|---|---|---|
| `none` | no model call | RTK, Graphify queries, tests, linters, ffmpeg, GitHub Actions |
| `local` | no per-call hosted API fee; local hardware/energy still matter | Ollama + supported open model |
| `included` | uses a plan or credit bucket | host-native/Agent SDK execution when available |
| `paid` | provider/API usage is billed or quota-metered | hosted OpenAI/Anthropic/Gemini/etc. |
| `unknown` | cost is not established | unverified MCP/provider/model |

These labels are descriptive metadata only. They do not impose an execution
order.

## Available approaches

Engineering-OS contains examples and capabilities for:

- deterministic repository work through tests, linters, RTK, Graphify and CI;
- local-model work through Ollama and compatible orchestration frameworks;
- host-native or hosted agents;
- parallel workers for independent tasks;
- application-testing tools such as Maestro, Playwright and Appium.

Delegation and parallelism are optional techniques. They can be useful when work
is independent and isolation is cheap, and can be counterproductive when setup,
context transfer or shared mutable state dominates.

## Evidence

Agent/model output and deterministic/runtime evidence are different kinds of
information. For correctness-sensitive claims, the library contains examples of
pairing hypotheses with tests, logs, exact code references or authoritative
runtime state.

## Related knowledge

- Machine-readable capability metadata: `capability-registry/EXECUTION-FAST-PATH.json`
- Optional trace schema: `capability-registry/EXECUTION-TRACE.json`
- Agent/tool catalog: `capability-registry/agent-tools.md`
- Token/context tools: `capability-registry/token-context-efficiency.md`
- Local inference: `external-systems/ollama/README.md`
- Multi-agent references: `external-systems/autogen/`, `crewai/`, `langgraph/`
- Specialized skill assets: `external-skills/`
