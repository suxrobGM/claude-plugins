---
name: access
description: Manage VK channel access - pair DMs, opt group chats in, edit allowlists, set DM policy. Use when the user wants to pair a DM, add or remove a group chat, approve a sender, list allowed chats, or change DM policy for the VK channel.
user-invocable: true
allowed-tools:
  - Bash(curl http://127.0.0.1:6060/access/*)
  - Read
---

# /vk:access - VK Channel Access Control

Calls the local management API at `http://127.0.0.1:6060/access/*` to manage
who can reach the VK channel.

- **DMs** are gated by `dmPolicy` (`pairing` by default). Unknown DMs receive
  a 6-character code; the operator runs `pair <code>` to approve.
- **Group chats** are off by default. Opt each one in by `peerId` with
  `group add <peerId>` - there is no group pairing flow.

Arguments: `$ARGUMENTS` - the first token is the sub-action, the rest are
sub-action arguments.

---

## Sub-actions

### `pair <code>` - DM only

Consume a pairing code that the bot DM'd. On success the originating DM peer
is added to `access.json → chats`.

```bash
curl -s -X POST http://127.0.0.1:6060/access/pairings \
  -H 'content-type: application/json' \
  -d '{"code":"<CODE>"}'
```

### `group add <peerId> [--allow id1,id2] [--mention-policy mention_only|all|reply_only]`

Opt a group chat in. VK group-chat peer ids are `>= 2_000_000_000`. Optional
flags seed the initial sender allowlist and mention policy (defaults:
`senders=[]` meaning anyone in the chat may write, `mentionPolicy=mention_only`).

```bash
# minimal: trust the whole chat, mention-only activation
curl -s -X POST http://127.0.0.1:6060/access/groups \
  -H 'content-type: application/json' \
  -d '{"peerId":2000000042}'

# lock down to two members and forward every message
curl -s -X POST http://127.0.0.1:6060/access/groups \
  -H 'content-type: application/json' \
  -d '{"peerId":2000000042,"allow":[123456,234567],"mentionPolicy":"all"}'
```

### `group remove <peerId>`

Drop a group chat entirely. Same endpoint as `remove-chat`.

```bash
curl -s -X DELETE http://127.0.0.1:6060/access/chats/<peerId>
```

### `list` and `list <peerId>`

```bash
# all allowed chats
curl -s http://127.0.0.1:6060/access/chats

# one chat with its senders
curl -s http://127.0.0.1:6060/access/chats/<peerId>
```

### `policy <pairing|allowlist|disabled>`

`pairing` and `allowlist` only affect DMs (group chats are opt-in by `peerId`). `disabled` is a global kill switch that silences DMs and group chats.

- `pairing` (default): unknown DMs get a 6-char code; known senders pass.
- `allowlist`: only listed senders pass; others get one "ask the operator" reply per 24h.
- `disabled`: global kill switch - every inbound message (DMs and group chats, allowlisted or not) is dropped silently.

```bash
curl -s -X PUT http://127.0.0.1:6060/access/policy \
  -H 'content-type: application/json' \
  -d '{"policy":"<policy>"}'
```

### `add-sender <peerId> <userId|@screenName>`

Group chats only. Numeric id or `@screenName`. DMs reject (single sender).

```bash
# numeric
curl -s -X POST http://127.0.0.1:6060/access/chats/<peerId>/senders \
  -H 'content-type: application/json' \
  -d '{"userId":123456}'

# screen name
curl -s -X POST http://127.0.0.1:6060/access/chats/<peerId>/senders \
  -H 'content-type: application/json' \
  -d '{"screenName":"vasiliy"}'
```

### `remove-sender <peerId> <userId>`

```bash
curl -s -X DELETE http://127.0.0.1:6060/access/chats/<peerId>/senders/<userId>
```

### `remove-chat <peerId>`

```bash
curl -s -X DELETE http://127.0.0.1:6060/access/chats/<peerId>
```

### `pending`

Outstanding pairing codes (peer + expiry).

```bash
curl -s http://127.0.0.1:6060/access/pairings
```

### `mention-policy <peerId> <mention_only|all|reply_only>`

Group-chat activation policy. Controls _when_ the bot activates on allowed
senders - `mention_only` (default) wakes only on `@<community>` or replies
to the bot; `reply_only` wakes only on direct replies; `all` forwards every
allowed-sender message.

```bash
curl -s -X PUT http://127.0.0.1:6060/access/chats/<peerId>/mention-policy \
  -H 'content-type: application/json' \
  -d '{"policy":"mention_only"}'
```

---

## Notes

- Hand-editing `~/.claude/channels/vk/access.json` works too - the server
  watches the file and hot-reloads valid edits. Malformed edits are rejected
  and the previous version stays live.
- All endpoints validate input. Errors come back as `{ "error": "..." }`
  with a 4xx status; successful mutations return `{ "ok": true, ... }`.
