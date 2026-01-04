# Roundtable Components (v3)

This document describes how Commands, Agents, and Skills work together in the Roundtable v3 system.

## Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER                                    │
│                           │                                     │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ WORKFLOW COMMANDS (specs.md, design.md, brainstorm.md)  │   │
│  │ • Workflow-specific setup and validation                 │   │
│  │ • Delegates via SlashCommand:/s2s:roundtable:start       │   │
│  │ • Post-processes results                                 │   │
│  └──────────────────────────┬──────────────────────────────┘   │
│                             │ SlashCommand                      │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ COMMAND: roundtable/start.md (Session Lifecycle)         │   │
│  │ • Creates session file .s2s/sessions/{id}.yaml           │   │
│  │ • Launches Orchestrator Agent                            │   │
│  │ • Batch writes results from orchestrator                 │   │
│  │ • Generates output document                              │   │
│  └──────────────────────────┬──────────────────────────────┘   │
│                             │ Task Agent                        │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ORCHESTRATOR AGENT (orchestrator.md)                     │   │
│  │ • Executes roundtable discussion loop                    │   │
│  │ • Launches Facilitator for questions/synthesis           │   │
│  │ • Launches Participants in parallel (blind voting)       │   │
│  │ • Returns structured YAML for batch write                │   │
│  │ • skills: roundtable-strategies                          │   │
│  └──────────────────────────┬──────────────────────────────┘   │
│                             │                                   │
│           ┌─────────────────┼─────────────────┐                │
│           ▼                 ▼                 ▼                │
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

## Commands

### roundtable/start.md

The session lifecycle manager. In v3, delegates loop execution to Orchestrator Agent:

| Responsibility | Description |
|----------------|-------------|
| Load configuration | Read `.s2s/config.yaml` for strategy, participants |
| Create session | Initialize `.s2s/sessions/{id}.yaml` |
| Launch orchestrator | Task(orchestrator) with session context |
| Batch write | Update session file with orchestrator results |
| Generate output | Create ADR, requirements, or architecture docs |

### roundtable/resume.md

Continues an interrupted session:
- Loads full session history
- Passes to facilitator with `resumed: true`
- Continues loop from where it left off

### roundtable/list.md

Displays session status:
- Groups by active/paused/completed
- Shows strategy, phase, round count
- Marks current session

## Orchestrator Agent (v3)

Location: `agents/roundtable/orchestrator.md`

**New in v3**: The discussion loop is now managed by a dedicated Orchestrator Agent, not the command.

| Responsibility | Description |
|----------------|-------------|
| Execute loop | Run rounds until conclusion |
| Launch facilitator | Task(facilitator) for questions and synthesis |
| Launch participants | Task(participants) in parallel (blind voting) |
| Enforce participation mode | Parallel or sequential per strategy |
| Return structured data | YAML for batch write by command |
| Handle fallbacks | Retry facilitator, use fallback logic if needed |

**Skills**: `roundtable-strategies` (comma-separated string format)

**Why this change?** Moving the loop to an agent:
- Reduces context usage in command
- Allows reuse across workflows (specs, design, brainstorm)
- Better separation of concerns (command = lifecycle, agent = logic)

### Orchestrator Input/Output

**Input** (from command):
```yaml
session:
  id: "{session-id}"
  topic: "{topic}"
  strategy: "disney"

strategy_config:
  participation: "parallel"
  phases: [...]

participants:
  - id: "software-architect"
    agent_file: "agents/roundtable/software-architect.md"

current_state:
  phase: "dreamer"
  rounds_completed: 0

escalation_triggers:
  no_consensus_after_attempts: 3
  confidence_below: 0.5
  critical_keywords: [security, must-have]
```

**Output** (to command):
```yaml
status: "round_complete" | "concluded" | "escalation_needed"
round_data:
  number: 1
  phase: "dreamer"
  question: "{facilitator's question}"
  responses:
    - participant: "architect"
      response: "{text}"
      confidence: 0.8
  synthesis: "{facilitator's synthesis}"
  new_consensus: [...]
  new_conflicts: [...]
```

## Agents

### Facilitator Agent

Location: `agents/roundtable/facilitator.md`

**Role**: Orchestrate discussion, generate questions, synthesize responses

**Input**: Structured YAML with session state, history, context
**Output**: Structured YAML with action, question/synthesis, next steps

**Key Decisions Made by Facilitator**:
- What question to ask next
- Which participants are relevant (for targeted mode)
- Whether consensus is reached
- Whether to continue, move to next phase, or conclude
- Whether to recommend escalation

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
**Output**: Position, rationale, confidence, dependencies

### Agent Skills Field

Agents can declare skills they need in their frontmatter:

```yaml
# In agent frontmatter:
skills: arc42-templates, iso25010-requirements
```

**Format**: Comma-separated string (not array)

| Agent | Location | Skills | Why |
|-------|----------|--------|-----|
| orchestrator | `agents/roundtable/` | `roundtable-strategies` | Access to facilitation methods |
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
1. Command builds facilitator input (session state, history)
2. Command calls Task(facilitator)
3. Facilitator returns: { action: "generate_question", question, relevant_participants }
4. Command parses response
```

### Participant Response Flow

```
1. Command builds participant prompts (context, question, synthesis)
2. Command launches Tasks in parallel (for parallel mode)
3. Each participant returns: { position, rationale, confidence }
4. Command collects all responses
```

### Synthesis Flow

```
1. Command builds synthesis input (all responses, history)
2. Command calls Task(facilitator) for synthesis
3. Facilitator returns: { synthesis, new_consensus, new_conflicts, next_action }
4. Command updates session file (batch write)
5. Command evaluates escalation triggers
6. Command proceeds based on next_action
```

## Separation of Concerns

| Component | Decides | Executes |
|-----------|---------|----------|
| Command | Session lifecycle | File I/O, Task launching |
| Orchestrator | Loop coordination | Task launching (facilitator, participants) |
| Facilitator | What questions, synthesis | Nothing (returns structured data) |
| Participants | Their perspective | Nothing (returns structured data) |
| Strategy Skill | Facilitation method | Nothing (provides prompts) |

**Key Principle**: Facilitator decides, Orchestrator coordinates, Command persists. Agents don't have side effects.

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
