# mob

Orchestrate multiple Claude Code sessions as a coordinated swarm. An operator shields you from noise, a coordinator breaks down tasks, and specialized workers execute in parallel.

## Quick Start

```bash
# Start a namespaced mob (operator + coordinator)
mob start api

# You're now in the operator session
# Send work to the coordinator:
mob task "Build a REST API with /users and /posts endpoints"

# Check coordinator reports:
mob results

# In another terminal, watch the swarm:
mob watch api
```

## Architecture

```
┌──────────┐
│   You    │
└────┬─────┘
     │ mob task / mob results
     ▼
┌──────────────────┐
│    Operator      │  opus model, shields you from worker noise
│ claude-operator-*│  Sends tasks, receives synthesized reports
└────────┬─────────┘
         │ priority inbox / reports
         ▼
┌──────────────────┐
│   Coordinator    │  sonnet model, orchestrates workers
│  claude-coord-*  │  Breaks down tasks, dispatches, synthesizes
└────────┬─────────┘
         │ mob dispatch
    ┌────┴────┬─────────┬─────────┐
    ▼         ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│researcher│ │planner │ │ worker │ │reviewer│
│read-only│ │ opus   │ │ full   │ │test/lint│
└────────┘ └────────┘ └────────┘ └────────┘
    │         │         │         │
    └─────────┴────┬────┴─────────┘
                   │ mob done / mob report
                   ▼
           ┌──────────────┐
           │ worker inbox │
           │ (queued)     │
           └──────────────┘
```

## Namespaces

Run multiple isolated mobs simultaneously:

```bash
mob start api      # Creates claude-coord-api, claude-operator-api
mob start web      # Creates claude-coord-web, claude-operator-web
```

Workers auto-inherit their coordinator's namespace:
- `mob dispatch worker 1` from coord-api → `claude-worker-api_1`

Filter commands by namespace:
```bash
mob watch api      # Dashboard for api namespace only
mob listen api     # Stream api messages only
mob health api     # Health for api sessions only
```

## Worker Types

| Type | Model | Tools | Use Case |
|------|-------|-------|----------|
| `researcher` | sonnet | read-only (Glob, Grep, Read, Web) | Explore code, find patterns |
| `planner` | **opus** | read-only | Architecture, complex decomposition |
| `worker` | sonnet | full (read/write/bash) | Implementation, bug fixes |
| `reviewer` | sonnet | read + test/lint | Code review, validation |

**Common patterns:**
- Simple bug fix → `worker`
- New feature → `researcher` → `planner` → `worker(s)` → `reviewer`
- Code question → `researcher`

## Message Flow

### Operator ↔ Coordinator

| Command | Direction | Description |
|---------|-----------|-------------|
| `mob task <msg>` | operator → coord | Send priority task (interrupts) |
| `mob priority` | coord reads | Check priority inbox |
| `mob report <msg>` | coord → operator | Send report |
| `mob results` | operator reads | Check coordinator reports |

### Coordinator ↔ Workers

| Command | Direction | Description |
|---------|-----------|-------------|
| `mob dispatch <type> <id> <task>` | coord → worker | Spawn and send task |
| `mob done <summary>` | worker → coord | Queue completion (auto-terminates) |
| `mob report <msg>` | worker → coord | Queue status update |
| `mob ask <question>` | worker → coord | Interrupt with question |
| `mob inbox` | coord reads | Check worker messages |

## Commands

### Session Management

| Command | Description |
|---------|-------------|
| `mob start <namespace>` | Start operator + coordinator, attach to operator |
| `mob spawn <type> [id]` | Spawn session (coord, operator, worker, researcher, reviewer, planner) |
| `mob dispatch <type> <id> <task>` | Spawn worker and send task in one command |
| `mob attach <session>` | Attach to session (`mob attach api` → operator) |
| `mob kill <session>` | Kill a session |
| `mob killall` | Kill all mob sessions |

### Monitoring

| Command | Description |
|---------|-------------|
| `mob list` | List all sessions |
| `mob health [namespace]` | Health status with heartbeat info |
| `mob watch [namespace]` | Live dashboard (Ctrl+C to exit) |
| `mob listen [namespace]` | Stream inbox messages in real-time |
| `mob peek <session> [n]` | Last n lines from session |
| `mob waiting` | Sessions awaiting input |

### Health Management

| Command | Description |
|---------|-------------|
| `mob zombies` | List zombie sessions |
| `mob reap` | Kill all zombies |

## Example Session

```bash
# Terminal 1: Start the swarm
mob start api

# You're now in the operator. Ask for something:
# "Add user authentication to this Express app"

# The operator sends to coordinator:
mob task "Add user authentication to this Express app"

# Coordinator will:
# 1. Check mob priority (gets your task)
# 2. Dispatch researcher to understand code
# 3. Dispatch planner to design auth
# 4. Dispatch workers to implement
# 5. Dispatch reviewer to validate
# 6. Report back to operator

# Check reports:
mob results

# Terminal 2: Monitor
mob watch api

# Terminal 3: Stream messages
mob listen api
```

## How It Works

- Sessions run in tmux (source of truth for liveness)
- Messages sent via `tmux send-keys` with per-session locking
- Worker completions queue to `/tmp/mob-inbox/{coord}.jsonl`
- Operator tasks queue to `/tmp/mob-inbox/{coord}-priority.jsonl`
- Coordinator reports queue to `/tmp/mob-inbox/{operator}-results.jsonl`
- Crash detection via tmux `pane-died` hooks
- Logs persisted to `/tmp/mob-logs/`

## Requirements

- tmux
- claude (Claude Code CLI)
