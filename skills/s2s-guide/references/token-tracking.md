# Token Tracking

Token tracking monitors context usage during roundtable sessions, providing visibility into consumption by subagents vs orchestrator.

## Overview

When `--tokens` flag is passed to roundtable commands, the system tracks token usage at key checkpoints and displays breakdown information.

## Setup Required (one-time)

Token tracking v2.1+ uses Claude Code's statusline feature for accurate context measurement. This survives `/compact` operations and provides reliable data.

### Why statusline?

| Source | Accuracy | Survives /compact | Notes |
|--------|----------|-------------------|-------|
| JSONL file | Approximate | No | May report stale data after /compact |
| Statusline | Accurate | Yes | Directly from Claude Code |

### Installation steps

#### Linux / macOS

1. **Create statusline script** at `~/.claude/statusline-command.sh`:

```bash
#!/bin/bash
INPUT=$(cat)

# Save context_window data for s2s token tracker
echo "$INPUT" | jq -r '.context_window // empty' > ~/.claude/cache/context-window.json 2>/dev/null

# Your existing statusline output (optional)
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
echo "$MODEL"
```

2. **Enable statusline** in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  }
}
```

#### Windows

On Windows, Claude Code doesn't execute `.sh` scripts via bash. Use PowerShell instead.

1. **Create statusline script** at `~/.claude/statusline-command.ps1`:

```powershell
$input_data = $input | Out-String
$json = $input_data | ConvertFrom-Json -ErrorAction SilentlyContinue

if ($json.context_window) {
    $json.context_window | ConvertTo-Json -Compress | Out-File -FilePath "$env:USERPROFILE\.claude\cache\context-window.json" -Encoding UTF8 -NoNewline
}

if ($json.model.display_name) {
    Write-Output $json.model.display_name
} else {
    Write-Output "Claude"
}
```

2. **Enable statusline** in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -ExecutionPolicy Bypass -File C:/Users/YOUR_USERNAME/.claude/statusline-command.ps1"
  }
}
```

**Note:** Replace `YOUR_USERNAME` with your actual Windows username.

#### Verify installation

Run any Claude Code command and check:
```bash
cat ~/.claude/cache/context-window.json
```

Should show context_window data with `total_input_tokens`, `used_percentage`, etc.

### Fallback behavior

If statusline is not configured (file doesn't exist or contains invalid JSON), token-tracker.sh falls back to JSONL parsing. The output will show `CONTEXT_SOURCE=jsonl` (less accurate, may be stale after /compact) instead of `CONTEXT_SOURCE=statusline` (accurate).

**Anti-pattern: file age check**. Do NOT add "freshness" checks based on file age. Claude Code updates the file after each response, so at session start the file may be minutes/hours old but still valid. Delta calculations (T1-T0, T2-T1) are accurate regardless of initial file age.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Session                                         │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ Statusline      │───▶│ context-window.json             ││
│  │ (after each     │    │ ~/.claude/cache/                ││
│  │  response)      │    │ - used_percentage               ││
│  └─────────────────┘    │ - total_input_tokens            ││
│                         │ - total_output_tokens           ││
│                         └─────────────────────────────────┘│
│           │                            │                   │
│           │                            │ PRIMARY SOURCE    │
│           ▼                            ▼                   │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ token-tracker.sh│───▶│ Cache File (per session)        ││
│  │                 │    │ ~/.claude/cache/s2s-token-      ││
│  │ Commands:       │    │ tracker-{session-id}.txt        ││
│  │ - init          │    │                                 ││
│  │ - capture       │    │ Stores:                         ││
│  │ - recap         │    │ - sessionStartTokens            ││
│  │ - summary       │    │ - T0, T1, T2, T3 checkpoints    ││
│  │ - cleanup       │    │ - roundsDeltaAccum              ││
│  └─────────────────┘    │ - contextSource                 ││
│           │             └─────────────────────────────────┘│
│           │                            │                   │
│           │                            │ FALLBACK          │
│           ▼                            ▼                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ JSONL File (fallback if statusline unavailable)        ││
│  │ ~/.claude/projects/.../xxx.jsonl                       ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Per Round

```
T0 (init)
│   Orchestrator prepares facilitator input
▼
T1 (capture)
│   Facilitator question task completes
│   Orchestrator prepares participant inputs
▼
T2 (capture)
│   All participant tasks complete
│   Orchestrator prepares synthesis input
▼
T3 (capture)
│   Facilitator synthesis task completes
│   Orchestrator updates files, displays recap
▼
Gap (between rounds)
│   Orchestrator prepares next round
▼
T0 (next round init)
```

### Calculations

**Measured values** (from statusline or JSONL):
- Facilitator question = T1 - T0
- Participants = T2 - T1
- Facilitator synthesis = T3 - T2
- Round subagents = T3 - T0
- Session consumed = Final - sessionStartTokens

**Estimated values** (derived, shown with `~` prefix):
- Orchestrator gap = T0(next) - T3(previous)
- Orchestrator total = Session consumed - Sum(round subagents)

## Data Sources

### Statusline (preferred)

The statusline script receives JSON with `context_window` object:

```json
{
  "context_window": {
    "total_input_tokens": 75702,
    "total_output_tokens": 108338,
    "context_window_size": 200000,
    "used_percentage": 68,
    "remaining_percentage": 32
  }
}
```

### JSONL (fallback)

If statusline unavailable, tokens are read from JSONL usage object:

```json
{
  "usage": {
    "input_tokens": 1234,
    "output_tokens": 567,
    "cache_creation_input_tokens": 890,
    "cache_read_input_tokens": 2345
  }
}
```

**Note**: JSONL data may be stale after `/compact` operations.

## Cache File Structure

```
sessionId=20260122-roundtable-test
sessionStartTokens=46000          # Preserved across all rounds
round=2
startTokens=56000                 # T0 for current round
startCost=0
jsonlFile=/path/to/session.jsonl
contextSource=statusline          # Data source indicator
timestamp=2026-01-22T17:45:00Z
lastT3=52000                      # For gap calculation
roundsDeltaAccum=4200             # Sum of all round deltas
orchestratorGapThisRound=4000     # Gap before this round
T1=57000
T2=59000
T3=61000
```

## Session-Level Tracking

The key fix in v2.0 is preserving `sessionStartTokens` across all rounds:

```
Round 0 init: sessionStartTokens = 46k (saved, never overwritten)
Round 1 init: sessionStartTokens = 46k (preserved from cache)
Round 2 init: sessionStartTokens = 46k (preserved from cache)
Summary:      uses sessionStartTokens = 46k (correct baseline)
```

## Display Conventions

- Values without prefix = measured directly from checkpoints
- Values with `~` prefix = estimated/derived
- Progress bar: `#` = used, `-` = available
- Status: OK (<60%), WARNING (60-80%), CRITICAL (>80%)
- `[statusline]` or `[jsonl]` = data source indicator

## Parallel Session Support

Version 2.2.0 adds session isolation for parallel execution:

- Each roundtable session uses its own cache file: `s2s-token-tracker-{session-id}.txt`
- Multiple roundtables can run in different terminals without interference
- The `context-window.json` file is shared but read timing minimizes collision risk

## Files

| File | Purpose |
|------|---------|
| `roundtable-execution/scripts/token-tracker.sh` | Bash script for tracking |
| `roundtable-execution/references/token-tracking.md` | Operational instructions |
| `s2s-guide/references/token-tracking.md` | This documentation |
| `~/.claude/cache/context-window.json` | Statusline context data (shared) |
| `~/.claude/cache/s2s-token-tracker-{session-id}.txt` | Session tracking cache (per-session) |
