---
name: status
description: Show VK channel status — transport, connection health, community handle, policies, chat count. Use when the user asks "is VK connected?", "what's the status of VK?", or wants a health summary.
user-invocable: true
allowed-tools:
  - Bash(curl http://127.0.0.1:6060/healthz)
  - Bash(curl http://127.0.0.1:6060/readyz)
  - Bash(curl http://127.0.0.1:6060/admin/*)
  - Read
---

# /vk:status — VK Channel Status

Aggregates health, runtime status, allowlist counts, and pending pairings
into a single summary.

## Steps

1. `curl -s http://127.0.0.1:6060/healthz` — should return `{"ok":true}`.
2. `curl -s http://127.0.0.1:6060/readyz` — `{"ok":true,"mcp":true}` once
   the MCP transport is connected.
3. `curl -s http://127.0.0.1:6060/admin/state` — runtime block with
   `vk_connected`, `last_error`, `last_event_at`, plus `recent_messages_count`.
4. `curl -s http://127.0.0.1:6060/admin/config` — effective config with
   `vk_token` redacted to `"***"`.
5. `curl -s http://127.0.0.1:6060/admin/access/policies` — current DM and
   group-chat policies.
6. `curl -s http://127.0.0.1:6060/admin/access/chats` — allowed chat count
   and per-chat sender count.
7. `curl -s http://127.0.0.1:6060/admin/access/pairings` — outstanding
   pairing codes (and their expiry).

Render as a compact status block, e.g.:

```
VK channel
  connected:        true
  community:        @claude_vk  (id 123456789)
  last event:       2026-05-14T10:42:18Z
  policies:         dm=allowlist, group_chat=pairing
  allowed chats:    3 (12 senders total)
  pending pairings: 1
```

If either liveness probe fails, the plugin isn't running. Remind the user
to launch with
`claude --dangerously-load-development-channels plugin:vk@claude-plugins`.

If `vk_connected` is `false` with `last_error: "VK_TOKEN missing"`, the
plugin booted without a token — run `/vk:configure <token>` then restart
the Claude session (the long-poll loop only reads `VK_TOKEN` at startup).
If the error starts with `vk_api_5` the token is rejected; with `vk_api_15`
the token is missing the `manage` scope or Long Poll API is disabled in
the community admin.
