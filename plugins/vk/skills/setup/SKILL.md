---
name: setup
description: Install the VK bot session on this machine - writes the tmux respawn script, the permission allowlist, the operating policy and an .env to fill in. Use when the user wants to set up, install or deploy the VK bot on a VPS.
user-invocable: true
allowed-tools:
  - Bash(bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup*)
  - Read
---

# Set up the VK bot

Run the plugin's installer:

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup
```

It writes into `~/bots/vk/` (pass a path for another directory) and `~/.claude/channels/vk/`,
then schedules the respawn cron. Re-run it after a plugin update: the plugin owns those files
and rewrites them, so never patch an installed copy - change the template in `deploy/` and ship
a new version. The `.env` is never touched once it exists.

The installed `respawn.sh` is pointed at the directory you passed, so a non-default workdir
works without hand-editing the script.

Then relay its "still to do" list, and offer to:

- open `~/.claude/channels/vk/.env` so they can paste `VK_TOKEN` - a community access token from
  vk.com -> Manage -> API usage -> Access tokens, with the `messages, photos, docs, manage`
  scopes, and Long Poll API enabled at version >= 5.199 with `message_new` checked;
- show the operating notes in `${CLAUDE_PLUGIN_ROOT}/deploy/README.md`.

Do not fill in the token yourself, and do not start the session for them - it must be launched
from its own working directory so it picks up the policy and permissions just written.

After the first inbound message the bot DMs a 6-character pairing code; finish with
`/vk:access pair <code>`.
