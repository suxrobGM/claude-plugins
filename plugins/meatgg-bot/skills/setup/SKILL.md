---
name: setup
description: Install the meatgg-bot support session on this machine — writes the tmux respawn script, the permission allowlist, the operating policy and an .env to fill in. Use when the user wants to set up, install or deploy the meat.gg support bot.
user-invocable: true
allowed-tools:
  - Bash(bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup*)
  - Read
---

# Set up the meat.gg support bot

Run the plugin's installer:

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup
```

If that is denied, this session is running in the bot's own working directory, whose installed
policy denies `Bash(bun *)` and outranks this skill's `allowed-tools`. Say so, and give the user
the command to run in a plain shell instead. Do not try to work around the deny.

It writes into `~/bots/meatgg/` (pass a path for another directory) and
`~/.claude/channels/meatgg/`. This is a first-install step only: the installed `respawn.sh`
reinstalls before every spawn, so later plugin updates need no re-run. The plugin owns those
files, so never patch an installed copy, change the template and ship a new version instead.
The `.env` is never touched once it exists.

Then relay its "still to do" list to the user, and offer to:

- open `~/.claude/channels/meatgg/.env` so they can paste the API key — it needs an `ApiKey`
  from `/admin/api-keys`, owned by an admin holding `VIEW_TICKETS`, scoped to `VIEW_TICKETS`,
  `MANAGE_TICKETS`, `VIEW_COMPLAINTS`, `MANAGE_COMPLAINTS`, `DELETE_CHAT_MESSAGES`;
- show the cron lines from `${CLAUDE_PLUGIN_ROOT}/deploy/README.md`.

Do not fill in the key yourself, and do not start the session for them — the session must be
launched from its own working directory so it picks up the policy and permissions just written.
