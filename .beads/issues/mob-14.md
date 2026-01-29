---
id: mob-14
title: "Use readonly for configuration constants"
status: open
priority: low
labels: [code-quality]
created: 2026-01-29
---

## Problem
Configuration constants can be accidentally overwritten.

## Location
`mob:4-12`

## Solution
```bash
readonly SESSION_PREFIX="claude"
readonly PRIME_DELAY=3
readonly ZOMBIE_GRACE_PERIOD=10
readonly HEARTBEAT_FRESH=300
readonly HEARTBEAT_STALE=900
readonly HEARTBEAT_DIR="/tmp/mob-heartbeats"
readonly LOCK_DIR="/tmp/mob-locks"
readonly LOG_DIR="/tmp/mob-logs"
readonly INBOX_DIR="/tmp/mob-inbox"
```

Also consider making tool lists readonly after definition.
