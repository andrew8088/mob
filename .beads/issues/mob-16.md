---
id: mob-16
title: "Implement session state machine"
status: open
priority: low
labels: [architecture, feature]
created: 2026-01-29
---

## Problem
Session health is computed from multiple sources each time (`get_session_health`). State transitions are implicit.

## Proposal
Maintain explicit state file tracking transitions:
```
created → starting → running → zombie/stuck/done
```

State file at `$STATE_DIR/$session.state`:
```json
{
  "state": "running",
  "created": 1706500000,
  "started": 1706500003,
  "last_heartbeat": 1706500100,
  "transitions": [
    {"from": "created", "to": "starting", "ts": 1706500000},
    {"from": "starting", "to": "running", "ts": 1706500003}
  ]
}
```

Benefits:
- Faster health checks (read state vs compute)
- Audit trail of state changes
- Can trigger actions on transitions
