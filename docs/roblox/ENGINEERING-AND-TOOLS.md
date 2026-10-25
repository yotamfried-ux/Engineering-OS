# Roblox engineering and maintained tools

Official: [Creator Hub](https://create.roblox.com/docs), [Luau](https://luau.org/), [Luau source](https://github.com/luau-lang/luau), [Roblox creator-docs](https://github.com/Roblox/creator-docs), [Open Cloud](https://create.roblox.com/docs/cloud).

## Source and build workflow

| Upstream | Use | Interface | Trust |
|---|---|---|---|
| [Rojo](https://github.com/rojo-rbx/rojo) | sync filesystem projects to Studio | CLI/plugin, **not native MCP** | community |
| [Rokit](https://github.com/rojo-rbx/rokit) | pinned development toolchain | CLI, not MCP | community |
| [Wally](https://github.com/UpliftGames/wally) | Luau package management | CLI, not MCP | community |
| [Luau](https://github.com/luau-lang/luau) | language and type system | tooling, not MCP | official language source |
| [Selene](https://github.com/Kampfkarren/selene) | static lint | CLI, not MCP | community |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | formatting | CLI, not MCP | community |
| [Lune](https://github.com/lune-org/lune) | automation outside Studio | CLI, not MCP | community |
| [React Luau](https://github.com/Roblox/react-luau) | component UI | library, not MCP | Roblox |
| [TestEZ](https://github.com/Roblox/testez) | Luau unit tests | library, not MCP | Roblox |
| [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) | profile persistence candidate | library, not MCP | community; audit before use |

Do not equate an executable CLI or package with an MCP server. Prefer official Studio MCP for interactive work, and host terminal automation for CLI tools.

## Engineering checklist

- Server authoritative game economy, purchases, combat and progression. Validate all client-originated RemoteEvent/RemoteFunction arguments, rates and permissions.
- Design DataStore retries, budgets, shutdown behavior, schema migrations, idempotent receipts, recovery and privacy.
- Consider network replication, streaming, ownership, teleport/matchmaking and multiplayer concurrency.
- Test Luau types, unit logic, integration, multiple clients, reconnects, purchases, load and mobile performance.
- Pin dependencies and licenses; evaluate upstream activity and security; avoid unreviewed community models or executable plugins.
- Do not use real credentials or production publishing in tests without approval.
