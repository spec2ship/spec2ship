---
description: Design technical architecture through a roundtable discussion. Reads requirements.md and produces architecture documentation. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [--skip-roundtable] [--focus components|api|deployment] [--strategy debate|standard|consensus-driven] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
skills: roundtable-execution, roundtable-strategies, arc42-templates, madr-decisions
---

# Design Technical Architecture

`/s2s:design` is a **thin launcher** for the `design` workflow (TECH-002 Phase 8). It runs
design-specific preparation (prerequisite check, existing-output handling), then delegates
to the `roundtable.md` master, which owns auto-detect, session setup, the Phase 2 round
loop, and output generation.

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Read `.s2s/CONTEXT.md` for project context
- Read `.s2s/requirements.md` if exists
- Check if `.s2s/architecture.md` exists
- Read `.s2s/config.yaml` for settings

---

## Parse flags for session handling

Extract from $ARGUMENTS:
- **--new**: force create a new session (the master skips auto-detect)
- **--session**: resume a specific session by ID

**IF `--session` is present**: skip all design-specific preparation below and **delegate
immediately** to the master (jump to "Delegate to the master", setting only
`WORKFLOW_TYPE`).

## Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

## Check prerequisites

If `.s2s/requirements.md` does not exist:

    Warning: No requirements document found.

    Recommended workflow:
    1. /s2s:init     - Initialize project
    2. /s2s:specs    - Define requirements
    3. /s2s:design   - Design architecture (you are here)

    Continue without formal requirements?

Ask using AskUserQuestion:
- Options: "Continue with CONTEXT.md only" / "Run /s2s:specs first"

If the user chooses "Run /s2s:specs first", stop.

## Check for existing architecture

Check if `.s2s/architecture.md` exists.

If the architecture doc exists:
- Display a summary (count components, decisions)
- Ask using AskUserQuestion: "Architecture doc exists. What would you like to do?"
  - Options: "Override (replace all)" / "Merge (add new)" / "Cancel"
- If "Cancel", stop.
- Store the choice as `OUTPUT_MERGE_MODE` (`override` or `merge`); the master's Phase 4
  output generation honors it. If `architecture.md` does not exist, `OUTPUT_MERGE_MODE = override`.

## Parse workflow arguments

Extract from $ARGUMENTS:
- **--skip-roundtable**: skip the discussion, generate architecture directly
- **--focus**: focus area (components|api|deployment). Store as `FOCUS_AREA`.

Generic flags (`--strategy`, `--verbose`, `--interactive`, `--diagnostic`, `--new`) are
parsed by the master from `$ARGUMENTS`; the launcher does not consume them.

## Skip Roundtable Mode

**If `--skip-roundtable` IS present:**

1. Analyze `.s2s/requirements.md` (and CONTEXT.md) directly.
2. Generate a basic architecture from common patterns.
3. Ask the user for technology preferences.
4. Read `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md` and generate
   `.s2s/architecture.md` + `.s2s/decisions/ADR-*.md` for `workflow_type=design`
   (honoring `OUTPUT_MERGE_MODE`).
5. STOP. Do not delegate to the master.

## Delegate to the master

Set the handoff variables in conversation context:
- `WORKFLOW_TYPE` = `design`
- `OUTPUT_MERGE_MODE` = the choice from "Check for existing architecture"
- `FOCUS_AREA` = the `--focus` value (empty if not given)

Then **Read** `${CLAUDE_PLUGIN_ROOT}/commands/roundtable.md` and follow it from `PHASE 0`.
The master resolves `workflow_type` from `WORKFLOW_TYPE`, loads `profiles/design.yaml`, and
runs auto-detect, session setup, the round loop, and completion. Strategy (`debate`
default) and output-type (`architecture`) are resolved by the master from the profile and
`workflow_type`; the launcher does not pass them.
