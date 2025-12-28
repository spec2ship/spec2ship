---
name: s2s-core
description: Core Spec2Ship skill for project initialization, implementation planning, and git workflow automation. Use this skill when working with s2s projects, creating implementation plans, or coordinating multi-repo development.
version: 0.1.0
---

# Spec2Ship Core Skill

## Overview

Spec2Ship (s2s) automates the full software development lifecycle:
- **Spec**: Define requirements, architecture, and decisions via roundtable discussions
- **Ship**: Execute implementation plans with automated git workflows

## Project Detection

Before any s2s operation, detect the project type:

1. **Single Project**: `.s2s/config.yaml` exists with `type: standalone`
2. **Workspace Hub**: `.s2s/workspace.yaml` exists with `type: workspace-hub`
3. **Parent Workspace**: Parent directory has `.s2s/workspace.yaml` with `type: workspace`
4. **Component**: `.s2s/component.yaml` exists (links to workspace)
5. **Not Initialized**: None of the above exist

## File Naming Convention

All timestamped files use format: `YYYYMMDD-HHMMSS-slug.md`

Generate timestamp using local time:
```bash
date +"%Y%m%d-%H%M%S"
```

Generate slug from topic:
- Convert to lowercase
- Replace spaces with hyphens
- Remove special characters
- Truncate to 50 chars max

## Git Operations

Before any git operation:
1. Verify git repository exists: `git rev-parse --git-dir`
2. Check for clean working tree: `git status --porcelain`
3. If dirty, warn user and offer to stash

Branch naming convention:
- Features: `feature/F{NN}-{slug}`
- Hotfixes: `hotfix/H{NN}-{slug}`
- Releases: `release/v{X.Y.Z}`

Get next feature number:
```bash
git branch --list 'feature/F*' | wc -l | xargs expr 1 +
```

## Key Paths

| Type | Single Project | Workspace | Component |
|------|----------------|-----------|-----------|
| Config | `.s2s/config.yaml` | `.s2s/workspace.yaml` | `.s2s/component.yaml` |
| Plans | `.s2s/plans/` | `.s2s/plans/` | `.s2s/plans/` |
| Sessions | `.s2s/sessions/` | `.s2s/sessions/` | (use workspace) |
| Context | `.s2s/CONTEXT.md` | `.s2s/CONTEXT.md` | (import workspace) |
| Docs | `docs/` | `docs/` | `docs/` (optional) |
| Decisions | `docs/decisions/` | `docs/decisions/` | (use workspace) |

## State Management

State is tracked in `.s2s/state.yaml`:

```yaml
current_plan: null                    # ID of active plan (or null)
plans:
  "20240115-143022-user-auth":
    status: "active"                  # planning | active | completed | blocked
    branch: "feature/F01-user-auth"
    created: "2024-01-15T14:30:22Z"
    updated: "2024-01-15T16:45:00Z"
```

## Multi-Repo Coordination

When in a workspace context:

1. Load `workspace.yaml` to get component list
2. For branch operations, iterate all components
3. Verify each component is clean before proceeding
4. Record operations in workspace `state.yaml`

## Error Handling

On any error:
1. Report clearly what failed
2. Suggest recovery action
3. Do NOT proceed with partial state
4. If git operation failed mid-way, list which repos succeeded/failed
