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
| [`vk`](./plugins/vk) | VK.com channel - DMs, group chats, message history, attachments, remote permission relay. | [suxrobgm/claude-vk](https://github.com/suxrobgm/claude-vk) |
| [`jobpilot`](./plugins/jobpilot) | Job-search agent - search boards, tailor resumes, auto-apply. Run `setup` to install the local agent. | [suxrobgm/jobpilot](https://github.com/suxrobgm/jobpilot) |

Install with `/plugin install <name>@sukhrob-claude-plugins`.

## How this marketplace works

Most plugins under [`plugins/`](./plugins) ship as a pre-bundled JavaScript artifact (`<plugin>/dist/server.js`) plus its `.claude-plugin/plugin.json`, `.mcp.json`, and skills; **`jobpilot` is a pure Markdown/JSON skill pack with no runtime bundle and no Bun requirement.** There is **no `npm install` / `bun install` step** - cloning the marketplace is enough.

End users need [Bun](https://bun.sh) on `$PATH` to run the bundles (not required for `jobpilot`).

Each plugin's source lives in its own repository (see the table above). Release artifacts are synced into this marketplace on each tag.
