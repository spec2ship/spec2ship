# Spec2Ship Development Context

@.s2s/CONTEXT.md

Spec2Ship (s2s) is a Claude Code plugin that automates the software lifecycle: specifications → planning → implementation → shipping.

## Project Structure

```
spec2ship/
├── .claude/                  # Claude configuration (this folder)
│   ├── CLAUDE.md             # Main context (you're reading it)
│   └── s2s-development.md    # Development patterns and lessons learned
├── .claude-plugin/           # Plugin manifest
├── commands/                 # Slash commands (/s2s:*)
│   ├── init.md, brainstorm.md, specs.md, design.md, plan.md, roundtable.md
│   ├── plan/                 # close, list
│   └── session/              # list, status, close, cleanup, validate
├── agents/roundtable/        # Discussion participants
│   ├── facilitator.md        # Orchestrates rounds
│   └── *.md                  # Participants (architect, tech-lead, etc.)
├── skills/                   # Knowledge bases
│   ├── s2s-guide/            # Comprehensive usage and extension guide
│   ├── roundtable-execution/ # Shared execution logic
│   ├── roundtable-strategies/# disney, debate, standard, etc.
│   └── arc42, iso25010, madr, conventional-commits, ...
├── templates/                # File templates for user projects
└── docs/                     # Public documentation (for humans)
```

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

## Quick Reference

| Type | Format | Example |
|------|--------|---------|
| Plan ID | `YYYYMMDD-HHMMSS-slug` | `20241228-143022-user-auth` |
| Branch | `feature/F{NN}-slug` | `feature/F01-user-auth` |
| Session | `YYYYMMDD-workflow-slug` | `20241228-specs-auth` |
| Command | `/s2s:{category}:{operation}` | `/s2s:session:validate` |

---

## Code Style

- **Language**: English for code, comments, documentation
- **Markdown**: GitHub-flavored, CommonMark compatible
- **YAML**: 2-space indent, quoted strings with special chars
- **File encoding**: UTF-8, LF line endings

## Key Reminders

1. **Agent invocation**: Use `**Use the roundtable-X agent**` pattern, not Task with generic prompt
2. **Subagents**: Cannot spawn other subagents - orchestration must be in commands
3. **SlashCommand**: Is ASYNCHRONOUS - cannot wait for results
4. **Skills**: Third person description with exact trigger phrases
5. **Config flow**: config.yaml → arguments → snapshot → subagent prompt

---

## Development Reference

### For Contributors

**Primary reference**: `.claude/s2s-development.md`
- Agent invocation patterns (YAML I/O)
- Command writing patterns (context, instructions)
- Multi-agent orchestration
- Anti-patterns to avoid
- Lessons learned

### For Everyone (Usage & Extension)

**Skill**: `s2s-guide` - Comprehensive guide activated by questions like:
- "what is s2s", "how do I use specs", "which command for..."
- "how to create custom agent", "extend s2s", "add new command"

The skill provides:
- Workflow explanations
- Command reference
- Glossary and terminology
- Extension guides (new agent, skill, command)

---

## Testing Plugin Changes

```bash
/plugin marketplace remove spec2ship
/plugin marketplace add https://github.com/spec2ship/spec2ship.git#develop
/plugin install s2s@spec2ship
```
