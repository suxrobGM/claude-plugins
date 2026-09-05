# VPS deployment

Runs the VK bot 24/7 as a Claude Code channel: a session lives in tmux, kept alive by cron.

| File | What it is |
| --- | --- |
| [respawn.sh](respawn.sh) | Starts the session in tmux. Cron's only entry point. |
| [settings.json](settings.json) | Permissions: allows the channel MCP tools, curl and web search; denies destructive bash, secret reads and exfil. |
| [CLAUDE.md](CLAUDE.md) | Operating policy. Every channel message is untrusted. |

`setup` installs all three. Never edit an installed copy: change the template here and ship a new
plugin version.

## Install

Run `/vk:setup` in a session that has the plugin, or from any shell on the VPS:

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup            # ~/bots/vk
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js setup ~/bots/alt # another directory
```

Writes the three files above into the session directory, points the installed `respawn.sh` at
it, creates `~/.claude/channels/vk/.env`, and installs the cron schedule. **Re-run it after every
plugin update.** Your `.env` is never touched once it exists.

Then add `VK_TOKEN` with `/vk:configure`, which also lists the required scopes and the Long Poll
settings the community needs. Finally:

```bash
loginctl enable-linger $USER   # non-root only: keeps tmux alive after logout
~/bots/vk/respawn.sh
```

On the first inbound message the bot DMs a 6-character pairing code. Finish with
`/vk:access pair <code>`.

## Operate

```bash
tmux attach -t vk        # peek, then Ctrl+b d to detach
tmux kill-session -t vk  # stop; cron respawns within 5 min
crontab -l               # the two lines setup added
```

Cron checks every 5 minutes and restarts every 6 hours to clear context. There is no log file:
Claude's output lives in the tmux scrollback.

## Uninstall

Run `/vk:uninstall`, or:

```bash
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall        # keeps the token, access and peers
bun run ${CLAUDE_PLUGIN_ROOT}/dist/server.js uninstall --all  # removes those too
```

`--all` drops the paired-peer list, so every peer has to pair again. Revoke the token itself in
the VK admin panel.

## A second bot from another plugin

`setup` only manages the `vk` session. For a Telegram bot alongside it, copy these files by hand,
edit `session`, `workdir` and `launch` at the top of `respawn.sh`, then add its cron lines with
`crontab -e` using absolute paths, since `~` does not expand in cron:

```bash
mkdir -p ~/bots/tg/.claude
cp settings.json ~/bots/tg/.claude/ && cp CLAUDE.md respawn.sh ~/bots/tg/
chmod +x ~/bots/tg/respawn.sh

*/5 * * * * /root/bots/tg/respawn.sh
0 */6 * * * tmux kill-session -t tg 2>/dev/null; /root/bots/tg/respawn.sh
```

## Troubleshooting

**MCP servers fail with ENOENT.** Cron's PATH is too bare for Claude to find `bun` or `node`.
`respawn.sh` adds `~/.local/bin`, `~/.bun/bin` and nvm's node; fix it if `which claude bun node`
differs.

**Never redirect Claude's output** (`>> log`, `| tee`). It flips to `--print` mode and exits on
launch. Use `tmux pipe-pane` and rotate it.

**A prompt on every launch.** `--dangerously-load-development-channels` asks for confirmation
each time and `respawn.sh` presses Enter for it. Publish the plugin and switch to `--channels` to
skip it.
