---
id: mob-11
title: "Add inherit_errexit for better error handling"
status: open
priority: low
labels: [robustness]
created: 2026-01-29
---

## Problem
`set -euo pipefail` doesn't propagate errexit to command substitutions in all bash versions.

## Location
`mob:2`

## Solution
Add after the set line:
```bash
set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true
```

This ensures subshells and command substitutions inherit the errexit option (bash 4.4+).
