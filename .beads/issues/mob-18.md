---
id: mob-18
title: "Add structured logging"
status: open
priority: low
labels: [feature, observability]
created: 2026-01-29
---

## Problem
All output uses bare `echo`. Hard to parse programmatically or integrate with log aggregation.

## Proposal
Add `_log()` function with JSON output option:

```bash
_log() {
    local level="$1"
    shift
    local msg="$*"
    
    if [[ "${MOB_LOG_FORMAT:-text}" == "json" ]]; then
        printf '{"ts":%d,"level":"%s","msg":"%s"}\n' \
            "$(date +%s)" "$level" "$msg"
    else
        printf "[%s] %s\n" "$level" "$msg"
    fi
}

# Usage:
_log INFO "Spawned worker $name"
_log WARN "Multiple coordinators found"
_log ERROR "Failed to acquire lock"
```

Environment variable `MOB_LOG_FORMAT=json` enables structured output.
