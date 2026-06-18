# Realtime — Common Bugs & Fixes

> Sources: Ably docs, Liveblocks docs, Supabase Realtime docs, MDN WebSocket API

## WebSocket Connection

| Symptom | Root Cause | Fix |
|---|---|---|
| Connection drops after 30-60s | Load balancer / proxy timeout kills idle WebSocket | Send ping/pong heartbeat every 25s; configure load balancer WebSocket timeout to 3600s |
| Can't connect behind corporate proxy | Proxy blocks WebSocket upgrade or port 443 WSS | Use WSS (port 443) not WS (80); configure `allowUpgrades: ["websocket"]` in socket.io |
| Connection refused in serverless | WebSocket not supported in serverless functions | Use a dedicated WebSocket service (Ably, Pusher, Supabase Realtime); serverless is stateless |
| Multiple connections per user | React strict mode double-mount + missing cleanup | Return cleanup function from `useEffect`: `return () => connection.close()` |

## Ably

| Symptom | Root Cause | Fix |
|---|---|---|
| Messages not received | Client subscribing after messages published; no history | Enable channel history in Ably Dashboard → Channel Rules; call `channel.history()` on subscribe to replay |
| Root API key leaked to client | Using root key instead of capability-scoped token | Generate tokens server-side with scoped capabilities; use `authUrl` or `authCallback` on client |
| Presence not showing members | Presence not enabled on channel; using REST connection | Use realtime connection (not REST) for presence; enable presence in channel rules |

## Liveblocks

| Symptom | Root Cause | Fix |
|---|---|---|
| `useOthers` returns empty | Room not joined; `RoomProvider` missing in component tree | Wrap component tree with `<RoomProvider roomId="..." initialPresence={{}}>` |
| Presence not updating | State updated without calling `updateMyPresence()` | Presence is opt-in; explicitly call `updateMyPresence({ cursor: { x, y } })` on mouse move |
| Storage conflicts (CRDT) | Concurrent edits causing merge issues | Use Liveblocks CRDT types (`LiveList`, `LiveMap`, `LiveObject`); avoid plain JS objects for shared state |
| Connection throttled | Too many messages per second from one client | Throttle high-frequency updates (cursor moves) to 16ms intervals with `requestAnimationFrame` |

## Supabase Realtime

| Symptom | Root Cause | Fix |
|---|---|---|
| No events received | Table not added to replication publication | Run `ALTER PUBLICATION supabase_realtime ADD TABLE tablename;` |
| Broadcast events delayed | Using `postgres_changes` instead of `broadcast` for ephemeral events | Use `channel.on("broadcast", ...)` for ephemeral events; `postgres_changes` has CDC latency |
| Channel not cleaned up | Component unmounts without unsubscribing | Call `supabase.removeChannel(channel)` in cleanup |

## Sources
- [Ably Connection State Machine](https://ably.com/docs/connect/states)
- [Ably Channel Best Practices](https://ably.com/docs/channels/best-practices)
- [Liveblocks Troubleshooting](https://liveblocks.io/docs/errors)
- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [MDN WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
