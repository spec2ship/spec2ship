---
description: List all implementation plans with their status.
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
argument-hint: [--status planning|active|completed|blocked]
---

# List Implementation Plans

## Arguments

- `--status <status>`: Filter by status (planning, active, completed, blocked)
- (no args): Show all plans

## Workflow

### Step 1: Validate Environment

```bash
if [ ! -d ".s2s/plans" ]; then
  echo "No plans directory found."
  echo "Use /s2s:plan:new to create your first plan."
  exit 0
fi
```

### Step 2: Collect Plan Information

For each plan file in `.s2s/plans/`:

```bash
for plan_file in .s2s/plans/*.md; do
  [ -f "$plan_file" ] || continue

  # Extract plan ID from filename
  PLAN_ID=$(basename "$plan_file" .md)

  # Extract metadata from file
  TOPIC=$(grep "^# Implementation Plan:" "$plan_file" | sed 's/^# Implementation Plan: //')
  STATUS=$(grep "^\\*\\*Status\\*\\*:" "$plan_file" | sed 's/.*: //')
  BRANCH=$(grep "^\\*\\*Branch\\*\\*:" "$plan_file" | sed 's/.*: //' | tr -d '`')
  CREATED=$(grep "^\\*\\*Created\\*\\*:" "$plan_file" | sed 's/.*: //')

  # Count tasks
  TOTAL_TASKS=$(grep -c "^- \\[" "$plan_file" || echo "0")
  DONE_TASKS=$(grep -c "^- \\[x\\]" "$plan_file" || echo "0")

  # Output
  echo "$PLAN_ID|$STATUS|$TOPIC|$BRANCH|$TOTAL_TASKS|$DONE_TASKS|$CREATED"
done
```

### Step 3: Filter by Status (if requested)

```bash
if [ -n "$STATUS_FILTER" ]; then
  # Filter results by status column
  RESULTS=$(echo "$RESULTS" | grep "|${STATUS_FILTER}|")
fi
```

### Step 4: Format Output

Display as a formatted table:

```
Implementation Plans
====================

Active:
  * 20240115-143022-user-auth
    Topic: User Authentication
    Branch: feature/F01-user-auth
    Progress: 3/7 tasks
    Started: 2024-01-15

Planning:
  - 20240116-091500-api-versioning
    Topic: API Versioning Strategy
    Branch: (none)
    Tasks: 0 defined

Completed:
  ✓ 20240110-100000-project-setup
    Topic: Initial Project Setup
    Completed: 2024-01-12
    Duration: 2 days

Total: 3 plans (1 active, 1 planning, 1 completed)
```

### Step 5: Highlight Current Plan

If `.s2s/state.yaml` has a `current_plan`, mark it with `*` or highlight.

```bash
CURRENT_PLAN=$(grep "current_plan:" .s2s/state.yaml 2>/dev/null | awk '{print $2}')
```

## Output Formatting

- **Active plans**: Show with `*` prefix, include progress
- **Planning plans**: Show with `-` prefix
- **Completed plans**: Show with `✓` prefix
- **Blocked plans**: Show with `!` prefix

Group by status, most recent first within each group.

## Empty State

If no plans exist:

```
No implementation plans found.

Create your first plan:
  /s2s:plan:new "feature name"

Or with a git branch:
  /s2s:plan:new "feature name" --branch
```
