#!/bin/bash
# test-context-reset.sh - hermetic regression tests for context-reset.sh
#
# Black-box: builds a throwaway project with a .s2s/state.json, feeds the hook
# its SessionStart JSON on stdin, and asserts on stdout (the resume banner) and
# on the state.json mutation. The no-jq fallback path is exercised by running
# the hook under a curated PATH that omits jq (the machine still has jq for the
# test's own assertions). Locks BUG-021 (spaced-JSON parsing) and BUG-024
# (fallback scoped to active_session). No network.
#
# Run: bash templates/hooks/tests/test-context-reset.sh
# Exit: 0 = all pass, 1 = any failure. SKIP (exit 0) if jq is unavailable.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESET="${SCRIPT_DIR}/../context-reset.sh"

if [[ ! -f "$RESET" ]]; then
    echo "FAIL: context-reset.sh not found at $RESET" >&2
    exit 1
fi

# The jq-path tests need jq both to drive the script's jq branch and to read back
# state.json. The fallback test simulates jq absence per-invocation via PATH.
if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not available - context-reset.sh jq-path tests require jq" >&2
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
        echo "  FAIL: ${label} should contain '${needle}'" >&2
        FAIL=$((FAIL + 1))
    fi
}

assert_lacks() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "  ok: ${label} lacks '${needle}'"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${label} should NOT contain '${needle}'" >&2
        FAIL=$((FAIL + 1))
    fi
}

# Project with an ACTIVE roundtable session in state.json.
make_active_project() {
    local dir
    dir=$(mktemp -d)
    mkdir -p "${dir}/.s2s"
    cat > "${dir}/.s2s/state.json" <<'EOF'
{
  "active_session": {
    "workflow_type": "specs",
    "id": "20260611-specs-foo",
    "round": 3
  }
}
EOF
    echo "$dir"
}

# A PATH that has the coreutils the hook needs but deliberately NOT jq, so the
# hook takes its grep/sed fallback branch even on a machine that has jq.
make_nojq_path() {
    local bindir t p
    bindir=$(mktemp -d)
    for t in bash cat grep sed cut head tr date mv mkdir basename dirname; do
        p=$(command -v "$t") && ln -s "$p" "${bindir}/${t}"
    done
    echo "$bindir"
}

# --- Test 1: compact with active session (jq path) --------------------------
echo "Test 1: /compact resume banner + state.json last_activity (jq path)"
PROJ=$(make_active_project)
OUT=$(printf '{"cwd":"%s","source":"compact"}' "$PROJ" | bash "$RESET")
assert_contains "banner" "$OUT" "Roundtable interrupted by /compact"
assert_contains "resume cmd" "$OUT" "/s2s:specs --session 20260611-specs-foo"
assert_contains "round line" "$OUT" "Round:    3 completed"
STATE="${PROJ}/.s2s/state.json"
assert_eq "last_activity.action" "context_compact" "$(jq -r '.last_activity.action' "$STATE")"
assert_eq "last_activity.session_id" "20260611-specs-foo" "$(jq -r '.last_activity.session_id' "$STATE")"
rm -rf "$PROJ"

# --- Test 2: clear with active session --------------------------------------
echo "Test 2: /clear banner + action"
PROJ=$(make_active_project)
OUT=$(printf '{"cwd":"%s","source":"clear"}' "$PROJ" | bash "$RESET")
assert_contains "banner" "$OUT" "Roundtable interrupted by /clear"
assert_eq "last_activity.action" "context_clear" "$(jq -r '.last_activity.action' "${PROJ}/.s2s/state.json")"
rm -rf "$PROJ"

# --- Test 3: startup source is a no-op (no banner) --------------------------
echo "Test 3: source=startup does not emit a resume banner"
PROJ=$(make_active_project)
OUT=$(printf '{"cwd":"%s","source":"startup"}' "$PROJ" | bash "$RESET")
assert_lacks "banner" "$OUT" "Roundtable interrupted"
rm -rf "$PROJ"

# --- Test 4: no active session => no banner even on compact -----------------
echo "Test 4: no active_session => no banner"
PROJ=$(mktemp -d); mkdir -p "${PROJ}/.s2s"; echo '{}' > "${PROJ}/.s2s/state.json"
OUT=$(printf '{"cwd":"%s","source":"compact"}' "$PROJ" | bash "$RESET")
assert_lacks "banner" "$OUT" "Roundtable interrupted"
rm -rf "$PROJ"

# --- Test 5: not an s2s project => silent exit ------------------------------
echo "Test 5: no .s2s dir => no output"
PROJ=$(mktemp -d)
OUT=$(printf '{"cwd":"%s","source":"compact"}' "$PROJ" | bash "$RESET")
assert_eq "empty output" "" "$OUT"
rm -rf "$PROJ"

# --- Test 6: no-jq fallback still emits the banner + install note -----------
echo "Test 6: fallback (no jq) emits banner and jq-install note"
PROJ=$(make_active_project)
BINDIR=$(make_nojq_path)
OUT=$(printf '{"cwd":"%s","source":"compact"}' "$PROJ" | PATH="$BINDIR" bash "$RESET")
assert_contains "banner" "$OUT" "Roundtable interrupted by /compact"
assert_contains "resume cmd" "$OUT" "/s2s:specs --session 20260611-specs-foo"
assert_contains "jq note" "$OUT" "'jq' not found"
# Without jq the hook must NOT have rewritten state.json (last_activity stays absent).
assert_eq "state untouched" "null" "$(jq -r '.last_activity // "null"' "${PROJ}/.s2s/state.json")"
rm -rf "$PROJ" "$BINDIR"

# --- Test 7: BUG-024 - fallback must read active_session, not decoy keys ----
# state.json where "workflow_type"/"id"/"round" appear BEFORE active_session
# (a history entry and last_activity). The old file-wide grep took the first
# match and would print the decoy session in the resume command.
echo "Test 7: BUG-024 fallback (no jq) scopes extraction to active_session"
PROJ=$(mktemp -d)
mkdir -p "${PROJ}/.s2s"
cat > "${PROJ}/.s2s/state.json" <<'EOF'
{
  "last_activity": {
    "timestamp": "2026-01-01T00:00:00Z",
    "action": "context_clear",
    "session_id": "20260101-specs-decoy"
  },
  "history": [
    { "workflow_type": "design", "id": "20260101-design-decoy", "round": 9 }
  ],
  "active_session": {
    "workflow_type": "specs",
    "id": "20260611-specs-foo",
    "round": 3
  }
}
EOF
BINDIR=$(make_nojq_path)
OUT=$(printf '{"cwd":"%s","source":"compact"}' "$PROJ" | PATH="$BINDIR" bash "$RESET")
assert_contains "scoped resume cmd" "$OUT" "/s2s:specs --session 20260611-specs-foo"
assert_contains "scoped round" "$OUT" "Round:    3 completed"
assert_lacks "no decoy id" "$OUT" "decoy"
assert_lacks "no decoy round" "$OUT" "Round:    9"
rm -rf "$PROJ" "$BINDIR"

# --- Summary ----------------------------------------------------------------
echo ""
echo "Passed: ${PASS}, Failed: ${FAIL}"
[[ $FAIL -eq 0 ]] || exit 1
echo "All context-reset tests passed."
