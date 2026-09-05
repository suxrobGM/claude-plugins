# Support bot deployment

Runs [apps/bot](../../apps/bot) as a Claude Code channel: a session lives in tmux on the VPS,
receives ticket, complaint and chat events, and answers with the `meatgg` MCP tools.

| File | What it is |
| --- | --- |
| [respawn.sh](respawn.sh) | Starts the session in tmux. Cron's only entry point. |
| [settings.json](settings.json) | Permissions: what the bot may call, and everything denied. |
| [CLAUDE.md](CLAUDE.md) | Operating policy. Every channel message is untrusted. |

`setup` installs all three. Never edit an installed copy: change the template here and ship a new
plugin version.

## 1. Prepare the site

1. `bun run db:seed --only ai-bot` on prod. Creates the Джаб Джабич user.
2. In `/admin/admins`, give that user an AdminProfile with `MANAGE_TICKETS` and
   `MANAGE_COMPLAINTS`. Without it the reply tools fail with "you can only reply to your own
   tickets".
3. Mint an ApiKey owned by a **human admin holding `VIEW_TICKETS`**, since `get_ticket` runs as
   the key's owner rather than as the bot. Scope it to `VIEW_TICKETS`, `MANAGE_TICKETS`,
   `VIEW_COMPLAINTS`, `MANAGE_COMPLAINTS`, `DELETE_CHAT_MESSAGES`.

## 2. Install

Run `/meatgg-bot:setup` in a session that has the plugin, or from any shell on the VPS:

```bash
bun run <plugin>/dist/server.js setup             # ~/bots/meatgg
bun run <plugin>/dist/server.js setup ~/bots/alt  # another directory
```

`<plugin>` is `~/.claude/plugins/**/meatgg-bot`, or `apps/bot` in a repo checkout.

Writes the three files above into the session directory, creates
`~/.claude/channels/meatgg/.env`, and installs the cron schedule. **Re-run it after every plugin
update.** Your `.env` is never touched once it exists.

## 3. Add the API key

In `~/.claude/channels/meatgg/.env`:

```bash
MEATGG_API_URL=https://meat.gg/api
MEATGG_API_KEY=<the ApiKey>
```

Topics and chat behaviour are optional. See [apps/bot/README.md](../README.md) for
`~/.claude/channels/meatgg/settings.json`.

## 4. Register the MCP server

Use **user** scope and the **API** domain. User scope skips the project-server prompt that would
stall an unattended launch, and Shield gates `${DOMAIN}`, so a challenge there would stall the
bot.

```bash
claude mcp add meatgg --scope user --transport http https://meat.gg/mcp \
  --header "Authorization: Bearer <the same ApiKey>"
```

## 5. Install the plugin and start

Log in with the subscription account. Channels are not available on API-key auth.

```bash
bun --cwd <repo>/apps/bot run build   # dist/server.js must exist first

cd ~/bots/meatgg
claude                                # /plugin marketplace add <repo>
                                      # /plugin install meatgg-bot@meat-app
                                      # /login

loginctl enable-linger $USER          # non-root only: keeps tmux alive after logout
~/bots/meatgg/respawn.sh
```

## Operate

```bash
tmux attach -t meatgg        # peek, then Ctrl+b d to detach
tmux kill-session -t meatgg  # stop; cron respawns within 5 min
crontab -l                   # the two lines setup added
```

Cron checks every 5 minutes and restarts every 6 hours to clear context. Ask the session
`get_channel_status` for feed health. Settings load at startup, so restart after editing them.

## Uninstall

Run `/meatgg-bot:uninstall`, or:

```bash
bun run <plugin>/dist/server.js uninstall        # keeps the key, settings and logs
bun run <plugin>/dist/server.js uninstall --all  # removes those too
```

Two steps belong to Claude Code rather than the host: `claude mcp remove meatgg --scope user`,
and `/plugin uninstall meatgg-bot@meat-app` from a session. The ApiKey itself lives on in
`/admin/api-keys`, so revoke it there.

## Troubleshooting

**MCP servers fail with ENOENT.** Cron's PATH is too bare to find `bun`. `respawn.sh` adds
`~/.local/bin` and `~/.bun/bin`; fix it if `which claude bun` differs.

**Never redirect Claude's output** (`>> log`, `| tee`). It flips to `--print` mode and exits on
launch. Use `tmux pipe-pane` and rotate it. The plugin's own log is
`~/.claude/channels/meatgg/meatgg-bot.log`.

**A prompt on every launch.** The dev-channels flag asks for confirmation each time and
`respawn.sh` presses Enter for it. It goes away once the plugin is allowlisted and `--channels`
works.

**Changed the bot's code?** Rebuild with `bun --cwd apps/bot run build`, then reinstall the
plugin.
