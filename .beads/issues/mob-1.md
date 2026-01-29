---
id: mob-1
title: "Fix broken lock trap in subshell"
status: open
priority: critical
labels: [bug, locking]
created: 2026-01-29
---

## Problem
The `trap` in `_acquire_lock` sets a trap for the main shell, but `_send_keys_locked` runs in a subshell `(...)`. The trap never fires on subshell exit, and if it did, it would clobber the parent's EXIT trap.

## Location
`mob:93-131` - `_acquire_lock()` and `_send_keys_locked()`

## Solution
Use `flock` instead of mkdir for proper cleanup:

```bash
_send_keys_locked() {
    local session="$1"
    shift
    local message="$*"
    
    mkdir -p "$LOCK_DIR"
    (
        flock -w 30 200 || { echo "Lock timeout for $session" >&2; exit 1; }
        tmux send-keys -t "$session" -l "$message"
        sleep 0.3
        tmux send-keys -t "$session" Enter
    ) 200>"$LOCK_DIR/${session}.lock"
}
```

This ensures lock is automatically released when subshell exits, even on SIGTERM.
