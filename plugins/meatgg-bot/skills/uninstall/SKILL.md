---
name: uninstall
description: Remove the meatgg-bot support session from this machine. Stops it, drops its cron schedule and deletes the files setup installed. Use when the user wants to uninstall, remove or disable the meat.gg support bot.
user-invocable: true
allowed-tools:
  - Bash(bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall*)
  - Read
---

# Remove the meat.gg support bot

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall
```

Denied? Then this session runs in the bot's own working directory, whose policy denies
`Bash(bun *)`. Give the user the command for a plain shell.

Stops the tmux session, removes its cron entries and deletes `~/bots/meatgg/` (pass a
directory if it was installed elsewhere). The channel config in `~/.claude/channels/meatgg/`,
API key included, is kept unless you pass `--all`. Ask before `--all`: the key cannot be
recovered from the machine afterwards.

Relay the printed last step, which needs a Claude Code session rather than a shell:
`/plugin uninstall meatgg-bot@sukhrob-claude-plugins` (`@meat-app` for a checkout install).
Mention that the ApiKey still exists in `/admin/api-keys` and should be revoked there.
