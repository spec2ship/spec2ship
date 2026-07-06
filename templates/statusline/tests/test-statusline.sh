#!/bin/bash
# test-statusline.sh - hermetic regression tests for statusline.sh
#
# Black-box: feeds Claude Code's statusline JSON on stdin, then asserts on (a) the
# .s2s/context-window.json the script writes (always, before any branch) and (b)
# the fallback status line it prints. Locks BUG-019 (dynamic context window),
# BUG-020 (percentage-based progress bar), BUG-022 (visible no-jq degradation)
# and BUG-023 (self-chain recursion guard). No network.
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

PASS=0
FAIL=0

# --- Test 0: BUG-022 - missing jq degrades visibly, before everything else ---
# Runs BEFORE the jq skip below: this branch is exactly the no-jq case. A curated
# PATH with only the tools the guard needs (no jq) forces it even where jq exists.
echo "Test 0: BUG-022 no-jq guard prints a visible notice and exits 0"
BASH_BIN=$(command -v bash)
STUB_BIN=$(mktemp -d)
for _t in cat dirname basename; do
    _p=$(command -v "$_t") && ln -s "$_p" "${STUB_BIN}/${_t}"
done
GUARD_OUT=$(printf '{}' | PATH="$STUB_BIN" "$BASH_BIN" "$STATUSLINE")
GUARD_RC=$?
rm -rf "$STUB_BIN"
if [[ "$GUARD_OUT" == *"jq not found"* && $GUARD_RC -eq 0 ]]; then
    echo "  ok: no-jq guard output '[s2s] jq not found...' with exit 0"
    PASS=$((PASS + 1))
else
    echo "  FAIL: no-jq guard expected visible notice + exit 0, got rc=${GUARD_RC}, out: ${GUARD_OUT}" >&2
    FAIL=$((FAIL + 1))
fi

# The remaining tests drive the jq branch. Without jq every jq call yields empty
# and the assertions are meaningless, so skip rather than report false failures.
if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not available - remaining statusline tests require jq" >&2
    [[ $FAIL -eq 0 ]] || exit 1
    exit 0
fi

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

# --- Test 4: BUG-023 - self-referential statusLine.command must not recurse --
# S2S_GLOBAL_SETTINGS points settings at a file whose statusLine.command is the
# statusline script itself (an executable temp copy, so -x passes). The guard
# must suppress the chain and render the fallback line exactly once. A timeout
# (when available) turns a regression into a fast FAIL instead of a hang.
echo "Test 4: BUG-023 self-chain is suppressed (fallback rendered once)"
PROJ=$(mktemp -d)
SELF_COPY="${PROJ}/statusline-self.sh"
cp "$STATUSLINE" "$SELF_COPY" && chmod +x "$SELF_COPY"
printf '{"statusLine":{"command":"%s"}}' "$SELF_COPY" > "${PROJ}/settings.json"
TIMEOUT_CMD=$(command -v timeout || true)
SELF_INPUT=$(printf '{"session_id":"t","model":{"display_name":"Test"},"workspace":{"current_dir":"%s"},"context_window":{"used_percentage":10,"remaining_percentage":90,"context_window_size":200000,"total_input_tokens":0,"total_output_tokens":0},"cost":{"total_cost_usd":0}}' "$PROJ")
OUT=$(printf '%s' "$SELF_INPUT" | S2S_GLOBAL_SETTINGS="${PROJ}/settings.json" ${TIMEOUT_CMD:+"$TIMEOUT_CMD" 10} bash "$SELF_COPY")
RC=$?
assert_eq "self-chain exit code" "0" "$RC"
assert_contains_always() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  ok: ${label} contains '${needle}'"; PASS=$((PASS + 1))
    else
        echo "  FAIL: ${label} should contain '${needle}', got: ${haystack}" >&2; FAIL=$((FAIL + 1))
    fi
}
assert_contains_always "self-chain output is the fallback line" "$OUT" "Test"
LINES=$(printf '%s\n' "$OUT" | grep -c "Test")
assert_eq "fallback rendered exactly once" "1" "$LINES"
rm -rf "$PROJ"

# --- Test 5: BUG-023 - a DIFFERENT global statusline still chains ------------
echo "Test 5: BUG-023 chaining to a distinct global statusline still works"
PROJ=$(mktemp -d)
STUB_GLOBAL="${PROJ}/global-stub.sh"
printf '#!/bin/bash\ncat >/dev/null\necho "CHAINED-OK"\n' > "$STUB_GLOBAL" && chmod +x "$STUB_GLOBAL"
printf '{"statusLine":{"command":"%s"}}' "$STUB_GLOBAL" > "${PROJ}/settings.json"
OUT=$(printf '%s' "$SELF_INPUT" | S2S_GLOBAL_SETTINGS="${PROJ}/settings.json" bash "$STATUSLINE")
assert_contains_always "chained output" "$OUT" "CHAINED-OK"
rm -rf "$PROJ"

# --- Summary ----------------------------------------------------------------
echo ""
echo "Passed: ${PASS}, Failed: ${FAIL}"
[[ $FAIL -eq 0 ]] || exit 1
echo "All statusline tests passed."
