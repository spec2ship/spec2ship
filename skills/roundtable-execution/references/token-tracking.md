# Token Tracking Instructions

Token tracking is always active during roundtable sessions. This file is read at Step 2.0 (context check) and Step 2.7 (round recap) of each round.

---

## Progressive Precision Model (TECH-009)

Token tracking uses **progressive precision** to accurately measure per-round consumption:

| Metric | Calculation | When Available | Precision |
|--------|-------------|----------------|-----------|
| `estimate` | T3 - T0 (full round subagents) | End of round N | Immediate |
| `actual` | T0_{n+1} - T0_n (includes orchestrator) | Start of round N+1 | Precise |

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

## Script Location (resolve at the START of EVERY round)

**At the start of EVERY round — unconditionally**, use the Read tool to (re-)resolve the script path:

```
Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/scripts/token-tracker.sh`
```

The Read tool response shows the actual resolved path in its header (e.g., `File: /path/to/.../token-tracker.sh`).

**Extract that full path** and store it as `TOKEN_SCRIPT`.

Do NOT assume `TOKEN_SCRIPT` is still set from a previous round. After `/compact` or `/clear` (or a fresh resume in a new Claude session) the LLM context is rebuilt and any earlier `TOKEN_SCRIPT` value is gone — even though the model may "recall" having resolved it. Re-running the Read is cheap; a silently-lost `TOKEN_SCRIPT` disables token tracking, so `SHOULD_STOP` is never evaluated and the round loop runs past context capacity (BUG-012). When in doubt, resolve again.

If Read fails (file not found): skip all token tracking, proceed normally.

---

## File Locations (TECH-007)

All files are project-local in `.s2s/`:
- **Context window**: `.s2s/context-window.json` (written by statusline ~300ms)
- **State file**: `.s2s/state.json` (active_session for statusline display)
- **Token cache**: `.s2s/sessions/{session-id}.cache`

No session ID needed in filenames - one state per project.

---

## Context Capacity Check (Step 2.0) - runs EVERY round

> **Purpose**: Before starting each round, verify there's enough context capacity.
> If projected usage exceeds 95%, stop and guide user to /compact or /clear.

**Execute at EVERY round** (including first and resume):

```bash
eval $(bash "<TOKEN_SCRIPT>" init "{session-id}" {rounds_completed})
```

**Parameters**:
- `session-id`: current session ID
- `rounds_completed`: from session file's `metrics.rounds_completed`

> **Note (BUG-018)**: `init` no longer takes workflow-type/strategy/phase/participants-count.
> Those were write-only cache fields nobody read. The statusline's roundtable info
> (`workflow:strategy R{n}`) is driven by `state.json`, which `phase-2-core.md §2.1b`
> rewrites every round from the on-disk profile/config — so it survives `/compact` + resume
> regardless of this cache. Extra positional args are still accepted (ignored) for back-compat.

**Check SHOULD_STOP and SHOULD_WARN from output** (TECH-009):

| Variable | Action |
|----------|--------|
| `SHOULD_STOP=true` | **STOP** - display pause message with /compact instructions |
| `SHOULD_WARN=true` | **WARNING** - display warning but continue |
| Both false | **OK** - proceed normally |

**TECH-009: Update previous round's actual** (MANDATORY if PREV_ROUND_ACTUAL is set):

The script outputs `PREV_ROUND_ACTUAL` and `PREV_ROUND_SOURCE` when it can calculate
the precise token consumption for the previous round.

> **WARNING**: Skipping this step causes `actual: null` in session file and breaks avg calculations!

**YOU MUST IMMEDIATELY** use Edit tool to update `.s2s/sessions/{session-id}.yaml`:

Find the entry in `metrics.tokens.by_round` where `round: {rounds_completed - 1}` and update:

```yaml
metrics:
  tokens:
    by_round:
      - round: {rounds_completed - 1}
        estimate: {keep existing value}
        actual: {PREV_ROUND_ACTUAL}      # ← update from null
        source: "{PREV_ROUND_SOURCE}"    # ← update from "estimated"
```

**Verify** the edit was applied before proceeding to the next step.

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

## Capture T1 (after facilitator question - Step 2.2) - MANDATORY

> **Do not skip!** Required for breakdown display (Facilitator question, Participants, Synthesis).

```bash
bash "<TOKEN_SCRIPT>" capture "{session-id}" T1
```

---

## Capture T2 (after participants - Step 2.3) - MANDATORY

> **Do not skip!** Required for breakdown display.

```bash
bash "<TOKEN_SCRIPT>" capture "{session-id}" T2
```

---

## Capture T3 (after synthesis - Step 2.4) - MANDATORY

> **Do not skip!** Required for breakdown display and round estimate.

```bash
bash "<TOKEN_SCRIPT>" capture "{session-id}" T3
```

---

## Round Recap (Step 2.7)

```bash
eval $(bash "<TOKEN_SCRIPT>" recap "{session-id}" {participant_count})
```

**Add token section at the end of the round recap display** (integrated, not separate box):

```
───────────────────────────────────────────────────────────────
Tokens:
  Facilitator question:      {QUESTION_K}k
  Participants ({count}):    {PARTICIPANTS_K}k  ({PARTICIPANT_AVG_K}k avg)
  Facilitator synthesis:     {SYNTHESIS_K}k
  Round subtotal:           {ROUND_DELTA_K}k
{if RECAP_DEGRADED}
  ⚠️  breakdown approximate — context was compacted/reset this round (BUG-017)
{/if}

{if round_number > 0}
  Avg per round:            {AVG_ACTUAL_K}k  ({SAMPLE_COUNT + 1} rounds)
{/if}
  Roundtable total:         {ROUNDS_ACCUM_K}k

  Context consumed:         {CURRENT_K}k ({CURRENT_PCT}%)
  Context remaining:        {REMAINING_K}k ({REMAINING_PCT}%)
{if SHOULD_WARN}

  ⚠️  Low context - consider /compact after this round
{/if}
───────────────────────────────────────────────────────────────
```

**Values from script output**:
- `QUESTION_K`, `PARTICIPANTS_K`, `SYNTHESIS_K`: breakdown per actor
- `ROUND_DELTA_K`: round subtotal (T3 - T0)
- `ROUNDS_ACCUM_K`: roundtable total (accumulated)
- `CURRENT_K`, `CURRENT_PCT`: context consumed
- `REMAINING_K`, `REMAINING_PCT`: context remaining — computed against the model's actual window (1M for Opus/Sonnet, 200K for Haiku), not a fixed 200k (BUG-019)
- `AVG_ACTUAL_K`, `SAMPLE_COUNT`: for rounds > 1
- `RECAP_DEGRADED`, `COMPACT_DETECTED`: `true` when `/compact` or a 0-token capture made this round's breakdown unreliable — display the approximate-breakdown note above (BUG-017)

**TECH-009: Save estimate to session file**:

After displaying the recap, **YOU MUST** use Edit tool to append to `.s2s/sessions/{session-id}.yaml`:

```yaml
metrics:
  tokens:
    by_round:
      - round: {round_number}
        estimate: {ROUND_TOKENS_ESTIMATE}  # value WITHOUT "k" suffix
        actual: null
        source: "estimated"
```

If `by_round` doesn't exist yet, create it as an empty array first.

---

## Session Complete (Step 3.1)

```bash
eval $(bash "<TOKEN_SCRIPT>" summary "{session-id}")
```

**Add session summary to completion display**:

```
───────────────────────────────────────────────────────────────
Session Tokens:
  Roundtable total:         {ROUNDS_TOTAL_K}k  (subagents)
  Orchestrator overhead:    {ORCHESTRATOR_ESTIMATED_K}k  (estimated)
  Session consumed:         {SESSION_CONSUMED_K}k

  Context consumed:         {FINAL_TOTAL_K}k ({CONTEXT_PCT}%)
  Context remaining:        {REMAINING_K}k ({REMAINING_PCT}%)
───────────────────────────────────────────────────────────────
```

**Update session file with total** (TECH-009):

**YOU MUST** use Edit tool to update `.s2s/sessions/{session-id}.yaml`:

```yaml
metrics:
  tokens:
    total: {SESSION_CONSUMED}  # ← update from 0 (value WITHOUT "k" suffix)
    by_round: [...]            # keep existing
```

Cleanup (cache file is in project, kept for debugging):
```bash
# Optional: bash "<TOKEN_SCRIPT>" cleanup "{session-id}"
# Cache file: .s2s/sessions/{session-id}.cache
# Also clears: .s2s/state.json active_session
```
