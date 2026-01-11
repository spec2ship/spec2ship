# Roundtable Components

This document describes how Commands, Agents, and Skills work together in the Roundtable system.

## Component Overview

> **Key Constraint**: Claude Code subagents cannot spawn other subagents.
> Solution: Orchestration logic is **inline in workflow commands**, not a separate agent.

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER                                    │
│                           │                                     │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ WORKFLOW COMMANDS (specs.md, design.md, brainstorm.md)  │   │
│  │                                                          │   │
│  │ PHASE 1: Setup                                           │   │
│  │ • Creates session file .s2s/sessions/{id}.yaml           │   │
│  │ • Workflow-specific validation and defaults              │   │
│  │                                                          │   │
│  │ PHASE 2: Discussion Loop (INLINE)                        │   │
│  │ ┌──────────────────────────────────────────────────────┐ │   │
│  │ │ For each round:                                      │ │   │
│  │ │ 1. Task(facilitator) → question                      │ │   │
│  │ │ 2. Task(participants) → parallel (blind voting)      │ │   │
│  │ │ 3. Task(facilitator) → synthesis                     │ │   │
│  │ │ 4. Update session file                               │ │   │
│  │ │ 5. Evaluate next_action                              │ │   │
│  │ └──────────────────────────────────────────────────────┘ │   │
│  │                                                          │   │
│  │ PHASE 3: Completion                                      │   │
│  │ • Generates output (requirements.md, architecture/)      │   │
│  └──────────────────────────┬──────────────────────────────┘   │
│                             │                                   │
│           ┌─────────────────┼─────────────────┐                │
│           ▼                                   ▼                │
│  ┌─────────────┐  ┌─────────────────────────────────┐         │
│  │ FACILITATOR │  │      PARTICIPANT AGENTS         │         │
│  │   (opus)    │  │  (parallel, blind voting)       │         │
│  │             │  │  Architect │ TechLead │ QA │... │         │
│  └─────────────┘  └─────────────────────────────────┘         │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ SKILL: roundtable-strategies/{strategy}.md               │   │
│  │ (Knowledge about facilitation method)                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

> **Note**: `roundtable/start.md` is a separate command for ad-hoc roundtable discussions,
> not used by workflow commands which have their own inline orchestration.

## Commands

### roundtable/start.md

The session lifecycle manager with **inline orchestration**:

| Responsibility | Description |
|----------------|-------------|
| Load configuration | Read `.s2s/config.yaml` for strategy, participants |
| Create session | Initialize `.s2s/sessions/{id}.yaml` |
| Auto-detect strategy | Analyze topic keywords, recommend strategy |
| Execute discussion loop | INLINE: Task(facilitator) + Task(participants) per round |
| Batch write | Update session file after each round |
| Handle escalation | AskUserQuestion when triggers fire |
| Generate output | Create ADR, requirements, or architecture docs |

**Why inline orchestration?**
Claude Code subagents cannot spawn other subagents. A pattern like `Task(orchestrator) → Task(facilitator)` doesn't work. Solution: keep the loop in the command, which CAN call Task() multiple times.

### roundtable/resume.md

Continues an interrupted session:
- Loads full session history
- Synthesizes state from `rounds[]` (single source of truth)
- Continues discussion loop from where it left off
- Uses same inline orchestration as start.md

### roundtable/list.md

Displays session status:
- Groups by active/paused/completed
- Shows strategy, phase, round count
- Marks current session

## Agents

### Facilitator Agent

Location: `agents/roundtable/facilitator.md`

**Role**: Generate questions, synthesize responses, decide next action

**Called by**: start.md (twice per round: question + synthesis)

**2 Action Types**:

| Action | Input | Output |
|--------|-------|--------|
| `question` | Session state, phase, consensus, conflicts | Question, focus, participants |
| `synthesis` | All participant responses | Synthesis, consensus, conflicts, next_action |

**Key Decisions Made by Facilitator**:
- What question to ask next
- Which participants are relevant (for targeted mode)
- Whether consensus is reached
- Whether to continue, move to next phase, or conclude
- Whether to recommend escalation

**Skills**: `roundtable-strategies` (for strategy-specific behavior)

### Participant Agents

Location: `agents/roundtable/`

| Agent | File | Perspective |
|-------|------|-------------|
| Software Architect | `software-architect.md` | Structure, patterns, design |
| Technical Lead | `technical-lead.md` | Implementation, tech stack |
| QA Lead | `qa-lead.md` | Quality, testing, edge cases |
| DevOps Engineer | `devops-engineer.md` | Deploy, infra, operations |
| Product Manager | `product-manager.md` | User needs, business value |

**Input**: Topic, question, context, previous synthesis
**Output**: Position, rationale, confidence, concerns

**Blind Voting**: All participants are launched in a SINGLE message (parallel Task calls). No participant sees another's response until the facilitator synthesizes.

### Agent Skills Field

Agents can declare skills they need in their frontmatter:

```yaml
# In agent frontmatter:
skills: arc42-templates, iso25010-requirements
```

**Format**: Comma-separated string (not array)

| Agent | Location | Skills | Why |
|-------|----------|--------|-----|
| facilitator | `agents/roundtable/` | `roundtable-strategies` | Strategy-specific behavior |
| software-architect | `agents/roundtable/` | `arc42-templates` | Architecture patterns |
| spec-validator | `agents/validation/` | `iso25010-requirements, arc42-templates, madr-decisions` | Validation standards |
| requirements-mapper | `agents/exploration/` | `iso25010-requirements` | Requirement patterns |

## Skills

### roundtable-strategies

Location: `skills/roundtable-strategies/`

**Purpose**: Define facilitation methods

**Structure**:
```
skills/roundtable-strategies/
├── SKILL.md                    # Overview, selection guide
└── references/
    ├── standard.md             # Round-robin
    ├── disney.md               # Dreamer/Realist/Critic
    ├── debate.md               # Pro vs Con
    ├── consensus-driven.md     # Fast convergence
    └── six-hats.md             # De Bono's method
```

**Each strategy defines**:
- Default participation mode
- Phases (if multi-phase)
- Prompt suffixes for each phase
- Consensus policy
- Validation rules

## Data Flow 
### Question Generation Flow

```
1. Command reads session file, calculates current state
2. Command builds facilitator input (session state, history)
3. Command calls Task(facilitator) with action: question
4. Facilitator returns: { action: "question", question, focus, participants }
5. Command validates YAML (uses fallback if malformed)
```

### Participant Response Flow

```
1. Command builds participant prompts (context, question, synthesis)
2. Command launches ALL Tasks in SINGLE message (parallel, blind voting)
3. Each participant returns: { position, rationale, confidence, concerns }
4. Command collects all responses
```

### Synthesis Flow

```
1. Command builds synthesis input (all responses, history)
2. Command calls Task(facilitator) with action: synthesis
3. Facilitator returns: { synthesis, consensus, conflicts, resolved, next_action }
4. Command updates session file (batch write)
5. Command evaluates escalation triggers
6. Command proceeds based on next_action (continue/phase/conclude/escalate)
```

## Separation of Concerns 
| Component | Decides | Executes |
|-----------|---------|----------|
| Command (start.md) | Session lifecycle, loop execution | File I/O, Task launching, escalation |
| Facilitator | What questions, synthesis, next action | Nothing (returns structured data) |
| Participants | Their perspective | Nothing (returns structured data) |
| Strategy Skill | Facilitation method | Nothing (provides prompts) |

**Key Principle**: Facilitator decides, Command orchestrates and persists. Agents don't have side effects.

## Agent Isolation

| Component | Reads Session? | Receives in Prompt |
|-----------|----------------|-------------------|
| Command (start.md) | YES | N/A (is the orchestrator) |
| Facilitator | NO | Curated state (phase, consensus, conflicts) |
| Participants | NO | Topic + question + project context only |

This isolation ensures:
- No direct agent-to-agent communication
- Controlled information flow
- Predictable behavior

## Configuration Hierarchy

```
Command line flags
       ↓
.s2s/config.yaml
       ↓
Strategy skill defaults
       ↓
Hardcoded fallbacks
```

---
*See [flow.md](./flow.md) for sequence diagrams*
*Part of Spec2Ship Roundtable documentation*
