# Token Tracking

Token tracking monitors context usage during roundtable sessions, providing visibility into consumption by subagents vs orchestrator.

## Overview

When `--tokens` flag is passed to roundtable commands, the system tracks token usage at key checkpoints and displays breakdown information.

## Automatic Setup (v3.0.0+)

Token tracking is **automatically configured** by `/s2s:init`. No manual setup required.

The init command creates:
- `.claude/settings.json` - Statusline configuration
- `.claude/statusline-command.sh` - Session-isolated context tracking

### How it works

Each Claude Code session gets its own context file in temp directory:
- **Statusline writes to**: `$TMPDIR/s2s-context-window-{cc-session-id}.json`
- **Token tracker cache**: `.s2s/sessions/{rt-session-id}.cache`

This enables:
- Parallel sessions without interference
- No stale data from other sessions
- Accurate tracking that survives `/compact`

### Fallback behavior

If statusline is not configured, token-tracker.sh falls back to JSONL parsing:
- `CONTEXT_SOURCE=statusline` = accurate, session-isolated
- `CONTEXT_SOURCE=jsonl` = less accurate, may be stale after /compact

## Architecture (v3.0.0)

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Session (CC-SESSION-ID)                         │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ Statusline      │───▶│ $TMPDIR/s2s-context-window-     ││
│  │ (per-project)   │    │ {CC-SESSION-ID}.json            ││
│  │ .claude/        │    │ - session_id (for validation)   ││
│  │ statusline-     │    │ - used_percentage               ││
│  │ command.sh      │    │ - total_input_tokens            ││
│  └─────────────────┘    └─────────────────────────────────┘│
│           │                            │                   │
│           │                            │ PRIMARY SOURCE    │
│           ▼                            ▼                   │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ token-tracker.sh│───▶│ .s2s/sessions/                  ││
│  │ v3.0.0          │    │ {rt-session-id}.cache           ││
│  │                 │    │                                 ││
│  │ Commands:       │    │ Stores:                         ││
│  │ - init          │    │ - sessionStartTokens            ││
│  │ - capture       │    │ - T0, T1, T2, T3 checkpoints    ││
│  │ - recap         │    │ - roundsDeltaAccum              ││
│  │ - summary       │    │ - ccSessionId                   ││
│  │ - cleanup       │    │ - statuslineActive              ││
│  └─────────────────┘    └─────────────────────────────────┘│
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

## Display Conventions

- Values without prefix = measured directly from checkpoints
- Values with `~` prefix = estimated/derived
- Progress bar: `#` = used, `-` = available
- Status: OK (<60%), WARNING (60-80%), CRITICAL (>80%)
- `[statusline]` or `[jsonl]` = data source indicator

## Compact Detection (v3.0.0)

If `/compact` occurs between rounds, the gap calculation would be negative. Token tracker detects this and:
- Resets orchestrator gap to 0
- Outputs `COMPACT_DETECTED=true`
- UI shows "[compact detected]" note

## Files

| File | Purpose |
|------|---------|
| `roundtable-execution/scripts/token-tracker.sh` | Bash script for tracking (v3.0.0) |
| `roundtable-execution/references/token-tracking.md` | Operational instructions |
| `templates/statusline/statusline-command.sh` | Statusline template (v2.0.0) |
| `$TMPDIR/s2s-context-window-{cc-session-id}.json` | Session-specific context (temp) |
| `.s2s/sessions/{rt-session-id}.cache` | Session tracking cache (project-local) |
