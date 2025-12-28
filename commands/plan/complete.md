---
description: Mark the current implementation plan as completed. Optionally merge the branch.
allowed-tools: Bash(*), Read, Write, Edit
argument-hint: [--merge] [--no-delete-branch]
---

# Complete Implementation Plan

## Arguments

- `--merge`: Also merge the feature branch to main
- `--no-delete-branch`: Keep the branch after completion (default: delete on merge)

## Workflow

### Step 1: Validate Current Plan

```bash
# Check for state file
if [ ! -f ".s2s/state.yaml" ]; then
  echo "Error: No s2s state found."
  exit 1
fi

# Get current plan
CURRENT_PLAN=$(grep "current_plan:" .s2s/state.yaml | awk '{print $2}')

if [ -z "$CURRENT_PLAN" ] || [ "$CURRENT_PLAN" = "null" ]; then
  echo "Error: No active plan to complete."
  echo "Use /s2s:plan:list to see all plans."
  exit 1
fi

PLAN_FILE=".s2s/plans/${CURRENT_PLAN}.md"

if [ ! -f "$PLAN_FILE" ]; then
  echo "Error: Plan file not found: $PLAN_FILE"
  exit 1
fi
```

### Step 2: Check Task Completion

Read the plan file and count incomplete tasks:

```bash
INCOMPLETE_TASKS=$(grep -c "^- \\[ \\]" "$PLAN_FILE")

if [ "$INCOMPLETE_TASKS" -gt 0 ]; then
  echo "Warning: $INCOMPLETE_TASKS task(s) still incomplete."
  grep "^- \\[ \\]" "$PLAN_FILE"
  echo ""
  echo "Do you want to mark the plan as completed anyway? [y/N]"
  # Handle user response
fi
```

### Step 3: Update Plan Status

Update the plan file:
- Change `**Status**: active` to `**Status**: completed`
- Update `**Updated**:` timestamp

### Step 4: Update State

Update `.s2s/state.yaml`:

```yaml
current_plan: null
plans:
  "{PLAN_ID}":
    status: "completed"
    completed: "{ISO_TIMESTAMP}"
    updated: "{ISO_TIMESTAMP}"
```

### Step 5: Handle Branch (if --merge)

If `--merge` flag provided:

```bash
# Extract branch from plan
BRANCH=$(grep "^\\*\\*Branch\\*\\*:" "$PLAN_FILE" | sed 's/.*: //' | tr -d '`')

if [ -n "$BRANCH" ] && [ "$BRANCH" != "N/A" ]; then
  # Get default branch
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}

  # Verify we're on the feature branch
  CURRENT_BRANCH=$(git branch --show-current)
  if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "Warning: Not currently on plan branch ($BRANCH)."
    echo "Current branch: $CURRENT_BRANCH"
    echo "Switch to $BRANCH before merging."
    exit 1
  fi

  # Check for uncommitted changes
  if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Uncommitted changes. Commit before merging."
    exit 1
  fi

  # Checkout default branch and merge
  git checkout "$DEFAULT_BRANCH"
  git merge "$BRANCH" --no-ff -m "Merge $BRANCH: Complete ${CURRENT_PLAN}"

  # Delete branch (unless --no-delete-branch)
  if [[ "$*" != *"--no-delete-branch"* ]]; then
    git branch -d "$BRANCH"
    echo "Deleted branch: $BRANCH"
  fi

  echo "Merged $BRANCH into $DEFAULT_BRANCH"
fi
```

For multi-repo context:

```bash
# If component or workspace, handle across repos
if [ -f ".s2s/component.yaml" ] || [ -f ".s2s/workspace.yaml" ]; then
  echo "Multi-repo merge requires manual coordination or PR workflow."
  echo "Use /s2s:git:pr to create pull requests."
fi
```

### Step 6: Output Summary

```
Plan completed: {PLAN_ID}

Topic: {extracted from plan file}
Status: completed
Duration: {calculated from created to completed}
{Merged to: {DEFAULT_BRANCH} (if --merge)}

Summary:
- Total tasks: {count}
- Completed: {count}
- Skipped: {count if any [ ] remain}

Completed plans are archived in .s2s/plans/
Use /s2s:plan:list to see all plans.
```

## Notes

- Completed plans remain in `.s2s/plans/` for reference
- The state.yaml tracks completion timestamp
- For PRs instead of direct merge, use `/s2s:git:pr`
