# Access control

`claude-vk` gates every inbound message on `from_id`. The chat must be
allowed; group chats additionally carry a per-chat sender allowlist and a
mention-activation policy. DMs have one implicit sender, so no `senders[]`.

The two flows are deliberately different:

- **DMs** are gated by `dmPolicy` and can pair themselves automatically.
- **Group chats** are off by default — opt in by `peer_id`. No group pairing.

## Policies

Set via `dmPolicy`. Default is `pairing`. `pairing` and `allowlist` only affect DMs (group chats are always opt-in by `peerId`); `disabled` is a global kill switch that silences both.

| Policy      | Behavior                                                                                                       |
| ----------- | -------------------------------------------------------------------------------------------------------------- |
| `pairing`   | Unknown DM senders receive a 6-character pairing code. The operator runs `/vk:access pair <code>` to add them. |
| `allowlist` | Only the senders listed in `access.json` are forwarded; denials reply with a one-time "ask the operator" note. |
| `disabled`  | Global kill switch — every inbound message is dropped silently, **DMs and group chats**, allowlisted or not.   |

Switch the policy:

```text
/vk:access policy pairing
/vk:access policy allowlist
/vk:access policy disabled
```

## Group chat access (key differences from DM pairing)

### Adding groups

Groups are **off by default**. Opt each one in by `peer_id`:

```text
/vk:access group add 2000000042
```

VK group-chat peer ids (`>= 2_000_000_000`) are **community-relative** —
the number in `vk.com/im/convo/N` is not the `peer_id` the bot receives.
To discover it: invite the bot, send a message, then run `/vk:status` —
recent dropped groups show up there ready to copy into `/vk:access group add`.

### Group-specific options

```text
/vk:access group add 2000000042 --mention-policy all
/vk:access group add 2000000042 --allow 412587349,628194073
/vk:access group remove 2000000042
```

- **`mentionPolicy: "mention_only"` (default):** bot responds only to
  `@<community>` mentions or replies to one of its own messages.
- **`mentionPolicy: "all"`:** every message from an allowed sender is
  forwarded. Requires VK community privacy mode "Read all messages" to be
  on for the long-poll to actually deliver everything.
- **`mentionPolicy: "reply_only"`:** wakes only on direct replies to the bot.
- **`--allow id1,id2`:** seed the per-chat sender allowlist. Empty means
  "anyone in this chat may write to the bot".

You can also change either field after the fact:

```text
/vk:access mention-policy 2000000042 reply_only
/vk:access add-sender 2000000042 @vasiliy
/vk:access remove-sender 2000000042 412587349
```

### Privacy-mode requirement

VK community admin → "Bots → Conversation messages" exposes a privacy switch.
With it off, VK only delivers messages where the bot is mentioned or replied
to — useful belt-and-braces alongside `mention_only`. To use
`mentionPolicy=all` you need privacy mode disabled in the community admin,
otherwise nothing reaches the long-poll regardless of the local config.

## Key differences: groups vs. DMs

| Aspect            | DMs (pairing)                               | Group chats                                               |
| ----------------- | ------------------------------------------- | --------------------------------------------------------- |
| **Default state** | Enabled, requires approval                  | Disabled, opt-in                                          |
| **Approval flow** | Automatic pairing code exchange             | Manual `/vk:access group add <peer_id>`                   |
| **Mention gate**  | N/A                                         | `mention_only` (default), `all`, or `reply_only`          |
| **Sender filter** | Optional `add-sender`; pairing seeds the DM | Optional `--allow` list per group; empty = anyone in chat |
| **Privacy mode**  | N/A                                         | Affects message delivery; toggle in VK community admin    |

## `access.json`

Lives at `~/.claude/channels/vk/access.json`, mode `0600`. Hand-editable —
the server hot-reloads on save and rejects malformed edits while keeping the
previous version live.

```json
{
  "version": 1,
  "dmPolicy": "pairing",
  "chats": {
    "123456": {
      "kind": "dm",
      "title": "Ivan Petrov",
      "addedAt": "2026-05-14T10:21:00Z",
      "addedBy": "pairing"
    },
    "2000000042": {
      "kind": "group_chat",
      "title": "Team Standup",
      "senders": [123456, 234567, 345678],
      "mentionPolicy": "mention_only",
      "addedAt": "2026-05-14T11:02:00Z",
      "addedBy": "manual"
    }
  },
  "pendingPairs": {
    "X7K4MQ": {
      "peerId": 999111,
      "fromId": 999111,
      "expiresAt": "2026-05-14T11:30:00Z"
    }
  }
}
```

- Keys under `chats` are stringified `peerId`s. DM peers are user IDs
  (`< 2_000_000_000`); group-chat peers are `>= 2_000_000_000`.
- `senders` (group chats only) is an array of VK user IDs. **An empty
  `senders` array means "no per-sender restriction" — anyone in this chat may
  message Claude.** Group `add` leaves it empty unless `--allow` is supplied.
  DM entries omit the field entirely — a DM only ever has one sender.
- `mentionPolicy` (group chats only): `mention_only` (default), `all`, or
  `reply_only`. The mention layer still applies even when `senders` is empty.
- `pendingPairs` is the live DM pairing table. Codes are 6 chars from a
  32-char alphabet (no `0/O/1/I/L`), TTL 10 minutes, single-use.

## Pairing flow (DM only)

1. A user DMs the community on VK.
2. If `policy=pairing` and the sender is unknown, the bot replies with a
   6-character code and stores it in `pendingPairs`.
3. The operator runs `/vk:access pair <code>` in their Claude session.
4. The DM peer is added to `chats` as `{ kind: "dm" }`.

Group chats never receive a pairing code automatically — adding the bot to
a chat is not enough on its own. Use `/vk:access group add <peer_id>`.

## Mention policy (group chats only)

Activation filter applied after the sender check. A non-mention from an
allowed sender is silently dropped — it isn't an access denial.

| Policy                   | Forwards to Claude when...                                                                         |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| `mention_only` (default) | The message mentions `[club{ID}\|...]`, `@<screen_name>`, or replies to one of the bot's messages. |
| `all`                    | Every message from an allowed sender.                                                              |
| `reply_only`             | Only replies to one of the bot's own messages.                                                     |

Change it:

```text
/vk:access mention-policy <peer_id> mention_only
/vk:access mention-policy <peer_id> all
/vk:access mention-policy <peer_id> reply_only
```

## `/vk:access` sub-actions

The slash skill calls the local management API at
`http://127.0.0.1:6060/access/*`. Full reference in
[skills/access/SKILL.md](skills/access/SKILL.md).

| Sub-action                                               | Effect                                                |
| -------------------------------------------------------- | ----------------------------------------------------- |
| `pair <code>`                                            | Consume a pending DM pairing code.                    |
| `group add <peer_id> [--allow ids] [--mention-policy …]` | Opt a group chat in (groups only).                    |
| `group remove <peer_id>`                                 | Drop a group chat (alias of `remove-chat <peer_id>`). |
| `list` / `list <peer_id>`                                | List allowed chats; per-chat sender detail.           |
| `policy <pairing\|allowlist>`                            | Set DM policy.                                        |
| `add-sender <peer_id> <user>`                            | Add user (id or `@screen_name`) to a group chat.      |
| `remove-sender <peer_id> <user_id>`                      | Drop a sender from a group chat.                      |
| `remove-chat <peer_id>`                                  | Drop a chat entirely.                                 |
| `mention-policy <peer_id> <policy>`                      | Group chats only.                                     |
| `pending`                                                | List outstanding pairing codes.                       |

## Hand-editing

Editing `access.json` directly is supported. The plugin watches the file via
`fs.watch` and reloads on save. Each load is validated against the TypeBox
schema — malformed edits are rejected with a `<channel>` warning and the
previous version stays live.

## Group-chat specifics

- **Privacy mode.** Leave "Read all messages" **off** in the community admin
  unless you really need it. With it off, VK only delivers messages where
  the bot is mentioned or replied-to — a useful belt-and-braces alongside
  `mentionPolicy`.
- **Removed bot.** When the bot is kicked, VK emits a `chat_kick_user`
  event. The chat is marked inactive (kept for audit) and forwarding stops.
- **Sender management.** `add-sender` accepts numeric IDs and `@screen_name`.
  Screen names are resolved via `users.get` and stored as IDs.
