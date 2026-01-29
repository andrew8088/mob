---
id: mob-10
title: "Replace heredoc || true pattern with command substitution"
status: open
priority: low
labels: [code-quality]
created: 2026-01-29
---

## Problem

The pattern `read -r -d '' VAR << 'EOF' || true` swallows real errors. The `read` command returns 1 when it hits EOF without finding a delimiter, which is expected behavior, but this pattern hides actual failures.

## Location

`mob:19,47,57,69,81` - all prompt definitions

## Solution

Use command substitution instead:

```bash
COORD_PROMPT=$(cat <<'EOF'
You are a **coordinator** ...
EOF
)
```

This is cleaner and doesn't require error suppression.
