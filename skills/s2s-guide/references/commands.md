# Commands Reference

Complete reference for all Spec2Ship commands.

## Initialization

### `/s2s:init`

Initialize or update a Spec2Ship project.

```bash
/s2s:init
/s2s:init --workspace     # Initialize as workspace
```

**What it does**:
- Detects project tech stack
- Creates `.s2s/` configuration directory
- Generates `CONTEXT.md` and `CLAUDE.md`
- For workspaces: creates `workspace.yaml`

---

## Roundtable Workflows

### `/s2s:specs`

Define requirements through roundtable discussion.

```bash
/s2s:specs
/s2s:specs --strategy consensus-driven
/s2s:specs --participants pm,ba,qa
/s2s:specs --verbose --interactive
```

**Default strategy**: `consensus-driven`
**Default participants**: `product-manager`, `business-analyst`, `qa-lead`
**Output**: `.s2s/requirements.md`

---

### `/s2s:design`

Design architecture through roundtable discussion.

```bash
/s2s:design
/s2s:design --strategy debate
/s2s:design --participants architect,tech-lead,security
```

**Default strategy**: `debate`
**Default participants**: `software-architect`, `technical-lead`, `devops-engineer`
**Output**: `.s2s/architecture.md` + `.s2s/decisions/`

---

### `/s2s:brainstorm "topic"`

Creative exploration of ideas.

```bash
/s2s:brainstorm "New authentication approach"
/s2s:brainstorm "topic" --participants +security-champion
```

**Strategy**: `disney` (fixed, cannot be overridden)
**Default participants**: `product-manager`, `software-architect`, `technical-lead`, `devops-engineer`
**Output**: `.s2s/sessions/{id}-summary.md`

---

### `/s2s:roundtable "topic"`

Start a standalone roundtable discussion.

```bash
/s2s:roundtable "API versioning strategy"
/s2s:roundtable "topic" --strategy debate
/s2s:roundtable --session              # Resume active session
/s2s:roundtable --session <id>         # Resume specific session
```

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
```

**Levels**:
- `structural` (default): Fast, deterministic checks
- `deep`: Includes LLM-based semantic analysis

### `/s2s:session:close [id]`

Close a session.

```bash
/s2s:session:close
/s2s:session:close 20260111-specs-my-project
```

### `/s2s:session:cleanup`

Remove old sessions.

```bash
/s2s:session:cleanup
/s2s:session:cleanup --older-than 7d
```

---

## Plan Management

### `/s2s:plan --new "name"`

Create a new implementation plan.

```bash
/s2s:plan --new "user-authentication"
/s2s:plan --new "feature" --branch     # Also create git branch
```

### `/s2s:plan:list`

List all implementation plans.

```bash
/s2s:plan:list
```

### `/s2s:plan --session`

Start working on an implementation plan.

```bash
/s2s:plan --session
/s2s:plan --session <id>
```

### `/s2s:plan:close`

Close a plan.

```bash
/s2s:plan:close
/s2s:plan:close --merge     # Also merge feature branch
```

---

## Common Flags

| Flag | Description | Available In |
|------|-------------|--------------|
| `--verbose` | Detailed output in session files | specs, design, brainstorm, roundtable |
| `--interactive` | Pause after each round | specs, design, brainstorm, roundtable |
| `--diagnostic` | Enable debugging output | specs, design, brainstorm |
| `--strategy <name>` | Override default strategy | specs, design, roundtable |
| `--participants <list>` | Override participants | specs, design, brainstorm, roundtable |

---

## Participant List Format

```bash
# Comma-separated list (replaces defaults)
--participants architect,tech-lead,qa-lead

# Add to defaults (prefix with +)
--participants +security-champion

# Available participants
product-manager, business-analyst, qa-lead, ux-researcher,
software-architect, technical-lead, devops-engineer, security-champion,
documentation-specialist, claude-code-expert, oss-community-manager
```

---

## Strategy Options

```bash
--strategy standard           # Balanced default
--strategy disney             # Dreamer→Realist→Critic
--strategy debate             # Pro vs Con
--strategy consensus-driven   # Fast convergence
--strategy six-hats           # Six perspectives
```
