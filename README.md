# mob

Orchestrate multiple Claude Code sessions as a coordinated swarm. One coordinator breaks down tasks and dispatches work to specialized workers running in parallel.

## Quick Start

```bash
# Start a coordinator and attach to it
mob start

# From another terminal, spawn workers
mob spawn worker 1
mob spawn researcher 2
```

The coordinator receives a prompt explaining how to manage workers. Ask it to do something complex and it will break it down, spawn the right worker types, and synthesize results.

## Architecture

```
┌─────────────────┐
│   Coordinator   │  Full Claude, breaks down tasks
│  claude-coord-* │  Chooses worker types, dispatches work, synthesizes results
└────────┬────────┘
         │ mob send
    ┌────┴────┬─────────┬─────────┐
    ▼         ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│researcher│ │planner │ │ worker │ │reviewer│
│read-only│ │ opus   │ │ full   │ │test/lint│
└────────┘ └────────┘ └────────┘ └────────┘
    │         │         │         │
    └────┬────┴─────────┴────┬────┘
         │                   │
    ┌────┴────┐         ┌────┴────┐
    ▼ queued  ▼         ▼interrupt▼
┌─────────────────┐ ┌─────────────────┐
│  mob inbox      │ │ [QUESTION ...]  │
│  (done/report)  │ │ [CRASH ...]     │
└─────────────────┘ └─────────────────┘
```

## Worker Types

The coordinator automatically chooses the right worker type based on the task:

| Type | Model | Tools | Use Case |
|------|-------|-------|----------|
| `researcher` | sonnet | read-only (Glob, Grep, Read, Web) | Explore code, find patterns, understand systems |
| `planner` | **opus** | read-only | Architecture decisions, complex problem decomposition |
| `worker` | sonnet | full (read/write/bash) | Implementation, bug fixes, refactoring |
| `reviewer` | sonnet | read + test/lint | Code review, validation, running tests |

**Common patterns:**
- Simple bug fix → `worker`
- New feature → `researcher` → `planner` → `worker(s)` → `reviewer`
- Code question → `researcher`
- Refactor → `planner` → `worker(s)` → `reviewer`
- PR review → `reviewer`

## Inbox System

Worker callbacks are **queued** by default to avoid interrupting the coordinator mid-thought:

| Callback | Delivery | Behavior |
|----------|----------|----------|
| `mob done` | queued | Writes to inbox, worker self-terminates |
| `mob report` | queued | Writes to inbox |
| `mob ask` | **interrupt** | Injects directly into coordinator |
| crash | **interrupt** | Injects directly into coordinator |

The coordinator checks messages when ready:

```bash
mob inbox
# === INBOX (2 messages) ===
# [DONE from claude-worker-1] Built REST API with CRUD endpoints
# [DONE from claude-researcher-2] Found auth patterns in src/auth/
# --- Inbox cleared ---
```

## Commands

### Session Management

| Command | Description |
|---------|-------------|
| `mob start [id]` | Start coordinator and attach |
| `mob spawn <type> [id]` | Spawn a worker (type: worker, researcher, reviewer, planner) |
| `mob attach <session>` | Attach to a session (detach: Ctrl-b d) |
| `mob kill <session>` | Kill a session |
| `mob killall` | Kill all mob sessions |

### Monitoring

| Command | Description |
|---------|-------------|
| `mob list` | List all sessions |
| `mob workers` | List workers only |
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
| `mob inbox` | Read and clear pending messages |
| `mob inbox-count` | Count of pending messages |

### Worker Callbacks (run from within worker)

| Command | Description |
|---------|-------------|
| `mob done <summary>` | Queue completion (auto-terminates worker) |
| `mob report <msg>` | Queue status update |
| `mob ask <question>` | Interrupt coordinator with question |
| `mob heartbeat` | Record heartbeat |

### Health Management

| Command | Description |
|---------|-------------|
| `mob zombies` | List zombie sessions |
| `mob reap` | Kill all zombies |

## Worker Security

Workers run with restricted permissions:

| Type | Model | Bash Access |
|------|-------|-------------|
| worker | sonnet | git, npm, npx, pnpm, yarn, make, jest, vitest, pytest, cargo |
| researcher | sonnet | none |
| reviewer | sonnet | git, test/lint commands only |
| planner | opus | none |

All workers run with `--dangerously-skip-permissions` (auto-approved) and no hooks.

## Example Session

```bash
# Terminal 1: Start coordinator
mob start

# Ask coordinator:
# "Add user authentication to this Express app"

# Coordinator will:
# 1. Spawn researcher to understand existing code
# 2. Spawn planner to design the auth system
# 3. Spawn workers to implement
# 4. Spawn reviewer to validate
# 5. Check mob inbox between phases
# 6. Synthesize final result

# Terminal 2: Monitor
mob watch
```

## How It Works

- Sessions run in tmux (source of truth for liveness)
- Messages sent via `tmux send-keys` with per-session locking
- Completions queue to `/tmp/mob-inbox/` (non-interruptive)
- Questions and crashes interrupt immediately
- Crash detection via tmux `pane-died` hooks
- Logs persisted to `/tmp/mob-logs/`

## Requirements

- tmux
- claude (Claude Code CLI)
