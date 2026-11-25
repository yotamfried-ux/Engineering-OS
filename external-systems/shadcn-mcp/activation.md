# Official shadcn/ui MCP — real project connector

Official source: https://ui.shadcn.com/docs/mcp
Reel: https://www.instagram.com/reel/DgJC0A4SF7B/

```bash
python3 /path/to/Engineering-OS/tools/eos_capabilities.py ensure --tool shadcn-mcp --project /path/to/react-project
```

Registers the actual project MCP server with Claude Code using the official `npx shadcn@latest mcp` entry point, via `claude mcp add -s local shadcn -- npx -y shadcn@latest mcp`. Status checks registration, **not handshake or component compatibility**. Restart Claude Code, open `/mcp` and check `Connected`, then ask for the registry list and try one component on a branch. Project's `components.json` config determines registries and permissions.

This is the official shadcn/ui component registry, not a claim that a private design library or the video's original setup was replicated.
