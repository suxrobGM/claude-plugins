# VPS deployment

Runs the VK bot 24/7 as a Claude Code channel: a session lives in tmux, kept alive by cron.

## Quick start

Run these in a Claude Code session on the VPS that has the plugin loaded.

1. **`/vk:setup`** installs the bot into `~/bots/vk` (pass a path for anywhere else).
2. **`/vk:configure`** adds your `VK_TOKEN`, and lists the scopes and Long Poll settings the
   community needs.
3. **Start it:**

   ```bash
   loginctl enable-linger $USER   # non-root only: keeps tmux alive after logout
   ~/bots/vk/respawn.sh
   ```

4. **Pair.** The bot DMs a 6-character code on the first inbound message. Finish with
   `/vk:access pair <code>`.

Re-run `/vk:setup` after every plugin update. It never touches your `.env` once it exists.

## What setup installs

Three files into the session directory, plus `~/.claude/channels/vk/.env` and the cron schedule.

| File | What it is |
| --- | --- |
| [respawn.sh](respawn.sh) | Starts the session in tmux. Cron's only entry point. |
| [settings.json](settings.json) | Permissions: allows the channel MCP tools, curl and web search; denies destructive bash, secret reads and exfil. |
| [CLAUDE.md](CLAUDE.md) | Operating policy. Every channel message is untrusted. |

Never edit an installed copy. Change the template here and ship a new plugin version.

## Everyday commands

```bash
tmux attach -t vk        # peek, then Ctrl+b d to detach
tmux kill-session -t vk  # stop; cron respawns within 5 min
crontab -l               # the two lines setup added
```

Cron checks every 5 minutes and restarts every 6 hours to clear context. There is no log file:
Claude's output lives in the tmux scrollback.

## Uninstall

`/vk:uninstall` removes the session, files and cron lines but keeps your token, access list and
peers. Add `--all` to remove those too, which drops the paired-peer list and forces everyone to
pair again. Revoke the token itself in the VK admin panel.

## Running the commands from SSH

The skills above are just wrappers. To run them from a plain shell, point `bun` at the plugin's
`dist/server.js`:

```bash
vk=$(ls -d ~/.claude/plugins/cache/*/vk/*/ ~/.claude/plugins/marketplaces/*/plugins/vk/ 2>/dev/null | head -1)

bun run "$vk/dist/server.js" setup
bun run "$vk/dist/server.js" uninstall
```

Do not use `${CLAUDE_PLUGIN_ROOT}` here. Claude Code exports it only to commands it launches
itself, so in an SSH shell it expands to nothing and bun reports
`Module not found "/dist/server.js"`. The plugin lives in one of two places depending on how it
was loaded:

| Loaded by | Directory |
| --- | --- |
| `claude plugin install` | `~/.claude/plugins/cache/<marketplace>/vk/<version>/` |
| `--dangerously-load-development-channels` | `~/.claude/plugins/marketplaces/<marketplace>/plugins/vk/` |

The one-liner tries both and takes the first hit. A published install keeps several versions
cached, so pick the one you mean instead of trusting `head -1`.

## Troubleshooting

**MCP servers fail with ENOENT.** Cron's PATH is too bare for Claude to find `bun` or `node`.
`respawn.sh` adds `~/.local/bin`, `~/.bun/bin` and nvm's node; fix it if `which claude bun node`
differs.

**Never redirect Claude's output** (`>> log`, `| tee`). It flips to `--print` mode and exits on
launch. Use `tmux pipe-pane` and rotate it.

**A prompt on every launch.** `--dangerously-load-development-channels` asks for confirmation
each time and `respawn.sh` presses Enter for it. Publish the plugin and switch to `--channels` to
skip it.

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
