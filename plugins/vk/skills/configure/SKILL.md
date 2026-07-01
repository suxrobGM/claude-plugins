---
name: configure
description: Set up the VK channel - save the community access token to ~/.claude/channels/vk/.env. Use when the user pastes a VK community token or asks to configure VK.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash(ls *)
  - Bash(mkdir *)
---

# /vk:configure - VK Channel Setup

Writes `VK_TOKEN` to `~/.claude/channels/vk/.env` (mode `0600`). The plugin
reads this file at startup and merges it under `process.env` (shell env wins
on conflict). Only `VK_TOKEN` is required; the community id and screen name
are resolved automatically at startup via `groups.getById`.

Arguments passed: `$ARGUMENTS`

---

## Flow

1. Ensure `~/.claude/channels/vk/` exists: `mkdir -p ~/.claude/channels/vk`.
2. Read `~/.claude/channels/vk/.env` if it exists and report which `VK_*`
   keys are already set (mask `VK_TOKEN` to `***`).
3. If the user passed a token in `$ARGUMENTS`, **use the Write tool** to
   create/overwrite `~/.claude/channels/vk/.env` with at minimum:

   ```env
   VK_TOKEN=<the token>
   ```

   Preserve any other keys (`PORT`, `LOG_LEVEL`, `NODE_ENV`) that were
   already in the file.

4. Tell the user to **restart this Claude session** - the long-poll loop
   reads `VK_TOKEN` at startup, not on `.env` hot reload.
5. After restart, the bot DMs a 6-character pairing code on first inbound
   message; finish with `/vk:access pair <code>` (see
   [access](../access/SKILL.md)).

## Prerequisite - enable Long Poll in the community admin

vk.com → Manage → Settings → API usage → Long Poll API → **Enabled**, API
version ≥ `5.199`, check the `message_new` event. Token must have the
`messages, photos, docs, manage` scopes - `manage` is required for
`groups.getLongPollServer`. Without these, the long-poll loop sits in backoff
or fails with VK error 15.
