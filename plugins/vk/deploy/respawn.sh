#!/usr/bin/env bash
# Respawn a Claude Code channel bot in tmux if its session died. Run from cron.
# Copy one per bot dir and edit the three vars below.
set -u

# Cron's PATH is bare; add the runtimes that launch the MCP servers (bun, node).
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/bin:/bin"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1

session=vk
workdir=/root/bots/vk
launch='exec claude --dangerously-load-development-channels plugin:vk@sukhrob-claude-plugins'

# Alive -> done. On a crash the pane (Claude) exits and tmux drops the session.
tmux has-session -t "$session" 2>/dev/null && exit 0

# To log, add `tmux pipe-pane`; never redirect Claude's stdout (`>> file`/`| tee`)
# -- that flips it into --print mode and it exits on launch.
tmux new -d -s "$session" -c "$workdir" "$launch"

# Confirm the dev-channels prompt shown on every launch (no-op for --channels).
for _ in $(seq 1 20); do
  if tmux capture-pane -p -t "$session" 2>/dev/null | grep -q "local development"; then
    tmux send-keys -t "$session" Enter
    break
  fi
  sleep 1
done
