---
description: Create Spec2Ship structure and gather project context. Use --workspace for parent workspace, --component to link to existing workspace.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(git:*), Read, Write, Glob, Grep, Edit, Task, TodoWrite, AskUserQuestion
argument-hint: [--workspace | --component [path]] [--roundtable]
---

# Setup Spec2Ship Project

**Standalone utility** - the main `/s2s:init` command includes this functionality and is preferred for most use cases.

Creates the .s2s/ directory structure and gathers project context. This command merges structure creation with context discovery.

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

---

## Interpret Context

Based on the Directory contents output, determine:

- **Directory name**: Extract the last segment from the `pwd` output
- **Is git repo**: If `.git` directory appears in listing → "yes", otherwise → "no"
- **S2S initialized**: If `.s2s` directory appears in listing → "yes", otherwise → "no"

---

## Phase 1: Validate and Determine Mode

### Step 1.1: Check Existing Initialization

If S2S initialized is "yes":
- Warn user: ".s2s/ already exists"
- Ask using AskUserQuestion:
  - "Reinitialize project?" / "Update context only (/s2s:init:context)" / "Cancel"
- If reinitialize: continue with backup warning
- If update context: redirect to /s2s:init:context
- If cancel: stop execution

### Step 1.2: Parse Arguments

Extract from $ARGUMENTS:
- **--workspace**: Initialize as workspace (manages multiple components)
- **--component [path]**: Initialize as component of workspace at path
- **--roundtable**: Force guided roundtable setup
- **(no flags)**: Standalone project

### Step 1.3: Git Repository Check

If NOT a git repo and mode is standalone or workspace:
- Ask using AskUserQuestion: "Initialize git repository?"
  - Options: "Yes, initialize git" / "No, continue without git"
- If yes: run `git init`

### Step 1.4: Workspace Relationship (standalone only)

If mode is standalone (no flags):
- Ask using AskUserQuestion: "Is this project part of a workspace?"
  - Options: "No, standalone project" / "Yes, it's a component of a workspace"
- If component:
  - Ask for workspace path
  - Switch mode to component

### Step 1.5: Validate Component Workspace

If mode is component:
- If path not provided in $ARGUMENTS, ask for it
- Validate workspace path has `.s2s/workspace.yaml`
- If invalid, report error and ask for correct path

---

## Phase 2: Analyze Project (Detection)

### Step 2.1: Scan Existing Files

Use Glob and Read to find:

1. **Project configuration**:
   - package.json, Cargo.toml, pyproject.toml, go.mod, etc.
   - Extract: name, description, dependencies

2. **Documentation**:
   - README.md → extract project description
   - docs/ structure if exists

3. **Source structure**:
   - Identify main source directories
   - Infer project type (frontend, backend, library, CLI, etc.)

4. **Tech stack indicators**:
   - Framework-specific files (next.config.js, vite.config.ts, etc.)
   - Build tools, test frameworks

Store all findings as **Detected Info**.

### Step 2.2: Determine Complexity

Based on Detected Info, assess if project is:

**Simple** (quick setup appropriate):
- Single-language project
- Clear purpose from README
- Small scope indicated
- No OSS governance files

**Complex** (roundtable may help):
- Multi-language or multi-service
- OSS project (LICENSE, CONTRIBUTING exist)
- Enterprise indicators
- Unclear scope or purpose

---

## Phase 3: Gather Context

### Step 3.1: Decide Setup Mode

If --roundtable flag OR project is complex:
- Offer roundtable: "This project could benefit from a guided discussion. Proceed with roundtable?"
- If yes: Jump to Phase 4 (Roundtable)
- If no: Continue with quick setup

### Step 3.2: Confirm Project Overview

Display Detected Info:
```
Detected Project:
  Name: {from config or directory}
  Description: {from README or config}
  Tech stack: {detected}
```

Ask using AskUserQuestion:
- "Is this information accurate?"
- Options: "Yes, continue" / "Let me provide corrections"

If corrections needed, gather:
- Project name
- Brief description (1-2 sentences)

### Step 3.3: Business Domain

Ask using AskUserQuestion:
- "What is the business domain?"
- Options:
  - "E-commerce / Retail"
  - "Developer Tools / DevOps"
  - "Data / Analytics"
  - "Web Application"
  - "Other (describe)"

### Step 3.4: Project Objectives

Ask using AskUserQuestion (multiSelect: true):
- "What are the main objectives?"
- Options:
  - "New product/feature development"
  - "Modernization/refactoring"
  - "Performance optimization"
  - "Adding capabilities to existing product"

Follow up: "Briefly describe the specific goals:"

### Step 3.5: Scope Definition

Ask using AskUserQuestion:
- "What type of project is this?"
- Options:
  - "MVP - minimal viable product, speed over completeness"
  - "Full implementation - complete feature set"
  - "Proof of concept - experimental"

Ask follow-up: "What is explicitly OUT of scope?"

### Step 3.6: Constraints

Ask using AskUserQuestion (multiSelect: true):
- "Are there technical constraints?"
- Options:
  - "Must use specific tech stack"
  - "Must integrate with existing systems"
  - "Performance requirements"
  - "Security/compliance requirements"
  - "No significant constraints"

If constraints selected, ask for details.

---

## Phase 4: Roundtable Setup (if selected)

Run a roundtable discussion for project setup:

```
Task(
  subagent_type="general-purpose",
  prompt="Facilitate a roundtable discussion for project setup.

Topic: Setting up project '{project-name}'
Strategy: consensus-driven
Workflow: setup

Detected project info:
{Detected Info}

Participants should discuss and decide:
1. Appropriate directory structure
2. Documentation standards (arc42, ADR format)
3. Key objectives and success criteria
4. Technical constraints and decisions
5. Initial task prioritization

The user should be included as a participant with their input weighted highly.

Output structured recommendations for:
- config.yaml values
- CONTEXT.md content
- Suggested initial structure
- Recommended next steps"
)
```

Use roundtable output for structure and context generation.

---

## Phase 5: Create Structure

### Step 5.1: Create Directories

**For Standalone or Workspace**:

```bash
mkdir -p .s2s/plans
mkdir -p .s2s/sessions
mkdir -p docs/architecture
mkdir -p docs/specifications
mkdir -p docs/decisions
mkdir -p docs/guides
```

**For Component**:

```bash
mkdir -p .s2s/plans
```

### Step 5.2: Generate Configuration

**Standalone config.yaml**:

```yaml
name: "{project-name}"
type: "standalone"
version: "0.1.0"

git:
  branch_convention: "feature/F{id}-{slug}"
  commit_convention: "conventional"
  default_branch: "main"

roundtable:
  strategy: "standard"
  participants:
    default:
      - software-architect
      - technical-lead
```

**Workspace workspace.yaml**:

```yaml
name: "{project-name}"
type: "workspace"

shared_docs:
  path: "./docs"

git:
  branch_convention: "feature/F{id}-{slug}"
  commit_convention: "conventional"
```

**Component component.yaml**:

```yaml
name: "{project-name}"
workspace:
  path: "{workspace-path}"
```

### Step 5.3: Generate state.yaml

```yaml
current_plan: null
plans: {}
last_sync: null
```

### Step 5.4: Generate CONTEXT.md

```markdown
# Project Context

## Overview

{Project description from user input or detected}

## Business Domain

{Domain from Step 3.3}

## Objectives

{Objectives from Step 3.4 as bullet points}

## Scope

**Type**: {MVP | Full Implementation | Proof of Concept}

**In scope**:
- {Inferred or specified items}

**Out of scope**:
- {From Step 3.5}

## Constraints

{From Step 3.6, or "No significant constraints identified."}

## Technical Stack

{Detected stack from Phase 2}

## Open Questions

- {Any unresolved items or decisions to be made}

---
*Last updated: {ISO date}*
*Phase: init*
```

### Step 5.5: Generate CLAUDE.md

Create `.claude/` directory and generate `.claude/CLAUDE.md`:

```markdown
# {Project Name}

@../.s2s/CONTEXT.md

<!-- Claude-specific directives - add as needed:

## Code Style
- Prefer composition over inheritance

## Testing
- Run tests before committing

## Project Commands
- /s2s:specs - Define requirements
- /s2s:design - Design architecture
- /s2s:plan:create - Create implementation plan
-->
```

### Step 5.6: Generate docs/ Structure

Create starter files in docs/:

- `docs/architecture/README.md` - Architecture overview template
- `docs/specifications/requirements.md` - Requirements template
- `docs/decisions/README.md` - ADR index template
- `docs/guides/development.md` - Development guide template

---

## Phase 6: Output

Display completion message:

```
Spec2Ship setup complete!

Project: {name}
Type: {standalone | workspace | component}
Domain: {domain}

Created:
- .s2s/config.yaml (or workspace.yaml or component.yaml)
- .s2s/CONTEXT.md
- .s2s/state.yaml
- docs/ structure
- .claude/CLAUDE.md

What's next?

For creative ideation:
  /s2s:brainstorm "your idea"

To define requirements:
  /s2s:specs

To design architecture:
  /s2s:design

For a quick task:
  /s2s:plan:create "task name"
```
