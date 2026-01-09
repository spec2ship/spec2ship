---
description: Initialize or update a Spec2Ship project. Analyzes existing structure, creates .s2s/ configuration, and gathers project context.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(git:*), Read, Write, Glob, Grep, Edit, Task, TodoWrite, AskUserQuestion
argument-hint: [--workspace | --component [path]]
---

# Initialize Spec2Ship Project

This is the smart orchestrator command that runs the full initialization flow:
`detect → setup → context`

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

## Phase 1: Detect

Goal: Analyze the current project state (read-only).

Actions:

1. **If S2S NOT initialized**:
   - Scan for existing project files:
     - README.md, package.json, Cargo.toml, pyproject.toml, go.mod, etc.
     - Existing docs/ folder structure
     - Source directories (src/, lib/, app/)
   - Identify project type and tech stack
   - Store findings as **Detected Info**
   - Proceed to Phase 2 (Setup)

2. **If S2S IS initialized**:
   - Read `.s2s/config.yaml` to determine project type
   - Read `.s2s/CONTEXT.md` to get current context
   - Compare with current project state:
     - New files detected? (README changed, new config files)
     - Structure changes?
   - **If significant changes detected**:
     - Present changes to user
     - Ask using AskUserQuestion:
       - "Reinitialize structure?" / "Update CONTEXT.md only?" / "No changes needed"
     - Based on response:
       - Reinitialize → Proceed to Phase 2 with `reinit: true`
       - Update context → Run `/s2s:init:context` logic
       - No changes → Display "Project is up to date" and stop
   - **If no changes detected**:
     - Display: "Spec2Ship project is already initialized and up to date."
     - Suggest next steps based on current state
     - Stop execution

---

## Phase 2: Setup

Goal: Create or update .s2s/ structure and gather project context.

This phase merges the old `proj/init` and `discover` functionality.

### Step 2.1: Determine Mode

Parse $ARGUMENTS for flags:
- **(no flags)**: Standalone project
- **--workspace**: Parent directory workspace
- **--component [path]**: Component linking to workspace

### Step 2.2: Validate Environment

1. **Git repository check** (for standalone/workspace):
   - If NOT a git repo:
     - Ask user using AskUserQuestion: "Initialize git repository?"
     - Options: "Yes, initialize git" / "No, skip git init"
     - If yes: run `git init`

2. **For standalone mode without flags**:
   - Ask user using AskUserQuestion: "Is this project part of a workspace?"
   - Options: "No, standalone project" / "Yes, it's a component of a workspace"
   - If component, ask for workspace path and switch mode

3. **For component mode**:
   - Validate workspace path exists and has `.s2s/workspace.yaml`

### Step 2.3: Assess Project Complexity

Based on Detected Info from Phase 1, determine if project is:

**Simple project** (skip roundtable):
- Clear scope (MVP, small feature, PoC)
- Single developer or small team
- No OSS requirements
- Tech stack already defined

**Complex project** (offer roundtable):
- Enterprise or OSS project
- Multiple stakeholders
- Unclear scope or requirements
- Need to decide on structure/standards

Ask user using AskUserQuestion:
- "This looks like a {simple/complex} project. How would you like to proceed?"
- Options for complex:
  - "Quick setup (default structure)"
  - "Guided setup with roundtable discussion"
- Options for simple:
  - "Quick setup" (default)
  - "I want more customization"

### Step 2.4: Gather Context

If quick setup OR after roundtable, gather user input:

1. **Confirm/Refine Overview**:
   - Display detected info (name, description, tech stack)
   - Ask if accurate or needs refinement

2. **Business Domain**:
   - Options: E-commerce, Developer Tools, Data/Analytics, Other

3. **Objectives**:
   - New product, Modernization, Performance optimization, Adding capabilities

4. **Scope**:
   - MVP, Full implementation, Proof of concept
   - What is out of scope?

5. **Constraints**:
   - Tech stack requirements, integrations, performance, security

### Step 2.5: Create Structure

Create directory structure based on mode:

**Standalone/Workspace**:
```
.s2s/
├── config.yaml
├── CONTEXT.md
├── plans/
└── state.yaml

docs/
├── architecture/
├── specifications/
├── decisions/
└── guides/

.claude/
└── CLAUDE.md
```

**Component**:
```
.s2s/
├── component.yaml
└── plans/

.claude/
└── CLAUDE.md
```

### Step 2.6: Generate CONTEXT.md

Write `.s2s/CONTEXT.md` with gathered information:

```markdown
# Project Context

## Overview
{Project description}

## Business Domain
{Domain}

## Objectives
{Objectives as bullet points}

## Scope
**Type**: {MVP | Full | PoC}
**In scope**: ...
**Out of scope**: ...

## Constraints
{Constraints or "None identified"}

## Technical Stack
{Detected or specified stack}

## Open Questions
{Any unresolved items}

---
*Last updated: {date}*
```

---

## Phase 3: Output

Display completion message:

```
Spec2Ship initialized successfully!

Project: {name}
Type: {standalone | workspace | component}
Domain: {domain}

Created:
- .s2s/config.yaml
- .s2s/CONTEXT.md
- docs/ (architecture, specifications, decisions)

What's next?

For creative ideation:
  /s2s:brainstorm "your idea"

For requirement definition:
  /s2s:specs

For a quick task:
  /s2s:plan:create "task name"
```

---

## Roundtable During Setup (if selected)

If user selected guided setup with roundtable:

```
Task(
  subagent_type="general-purpose",
  prompt="Run a roundtable discussion to help set up this project.

Topic: Project setup for {project-name}
Strategy: consensus-driven
Workflow: setup

Participants should discuss:
1. Appropriate project structure based on detected info
2. Key objectives and scope
3. Technical constraints and decisions
4. Standards to adopt (arc42, conventional commits, etc.)

Detected project info:
{detected info from Phase 1}

Output a structured recommendation for:
- Directory structure
- Configuration values
- Initial CONTEXT.md content
- Suggested next steps"
)
```

Use roundtable output to customize setup.
