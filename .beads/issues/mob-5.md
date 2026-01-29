---
id: mob-5
title: "Extract session listing helper"
status: open
priority: low
labels: [refactor, dry]
created: 2026-01-29
---

## Problem
Session listing pattern repeated 7+ times throughout codebase:
```bash
tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${SESSION_PREFIX}-..." || true
```

## Locations
- `mob:230-233` - list_sessions
- `mob:236-239` - workers
- `mob:565-566` - zombies
- `mob:582-583` - reap
- `mob:635-636` - kill_all
- `mob:706-707` - broadcast
- `mob:722-723` - broadcast_workers

## Solution
```bash
_list_sessions() {
    local pattern="${1:-}"
    tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${SESSION_PREFIX}-${pattern}" || true
}

# Usage:
_list_sessions "worker"    # workers only
_list_sessions "coord"     # coordinators only
_list_sessions ""          # all claude sessions
```
