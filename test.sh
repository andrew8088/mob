#!/usr/bin/env bash
set -euo pipefail

MOB="./mob"
PREFIX="smoketest"
FAILED=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; FAILED=1; }

cleanup() {
    local sessions
    sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "claude-${PREFIX}" || true)
    for s in $sessions; do
        tmux kill-session -t "$s" 2>/dev/null || true
    done
}
trap cleanup EXIT

echo "=== mob smoke tests ==="
cleanup

echo "TEST: spawn-quiet creates tmux session"
SESSION=$($MOB spawn-quiet "$PREFIX" 1)
if tmux has-session -t "$SESSION" 2>/dev/null; then
    pass "spawn-quiet created $SESSION"
else
    fail "spawn-quiet failed to create session"
fi

echo "TEST: list shows the session"
LIST_OUTPUT=$($MOB list)
if echo "$LIST_OUTPUT" | grep -q "$SESSION"; then
    pass "list shows $SESSION"
else
    fail "list does not show $SESSION"
fi

echo "TEST: send delivers message"
$MOB send "$SESSION" "echo hello-from-test" >/dev/null
sleep 1
PEEK_OUTPUT=$($MOB peek "$SESSION" 50)
if echo "$PEEK_OUTPUT" | grep -q "hello-from-test"; then
    pass "send delivered message"
else
    fail "send did not deliver message (peek: $PEEK_OUTPUT)"
fi

echo "TEST: health runs without error"
if $MOB health >/dev/null 2>&1; then
    pass "health command succeeded"
else
    fail "health command failed"
fi

echo "TEST: kill removes session"
$MOB kill "$SESSION" >/dev/null
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    pass "kill removed $SESSION"
else
    fail "kill did not remove $SESSION"
fi

echo "TEST: killall cleans up multiple sessions"
$MOB spawn-quiet "$PREFIX" 2 >/dev/null
$MOB spawn-quiet "$PREFIX" 3 >/dev/null
sleep 0.5
$MOB killall >/dev/null
REMAINING=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "claude-${PREFIX}" || true)
if [[ -z "$REMAINING" ]]; then
    pass "killall removed all test sessions"
else
    fail "killall left sessions: $REMAINING"
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
    echo "All tests passed"
    exit 0
else
    echo "Some tests failed"
    exit 1
fi
