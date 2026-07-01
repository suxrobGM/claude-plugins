---
name: status
description: Show VK channel status - transport, connection health, community handle, policies, chat count. Use when the user asks "is VK connected?", "what's the status of VK?", or wants a health summary.
user-invocable: true
allowed-tools:
  - Bash(curl http://127.0.0.1:6060/healthz)
  - Bash(curl http://127.0.0.1:6060/config)
  - Bash(curl http://127.0.0.1:6060/state)
  - Bash(curl http://127.0.0.1:6060/access/*)
  - Read
---

# /vk:status - VK Channel Status

Aggregates health, runtime status, allowlist counts, and pending pairings
into a single summary.

## Steps

1. `curl -s http://127.0.0.1:6060/healthz` - combined liveness +
   readiness; returns `{"ok":true,"mcp":true}` when the MCP transport
   is connected.
2. `curl -s http://127.0.0.1:6060/state` - runtime block with
   `vkConnected`, `lastError`, `lastEventAt`, plus `recentMessagesCount`.
3. `curl -s http://127.0.0.1:6060/config` - effective config with
   `vkToken` redacted to `"***"`.
4. `curl -s http://127.0.0.1:6060/access/policy` - current DM policy
   (`pairing` or `allowlist`). Group chats are always opt-in via
   `/vk:access group add` - no group policy exists.
5. `curl -s http://127.0.0.1:6060/access/chats` - allowed chat count
   and per-chat sender count.
6. `curl -s http://127.0.0.1:6060/access/pairings` - outstanding
   pairing codes (and their expiry).
7. `curl -s http://127.0.0.1:6060/access/groups/pending` - recently
   dropped group chats with their canonical `peer_id`, ready to copy
   into `/vk:access group add`.

Render as a compact status block, e.g.:

```
VK channel
  connected:        true
  community:        @claude_vk  (id 123456789)
  last event:       2026-05-14T10:42:18Z
  policies:         dm=allowlist, group_chat=pairing
  allowed chats:    3 (12 senders total)
  pending pairings: 1
  pending groups:   1
    2000000001  hits=4  last 2026-05-14T10:42:18Z  "@claude_vk hi"
    → /vk:access group add 2000000001
```

Omit the `pending groups` section when the list is empty.

If `/healthz` is unreachable, the plugin isn't running. Remind the user
to launch with
`claude --dangerously-load-development-channels plugin:vk@sukhrob-claude-plugins`.

If `vkConnected` is `false` with `lastError: "VK_TOKEN missing"`, the
plugin booted without a token - run `/vk:configure <token>` then restart
the Claude session (the long-poll loop only reads `VK_TOKEN` at startup).
If the error starts with `vk_api_5` the token is rejected; with `vk_api_15`
the token is missing the `manage` scope or Long Poll API is disabled in
the community admin.
