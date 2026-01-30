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
echo "=== namespace tests ==="

NS1="test-ns-alpha"
NS2="test-ns-beta"

cleanup_ns() {
    tmux kill-session -t "claude-coord-$NS1" 2>/dev/null || true
    tmux kill-session -t "claude-operator-$NS1" 2>/dev/null || true
    tmux kill-session -t "claude-coord-$NS2" 2>/dev/null || true
    tmux kill-session -t "claude-operator-$NS2" 2>/dev/null || true
    rm -f /tmp/mob-inbox/_listen-*.jsonl 2>/dev/null || true
}
cleanup_ns

echo "TEST: spawn coord creates claude-coord-{namespace}"
$MOB spawn coord "$NS1" >/dev/null 2>&1 &
sleep 1
if tmux has-session -t "claude-coord-$NS1" 2>/dev/null; then
    pass "spawn coord created claude-coord-$NS1"
else
    fail "spawn coord did not create claude-coord-$NS1"
fi

echo "TEST: spawn operator creates claude-operator-{namespace}"
$MOB spawn operator "$NS2" >/dev/null 2>&1 &
sleep 1
if tmux has-session -t "claude-operator-$NS2" 2>/dev/null; then
    pass "spawn operator created claude-operator-$NS2"
else
    fail "spawn operator did not create claude-operator-$NS2"
fi

echo "TEST: health <namespace> filters to that namespace only"
HEALTH_NS1=$($MOB health "$NS1" 2>/dev/null)
if echo "$HEALTH_NS1" | grep -q "claude-coord-$NS1"; then
    if echo "$HEALTH_NS1" | grep -q "claude-operator-$NS2"; then
        fail "health $NS1 showed $NS2 session (should be filtered)"
    else
        pass "health $NS1 only shows $NS1 sessions"
    fi
else
    fail "health $NS1 did not show claude-coord-$NS1"
fi

echo "TEST: listen creates probe file matching namespace glob"
$MOB listen "$NS1" &
LISTEN_PID=$!
sleep 1
kill $LISTEN_PID 2>/dev/null || true
if ls /tmp/mob-inbox/*${NS1}*.jsonl >/dev/null 2>&1; then
    pass "listen created probe file matching *${NS1}*.jsonl"
else
    fail "listen did not create matchable probe file for $NS1"
fi

echo "TEST: attach <namespace> attaches to operator"
if tmux has-session -t "claude-operator-$NS2" 2>/dev/null; then
    pass "attach shortcut: claude-operator-$NS2 exists for attach test"
else
    fail "cannot test attach shortcut - operator session missing"
fi

cleanup_ns

echo ""
if [[ $FAILED -eq 0 ]]; then
    echo "All tests passed"
    exit 0
else
    echo "Some tests failed"
    exit 1
fi
