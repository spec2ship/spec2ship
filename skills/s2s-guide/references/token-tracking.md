# Token Tracking

Token tracking monitors context usage during roundtable sessions, providing visibility into consumption by subagents vs orchestrator.

## Overview

When `--tokens` flag is passed to roundtable commands, the system tracks token usage at key checkpoints and displays breakdown information.

## Automatic Setup (v3.1.0+)

Token tracking is **automatically configured** by `/s2s:init`. No manual setup required.

The init command creates:
- `.claude/settings.json` - Statusline configuration
- `.claude/statusline.sh` - Context tracking with state display

### How it works (TECH-007)

All files are **project-local** in `.s2s/` directory:
- **Statusline writes to**: `.s2s/context-window.json`
- **State file**: `.s2s/state.json` (for active session display)
- **Token tracker cache**: `.s2s/sessions/{rt-session-id}.cache`

This enables:
- No session ID complexity
- Project-specific tracking
- Resume suggestions for interrupted sessions
- Accurate tracking that survives `/compact`

### Fallback behavior

If statusline is not configured, token-tracker.sh falls back to JSONL parsing:
- `CONTEXT_SOURCE=statusline` = accurate, project-local
- `CONTEXT_SOURCE=jsonl` = less accurate, may be stale after /compact

## Architecture (v4.1.0)

```
┌─────────────────────────────────────────────────────────────┐
│ Project Directory                                           │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ Statusline      │───▶│ .s2s/context-window.json        ││
│  │ (per-project)   │    │ - session_id                    ││
│  │ .claude/        │    │ - used_percentage               ││
│  │ statusline.sh   │    │ - current_context_tokens        ││
│  │ v3.1.0          │    │ - transcript_path               ││
│  └─────────────────┘    └─────────────────────────────────┘│
│           │                            │                   │
│           │                            │ PRIMARY SOURCE    │
│           ▼                            ▼                   │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ SKILL.md        │───▶│ .s2s/state.json                 ││
│  │ (inline)        │    │ - active_session (for statusline)│
│  │                 │    │ - active_plan                   ││
│  │ Updates state   │    │ - last_activity (for resume)    ││
│  │ at Step 2.1/3.1 │    │                                 ││
│  └─────────────────┘    └─────────────────────────────────┘│
│           │                                               │
│           ▼                                               │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ token-tracker.sh│───▶│ .s2s/sessions/                  ││
│  │ v4.1.0          │    │ {rt-session-id}.cache           ││
│  │                 │    │                                 ││
│  │ Commands:       │    │ Stores:                         ││
│  │ - init          │    │ - sessionStartTokens            ││
│  │ - capture       │    │ - T0, T1, T2, T3 checkpoints    ││
│  │ - recap         │    │ - roundsDeltaAccum              ││
│  │ - summary       │    │ - statuslineActive              ││
│  │ - cleanup       │    │                                 ││
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

## Compact Detection

If `/compact` occurs between rounds, the gap calculation would be negative. Token tracker detects this and:
- Resets orchestrator gap to 0
- Outputs `COMPACT_DETECTED=true`
- UI shows "[compact detected]" note

## Files

| File | Purpose |
|------|---------|
| `roundtable-execution/scripts/token-tracker.sh` | Bash script for tracking (v4.1.0) |
| `roundtable-execution/references/token-tracking.md` | Operational instructions |
| `roundtable-execution/SKILL.md` | State management inline (v2.1.0) |
| `templates/statusline/statusline.sh` | Statusline template (v3.1.0) |
| `.s2s/context-window.json` | Context data (project-local) |
| `.s2s/state.json` | Active session state (project-local) |
| `.s2s/sessions/{rt-session-id}.cache` | Session tracking cache (project-local) |

## Known Limitations

- **One session per project**: Multiple Claude Code sessions on the same project will interfere (last writer wins). This is an acceptable trade-off for simplicity.
