---
name: uninstall
description: Remove the meatgg-bot support session from this machine — stops it, drops its cron schedule and deletes the files setup installed. Use when the user wants to uninstall, remove or disable the meat.gg support bot.
user-invocable: true
allowed-tools:
  - Bash(bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall*)
  - Read
---

# Remove the meat.gg support bot

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall
```

If that is denied, this session is running in the bot's own working directory, whose installed
policy denies `Bash(bun *)`. Give the user the command to run in a plain shell instead.

Stops the tmux session, removes its cron entries and deletes `~/bots/meatgg/`. The channel
config — the API key, settings and logs in `~/.claude/channels/meatgg/` — is kept unless you
pass `--all`.

Ask before passing `--all`: it deletes the API key with everything else, and the key cannot be
recovered from the machine afterwards. Pass a directory as the first argument if the session was
installed somewhere other than `~/bots/meatgg`.

Then relay the step it prints, which has to happen from a Claude Code session rather than a
shell: `/plugin uninstall meatgg-bot@sukhrob-claude-plugins` (`@meat-app` if it was installed
from a repo checkout). Mention that the ApiKey itself still exists in `/admin/api-keys` and
should be revoked there.
