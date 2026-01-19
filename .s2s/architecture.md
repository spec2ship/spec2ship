# Spec2Ship Architecture

**Updated**: 2026-01-19
**Format**: Technical architecture overview

---

## System context

Spec2Ship (s2s) is a Claude Code plugin that automates the software development lifecycle through AI-assisted roundtable discussions. It operates within Claude Code's plugin architecture, using markdown files as both code and configuration.

### External dependencies

| System | Purpose | Interface |
|--------|---------|-----------|
| Claude Code | Plugin host | Plugin manifest, slash commands |
| User project | Target for generated artifacts | File system (`.s2s/`) |
| Git | Version control (optional) | Bash commands |

---

## Architecture principles

- **Markdown as code**: All logic expressed in markdown files that Claude interprets
- **Session as single source of truth**: All state in one YAML file per session
- **Progressive disclosure**: Skills load detailed content on-demand
- **Templates as source of truth**: Commands read templates, not inline content
- **No external dependencies**: Pure markdown/YAML implementation

---

## Component overview

```
spec2ship/
├── .claude-plugin/           # Plugin manifest
├── commands/                 # Slash commands (COMP-001)
│   ├── init.md              # /s2s:init
│   ├── specs.md             # /s2s:specs
│   ├── design.md            # /s2s:design
│   ├── brainstorm.md        # /s2s:brainstorm
│   ├── plan.md              # /s2s:plan
│   ├── roundtable.md        # /s2s:roundtable
│   ├── plan/                # Subcommands
│   └── session/             # Subcommands
├── agents/                   # AI participants (COMP-002)
│   └── roundtable/
│       ├── facilitator.md   # Orchestrates discussions
│       └── *.md             # Participants (architect, tech-lead, etc.)
├── skills/                   # Knowledge bases (COMP-003)
│   ├── roundtable-execution/# Shared execution logic
│   ├── roundtable-strategies/# Facilitation strategies
│   ├── s2s-guide/           # Usage and extension guide
│   └── */                   # Domain skills (arc42, madr, etc.)
└── templates/                # File templates (COMP-004)
    ├── project/             # Standalone project templates
    └── workspace/           # Workspace templates
```

---

## Components

| ID | Component | Responsibility | Technology |
|----|-----------|---------------|------------|
| COMP-001 | Commands | Entry points for user interaction | Markdown |
| COMP-002 | Agents | AI participants with specialized perspectives | Markdown |
| COMP-003 | Skills | Knowledge bases and patterns | Markdown |
| COMP-004 | Templates | File structure definitions | Markdown/YAML |

### COMP-001: Commands

**Responsibility**: Define slash commands that users invoke. Commands contain context (what to read), instructions (what to do), and orchestration logic (when to spawn agents).

**Key patterns**:
- Frontmatter: `description`, `allowed-tools`, `argument-hint`
- Imperative voice for instructions
- Agent invocation: `**Use the {name} agent**`
- Tool emphasis: `**YOU MUST use {Tool} tool**`

**Files**: `commands/*.md`, `commands/**/*.md`

---

### COMP-002: Agents

**Responsibility**: Provide specialized perspectives in roundtable discussions. Agents are system prompts that configure Claude for specific roles.

**Types**:
- **Facilitator**: Orchestrates rounds, synthesizes, manages artifacts
- **Participants**: Provide domain expertise (architect, tech-lead, PM, QA, etc.)

**Key constraints**:
- Agents CANNOT spawn other agents (architectural limitation)
- Orchestration must happen in commands
- Agents receive YAML input, return YAML output

**Files**: `agents/roundtable/*.md`

---

### COMP-003: Skills

**Responsibility**: Provide reusable knowledge, patterns, and reference material. Skills are loaded on-demand based on trigger phrases.

**Structure**:
```
skills/{skill-name}/
├── SKILL.md           # Entry point (< 2000 words)
└── references/        # Detailed content
    └── *.md
```

**Key patterns**:
- Third person description: "This skill should be used when..."
- Progressive disclosure: Core in SKILL.md, details in references/
- Trigger phrases for automatic loading

**Files**: `skills/*/SKILL.md`, `skills/*/references/*.md`

---

### COMP-004: Templates

**Responsibility**: Define file structures for generated artifacts. Commands read templates, substitute placeholders, and write to user project.

**Placeholder format**: `{placeholder-name}`

**Files**: `templates/project/*.md`, `templates/workspace/*.md`

---

## Data flow

### Configuration cascade

```
templates/project/config.yaml     # Defaults
         ↓
.s2s/config.yaml                  # User customizations
         ↓
Command arguments (--strategy)    # Runtime overrides
         ↓
.s2s/sessions/{id}/config-snapshot.yaml   # Frozen for session
         ↓
Subagent prompt (YAML input)      # Passed to facilitator/participants
```

### Session lifecycle

```
User invokes /s2s:specs "topic"
         ↓
Command reads: CONTEXT.md, config.yaml, ideas.md
         ↓
Command creates: session file, config-snapshot, context-snapshot
         ↓
Loop:
  ├── Facilitator generates question
  ├── Participants respond (parallel)
  ├── Facilitator synthesizes
  ├── Session file updated
  └── Check: continue or conclude?
         ↓
Command generates: requirements.md (or architecture.md, ideas.md)
         ↓
Session status → "closed"
```

### Artifact flow

```
brainstorm → ideas.md (IDEA-*)
                 ↓ promote
specs ←──── BACKLOG.md (FEAT-*)
    ↓
requirements.md (REQ-*, NFR-*)
    ↓
design → architecture.md (COMP-*, INT-*)
       + decisions/ (ADR-*)
    ↓
plan → plans/ (task breakdown)
```

---

## Interfaces

### INT-001: Command ↔ Agent

**Type**: YAML via Task tool prompt

**Provider**: Commands
**Consumer**: Agents

**Contract**:
```yaml
# Command passes to agent:
action: "generate_question" | "synthesize" | "respond"
topic: "discussion topic"
context:
  project: {from context-snapshot}
  config: {from config-snapshot}
round: 1
previous_responses: [...]  # For synthesis

# Agent returns:
status: "success" | "error"
result:
  question: "..." | synthesis: "..." | response: "..."
artifacts: [...]  # New/updated artifacts
next_action: "continue" | "conclude" | "escalate"
```

---

### INT-002: Command ↔ Skill

**Type**: File read via Read tool

**Provider**: Skills
**Consumer**: Commands

**Contract**: Commands reference skills by reading SKILL.md and/or specific reference files.

---

### INT-003: Command ↔ Template

**Type**: File read + placeholder substitution

**Provider**: Templates
**Consumer**: Commands (init, plan)

**Contract**:
- Read template from `${CLAUDE_PLUGIN_ROOT}/templates/`
- Replace `{placeholder}` with values
- Write to target location

---

## Extension points

### Adding a new command

1. Create `commands/{name}.md` with frontmatter
2. Define context section (what to read)
3. Define instructions (what to do)
4. Document in `skills/s2s-guide/`

See: `skills/s2s-guide/examples/new-command.md`

---

### Adding a new agent

1. Create `agents/roundtable/{name}.md`
2. Define system prompt with role and perspective
3. Specify YAML input/output schema
4. Register in participant lists (config.yaml)

See: `skills/s2s-guide/examples/new-agent.md`

---

### Adding a new skill

1. Create `skills/{name}/SKILL.md` (< 2000 words)
2. Add trigger phrases in description
3. Create `references/` for detailed content
4. Optionally create `examples/`

See: `skills/s2s-guide/examples/new-skill.md`

---

## Key decisions

| ID | Decision | Rationale | ADR |
|----|----------|-----------|-----|
| ARCH-001 | Commands orchestrate, agents don't spawn subagents | Task tool only available to main agent | 0002 |
| ARCH-002 | Session file as single source of truth | Simplifies recovery and debugging | 0006 |
| ARCH-003 | Single state field for artifacts | Deterministic transitions for LLM | 0010 |
| ARCH-004 | Progressive disclosure for skills | Minimize token usage | 0005 |
| ARCH-005 | Workspace context cascade | Components inherit workspace context | 0009 |

---

## Open questions

- **OQ-001**: Should we support custom participant agents in user projects?
- **OQ-002**: How to handle very large codebases (context limits)?
