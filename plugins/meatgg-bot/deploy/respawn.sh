#!/usr/bin/env bash
# Restarts the meat.gg support bot in tmux if its session died. Run from cron.
set -u

# Cron's PATH is too bare to find the runtimes the MCP servers launch with.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/bin:/bin"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1

session=meatgg
workdir="$(cd "$(dirname "$0")" && pwd)"

# Existing tmux servers do not inherit environment changes, so export inside the pane.
env_file="$workdir/.state/.env"
launch="export MEATGG_BOT_HOME='$workdir'; [ -f '$env_file' ] && { set -a; . '$env_file'; set +a; }; exec claude --permission-mode dontAsk --dangerously-load-development-channels plugin:meatgg-bot@sukhrob-claude-plugins"

tmux has-session -t "$session" 2>/dev/null && exit 0

# Reinstall first, so a plugin update lands without anyone re-running setup.
installer=$(ls -d "$HOME"/.claude/plugins/cache/*/meatgg-bot/*/dist/server.js 2>/dev/null |
  sort -V | tail -1)
[ -n "$installer" ] && bun run "$installer" setup "$workdir" >/dev/null 2>&1

# Redirecting Claude's stdout enables --print and exits; log with tmux pipe-pane.
tmux new -d -s "$session" -c "$workdir" "$launch"

# Development channels require Enter confirmation.
for _ in $(seq 1 20); do
  if tmux capture-pane -p -t "$session" 2>/dev/null | grep -q "local development"; then
    tmux send-keys -t "$session" Enter
    break
  fi
  sleep 1
done
