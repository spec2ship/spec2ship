# Workflows

Spec2Ship organizes software development into six progressive phases, each with a dedicated command.

## The Six Phases

```
┌─────────┐   ┌───────────┐   ┌───────┐   ┌────────┐   ┌──────┐   ┌─────────┐
│  init   │──▶│ brainstorm│──▶│ specs │──▶│ design │──▶│ plan │──▶│ execute │
└─────────┘   └───────────┘   └───────┘   └────────┘   └──────┘   └─────────┘
   Setup        Explore        Define       Design       Plan       Build
              (optional)
```

## Phase Details

### 1. Init (`/s2s:init`)

**Purpose**: Set up project context

**What it does**:
- Detects tech stack and project structure
- Creates `.s2s/` configuration directory
- Generates `CONTEXT.md` with project description
- Creates `CLAUDE.md` for AI context

**When to run**: Once at project start, or when project context changes significantly.

### 2. Brainstorm (`/s2s:brainstorm "topic"`)

**Purpose**: Creative exploration of ideas

**What it does**:
- Uses Disney strategy (Dreamer → Realist → Critic)
- Generates ideas without constraints
- Evaluates feasibility
- Identifies risks and mitigations

**When to run**: Optional. Use for new features or when exploring solution space.

**Default participants**: Product Manager, Software Architect, Technical Lead, DevOps Engineer

### 3. Specs (`/s2s:specs`)

**Purpose**: Define what to build

**What it does**:
- Roundtable discussion on requirements
- Produces structured requirements document
- Identifies user personas and workflows
- Defines functional and non-functional requirements

**When to run**: Before design, to establish clear requirements.

**Default participants**: Product Manager, Business Analyst, QA Lead

**Default strategy**: Consensus-Driven

### 4. Design (`/s2s:design`)

**Purpose**: Define how to build it

**What it does**:
- Roundtable discussion on architecture
- Produces architecture decisions (ADRs)
- Defines components and interfaces
- Evaluates trade-offs

**When to run**: After specs, when architecture decisions are needed.

**Default participants**: Software Architect, Technical Lead, DevOps Engineer

**Default strategy**: Debate

### 5. Plan (`/s2s:plan --new "feature"`)

**Purpose**: Create implementation roadmap

**What it does**:
- Breaks feature into tasks
- Identifies dependencies
- Creates step-by-step plan
- References specs and design artifacts

**When to run**: When ready to implement a feature.

### 6. Execute (`/s2s:plan --session`)

**Purpose**: Implement with guidance

**What it does**:
- Works through plan tasks
- Provides implementation guidance
- Tracks progress
- Updates plan status

**When to run**: When starting implementation work.

## Workflow Independence

Each phase can be run independently:
- You can run `/s2s:design` without running `/s2s:specs` first
- Missing prerequisites trigger helpful prompts, not hard failures
- Skip phases when appropriate for your project

## State Management

Workflow state is tracked in session files (`.s2s/sessions/*.yaml`):
- Session status (active/closed)
- Last activity timestamp
- Round progress and artifacts

Each session file is the single source of truth for its workflow.

---

*See also: [Roundtable](./roundtable.md) | [Sessions](./sessions.md)*
