# Page Agent

**Canonical upstream:** `alibaba/page-agent`

Alibaba's in-page GUI agent. A JavaScript integration gives a web page a natural-language agent that operates against the text/DOM rather than requiring screenshot-driven browser control. Upstream also documents an optional Chrome extension for multi-page tasks and a beta MCP server.

## Use when
Use when building an AI copilot directly into a web product, natural-language form/workflow control, or an agent-accessible browser surface where DOM-native control is preferable to vision-only automation.

## Qualification
Verify on a disposable page: integration loads, chosen LLM provider works, a read-only navigation/query works, one bounded form action works, and any MCP surface initializes and exposes the expected tools. Record version/commit and browser.

## Limits
This does not replace Playwright/system tests or authorization controls. DOM access can make actions easier, but the application must still enforce permissions server-side.

**Status:** READY AS KNOWLEDGE / HOST-DEPENDENT.
