---
name: uninstall
description: Remove the VK bot session from this machine - stops it, drops its cron schedule and deletes the files setup installed. Use when the user wants to uninstall, remove or disable the VK bot.
user-invocable: true
allowed-tools:
  - Bash(bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall*)
  - Read
---

# Remove the VK bot

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall
```

Stops the tmux session, removes its cron entries and deletes `~/bots/vk/`. The channel config -
the token, access policy, paired peers and logs in `~/.claude/channels/vk/` - is kept unless you
pass `--all`.

Ask before passing `--all`: it deletes `VK_TOKEN` and the paired-peer list with everything else,
so every peer has to re-pair afterwards. Pass a directory as the first argument if the session
was installed somewhere other than `~/bots/vk`.

Then relay the step it prints, which has to happen from a Claude Code session rather than a
shell: `/plugin uninstall vk@claude-vk`. Mention that the community token itself still exists in
the VK admin panel and should be revoked there.
