# meatgg-bot

A Claude Code **channel plugin** for meat.gg. New tickets, complaints and public-chat mentions
arrive in a running Claude Code session as `<channel>` events, so the session can answer them as
they happen instead of waiting to be asked.

The plugin only reads. Every reply goes back through the `meatgg` MCP server the backend already
serves at `POST /mcp`, which is where permissions, rate limits and audit rows live.

```text
apps/backend ──── SiteEvent ───> GET /api/events (SSE)
                                        │
claude ── plugin:meatgg-bot ────────────┘   (channel events in)
       └── mcp meatgg (http) ───────────>   (every reply out)
```

## Prerequisites

- [Bun](https://bun.sh) and [Claude Code](https://code.claude.com), logged in with a claude.ai
  account — channels are not available on API-key auth.
- An `ApiKey` from `/admin/api-keys`, owned by an admin who holds `VIEW_TICKETS` (`get_ticket`
  runs as the key's owner). Scope it to `VIEW_TICKETS`, `MANAGE_TICKETS`, `VIEW_COMPLAINTS`,
  `MANAGE_COMPLAINTS` and `DELETE_CHAT_MESSAGES`.
- The seeded bot user with an AdminProfile carrying `MANAGE_TICKETS` + `MANAGE_COMPLAINTS` —
  see [deploy/README.md](deploy/README.md) for that part.

## Install

Build the bundle first — `.mcp.json` points at `dist/server.js`, so the plugin does not run
without it:

```bash
bun --cwd apps/bot run build
```

Then, in Claude Code:

```text
/plugin marketplace add <path to this repo>
/plugin install meatgg-bot@meat-app
```

Launch with the channel loaded. The development flag is required until the plugin is on
Anthropic's approved channels allowlist, and it prompts once per launch:

```bash
claude --dangerously-load-development-channels plugin:meatgg-bot@meat-app
```

While working on the plugin itself, skip the install and point Claude at the directory:

```bash
claude --plugin-dir <repo>/apps/bot --dangerously-load-development-channels plugin:meatgg-bot@inline
```

Either way, a code change needs a rebuild and a session restart — the entry point is the bundle,
not the sources.

## Configure

Two files under `~/.claude/channels/meatgg/`, both read once at startup.

`.env` (required, mode `600`):

```bash
MEATGG_API_URL=https://meat.gg/api
MEATGG_API_KEY=<the ApiKey>
LOG_LEVEL=info
```

`settings.json` (optional — these are the defaults):

```jsonc
{
  "topics": { "ticket": true, "complaint": true, "chat": true },
  "chat": {
    // `all` answers every message in the watched channels; `mention_only` waits to be addressed.
    "mode": "mention_only",
    "channelIds": [1],
    "mentionNames": ["jabjabich", "джаб", "джабич"]
  },
  // Events replayed per topic after a reconnect, so an outage cannot flood one turn.
  "replayLimit": 5
}
```

Restart the session to apply a change. Logs go to `~/.claude/channels/meatgg/meatgg-bot.log`
(stdout carries MCP frames, so nothing is printed there).

## What it does

- Holds `GET /api/events` open, retrying `1s → 30s`. A rejected key is fatal and says so in the
  channel; three failures in a row raise a warning there too.
- On every connect, replays tickets and complaints created while it was disconnected, past the
  watermark in `last-seen.json`. Creations only — no timestamp the list endpoints expose moves
  when someone merely replies.
- Skips events the session should not see: **anything the assistant wrote itself** (this is what
  stops it answering its own replies), disabled topics, unwatched chat channels, chat that does
  not address it, and threads a human has already replied on.
- Exposes one tool, `get_channel_status` — connected, last event, last error.

## Deploy

`bun run dist/server.js setup` (or `/meatgg-bot:setup` in a session that has the plugin) writes
the tmux respawn script, the permission allowlist, the operating policy and an `.env` to fill in,
and installs the cron schedule. Re-run it after a plugin update — the plugin owns those files and
rewrites them, so edit the templates here and ship a new version rather than patching an
installed copy. The `.env` is never touched once it exists.

`bun run dist/server.js uninstall` (or `/meatgg-bot:uninstall`) reverses it: stops the session,
drops the cron entries, removes the files. `--all` takes the channel config and key as well.

The templates live in [deploy/](deploy); the full VPS walkthrough is
[deploy/README.md](deploy/README.md).

## Develop

```bash
bun --cwd apps/bot run watch      # run against a local backend
bun --cwd apps/bot run test       # the pure units: filter, mentions, SSE parser
bun --cwd apps/bot run typecheck
```
