#!/usr/bin/env bash
# Restarts a Claude Code channel bot in tmux if its session died. Run from cron.
# Copy one per bot dir and edit the three vars below.
set -u

# Cron's PATH is too bare to find the runtimes the MCP servers launch with.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/bin:/bin"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1

session=vk
workdir=/root/bots/vk
launch='exec claude --dangerously-load-development-channels plugin:vk@sukhrob-claude-plugins'

# Still alive -> nothing to do. A crash exits the pane and tmux drops the session.
tmux has-session -t "$session" 2>/dev/null && exit 0

# Reinstall first, so a plugin update lands without anyone re-running setup. The glob covers the
# version in the path; writes are atomic, so rewriting this running script is safe.
installer=$(ls -d "$HOME"/.claude/plugins/cache/*/vk/*/dist/server.js 2>/dev/null |
  sort -V | tail -1)
[ -n "$installer" ] && bun run "$installer" setup "$workdir" >/dev/null 2>&1

# Never redirect Claude's stdout (`>> file`, `| tee`); that flips it to --print and it exits.
# Use `tmux pipe-pane` to log.
tmux new -d -s "$session" -c "$workdir" "$launch"

# Answers the development-channels prompt; a no-op once --channels works.
for _ in $(seq 1 20); do
  if tmux capture-pane -p -t "$session" 2>/dev/null | grep -q "local development"; then
    tmux send-keys -t "$session" Enter
    break
  fi
  sleep 1
done
