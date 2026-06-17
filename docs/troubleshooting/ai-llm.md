# AI / LLM — Common Bugs & Fixes

> Sources: Anthropic API docs, OpenAI error reference, LangGraph docs, Pydantic AI docs, AutoGen docs

## Tool Use / Function Calling

| Symptom | Root Cause | Fix |
|---|---|---|
| Agent loop never terminates | `stop_reason: "tool_use"` not checked; loop exits on first response | Branch on `stop_reason`: continue loop only until `"end_turn"` |
| Tool result causes 400 error | `tool_result` placed in wrong message or missing `tool_use_id` | All `tool_result` blocks for a parallel call go in a single user message with matching `tool_use_id` |
| Model ignores tool definitions | Tool `description` is too vague or `input_schema` has no `required` fields | Write specific descriptions; mark required params in JSON Schema |
| Parallel tool calls only partially executed | Code only processes first tool call in response | Iterate over all `tool_use` content blocks, not just `content[0]` |

## Streaming

| Symptom | Root Cause | Fix |
|---|---|---|
| Tool call args arrive empty | Streaming tool call arguments come in `input_json_delta` chunks | Accumulate `input_json_delta` strings, JSON-parse only after `content_block_stop` |
| Stream hangs / connection never closes | SSE stream not fully consumed before connection close | Always read until `message_stop` event; use SDK streaming helpers |
| Partial response on timeout | `max_tokens` reached mid-stream | Increase `max_tokens`; check `finish_reason: "length"` in `message_delta` |

## Prompt Caching

| Symptom | Root Cause | Fix |
|---|---|---|
| `cache_read_input_tokens` always 0 | Block is under ~2048 tokens; Anthropic silently ignores short blocks | Ensure the cached prefix is at least 2048 tokens |
| Cache misses on identical content | `cache_control` placed on wrong block (not the last block of the static prefix) | Attach `cache_control` to the last content block of the system prompt or document |
| Cache expires unexpectedly | TTL is 5 minutes, refreshed only on cache hits | For infrequent requests, cache warm-up call or accept cache misses |

## Token / Context Limits

| Symptom | Root Cause | Fix |
|---|---|---|
| 400 "context length exceeded" | Messages array not pruned; history grows unbounded | Implement sliding window or summarization before each call |
| Unexpected truncation mid-response | `max_tokens` set too low | Set `max_tokens` to max allowed for the model; check `stop_reason: "max_tokens"` |
| High costs on repeated calls | Large system prompt re-sent every call without caching | Use prompt caching on static system prompt prefix |

## Structured Output / JSON Mode

| Symptom | Root Cause | Fix |
|---|---|---|
| Model outputs invalid JSON | No schema enforcement; model instructed in prose only | Use tool-use schema enforcement or provider-native JSON mode |
| Schema ignored with high temperature | Temperature > 1 destabilizes constrained generation | Keep temperature ≤ 0.7 for structured outputs; prefer 0 for determinism |
| Nested objects missing | Required fields not marked in JSON Schema | Explicitly list required fields in `required` array of each nested object |

## Agent Loops

| Symptom | Root Cause | Fix |
|---|---|---|
| `GraphRecursionError` (LangGraph) | Missing `END` node or all paths lead back into the graph | Every conditional branch must have a path to `END` |
| Infinite loop / runaway costs | No termination condition; agent keeps generating tasks for itself | Set `max_iterations`, `recursion_limit`, or `max_consecutive_auto_reply` |
| State lost between agent turns | State not persisted; in-memory only | Use LangGraph checkpointers or persist state to DB between turns |

## Model Identity / Versioning

| Symptom | Root Cause | Fix |
|---|---|---|
| Behavior changes without code change | Pinned to a floating alias (e.g. `claude-sonnet`, `gpt-4`) that updated | Pin to a dated snapshot ID in production; alias in dev only |
| Wrong model billed | Using OpenAI SDK with Mistral by forgetting `base_url` | Always set `base_url` when using OpenAI-compatible SDKs with non-OpenAI providers |

## Sources
- [Anthropic API Errors](https://docs.anthropic.com/en/api/errors)
- [OpenAI Error Codes](https://platform.openai.com/docs/guides/error-codes)
- [LangGraph Troubleshooting](https://langchain-ai.github.io/langgraph/troubleshooting/errors/)
- [Pydantic AI Docs](https://ai.pydantic.dev)
- [AutoGen Docs](https://microsoft.github.io/autogen/)
- [CrewAI Docs](https://docs.crewai.com)
