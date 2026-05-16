# claude-plugins

Claude Code plugins by [Sukhrob Ilyosbekov](https://github.com/suxrobgm). Pre-bundled, no install step.

## Use

```text
/plugin marketplace add https://github.com/suxrobgm/claude-plugins
```

Then pick a plugin from the list below.

## Plugins

| Plugin | What it does | Source |
| --- | --- | --- |
| [`vk`](./plugins/vk) | VK.com channel — DMs, group chats, message history, attachments, remote permission relay. | [suxrobgm/claude-vk](https://github.com/suxrobgm/claude-vk) |

Install with `/plugin install <name>@sukhrob-claude-plugins`.

## How this marketplace works

Each plugin under [`plugins/`](./plugins) ships as a pre-bundled JavaScript artifact (`<plugin>/dist/server.js`) plus its `.claude-plugin/plugin.json`, `.mcp.json`, and skills. There is **no `npm install` / `bun install` step** — cloning the marketplace is enough.

End users need [Bun](https://bun.sh) on `$PATH` to run the bundles.

Each plugin's source lives in its own repository (see the table above). Release artifacts are synced into this marketplace on each tag.
