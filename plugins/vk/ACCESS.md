# Access control

Every inbound message is gated on `from_id`. DMs and group chats follow
different rules:

- **DMs** — controlled by `dmPolicy`. Can self-pair.
- **Group chats** — off by default, opt in by `peer_id`. No pairing.

## DM policy

| `dmPolicy`  | Behavior                                                                |
| ----------- | ----------------------------------------------------------------------- |
| `pairing`   | Unknown DM → 6-char pairing code. Operator runs `/vk:access pair`.      |
| `allowlist` | Only listed senders forwarded; others get one "ask the operator" reply. |
| `disabled`  | Global kill switch — drops every message, allowlisted or not.           |

```text
/vk:access policy pairing|allowlist|disabled
```

## Group chats

Opt in by `peer_id` (`>= 2_000_000_000`):

```text
/vk:access group add 2000000042
/vk:access group add 2000000042 --allow 412587349,628194073 --mention-policy reply_only
/vk:access group remove 2000000042
```

To find a chat's `peer_id`: invite the bot, send a message, then `/vk:status`
shows recent dropped groups ready to copy.

Adjust after the fact:

```text
/vk:access mention-policy 2000000042 reply_only
/vk:access add-sender 2000000042 @vasiliy
/vk:access remove-sender 2000000042 412587349
```

### Mention policy (group chats only)

A non-mention from an allowed sender is silently dropped — not a denial.

| Policy                   | Forwards when...                                                                             |
| ------------------------ | -------------------------------------------------------------------------------------------- |
| `mention_only` (default) | `[club{ID}\|...]`, `@<screen_name>`, any `mentionPatterns`, or quote-reply to a bot message. |
| `all`                    | Every message from an allowed sender. Requires VK "Read all messages" on.                    |
| `reply_only`             | Only quote-replies to a bot message.                                                         |

Reply-to-bot is restart-safe — matched by `reply_message.from_id == -<communityId>`.

### Friendly mentions (`mentionPatterns`)

Root-level list in `access.json`. Case-insensitive, word-bounded literal match:

```json
"mentionPatterns": ["claude", "клод"]
```

Hot-reloads on save. `"claude"` hits `"Hey Claude, do X"` but not `"claudette"`.

### Privacy mode

VK community admin → "Bots → Conversation messages":

- **Off** — VK only delivers mentions/replies. Good pairing for `mention_only`.
- **On** — required for `mentionPolicy=all`. Without it, the long-poll sees nothing else.

## `access.json`

Lives at `~/.claude/channels/vk/access.json` (mode `0600`). Hand-edits hot-reload
on save; invalid edits are rejected and the previous version stays live.

```json
{
  "version": 1,
  "dmPolicy": "pairing",
  "mentionPatterns": ["claude", "клод"],
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
      "senders": [123456, 234567],
      "mentionPolicy": "mention_only",
      "addedAt": "2026-05-14T11:02:00Z",
      "addedBy": "manual"
    }
  },
  "pendingPairs": {
    "X7K4MQ": { "peerId": 999111, "fromId": 999111, "expiresAt": "2026-05-14T11:30:00Z" }
  }
}
```

- `chats` keys are stringified `peerId`s. DMs `< 2_000_000_000`; groups `>=`.
- `senders` (groups only): empty array means **anyone in the chat may write**.
  Omitted entirely for DMs.
- `mentionPolicy` (groups only): default `mention_only`. Applies even when `senders` is empty.
- `pendingPairs`: 6-char codes, 10-min TTL, single-use.

## DM pairing flow

1. User DMs the community.
2. Under `dmPolicy=pairing`, unknown sender → bot replies with a 6-char code.
3. Operator runs `/vk:access pair <code>`.
4. DM peer is added as `{ kind: "dm" }`.

Group chats never pair — they must be added explicitly.

## Permission relay routing

Permission prompts DM the **first `kind: "dm"` entry** in `access.json`
(deterministic, no in-memory state). No paired DM → terminal-prompt fallback
with a `<channel>` warning. Pair one via `/vk:access pair <code>`.

## `/vk:access` sub-actions

Calls `http://127.0.0.1:6060/access/*`. Full reference in
[skills/access/SKILL.md](skills/access/SKILL.md).

| Sub-action                                               | Effect                                           |
| -------------------------------------------------------- | ------------------------------------------------ |
| `pair <code>`                                            | Consume a pending DM pairing code.               |
| `group add <peer_id> [--allow ids] [--mention-policy …]` | Opt a group chat in.                             |
| `group remove <peer_id>` / `remove-chat <peer_id>`       | Drop a chat.                                     |
| `list` / `list <peer_id>`                                | List chats; per-chat sender detail.              |
| `policy <pairing\|allowlist\|disabled>`                  | Set DM policy.                                   |
| `add-sender <peer_id> <user>`                            | Add user (id or `@screen_name`) to a group chat. |
| `remove-sender <peer_id> <user_id>`                      | Drop a sender from a group chat.                 |
| `mention-policy <peer_id> <policy>`                      | Group chats only.                                |
| `pending`                                                | List outstanding pairing codes.                  |

## Notes

- **Removed bot.** When the bot is kicked from a group, the chat is marked
  inactive (kept for audit) and forwarding stops.
- **Sender management.** `add-sender` accepts numeric IDs and `@screen_name`
  (resolved via `users.get`, stored as IDs).
