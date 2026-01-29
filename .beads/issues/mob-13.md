---
id: mob-13
title: "Missing mkdir -p in heartbeat reading functions"
status: open
priority: medium
labels: [bug]
created: 2026-01-29
---

## Problem
If `HEARTBEAT_DIR` doesn't exist, `get_heartbeat_age` does `cat "$heartbeat_file"` which fails silently and falls back to "0", calculating a massive age incorrectly.

## Location
`mob:390-404` - `get_heartbeat_age()`

## Solution
Either ensure directory exists:
```bash
get_heartbeat_age() {
    local session="$1"
    local heartbeat_file="$HEARTBEAT_DIR/$session"

    if [[ ! -d "$HEARTBEAT_DIR" ]] || [[ ! -f "$heartbeat_file" ]]; then
        echo "-1"
        return
    fi
    # ...
}
```

Or create on first access in any heartbeat function.
