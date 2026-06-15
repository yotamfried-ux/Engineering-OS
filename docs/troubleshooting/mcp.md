# MCP Servers — Common Bugs & Fixes

> Sources: Model Context Protocol spec (modelcontextprotocol.io), Anthropic MCP docs, MCP TypeScript SDK

## stdio Transport

| Symptom | Root Cause | Fix |
|---|---|---|
| Server never receives requests | Process writes to stdout instead of using SDK | Never write to stdout directly; all communication is through the MCP SDK's `server.connect(transport)` — use `console.error()` for debug logging |
| Process exits immediately | Server has nothing keeping the event loop alive | Keep the process alive with the transport connection; stdio server exits when stdin closes (correct behavior) |
| JSON-RPC parsing error | Non-JSON output on stdout (e.g., a `console.log`) | All stdout must be valid JSON-RPC; use `process.stderr` for any non-protocol output |
| Client can't start server | Wrong command path in `claude_desktop_config.json` | Use absolute path or ensure binary is on PATH; test with `which <command>` before configuring |

## HTTP + SSE Transport

| Symptom | Root Cause | Fix |
|---|---|---|
| SSE connection drops | Server doesn't send keepalive | Send a comment (`: keepalive\n\n`) every 15s to prevent proxy timeout |
| 401 on tool calls | OAuth token not attached to SSE session | MCP clients must re-attach auth on every SSE reconnect; server must validate each connection |
| Tool calls fail on stateless server | Session state lost between SSE reconnects | Store session state in Redis or database; SSE connections are not permanent |
| CORS error on SSE endpoint | Server doesn't allow browser origin | Add `Access-Control-Allow-Origin` and `Access-Control-Allow-Headers` for SSE endpoint |

## Tool Registration

| Symptom | Root Cause | Fix |
|---|---|---|
| Tool not visible to Claude | Tool name contains spaces or special chars | Use snake_case or camelCase; only alphanumeric + underscore allowed in tool names |
| Tool call fails with schema error | `inputSchema` missing `type: "object"` or `properties` | JSON Schema must have `type: "object"` at root with `properties` map |
| Tool result not used by model | Result returned as plain string when JSON expected | For structured data, return `{ type: "text", text: JSON.stringify(data) }` inside a content array |
| Optional params cause errors | Model passes null for optional fields | Mark optional params without `required`; handle null/undefined in tool implementation |

## Resources & Prompts

| Symptom | Root Cause | Fix |
|---|---|---|
| Resource URI not resolvable | URI template not registered with correct pattern | Register exact URI patterns: `resource://myserver/items/{id}`; implement `ReadResourceRequestSchema` handler |
| Resource content too large | Returning full dataset as resource content | Paginate or summarize large resources; Claude has a context window limit |
| Prompt not appearing in Claude | Prompt not registered via `ListPromptsRequestSchema` | Implement handler for `ListPromptsRequestSchema`; return array of `{ name, description, arguments }` |

## Debugging

| Symptom | Root Cause | Fix |
|---|---|---|
| No logs from MCP server | Logging to stdout instead of stderr | Use `console.error()` or write to stderr; Claude Desktop captures stderr for diagnostics |
| Can't test without Claude Desktop | No local test client | Use `@modelcontextprotocol/inspector` (`npx @modelcontextprotocol/inspector <command>`) to test locally |
| Server works locally but not in Claude | Environment variables not set in MCP config | Add `env` object to server config in `claude_desktop_config.json` |

## Sources
- [MCP Specification](https://modelcontextprotocol.io/specification)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Anthropic MCP Guide](https://docs.anthropic.com/en/docs/build-with-claude/mcp)
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector)
- [MCP Server Examples](https://github.com/modelcontextprotocol/servers)
