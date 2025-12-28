---
description: Create a new implementation plan. Use --branch to also create a git feature branch.
allowed-tools: Bash(date:*), Bash(mkdir:*), Bash(git:*), Bash(wc:*), Read, Write, Glob, Edit, TodoWrite, AskUserQuestion
argument-hint: "topic" [--branch]
---

# Create New Implementation Plan

## Context

- Project type: !`[ -f ".s2s/config.yaml" ] && echo "standalone" || ([ -f ".s2s/workspace.yaml" ] && echo "workspace" || ([ -f ".s2s/component.yaml" ] && echo "component" || echo "NOT_S2S"))`
- Current timestamp: !`date +"%Y%m%d-%H%M%S"`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Existing feature branches: !`(git branch --list 'feature/F*' 2>/dev/null | wc -l | tr -d ' ') || echo "0"`
- Git status clean: !`[ -z "$(git status --porcelain 2>/dev/null)" ] && echo "clean" || echo "dirty"`
- Plans directory exists: !`[ -d ".s2s/plans" ] && echo "yes" || echo "no"`

## Instructions

### Validate environment

If project type is "NOT_S2S", display this message and stop:

    Error: Not an s2s project. Run /s2s:proj:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **Topic**: The first quoted string or unquoted words (required)
- **--branch flag**: Whether to create a git branch

If no topic is provided, ask the user for one using AskUserQuestion.

### Generate identifiers

Using the timestamp from context:
1. **Plan ID**: Combine timestamp with a slug of the topic
   - Slug: lowercase, spaces to hyphens, only a-z 0-9 hyphens, max 50 chars
   - Format: {timestamp}-{slug}
2. **File path**: .s2s/plans/{plan-id}.md

If --branch flag is present:
3. **Branch number**: existing feature branches count + 1, zero-padded to 2 digits
4. **Branch name**: feature/F{NN}-{slug}

### Pre-flight checks

If plans directory does not exist, create it using Bash mkdir.

If --branch flag and git status is "dirty":
- Warn user about uncommitted changes
- Ask if they want to proceed using AskUserQuestion

### Confirm with user

Present the following and ask for confirmation:
- Plan topic
- Plan ID
- File path
- Branch name (if --branch)

### Create the plan file

Write a new file at .s2s/plans/{plan-id}.md with this content:

    # Implementation Plan: {Topic}

    **ID**: {plan-id}
    **Status**: planning
    **Branch**: {branch-name or N/A}
    **Created**: {ISO timestamp}
    **Updated**: {ISO timestamp}

    ## References

    ### Requirements
    <!-- Link to relevant requirements -->

    ### Architecture
    <!-- Link to relevant architecture sections -->

    ### Decisions
    <!-- Link to relevant ADRs -->

    ## Design Notes

    <!-- Component-specific technical decisions -->

    ## Tasks

    - [ ] Task 1
    - [ ] Task 2
    - [ ] Task 3

    ## Notes

    <!-- Progress notes, blockers, etc. -->

### Create git branch (if --branch)

Run: git checkout -b {branch-name}

Update the plan file to include the actual branch name.

### Update state

Read .s2s/state.yaml (or create if missing) and add the plan entry with status "planning".

### Output

Display confirmation:

    Implementation plan created!

    Plan ID: {plan-id}
    File: .s2s/plans/{plan-id}.md
    Topic: {topic}
    Status: planning
    Branch: {branch-name if created}

    Next steps:
    1. Edit the plan to add references and tasks
    2. Run /s2s:plan:start "{plan-id}" when ready to begin
    3. Use /s2s:decision:new if architectural decisions needed
