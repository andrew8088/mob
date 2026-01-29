---
id: mob-8
title: "Warn when multiple coordinators exist"
status: open
priority: low
labels: [robustness, ux]
created: 2026-01-29
---

## Problem
`coord()` silently picks the first coordinator if multiple exist via `head -1`. User might not realize they have multiple coordinators.

## Location
`mob:241-253`

## Solution
```bash
coord() {
    local coords
    coords=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${SESSION_PREFIX}-coord" || true)
    local count
    count=$(echo "$coords" | grep -c . || echo 0)
    
    if [[ $count -eq 0 ]]; then
        echo "No coordinator found" >&2
        return 1
    elif [[ $count -gt 1 ]]; then
        echo "Warning: Multiple coordinators found, using first" >&2
    fi
    
    echo "$coords" | head -1
}
```
