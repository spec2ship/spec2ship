# Architecture Overview

This document provides a high-level overview of Spec2Ship's architecture for contributors.

## Component Structure

```
spec2ship/
├── .claude/                  # Claude context and guidelines
│   ├── CLAUDE.md             # Main context file
│   └── s2s-development.md    # Development patterns
├── .claude-plugin/           # Plugin manifest
├── commands/                 # Slash commands (/s2s:*)
│   ├── init.md, specs.md, design.md, brainstorm.md, plan.md, roundtable.md
│   ├── plan/                 # Plan subcommands
│   └── session/              # Session subcommands
├── agents/                   # AI agents
│   ├── roundtable/           # Discussion participants
│   ├── exploration/          # Codebase analysis
│   └── validation/           # Session validation
├── skills/                   # Knowledge bases
│   ├── roundtable-execution/ # How to run roundtables
│   ├── roundtable-strategies/# Facilitation strategies
│   ├── arc42-templates/      # Architecture templates
│   ├── iso25010-requirements/# Quality model
│   └── ...
├── templates/                # File templates
├── docs/                     # Documentation
│   ├── README.md             # Core concepts
│   └── architecture/         # Architecture docs and ADRs
└── examples/                 # Sample outputs
```

## Component Types

### Commands

Slash commands that users invoke directly.

**Location**: `commands/*.md`

**Characteristics**:
- Orchestrate workflows
- Parse arguments
- Manage state
- Invoke agents
- Write output files

**Example**: `commands/specs.md` orchestrates the specs roundtable.

### Agents

Specialized AI participants invoked by commands.

**Location**: `agents/*/*.md`

**Types**:
- **Facilitator**: Orchestrates roundtable discussions
- **Participants**: Domain experts (product-manager, architect, etc.)
- **Exploration**: Analyze codebases
- **Validation**: Check session consistency

**Key constraint**: Subagents cannot spawn other subagents.

### Skills

Knowledge bases loaded on demand.

**Location**: `skills/*/SKILL.md`

**Characteristics**:
- Provide domain knowledge
- Third-person descriptions
- Progressive disclosure (references/, examples/)
- Max ~2,000 words in SKILL.md

## Roundtable Architecture

Since TECH-002 Phase 8 (v0.4.0, 2026-05), all 4 workflow commands route through a single master orchestrator. The 3 workflow-specific commands are thin launchers; the master holds the round loop, profile-driven session setup, and output dispatch.

```
┌─────────────────────────────────────────────────────────────┐
│              THIN LAUNCHER (workflow-specific)              │
│           (specs.md, design.md, brainstorm.md)              │
│                                                             │
│  • Parses arguments (--session, --skip-roundtable, ...)     │
│  • Validates workflow-specific prerequisites                │
│  • Smart source detection (specs only)                      │
│  • Read-and-follow handoff to the master                    │
└─────────────────────────────────────────────────────────────┘
                           │ handoff variables
                           │ (WORKFLOW_TYPE, INPUT_SOURCES,
                           │  OUTPUT_MERGE_MODE, OUTPUT_FORMAT,
                           │  FOCUS_AREA)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│             MASTER ORCHESTRATOR (roundtable.md)             │
│                                                             │
│  PHASE 0  Auto-detect / parse args (scoped to workflow)     │
│  PHASE 1  Profile-driven session setup                      │
│           (folder + 3 snapshots + skeleton from PROFILE)    │
│  PHASE 3  Delegate to phase-2-core.md round loop            │
│  PHASE 4  Close-out + output dispatch                       │
│                                                             │
│  Profile source: skills/roundtable-execution/profiles/      │
│                  {specs,design,brainstorm,roundtable}.yaml  │
└─────────────────────────────────────────────────────────────┘
                           │
              For each round (phase-2-core.md §2):
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. FACILITATOR (question)                                   │
│    • Generates discussion question                          │
│    • Prepares participant context (+ hook_overrides)        │
│    • Uses: Task(roundtable-facilitator)                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. PARTICIPANTS (parallel, blind voting)                    │
│    • Receive context (no file access)                       │
│    • Provide domain perspectives                            │
│    • Uses: Task(roundtable-{participant}) × N               │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. FACILITATOR (synthesis)                                  │
│    • Synthesizes responses                                  │
│    • Creates/updates artifacts                              │
│    • Decides next action                                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. MASTER (update session, evaluate next)                   │
│    • Writes round to session file                           │
│    • Updates metrics + state.json                           │
│    • Displays recap; loops or exits round loop              │
└─────────────────────────────────────────────────────────────┘
                           │
              After last round:
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 4 (master): Close-out + Output                        │
│  • Diagnostic report (if --diagnostic)                      │
│  • Update session status = closed                           │
│  • Dispatch to output-generation/references/{workflow}.md   │
│    (specs-srs, design-arc42, brainstorm, roundtable-summary)│
└─────────────────────────────────────────────────────────────┘
```

The master can also be invoked directly via `/s2s:roundtable` (native mode, generic workflow_type). See ADR-0011 (Phase 4 + Phase 8 addenda) for the architectural decision and ADR-0012 for output-generation skill rationale.

## Key Design Principles

| Principle | Description |
|-----------|-------------|
| **Component Separation** | Commands orchestrate, Agents provide expertise, Skills provide knowledge |
| **Master Orchestrator + Thin Launchers** | One round-loop implementation in `commands/roundtable.md`; workflow-specific commands are thin launchers that Read-and-follow the master (Pattern 1) |
| **Profile-Driven** | Workflow shape is data (`skills/roundtable-execution/profiles/*.yaml`), not duplicated procedural code |
| **Inline Orchestration** | Round loop runs in command land, not subagents (subagents can't spawn subagents) |
| **Model Tiers** | Critical tasks use opus, most use inherited model, simple tasks use haiku |
| **Context Passing** | Participants receive inline context (no file access, enables blind voting) |
| **Session as Truth** | Single session file contains all state and artifacts |

## Data Flow

```
CONTEXT.md (project info)
     │
     ▼
config.yaml (settings)
     │
     ▼
COMMAND (orchestrator)
     │
     ├──► Facilitator (question)
     │         │
     │         ▼
     │    participant_context
     │         │
     │         ▼
     ├──► Participants (parallel)
     │         │
     │         ▼
     │    responses[]
     │         │
     │         ▼
     ├──► Facilitator (synthesis)
     │         │
     │         ▼
     │    artifacts, next_action
     │         │
     ▼         ▼
SESSION FILE (.s2s/sessions/*.yaml)
     │
     ▼
OUTPUT DOCS (requirements.md, etc.)
```

## Extending the System

| Extension | How |
|-----------|-----|
| New agent | Create `agents/roundtable/{name}.md` |
| New skill | Create `skills/{name}/SKILL.md` |
| New strategy | Add to `skills/roundtable-strategies/` |
| New command | Create `commands/{name}.md` |

For extension guides, ask Claude: "how to extend s2s"

## Architecture Decisions

Significant architecture decisions are documented as ADRs in [`decisions/`](./decisions/).

For detailed design rationale, see the [ADR index](./decisions/README.md).

---

*See also: [Contributing](../../CONTRIBUTING.md)*
