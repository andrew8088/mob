---
id: mob-6
title: "Extract duration formatting helper"
status: open
priority: low
labels: [refactor, dry]
created: 2026-01-29
---

## Problem
Age/duration formatting duplicated in `health()` function.

## Locations
- `mob:527-531` - session age formatting
- `mob:549-555` - heartbeat age formatting

## Solution
```bash
_format_duration() {
    local seconds="$1"
    if [[ $seconds -ge 3600 ]]; then
        echo "$((seconds / 3600))h$((seconds % 3600 / 60))m"
    elif [[ $seconds -ge 60 ]]; then
        echo "$((seconds / 60))m$((seconds % 60))s"
    else
        echo "${seconds}s"
    fi
}
```
