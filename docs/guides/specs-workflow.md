# Specs Workflow Guide

The specs workflow uses a roundtable discussion to define requirements for your project.

## Overview

```bash
/s2s:specs [--strategy <name>] [--participants <list>] [--verbose] [--interactive] [--diagnostic]
```

**Purpose**: Define what to build through collaborative discussion.

**Output**: `docs/specifications/requirements.md`

## Prerequisites

1. Project initialized with `/s2s:init`
2. `.s2s/CONTEXT.md` populated with project description

## Default Configuration

| Setting | Value |
|---------|-------|
| Strategy | `consensus-driven` |
| Participants | product-manager, business-analyst, qa-lead |
| Minimum rounds | 3 |

## What Gets Discussed

The roundtable covers these topics (agenda):

1. **User Personas & Workflows** - Who uses the system and how
2. **Functional Requirements** - What the system must do
3. **Non-Functional Requirements** - Quality attributes (performance, security, etc.)
4. **Business Rules** - Domain constraints and policies
5. **Exclusions** - What's explicitly out of scope
6. **Acceptance Criteria** - How to verify requirements

## Running the Workflow

### Basic Usage

```bash
/s2s:specs
```

The roundtable will:
1. Generate questions based on your project context
2. Collect perspectives from participants
3. Synthesize into requirements
4. Continue until all topics are covered (minimum 3 rounds)

### With Options

```bash
# See detailed output
/s2s:specs --verbose

# Control each round manually
/s2s:specs --interactive

# Use different strategy
/s2s:specs --strategy debate

# Add security perspective
/s2s:specs --participants +security-champion
```

## Understanding the Output

### During Discussion

After each round, you'll see:
- Round number and topic
- Key decisions made
- Artifacts created/updated
- Next action (continue, conclude, etc.)

### Final Output

The `docs/specifications/requirements.md` contains:

```markdown
# Software Requirements Specification

## 1. Introduction
- Purpose
- Scope
- Definitions

## 2. User Personas
- REQ-001: Primary persona
- REQ-002: Secondary persona

## 3. Functional Requirements
- REQ-003: Feature 1
- REQ-004: Feature 2

## 4. Non-Functional Requirements
- NFR-001: Performance
- NFR-002: Security

## 5. Business Rules
- BR-001: Rule 1

## 6. Exclusions
- EX-001: Out of scope item

## 7. Open Questions
- OQ-001: Unresolved item
```

## Interactive Mode

With `--interactive`, you can control the discussion:

```
Round 2 Complete
━━━━━━━━━━━━━━━━
Topic: Functional Requirements
Artifacts: REQ-003, REQ-004 created
Consensus: 85%

What would you like to do?
› continue - Proceed to next round
  skip     - Skip to next topic
  exit     - Save and exit
```

## Handling Conflicts

When participants disagree:

1. **Conflict recorded** as `CONF-*` artifact
2. **Both positions preserved** with rationale
3. **Facilitator attempts resolution** in subsequent rounds
4. **Escalation** if unresolved after 3 rounds

## Tips for Better Results

### Before Running

1. **Complete CONTEXT.md** - Include business domain, users, constraints
2. **Have requirements inputs** - User stories, stakeholder notes, etc.
3. **Know your priorities** - Must-have vs nice-to-have

### During Discussion

1. **Use interactive mode** for important projects
2. **Skip topics** you've already covered elsewhere
3. **Stop when needed** - sessions can be resumed

### After Completion

1. **Review the output** - Check requirements make sense
2. **Validate the session** - `/s2s:session:validate`
3. **Proceed to design** - `/s2s:design`

## Troubleshooting

### "Missing project context"

Run `/s2s:init` first to create CONTEXT.md.

### Requirements too vague

Add more detail to CONTEXT.md before re-running.

### Discussion goes in circles

Use `--interactive` and skip stuck topics, or add `--participants +technical-lead` for different perspectives.

---

*See also: [Command Reference](../reference/commands.md) | [Concepts: Sessions](../concepts/sessions.md)*
