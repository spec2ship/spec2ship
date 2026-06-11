#!/bin/bash
# test-statusline.sh - hermetic regression tests for statusline.sh
#
# Black-box: feeds Claude Code's statusline JSON on stdin, then asserts on (a) the
# .s2s/context-window.json the script writes (always, before any branch) and (b)
# the fallback status line it prints. Locks BUG-019 (dynamic context window) and
# BUG-020 (percentage-based progress bar). No network.
#
# HOME is left untouched: faking it to suppress the global statusline would break
# $HOME-relative toolchains (e.g. an asdf-shimmed jq, which the script needs).
# Instead, the fallback-only assertions self-skip when a real global statusline is
# configured (the same condition the script checks). CI has none, so it runs them.
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
    if [[ -n "$SKIP_FALLBACK" ]]; then
        echo "  skip: ${label} (a global statusline is configured; fallback branch not exercised)"
        return
    fi
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  ok: ${label} contains '${needle}'"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${label} should contain '${needle}', got: ${haystack}" >&2
        FAIL=$((FAIL + 1))
    fi
}

# assert_eq variant for fallback-branch-only values (skips when chaining).
assert_eq_fallback() {
    if [[ -n "$SKIP_FALLBACK" ]]; then
        echo "  skip: $1 (global statusline configured; fallback branch not exercised)"
        return
    fi
    assert_eq "$@"
}

# Whether statusline.sh will chain to a global statusline instead of rendering
# its own fallback line. Mirrors the script's own check (lines 38-45). We do NOT
# fake $HOME to force the fallback: $HOME-relative toolchains (e.g. an asdf/shim
# jq) break under a synthetic HOME, and the script itself needs jq. Instead we
# run with the real HOME and skip the fallback-only assertions when a global
# statusline is actually configured. The json-write assertions run unconditionally
# (the script writes context-window.json before the chain decision). CI has no
# global statusline, so it always exercises the fallback branch.
SKIP_FALLBACK=""
_gs=""
if [[ -f "$HOME/.claude/settings.json" ]]; then
    _gs=$(jq -r '.statusLine.command // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi
[[ -n "$_gs" && -x "$_gs" ]] && SKIP_FALLBACK=1

# Run statusline.sh and echo its stdout. Always writes ${proj}/.s2s/context-window.json.
# Args: project_dir (created by caller), used_pct, window_size ("" to omit field).
run_statusline() {
    local proj="$1" pct="$2" size="$3"

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
    printf '%s' "$input" | bash "$STATUSLINE"
}

# Count filled bar slots (BUG-020: '⛁' per 10% of the window).
filled_slots() { printf '%s' "$1" | grep -o '⛁' | wc -l | tr -d ' '; }

# --- Test 1: BUG-019 - current_context_tokens scales to a 1M window ---------
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

# --- Test 2: BUG-019 - default window (size absent) falls back to 200k ------
echo "Test 2: BUG-019 default 200k window when size absent"
PROJ=$(mktemp -d)
OUT=$(run_statusline "$PROJ" 14 "")
JSON="${PROJ}/.s2s/context-window.json"
assert_eq "current_context_tokens" "28000" "$(jq -r '.current_context_tokens' "$JSON")"  # 200000*14/100
assert_contains "fallback line (used)" "$OUT" "28k (14%)"
rm -rf "$PROJ"

# --- Test 3: BUG-020 - progress bar is percentage-based ---------------------
# Window-agnostic: filled slots = round(pct/10). On a 1M window the old USED_K/20
# formula pegged the bar to full at 20% used; the percentage formula must not.
echo "Test 3: BUG-020 bar slots = round(pct/10) on a 1M window"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 14 1000000); assert_eq_fallback "filled@14%" "1" "$(filled_slots "$OUT")"; rm -rf "$PROJ"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 50 1000000); assert_eq_fallback "filled@50%" "5" "$(filled_slots "$OUT")"; rm -rf "$PROJ"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 80 1000000); assert_eq_fallback "filled@80%" "8" "$(filled_slots "$OUT")"; rm -rf "$PROJ"
PROJ=$(mktemp -d); OUT=$(run_statusline "$PROJ" 95 1000000); assert_eq_fallback "filled@95%" "10" "$(filled_slots "$OUT")"; rm -rf "$PROJ"

# --- Summary ----------------------------------------------------------------
echo ""
echo "Passed: ${PASS}, Failed: ${FAIL}"
[[ $FAIL -eq 0 ]] || exit 1
echo "All statusline tests passed."
