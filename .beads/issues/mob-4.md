---
id: mob-4
title: "Refactor spawn() to eliminate 70 lines of duplication"
status: open
priority: medium
labels: [refactor, dry]
created: 2026-01-29
---

## Problem
The `spawn()` function is 70 lines of nearly identical copy-paste for each role type.

## Location
`mob:141-209`

## Solution
Use associative arrays for role configuration:

```bash
declare -A ROLE_TOOLS=(
    [worker]="$WORKER_TOOLS"
    [researcher]="$RESEARCHER_TOOLS"
    [reviewer]="$REVIEWER_TOOLS"
    [planner]="$PLANNER_TOOLS"
)
declare -A ROLE_MODELS=(
    [worker]="sonnet"
    [researcher]="sonnet"
    [reviewer]="sonnet"
    [planner]="opus"
)
declare -A ROLE_PROMPTS=(
    [worker]="$WORKER_PROMPT"
    [researcher]="$RESEARCHER_PROMPT"
    [reviewer]="$REVIEWER_PROMPT"
    [planner]="$PLANNER_PROMPT"
    [coord]="$COORD_PROMPT"
)

spawn() {
    local role="$1"
    local id="${2:-$(date +%s)}"
    local name="${SESSION_PREFIX}-${role}-${id}"
    local base_role="${role%%[0-9]*}"

    # ... single code path using arrays
}
```

This reduces spawn() from ~70 lines to ~25 lines.
