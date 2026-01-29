---
id: mob-12
title: "waiting() regex could false-positive"
status: open
priority: low
labels: [bug]
created: 2026-01-29
---

## Problem
```bash
if echo "$content" | grep -qE "(Allow|Deny|Yes|No).*\?"; then
```

This would match any output containing "Yes?" or "No?" in normal conversation text, not just permission prompts.

## Location
`mob:779`

## Solution
Make the pattern more specific to Claude's actual permission prompts:
```bash
if echo "$content" | grep -qE "^\s*(Allow|Deny)\s+once\?|^\s*\[Y/n\]|^\s*\[y/N\]"; then
    state="PERMISSION PROMPT"
```

Or check for the actual Claude permission UI patterns.
