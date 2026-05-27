---
description: Creative brainstorming session using the Disney strategy (Dreamer → Realist → Critic). Use for ideation and exploring new ideas without constraints. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy disney|six-hats|standard] [--participants <list>] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
skills: roundtable-execution, roundtable-strategies
---

# Brainstorm Session

`/s2s:brainstorm` is a **thin launcher** for the `brainstorm` workflow (TECH-002 Phase 8).
It runs minimal brainstorm-specific preparation, then delegates to the `roundtable.md`
master, which owns auto-detect, session setup, the Phase 2 round loop, and output
generation. Brainstorm uses the **Disney strategy** (Dreamer → Realist → Critic), forced
by `profiles/brainstorm.yaml`.

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"
- **Directory name**: the last segment of pwd

---

## Parse flags for session handling

Extract from $ARGUMENTS:
- **--new**: force create a new session (the master skips auto-detect)
- **--session**: resume a specific session by ID

**IF `--session` is present**: skip the preparation below and **delegate immediately** to
the master (jump to "Delegate to the master", setting only `WORKFLOW_TYPE`).

## Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

## Parse arguments

Extract from $ARGUMENTS:
- **topic**: required (unless resuming). The subject to brainstorm (first quoted argument).

If the topic is missing, ask using AskUserQuestion: "What would you like to brainstorm?"

Generic flags (`--participants`, `--strategy`, `--verbose`, `--interactive`,
`--diagnostic`, `--new`) are parsed by the master from `$ARGUMENTS`. Note: brainstorm
forces the `disney` strategy via `profiles/brainstorm.yaml` `strategy_constraints.forced`,
so `--strategy` is ignored.

## Display introduction

    Brainstorm Session Starting
    ═══════════════════════════

    Disney strategy: creative thinking is kept separate from critical evaluation.
    Phase 1 (Dreamer): think big, no constraints.
    Phase 2 (Realist): what is feasible? how to implement?
    Phase 3 (Critic): what could go wrong? what risks?

## Delegate to the master

Set the handoff variable in conversation context:
- `WORKFLOW_TYPE` = `brainstorm`

Then **Read** `${CLAUDE_PLUGIN_ROOT}/commands/roundtable.md` and follow it from `PHASE 0`.
The master resolves `workflow_type` from `WORKFLOW_TYPE`, loads `profiles/brainstorm.yaml`,
and runs auto-detect, session setup, the round loop, and completion. Strategy (`disney`,
forced by the profile), participants (`profiles/brainstorm.yaml` default, overridable via
`--participants`), and output-type (`summary`) are all resolved by the master.
