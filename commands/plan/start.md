---
description: Start working on an implementation plan. Switches to the plan's branch and marks it as active.
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob"]
argument-hint: "plan-id"
---

# Start Implementation Plan

## Arguments

- `$1`: Plan ID (timestamp-slug format) - required

## Workflow

### Step 1: Validate Environment

```bash
# Verify s2s project
if [ ! -d ".s2s" ]; then
  echo "Error: Not an s2s project."
  exit 1
fi

# Determine project type
if [ -f ".s2s/config.yaml" ]; then
  PROJECT_TYPE="standalone"
elif [ -f ".s2s/workspace.yaml" ]; then
  PROJECT_TYPE="workspace"
elif [ -f ".s2s/component.yaml" ]; then
  PROJECT_TYPE="component"
fi
```

### Step 2: Find Plan File

```bash
PLAN_ID="$1"
PLAN_FILE=".s2s/plans/${PLAN_ID}.md"

if [ ! -f "$PLAN_FILE" ]; then
  # Try partial match
  MATCHES=$(ls .s2s/plans/*${PLAN_ID}*.md 2>/dev/null | wc -l)
  if [ "$MATCHES" -eq 1 ]; then
    PLAN_FILE=$(ls .s2s/plans/*${PLAN_ID}*.md)
    PLAN_ID=$(basename "$PLAN_FILE" .md)
  elif [ "$MATCHES" -gt 1 ]; then
    echo "Multiple plans match '$PLAN_ID':"
    ls .s2s/plans/*${PLAN_ID}*.md
    echo "Please specify the exact plan ID."
    exit 1
  else
    echo "Error: Plan not found: $PLAN_ID"
    echo "Available plans:"
    ls .s2s/plans/
    exit 1
  fi
fi
```

### Step 3: Check Current Plan

Read `.s2s/state.yaml` to check if another plan is active:

```bash
CURRENT_PLAN=$(grep "current_plan:" .s2s/state.yaml | awk '{print $2}')

if [ -n "$CURRENT_PLAN" ] && [ "$CURRENT_PLAN" != "null" ]; then
  echo "Warning: Another plan is currently active: $CURRENT_PLAN"
  echo "Do you want to pause it and start this one?"
  # Ask user for confirmation
fi
```

### Step 4: Extract Branch from Plan

Read the plan file and extract branch name:

```bash
BRANCH=$(grep "^\\*\\*Branch\\*\\*:" "$PLAN_FILE" | sed 's/.*: //' | tr -d '`')

if [ -z "$BRANCH" ] || [ "$BRANCH" = "N/A" ]; then
  BRANCH=""
fi
```

### Step 5: Switch to Branch (if exists)

If branch is specified:

```bash
if [ -n "$BRANCH" ]; then
  # Check if branch exists
  if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    # Check current branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
      # Check for uncommitted changes
      if [ -n "$(git status --porcelain)" ]; then
        echo "Warning: Uncommitted changes in working directory."
        echo "Please commit or stash before switching branches."
        exit 1
      fi

      git checkout "$BRANCH"
      echo "Switched to branch: $BRANCH"
    else
      echo "Already on branch: $BRANCH"
    fi
  else
    echo "Warning: Branch '$BRANCH' does not exist."
    echo "Would you like to create it? [y/N]"
    # Handle user response
  fi
fi
```

For multi-repo context:

```bash
if [ "$PROJECT_TYPE" = "component" ]; then
  # Also verify branch exists in component
  echo "Verifying branch across workspace..."
fi
```

### Step 6: Update Plan Status

Update the plan file:
- Change `**Status**: planning` to `**Status**: active`
- Update `**Updated**:` timestamp

### Step 7: Update State

Update `.s2s/state.yaml`:

```yaml
current_plan: "{PLAN_ID}"
plans:
  "{PLAN_ID}":
    status: "active"
    started: "{ISO_TIMESTAMP}"
    updated: "{ISO_TIMESTAMP}"
```

### Step 8: Output Summary

```
Plan started: {PLAN_ID}

Topic: {extracted from plan file}
Status: active
{Branch: {BRANCH} (if applicable)}

Tasks:
{List tasks from plan file with [ ] status}

Use /s2s:plan:complete when finished.
```

## Error Handling

- Plan not found: List available plans
- Branch doesn't exist: Offer to create
- Dirty working directory: Block and advise
- Another plan active: Confirm before switching
