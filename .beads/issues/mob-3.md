---
id: mob-3
title: "Race condition in done_task"
status: open
priority: high
labels: [bug, race-condition]
created: 2026-01-29
---

## Problem
```bash
sleep 1
tmux kill-session -t "$sender" 2>/dev/null &
```

The `&` backgrounds the kill but `done_task` returns immediately. If the worker has more work queued, it might execute before the kill arrives. Backgrounding a kill is unusual.

## Location
`mob:297-298`

## Solution
Just do it synchronously:
```bash
sleep 1
tmux kill-session -t "$sender" 2>/dev/null || true
```

Or use `exec` to replace the shell:
```bash
echo "Completion queued for $coord_session"
sleep 1
exec tmux kill-session -t "$sender"
```
