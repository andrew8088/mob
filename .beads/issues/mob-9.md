---
id: mob-9
title: "Fix process group detection in is_claude_running_in_session"
status: open
priority: high
labels: [bug]
created: 2026-01-29
---

## Problem
`ps -o pid,comm -g "$pane_pid"` uses `-g` for process group, but the pane PID isn't necessarily a process group leader. This can miss running Claude processes.

## Location
`mob:446-475`

## Solution
Simplify using pgrep:
```bash
is_claude_running_in_session() {
    local session="$1"
    local pane_pid
    pane_pid=$(tmux list-panes -t "$session" -F "#{pane_pid}" 2>/dev/null | head -1)
    [[ -z "$pane_pid" ]] && return 1
    
    pgrep -P "$pane_pid" -a 2>/dev/null | grep -qE "claude|node"
}
```

This directly checks child processes of the pane for claude/node.
