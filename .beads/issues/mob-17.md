---
id: mob-17
title: "Add configuration file support"
status: open
priority: low
labels: [feature]
created: 2026-01-29
---

## Problem
All configuration is hardcoded. Users can't customize thresholds without editing the script.

## Proposal
Support config files at:
1. `/etc/mob.conf` - system-wide
2. `~/.mobrc` - user defaults
3. `./.mobrc` - project-specific

Example `.mobrc`:
```bash
PRIME_DELAY=5
HEARTBEAT_FRESH=600
HEARTBEAT_STALE=1800
ZOMBIE_GRACE_PERIOD=15
DEFAULT_MODEL="sonnet"
PLANNER_MODEL="opus"
```

Load order (later overrides earlier):
```bash
[[ -f /etc/mob.conf ]] && source /etc/mob.conf
[[ -f ~/.mobrc ]] && source ~/.mobrc
[[ -f ./.mobrc ]] && source ./.mobrc
```
