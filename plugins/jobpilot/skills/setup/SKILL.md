---
name: setup
description: Install the JobPilot agent terminal on this machine and open the dashboard. Run this first after installing the plugin in Claude Code or Codex.
---

# JobPilot Setup

Bootstraps the local agent: checks for the JobPilot terminal host, installs it if missing, then sends the user to the dashboard where the agent signs in automatically. Safe to run without a token - this is the onboarding entry point, so do not defer to the auth gate in `../shared/setup.md`.

```bash
JOBPILOT_WEB="${JOBPILOT_WEB:-https://jobpilot.suxrobgm.net}"
```

## 1. Already inside the terminal host?

If `JOBPILOT_API_TOKEN` is set, this session is already running inside the agent terminal - nothing to install. Confirm and stop:

> You're connected to JobPilot. Run the `search` skill to find jobs, `auto-apply` to run a campaign, or manage everything at $JOBPILOT_WEB.

## 2. Is the terminal host installed?

Probe the local host (default port 4102):

```bash
curl -fsS http://localhost:4102/healthz
```

- Reachable → installed and running; skip to step 4.
- Refused but `jobpilot` is on `PATH` → installed, not running; tell the user to start it, then go to step 4.
- Not found → install it (step 3).

## 3. Install the terminal host

Confirm with the user before running a remote install script, then run the one-liner for their OS:

- **Windows (PowerShell):**

  ```powershell
  irm https://raw.githubusercontent.com/suxrobGM/jobpilot/main/apps/terminal/install.ps1 | iex
  ```

- **macOS / Linux:**

  ```bash
  curl -fsSL https://raw.githubusercontent.com/suxrobGM/jobpilot/main/apps/terminal/install.sh | bash
  ```

It downloads the latest release into `~/.jobpilot` and adds it to `PATH`. After it finishes, start the host (`jobpilot`), then continue.

## 4. Open the dashboard

The agent launches and signs in from the dashboard - never from this session:

> JobPilot is ready. Open $JOBPILOT_WEB, sign in, and launch the agent from the dashboard - it connects to your local terminal automatically. From there, `search` for jobs or `auto-apply` to run a campaign.

## What JobPilot does

Searches job boards, tailors your resume per posting, and applies on your behalf - running on your own Claude/Codex subscription via the local agent. Your data lives in your hosted JobPilot account; the agent talks to it for you.
