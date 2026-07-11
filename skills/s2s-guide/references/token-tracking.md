# Token Tracking

Token tracking monitors context usage during roundtable sessions, providing visibility into consumption by subagents vs orchestrator.

## Overview

Token tracking is **always active** (v2.3.0+) during roundtable sessions. The system tracks token usage at key checkpoints and displays breakdown information automatically.

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

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Project Directory                                           │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ Statusline      │───▶│ .s2s/context-window.json        ││
│  │ (per-project)   │    │ - session_id                    ││
│  │ .claude/        │    │ - used_percentage               ││
│  │ statusline.sh   │    │ - current_context_tokens        ││
│  │                 │    │ - transcript_path               ││
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
│  │                 │    │ {rt-session-id}.cache           ││
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

**Derived values** (calculated, not directly measured):
- Orchestrator gap = T0(next) - T3(previous)
- Orchestrator total = Session consumed - Sum(round subagents)

## Progressive Precision (TECH-009, since v5.3.0)

Token tracking uses **progressive precision** to measure per-round consumption:

| Metric | Calculation | When Available | Precision |
|--------|-------------|----------------|-----------|
| `estimate` | T3 - T0 | End of round N | Immediate |
| `actual` | T0_{n+1} - T0_n | Start of round N+1 | Precise |

**Source values**:
- `measured`: actual calculated with continuity
- `estimated`: only estimate available (last round)
- `interrupted`: /compact or /clear detected
- `noisy`: actual >> estimate (user did other commands)

## Display Format

Token information is displayed at the end of each round recap (not in separate boxes):

```
───────────────────────────────────────────────────────────────
Tokens:
  Facilitator question:      2k
  Participants (4):          8k  (2k avg)
  Facilitator synthesis:     2k
  Round subtotal:           12k

  Avg per round:            12k  (3 rounds)
  Roundtable total:         36k

  Context consumed:         86k (43%)
  Context remaining:       114k (57%)
───────────────────────────────────────────────────────────────
```

For round 1, "Avg per round" is omitted (only 1 sample).

Warning displayed when context >= 85%:
```
  ⚠️  Low context - consider /compact after this round
```

## Auto-Stop Thresholds

| Condition | Action |
|-----------|--------|
| Projected ≥95% | **STOP** - pause session, suggest /compact |
| Projected 85-95% | **WARNING** - display warning, continue |
| Projected <85% | **OK** - proceed normally |

## Compact Detection

If `/compact` occurs between rounds, the gap calculation would be negative. Token tracker detects this and:
- Resets orchestrator gap to 0
- Outputs `COMPACT_DETECTED=true`
- UI shows "[compact detected]" note

## Files

| File | Purpose |
|------|---------|
| `roundtable-execution/scripts/token-tracker.sh` | Bash script for tracking (version in script header) |
| `roundtable-execution/references/token-tracking.md` | Operational instructions |
| `roundtable-execution/SKILL.md` | State management inline |
| `templates/statusline/statusline.sh` | Statusline template (version in script header) |
| `.s2s/context-window.json` | Context data (project-local) |
| `.s2s/state.json` | Active session state (project-local) |
| `.s2s/sessions/{rt-session-id}.cache` | Session tracking cache (project-local) |

## Known Limitations

- **One session per project**: Multiple Claude Code sessions on the same project will interfere (last writer wins). This is an acceptable trade-off for simplicity.
