---
name: Spec2Ship Guide
description: "This skill should be used when the user asks 'what is s2s', 'how do I use specs',
  'which command for requirements', 'difference between specs and design', 'how to create custom agent',
  'extend s2s', 'add new command', 'workspace vs standalone', 'what are roundtables',
  'how does facilitator work', 'come funziona s2s', 'quale comando uso', 'come estendo il plugin'.
  Provides comprehensive guidance on Spec2Ship usage and extension."
version: 1.0.0
---

# Spec2Ship Guide

## Purpose

This skill provides guidance on using and extending Spec2Ship (s2s), a Claude Code plugin that automates the software development lifecycle through AI-facilitated roundtable discussions.

## What is Spec2Ship?

Spec2Ship guides software development through structured phases:

```
/s2s:init → /s2s:specs → /s2s:design → /s2s:plan → Implementation
  Setup      Define        Design        Plan         Build
             WHAT          HOW           STEPS
```

**Key concept**: Each phase uses a **roundtable** - multiple AI agents with different perspectives discuss and produce artifacts.

## Workflow Overview

| Phase | Command | Purpose | Output |
|-------|---------|---------|--------|
| **Init** | `/s2s:init` | Setup project context | `.s2s/`, `CLAUDE.md` |
| **Specs** | `/s2s:specs` | Define requirements | `requirements.md` |
| **Design** | `/s2s:design` | Design architecture | `architecture.md`, ADRs |
| **Plan** | `/s2s:plan --new` | Create implementation plan | `plans/*.md` |
| **Brainstorm** | `/s2s:brainstorm "topic"` | Creative exploration | Session summary |

### When to Use Each Command

- **Need to start a new project?** → `/s2s:init`
- **Need to define what to build?** → `/s2s:specs`
- **Need to decide how to build it?** → `/s2s:design`
- **Need to break work into tasks?** → `/s2s:plan --new "feature"`
- **Need creative exploration?** → `/s2s:brainstorm "topic"`
- **Need ad-hoc technical discussion?** → `/s2s:roundtable "topic"`

## Commands Quick Reference

### Workflow Commands

```bash
/s2s:init                           # Initialize project
/s2s:specs                          # Define requirements (roundtable)
/s2s:design                         # Design architecture (roundtable)
/s2s:brainstorm "topic"             # Creative exploration (roundtable)
/s2s:plan --new "feature"           # Create implementation plan
/s2s:roundtable "topic"             # Ad-hoc discussion
```

### Session Management

```bash
/s2s:session                        # Current session status
/s2s:session:list                   # List all sessions
/s2s:session:close                  # Close active session
/s2s:session:validate               # Validate session consistency
```

### Plan Management

```bash
/s2s:plan:list                      # List all plans
/s2s:plan --session                 # Work on a plan
/s2s:plan:close                     # Close current plan
```

### Common Flags

| Flag | Purpose |
|------|---------|
| `--verbose` | Detailed output in session files |
| `--interactive` | Pause after each round |
| `--strategy <name>` | Override strategy (standard, disney, debate, consensus-driven, six-hats) |
| `--participants <list>` | Override participants |

## Roundtables Explained

A **roundtable** is an AI-facilitated discussion between specialized agents:

1. **Facilitator** generates a question
2. **Participants** respond in parallel (prevents groupthink)
3. **Facilitator** synthesizes responses into artifacts
4. Repeat until agenda complete

### Default Participants by Workflow

| Workflow | Default Participants |
|----------|---------------------|
| specs | product-manager, business-analyst, qa-lead |
| design | software-architect, technical-lead, devops-engineer |
| brainstorm | product-manager, architect, tech-lead, devops |

### Available Strategies

| Strategy | Best For |
|----------|----------|
| `standard` | General discussions |
| `consensus-driven` | Fast convergence (specs default) |
| `debate` | Evaluating trade-offs (design default) |
| `disney` | Creative exploration (brainstorm, fixed) |
| `six-hats` | Comprehensive analysis |

## Workspace vs Standalone

**Standalone**: Single project, independent.

```
my-project/
└── .s2s/
```

**Workspace**: Multiple related components coordinated together.

```
workspace/
├── .s2s/                    # Workspace-level
│   └── workspace.yaml
├── frontend/
│   └── .s2s/                # Component-level
└── backend/
    └── .s2s/
```

Run `/s2s:init` with `--workspace` flag or let init detect the structure.

## Extending Spec2Ship

Three extension types:

| Type | Location | Guide |
|------|----------|-------|
| **Agent** | `agents/roundtable/*.md` | `examples/new-agent.md` |
| **Skill** | `skills/**/SKILL.md` | `examples/new-skill.md` |
| **Command** | `commands/*.md` | `examples/new-command.md` |

### Critical Pattern: Agent Invocation

```markdown
# CORRECT - Invokes the agent file
**Use the roundtable-facilitator agent** with this input:

# WRONG - Creates generic agent without config
Task(subagent_type="general-purpose", prompt="You are a facilitator...")
```

## Additional Resources

### References (Detailed Documentation)

| File | Content |
|------|---------|
| `references/workflows.md` | Detailed workflow explanations |
| `references/commands.md` | Complete command reference |
| `references/glossary.md` | Terminology and artifact types |
| `references/extension-patterns.md` | LLM patterns for writing commands |
| `references/naming-conventions.md` | ID formats and naming rules |
| `references/state-machine.md` | State transitions |
| `references/workspace.md` | Workspace architecture |

### Examples (Step-by-Step Guides)

| File | Content |
|------|---------|
| `examples/new-agent.md` | Create a new roundtable participant |
| `examples/new-skill.md` | Create a new knowledge skill |
| `examples/new-command.md` | Create a new slash command |

## Troubleshooting

### "Session not found"

Run `/s2s:session:list` to see available sessions, then resume with the correct ID.

### "No requirements.md found"

Run `/s2s:specs` first to define requirements before design.

### "Agent not responding correctly"

Check that agents are invoked with `**Use the roundtable-X agent**` pattern, not with generic Task prompts.

### "Roundtable stuck in loop"

Check `min_rounds` and `max_rounds` in config.yaml. Sessions automatically close after max_rounds.
