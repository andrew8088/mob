# mob

Orchestrate multiple Claude Code sessions as a coordinated swarm. One coordinator breaks down tasks and dispatches work to multiple workers running in parallel.

## Quick Start

```bash
# Start a coordinator and attach to it
mob start

# From another terminal, spawn workers
mob spawn worker 1
mob spawn worker 2
```

The coordinator receives a prompt explaining how to manage workers. Ask it to do something complex and it will break it down, spawn workers, and synthesize results.

## Architecture

```
┌─────────────────┐
│   Coordinator   │  Full Claude (opus), breaks down tasks
│  claude-coord-* │  Spawns workers, dispatches work, synthesizes results
└────────┬────────┘
         │ mob send / mob broadcast-workers
    ┌────┴────┬─────────┐
    ▼         ▼         ▼
┌───────┐ ┌───────┐ ┌───────┐
│Worker1│ │Worker2│ │Worker3│  Sonnet model, restricted tools
└───────┘ └───────┘ └───────┘  Auto-approved, no hooks
    │         │         │
    └────┬────┴─────────┘
         │ mob done / mob report / mob ask
         ▼
   Back to Coordinator
```

## Commands

### Session Management

| Command | Description |
|---------|-------------|
| `mob start [id]` | Start coordinator and attach |
| `mob spawn coord [id]` | Spawn coordinator (without attaching) |
| `mob spawn worker [id]` | Spawn a worker |
| `mob attach <session>` | Attach to a session (detach: Ctrl-b d) |
| `mob kill <session>` | Kill a session |
| `mob killall` | Kill all mob sessions |

### Monitoring

| Command | Description |
|---------|-------------|
| `mob list` | List all sessions |
| `mob workers` | List workers only |
| `mob coord` | Print coordinator session name |
| `mob status` | Detailed session status |
| `mob health` | Health status with heartbeat info |
| `mob watch` | Live dashboard (Ctrl+C to exit) |
| `mob peek <session> [n]` | Last n lines from session |
| `mob logs <session> [n]` | Session log file |
| `mob waiting` | Sessions awaiting input |

### Communication

| Command | Description |
|---------|-------------|
| `mob send <session> <msg>` | Send message to session |
| `mob broadcast <msg>` | Send to all sessions |
| `mob broadcast-workers <msg>` | Send to workers only |

### Worker Callbacks (run from within worker)

| Command | Description |
|---------|-------------|
| `mob done <summary>` | Signal completion (auto-exits worker) |
| `mob report <msg>` | Status update to coordinator |
| `mob ask <question>` | Ask coordinator a question |
| `mob heartbeat` | Record heartbeat |

### Health Management

| Command | Description |
|---------|-------------|
| `mob zombies` | List zombie sessions |
| `mob reap` | Kill all zombies |

## Worker Security

Workers run with restricted permissions:

- **Model**: Sonnet (faster/cheaper for subtasks)
- **No hooks**: Won't trigger your notification hooks
- **Auto-approved**: No permission prompts
- **Restricted Bash**: Only allowed commands:
  - `git`, `npm`, `npx`, `pnpm`, `yarn`
  - `make`, `jest`, `vitest`, `pytest`, `cargo`

## Example Session

```bash
# Terminal 1: Start coordinator
mob start

# Ask coordinator:
# "Build a REST API with /users and /posts endpoints, with tests"

# Coordinator will:
# 1. Spawn workers for each endpoint
# 2. Dispatch tasks via mob send
# 3. Collect [DONE] callbacks
# 4. Synthesize final result

# Terminal 2: Monitor
mob watch
```

## How It Works

- Sessions run in tmux (source of truth for liveness)
- Messages sent via `tmux send-keys` with per-session locking
- Workers report back with `[DONE from ...]`, `[REPORT from ...]`, `[QUESTION from ...]`
- Crash detection via tmux `pane-died` hooks
- Logs persisted to `/tmp/mob-logs/`

## Requirements

- tmux
- claude (Claude Code CLI)
