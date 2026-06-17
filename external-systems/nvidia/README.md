# NVIDIA NIM — Inference Microservices

NVIDIA NIM provides OpenAI-compatible LLM inference for models including Llama,
Nemotron, Mistral, and others. The API is a drop-in replacement for the OpenAI SDK.

## Setup

### API Key

1. Sign up at [build.nvidia.com](https://build.nvidia.com)
2. Generate an API key — starts with `nvapi-`
3. Add to `.env`:

```bash
NVIDIA_API_KEY=nvapi-...
```

### Base URL

```
https://integrate.api.nvidia.com/v1
```

This endpoint is fully OpenAI-compatible — use the OpenAI SDK with a custom `base_url`.

## Quick Start

### curl

```bash
curl https://integrate.api.nvidia.com/v1/chat/completions \
  -H "Authorization: Bearer $NVIDIA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta/llama-3.1-8b-instruct",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 256
  }'
```

### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://integrate.api.nvidia.com/v1",
    api_key=os.environ["NVIDIA_API_KEY"],
)

response = client.chat.completions.create(
    model="meta/llama-3.1-8b-instruct",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=256,
)
print(response.choices[0].message.content)
```

### TypeScript (OpenAI SDK)

```typescript
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "https://integrate.api.nvidia.com/v1",
  apiKey: process.env.NVIDIA_API_KEY,
});

const response = await client.chat.completions.create({
  model: "meta/llama-3.1-8b-instruct",
  messages: [{ role: "user", content: "Hello" }],
  max_tokens: 256,
});
```

## Available Models (as of 2025)

| Model | ID | Context | Notes |
|---|---|---|---|
| Llama 3.1 8B | `meta/llama-3.1-8b-instruct` | 128k | Fast, free tier |
| Llama 3.1 70B | `meta/llama-3.1-70b-instruct` | 128k | High quality |
| Llama 3.1 405B | `meta/llama-3.1-405b-instruct` | 128k | Largest |
| Nemotron 70B | `nvidia/nemotron-4-340b-instruct` | 4k | NVIDIA fine-tune |
| Mistral NeMo | `nv-mistralai/mistral-nemo-12b-instruct` | 128k | Efficient |
| CodeLlama 70B | `meta/codellama-70b` | 100k | Code-focused |

Full model list: `curl https://integrate.api.nvidia.com/v1/models -H "Authorization: Bearer $NVIDIA_API_KEY"`

## Env Var

```bash
NVIDIA_API_KEY=nvapi-...    # required
```

## Free Tier

NVIDIA provides a free tier with rate limits for testing. No credit card required.
Rate limits: ~5 requests/minute on free tier; higher on paid.

## When to use vs. Anthropic/OpenAI

- **Use NVIDIA NIM** when: you need open-weight models (Llama), want to avoid vendor
  lock-in on inference, need specific NVIDIA-optimized models (Nemotron), or want a
  free-tier inference option.
- **Use Anthropic** for Claude models (best tool use, instruction following).
- **Use OpenAI** for GPT-4o, DALL-E, Whisper.

## Connector status

✅ Available via direct HTTP/OpenAI SDK — no MCP server needed.
