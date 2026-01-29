---
id: mob-15
title: "Split into modular source files"
status: open
priority: medium
labels: [architecture, refactor]
created: 2026-01-29
---

## Problem
The 1000-line bash file is getting unwieldy for maintenance.

## Proposal
Split into sourced modules:
```
mob              # Main entry point
lib/
  config.sh      # Constants, tool lists, prompts
  session.sh     # spawn, kill, attach, list functions
  health.sh      # Health checks, zombie detection, heartbeats
  messaging.sh   # send, broadcast, inbox, report, done, ask
  utils.sh       # Helpers (_list_sessions, _format_duration, etc.)
```

Main script becomes:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/session.sh"
source "$SCRIPT_DIR/lib/health.sh"
source "$SCRIPT_DIR/lib/messaging.sh"

main "$@"
```

## Considerations
- Adds complexity for single-file distribution
- Could provide `mob-bundle` that concatenates for distribution
