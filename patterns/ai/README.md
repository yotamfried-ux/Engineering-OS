# AI Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview

Patterns for building reliable LLM-powered features. Covers decomposing complex tasks into sequential prompt chains, giving the model callable tools, managing what fits in context vs. what lives in a vector store, streaming tokens to the user progressively, and enforcing structured output with schema validation and retries. These patterns apply regardless of provider (Anthropic, OpenAI, Gemini) — swap the SDK but keep the architecture.

---

## Pattern: Prompt Chaining

**Problem:** A single prompt that asks the model to plan, execute, review, and format in one shot produces worse results than specialized prompts for each concern, and makes errors hard to isolate.

**Solution:** Break the task into a linear sequence of focused prompts where each step's output becomes the next step's input. Validate or transform intermediate outputs between steps.

**Implementation Notes:**
- Keep each prompt's responsibility to one task: extract → classify → generate → review → format.
- Pass only the relevant slice of prior output to the next step, not the entire prior conversation — keeps each context window clean and costs less.
- Insert deterministic validation between steps (schema check, length guard, regex) so a bad intermediate output fails loudly rather than propagating silently.
- Add a retry with a corrective instruction if a step fails validation: `"Your previous output was not valid JSON. Return only valid JSON: ..."`.
- Log every step's input and output in development to build intuition for where chains break.

**Example:**
```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

async function summarizeAndClassify(articleText: string) {
  // Step 1: Summarize
  const summaryMsg = await client.messages.create({
    model: "claude-opus-4-5",
    max_tokens: 300,
    messages: [{ role: "user", content: `Summarize this article in 3 sentences:\n\n${articleText}` }],
  });
  const summary = summaryMsg.content[0].type === "text" ? summaryMsg.content[0].text : "";

  // Step 2: Classify — pass only the summary, not the full article
  const classifyMsg = await client.messages.create({
    model: "claude-haiku-4-5",
    max_tokens: 50,
    messages: [
      {
        role: "user",
        content: `Classify this summary as one of: technology, politics, sports, science.\nReturn only the category word.\n\n${summary}`,
      },
    ],
  });
  const category = classifyMsg.content[0].type === "text"
    ? classifyMsg.content[0].text.trim().toLowerCase()
    : "unknown";

  return { summary, category };
}
```

**Common Mistakes:**
- Passing the entire conversation history into every step — blows up the context window and cost.
- Skipping validation between steps — a hallucinated intermediate value cascades through the chain.
- Using the same large model for every step — cheaper/faster models often suffice for classification or extraction steps.

**Security Considerations:**
- Sanitize user-supplied text before injecting it into prompts to reduce prompt injection risk (e.g., strip or escape instruction-like patterns).
- Never include secrets or PII in prompts unless the model is running in a private, on-prem deployment.

**Testing:**
Unit-test each step's prompt in isolation by mocking the LLM client and asserting the input construction. Integration-test the full chain with a small fixture corpus and assert that the final output matches expected categories. Record golden outputs and alert on significant divergence.

---

## Pattern: Tool Use / Function Calling

**Problem:** LLMs lack access to real-time data, private systems, and the ability to take side-effecting actions; without a structured interface they resort to hallucination.

**Solution:** Define tools as JSON schemas, pass them in the API request, and implement an agentic loop that executes tool calls returned by the model and feeds results back until the model issues a final text response.

**Implementation Notes:**
- Define tool `input_schema` with `required` fields and tight types — vague schemas produce vague inputs.
- Support parallel tool calls: the model may request multiple tools in one turn; run them concurrently with `Promise.all`.
- Always validate tool inputs against the schema before executing — the model can hallucinate argument values.
- Return structured errors in tool results (`{"error": "not found"}`) rather than throwing — lets the model recover gracefully.
- Set a `max_iterations` guard on the loop to prevent runaway tool chains.

**Example:**
```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const tools: Anthropic.Tool[] = [
  {
    name: "get_weather",
    description: "Get the current weather for a city.",
    input_schema: {
      type: "object",
      properties: {
        city: { type: "string", description: "City name, e.g. 'Tel Aviv'" },
      },
      required: ["city"],
    },
  },
];

async function runAgent(userQuery: string) {
  const messages: Anthropic.MessageParam[] = [
    { role: "user", content: userQuery },
  ];

  for (let i = 0; i < 10; i++) {
    const response = await client.messages.create({
      model: "claude-opus-4-5",
      max_tokens: 1024,
      tools,
      messages,
    });

    if (response.stop_reason === "end_turn") {
      return response.content.find((b) => b.type === "text")?.text;
    }

    // Collect all tool calls and run them in parallel
    const toolUses = response.content.filter((b) => b.type === "tool_use");
    const toolResults = await Promise.all(
      toolUses.map(async (block) => {
        if (block.type !== "tool_use") return null;
        const result = await dispatchTool(block.name, block.input);
        return { type: "tool_result" as const, tool_use_id: block.id, content: JSON.stringify(result) };
      })
    );

    messages.push({ role: "assistant", content: response.content });
    messages.push({ role: "user", content: toolResults.filter(Boolean) as Anthropic.ToolResultBlockParam[] });
  }
  throw new Error("Agent exceeded max iterations");
}
```

**Common Mistakes:**
- Returning `null` or an empty string on tool error — the model interprets silence as success.
- Defining overlapping tools with similar names — the model picks arbitrarily; make names and descriptions distinct.
- Not handling `stop_reason === "tool_use"` vs `"end_turn"` — causes the loop to exit early.

**Security Considerations:**
- Treat all tool inputs as untrusted user input — validate and sanitize before passing to databases, file systems, or external APIs.
- Scope tool permissions to the minimum needed (read-only where possible); never give an agent write access to production data by default.
- Log all tool invocations and their results for auditability.

**Testing:**
Mock the LLM client to return a pre-defined sequence of tool-use responses, then a final `end_turn`. Assert that the tool dispatcher was called with the correct arguments and that the loop terminates. Test the error path by having a tool return an error object and assert the model receives it correctly.

---

## Pattern: Memory Management

**Problem:** Conversation history grows unbounded and eventually exceeds the context window; meanwhile, information from previous sessions or large knowledge bases cannot fit in context at all.

**Solution:** Use a two-tier memory architecture: keep short-term (in-session) memory in the message array with a rolling window or summary, and offload long-term (cross-session) facts to a vector database retrieved with semantic search.

**Implementation Notes:**
- **Short-term:** When the token count approaches the context limit, summarize the oldest N messages into a single "conversation so far" system message and drop the originals.
- **Long-term:** Embed user facts, document chunks, and prior summaries into a vector store (Pinecone, pgvector, Qdrant). At each turn, retrieve the top-k most relevant chunks and inject them into the system prompt.
- Chunk documents at semantic boundaries (paragraph / section), not fixed character counts, for better retrieval relevance.
- Store metadata (source, timestamp, user_id) alongside embeddings to support filtering and attribution.
- Re-rank retrieved chunks with a cross-encoder before injecting them — raw vector similarity is noisy.

**Example:**
```python
from anthropic import Anthropic
from pinecone import Pinecone
import tiktoken

client = Anthropic()
pc = Pinecone()
index = pc.Index("user-memory")
enc = tiktoken.encoding_for_model("gpt-4o")  # use for token counting across providers

MAX_HISTORY_TOKENS = 4_000

def count_tokens(messages: list[dict]) -> int:
    return sum(len(enc.encode(m["content"])) for m in messages if isinstance(m["content"], str))

def compress_history(messages: list[dict]) -> list[dict]:
    """Summarize oldest half when history grows too large."""
    if count_tokens(messages) < MAX_HISTORY_TOKENS:
        return messages
    mid = len(messages) // 2
    to_summarize = messages[:mid]
    summary_resp = client.messages.create(
        model="claude-haiku-4-5", max_tokens=300,
        messages=[{"role": "user", "content": f"Summarize this conversation:\n{to_summarize}"}]
    )
    summary_text = summary_resp.content[0].text
    return [{"role": "user", "content": f"[Summary of earlier conversation]: {summary_text}"}] + messages[mid:]

def retrieve_context(query: str, user_id: str, top_k: int = 5) -> str:
    from openai import OpenAI  # use any embeddings provider
    embedding = OpenAI().embeddings.create(input=query, model="text-embedding-3-small").data[0].embedding
    results = index.query(vector=embedding, top_k=top_k, filter={"user_id": user_id}, include_metadata=True)
    return "\n".join(r["metadata"]["text"] for r in results["matches"])
```

**Common Mistakes:**
- Truncating messages from the middle — destroys conversation coherence; always truncate from the start.
- Embedding entire documents as single vectors — retrieval recall suffers; chunk first.
- Not filtering by `user_id` in the vector store — leaks one user's memory into another's context.

**Security Considerations:**
- Namespace vector store entries per user and enforce the filter server-side — never let clients specify their own namespace.
- Treat retrieved memory as untrusted content (it may have been injected by a prior prompt injection attack); do not execute instructions found in retrieved memory.

**Testing:**
Unit-test `compress_history` by feeding a long message list and asserting the output fits within the token budget and begins with a summary block. Integration-test retrieval by upserting a known document and querying for it; assert it appears in top-3 results.

---

## Pattern: Streaming Responses

**Problem:** LLM responses can take 5–30 seconds for long outputs; waiting for the full response before rendering makes the UI feel broken and increases perceived latency dramatically.

**Solution:** Use the provider's streaming API to receive tokens as they are generated and render them progressively. On the backend, forward the stream over Server-Sent Events (SSE) or a `ReadableStream`; on the frontend, append tokens to state as they arrive.

**Implementation Notes:**
- Use `stream: true` (OpenAI) or the `.stream()` helper (Anthropic SDK) to get an async iterable of events.
- Forward via SSE (`text/event-stream`) from a Next.js Route Handler or an Express endpoint — it works over HTTP/1.1 without WebSockets.
- Always handle `AbortController` / `AbortSignal` so the client can cancel mid-stream (e.g., user navigates away).
- Buffer tokens into state with a ref to avoid re-rendering on every single token; batch updates with `requestAnimationFrame` or a 16ms flush interval.
- Emit a final `[DONE]` SSE event so the client knows the stream ended cleanly vs. a network drop.

**Example:**
```typescript
// app/api/chat/route.ts — Next.js Route Handler
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

export async function POST(req: Request) {
  const { messages } = await req.json();
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    async start(controller) {
      const anthropicStream = await client.messages.stream({
        model: "claude-opus-4-5",
        max_tokens: 1024,
        messages,
      });

      for await (const event of anthropicStream) {
        if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ token: event.delta.text })}\n\n`));
        }
      }
      controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      controller.close();
    },
    cancel() {
      anthropicStream.controller.abort();
    },
  });

  return new Response(stream, {
    headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-cache" },
  });
}
```

```typescript
// Client-side consumption
async function streamChat(messages: Message[], onToken: (t: string) => void) {
  const res = await fetch("/api/chat", { method: "POST", body: JSON.stringify({ messages }) });
  const reader = res.body!.getReader();
  const decoder = new TextDecoder();
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    const lines = decoder.decode(value).split("\n\n").filter(Boolean);
    for (const line of lines) {
      if (line === "data: [DONE]") return;
      const { token } = JSON.parse(line.replace("data: ", ""));
      onToken(token);
    }
  }
}
```

**Common Mistakes:**
- Not calling `reader.cancel()` when the component unmounts — keeps the HTTP connection and model inference running.
- Storing every token in `useState` directly — causes N re-renders for N tokens; accumulate in a `ref` and flush on a timer.
- Forgetting to set `Cache-Control: no-cache` — proxies and CDNs buffer SSE responses and the user sees nothing until the full response arrives.

**Security Considerations:**
- Authenticate the streaming endpoint the same way as any other API route — SSE connections are persistent HTTP requests.
- Rate-limit per user to prevent stream-based abuse (each stream holds a connection open and incurs LLM cost).

**Testing:**
Mock the Anthropic SDK stream to emit a fixed sequence of delta events in unit tests. Assert that `onToken` is called in order and that the final accumulated string matches the expected output. Test cancellation by aborting mid-stream and asserting no further `onToken` calls occur.

---

## Pattern: Structured Output

**Problem:** Free-text LLM responses are brittle to parse; ad-hoc regex or string splitting breaks on slight model phrasing changes and makes the output unreliable for downstream code.

**Solution:** Use the provider's JSON mode or `response_format` / tool-based extraction to constrain output shape, then validate with Pydantic (Python) or Zod (TypeScript) and retry with a corrective prompt on parse failure.

**Implementation Notes:**
- Prefer tool-based structured output over JSON mode when the schema is complex — tools are more reliably followed.
- Always include the schema description in the system prompt even when using `response_format` — it improves adherence.
- Validate immediately after receiving the response; never pass raw model output to downstream logic.
- On validation failure, retry once with the original prompt plus the error message: `"Your previous response failed validation: {error}. Return valid JSON matching the schema."`.
- Cap retries at 2 to avoid infinite loops on genuinely malformed outputs.

**Example:**
```python
import json
from anthropic import Anthropic
from pydantic import BaseModel, ValidationError

client = Anthropic()

class ProductReview(BaseModel):
    sentiment: str  # "positive" | "neutral" | "negative"
    score: float    # 0.0 – 1.0
    key_points: list[str]

SYSTEM = """You are a review analyzer. Always respond with valid JSON matching:
{"sentiment": "positive|neutral|negative", "score": 0.0-1.0, "key_points": ["..."]}"""

def analyze_review(review_text: str, max_retries: int = 2) -> ProductReview:
    messages = [{"role": "user", "content": f"Analyze this review:\n\n{review_text}"}]
    last_error = None

    for attempt in range(max_retries + 1):
        if attempt > 0 and last_error:
            messages.append({"role": "assistant", "content": messages[-1]["content"]})
            messages.append({
                "role": "user",
                "content": f"Your response failed validation: {last_error}. Return only valid JSON.",
            })

        response = client.messages.create(
            model="claude-haiku-4-5",
            max_tokens=512,
            system=SYSTEM,
            messages=messages,
        )
        raw = response.content[0].text.strip()

        try:
            data = json.loads(raw)
            return ProductReview(**data)
        except (json.JSONDecodeError, ValidationError) as e:
            last_error = str(e)
            messages.append({"role": "assistant", "content": raw})

    raise ValueError(f"Failed to get valid structured output after {max_retries} retries: {last_error}")
```

**Common Mistakes:**
- Parsing the raw string with `eval()` instead of `json.loads()` — arbitrary code execution risk.
- Not retrying on validation failure — a single transient formatting error causes a hard crash.
- Using overly strict schemas (e.g., exact enum values the model doesn't know) — causes constant validation failures; normalize values after parsing instead.

**Security Considerations:**
- Never pass model-generated structured output directly to SQL queries or shell commands — validate and parameterize first.
- If the schema contains a `url` or `path` field, whitelist allowed values or strip dangerous prefixes before use.

**Testing:**
Unit-test the validation + retry loop by mocking the client to return an invalid JSON string on the first call and a valid one on the second. Assert the function succeeds and the retry counter incremented. Test the failure path by always returning invalid JSON and asserting `ValueError` is raised after `max_retries`.

## Official References
- [Anthropic Docs](https://docs.anthropic.com) — Claude API documentation
- [OpenAI Docs](https://platform.openai.com/docs) — GPT API documentation
- [LangChain Docs](https://python.langchain.com/docs/introduction/) — LLM application framework
- [LangGraph Docs](https://langchain-ai.github.io/langgraph/) — stateful agent workflows
- [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) — Anthropic's agent design guide
