#!/bin/bash
# test-token-tracker.sh - hermetic regression tests for token-tracker.sh
#
# Black-box: builds a throwaway project dir, writes a cache file, runs the
# script with that dir as cwd, and asserts on the eval-able output. No network,
# no statusline, no JSONL needed (absent sources resolve to 0 deterministically).
#
# Run: bash skills/roundtable-execution/scripts/tests/test-token-tracker.sh
# Exit: 0 = all pass, 1 = first failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRACKER="${SCRIPT_DIR}/../token-tracker.sh"

if [[ ! -f "$TRACKER" ]]; then
    echo "FAIL: token-tracker.sh not found at $TRACKER" >&2
    exit 1
fi

PASS=0
FAIL=0

# Assert that a KEY=VALUE line in $OUTPUT has the expected value.
assert_eq() {
    local key="$1" expected="$2" output="$3"
    local actual
    actual=$(printf '%s\n' "$output" | grep "^${key}=" | head -1 | cut -d= -f2)
    if [[ "$actual" == "$expected" ]]; then
        echo "  ok: ${key}=${actual}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${key} expected '${expected}', got '${actual}'" >&2
        FAIL=$((FAIL + 1))
    fi
}

# Assert that a numeric/float KEY value is not negative (does not start with '-').
assert_non_negative() {
    local key="$1" output="$2"
    local actual
    actual=$(printf '%s\n' "$output" | grep "^${key}=" | head -1 | cut -d= -f2)
    if [[ "$actual" != -* && -n "$actual" ]]; then
        echo "  ok: ${key}=${actual} (>= 0)"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${key} should be >= 0, got '${actual}'" >&2
        FAIL=$((FAIL + 1))
    fi
}

# Assert that a KEY value is not equal to a forbidden value.
assert_ne() {
    local key="$1" forbidden="$2" output="$3"
    local actual
    actual=$(printf '%s\n' "$output" | grep "^${key}=" | head -1 | cut -d= -f2)
    if [[ "$actual" != "$forbidden" ]]; then
        echo "  ok: ${key}=${actual} (!= ${forbidden})"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${key} should not be '${forbidden}'" >&2
        FAIL=$((FAIL + 1))
    fi
}

make_project() {
    local dir
    dir=$(mktemp -d)
    mkdir -p "${dir}/.s2s/sessions"
    echo "$dir"
}

# --- Test 1: BUG-017 — post-compact recap with a zeroed T3 capture ----------
# Reproduces exp61: round-start tokens known (T0=42000), but the per-phase
# captures landed 0 (statusline momentarily 0% + JSONL unavailable) and the
# round is flagged compactDetected. Pre-fix this produced negative deltas and a
# 0% statusline; post-fix deltas are clamped >= 0 and the percentage is real.
echo "Test 1: BUG-017 recap survives /compact (zeroed captures)"
PROJ=$(make_project)
SID="20260610-specs-bug017"
cat > "${PROJ}/.s2s/sessions/${SID}.cache" <<EOF
sessionId=${SID}
sessionStartTokens=42000
round=3
startTokens=42000
startCost=0
jsonlFile=/nonexistent.jsonl
contextSource=statusline
statuslineActive=true
lastT0=0
lastT3=0
lastRoundEstimate=0
roundsDeltaAccum=0
orchestratorGapThisRound=0
compactDetected=true
workflowType=specs
strategy=standard
phase=
participantsCount=4
T1=0
T2=0
T3=0
EOF
OUT=$( cd "$PROJ" && bash "$TRACKER" recap "$SID" 4 )
assert_non_negative "QUESTION_K" "$OUT"
assert_non_negative "PARTICIPANTS_K" "$OUT"
assert_non_negative "SYNTHESIS_K" "$OUT"
assert_non_negative "ROUND_DELTA_K" "$OUT"
assert_ne "CONTEXT_PCT" "0" "$OUT"          # no phantom 0% statusline
assert_eq "RECAP_DEGRADED" "true" "$OUT"    # flagged so display can note it
assert_eq "COMPACT_DETECTED" "true" "$OUT"  # BUG-006/012 semantics preserved
rm -rf "$PROJ"

# --- Test 2: normal round — guard must NOT degrade a healthy recap ----------
# Valid monotonic captures, no compact. Deltas must be the real positive values
# and RECAP_DEGRADED must stay false.
echo "Test 2: normal recap is not degraded"
PROJ=$(make_project)
SID="20260610-specs-normal"
cat > "${PROJ}/.s2s/sessions/${SID}.cache" <<EOF
sessionId=${SID}
sessionStartTokens=100000
round=2
startTokens=100000
startCost=0
jsonlFile=/nonexistent.jsonl
contextSource=statusline
statuslineActive=true
lastT0=0
lastT3=0
lastRoundEstimate=0
roundsDeltaAccum=0
orchestratorGapThisRound=0
compactDetected=false
workflowType=specs
strategy=standard
phase=
participantsCount=4
T1=105000
T2=120000
T3=125000
EOF
OUT=$( cd "$PROJ" && bash "$TRACKER" recap "$SID" 4 )
assert_eq "QUESTION_K" "5.0" "$OUT"
assert_eq "PARTICIPANTS_K" "15.0" "$OUT"
assert_eq "SYNTHESIS_K" "5.0" "$OUT"
assert_eq "ROUND_DELTA_K" "25.0" "$OUT"
assert_eq "CONTEXT_PCT" "62" "$OUT"  # 125000/200000 = 62.5%, printf rounds half-to-even
assert_eq "RECAP_DEGRADED" "false" "$OUT"
assert_eq "COMPACT_DETECTED" "false" "$OUT"
rm -rf "$PROJ"

# --- Test 3: BUG-019 — limit adapts to a 1M window (absolute tokens correct) -
# With a statusline JSON reporting a 1M window at 14%, init must report the real
# 140k used / 860k available, not 28k / 172k scaled against a hardcoded 200k.
echo "Test 3: BUG-019 init adapts to 1M context window (current_context_tokens)"
PROJ=$(make_project)
SID="20260610-specs-1m"
cat > "${PROJ}/.s2s/context-window.json" <<EOF
{
  "session_id": "${SID}",
  "used_percentage": 14,
  "remaining_percentage": 86,
  "context_window_size": 1000000,
  "current_context_tokens": 140000
}
EOF
OUT=$( cd "$PROJ" && bash "$TRACKER" init "$SID" 0 specs standard "" 4 )
assert_eq "CURRENT_K" "140" "$OUT"      # 140000 / 1000, not 28 (200k-scaled)
assert_eq "CURRENT_PCT" "14" "$OUT"
assert_eq "AVAILABLE_K" "860" "$OUT"    # (1000000 - 140000) / 1000
rm -rf "$PROJ"

# --- Test 4: BUG-019 — pct fallback also uses the dynamic limit --------------
# Older statusline JSON without current_context_tokens: the percentage recompute
# must use the real window_size (1M), still yielding 140k, not 28k.
echo "Test 4: BUG-019 percentage fallback uses dynamic limit"
PROJ=$(make_project)
SID="20260610-specs-1m-fallback"
cat > "${PROJ}/.s2s/context-window.json" <<EOF
{
  "session_id": "${SID}",
  "used_percentage": 14,
  "context_window_size": 1000000
}
EOF
OUT=$( cd "$PROJ" && bash "$TRACKER" init "$SID" 0 specs standard "" 4 )
assert_eq "CURRENT_K" "140" "$OUT"
assert_eq "CURRENT_PCT" "14" "$OUT"
rm -rf "$PROJ"

# --- Summary ----------------------------------------------------------------
echo ""
echo "Passed: ${PASS}, Failed: ${FAIL}"
[[ $FAIL -eq 0 ]] || exit 1
echo "All token-tracker tests passed."
