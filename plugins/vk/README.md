# vk

VK.com channel for Claude Code - DM and group-chat bridge with message history, search, attachments, and remote permission relay.

## Install

```text
/plugin marketplace add https://github.com/suxrobgm/claude-plugins
/plugin install vk@sukhrob-claude-plugins
```

Save your VK community access token, then restart with the channel attached:

```text
/vk:configure <token>
```

```bash
claude --dangerously-load-development-channels plugin:vk@sukhrob-claude-plugins
```

On first inbound DM the bot replies with a 6-character pairing code - finish with `/vk:access pair <code>`.

## Skills

- `/vk:configure` - save `VK_TOKEN` to `~/.claude/channels/vk/.env`.
- `/vk:access` - pair DMs, opt group chats in, manage allowlists and policy. Full surface in [ACCESS.md](ACCESS.md).
- `/vk:status` - connection health and channel summary.

## Requirements

- [Bun](https://bun.sh) on `$PATH` (the bundle is JavaScript, run with `bun`).
- A VK community with Bots Long Poll enabled and a token scoped `messages, photos, docs, manage`.

Full setup walkthrough - creating the community, minting a token, enabling Long Poll - lives in the [source repository](https://github.com/suxrobgm/claude-vk/blob/main/docs/setup.md).

## Source

This directory is a pre-built distribution. Source code and issue tracker: [github.com/suxrobgm/claude-vk](https://github.com/suxrobgm/claude-vk).
