# Command Reference

Complete reference for all Spec2Ship commands.

## Initialization

### `/s2s:init`

Initialize or update a Spec2Ship project.

```bash
/s2s:init
```

**What it does**:
- Detects project tech stack
- Creates `.s2s/` configuration directory
- Generates `CONTEXT.md` and `CLAUDE.md`

**Flags**: None

---

## Roundtable Workflows

### `/s2s:specs`

Define requirements through roundtable discussion.

```bash
/s2s:specs [--strategy <name>] [--participants <list>] [--verbose] [--interactive] [--diagnostic]
```

**Default strategy**: `consensus-driven`

**Default participants**: `product-manager`, `business-analyst`, `qa-lead`

**Output**: `docs/specifications/requirements.md`

### `/s2s:design`

Design architecture through roundtable discussion.

```bash
/s2s:design [--strategy <name>] [--participants <list>] [--verbose] [--interactive] [--diagnostic]
```

**Default strategy**: `debate`

**Default participants**: `software-architect`, `technical-lead`, `devops-engineer`

**Output**: `docs/architecture/`

### `/s2s:brainstorm "topic"`

Creative exploration of ideas.

```bash
/s2s:brainstorm "topic" [--participants <list>] [--verbose] [--interactive] [--diagnostic]
```

**Strategy**: `disney` (fixed)

**Default participants**: `product-manager`, `software-architect`, `technical-lead`, `devops-engineer`

**Output**: `.s2s/sessions/{id}-summary.md`

---

## Session Management

### `/s2s:session`

Show current roundtable session.

```bash
/s2s:session
```

### `/s2s:session:list`

List all roundtable sessions.

```bash
/s2s:session:list
```

### `/s2s:session:status [id]`

Show detailed session information.

```bash
/s2s:session:status
/s2s:session:status 20260111-specs-my-project
```

### `/s2s:session:validate [id]`

Validate session consistency.

```bash
/s2s:session:validate
/s2s:session:validate --level deep
/s2s:session:validate 20260111-specs-my-project
```

**Levels**:
- `structural` (default): Fast, deterministic checks
- `deep`: Includes LLM-based semantic analysis

### `/s2s:session:cleanup`

Remove old or abandoned sessions.

```bash
/s2s:session:cleanup
/s2s:session:cleanup --older-than 7d
```

---

## Ad-hoc Roundtable

### `/s2s:roundtable:start "topic"`

Start a standalone roundtable discussion.

```bash
/s2s:roundtable:start "topic" [--strategy <name>] [--participants <list>] [--verbose] [--interactive]
```

### `/s2s:roundtable:list`

List all roundtable sessions.

```bash
/s2s:roundtable:list
```

### `/s2s:roundtable:resume`

Resume a paused roundtable session.

```bash
/s2s:roundtable:resume
/s2s:roundtable:resume --session <id>
```

---

## Plan Management

### `/s2s:plan:create "name"`

Create a new implementation plan.

```bash
/s2s:plan:create "feature-name"
/s2s:plan:create "feature-name" --branch
```

**Flags**:
- `--branch`: Also create a git feature branch

### `/s2s:plan:list`

List all implementation plans.

```bash
/s2s:plan:list
```

### `/s2s:plan:start`

Start working on an implementation plan.

```bash
/s2s:plan:start
/s2s:plan:start --plan <id>
```

### `/s2s:plan:complete`

Mark a plan as completed.

```bash
/s2s:plan:complete
/s2s:plan:complete --merge
```

**Flags**:
- `--merge`: Also merge the feature branch

---

## Common Flags

| Flag | Description | Available In |
|------|-------------|--------------|
| `--verbose` | Include detailed output in session files | specs, design, brainstorm, roundtable:start |
| `--interactive` | Pause after each round for user input | specs, design, brainstorm, roundtable:start |
| `--diagnostic` | Enable debugging output | specs, design, brainstorm |
| `--strategy <name>` | Override default strategy | specs, design, roundtable:start |
| `--participants <list>` | Override default participants | specs, design, brainstorm, roundtable:start |

## Participant List Format

```bash
# Comma-separated list
--participants architect,tech-lead,qa-lead

# Add to defaults (prefix with +)
--participants +security-champion

# Available participants
product-manager, business-analyst, qa-lead, ux-researcher,
software-architect, technical-lead, devops-engineer, security-champion,
documentation-specialist, claude-code-expert, oss-community-manager
```

## Strategy Options

```bash
--strategy standard
--strategy disney
--strategy debate
--strategy consensus-driven
--strategy six-hats
```

---

*See also: [Configuration](./configuration.md) | [Concepts](../concepts/)*
