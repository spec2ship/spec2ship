# Plan Workflow Guide

The plan workflow helps you create and execute implementation plans based on your specs and architecture.

## Overview

Plans break features into actionable tasks with clear steps and dependencies.

### Commands

| Command | Description |
|---------|-------------|
| `/s2s:plan:create "name"` | Create a new implementation plan |
| `/s2s:plan:list` | List all plans |
| `/s2s:plan:start` | Start working on a plan |
| `/s2s:plan:complete` | Mark plan as completed |

## Creating a Plan

### Basic Usage

```bash
/s2s:plan:create "user-authentication"
```

This will:
1. Analyze requirements from `docs/specifications/`
2. Review architecture from `docs/architecture/`
3. Generate a step-by-step implementation plan
4. Save to `.s2s/plans/`

### With Git Branch

```bash
/s2s:plan:create "user-authentication" --branch
```

Also creates a feature branch: `feature/F01-user-authentication`

## Plan Structure

Plans are stored in `.s2s/plans/` as YAML files:

```yaml
# .s2s/plans/20260111-143022-user-authentication.yaml
id: "20260111-143022-user-authentication"
name: "user-authentication"
status: "pending"  # pending | active | completed | abandoned

created: "2026-01-11T14:30:22Z"
branch: "feature/F01-user-authentication"

requirements:
  - REQ-003  # User login
  - REQ-004  # Session management

tasks:
  - id: 1
    title: "Create User model"
    status: pending
    description: |
      Define User entity with fields: id, email, password_hash, created_at
    files:
      - src/models/user.ts
    depends_on: []

  - id: 2
    title: "Implement password hashing"
    status: pending
    description: |
      Add bcrypt-based password hashing utility
    files:
      - src/utils/password.ts
    depends_on: [1]

  - id: 3
    title: "Create auth endpoints"
    status: pending
    description: |
      POST /auth/register
      POST /auth/login
      POST /auth/logout
    files:
      - src/routes/auth.ts
      - src/controllers/auth.ts
    depends_on: [1, 2]
```

## Listing Plans

```bash
/s2s:plan:list
```

Output:

```
Implementation Plans
━━━━━━━━━━━━━━━━━━━

Active:
  → 20260111-143022-user-authentication (3/8 tasks)
    Branch: feature/F01-user-authentication

Pending:
  • 20260111-150000-api-versioning (0/5 tasks)

Completed:
  ✓ 20260110-120000-project-setup (5/5 tasks)
```

## Starting a Plan

### Start the Active Plan

```bash
/s2s:plan:start
```

If there's an active plan, continues from where you left off.

### Start a Specific Plan

```bash
/s2s:plan:start --plan 20260111-143022-user-authentication
```

### What Happens

When you start a plan:

1. **Branch checkout** - Switches to the plan's feature branch (if exists)
2. **Context loading** - Reads requirements and architecture
3. **Task guidance** - Shows current task with context
4. **Progress tracking** - Updates task status as you work

## Working Through Tasks

When a plan is active, you'll receive guidance for each task:

```
Current Task: Create User model
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Description:
Define User entity with fields: id, email, password_hash, created_at

Files to create/modify:
- src/models/user.ts

Related requirements:
- REQ-003: Users must be able to register with email

Architecture context:
- ARCH-002: Use TypeScript with strict mode
- ARCH-005: Models in src/models/

Ready to implement? Ask me to help with this task or say "done" when complete.
```

## Completing Tasks

As you complete tasks, the plan is updated automatically. The system tracks:
- Task completion status
- Files modified
- Time spent

## Completing a Plan

When all tasks are done:

```bash
/s2s:plan:complete
```

This will:
1. Mark the plan as completed
2. Update `.s2s/state.yaml`
3. Optionally merge the feature branch

### With Merge

```bash
/s2s:plan:complete --merge
```

Also merges the feature branch to develop/main.

## Plan States

| State | Description |
|-------|-------------|
| `pending` | Created but not started |
| `active` | Currently being worked on |
| `completed` | All tasks done |
| `abandoned` | Cancelled before completion |

## Best Practices

### Plan Granularity

- **Too big**: "Implement the entire backend" - hard to track
- **Too small**: "Add semicolon to line 42" - overhead not worth it
- **Just right**: "Implement user authentication" - clear scope, multiple tasks

### Task Dependencies

Define dependencies to ensure correct order:

```yaml
tasks:
  - id: 1
    title: "Create database schema"
    depends_on: []  # No dependencies

  - id: 2
    title: "Create models"
    depends_on: [1]  # Needs schema first

  - id: 3
    title: "Create API endpoints"
    depends_on: [2]  # Needs models first
```

### Using Branches

Always use `--branch` for features that will be reviewed:

```bash
/s2s:plan:create "new-feature" --branch
```

Benefits:
- Clean git history
- Easy to review
- Can be abandoned without affecting main

## Troubleshooting

### "No active plan"

Either start a plan or specify which one:

```bash
/s2s:plan:start --plan <plan-id>
```

### Plan seems outdated

If requirements or architecture changed significantly:
1. Complete or abandon the old plan
2. Create a new plan that reflects current state

### Stuck on a task

Ask for help with the specific task. The system has context about:
- What the task requires
- Related requirements
- Architecture decisions

## Integration with Other Workflows

### Typical Flow

```
/s2s:init                        # Setup project
    ↓
/s2s:specs                       # Define requirements
    ↓
/s2s:design                      # Design architecture
    ↓
/s2s:plan:create "feature"       # Create implementation plan
    ↓
/s2s:plan:start                  # Start working
    ↓
(implement tasks)
    ↓
/s2s:plan:complete --merge       # Complete and merge
```

### Multiple Plans

You can have multiple pending plans but only one active:

```bash
# Create several plans
/s2s:plan:create "auth" --branch
/s2s:plan:create "api" --branch
/s2s:plan:create "frontend" --branch

# Work on one at a time
/s2s:plan:start --plan <auth-id>
# ... complete auth ...

/s2s:plan:start --plan <api-id>
# ... complete api ...
```

---

*See also: [Specs Workflow](./specs-workflow.md) | [Design Workflow](./design-workflow.md) | [Session Management](./session-management.md)*