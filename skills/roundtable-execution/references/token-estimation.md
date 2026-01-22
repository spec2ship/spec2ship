# Token Estimation Instructions

This file contains instructions for token tracking during roundtable execution.
Only read this file when `--tokens` flag is passed.

---

## Script Location (execute ONCE at session start)

**Determine script path before any token tracking.**

The token tracking script is located at:
```
${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/scripts/s2s-round-baseline.sh
```

**Store this path as `S2S_SCRIPT`** for use in all subsequent bash commands.

**Verify the script exists** by running:
```bash
[ -f "<S2S_SCRIPT>" ] && echo "Script found" || echo "Script NOT found"
```
(Replace `<S2S_SCRIPT>` with the actual expanded path)

**IF** script not found:
- Display warning: "Token tracking script not found. Skipping token tracking."
- Skip all token tracking steps below and proceed with roundtable normally.

**IF** script found: Continue with token tracking.

---

## Session Start (before first round)

**Execute this ONCE at the beginning of the roundtable session.**

Run the following bash command:

```bash
eval $(bash "<S2S_SCRIPT>" init "{session-id}" {rounds_completed})
```

Substitute:
- `{session-id}`: Current session ID from session file
- `{rounds_completed}`: Value from `metrics.rounds_completed` (0 for new session)

**Display CONTEXT STATUS box (shows initial state before roundtable starts):**

```
┌─────────────────────────────────────────────────────────────┐
│ CONTEXT STATUS (Initial)                                    │
├─────────────────────────────────────────────────────────────┤
│ Current usage:     {CURRENT_K}k tokens ({CURRENT_PCT}%)     │
│ Available:         ~{AVAILABLE_K}k tokens remaining         │
│ Status:            {PROGRESS_BAR} [{CONTEXT_STATUS}]        │
└─────────────────────────────────────────────────────────────┘
```

**Status indicators:**
- `[OK]` - Under 60% context usage
- `[WARNING]` - 60-80% context usage
- `[CRITICAL]` - Over 80% context usage

---

## Per-Round Init (Step 2.1)

**Execute this at the START of each round (before facilitator question).**

For rounds after the first, re-initialize to get fresh estimate:

```bash
eval $(bash "<S2S_SCRIPT>" init "{session-id}" {rounds_completed})
```

**Display token estimate** (same format as Session Start).

---

## Capture T1 (after facilitator question - Step 2.2)

**Execute IMMEDIATELY after receiving facilitator's question response.**

```bash
bash "<S2S_SCRIPT>" capture T1
```

---

## Capture T2 (after participants - Step 2.3)

**Execute IMMEDIATELY after ALL participant responses are received.**

```bash
bash "<S2S_SCRIPT>" capture T2
```

---

## Capture T3 (after synthesis - Step 2.4)

**Execute IMMEDIATELY after receiving facilitator's synthesis response.**

```bash
bash "<S2S_SCRIPT>" capture T3
```

---

## Round Recap (Step 2.7)

**Execute after T3 capture to display token breakdown.**

Run the following bash command:

```bash
eval $(bash "<S2S_SCRIPT>" recap "{session-id}" {participant_count})
```

Substitute:
- `{session-id}`: Current session ID
- `{participant_count}`: Number of participants in current round

**Display token breakdown:**

```
┌─────────────────────────────────────────────────────────────┐
│ TOKEN BREAKDOWN (Round {round_number})                      │
├─────────────────────────────────────────────────────────────┤
│ Facilitator (question):     {QUESTION_K}k tokens            │
│ Participants ({PARTICIPANT_COUNT} agents): {PARTICIPANTS_K}k tokens ({PARTICIPANT_AVG_K}k avg) │
│ Facilitator (synthesis):    {SYNTHESIS_K}k tokens           │
│ ─────────────────────────────────────────────────────────── │
│ Total round:                {ROUND_DELTA_K}k tokens         │
│ Session total:              {ROUND_END_K}k tokens           │
│ Context usage:              {CONTEXT_PCT}% {PROGRESS_BAR} [{CONTEXT_STATUS}] │
└─────────────────────────────────────────────────────────────┘
```

**Progress bar legend:**
- `#` = used context
- `-` = available context

---

## Session Complete (Step 3.1)

**Execute ONCE when session is closing (before final status update).**

First, get final session summary:

```bash
eval $(bash "<S2S_SCRIPT>" summary)
```

**Display SESSION SUMMARY box:**

```
┌─────────────────────────────────────────────────────────────┐
│ SESSION TOKEN SUMMARY                                       │
├─────────────────────────────────────────────────────────────┤
│ Session consumed:  {SESSION_CONSUMED_K}k tokens             │
│ Final total:       {FINAL_TOTAL_K}k tokens ({CONTEXT_PCT}%) │
│ Context status:    {PROGRESS_BAR} [{CONTEXT_STATUS}]        │
└─────────────────────────────────────────────────────────────┘
```

Then cleanup:

```bash
bash "<S2S_SCRIPT>" cleanup
```

This removes the temporary cache file.

---

## Variables Reference

When following these instructions, substitute:

| Variable | Source |
|----------|--------|
| `<S2S_SCRIPT>` | The expanded path from Script Location section: `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/scripts/s2s-round-baseline.sh` |
| `{session-id}` | Session ID from session file |
| `{rounds_completed}` | `metrics.rounds_completed` from session file |
| `{round_number}` | Current round number (rounds_completed + 1) |
| `{participant_count}` | Length of participants list |
| `CURRENT_K` | From script output (current token usage in thousands) |
| `ESTIMATED_K` | From script output (estimated round tokens in thousands) |
| `ESTIMATED_TOTAL_K` | From script output (estimated total after round) |
| `CURRENT_PCT` | From script output (current usage as percentage of 200k limit) |
| `ESTIMATED_TOTAL_PCT` | From script output (estimated total as percentage) |
| `AVAILABLE_K` | From script output (remaining tokens in thousands) |
| `CONTEXT_STATUS` | From script output (OK, WARNING, or CRITICAL) |
| `QUESTION_K` | From script output (facilitator question tokens) |
| `PARTICIPANTS_K` | From script output (all participants tokens) |
| `PARTICIPANT_AVG_K` | From script output (average per participant) |
| `SYNTHESIS_K` | From script output (facilitator synthesis tokens) |
| `ROUND_DELTA_K` | From script output (total round tokens) |
| `ROUND_END_K` | From script output (session total tokens) |
| `SESSION_CONSUMED_K` | From script output (tokens consumed by this roundtable session) |
| `FINAL_TOTAL_K` | From script output (final context total tokens) |
| `CONTEXT_PCT` | From script output (session total as percentage) |
| `PROGRESS_BAR` | From script output (16-char progress bar: `####------------`) |

---

## How Token Tracking Works

### Data Source

Claude Code stores conversation transcripts in JSONL files at:
```
~/.claude/projects/<encoded-project-path>/<session-id>.jsonl
```

Each assistant message includes a `usage` object with real token counts:
```json
{
  "type": "assistant",
  "message": {
    "usage": {
      "input_tokens": 1234,
      "output_tokens": 567,
      "cache_creation_input_tokens": 890,
      "cache_read_input_tokens": 2345
    }
  },
  "costUSD": 0.01234
}
```

**Context tokens** = `input_tokens` + `cache_creation_input_tokens` + `cache_read_input_tokens`

### Capture Points

```
Round Start (T0)     Per-Round Init
        │
        ▼
   Facilitator Question
        │
        ▼
After Question (T1)   Capture T1
        │
        ▼
   Participant Responses (parallel)
        │
        ▼
After Participants (T2)  Capture T2
        │
        ▼
   Facilitator Synthesis
        │
        ▼
After Synthesis (T3)  Capture T3
        │
        ▼
   Display Breakdown    Round Recap
```

### Calculation

```
Facilitator (question)  = T1 - T0
Participants (all)      = T2 - T1
Facilitator (synthesis) = T3 - T2
─────────────────────────────────
Total round             = T3 - T0
```
