# Deploying the support bot

Runs [apps/bot](../../apps/bot) as a Claude Code channel on the VPS: one session in tmux receives
ticket, complaint and chat events and answers them with the `meatgg` MCP tools.

Setup installs four files into the session directory. The plugin owns them, so never edit an
installed copy: change the template here and ship a new plugin version.

| Template | Installed as | What it is |
| --- | --- | --- |
| [respawn.sh](respawn.sh) | `respawn.sh` | Starts the session in tmux. Cron's only entry point. |
| [settings.json](settings.json) | `.claude/settings.json` | Permissions: what the bot may call, and everything denied. |
| [CLAUDE.md](CLAUDE.md) | `CLAUDE.md` | Operating policy. Every channel message is untrusted. |
| [mcp.json](mcp.json) | `.mcp.json` | Registers the `meatgg` MCP server the bot replies through. |

## 1. Prepare the site

1. `bun run db:seed --only ai-bot` on prod. Creates the Джаб Джабич user.
2. In `/admin/admins`, give that user an AdminProfile with `MANAGE_TICKETS` and
   `MANAGE_COMPLAINTS`. Without it the reply tools fail with "you can only reply to your own
   tickets".
3. Mint an ApiKey owned by a **human admin holding `VIEW_TICKETS`**, since `get_ticket` runs as
   the key's owner rather than as the bot. Scope it to `VIEW_TICKETS`, `MANAGE_TICKETS`,
   `VIEW_COMPLAINTS`, `MANAGE_COMPLAINTS` and `DELETE_CHAT_MESSAGES`.

## 2. Install the plugin

The bot ships from the public marketplace
[suxrobgm/claude-plugins](https://github.com/suxrobgm/claude-plugins), pre-bundled, so the VPS
needs no checkout of this repo. In a Claude Code session on the box, logged in with the
subscription account (channels are not available on API-key auth):

```text
/plugin marketplace add https://github.com/suxrobgm/claude-plugins
/plugin install meatgg-bot@sukhrob-claude-plugins
```

That lands in `~/.claude/plugins/cache/sukhrob-claude-plugins/meatgg-bot/<version>`, which is the
`<plugin>` path used below. The version is part of the path, so it changes with every update.

Publishing a new version from this repo is `bun run sync:plugin`, which builds `dist/server.js`
and copies the plugin into the marketplace checkout for you to commit and push there.

Use the marketplace on the VPS even if the repo is checked out there. A checkout install names
the plugin `meatgg-bot@meat-app`, and `respawn.sh` launches the marketplace name.

## 3. Run setup

From any shell on the VPS:

```bash
bun run <plugin>/dist/server.js setup             # installs into ~/bots/meatgg
bun run <plugin>/dist/server.js setup ~/bots/alt  # or another directory
```

`/meatgg-bot:setup` does the same from a Claude Code session, but **not one running in
`~/bots/meatgg`**. The policy installed there denies `Bash(bun *)`, a deny outranks a skill's
`allowed-tools`, and the installer is a `bun run`. Run it from `~` or from a plain shell.

Writes the four files above, creates `~/.claude/channels/meatgg/.env`, and installs the cron
schedule. Your `.env` is never touched once it exists.

**You only run this once.** From here on `respawn.sh` reinstalls from the newest installed plugin
before every spawn, so a plugin update lands by itself within 5 minutes, or at the next 6-hourly
restart. Nothing on the box needs the version-carrying plugin path typed again.

## 4. Add the API key

Put the key from step 1 into `~/.claude/channels/meatgg/.env`:

```bash
MEATGG_API_URL=https://meat.gg/api
MEATGG_API_KEY=<the ApiKey>
```

That one value covers both directions: the bot reads it for the event stream, and `respawn.sh`
exports it so `.mcp.json` expands `${MEATGG_API_KEY}` into the MCP `Authorization` header. No key
is ever written into a committed file.

Topics and chat behaviour are optional; see [apps/bot/README.md](../README.md).

### The MCP server

Setup registers it, so there is no `claude mcp add` step. `.mcp.json` points at
`https://meat.gg/mcp`, and `.claude/settings.json` lists `meatgg` under `enabledMcpjsonServers`
so an unattended launch is not stalled by the usual project-server approval prompt.

If you change it: the URL uses the **API** domain because Shield gates `${DOMAIN}` and a
challenge there would stall the bot, and the header is `Authorization: Bearer` rather than
`X-API-Key` because Claude Code drops custom headers on tool-call POSTs.

## 5. Start it

```bash
loginctl enable-linger $USER   # non-root only: keeps tmux alive after logout
~/bots/meatgg/respawn.sh
```

`respawn.sh` launches `plugin:meatgg-bot@sukhrob-claude-plugins`, so the VPS has to install from
the marketplace in step 2. A repo checkout names the plugin `@meat-app` instead, which the script
will not find.

## Day to day

```bash
tmux attach -t meatgg        # peek, then Ctrl+b d to detach
tmux kill-session -t meatgg  # stop; cron respawns within 5 min
crontab -l                   # the two lines setup added
```

Cron checks every 5 minutes and restarts every 6 hours to clear context. Ask the session for
`get_channel_status` to check feed health. Settings load at startup, so restart after editing
them.

## Uninstall

`/meatgg-bot:uninstall`, or:

```bash
bun run <plugin>/dist/server.js uninstall        # keeps the key, settings and logs
bun run <plugin>/dist/server.js uninstall --all  # removes those too
```

Stops the session, drops the cron entries, deletes the installed files. `.mcp.json` goes with
them, so the MCP server unregisters itself. One step is left for a Claude Code session:
`/plugin uninstall meatgg-bot@sukhrob-claude-plugins`. The ApiKey still exists in
`/admin/api-keys`, so revoke it there.

## Troubleshooting

**MCP servers fail with ENOENT.** Cron's PATH is too bare to find `bun`. `respawn.sh` adds
`~/.local/bin` and `~/.bun/bin`; fix it if `which claude bun` differs.

**The `meatgg` tools are missing, or every call 401s.** The key never reached the process. Check
`MEATGG_API_KEY` in `~/.claude/channels/meatgg/.env`, and start the session with `respawn.sh`
rather than a bare `claude`, since that is what exports it.

**Never redirect Claude's output** (`>> log`, `| tee`). It flips to `--print` mode and exits on
launch. Use `tmux pipe-pane` and rotate it. The plugin's own log is
`~/.claude/channels/meatgg/meatgg-bot.log`.

**A prompt on every launch.** The dev-channels flag asks for confirmation each time and
`respawn.sh` presses Enter for it. It goes away once the plugin is allowlisted and `--channels`
works.

**Changed the bot's code?** Rebuild with `bun --cwd apps/bot run build`, then reinstall the
plugin.
