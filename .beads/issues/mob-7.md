---
id: mob-7
title: "Add validation for role names"
status: open
priority: medium
labels: [robustness, validation]
created: 2026-01-29
---

## Problem
`mob spawn foobar 1` creates `claude-foobar-1` with bare `claude` (no permissions, no prompt). Invalid roles should be rejected.

## Location
`mob:141` - start of `spawn()`

## Solution
```bash
spawn() {
    local role="$1"
    local base_role="${role%%[0-9]*}"
    local valid_roles="coord worker researcher reviewer planner"
    
    if [[ ! " $valid_roles " =~ " $base_role " ]]; then
        echo "Invalid role: $role. Must be one of: $valid_roles" >&2
        return 1
    fi
    
    # ... rest of function
}
```
