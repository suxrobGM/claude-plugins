#!/usr/bin/env bash
# Respawn the meat.gg support bot in tmux if its session died. Run from cron.
set -u

# Cron's PATH is bare; add the runtimes that launch the MCP servers (bun, node).
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/bin:/bin"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1

session=meatgg
workdir=/root/bots/meatgg
launch='exec claude --permission-mode dontAsk --dangerously-load-development-channels plugin:meatgg-bot@meat-app'

# Alive -> done. On a crash the pane (Claude) exits and tmux drops the session.
tmux has-session -t "$session" 2>/dev/null && exit 0

# To log, add `tmux pipe-pane`; never redirect Claude's stdout (`>> file` / `| tee`)
# -- that flips it into --print mode and it exits on launch.
tmux new -d -s "$session" -c "$workdir" "$launch"

# Confirm the development-channels prompt shown on every launch.
for _ in $(seq 1 20); do
  if tmux capture-pane -p -t "$session" 2>/dev/null | grep -q "local development"; then
    tmux send-keys -t "$session" Enter
    break
  fi
  sleep 1
done
