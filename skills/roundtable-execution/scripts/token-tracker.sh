#!/bin/bash
# token-tracker.sh - Token tracking for roundtable sessions
# Works on: Linux, Windows (Git Bash), macOS
#
# Version: 5.5.0 - BUG-018: drop vestigial write-only cache fields (workflowType/
#                  strategy/phase/participantsCount); statusline RT info comes
#                  from state.json (phase-2-core.md §2.1b), not this cache.
#                  5.4.0 BUG-019: limit adapts to model window. 5.3.1 BUG-017 recap guard.
#
# Usage:
#   token-tracker.sh init <session-id> <round-number>   # (extra args ignored; back-compat)
#   token-tracker.sh capture <session-id> <T1|T2|T3>
#   token-tracker.sh recap <session-id> <participant-count>
#   token-tracker.sh summary <session-id>
#   token-tracker.sh cleanup <session-id>
#
# Output (eval-able):
#   init:    CURRENT_K, NEXT_ESTIMATE_K, SHOULD_STOP, SHOULD_WARN, PREV_ROUND_ACTUAL, PREV_ROUND_SOURCE
#   capture: (appends to cache file)
#   recap:   ROUND_TOKENS_ESTIMATE, QUESTION_K, PARTICIPANTS_K, SYNTHESIS_K, ROUND_DELTA_K, AVG_ACTUAL_K, SAMPLE_COUNT, COMPACT_DETECTED, RECAP_DEGRADED
#   summary: SESSION_CONSUMED_K, ROUNDS_TOTAL_K, ORCHESTRATOR_ESTIMATED_K, FINAL_TOTAL_K
#
# Token tracking model (TECH-009 - Progressive Precision):
#   - estimate: T3-T0 (immediate, full round subagents)
#   - actual: T0_{n+1} - T0_n (calculated next round, includes orchestrator overhead)
#   - source: "measured" | "estimated" | "interrupted" | "noisy"
#
# Per-round tracking:
#   - lastT0: saved after recap for next round's actual calculation
#   - lastT3: saved after recap for orchestrator gap detection
#   - roundsDeltaAccum: accumulator of all round deltas
#   - Orchestrator overhead = actual - estimate (measured when continuity)
#
# Data sources (in priority order):
#   1. .s2s/context-window.json (accurate, survives /compact, written by statusline)
#   2. JSONL file (fallback, may be stale after /compact)
#
# File locations (all project-local in .s2s/):
#   - Context window: .s2s/context-window.json (written by statusline ~300ms)
#   - Token cache: .s2s/sessions/{rt-session-id}.cache
#   - State file: .s2s/state.json (managed by SKILL.md, not this script)

ACTION="$1"
# BUG-019: the context window depends on the running model (1M for Opus 4.6+ /
# Sonnet 4.6, 200K for Haiku 4.5). DEFAULT is only a fallback for when the
# statusline JSON is unavailable; the real limit is resolved per-invocation from
# context_window_size below.
DEFAULT_CONTEXT_LIMIT=200000
CONTEXT_LIMIT=$DEFAULT_CONTEXT_LIMIT

# Project-local .s2s directory
S2S_DIR=".s2s"

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

# Helper: Get context window file path (project-local)
get_context_window_file() {
    echo "${S2S_DIR}/context-window.json"
}

# Note: state.json management is handled inline in roundtable-execution SKILL.md
# Token tracker only handles token metrics, not session state

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

# Helper: Get tokens from statusline context file (project-local)
# Returns: tokens (empty if not available)
get_tokens_from_statusline() {
    local context_file=$(get_context_window_file)

    if [[ ! -f "$context_file" ]]; then
        echo ""
        return
    fi

    # BUG-019: prefer the absolute count the statusline already wrote
    # (current_context_tokens = window_size * used_pct / 100). It reflects the
    # real model window and survives /compact, so we don't rescale a percentage
    # against a hardcoded limit.
    local cur_tokens=$(jq -r '.current_context_tokens // empty' "$context_file" 2>/dev/null)
    if [[ "$cur_tokens" =~ ^[0-9]+$ && "$cur_tokens" -gt 0 ]]; then
        echo "$cur_tokens"
        return
    fi

    # Fallback (older statusline JSON without current_context_tokens): recompute
    # from the percentage against the dynamic limit resolved in get_context_limit.
    local used_pct=$(jq -r '.used_percentage // 0' "$context_file" 2>/dev/null)

    if [[ -n "$used_pct" && "$used_pct" != "null" && "$used_pct" != "0" ]]; then
        # Use awk for floating point math (bash doesn't support floats)
        local tokens=$(awk "BEGIN {printf \"%.0f\", $CONTEXT_LIMIT * $used_pct / 100}")
        echo "$tokens"
        return
    fi

    echo ""
}

# Helper: Resolve the context window limit (BUG-019)
# Reads context_window_size written by the statusline (adapts to the running
# model). Falls back to DEFAULT_CONTEXT_LIMIT only when the JSON is absent or
# lacks the field.
get_context_limit() {
    local context_file=$(get_context_window_file)

    if [[ -f "$context_file" ]]; then
        local size=$(jq -r '.context_window_size // empty' "$context_file" 2>/dev/null)
        if [[ "$size" =~ ^[0-9]+$ && "$size" -gt 0 ]]; then
            echo "$size"
            return
        fi
    fi

    echo "$DEFAULT_CONTEXT_LIMIT"
}

# Helper: Get current tokens (tries statusline first, falls back to JSONL)
# Returns: "tokens:source" format (e.g., "78000:statusline" or "76000:jsonl")
get_current_tokens() {
    local jsonl_file="$1"

    # Try statusline first (accurate, survives /compact)
    local tokens=$(get_tokens_from_statusline)

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

# Helper: Check if statusline is active (context-window.json exists)
check_statusline_active() {
    local context_file=$(get_context_window_file)

    if [[ -f "$context_file" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# BUG-019: adapt the limit to the running model's actual window before any
# action computes percentages, available/remaining tokens, or the statusline
# fallback. No-op (keeps 200K) when the statusline JSON is unavailable.
CONTEXT_LIMIT=$(get_context_limit)

case "$ACTION" in
    init)
        SESSION_ID="$2"
        ROUND_NUMBER="$3"
        # BUG-018: positional args 4-7 (workflow-type/strategy/phase/
        # participants-count) are accepted for backward compatibility but no
        # longer stored — they were write-only cache fields nobody read. The
        # statusline's roundtable info comes from state.json (written every round
        # by phase-2-core.md §2.1b from on-disk profile/config, so it survives
        # /compact), not from this cache.
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        # Ensure cache directory exists
        mkdir -p "$(dirname "$CACHE_FILE")"

        # Find JSONL file
        JSONL_FILE=$(find_jsonl_file)

        # Check if statusline is active
        STATUSLINE_ACTIVE=$(check_statusline_active)

        # Get current tokens (statusline preferred, JSONL fallback)
        _RESULT=$(get_current_tokens "$JSONL_FILE")
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
        LAST_T0=0
        LAST_T3=0
        ROUNDS_DELTA_ACCUM=0
        ORCHESTRATOR_GAP=0
        PREV_ROUND_ESTIMATE=0

        # TECH-009: Progressive precision variables
        PREV_ROUND_ACTUAL=""
        PREV_ROUND_SOURCE="estimated"
        AVG_ACTUAL=0
        AVG_ESTIMATE=20000
        OVERHEAD_DELTA=0
        SAMPLE_COUNT=0

        if [[ $ROUND_NUMBER -gt 0 && -f "$CACHE_FILE" ]]; then
            PREV_SESSION_START=$(grep "^sessionStartTokens=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)
            PREV_LAST_T0=$(grep "^lastT0=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)
            PREV_LAST_T3=$(grep "^lastT3=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)
            PREV_ROUNDS_ACCUM=$(grep "^roundsDeltaAccum=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)
            PREV_ROUND_ESTIMATE=$(grep "^lastRoundEstimate=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2)

            if [[ -n "$PREV_SESSION_START" ]]; then
                SESSION_START_TOKENS=$PREV_SESSION_START
            fi
            if [[ -n "$PREV_ROUNDS_ACCUM" ]]; then
                ROUNDS_DELTA_ACCUM=$PREV_ROUNDS_ACCUM
            fi

            # TECH-009: Calculate actual for previous round
            if [[ -n "$PREV_LAST_T0" && "$PREV_LAST_T0" -gt 0 ]]; then
                LAST_T0=$PREV_LAST_T0
            fi
            if [[ -n "$PREV_LAST_T3" && "$PREV_LAST_T3" -gt 0 ]]; then
                LAST_T3=$PREV_LAST_T3
                ORCHESTRATOR_GAP=$((ROUND_START_TOKENS - LAST_T3))

                # BUG-006: Detect /compact (negative gap = context reduced)
                if [[ $ORCHESTRATOR_GAP -lt 0 ]]; then
                    ORCHESTRATOR_GAP=0
                    COMPACT_DETECTED="true"
                    PREV_ROUND_SOURCE="interrupted"
                elif [[ $LAST_T0 -gt 0 ]]; then
                    # Calculate actual: T0_new - T0_prev (full round + orchestrator)
                    PREV_ROUND_ACTUAL=$((ROUND_START_TOKENS - LAST_T0))
                    PREV_ROUND_SOURCE="measured"

                    # TECH-009: Detect noisy measurement (user did other commands)
                    # If actual >> estimate, something else happened between rounds
                    if [[ -n "$PREV_ROUND_ESTIMATE" && "$PREV_ROUND_ESTIMATE" -gt 0 ]]; then
                        DELTA=$((PREV_ROUND_ACTUAL - PREV_ROUND_ESTIMATE))
                        # If delta > 3x the estimate, mark as noisy
                        THRESHOLD=$((PREV_ROUND_ESTIMATE * 3))
                        if [[ $DELTA -gt $THRESHOLD ]]; then
                            PREV_ROUND_SOURCE="noisy"
                        fi
                    fi
                fi
            fi

            # TECH-009: Read statistics from session file
            SESSION_FILE=".s2s/sessions/${SESSION_ID}.yaml"
            if [[ -f "$SESSION_FILE" ]]; then
                # Extract actuals where source=measured (not interrupted/noisy)
                # YAML order: round, estimate, actual, source - so actual is BEFORE source
                # Using grep/awk for cross-platform compatibility
                ACTUALS=$(grep -B2 "source: \"measured\"" "$SESSION_FILE" 2>/dev/null | grep "actual:" | awk '{print $2}' | grep -v "null")
                # Extract estimates only from metrics.tokens.by_round (not other estimate: fields)
                ESTIMATES=$(grep -A20 "by_round:" "$SESSION_FILE" 2>/dev/null | grep "estimate:" | awk '{print $2}')

                if [[ -n "$ACTUALS" ]]; then
                    SAMPLE_COUNT=$(echo "$ACTUALS" | wc -l | tr -d ' ')
                    AVG_ACTUAL=$(echo "$ACTUALS" | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count); else print 0}')
                fi
                if [[ -n "$ESTIMATES" ]]; then
                    AVG_ESTIMATE=$(echo "$ESTIMATES" | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count); else print 20000}')
                fi

                # Calculate overhead delta (avg of actual - estimate for measured rounds)
                if [[ $SAMPLE_COUNT -gt 0 && $AVG_ACTUAL -gt 0 && $AVG_ESTIMATE -gt 0 ]]; then
                    OVERHEAD_DELTA=$((AVG_ACTUAL - AVG_ESTIMATE))
                    if [[ $OVERHEAD_DELTA -lt 0 ]]; then
                        OVERHEAD_DELTA=0
                    fi
                fi
            fi
        fi

        # TECH-009: Calculate next round estimate
        if [[ $SAMPLE_COUNT -ge 2 && $AVG_ACTUAL -gt 0 ]]; then
            # We have enough actual data - use it
            NEXT_ESTIMATE=$AVG_ACTUAL
        elif [[ $SAMPLE_COUNT -eq 1 && $AVG_ACTUAL -gt 0 ]]; then
            # One actual sample - use it
            NEXT_ESTIMATE=$AVG_ACTUAL
        elif [[ $AVG_ESTIMATE -gt 0 ]]; then
            # Only estimates available - add 20% buffer for orchestrator overhead
            NEXT_ESTIMATE=$(awk "BEGIN {print int($AVG_ESTIMATE * 1.2)}")
        else
            # No data - use default
            NEXT_ESTIMATE=20000
        fi

        ESTIMATED_TOKENS=$NEXT_ESTIMATE
        ESTIMATED_K=$((NEXT_ESTIMATE / 1000))
        ESTIMATED_TOTAL_K=$(( (ROUND_START_TOKENS + NEXT_ESTIMATE) / 1000 ))

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

        # TECH-009: Calculate SHOULD_STOP and SHOULD_WARN based on projection
        PROJECTED_TOTAL=$((ROUND_START_TOKENS + NEXT_ESTIMATE))
        PROJECTED_PCT=$(awk "BEGIN {printf \"%.0f\", ($PROJECTED_TOTAL / $CONTEXT_LIMIT) * 100}")

        if [[ $PROJECTED_PCT -ge 95 ]]; then
            SHOULD_STOP="true"
            SHOULD_WARN="false"
        elif [[ $PROJECTED_PCT -ge 85 ]]; then
            SHOULD_STOP="false"
            SHOULD_WARN="true"
        else
            SHOULD_STOP="false"
            SHOULD_WARN="false"
        fi

        # Save to project-local cache
        cat > "$CACHE_FILE" <<EOF
sessionId=${SESSION_ID}
sessionStartTokens=${SESSION_START_TOKENS}
round=$((ROUND_NUMBER + 1))
startTokens=${ROUND_START_TOKENS}
startCost=${ROUND_START_COST}
jsonlFile=${JSONL_FILE}
contextSource=${CONTEXT_SOURCE}
statuslineActive=${STATUSLINE_ACTIVE}
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
lastT0=${LAST_T0}
lastT3=${LAST_T3}
lastRoundEstimate=${PREV_ROUND_ESTIMATE}
roundsDeltaAccum=${ROUNDS_DELTA_ACCUM}
orchestratorGapThisRound=${ORCHESTRATOR_GAP}
compactDetected=${COMPACT_DETECTED:-false}
EOF

        # Note: state.json is updated by SKILL.md inline, not by token-tracker

        # Format K values
        NEXT_ESTIMATE_K=$(awk "BEGIN {printf \"%.1f\", $NEXT_ESTIMATE / 1000}")
        AVG_ACTUAL_K=$(awk "BEGIN {printf \"%.1f\", $AVG_ACTUAL / 1000}")
        AVG_ESTIMATE_K=$(awk "BEGIN {printf \"%.1f\", $AVG_ESTIMATE / 1000}")
        OVERHEAD_DELTA_K=$(awk "BEGIN {printf \"%.1f\", $OVERHEAD_DELTA / 1000}")
        PROJECTED_TOTAL_K=$(awk "BEGIN {printf \"%.1f\", $PROJECTED_TOTAL / 1000}")
        PREV_ROUND_ACTUAL_K=""
        if [[ -n "$PREV_ROUND_ACTUAL" ]]; then
            PREV_ROUND_ACTUAL_K=$(awk "BEGIN {printf \"%.1f\", $PREV_ROUND_ACTUAL / 1000}")
        fi

        # Output eval-able variables
        echo "CURRENT_K=${CURRENT_K}"
        echo "CURRENT_PCT=${CURRENT_PCT}"
        echo "AVAILABLE_K=${AVAILABLE_K}"
        echo "PROGRESS_BAR=${PROGRESS_BAR}"
        echo "CONTEXT_STATUS=${CONTEXT_STATUS}"
        echo "CONTEXT_SOURCE=${CONTEXT_SOURCE}"
        echo "STATUSLINE_ACTIVE=${STATUSLINE_ACTIVE}"
        echo "ORCHESTRATOR_GAP_K=${ORCHESTRATOR_GAP_K}"

        # TECH-009: Progressive precision outputs
        echo "NEXT_ESTIMATE_K=${NEXT_ESTIMATE_K}"
        echo "PROJECTED_TOTAL_K=${PROJECTED_TOTAL_K}"
        echo "PROJECTED_PCT=${PROJECTED_PCT}"
        echo "SHOULD_STOP=${SHOULD_STOP}"
        echo "SHOULD_WARN=${SHOULD_WARN}"
        echo "AVG_ACTUAL_K=${AVG_ACTUAL_K}"
        echo "AVG_ESTIMATE_K=${AVG_ESTIMATE_K}"
        echo "OVERHEAD_DELTA_K=${OVERHEAD_DELTA_K}"
        echo "SAMPLE_COUNT=${SAMPLE_COUNT}"

        # Previous round actual (for SKILL.md to update session file)
        if [[ -n "$PREV_ROUND_ACTUAL" ]]; then
            echo "PREV_ROUND_ACTUAL=${PREV_ROUND_ACTUAL}"
            echo "PREV_ROUND_ACTUAL_K=${PREV_ROUND_ACTUAL_K}"
        fi
        echo "PREV_ROUND_SOURCE=${PREV_ROUND_SOURCE}"

        # Legacy outputs (kept for compatibility)
        echo "ESTIMATED_K=${ESTIMATED_K}"
        echo "ESTIMATED_TOTAL_K=${ESTIMATED_TOTAL_K}"
        echo "ESTIMATED_TOTAL_PCT=${PROJECTED_PCT}"
        echo "JSONL_FILE=\"${JSONL_FILE}\""
        [[ "$COMPACT_DETECTED" == "true" ]] && echo "COMPACT_DETECTED=true"
        ;;

    capture)
        SESSION_ID="$2"
        CHECKPOINT="$3"
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        _RESULT=$(get_current_tokens "$jsonlFile")
        TOKENS=${_RESULT%%:*}

        echo "${CHECKPOINT}=${TOKENS}" >> "$CACHE_FILE"
        ;;

    recap)
        SESSION_ID="$2"
        PARTICIPANT_COUNT="$3"
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
        COMPACT_THIS_ROUND=${compactDetected:-false}

        # BUG-017: keep recap sane after /compact. In the v0.5.0 dogfood (exp61)
        # a post-compact round-3 recap reported "statusline returned 0%" and
        # negative round deltas. Root cause: a capture can land 0 when the
        # statusline momentarily reports 0% and the JSONL fallback is unavailable,
        # leaving T3=0; the recap then computes T3-T0 < 0 and a phantom 0%.
        # Recover the end-of-round count from a fresh read, then from the
        # round-start count, so the percentage is never a false 0%.
        _NOW=$(get_current_tokens "$jsonlFile")
        NOW_TOKENS=${_NOW%%:*}
        NOW_TOKENS=${NOW_TOKENS:-0}
        if [[ $T3_TOKENS -le 0 ]]; then
            T3_TOKENS=$NOW_TOKENS
        fi
        if [[ $T3_TOKENS -le 0 ]]; then
            T3_TOKENS=$T0_TOKENS
        fi

        QUESTION_TOKENS=$((T1_TOKENS - T0_TOKENS))
        PARTICIPANTS_TOKENS=$((T2_TOKENS - T1_TOKENS))
        SYNTHESIS_TOKENS=$((T3_TOKENS - T2_TOKENS))
        ROUND_DELTA_TOKENS=$((T3_TOKENS - T0_TOKENS))

        # BUG-017: inconsistent T0..T3 markers (a compact span or a 0 capture)
        # can still drive any phase delta negative. Clamp to 0 and flag the recap
        # as degraded so the display can note it, rather than printing negative
        # token counts. init's compactDetected (BUG-006/012) also degrades the
        # first post-compact round's recap.
        RECAP_DEGRADED=false
        if [[ $QUESTION_TOKENS -lt 0 ]]; then QUESTION_TOKENS=0; RECAP_DEGRADED=true; fi
        if [[ $PARTICIPANTS_TOKENS -lt 0 ]]; then PARTICIPANTS_TOKENS=0; RECAP_DEGRADED=true; fi
        if [[ $SYNTHESIS_TOKENS -lt 0 ]]; then SYNTHESIS_TOKENS=0; RECAP_DEGRADED=true; fi
        if [[ $ROUND_DELTA_TOKENS -lt 0 ]]; then ROUND_DELTA_TOKENS=0; RECAP_DEGRADED=true; fi
        if [[ "$COMPACT_THIS_ROUND" == "true" ]]; then RECAP_DEGRADED=true; fi

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

        # TECH-009: Calculate round estimate (T3 - T0, full round subagents)
        # This is the immediate estimate, will be refined to "actual" next round
        ROUND_TOKENS_ESTIMATE=$((T3_TOKENS - T0_TOKENS))
        ROUND_TOKENS_ESTIMATE_K=$(awk "BEGIN {printf \"%.1f\", $ROUND_TOKENS_ESTIMATE / 1000}")

        # Update cache file with lastT0, lastT3, lastRoundEstimate
        if [[ -f "$CACHE_FILE" ]]; then
            # TECH-009: Save T0 for next round's actual calculation
            sed -i.bak "s/^lastT0=.*/lastT0=${T0_TOKENS}/" "$CACHE_FILE" 2>/dev/null || \
                sed -i '' "s/^lastT0=.*/lastT0=${T0_TOKENS}/" "$CACHE_FILE"
            sed -i.bak "s/^lastT3=.*/lastT3=${T3_TOKENS}/" "$CACHE_FILE" 2>/dev/null || \
                sed -i '' "s/^lastT3=.*/lastT3=${T3_TOKENS}/" "$CACHE_FILE"
            sed -i.bak "s/^lastRoundEstimate=.*/lastRoundEstimate=${ROUND_TOKENS_ESTIMATE}/" "$CACHE_FILE" 2>/dev/null || \
                sed -i '' "s/^lastRoundEstimate=.*/lastRoundEstimate=${ROUND_TOKENS_ESTIMATE}/" "$CACHE_FILE"
            sed -i.bak "s/^roundsDeltaAccum=.*/roundsDeltaAccum=${NEW_ROUNDS_ACCUM}/" "$CACHE_FILE" 2>/dev/null || \
                sed -i '' "s/^roundsDeltaAccum=.*/roundsDeltaAccum=${NEW_ROUNDS_ACCUM}/" "$CACHE_FILE"
            rm -f "${CACHE_FILE}.bak" 2>/dev/null
        fi

        # TECH-009: Output round estimate for session file
        echo "ROUND_TOKENS_ESTIMATE=${ROUND_TOKENS_ESTIMATE}"
        echo "ROUND_TOKENS_ESTIMATE_K=${ROUND_TOKENS_ESTIMATE_K}"

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
        echo "CURRENT_PCT=${CONTEXT_PCT}"  # Alias for display format compatibility
        REMAINING_PCT=$((100 - CONTEXT_PCT))
        REMAINING_K=$(( (CONTEXT_LIMIT - T3_TOKENS) / 1000 ))
        echo "REMAINING_PCT=${REMAINING_PCT}"
        echo "REMAINING_K=${REMAINING_K}"
        echo "CURRENT_K=${ROUND_END_K}"
        echo "CONTEXT_STATUS=${CONTEXT_STATUS}"
        echo "PROGRESS_BAR=${PROGRESS_BAR}"
        echo "ORCHESTRATOR_GAP_K=${ORCH_GAP_K}"
        echo "ROUNDS_ACCUM_K=${ROUNDS_ACCUM_K}"
        echo "CONTEXT_SOURCE=${contextSource:-jsonl}"
        echo "STATUSLINE_ACTIVE=${statuslineActive:-false}"

        # BUG-017: surface the compact/degraded state so the display can note
        # "recap approximate after /compact" instead of trusting the breakdown.
        echo "COMPACT_DETECTED=${COMPACT_THIS_ROUND}"
        echo "RECAP_DEGRADED=${RECAP_DEGRADED}"

        # TECH-009: Calculate AVG_ACTUAL_K and SAMPLE_COUNT from session file
        # These are needed for "Avg per round" display in recap
        ROUND_NUMBER=${round:-1}
        AVG_ACTUAL=0
        SAMPLE_COUNT=0
        SESSION_FILE=".s2s/sessions/${SESSION_ID}.yaml"
        if [[ -f "$SESSION_FILE" && $ROUND_NUMBER -gt 1 ]]; then
            # Extract actuals where source=measured (not interrupted/noisy)
            ACTUALS=$(grep -B2 "source: \"measured\"" "$SESSION_FILE" 2>/dev/null | grep "actual:" | awk '{print $2}' | grep -v "null")
            if [[ -n "$ACTUALS" ]]; then
                SAMPLE_COUNT=$(echo "$ACTUALS" | wc -l | tr -d ' ')
                AVG_ACTUAL=$(echo "$ACTUALS" | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count); else print 0}')
            fi
        fi
        AVG_ACTUAL_K=$(awk "BEGIN {printf \"%.1f\", $AVG_ACTUAL / 1000}")
        echo "AVG_ACTUAL_K=${AVG_ACTUAL_K}"
        echo "SAMPLE_COUNT=${SAMPLE_COUNT}"
        ;;

    summary)
        SESSION_ID="$2"
        CACHE_FILE=$(get_cache_file "$SESSION_ID")

        if [[ -f "$CACHE_FILE" ]]; then
            source "$CACHE_FILE"
        fi

        SESSION_START_TOKENS=${sessionStartTokens:-${startTokens:-0}}
        ROUNDS_TOTAL=${roundsDeltaAccum:-0}

        _RESULT=$(get_current_tokens "$jsonlFile")
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

        # Note: state.json is cleared by SKILL.md inline, not by token-tracker

        REMAINING_PCT=$((100 - CONTEXT_PCT))
        REMAINING_K=$(( (CONTEXT_LIMIT - CURRENT_TOKENS) / 1000 ))

        echo "SESSION_START_K=${SESSION_START_K}"
        echo "SESSION_CONSUMED_K=${SESSION_CONSUMED_K}"
        echo "SESSION_CONSUMED=${SESSION_CONSUMED}"
        echo "ROUNDS_TOTAL_K=${ROUNDS_TOTAL_K}"
        echo "ORCHESTRATOR_ESTIMATED_K=${ORCHESTRATOR_ESTIMATED_K}"
        echo "FINAL_TOTAL_K=${FINAL_TOTAL_K}"
        echo "CONTEXT_PCT=${CONTEXT_PCT}"
        echo "REMAINING_PCT=${REMAINING_PCT}"
        echo "REMAINING_K=${REMAINING_K}"
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

        # Note: state.json is cleared by SKILL.md inline, not by token-tracker
        ;;

    *)
        echo "Usage: $0 {init|capture|recap|summary|cleanup} <session-id> [args...]" >&2
        exit 1
        ;;
esac

# BUG-016: explicit success exit. Without this the script inherits the exit
# status of the last command in the matched branch — e.g. the init branch ends
# with `[[ "$COMPACT_DETECTED" == "true" ]] && echo ...`, which returns 1 when no
# compact occurred, spuriously aborting `eval $(... init ...) && ...` chains.
exit 0
