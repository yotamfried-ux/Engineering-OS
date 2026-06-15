# Anthropic Quickstarts

## Repository

**URL:** https://github.com/anthropics/anthropic-quickstarts
**Owner:** Anthropic (official)
**Purpose:** Production-quality starter applications demonstrating complete, real-world Claude integrations. Unlike the Cookbook (which is notebook-based recipes), Quickstarts are full runnable apps covering architecture, UI, and backend — designed to fork and build on.

---

## What to Learn from It

- How to structure a complete agentic application end-to-end (not just API calls)
- How Claude handles multi-turn conversations with tool use across a full web UI
- Computer use integration: the screenshot → action → screenshot loop in a real application
- How to build a financial analyst agent that calls external data APIs and synthesizes results
- Customer support patterns: intent classification, tool delegation, human handoff logic

---

## Applications Included

### Customer Support Agent
**Stack:** Next.js + TypeScript + Claude  
**What it demonstrates:**
- Multi-turn conversation management with system prompt for support persona
- Tool use for looking up order status, FAQs, and escalation policies
- Handling ambiguous user inputs by asking clarifying questions
- Maintaining context across a long support session
- Transferring to human agent when Claude determines it's needed

**Key Files to Study:**
- System prompt design for a constrained support role
- Tool definition for order lookup + escalation
- Frontend conversation loop

### Computer Use Demo
**Stack:** Python + Docker + Claude (claude-3-5-sonnet with computer use)  
**What it demonstrates:**
- Setting up the computer use environment (virtual desktop in Docker)
- The full screenshot → `tool_use` → action → screenshot loop
- Handling `computer`, `bash`, and `text_editor` tool types in sequence
- Safely sandboxing computer use to prevent unintended actions

**Key Files to Study:**
- `computer_use_demo/loop.py` — the core agentic loop
- `computer_use_demo/tools/` — computer, bash, and text editor tool implementations

### Financial Data Analyst
**Stack:** Python + Streamlit + Claude + financial data APIs  
**What it demonstrates:**
- Parallel tool calls to fetch multiple data sources simultaneously
- Synthesizing structured data (stock prices, financials) into natural language analysis
- Chart generation from data fetched via tools
- Streaming responses for long-form analysis output

---

## Recommended Usage

- **Fork the customer support agent** as a base for any conversational AI product
- **Study computer use demo** before building any GUI automation or RPA integration
- **Use financial analyst** as reference for multi-tool parallel data fetching patterns

---

## Related

- [anthropics/anthropic-cookbook](https://github.com/anthropics/anthropic-cookbook) — recipe-level examples (notebooks)
- [anthropics/courses](https://github.com/anthropics/courses) — structured learning curriculum
- [external-systems/anthropic](../../external-systems/anthropic/README.md) — API integration guide
- [docs/official-docs/anthropic.md](../official-docs/anthropic.md) — complete API reference
- [docs/architecture-guides/ai/](../architecture-guides/ai/) — AI architecture patterns
