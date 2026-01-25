# Token Tracking Instructions

Token tracking is always active during roundtable sessions. This file is read at Step 2.0 (context check) and Step 2.1 (round start) of each round.

---

## Script Location (execute ONCE at Step 2.0 of first round)

Script path:
```
${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/scripts/token-tracker.sh
```

Store as `TOKEN_SCRIPT`. Verify exists:
```bash
[ -f "<TOKEN_SCRIPT>" ] && echo "Script found" || echo "Script NOT found"
```

If not found: skip all token tracking, proceed normally.

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

**Check ESTIMATED_TOTAL_PCT from output**:

| Condition | Action |
|-----------|--------|
| `ESTIMATED_TOTAL_PCT >= 95` | **STOP** - display pause message with /compact instructions |
| `ESTIMATED_TOTAL_PCT >= 85` | **WARNING** - display warning but continue |
| `ESTIMATED_TOTAL_PCT < 85` | **OK** - proceed normally |

**On STOP** - display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  CONTEXT CAPACITY INSUFFICIENT FOR NEXT ROUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current:     {CURRENT_K}k tokens ({CURRENT_PCT}%)
Estimated:   +{ESTIMATED_K}k for next round
Projected:   {ESTIMATED_TOTAL_K}k ({ESTIMATED_TOTAL_PCT}%) ← exceeds 95%

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
⚠️  Context at {CURRENT_PCT}% - estimated {ESTIMATED_TOTAL_PCT}% after this round
    Consider /compact after this round completes
```

---

## Per-Round Display (Step 2.1)

> Note: `token-tracker init` was already executed in Step 2.0.
> Use those results to display the context status box.

**Print this box to the user** (for round > 1, include orchestrator gap if > 0):
```
┌─────────────────────────────────────────────────────────────┐
│ CONTEXT STATUS (Round {round_number} Start)   [{CONTEXT_SOURCE}] │
├─────────────────────────────────────────────────────────────┤
│ Current usage:     {CURRENT_K}k tokens ({CURRENT_PCT}%)     │
│ ~Orchestrator:     ~{ORCHESTRATOR_GAP_K}k (since last round)│
│ Available:         ~{AVAILABLE_K}k tokens remaining         │
│ Status:            {PROGRESS_BAR} [{CONTEXT_STATUS}]        │
{if COMPACT_DETECTED}
│ Note:              /compact detected - gap reset            │
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
│ ─────────────────────────────────────────────────────────── │
│ Rounds total (accum):       {ROUNDS_ACCUM_K}k tokens        │
│ Context total:              {ROUND_END_K}k tokens           │
│ Context usage:              {CONTEXT_PCT}% {PROGRESS_BAR} [{CONTEXT_STATUS}] │
└─────────────────────────────────────────────────────────────┘
```

`~` prefix = estimated value.

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
