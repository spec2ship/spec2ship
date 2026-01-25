#!/bin/bash
# token-tracker.sh - Token tracking for roundtable sessions
# Works on: Linux, Windows (Git Bash), macOS
#
# Version: 3.0.1 - Fix floating point arithmetic in statusline percentage
#
# Usage:
#   token-tracker.sh init <session-id> <round-number> [cc-session-id]
#   token-tracker.sh capture <session-id> <T1|T2|T3> [cc-session-id]
#   token-tracker.sh recap <session-id> <participant-count> [cc-session-id]
#   token-tracker.sh summary <session-id> [cc-session-id]
#   token-tracker.sh cleanup <session-id>
#
# Output (eval-able):
#   init:    CURRENT_K, ESTIMATED_K, ESTIMATED_TOTAL_K, ORCHESTRATOR_GAP_K, STATUSLINE_ACTIVE
#   capture: (appends to cache file)
#   recap:   QUESTION_K, PARTICIPANTS_K, SYNTHESIS_K, ROUND_DELTA_K, ROUND_END_K
#   summary: SESSION_CONSUMED_K, ROUNDS_TOTAL_K, ORCHESTRATOR_ESTIMATED_K, FINAL_TOTAL_K
#
# Token tracking model:
#   - sessionStartTokens: captured at first init (round=0), never overwritten
#   - startTokens (T0): captured at each round init
#   - T1, T2, T3: captured during round execution
#   - lastT3: saved after recap to calculate gap to next round
#   - roundsDeltaAccum: accumulator of all round deltas
#   - Orchestrator overhead = SESSION_CONSUMED - roundsDeltaAccum (estimated, shown as ~)
#
# Data sources (in priority order):
#   1. Statusline temp file (accurate, session-isolated, survives /compact)
#   2. JSONL file (fallback, may be stale after /compact)
#
# Session isolation:
#   - Statusline writes to: $TMPDIR/s2s-context-window-{cc-session-id}.json
#   - Token tracker cache: .s2s/sessions/{rt-session-id}.cache
#   - Each CC session has its own context file, no conflicts

ACTION="$1"
CONTEXT_LIMIT=200000  # Claude Code context limit in tokens

# Temp directory for statusline context files
S2S_TMPDIR="${CLAUDE_CODE_TMPDIR:-${TMPDIR:-/tmp}}"

# Helper: Get cache file path for a roundtable session (project-local)
get_cache_file() {
    local session_id="$1"
    if [[ -z "$session_id" ]]; then
        echo ".s2s/sessions/token-tracker.cache"
    else
        local safe_id=$(echo "$session_id" | sed 's/[^a-zA-Z0-9_-]/-/g')
        echo ".s2s/sessions/${safe_id}.cache"
    fi
}

# Helper: Get context window file path for a CC session (temp directory)
get_context_window_file() {
    local cc_session_id="$1"
    if [[ -z "$cc_session_id" ]]; then
        echo ""
    else
        echo "$S2S_TMPDIR/s2s-context-window-${cc_session_id}.json"
    fi
}

# Helper: Extract token field from JSONL line using sed (cross-platform)
extract_number() {
    local field="$1"
    local line="$2"
    echo "$line" | sed -n "s/.*\"${field}\":\([0-9]*\).*/\1/p" | head -1
}

# Helper: Get total tokens from JSONL file
get_tokens_from_jsonl() {
    local jsonl_file="$1"

    if [[ -z "$jsonl_file" || ! -f "$jsonl_file" ]]; then
        echo "0"
        return
    fi

    local usage_line=$(grep '"type":"assistant"' "$jsonl_file" | grep '"usage"' | tail -1)

    if [[ -z "$usage_line" ]]; then
        usage_line=$(grep 'input_tokens' "$jsonl_file" | tail -1)
    fi

    if [[ -z "$usage_line" ]]; then
        echo "0"
        return
    fi

    local input=$(extract_number "input_tokens" "$usage_line")
    local cache_create=$(extract_number "cache_creation_input_tokens" "$usage_line")
    local cache_read=$(extract_number "cache_read_input_tokens" "$usage_line")

    echo $((${input:-0} + ${cache_create:-0} + ${cache_read:-0}))
}

# Helper: Get cost from JSONL file
get_cost_from_jsonl() {
    local jsonl_file="$1"

    if [[ -z "$jsonl_file" || ! -f "$jsonl_file" ]]; then
        echo "0"
        return
    fi

    local cost_line=$(grep '"costUSD"' "$jsonl_file" | tail -1)
    local cost=$(echo "$cost_line" | sed -n 's/.*"costUSD":\([0-9.]*\).*/\1/p' | head -1)
    echo "${cost:-0}"
}

# Helper: Get tokens from statusline temp file (session-specific)
# Returns: tokens (empty if not available or wrong session)
get_tokens_from_statusline() {
    local cc_session_id="$1"
    local context_file=$(get_context_window_file "$cc_session_id")

    if [[ -z "$context_file" || ! -f "$context_file" ]]; then
        echo ""
        return
    fi

    # Verify session ID matches (statusline writes session_id in the file)
    local file_session=$(jq -r '.session_id // ""' "$context_file" 2>/dev/null)
    if [[ -n "$cc_session_id" && "$file_session" != "$cc_session_id" ]]; then
        # Session mismatch - file from different session
        echo ""
        return
    fi

    local used_pct=$(jq -r '.used_percentage // 0' "$context_file" 2>/dev/null)

    if [[ -n "$used_pct" && "$used_pct" != "null" && "$used_pct" != "0" ]]; then
        # Use awk for floating point math (bash doesn't support floats)
        local tokens=$(awk "BEGIN {printf \"%.0f\", $CONTEXT_LIMIT * $used_pct / 100}")
        echo "$tokens"
        return
    fi

    echo ""
}

# Helper: Get current tokens (tries statusline first, falls back to JSONL)
# Returns: "tokens:source" format (e.g., "78000:statusline" or "76000:jsonl")
get_current_tokens() {
    local jsonl_file="$1"
    local cc_session_id="$2"

    # Try statusline first (accurate, survives /compact)
    local tokens=$(get_tokens_from_statusline "$cc_session_id")

    if [[ -n "$tokens" && "$tokens" != "0" ]]; then
        echo "${tokens}:statusline"
        return
    fi

    # Fallback to JSONL (may be stale after /compact)
    local jsonl_tokens=$(get_tokens_from_jsonl "$jsonl_file")
    echo "${jsonl_tokens}:jsonl"
}

# Helper: Find JSONL file for current project
find_jsonl_file() {
    local raw_cwd=$(pwd)
    local cwd_encoded

    local drive_letter=$(echo "$raw_cwd" | sed -n 's|^/\([a-zA-Z]\)/.*|\1|p')

    if [[ -n "$drive_letter" ]]; then
        drive_letter=$(echo "$drive_letter" | tr '[:lower:]' '[:upper:]')
        local rest_path=$(echo "$raw_cwd" | sed 's|^/[a-zA-Z]/||; s|/|-|g; s|_|-|g')
        cwd_encoded="${drive_letter}--${rest_path}"
    else
        cwd_encoded=$(echo "$raw_cwd" | tr '/' '-' | sed 's/_/-/g')
    fi

    local jsonl_dir="$HOME/.claude/projects/${cwd_encoded}"
    ls -t "${jsonl_dir}"/*.jsonl 2>/dev/null | head -1
}

# Helper: Check if statusline is active for this CC session
check_statusline_active() {
    local cc_session_id="$1"
    local context_file=$(get_context_window_file "$cc_session_id")

    if [[ -n "$context_file" && -f "$context_file" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

case "$ACTION" in
    init)
        SESSION_ID="$2"
        ROUND_NUMBER="$3"
        CC_SESSION_ID="$4"
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        # Ensure cache directory exists
        mkdir -p "$(dirname "$CACHE_FILE")"

        # Find JSONL file
        JSONL_FILE=$(find_jsonl_file)

        # Check if statusline is active
        STATUSLINE_ACTIVE=$(check_statusline_active "$CC_SESSION_ID")

        # Get current tokens (statusline preferred, JSONL fallback)
        _RESULT=$(get_current_tokens "$JSONL_FILE" "$CC_SESSION_ID")
        ROUND_START_TOKENS=${_RESULT%%:*}
        CONTEXT_SOURCE=${_RESULT##*:}
        ROUND_START_TOKENS=${ROUND_START_TOKENS:-0}

        # Get cost from JSONL (only source for cost data)
        if [[ -n "$JSONL_FILE" && -f "$JSONL_FILE" ]]; then
            ROUND_START_COST=$(get_cost_from_jsonl "$JSONL_FILE")
        else
            ROUND_START_COST=0
        fi

        # Preserve session-level values across rounds
        SESSION_START_TOKENS=$ROUND_START_TOKENS
        LAST_T3=0
        ROUNDS_DELTA_ACCUM=0
        ORCHESTRATOR_GAP=0

        if [[ $ROUND_NUMBER -gt 0 && -f "$CACHE_FILE" ]]; then
            PREV_SESSION_START=$(grep "^sessionStartTokens=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)
            PREV_LAST_T3=$(grep "^lastT3=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)
            PREV_ROUNDS_ACCUM=$(grep "^roundsDeltaAccum=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)

            if [[ -n "$PREV_SESSION_START" ]]; then
                SESSION_START_TOKENS=$PREV_SESSION_START
            fi
            if [[ -n "$PREV_ROUNDS_ACCUM" ]]; then
                ROUNDS_DELTA_ACCUM=$PREV_ROUNDS_ACCUM
            fi
            if [[ -n "$PREV_LAST_T3" && "$PREV_LAST_T3" -gt 0 ]]; then
                LAST_T3=$PREV_LAST_T3
                ORCHESTRATOR_GAP=$((ROUND_START_TOKENS - LAST_T3))
                # BUG-006: Detect /compact (negative gap)
                if [[ $ORCHESTRATOR_GAP -lt 0 ]]; then
                    ORCHESTRATOR_GAP=0
                    COMPACT_DETECTED="true"
                fi
            fi
        fi

        # Calculate estimate based on previous rounds
        if [[ $ROUND_NUMBER -gt 0 ]]; then
            PREV_ROUNDS=$(grep -A5 "by_round:" ".s2s/sessions/${SESSION_ID}.yaml" 2>/dev/null | grep "total_k:" | tail -3 | awk '{print $2}')

            if [[ -n "$PREV_ROUNDS" ]]; then
                ESTIMATED_TOKENS=$(echo "$PREV_ROUNDS" | awk '{sum+=$1*1000; count++} END {print int(sum/count)}')
                ESTIMATED_K=$((ESTIMATED_TOKENS / 1000))
                ESTIMATED_TOTAL_K=$(( (ROUND_START_TOKENS + ESTIMATED_TOKENS) / 1000 ))
            else
                ESTIMATED_K=20
                ESTIMATED_TOTAL_K=$(( (ROUND_START_TOKENS + 20000) / 1000 ))
            fi
        else
            ESTIMATED_K=20
            ESTIMATED_TOTAL_K=$(( (ROUND_START_TOKENS + 20000) / 1000 ))
        fi

        CURRENT_K=$((ROUND_START_TOKENS / 1000))

        # Calculate percentage and status
        CURRENT_PCT=$(awk "BEGIN {printf \"%.0f\", ($ROUND_START_TOKENS / $CONTEXT_LIMIT) * 100}")
        ESTIMATED_TOTAL_PCT=$(awk "BEGIN {printf \"%.0f\", (($ROUND_START_TOKENS + ${ESTIMATED_TOKENS:-20000}) / $CONTEXT_LIMIT) * 100}")

        if [[ $ESTIMATED_TOTAL_PCT -lt 60 ]]; then
            CONTEXT_STATUS="OK"
        elif [[ $ESTIMATED_TOTAL_PCT -lt 80 ]]; then
            CONTEXT_STATUS="WARNING"
        else
            CONTEXT_STATUS="CRITICAL"
        fi

        AVAILABLE_K=$(( (CONTEXT_LIMIT - ROUND_START_TOKENS) / 1000 ))

        # Generate progress bar
        FILLED=$(awk "BEGIN {printf \"%.0f\", ($CURRENT_PCT / 100) * 16}")
        FILLED=${FILLED:-0}
        if [[ $FILLED -gt 16 ]]; then FILLED=16; fi
        EMPTY=$((16 - FILLED))
        PROGRESS_BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '#')$(printf '%*s' "$EMPTY" '' | tr ' ' '-')

        ORCHESTRATOR_GAP_K=$(awk "BEGIN {printf \"%.1f\", $ORCHESTRATOR_GAP / 1000}")

        # Save to project-local cache
        cat > "$CACHE_FILE" <<EOF
sessionId=${SESSION_ID}
ccSessionId=${CC_SESSION_ID}
sessionStartTokens=${SESSION_START_TOKENS}
round=$((ROUND_NUMBER + 1))
startTokens=${ROUND_START_TOKENS}
startCost=${ROUND_START_COST}
jsonlFile=${JSONL_FILE}
contextSource=${CONTEXT_SOURCE}
statuslineActive=${STATUSLINE_ACTIVE}
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
lastT3=${LAST_T3}
roundsDeltaAccum=${ROUNDS_DELTA_ACCUM}
orchestratorGapThisRound=${ORCHESTRATOR_GAP}
compactDetected=${COMPACT_DETECTED:-false}
EOF

        # Output eval-able variables
        echo "CURRENT_K=${CURRENT_K}"
        echo "ESTIMATED_K=${ESTIMATED_K}"
        echo "ESTIMATED_TOTAL_K=${ESTIMATED_TOTAL_K}"
        echo "CURRENT_PCT=${CURRENT_PCT}"
        echo "ESTIMATED_TOTAL_PCT=${ESTIMATED_TOTAL_PCT}"
        echo "CONTEXT_STATUS=${CONTEXT_STATUS}"
        echo "AVAILABLE_K=${AVAILABLE_K}"
        echo "PROGRESS_BAR=${PROGRESS_BAR}"
        echo "JSONL_FILE=\"${JSONL_FILE}\""
        echo "ORCHESTRATOR_GAP_K=${ORCHESTRATOR_GAP_K}"
        echo "CONTEXT_SOURCE=${CONTEXT_SOURCE}"
        echo "STATUSLINE_ACTIVE=${STATUSLINE_ACTIVE}"
        [[ "$COMPACT_DETECTED" == "true" ]] && echo "COMPACT_DETECTED=true"
        ;;

    capture)
        SESSION_ID="$2"
        CHECKPOINT="$3"
        CC_SESSION_ID="$4"
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        _RESULT=$(get_current_tokens "$jsonlFile" "$CC_SESSION_ID")
        TOKENS=${_RESULT%%:*}

        echo "${CHECKPOINT}=${TOKENS}" >> "$CACHE_FILE"
        ;;

    recap)
        SESSION_ID="$2"
        PARTICIPANT_COUNT="$3"
        CC_SESSION_ID="$4"
        PARTICIPANT_COUNT=${PARTICIPANT_COUNT:-4}
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        T0_TOKENS=${startTokens:-0}
        T1_TOKENS=${T1:-0}
        T2_TOKENS=${T2:-0}
        T3_TOKENS=${T3:-0}
        ROUND_START_COST=${startCost:-0}
        PREV_ROUNDS_ACCUM=${roundsDeltaAccum:-0}
        ORCH_GAP_THIS_ROUND=${orchestratorGapThisRound:-0}

        QUESTION_TOKENS=$((T1_TOKENS - T0_TOKENS))
        PARTICIPANTS_TOKENS=$((T2_TOKENS - T1_TOKENS))
        SYNTHESIS_TOKENS=$((T3_TOKENS - T2_TOKENS))
        ROUND_DELTA_TOKENS=$((T3_TOKENS - T0_TOKENS))

        NEW_ROUNDS_ACCUM=$((PREV_ROUNDS_ACCUM + ROUND_DELTA_TOKENS))

        if [[ $PARTICIPANT_COUNT -gt 0 ]]; then
            PARTICIPANT_AVG=$((PARTICIPANTS_TOKENS / PARTICIPANT_COUNT))
        else
            PARTICIPANT_AVG=0
        fi

        ROUND_END_COST=$(get_cost_from_jsonl "$jsonlFile")
        ROUND_DELTA_COST=$(awk "BEGIN {printf \"%.2f\", $ROUND_END_COST - $ROUND_START_COST}")

        QUESTION_K=$(awk "BEGIN {printf \"%.1f\", $QUESTION_TOKENS / 1000}")
        PARTICIPANTS_K=$(awk "BEGIN {printf \"%.1f\", $PARTICIPANTS_TOKENS / 1000}")
        PARTICIPANT_AVG_K=$(awk "BEGIN {printf \"%.1f\", $PARTICIPANT_AVG / 1000}")
        SYNTHESIS_K=$(awk "BEGIN {printf \"%.1f\", $SYNTHESIS_TOKENS / 1000}")
        ROUND_DELTA_K=$(awk "BEGIN {printf \"%.1f\", $ROUND_DELTA_TOKENS / 1000}")
        ROUND_END_K=$(awk "BEGIN {printf \"%.1f\", $T3_TOKENS / 1000}")
        ORCH_GAP_K=$(awk "BEGIN {printf \"%.1f\", $ORCH_GAP_THIS_ROUND / 1000}")
        ROUNDS_ACCUM_K=$(awk "BEGIN {printf \"%.1f\", $NEW_ROUNDS_ACCUM / 1000}")

        CONTEXT_PCT=$(awk "BEGIN {printf \"%.0f\", ($T3_TOKENS / $CONTEXT_LIMIT) * 100}")

        if [[ $CONTEXT_PCT -lt 60 ]]; then
            CONTEXT_STATUS="OK"
        elif [[ $CONTEXT_PCT -lt 80 ]]; then
            CONTEXT_STATUS="WARNING"
        else
            CONTEXT_STATUS="CRITICAL"
        fi

        FILLED=$(awk "BEGIN {printf \"%.0f\", ($CONTEXT_PCT / 100) * 16}")
        FILLED=${FILLED:-0}
        if [[ $FILLED -gt 16 ]]; then FILLED=16; fi
        EMPTY=$((16 - FILLED))
        PROGRESS_BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '#')$(printf '%*s' "$EMPTY" '' | tr ' ' '-')

        if [[ -f "$CACHE_FILE" ]]; then
            sed -i.bak "s/^lastT3=.*/lastT3=${T3_TOKENS}/" "$CACHE_FILE" 2>/dev/null || \
                sed -i '' "s/^lastT3=.*/lastT3=${T3_TOKENS}/" "$CACHE_FILE"
            sed -i.bak "s/^roundsDeltaAccum=.*/roundsDeltaAccum=${NEW_ROUNDS_ACCUM}/" "$CACHE_FILE" 2>/dev/null || \
                sed -i '' "s/^roundsDeltaAccum=.*/roundsDeltaAccum=${NEW_ROUNDS_ACCUM}/" "$CACHE_FILE"
            rm -f "${CACHE_FILE}.bak" 2>/dev/null
        fi

        echo "QUESTION_K=${QUESTION_K}"
        echo "PARTICIPANTS_K=${PARTICIPANTS_K}"
        echo "PARTICIPANT_AVG_K=${PARTICIPANT_AVG_K}"
        echo "SYNTHESIS_K=${SYNTHESIS_K}"
        echo "ROUND_DELTA_K=${ROUND_DELTA_K}"
        echo "ROUND_END_K=${ROUND_END_K}"
        echo "ROUND_DELTA_COST=${ROUND_DELTA_COST}"
        echo "ROUND_END_COST=${ROUND_END_COST}"
        echo "PARTICIPANT_COUNT=${PARTICIPANT_COUNT}"
        echo "CONTEXT_PCT=${CONTEXT_PCT}"
        echo "CONTEXT_STATUS=${CONTEXT_STATUS}"
        echo "PROGRESS_BAR=${PROGRESS_BAR}"
        echo "ORCHESTRATOR_GAP_K=${ORCH_GAP_K}"
        echo "ROUNDS_ACCUM_K=${ROUNDS_ACCUM_K}"
        echo "CONTEXT_SOURCE=${contextSource:-jsonl}"
        echo "STATUSLINE_ACTIVE=${statuslineActive:-false}"
        ;;

    summary)
        SESSION_ID="$2"
        CC_SESSION_ID="$3"
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        SESSION_START_TOKENS=${sessionStartTokens:-${startTokens:-0}}
        ROUNDS_TOTAL=${roundsDeltaAccum:-0}

        _RESULT=$(get_current_tokens "$jsonlFile" "$CC_SESSION_ID")
        CURRENT_TOKENS=${_RESULT%%:*}

        SESSION_CONSUMED=$((CURRENT_TOKENS - SESSION_START_TOKENS))
        ORCHESTRATOR_ESTIMATED=$((SESSION_CONSUMED - ROUNDS_TOTAL))

        SESSION_CONSUMED_K=$(awk "BEGIN {printf \"%.1f\", $SESSION_CONSUMED / 1000}")
        FINAL_TOTAL_K=$(awk "BEGIN {printf \"%.1f\", $CURRENT_TOKENS / 1000}")
        ROUNDS_TOTAL_K=$(awk "BEGIN {printf \"%.1f\", $ROUNDS_TOTAL / 1000}")
        ORCHESTRATOR_ESTIMATED_K=$(awk "BEGIN {printf \"%.1f\", $ORCHESTRATOR_ESTIMATED / 1000}")
        SESSION_START_K=$(awk "BEGIN {printf \"%.1f\", $SESSION_START_TOKENS / 1000}")

        CONTEXT_PCT=$(awk "BEGIN {printf \"%.0f\", ($CURRENT_TOKENS / $CONTEXT_LIMIT) * 100}")

        if [[ $CONTEXT_PCT -lt 60 ]]; then
            CONTEXT_STATUS="OK"
        elif [[ $CONTEXT_PCT -lt 80 ]]; then
            CONTEXT_STATUS="WARNING"
        else
            CONTEXT_STATUS="CRITICAL"
        fi

        FILLED=$(awk "BEGIN {printf \"%.0f\", ($CONTEXT_PCT / 100) * 16}")
        FILLED=${FILLED:-0}
        if [[ $FILLED -gt 16 ]]; then FILLED=16; fi
        EMPTY=$((16 - FILLED))
        PROGRESS_BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '#')$(printf '%*s' "$EMPTY" '' | tr ' ' '-')

        echo "SESSION_START_K=${SESSION_START_K}"
        echo "SESSION_CONSUMED_K=${SESSION_CONSUMED_K}"
        echo "ROUNDS_TOTAL_K=${ROUNDS_TOTAL_K}"
        echo "ORCHESTRATOR_ESTIMATED_K=${ORCHESTRATOR_ESTIMATED_K}"
        echo "FINAL_TOTAL_K=${FINAL_TOTAL_K}"
        echo "CONTEXT_PCT=${CONTEXT_PCT}"
        echo "CONTEXT_STATUS=${CONTEXT_STATUS}"
        echo "PROGRESS_BAR=${PROGRESS_BAR}"
        echo "CONTEXT_SOURCE=${contextSource:-jsonl}"
        echo "STATUSLINE_ACTIVE=${statuslineActive:-false}"
        ;;

    cleanup)
        SESSION_ID="$2"
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        rm -f "$CACHE_FILE"
        rm -f "${CACHE_FILE}.bak" 2>/dev/null
        ;;

    *)
        echo "Usage: $0 {init|capture|recap|summary|cleanup} <session-id> [args...] [cc-session-id]" >&2
        exit 1
        ;;
esac
