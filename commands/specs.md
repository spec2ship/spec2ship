---
description: Define functional requirements through a roundtable discussion. Reads CONTEXT.md and produces structured requirements.md. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [--skip-roundtable] [--format srs|volere|simple] [--strategy consensus-driven|standard|six-hats] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
skills: roundtable-execution, roundtable-strategies, iso25010-requirements
---

# Define Functional Requirements

`/s2s:specs` is a **thin launcher** for the `specs` workflow (TECH-002 Phase 8). It runs
specs-specific preparation (prerequisite checks, source detection, existing-output
handling), then delegates to the `roundtable.md` master, which owns auto-detect, session
setup, the Phase 2 round loop, and output generation.

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
- Check if `.s2s/requirements.md` exists
- Read `.s2s/config.yaml` for roundtable settings

---

## Parse flags for session handling

Extract from $ARGUMENTS:
- **--new**: force create a new session (the master skips auto-detect)
- **--session**: resume a specific session by ID

**IF `--session` is present**: skip all specs-specific preparation below and **delegate
immediately** to the master (jump to "Delegate to the master", setting only
`WORKFLOW_TYPE`). Resume must not be gated behind new-session prerequisite checks.

## Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

## Check prerequisites

Read `.s2s/CONTEXT.md` and verify it has been populated.

If CONTEXT.md contains placeholder text like "{Project description}":

    Error: Project context not defined.
    Run /s2s:init first to set up the project and gather context.

## Smart Source Detection (no flags needed)

**Detect available sources** for requirements input:

1. **Check for recent brainstorm sessions**:
   Use Bash to find brainstorm sessions from the last 7 days:
   ```bash
   find .s2s/sessions -name "*.yaml" -mtime -7 2>/dev/null | xargs grep -l 'workflow_type: brainstorm' 2>/dev/null
   ```

2. **Check for ideas.md with active ideas**:
   - Read `.s2s/ideas.md` if exists
   - Count ideas under `## Active` section (not `## Parked`, `## Promoted`, `## Rejected`)
   - Look for `**Status**: draft` or `**Status**: validated`

3. **Check for BACKLOG items**:
   - Read `.s2s/BACKLOG.md` if exists
   - Count items under `## Planned` section with status `planned`

**IF sources found**:

Display sources and ask user:

```
Available Input Sources
═══════════════════════

{IF recent brainstorm sessions found}
Recent Brainstorm Sessions:
- {session-id}: "{topic}" ({N} ideas, {date})
{/IF}

{IF active ideas in ideas.md}
Active Ideas (.s2s/ideas.md):
- {count} draft/validated ideas available
{/IF}

{IF planned BACKLOG items}
Planned Backlog Items (.s2s/BACKLOG.md):
- {count} features planned for implementation
{/IF}

These sources can inform requirements gathering.
```

Ask using AskUserQuestion:
- "Would you like to use these as input for requirements?"
  - Options:
    - "Yes, use all available sources (recommended)" - load all sources into context
    - "Select specific sources" - let user choose
    - "Start fresh" - ignore and start from CONTEXT.md only

**IF user selects "Select specific sources"**:
Present checkboxes for:
- Each brainstorm session
- ideas.md
- BACKLOG.md

**Store the selected sources** as `INPUT_SOURCES` (handoff variable; the master writes
them into `context-snapshot.yaml`).

**IF an ID is passed in arguments** (e.g., "specs IDEA-001"):
- Parse the ID from $ARGUMENTS
- **IF IDEA-*** pattern: Read `.s2s/ideas.md`, find that idea, use as primary input
- **IF FEAT-*** pattern: Read `.s2s/BACKLOG.md`, find that item, use as primary input
- Display: "Using {ID}: {title} as primary input for requirements"
- Record it as `INPUT_SOURCES.primary_id`.

## Check for existing requirements

If `.s2s/requirements.md` exists and has content:
- Display a summary of existing requirements (count REQ-* entries)
- Ask using AskUserQuestion: "Requirements exist. What would you like to do?"
  - Options: "Override (replace all)" / "Merge (add new)" / "Cancel"
- If "Cancel", stop.
- Store the choice as `OUTPUT_MERGE_MODE` (`override` or `merge`); the master's Phase 4
  output generation honors it. If `requirements.md` does not exist, `OUTPUT_MERGE_MODE = override`.

## Parse workflow arguments

Extract from $ARGUMENTS:
- **--skip-roundtable**: skip the discussion, generate requirements from CONTEXT.md directly
- **--format**: document format (srs|volere|simple), default `srs`. Store as `OUTPUT_FORMAT`.

Generic flags (`--strategy`, `--verbose`, `--interactive`, `--diagnostic`, `--new`) are
parsed by the master from `$ARGUMENTS`; the launcher does not consume them.

## Skip Roundtable Mode

**If `--skip-roundtable` IS present:**

1. Read CONTEXT.md directly.
2. Infer requirements from objectives and scope.
3. Generate a basic requirement list without discussion.
4. Skip session-folder creation.
5. Read `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md` and generate
   `.s2s/requirements.md` for `workflow_type=specs` (honoring `OUTPUT_FORMAT` and
   `OUTPUT_MERGE_MODE`).
6. STOP. Do not delegate to the master.

## Delegate to the master

Set the handoff variables in conversation context:
- `WORKFLOW_TYPE` = `specs`
- `INPUT_SOURCES` = the sources selected in "Smart Source Detection" (empty if none)
- `OUTPUT_MERGE_MODE` = the choice from "Check for existing requirements"
- `OUTPUT_FORMAT` = the `--format` value (default `srs`)

Then **Read** `${CLAUDE_PLUGIN_ROOT}/commands/roundtable.md` and follow it from `PHASE 0`.
The master resolves `workflow_type` from `WORKFLOW_TYPE`, loads `profiles/specs.yaml`, and
runs auto-detect, session setup, the round loop, and completion. Strategy
(`consensus-driven` default) and output-type (`requirements`) are resolved by the master
from the profile and `workflow_type`; the launcher does not pass them.
