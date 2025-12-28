---
description: Initialize a new Spec2Ship project or workspace. Use --workspace for parent directory workspace, --workspace-hub for stack repo hub, --component to link to existing workspace.
allowed-tools: Bash(*), Read, Write, Glob, Grep
argument-hint: [--workspace | --workspace-hub | --component]
---

# Initialize Spec2Ship Project

## Arguments

Parse `$ARGUMENTS` for flags:
- `--workspace`: Initialize parent directory as workspace (non-git)
- `--workspace-hub`: Initialize current repo as workspace hub (stack repo pattern)
- `--component`: Initialize as component linking to existing workspace
- (no flag): Initialize as standalone project

## Workflow

### Step 1: Detect Current State

Check what already exists:

```bash
# Check for existing s2s initialization
ls -la .s2s/ 2>/dev/null
```

If `.s2s/` exists, warn user and ask if they want to reinitialize.

### Step 2: Detect Git Repository

```bash
git rev-parse --git-dir 2>/dev/null
```

- If NOT a git repo and NOT `--workspace`: Warn and ask if user wants to `git init`
- If `--workspace` flag: Parent directory mode (no git required)

### Step 3: For Standalone Project (no flags)

Create the following structure:

```
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
```

#### config.yaml content:

```yaml
name: "{project-name}"          # From directory name or ask user
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
  human_in_loop:
    - business_priority
    - unresolved_tradeoff
```

#### state.yaml content:

```yaml
current_plan: null
plans: {}
last_sync: null
```

#### CONTEXT.md content:

```markdown
# {Project Name} - S2S Context

This file is automatically maintained by Spec2Ship.

## Project Structure

- Architecture: `docs/architecture/`
- Requirements: `docs/specifications/requirements.md`
- API Specs: `docs/specifications/api/`
- Decisions: `docs/decisions/`
- Guides: `docs/guides/`

## Active Plans

@.s2s/plans/

## S2S Commands

Use `/s2s:*` commands for development workflow:
- `/s2s:plan:new "topic"` - Create implementation plan
- `/s2s:plan:start "id"` - Start working on plan
- `/s2s:decision:new "topic"` - Create architecture decision
- `/s2s:roundtable:start "topic"` - Start discussion session
```

#### CLAUDE.md content:

```markdown
# {Project Name}

@.s2s/CONTEXT.md
```

### Step 4: For Workspace (--workspace flag)

Must be run from parent directory containing component repos.

Create:

```
.s2s/
├── workspace.yaml
├── components.yaml
├── CONTEXT.md
├── plans/
├── sessions/
└── state.yaml

docs/
├── architecture/
├── specifications/
└── decisions/
```

#### workspace.yaml content:

```yaml
name: "{workspace-name}"        # From directory name or ask user
type: "workspace"

shared_docs:
  path: "./docs"

git:
  branch_convention: "feature/F{id}-{slug}"
  commit_convention: "conventional"

roundtable:
  default_scope: "workspace"
  default_participants:
    - software-architect
    - technical-lead
  strategy: "round-robin"
```

#### components.yaml content:

Detect subdirectories that are git repos:

```bash
for dir in */; do
  if [ -d "$dir/.git" ]; then
    echo "- name: ${dir%/}"
    echo "  path: ./${dir%/}"
    echo "  type: component"
  fi
done
```

Generate:

```yaml
components: []
# Add components using /s2s:proj:add-component
# Or manually edit this file

# Example:
# components:
#   - name: "component-a"
#     path: "./component-a"
#     type: "service"
#     implements: []
#     dependencies: []
```

### Step 5: For Workspace Hub (--workspace-hub flag)

Current repo becomes the workspace hub (stack repo pattern).

Create same structure as workspace but with:

```yaml
# workspace.yaml
type: "workspace-hub"

shared_docs:
  path: "./docs"

# Components are peer repos (relative paths go up)
# components:
#   - name: "component-a"
#     path: "../component-a"
```

### Step 6: For Component (--component flag)

Link to existing workspace.

First, detect workspace:

```bash
# Check parent directory
if [ -f "../.s2s/workspace.yaml" ]; then
  echo "Found workspace in parent directory"
  WORKSPACE_PATH=".."
  WORKSPACE_TYPE="parent-directory"
fi

# Check sibling directories for workspace-hub
for dir in ../*; do
  if [ -f "$dir/.s2s/workspace.yaml" ]; then
    TYPE=$(grep "type:" "$dir/.s2s/workspace.yaml" | head -1)
    if [[ "$TYPE" == *"workspace-hub"* ]]; then
      echo "Found workspace hub at $dir"
      WORKSPACE_PATH="$dir"
      WORKSPACE_TYPE="peer-repo"
    fi
  fi
done
```

If no workspace found, ask user for path.

Create minimal structure:

```
.s2s/
├── component.yaml
└── plans/

CLAUDE.md
```

#### component.yaml content:

```yaml
name: "{component-name}"        # From directory name
workspace:
  type: "{workspace-type}"      # parent-directory or peer-repo
  path: "{workspace-path}"      # Relative path to workspace
```

#### CLAUDE.md content:

```markdown
# {Component Name}

## Workspace Context
@{workspace-path}/.s2s/CONTEXT.md

## Component Plans
@.s2s/plans/
```

### Step 7: Create Documentation Templates

For all project types, create appropriate doc templates from `templates/docs/`.

### Step 8: Output Summary

Report what was created:

```
Spec2Ship initialized successfully!

Type: {standalone | workspace | workspace-hub | component}
Config: .s2s/{config|workspace|component}.yaml
Docs: docs/
Context: .s2s/CONTEXT.md

Next steps:
- Review and customize .s2s/*.yaml
- Define requirements in docs/specifications/requirements.md
- Start planning with /s2s:plan:new "feature name"
```
