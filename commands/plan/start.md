---
description: Start working on an implementation plan. Switches to the plan's branch and marks it as active.
allowed-tools: Bash(git:*), Bash(ls:*), Bash(cat:*), Read, Write, Edit, Glob, TodoWrite, AskUserQuestion
argument-hint: "plan-id"
---

# Start Implementation Plan

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"
- **Is git repo**: If `.git` directory appears in Directory contents → "yes", otherwise → "no"

If S2S is initialized, use Read tool to:
- Read `.s2s/state.yaml` to get current_plan value
- List `.s2s/plans/` to get available plan IDs
- Check project type from config files

## Instructions

### Validate environment

If project type is "NOT_S2S", display error and stop:

    Error: Not an s2s project. Run /s2s:init first.

### Gather git information (if git repo)

If "Is git repo" is "yes", use Bash tool to gather:
1. Run `git branch --show-current` to get current branch name
   - Store result: **Current branch**
2. Run `git status --porcelain` to check for uncommitted changes
   - Store result: **Git status clean** = "clean" if output is empty, otherwise "dirty"

If "Is git repo" is "no":
- **Current branch** = "N/A"
- **Git status clean** = "N/A"

### Find the plan

Extract plan ID from $ARGUMENTS.

1. If exact match exists in available plans, use it
2. If not exact, search for partial matches in the available plans list
3. If multiple matches found, list them and ask user to be specific
4. If no matches, show available plans and stop

### Check current state

If current plan is not "none" and is different from the requested plan:
- Warn user that another plan is active
- Ask if they want to switch using AskUserQuestion
- If user declines, stop

### Read plan file

Read .s2s/plans/{plan-id}.md and extract:
- Topic from "# Implementation Plan: " line
- Branch from "**Branch**: " line
- Status from "**Status**: " line
- Tasks (count of "- [ ]" and "- [x]" lines)

### Pre-flight checks for branch switch

If branch name (from plan file) is not "N/A":
1. If "Is git repo" is "no":
   - Display warning: "Plan has branch '{branch}' but this is not a git repository. Branch switch skipped."
   - Continue without branch operations
2. If "Is git repo" is "yes":
   - Check if branch exists: `git branch --list {branch}`
   - If "Git status clean" is "dirty", warn user and ask confirmation

### Confirm with user

Present summary and ask for confirmation:
- Plan ID and topic
- Current branch vs target branch
- Task count (completed/total)

### Activate the plan

1. If branch exists and "Is git repo" is "yes" and not already on target branch:
   - Run `git checkout {branch}`
2. Update the plan file:
   - Change Status from "planning" to "active"
   - Update the "**Updated**:" timestamp to current ISO time
3. If another plan was active, update its status back to "planning"

### Update state

Update .s2s/state.yaml to set current_plan to the new plan ID.

### Output

Display confirmation:

    Plan activated!

    Plan: {plan-id}
    Topic: {topic}
    Branch: {branch}
    Status: active

    Tasks:
    {list first 5 tasks from plan}

    Next steps:
    - Work through the tasks in the plan
    - Mark tasks complete with [x] as you progress
    - Run /s2s:plan:complete when finished
