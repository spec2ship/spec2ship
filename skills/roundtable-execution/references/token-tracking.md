# Token Tracking Instructions

Token tracking is always active during roundtable sessions. This file is read at Step 2.0 (context check) and Step 2.1 (round start) of each round.

---

## Progressive Precision Model (TECH-009)

Token tracking uses **progressive precision** to accurately measure per-round consumption:

| Metric | Calculation | When Available | Precision |
|--------|-------------|----------------|-----------|
| `estimate` | T3 - T1 (subagent-only) | End of round N | Underestimates (~) |
| `actual` | T1_{n+1} - T1_n (includes orchestrator) | Start of round N+1 | Precise |

**Source values**:
- `measured`: actual calculated with continuity (precise)
- `estimated`: only estimate available (last round or first round)
- `interrupted`: /compact or /clear detected (cannot calculate actual)
- `noisy`: actual >> estimate, user likely did other commands between rounds

**Statistics** (calculated from measured rounds):
- `avg_actual`: average of actual values (best for projection)
- `overhead_delta`: avg(actual - estimate) = typical orchestrator overhead
- `sample_count`: how many rounds have valid actual measurements

---

## Script Location (execute ONCE at Step 2.0 of first round)

**Use the Read tool** to get the resolved script path:

```
Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/scripts/token-tracker.sh`
```

The Read tool response shows the actual resolved path in its header (e.g., `File: /path/to/.../token-tracker.sh`).

**Extract that full path** and store it as `TOKEN_SCRIPT`.

If Read fails (file not found): skip all token tracking, proceed normally.

---

## File Locations (TECH-007)

All files are project-local in `.s2s/`:
- **Context window**: `.s2s/context-window.json` (written by statusline ~300ms)
- **State file**: `.s2s/state.json` (active_session for statusline display)
- **Token cache**: `.s2s/sessions/{session-id}.cache`

No session ID needed in filenames - one state per project.

---

## Session Start (before first round)

```bash
eval $(bash "<TOKEN_SCRIPT>" init "{session-id}" {rounds_completed} "{workflow_type}" "{strategy}" "{phase}" {participants_count})
```

**Parameters**:
- `workflow_type`: specs | design | brainstorm | roundtable
- `strategy`: standard | consensus-driven | debate | disney | six-hats
- `phase`: current phase (e.g., "discussion", "dreamer", "opening")
- `participants_count`: number of participants

These are used to update `.s2s/state.json` for statusline display.

**Print this box to the user** (substitute variables from eval):
```
┌─────────────────────────────────────────────────────────────┐
│ CONTEXT STATUS (Initial)                      [{CONTEXT_SOURCE}] │
├─────────────────────────────────────────────────────────────┤
│ Current usage:     {CURRENT_K}k tokens ({CURRENT_PCT}%)     │
│ Available:         ~{AVAILABLE_K}k tokens remaining         │
│ Statusline:        {STATUSLINE_ACTIVE ? "active" : "not configured (using jsonl fallback)"} │
│ Status:            {PROGRESS_BAR} [{CONTEXT_STATUS}]        │
└─────────────────────────────────────────────────────────────┘
```

---

## Context Capacity Check (Step 2.0)

> **Purpose**: Before starting each round, verify there's enough context capacity.
> If projected usage exceeds 95%, stop and guide user to /compact or /clear.

```bash
eval $(bash "<TOKEN_SCRIPT>" init "{session-id}" {rounds_completed} "{workflow_type}" "{strategy}" "{phase}" {participants_count})
```

**Check SHOULD_STOP and SHOULD_WARN from output** (TECH-009):

| Variable | Action |
|----------|--------|
| `SHOULD_STOP=true` | **STOP** - display pause message with /compact instructions |
| `SHOULD_WARN=true` | **WARNING** - display warning but continue |
| Both false | **OK** - proceed normally |

**TECH-009: Update previous round's actual** (if PREV_ROUND_ACTUAL is set):

The script outputs `PREV_ROUND_ACTUAL` and `PREV_ROUND_SOURCE` when it can calculate
the precise token consumption for the previous round. SKILL.md should update the
session file's `metrics.tokens.by_round[N-1]` with these values.

**On STOP** - display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  CONTEXT CAPACITY INSUFFICIENT FOR NEXT ROUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current:     {CURRENT_K}k tokens ({CURRENT_PCT}%)
Next round:  ~{NEXT_ESTIMATE_K}k (based on {SAMPLE_COUNT} samples)
Projected:   {PROJECTED_TOTAL_K}k ({PROJECTED_PCT}%) ← exceeds 95%

Option 1 - Compact (preserves some context):
  /compact Keep s2s roundtable session {session-id}, agenda, artifacts

  Then: /s2s:{workflow_type} --session {session-id}

Option 2 - Clear (fresh start):
  /clear

  Then: /s2s:{workflow_type} --session {session-id}

Session saved at round {round_number}. Progress preserved.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**On WARNING** - display inline with round start:
```
⚠️  Context at {CURRENT_PCT}% - projected {PROJECTED_PCT}% after this round
    Consider /compact after this round completes
```

---

## Per-Round Display (Step 2.1)

> Note: `token-tracker init` was already executed in Step 2.0.
> Use those results to display the context status box.

**Print this box to the user** (for round > 1, include previous round actual if available):
```
┌─────────────────────────────────────────────────────────────┐
│ CONTEXT STATUS (Round {round_number} Start)   [{CONTEXT_SOURCE}] │
├─────────────────────────────────────────────────────────────┤
│ Current usage:     {CURRENT_K}k tokens ({CURRENT_PCT}%)     │
{if round > 1 and PREV_ROUND_ACTUAL_K}
│ Previous round:    {PREV_ROUND_ACTUAL_K}k actual [{PREV_ROUND_SOURCE}] │
{/if}
│ Avg per round:     {AVG_ACTUAL_K}k ({SAMPLE_COUNT} samples) │
│ Next estimate:     ~{NEXT_ESTIMATE_K}k                      │
│ Projected:         {PROJECTED_TOTAL_K}k ({PROJECTED_PCT}%)  │
│ Status:            {PROGRESS_BAR} [{CONTEXT_STATUS}]        │
{if COMPACT_DETECTED}
│ Note:              /compact detected - previous round interrupted │
{/if}
└─────────────────────────────────────────────────────────────┘
```

---

## Capture T1 (after facilitator question - Step 2.2)

```bash
bash "<TOKEN_SCRIPT>" capture "{session-id}" T1
```

---

## Capture T2 (after participants - Step 2.3)

```bash
bash "<TOKEN_SCRIPT>" capture "{session-id}" T2
```

---

## Capture T3 (after synthesis - Step 2.4)

```bash
bash "<TOKEN_SCRIPT>" capture "{session-id}" T3
```

---

## Round Recap (Step 2.7)

```bash
eval $(bash "<TOKEN_SCRIPT>" recap "{session-id}" {participant_count})
```

**Print this box to the user** (substitute variables from eval):
```
┌─────────────────────────────────────────────────────────────┐
│ TOKEN BREAKDOWN (Round {round_number})        [{CONTEXT_SOURCE}] │
├─────────────────────────────────────────────────────────────┤
│ Facilitator (question):     {QUESTION_K}k tokens            │
│ Participants ({PARTICIPANT_COUNT}): {PARTICIPANTS_K}k tokens ({PARTICIPANT_AVG_K}k avg) │
│ Facilitator (synthesis):    {SYNTHESIS_K}k tokens           │
│ ─────────────────────────────────────────────────────────── │
│ Round subagents:            {ROUND_DELTA_K}k tokens         │
│ ~Orchestrator gap:          ~{ORCHESTRATOR_GAP_K}k tokens   │
│ Round estimate:             ~{ROUND_TOKENS_ESTIMATE_K}k (will refine next round) │
│ ─────────────────────────────────────────────────────────── │
│ Rounds total (accum):       {ROUNDS_ACCUM_K}k tokens        │
│ Context total:              {ROUND_END_K}k tokens           │
│ Context usage:              {CONTEXT_PCT}% {PROGRESS_BAR} [{CONTEXT_STATUS}] │
└─────────────────────────────────────────────────────────────┘
```

`~` prefix = estimated value.

**TECH-009: Save estimate to session file**:

After displaying the recap, SKILL.md should save `ROUND_TOKENS_ESTIMATE` to the session file:
```yaml
metrics:
  tokens:
    by_round:
      - round: {round_number}
        estimate: {ROUND_TOKENS_ESTIMATE}
        actual: null
        source: "estimated"
```

---

## Session Complete (Step 3.1)

```bash
eval $(bash "<TOKEN_SCRIPT>" summary "{session-id}")
```

**Print this box to the user** (substitute variables from eval):
```
┌─────────────────────────────────────────────────────────────┐
│ SESSION TOKEN SUMMARY                         [{CONTEXT_SOURCE}] │
├─────────────────────────────────────────────────────────────┤
│ Session start:     {SESSION_START_K}k tokens                │
│ Session consumed:  {SESSION_CONSUMED_K}k tokens             │
│   ├─ Subagents:    {ROUNDS_TOTAL_K}k tokens (measured)      │
│   └─ ~Orchestrator: ~{ORCHESTRATOR_ESTIMATED_K}k (estimated)│
│ ─────────────────────────────────────────────────────────── │
│ Final total:       {FINAL_TOTAL_K}k tokens ({CONTEXT_PCT}%) │
│ Context status:    {PROGRESS_BAR} [{CONTEXT_STATUS}]        │
└─────────────────────────────────────────────────────────────┘
```

Cleanup (cache file is in project, kept for debugging):
```bash
# Optional: bash "<TOKEN_SCRIPT>" cleanup "{session-id}"
# Cache file: .s2s/sessions/{session-id}.cache
# Also clears: .s2s/state.json active_session
```
