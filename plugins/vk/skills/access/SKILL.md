---
name: access
description: Manage VK channel access — pair new chats, edit allowlists, set policy. Use when the user wants to pair, approve a sender, list allowed chats, or change policy for the VK channel.
user-invocable: true
allowed-tools:
  - Bash(curl http://127.0.0.1:6060/admin/access/*)
  - Read
---

# /vk:access — VK Channel Access Control

Calls the local admin API at `http://127.0.0.1:6060/admin/access/*` to manage
who is allowed to reach the VK channel. The plugin's gate drops everything
that isn't on this allowlist (unless the policy is `pairing`, in which case
unknown DMs get a 6-character code that this skill consumes).

Arguments: `$ARGUMENTS` — the first token is the sub-action, the rest are
sub-action arguments.

---

## Sub-actions

### `pair <code>`

Consume a pairing code that the bot DM'd. On success the originating peer is
added to `access.json → chats`.

```bash
curl -s -X POST http://127.0.0.1:6060/admin/access/pairings \
  -H 'content-type: application/json' \
  -d '{"code":"<CODE>"}'
```

### `list` and `list <peer_id>`

```bash
# all allowed chats
curl -s http://127.0.0.1:6060/admin/access/chats

# one chat with its senders
curl -s http://127.0.0.1:6060/admin/access/chats/<peer_id>
```

### `policy <peer_type> <policy>`

`peer_type` is `dm` or `group_chat`; `policy` is `pairing` or `allowlist`.

```bash
curl -s -X PUT http://127.0.0.1:6060/admin/access/policies/<peer_type> \
  -H 'content-type: application/json' \
  -d '{"policy":"<policy>"}'
```

### `add-sender <peer_id> <user_id|@screen_name>`

Either a numeric VK user id or an `@screen_name` works; the plugin resolves
screen names via `users.get`.

```bash
# numeric
curl -s -X POST http://127.0.0.1:6060/admin/access/chats/<peer_id>/senders \
  -H 'content-type: application/json' \
  -d '{"user_id":123456}'

# screen name
curl -s -X POST http://127.0.0.1:6060/admin/access/chats/<peer_id>/senders \
  -H 'content-type: application/json' \
  -d '{"screen_name":"vasiliy"}'
```

### `remove-sender <peer_id> <user_id>`

```bash
curl -s -X DELETE http://127.0.0.1:6060/admin/access/chats/<peer_id>/senders/<user_id>
```

### `remove-chat <peer_id>`

```bash
curl -s -X DELETE http://127.0.0.1:6060/admin/access/chats/<peer_id>
```

### `pending`

Outstanding pairing codes (peer + expiry).

```bash
curl -s http://127.0.0.1:6060/admin/access/pairings
```

### `mention-policy <peer_id> <mention_only|all|reply_only>`

Group-chat activation policy. Controls _when_ the bot activates on allowed
senders — `mention_only` (default) wakes only on `@<community>` or replies
to the bot; `reply_only` wakes only on direct replies; `all` forwards every
allowed-sender message.

```bash
curl -s -X PUT http://127.0.0.1:6060/admin/access/chats/<peer_id>/mention-policy \
  -H 'content-type: application/json' \
  -d '{"policy":"mention_only"}'
```

---

## Notes

- Hand-editing `~/.claude/channels/vk/access.json` works too — the server
  watches the file and hot-reloads valid edits. Malformed edits are rejected
  and the previous version stays live.
- All endpoints validate input. Errors come back as `{ "error": "..." }`
  with a 4xx status; successful mutations return `{ "ok": true, ... }`.
