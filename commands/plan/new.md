---
description: Create a new implementation plan. Use --branch to also create a git feature branch.
allowed-tools: ["Bash", "Read", "Write", "Glob", "Edit"]
argument-hint: "topic" [--branch]
---

# Create New Implementation Plan

## Arguments

- `$1` or first quoted string: Topic/title for the plan (required)
- `--branch`: Also create a git branch for this plan

## Workflow

### Step 1: Validate Environment

Verify we're in an s2s project:

```bash
# Check for any s2s config
if [ -f ".s2s/config.yaml" ]; then
  PROJECT_TYPE="standalone"
elif [ -f ".s2s/workspace.yaml" ]; then
  PROJECT_TYPE="workspace"
elif [ -f ".s2s/component.yaml" ]; then
  PROJECT_TYPE="component"
else
  echo "Error: Not an s2s project. Run /s2s:proj:init first."
  exit 1
fi
```

### Step 2: Parse Arguments

Extract topic from arguments:
- If quoted string provided, use as topic
- Remove --branch flag for later processing

Example parsing:
- `"user authentication" --branch` → topic="user authentication", branch=true
- `"API versioning"` → topic="API versioning", branch=false

### Step 3: Generate Identifiers

```bash
# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Generate slug from topic
SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-50)

# Plan ID
PLAN_ID="${TIMESTAMP}-${SLUG}"

# File path
PLAN_FILE=".s2s/plans/${PLAN_ID}.md"
```

### Step 4: Check for Existing Plan

```bash
if [ -f "$PLAN_FILE" ]; then
  echo "Error: Plan already exists at $PLAN_FILE"
  exit 1
fi
```

### Step 5: Create Plans Directory

```bash
mkdir -p .s2s/plans
```

### Step 6: Generate Plan Content

Use the template from `templates/plan.md` with substitutions:

- `{TOPIC}` → User-provided topic
- `{YYYYMMDD-HHMMSS-slug}` → Generated PLAN_ID
- `{feature/FNN-slug}` → Generated branch name (if --branch) or "N/A"
- `{YYYY-MM-DDTHH:MM:SSZ}` → ISO timestamp

Write the file to `.s2s/plans/{PLAN_ID}.md`.

### Step 7: Create Git Branch (if --branch)

If `--branch` flag provided:

```bash
# Check git status is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "Warning: Working directory has uncommitted changes."
  echo "Please commit or stash changes before creating a branch."
  # Ask user if they want to continue anyway
fi

# Get next feature number
FEATURE_NUM=$(git branch --list 'feature/F*' 2>/dev/null | wc -l | xargs expr 1 +)
FEATURE_NUM=$(printf "%02d" $FEATURE_NUM)

# Create branch name
BRANCH_NAME="feature/F${FEATURE_NUM}-${SLUG}"

# Create and checkout branch
git checkout -b "$BRANCH_NAME"
```

If in a workspace context (component or workspace-hub):

```bash
# Load component paths from workspace
if [ "$PROJECT_TYPE" = "component" ]; then
  WORKSPACE_PATH=$(grep "path:" .s2s/component.yaml | head -1 | awk '{print $2}' | tr -d '"')
  COMPONENTS_FILE="$WORKSPACE_PATH/.s2s/components.yaml"
else
  COMPONENTS_FILE=".s2s/components.yaml"
fi

# For each component that needs the branch
# (This is simplified - full implementation would parse YAML properly)
echo "Creating branch across workspace components..."
```

### Step 8: Update State

Update `.s2s/state.yaml`:

```yaml
plans:
  "{PLAN_ID}":
    status: "planning"
    branch: "{BRANCH_NAME}"    # or null if no branch
    created: "{ISO_TIMESTAMP}"
    updated: "{ISO_TIMESTAMP}"
```

If no state.yaml exists, create it:

```yaml
current_plan: null
plans:
  "{PLAN_ID}":
    status: "planning"
    branch: "{BRANCH_NAME}"
    created: "{ISO_TIMESTAMP}"
    updated: "{ISO_TIMESTAMP}"
last_sync: null
```

### Step 9: Output Summary

```
Implementation plan created!

File: .s2s/plans/{PLAN_ID}.md
Topic: {TOPIC}
Status: planning
{Branch: {BRANCH_NAME} (if --branch)}

Next steps:
1. Edit the plan file to add references and tasks
2. Run /s2s:plan:start "{PLAN_ID}" when ready to begin
3. Use /s2s:decision:new if architectural decisions needed
```

## Error Handling

- If no topic provided: Ask user for topic
- If git operations fail: Report error, do NOT delete plan file
- If in multi-repo and some repos fail: Report which succeeded/failed
