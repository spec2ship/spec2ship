---
description: Initialize a Spec2Ship project. Use --workspace for parent directory, --workspace-hub for stack repo, --component to link to workspace.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(git:*), Read, Write, Glob, Grep, TodoWrite, AskUserQuestion
argument-hint: [--workspace | --workspace-hub | --component [path]]
---

# Initialize Spec2Ship Project

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

---

## Interpret Context

Based on the Directory contents output, determine:

- **Directory name**: Extract the last segment from the `pwd` output
- **Is git repo**: If `.git` directory appears in listing → "yes", otherwise → "no"
- **S2S already initialized**: If `.s2s` directory appears in listing → "yes", otherwise → "no"
- **Subdirectories**: Entries starting with `d` (directories) excluding `.` and `..`

If S2S is initialized, use the Read tool to check `.s2s/` contents and determine project type:
- `config.yaml` exists → standalone
- `workspace.yaml` exists → workspace
- `component.yaml` exists → component

---

## Phase 1: Determine Mode

Goal: Parse arguments and determine initialization type.

Actions:
1. Check $ARGUMENTS for flags:
   - **(no flags)**: Standalone project (but will ask about workspace relationship)
   - **--workspace**: Parent directory workspace
   - **--workspace-hub**: Stack repo as workspace hub
   - **--component [path]**: Component linking to workspace (path is optional)
2. If `--component` is present, extract the optional path argument that follows it.
3. Store the selected mode and workspace path (if any) for subsequent phases.

---

## Phase 2: Validate Environment

Goal: Check prerequisites and handle existing initialization.

Actions:
1. If S2S already initialized is "yes":
   - Warn user that .s2s/ already exists
   - Ask if they want to reinitialize using AskUserQuestion
   - If user declines, stop execution

2. For standalone mode (no flags):
   - Ask user using AskUserQuestion: "Is this project part of a workspace?"
     - Options: "No, standalone project" / "Yes, it's a component of a workspace"
   - If user selects "Yes, it's a component":
     - Ask for the workspace path using AskUserQuestion
     - Switch mode to "component" with the provided path
   - If user selects "No, standalone": continue with standalone mode

3. For workspace/workspace-hub modes:
   - If not a git repo, suggest "git init" but allow continuing

4. For component mode:
   - If workspace path was NOT provided in $ARGUMENTS:
     - Ask user for workspace path using AskUserQuestion
     - Provide examples: "../workspace", "/absolute/path/to/workspace"
   - Validate the workspace path:
     - Use Read tool to check if {workspace-path}/.s2s/workspace.yaml exists
     - If not found, report error and ask for correct path
   - Store the validated workspace path for Phase 4

---

## Phase 3: Confirm with User

Goal: Present initialization plan and get user approval.

Actions:
1. Display summary of what will be created:
   - Project type (standalone/workspace/workspace-hub/component)
   - Directories to create
   - Files to generate
   - Configuration values
2. Ask for confirmation using AskUserQuestion
3. If user declines, stop execution

---

## Phase 4: Create Structure

Goal: Generate all required files and directories.

Actions:
1. Create directory structure using Bash mkdir
2. Generate configuration files using Write tool
3. Apply mode-specific content (see Mode Specifications below)

---

## Phase 5: Output Results

Goal: Confirm success and guide next steps.

Actions:
1. Display confirmation message with created resources
2. Show relevant next steps based on project type
3. Suggest immediate actions (review config, define requirements, create plan)

---

## Mode Specifications

### Mode: Standalone Project (no flags)

**Structure**:

    .s2s/
    ├── config.yaml
    ├── CONTEXT.md
    ├── plans/
    └── state.yaml

    docs/
    ├── architecture/
    │   ├── README.md
    │   ├── components.md
    │   └── glossary.md
    ├── specifications/
    │   ├── requirements.md
    │   └── api/
    │       └── README.md
    ├── decisions/
    │   └── README.md
    └── guides/
        ├── development.md
        ├── testing.md
        └── deployment.md

    CLAUDE.md

**config.yaml**:

    name: "{directory-name}"
    type: "standalone"
    version: "0.1.0"

    git:
      branch_convention: "feature/F{id}-{slug}"
      commit_convention: "conventional"
      default_branch: "main"

    roundtable:
      default_participants:
        - software-architect
        - technical-lead
      strategy: "round-robin"

**state.yaml**:

    current_plan: null
    plans: {}
    last_sync: null

**CONTEXT.md**: Import from plugin templates or create with project overview.

**CLAUDE.md**:

    # {Project Name}

    @.s2s/CONTEXT.md

**docs/**: Use templates from plugin or create minimal stubs.

### Mode: Workspace (--workspace)

**Structure**:

    .s2s/
    ├── workspace.yaml
    ├── components.yaml
    ├── CONTEXT.md
    ├── plans/
    ├── sessions/
    └── state.yaml

    docs/
    └── (same structure as standalone)

**workspace.yaml**:

    name: "{directory-name}"
    type: "workspace"

    shared_docs:
      path: "./docs"

    git:
      branch_convention: "feature/F{id}-{slug}"
      commit_convention: "conventional"

**components.yaml**: List detected git repos from context as comments.

### Mode: Workspace Hub (--workspace-hub)

Same as workspace but:
- type: "workspace-hub" in workspace.yaml
- Component paths use "../" prefix

### Mode: Component (--component [path])

The workspace path is obtained from:
1. The path argument after `--component` (e.g., `--component ../my-workspace`)
2. Or by asking the user during Phase 2 if not provided

**Structure**:

    .s2s/
    ├── component.yaml
    └── plans/

    CLAUDE.md

**component.yaml**:

    name: "{directory-name}"
    workspace:
      path: "{workspace-path}"  # as provided by user (relative or absolute)

**CLAUDE.md**: Content referencing workspace context:

    # {Project Name}

    This is a component of workspace at {workspace-path}.

    @{workspace-path}/.s2s/CONTEXT.md

---

## Output Template

    Spec2Ship initialized successfully!

    Type: {standalone | workspace | workspace-hub | component}
    Config: .s2s/{config|workspace|component}.yaml
    Context: .s2s/CONTEXT.md
    Docs: docs/

    Next steps:
    - Review configuration in .s2s/*.yaml
    - Define requirements in docs/specifications/requirements.md
    - Start planning: /s2s:plan:new "feature name"
