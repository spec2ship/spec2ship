#!/bin/bash
# test-statusline.sh - hermetic regression tests for statusline.sh
#
# Black-box: feeds Claude Code's statusline JSON on stdin with HOME pointed at a
# temp dir (no global statusline -> forces the s2s fallback branch), then asserts
# on (a) the .s2s/context-window.json it writes and (b) the fallback line it
# prints. No network, no real settings. Locks BUG-019 (dynamic context window)
# and BUG-020 (percentage-based progress bar).
#
# Run: bash templates/statusline/tests/test-statusline.sh
# Exit: 0 = all pass, 1 = any failure. SKIP (exit 0) if jq is unavailable.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE="${SCRIPT_DIR}/../statusline.sh"

if [[ ! -f "$STATUSLINE" ]]; then
    echo "FAIL: statusline.sh not found at $STATUSLINE" >&2
    exit 1
fi

# The statusline script hard-depends on jq. Without it every jq call yields empty
# and the assertions are meaningless, so skip rather than report false failures.
if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not available - statusline.sh requires jq" >&2
    exit 0
fi

PASS=0
FAIL=0

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "  ok: ${label}=${actual}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${label} expected '${expected}', got '${actual}'" >&2
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  ok: ${label} contains '${needle}'"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${label} should contain '${needle}', got: ${haystack}" >&2
        FAIL=$((FAIL + 1))
    fi
}

# Run statusline.sh in a hermetic sandbox and echo its stdout.
# Args: project_dir (created by caller), used_pct, window_size ("" to omit field).
# The caller owns project_dir so it can read the json the script writes (this
# function runs in a command-substitution subshell, so it cannot export it).
run_statusline() {
    local proj="$1" pct="$2" size="$3"
    local fake_home
    fake_home=$(mktemp -d)   # no .claude/settings.json -> fallback branch

    local size_field=""
    [[ -n "$size" ]] && size_field="\"context_window_size\": ${size},"

    local input
    input=$(cat <<EOF
{
  "session_id": "test-session",
  "model": { "display_name": "Test" },
  "workspace": { "current_dir": "${proj}" },
  "context_window": {
    "used_percentage": ${pct},
    "remaining_percentage": $((100 - pct)),
    ${size_field}
    "total_input_tokens": 0,
    "total_output_tokens": 0
  },
  "cost": { "total_cost_usd": 0 }
}
EOF
)
    HOME="$fake_home" printf '%s' "$input" | bash "$STATUSLINE"
    rm -rf "$fake_home"
}

# Count filled bar slots (BUG-020: '⛁' per 10% of the window).
filled_slots() { printf '%s' "$1" | grep -o '⛁' | wc -l | tr -d ' '; }

# --- Test 1: BUG-019 — current_context_tokens scales to a 1M window ----------
echo "Test 1: BUG-019 context-window.json uses the real 1M window"
PROJ=$(mktemp -d)
OUT=$(run_statusline "$PROJ" 14 1000000)
JSON="${PROJ}/.s2s/context-window.json"
assert_eq "current_context_tokens" "140000" "$(jq -r '.current_context_tokens' "$JSON")"
assert_eq "context_window_size" "1000000" "$(jq -r '.context_window_size' "$JSON")"
assert_eq "used_percentage" "14" "$(jq -r '.used_percentage' "$JSON")"
# Fallback line shows real used/available, not 200k-scaled values.
assert_contains "fallback line (used)" "$OUT" "140k (14%)"
assert_contains "fallback line (avail)" "$OUT" "860k"
rm -rf "$PROJ"

# --- Test 2: BUG-019 — default window (size absent) falls back to 200k -------
echo "Test 2: BUG-019 default 200k window when size absent"
PROJ=$(mktemp -d)
OUT=$(run_statusline "$PROJ" 14 "")
JSON="${PROJ}/.s2s/context-window.json"
assert_eq "current_context_tokens" "28000" "$(jq -r '.current_context_tokens' "$JSON")"  # 200000*14/100
assert_contains "fallback line (used)" "$OUT" "28k (14%)"
rm -rf "$PROJ"

# --- Test 3: BUG-020 — progress bar is percentage-based ----------------------
# Window-agnostic: filled slots = round(pct/10). On a 1M window the old USED_K/20
# formula pegged the bar to full at 20% used; the percentage formula must not.
echo "Test 3: BUG-020 bar slots = round(pct/10) on a 1M window"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 14 1000000); assert_eq "filled@14%" "1" "$(filled_slots "$OUT")"; rm -rf "$PROJ"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 50 1000000); assert_eq "filled@50%" "5" "$(filled_slots "$OUT")"; rm -rf "$PROJ"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 80 1000000); assert_eq "filled@80%" "8" "$(filled_slots "$OUT")"; rm -rf "$PROJ"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 95 1000000); assert_eq "filled@95%" "10" "$(filled_slots "$OUT")"; rm -rf "$PROJ"

# --- Summary ----------------------------------------------------------------
echo ""
echo "Passed: ${PASS}, Failed: ${FAIL}"
[[ $FAIL -eq 0 ]] || exit 1
echo "All statusline tests passed."
