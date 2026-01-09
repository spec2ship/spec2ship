# Spec2Ship Development Context

Spec2Ship (s2s) is a Claude Code plugin that automates the software lifecycle: specifications → planning → implementation → shipping.

## Project Structure

```
spec2ship/
├── .claude/                  # Claude configuration (this folder)
├── .claude-plugin/           # Plugin manifest
├── commands/                 # Slash commands (/s2s:*)
│   ├── init.md, brainstorm.md, specs.md, design.md, plan.md
│   ├── init/                 # detect, setup, context
│   ├── plan/                 # create, list, start, complete
│   └── roundtable/           # start, list, resume
├── agents/roundtable/        # Discussion participants
│   ├── facilitator.md        # Orchestrates rounds
│   └── *.md                  # Participants (architect, tech-lead, etc.)
├── skills/                   # Knowledge bases
│   ├── roundtable-execution/ # Shared execution logic
│   ├── roundtable-strategies/# disney, debate, standard, etc.
│   └── arc42, iso25010, madr, conventional-commits
├── templates/                # File templates for user projects
└── docs/                     # User documentation
```

---

## Architecture Decisions

### SAD-001: Component Separation

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| **Commands** | Workflow orchestration | User-facing operations with phases, state |
| **Agents** | Specialized tasks | Domain expertise, parallelizable work |
| **Skills** | Knowledge on-demand | Standards, patterns, templates |

### SAD-002: Roundtable Implementation

- **Inline orchestration**: Commands execute roundtable loop directly (not via SlashCommand)
- **Skill as library**: `roundtable-execution` skill provides shared logic
- **Constraint**: Claude Code subagents cannot spawn other subagents

### SAD-003: Agent Tiers

| Tier | Model | Use Case |
|------|-------|----------|
| **Critical** | opus | Facilitator decisions |
| **Default** | inherit | Most agents - inherits user's model |
| **Fast** | haiku | Simple validation |

### SAD-004: Skills Progressive Disclosure

```
skills/{name}/
├── SKILL.md          # Always loaded (~1,500-2,000 words)
├── references/       # Loaded on demand
└── examples/         # Loaded on demand
```

### SAD-005: State Management

Single source of truth: `.s2s/state.yaml`

---

## Component Guidelines

| Aspect | Commands | Agents | Skills |
|--------|----------|--------|--------|
| **Voice** | Imperative | Second person ("You are...") | Third person ("This skill...") |
| **Frontmatter** | description, allowed-tools, argument-hint | name, description, model, color, tools | name, description, version |
| **Body** | Context + Instructions | System prompt (500-3,000 words) | Core concepts + references |

### Agent Invocation (CRITICAL)

```markdown
# CORRECT - Invokes the agent file
**Use the roundtable-facilitator agent** with this input:

# WRONG - Creates generic agent without agent's config
Task(subagent_type="general-purpose", prompt="You are a facilitator...")
```

---

## Naming Conventions

| Type | Format | Example |
|------|--------|---------|
| Plan ID | `YYYYMMDD-HHMMSS-slug` | `20241228-143022-user-auth` |
| Branch | `feature/F{NN}-slug` | `feature/F01-user-auth` |
| Session | `YYYYMMDD-HHMMSS-topic` | `20241228-150000-auth-strategy` |

### Command Structure

```
/s2s:{category}:{operation}        # Subcommands = operations
/s2s:roundtable:start --strategy   # Flags = configuration
```

---

## Code Style

- **Language**: English for code, comments, documentation
- **Markdown**: GitHub-flavored, CommonMark compatible
- **YAML**: 2-space indent, quoted strings with special chars
- **File encoding**: UTF-8, LF line endings

---

## Testing

```bash
/plugin marketplace remove spec2ship
/plugin marketplace add https://github.com/spec2ship/spec2ship.git#develop
/plugin install s2s@spec2ship
```

---

## Development Reference

For detailed patterns, examples, anti-patterns, and lessons learned, see:
**`.claude/s2s-development.md`**

Key topics covered:
- Agent invocation patterns (YAML I/O)
- Command writing patterns (context, instructions)
- Multi-agent orchestration
- Adding new skills/strategies
- Anti-patterns to avoid
- Session file management

---

## Key Reminders

1. **Agent invocation**: Use `**Use the roundtable-X agent**` pattern, not Task with generic prompt
2. **Subagents**: Cannot spawn other subagents - orchestration must be in commands
3. **SlashCommand**: Is ASYNCHRONOUS - cannot wait for results
4. **Skills**: Third person description with exact trigger phrases
5. **Config flow**: config.yaml → arguments → snapshot → subagent prompt
