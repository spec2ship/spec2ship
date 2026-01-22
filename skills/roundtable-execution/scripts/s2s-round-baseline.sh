#!/bin/bash
# s2s-round-baseline.sh - Complete token tracking for roundtable rounds
# Works on: Linux, Windows (Git Bash), macOS
#
# Usage:
#   s2s-round-baseline.sh init <session-id> <round-number>    # Capture T0, save baseline
#   s2s-round-baseline.sh capture <T1|T2|T3>                  # Capture checkpoint
#   s2s-round-baseline.sh recap <session-id> <participant-count>  # Calculate breakdown
#   s2s-round-baseline.sh cleanup                              # Remove cache
#
# Output (eval-able):
#   init:    CURRENT_K, ESTIMATED_K, ESTIMATED_TOTAL_K, JSONL_FILE
#   capture: (appends to cache file)
#   recap:   QUESTION_K, PARTICIPANTS_K, PARTICIPANT_AVG_K, SYNTHESIS_K, ROUND_DELTA_K, ROUND_END_K, ROUND_DELTA_COST, ROUND_END_COST

ACTION="$1"
CACHE_FILE="$HOME/.claude/cache/s2s-round-baseline.txt"
CONTEXT_LIMIT=200000  # Claude Code context limit in tokens

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

    # Find last line with usage data
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

# Helper: Find JSONL file for current project
find_jsonl_file() {
    local raw_cwd=$(pwd)
    local cwd_encoded

    # Check if Windows Git Bash path: /c/Users/... or /d/Work/...
    local drive_letter=$(echo "$raw_cwd" | sed -n 's|^/\([a-zA-Z]\)/.*|\1|p')

    if [[ -n "$drive_letter" ]]; then
        # Git Bash on Windows: /c/Users/... -> C--Users-...
        drive_letter=$(echo "$drive_letter" | tr '[:lower:]' '[:upper:]')
        local rest_path=$(echo "$raw_cwd" | sed 's|^/[a-zA-Z]/||; s|/|-|g; s|_|-|g')
        cwd_encoded="${drive_letter}--${rest_path}"
    else
        # Unix: /home/user/project -> -home-user-project
        cwd_encoded=$(echo "$raw_cwd" | tr '/' '-' | sed 's/_/-/g')
    fi

    local jsonl_dir="$HOME/.claude/projects/${cwd_encoded}"
    ls -t "${jsonl_dir}"/*.jsonl 2>/dev/null | head -1
}

case "$ACTION" in
    init)
        SESSION_ID="$2"
        ROUND_NUMBER="$3"

        # Find JSONL file
        JSONL_FILE=$(find_jsonl_file)

        # Get current tokens and cost
        if [[ -n "$JSONL_FILE" && -f "$JSONL_FILE" ]]; then
            ROUND_START_TOKENS=$(get_tokens_from_jsonl "$JSONL_FILE")
            ROUND_START_COST=$(get_cost_from_jsonl "$JSONL_FILE")
        else
            ROUND_START_TOKENS=0
            ROUND_START_COST=0
        fi

        # Calculate estimate based on previous rounds
        if [[ $ROUND_NUMBER -gt 0 ]]; then
            # Read previous round tokens from session file
            PREV_ROUNDS=$(grep -A5 "by_round:" ".s2s/sessions/${SESSION_ID}.yaml" 2>/dev/null | grep "combined:" | tail -3 | awk '{print $2}')

            if [[ -n "$PREV_ROUNDS" ]]; then
                ESTIMATED_TOKENS=$(echo "$PREV_ROUNDS" | awk '{sum+=$1; count++} END {print int(sum/count)}')
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

        # Determine status based on estimated usage after round
        if [[ $ESTIMATED_TOTAL_PCT -lt 60 ]]; then
            CONTEXT_STATUS="OK"
        elif [[ $ESTIMATED_TOTAL_PCT -lt 80 ]]; then
            CONTEXT_STATUS="WARNING"
        else
            CONTEXT_STATUS="CRITICAL"
        fi

        # Calculate available tokens
        AVAILABLE_K=$(( (CONTEXT_LIMIT - ROUND_START_TOKENS) / 1000 ))

        # Generate progress bar for current status (16 chars total)
        FILLED=$(awk "BEGIN {printf \"%.0f\", ($CURRENT_PCT / 100) * 16}")
        FILLED=${FILLED:-0}
        if [[ $FILLED -gt 16 ]]; then FILLED=16; fi
        EMPTY=$((16 - FILLED))
        PROGRESS_BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '#')$(printf '%*s' "$EMPTY" '' | tr ' ' '-')

        # Save baseline to cache
        mkdir -p "$HOME/.claude/cache"
        cat > "$CACHE_FILE" <<EOF
sessionId=${SESSION_ID}
round=$((ROUND_NUMBER + 1))
startTokens=${ROUND_START_TOKENS}
startCost=${ROUND_START_COST}
jsonlFile=${JSONL_FILE}
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
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
        ;;

    capture)
        CHECKPOINT="$2"  # T1, T2, or T3

        # Load cache to get JSONL file path
        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        # Capture current tokens
        TOKENS=$(get_tokens_from_jsonl "$jsonlFile")

        # Append to cache
        echo "${CHECKPOINT}=${TOKENS}" >> "$CACHE_FILE"
        ;;

    recap)
        SESSION_ID="$2"
        PARTICIPANT_COUNT="$3"
        PARTICIPANT_COUNT=${PARTICIPANT_COUNT:-4}

        # Load all captured values
        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        T0_TOKENS=${startTokens:-0}
        T1_TOKENS=${T1:-0}
        T2_TOKENS=${T2:-0}
        T3_TOKENS=${T3:-0}
        ROUND_START_COST=${startCost:-0}

        # Calculate per-phase breakdown
        QUESTION_TOKENS=$((T1_TOKENS - T0_TOKENS))
        PARTICIPANTS_TOKENS=$((T2_TOKENS - T1_TOKENS))
        SYNTHESIS_TOKENS=$((T3_TOKENS - T2_TOKENS))
        ROUND_DELTA_TOKENS=$((T3_TOKENS - T0_TOKENS))

        # Calculate participant average
        if [[ $PARTICIPANT_COUNT -gt 0 ]]; then
            PARTICIPANT_AVG=$((PARTICIPANTS_TOKENS / PARTICIPANT_COUNT))
        else
            PARTICIPANT_AVG=0
        fi

        # Get end cost
        ROUND_END_COST=$(get_cost_from_jsonl "$jsonlFile")
        ROUND_DELTA_COST=$(awk "BEGIN {printf \"%.2f\", $ROUND_END_COST - $ROUND_START_COST}")

        # Format for display (in K)
        QUESTION_K=$(awk "BEGIN {printf \"%.1f\", $QUESTION_TOKENS / 1000}")
        PARTICIPANTS_K=$(awk "BEGIN {printf \"%.1f\", $PARTICIPANTS_TOKENS / 1000}")
        PARTICIPANT_AVG_K=$(awk "BEGIN {printf \"%.1f\", $PARTICIPANT_AVG / 1000}")
        SYNTHESIS_K=$(awk "BEGIN {printf \"%.1f\", $SYNTHESIS_TOKENS / 1000}")
        ROUND_DELTA_K=$(awk "BEGIN {printf \"%.1f\", $ROUND_DELTA_TOKENS / 1000}")
        ROUND_END_K=$(awk "BEGIN {printf \"%.1f\", $T3_TOKENS / 1000}")

        # Calculate percentage and status
        CONTEXT_PCT=$(awk "BEGIN {printf \"%.0f\", ($T3_TOKENS / $CONTEXT_LIMIT) * 100}")

        # Determine status
        if [[ $CONTEXT_PCT -lt 60 ]]; then
            CONTEXT_STATUS="OK"
        elif [[ $CONTEXT_PCT -lt 80 ]]; then
            CONTEXT_STATUS="WARNING"
        else
            CONTEXT_STATUS="CRITICAL"
        fi

        # Generate progress bar (16 chars total)
        FILLED=$(awk "BEGIN {printf \"%.0f\", ($CONTEXT_PCT / 100) * 16}")
        FILLED=${FILLED:-0}
        if [[ $FILLED -gt 16 ]]; then FILLED=16; fi
        EMPTY=$((16 - FILLED))
        PROGRESS_BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '#')$(printf '%*s' "$EMPTY" '' | tr ' ' '-')

        # Output eval-able variables
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
        ;;

    summary)
        # Final session summary - calculates total consumed since session start
        # Load cache to get initial values
        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        SESSION_START_TOKENS=${startTokens:-0}

        # Get current tokens
        CURRENT_TOKENS=$(get_tokens_from_jsonl "$jsonlFile")

        # Calculate session consumption
        SESSION_CONSUMED=$((CURRENT_TOKENS - SESSION_START_TOKENS))

        # Format for display
        SESSION_CONSUMED_K=$(awk "BEGIN {printf \"%.1f\", $SESSION_CONSUMED / 1000}")
        FINAL_TOTAL_K=$(awk "BEGIN {printf \"%.1f\", $CURRENT_TOKENS / 1000}")

        # Calculate percentage and status
        CONTEXT_PCT=$(awk "BEGIN {printf \"%.0f\", ($CURRENT_TOKENS / $CONTEXT_LIMIT) * 100}")

        # Determine status
        if [[ $CONTEXT_PCT -lt 60 ]]; then
            CONTEXT_STATUS="OK"
        elif [[ $CONTEXT_PCT -lt 80 ]]; then
            CONTEXT_STATUS="WARNING"
        else
            CONTEXT_STATUS="CRITICAL"
        fi

        # Generate progress bar (16 chars total)
        FILLED=$(awk "BEGIN {printf \"%.0f\", ($CONTEXT_PCT / 100) * 16}")
        FILLED=${FILLED:-0}
        if [[ $FILLED -gt 16 ]]; then FILLED=16; fi
        EMPTY=$((16 - FILLED))
        PROGRESS_BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '#')$(printf '%*s' "$EMPTY" '' | tr ' ' '-')

        # Output eval-able variables
        echo "SESSION_CONSUMED_K=${SESSION_CONSUMED_K}"
        echo "FINAL_TOTAL_K=${FINAL_TOTAL_K}"
        echo "CONTEXT_PCT=${CONTEXT_PCT}"
        echo "CONTEXT_STATUS=${CONTEXT_STATUS}"
        echo "PROGRESS_BAR=${PROGRESS_BAR}"
        ;;

    cleanup)
        rm -f "$CACHE_FILE"
        ;;

    *)
        echo "Usage: $0 {init|capture|recap|summary|cleanup} [args...]" >&2
        exit 1
        ;;
esac
