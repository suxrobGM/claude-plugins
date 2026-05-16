# vk

VK.com channel for Claude Code — DM and group-chat bridge with message history, search, attachments, and remote permission relay.

## Install

```text
/plugin marketplace add https://github.com/suxrobgm/claude-plugins
/plugin install vk@claude-plugins
```

Then save your VK community access token:

```text
/vk:configure <token>
```

And restart with the channel attached:

```bash
claude --dangerously-load-development-channels plugin:vk@claude-plugins
```

## Requirements

- [Bun](https://bun.sh) on `$PATH` (the bundle is JavaScript, run with `bun`).
- A VK community with bot capabilities + Bots Long Poll enabled.

Full setup walkthrough, including how to create the community and mint a token, is in the [source repository](https://github.com/suxrobgm/claude-vk/blob/main/docs/setup.md).

## Source

This directory is a pre-built distribution. Source code, issue tracker, and PRD live at [github.com/suxrobgm/claude-vk](https://github.com/suxrobgm/claude-vk).
