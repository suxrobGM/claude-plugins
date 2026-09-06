---
name: setup
description: Install the meatgg-bot support session on this machine. Writes the tmux respawn script, permissions, operating policy and an .env to fill in. Use when the user wants to set up, install or deploy the meat.gg support bot.
user-invocable: true
allowed-tools:
  - Bash(bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup*)
  - Read
---

# Set up the meat.gg support bot

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup
```

Denied? Then this session runs in the bot's own working directory, whose policy denies
`Bash(bun *)` and outranks this skill. Say so and give the user the command for a plain shell.

It installs into `~/bots/meatgg/` (pass a path for another directory) and
`~/.claude/channels/meatgg/`. The plugin owns those files and `respawn.sh` reinstalls them
before every spawn, so never patch an installed copy. The `.env` is never touched once it
exists.

Relay the printed "still to do" list, then offer to:

- open `~/.claude/channels/meatgg/.env` for the API key. It must be an `ApiKey` from
  `/admin/api-keys`, owned by an admin holding `VIEW_TICKETS`, scoped to the write permissions
  `MANAGE_TICKETS`, `MANAGE_COMPLAINTS`, `MANAGE_DROPS`, `MANAGE_PUNISHMENTS`,
  `DELETE_CHAT_MESSAGES` plus the reads the bot answers from: `VIEW_TICKETS`, `VIEW_COMPLAINTS`, `VIEW_USERS`, `VIEW_PUNISHMENTS`, `VIEW_DROPS`,
  `VIEW_SUBSCRIPTIONS`, `VIEW_RULES`, `VIEW_SERVERS`, `VIEW_SITE_SETTINGS`. A tool the key
  lacks permission for is not listed at all. The bot user's own AdminProfile still needs
  `MANAGE_TICKETS` and `MANAGE_COMPLAINTS`, since the replies, `assign_ticket` and
  `set_complaint_status` act as the bot rather than as the key's owner;
- show the cron lines from `${CLAUDE_PLUGIN_ROOT}/deploy/README.md`.

Do not fill in the key and do not start the session: it has to launch from its own working
directory to pick up the policy just written.
