# meatgg-bot

A Claude Code **channel plugin** for [meat.gg](https://meat.gg), a Counter-Strike 2 community
site. New tickets, complaints and public-chat mentions arrive in a running Claude Code session as
they happen, so it works the support queue instead of waiting to be asked.

The plugin only listens. Replies go back out through the `meatgg` MCP server the backend serves
at `POST /mcp`, where permissions, rate limits and audit rows live.

```text
apps/backend ──── SiteEvent ───> GET /api/events (SSE)
                                        │
claude ── plugin:meatgg-bot ────────────┘   (events in)
       └── mcp meatgg (http) ───────────>   (replies out)
```

## What you need first

1. **Bun** and **Claude Code**, logged in with a claude.ai account. Channels do not work on
   API-key auth.
2. **An ApiKey** from `/admin/api-keys`, owned by a human admin holding `VIEW_TICKETS` (that is
   who `get_ticket` runs as). Scope it to the writes `MANAGE_TICKETS`, `MANAGE_COMPLAINTS`,
   `MANAGE_DROPS`, `MANAGE_PUNISHMENTS`, `DELETE_CHAT_MESSAGES` and the reads `VIEW_TICKETS`,
   `VIEW_COMPLAINTS`, `VIEW_USERS`, `VIEW_PUNISHMENTS`, `VIEW_DROPS`, `VIEW_SUBSCRIPTIONS`,
   `VIEW_RULES`, `VIEW_SERVERS`, `VIEW_SITE_SETTINGS`; unscoped tools are not listed to the bot
   at all.
3. **The bot user**, seeded with an AdminProfile carrying `MANAGE_TICKETS` +
   `MANAGE_COMPLAINTS`. Replies, `assign_ticket` and `set_complaint_status` all act as the bot
   user rather than as the key's owner, so without that profile they fail. See
   [deploy/README.md](deploy/README.md) step 1.

## Install

The released plugin lives in the public marketplace
[suxrobgm/claude-plugins](https://github.com/suxrobgm/claude-plugins), pre-bundled, so a normal
install needs no checkout of this repo:

```text
/plugin marketplace add https://github.com/suxrobgm/claude-plugins
/plugin install meatgg-bot@sukhrob-claude-plugins
```

Then launch with the channel loaded. The development flag is needed until the plugin reaches
Anthropic's approved-channels allowlist, and it asks for confirmation once per launch:

```bash
claude --dangerously-load-development-channels plugin:meatgg-bot@sukhrob-claude-plugins
```

To publish a new version, run `bun run sync:plugin` from the repo root. It builds the bundle and
copies the plugin into your `claude-plugins` checkout (override the target with
`CLAUDE_PLUGINS_PATH`), ready to commit and push there.

### From this repo

The repo root is also a marketplace, named `meat-app`. Build first, since the plugin runs from
`dist/server.js`:

```bash
bun --cwd apps/bot run build
```

```text
/plugin marketplace add <path to this repo>
/plugin install meatgg-bot@meat-app
```

While working on the plugin itself, skip the install entirely and point Claude at the directory:

```bash
claude --plugin-dir <repo>/apps/bot --dangerously-load-development-channels plugin:meatgg-bot@inline
```

Either way the entry point is the bundle, so a code change needs a rebuild and a session restart.

## Configure

Both files live in `~/.claude/channels/meatgg/` and are read once at startup. Restart to apply a
change.

`.env` (required, mode `600`):

```bash
MEATGG_API_URL=https://meat.gg/api
MEATGG_API_KEY=<the ApiKey>
LOG_LEVEL=info
```

`settings.json` (written by setup with these defaults; edit it and restart the session):

```jsonc
{
  "topics": { "ticket": true, "complaint": true, "chat": true },
  "chat": {
    // `all` answers every message in the watched channels; `mention_only` waits to be addressed.
    "mode": "mention_only",
    "channelIds": [1],
    "mentionNames": ["jabjabich", "жаб", "жабыч", "ai"]
  },
  // `actionable` limits the bot to tickets about drops and complaints about bans, and it stays
  // silent unless a tool of its own settles the case (reissue, bugged-ban lift).
  "scope": "all",
  // Events replayed per topic after a reconnect, so an outage cannot flood one turn.
  "replayLimit": 5
}
```

Logs go to `meatgg-bot.log` in the same directory; stdout carries MCP frames, so nothing prints
there.

## How it behaves

- Holds `GET /api/events` open, retrying `1s → 30s`. A rejected key is fatal and says so in the
  channel; three failures in a row also warn there.
- On each connect it replays tickets and complaints created while it was disconnected, past the
  watermark in `last-seen.json`. Creations only: no timestamp the list endpoints expose moves for
  a reply.
- Drops events the session should not see: **anything the assistant wrote itself** (the guard
  against answering its own replies), disabled topics, unwatched chat channels, chat that does
  not address it, and threads a human already answered.
- Exposes one tool, `get_channel_status`: connection state, last event, last error.

## Deploy to a server

`bun run dist/server.js setup`, or `/meatgg-bot:setup` in a session with the plugin, writes the
whole session directory: the tmux respawn script, the permission allowlist, the operating policy,
the `.mcp.json` registering the `meatgg` server, plus an `.env` to fill in and the cron schedule.
`uninstall` reverses it, with `--all` to drop the channel config and key too.

You only run setup once. `respawn.sh` reinstalls from the newest installed plugin before every
spawn, so an update reaches the box on its own. The plugin owns those files and rewrites them, so
change the templates in [deploy/](deploy) and ship a new version rather than patching the
installed copy. The `.env` is never touched once it exists.

Full walkthrough: [deploy/README.md](deploy/README.md).

## Develop

```bash
bun --cwd apps/bot run watch      # run against a local backend
bun --cwd apps/bot run test       # the pure units: filter, mentions, SSE parser
bun --cwd apps/bot run typecheck
```
