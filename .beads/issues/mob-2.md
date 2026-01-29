---
id: mob-2
title: "JSON parsing with sed is fragile"
status: open
priority: critical
labels: [bug, parsing]
created: 2026-01-29
---

## Problem
Sed regex breaks on messages containing quotes, newlines, or special chars:
```bash
msg_type=$(echo "$line" | sed -n 's/.*"type":"\([^"]*\)".*/\1/p')
```

## Location
`mob:344-346` - `inbox()` function
`mob:267,293` - JSON writing in `report()` and `done_task()`

## Solution
Use `jq` for reading:
```bash
while IFS= read -r line; do
    msg_type=$(echo "$line" | jq -r '.type')
    msg_from=$(echo "$line" | jq -r '.from')
    msg_text=$(echo "$line" | jq -r '.message')
    echo "[$msg_type from $msg_from] $msg_text"
done < "$inbox_file"
```

Escape messages when writing:
```bash
local escaped_message
escaped_message=$(printf '%s' "$message" | jq -Rs '.')
echo "{\"type\":\"REPORT\",\"from\":\"$sender\",\"message\":$escaped_message,\"ts\":$(date +%s)}" >> ...
```
