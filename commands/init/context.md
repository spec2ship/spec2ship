---
description: Update project CONTEXT.md with new information. Re-analyzes project files and optionally re-gathers user input.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(date:*), Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: [--full]
---

# Update Project Context

**Standalone utility** - can also be run via `/s2s:init --context`

Updates `.s2s/CONTEXT.md` with new information from project files or user input.

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current date: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

---

## Interpret Context

Based on the Directory contents output, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"

---

## Instructions

### Validate Environment

If S2S initialized is "NOT_S2S", display this message and stop:

```
Error: Not an s2s project. Run /s2s:init first.
```

### Read Current Context

Use Read tool to get:
1. `.s2s/CONTEXT.md` - current context content
2. `.s2s/config.yaml` (or workspace.yaml or component.yaml) - project config

Parse current CONTEXT.md to extract:
- Overview
- Business Domain
- Objectives
- Scope (type, in scope, out of scope)
- Constraints
- Technical Stack
- Open Questions
- Last updated date

### Detect Changes in Project

Scan project for changes since last update:

1. **README.md changes**:
   - Read README.md
   - Compare description with CONTEXT.md overview
   - Note significant differences

2. **Package/Config changes**:
   - Check package.json, Cargo.toml, pyproject.toml, etc.
   - Detect new dependencies
   - Detect version changes

3. **New documentation**:
   - Check docs/ for new files
   - Check for new decisions in docs/decisions/

4. **Structure changes**:
   - New source directories
   - New configuration files

Store changes as **Detected Changes**.

### Present Changes

If changes detected:

```
Context Update Analysis
═══════════════════════

Current context last updated: {date}

Detected changes:
─────────────────
{For each change}
• {Type}: {Description}
  Current: {what CONTEXT says}
  Detected: {what files show}
{/For}

No changes detected: {list what was checked}
```

### Determine Update Mode

Parse $ARGUMENTS:
- **--full**: Re-gather all user input (like initial setup)
- **(no flag)**: Smart update - only ask about detected changes

### Smart Update (default)

For each detected change, ask user using AskUserQuestion:
- "Update {section} with detected changes?"
- Show current vs detected
- Options: "Yes, update" / "No, keep current" / "Let me edit manually"

If "Let me edit manually", ask for new value.

### Full Update (--full flag)

Re-run the context gathering questions from setup:

1. Confirm/refine overview
2. Business domain
3. Objectives
4. Scope
5. Constraints

### Update CONTEXT.md

Apply all confirmed changes to CONTEXT.md:

1. Read current content
2. Use Edit tool to update each changed section
3. Update "Last updated" date
4. Update "Phase" if appropriate

### Output

Display update summary:

```
Context updated!

Changes applied:
{List of sections updated}

Unchanged:
{List of sections kept as-is}

.s2s/CONTEXT.md has been updated.

To view full context:
  Read .s2s/CONTEXT.md

Next steps based on current phase:
{Suggest appropriate next command}
```

---

## CONTEXT.md Template Reference

```markdown
# Project Context

## Overview

{2-3 sentence project description}

## Business Domain

{Domain category}

## Objectives

- {Objective 1}
- {Objective 2}
- {Objective 3}

## Scope

**Type**: {MVP | Full Implementation | Proof of Concept}

**In scope**:
- {Item 1}
- {Item 2}

**Out of scope**:
- {Item 1}
- {Item 2}

## Constraints

{Constraints or "No significant constraints identified."}

## Technical Stack

- **Language**: {language}
- **Framework**: {framework if any}
- **Package manager**: {manager}
- **Key dependencies**: {list}

## Open Questions

- {Question 1}
- {Question 2}

---
*Last updated: {ISO date}*
*Phase: {current phase}*
```
