# Access control

`claude-vk` gates every inbound message through a **two-layer allowlist**: the
chat itself must be allowed, and within each allowed chat there is a per-chat
list of trusted sender user IDs. The check runs on `from_id`, not `peer_id` —
so a user trusted in a DM is not automatically trusted in a group chat.

Group chats get a third layer (mention activation) that decides which kinds
of messages from an allowed sender actually wake Claude up.

The two access flows are deliberately different:

- **DMs** are gated by a `dmPolicy` and can pair themselves automatically.
- **Group chats** are off by default and have to be opted in by `peer_id`.
  There is no group pairing flow.

## DM policies

Set via `dmPolicy`. Default is `pairing`.

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

VK group-chat peer ids are `>= 2_000_000_000`. The easiest way to find one
is to invite the bot, send a message, and look at the recent dropped chats
in the server log — group chats with no entry in `access.json` are silently
dropped, but the drop is logged with the `peer_id`.

### Group-specific options

```text
/vk:access group add 2000000042 --mention-policy all
/vk:access group add 2000000042 --allow 412587349,628194073
/vk:access group remove 2000000042
```

- **`mention_policy: "mention_only"` (default):** bot responds only to
  `@<community>` mentions or replies to one of its own messages.
- **`mention_policy: "all"`:** every message from an allowed sender is
  forwarded. Requires VK community privacy mode "Read all messages" to be
  on for the long-poll to actually deliver everything.
- **`mention_policy: "reply_only"`:** wakes only on direct replies to the bot.
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
`mention_policy=all` you need privacy mode disabled in the community admin,
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
  "policies": {
    "dm": "allowlist"
  },
  "chats": {
    "123456": {
      "kind": "dm",
      "title": "Ivan Petrov",
      "senders": [123456],
      "added_at": "2026-05-14T10:21:00Z",
      "added_by": "pairing"
    },
    "2000000042": {
      "kind": "group_chat",
      "title": "Team Standup",
      "senders": [123456, 234567, 345678],
      "mention_policy": "mention_only",
      "added_at": "2026-05-14T11:02:00Z",
      "added_by": "manual"
    }
  },
  "pending_pairs": {
    "X7K4MQ": {
      "peer_id": 999111,
      "from_id": 999111,
      "expires_at": "2026-05-14T11:30:00Z"
    }
  }
}
```

- Keys under `chats` are stringified `peer_id`s. DM peers are user IDs
  (`< 2_000_000_000`); group-chat peers are `>= 2_000_000_000`.
- `senders` is an array of VK user IDs. **An empty `senders` array means
  "no per-sender restriction" — anyone in this chat may message Claude.**
  Group `add` leaves it empty unless `--allow` is supplied. DM pairing seeds
  it with the DM peer's user id (a DM has only ever one possible sender
  anyway).
- `mention_policy` (group chats only): `mention_only` (default), `all`, or
  `reply_only`. The mention layer still applies even when `senders` is empty.
- `pending_pairs` is the live DM pairing table. Codes are 6 chars from a
  32-char alphabet (no `0/O/1/I/L`), TTL 10 minutes, single-use.

## Pairing flow (DM only)

1. A user DMs the community on VK.
2. If `dmPolicy=pairing` and the sender is unknown, the bot replies with a
   6-character code and stores it in `pending_pairs`.
3. The operator runs `/vk:access pair <code>` in their Claude session.
4. The DM peer is added to `chats` with the sender's `user_id` in `senders`.

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
| `add-sender <peer_id> <user>`                            | Add user (numeric id or `@screen_name`) to a chat.    |
| `remove-sender <peer_id> <user_id>`                      | Drop a sender from a chat.                            |
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
  `mention_policy`.
- **Removed bot.** When the bot is kicked, VK emits a `chat_kick_user`
  event. The chat is marked inactive (kept for audit) and forwarding stops.
- **Sender management.** `add-sender` accepts numeric IDs and `@screen_name`.
  Screen names are resolved via `users.get` and stored as IDs.
