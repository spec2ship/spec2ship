---
description: Start working on an implementation plan. Switches to the plan's branch and marks it as active.
allowed-tools: Bash(git:*), Bash(ls:*), Bash(test:*), Bash(grep:*), Bash(xargs:*), Bash(basename:*), Bash(cut:*), Bash(tr:*), Bash(echo:*), Read, Write, Edit, Glob, TodoWrite, AskUserQuestion
argument-hint: "plan-id"
---

# Start Implementation Plan

## Context

- Project type: !`test -f ".s2s/config.yaml" && echo "standalone" || (test -f ".s2s/workspace.yaml" && echo "workspace" || (test -f ".s2s/component.yaml" && echo "component" || echo "NOT_S2S"))`
- Available plans: !`(ls .s2s/plans/*.md 2>/dev/null | xargs -I {} basename {} .md) || echo "NO_PLANS"`
- Current plan: !`(grep "current_plan:" .s2s/state.yaml 2>/dev/null | cut -d: -f2 | tr -d ' "') || echo "none"`
- Current git branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
- Git status clean: !`test -z "$(git status --porcelain 2>/dev/null)" && echo "clean" || echo "dirty"`

## Instructions

### Validate environment

If project type is "NOT_S2S", display error and stop:

    Error: Not an s2s project. Run /s2s:proj:init first.

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

If branch name is not "N/A":
1. Check if branch exists: git branch --list {branch}
2. If git status is "dirty", warn user and ask confirmation

### Confirm with user

Present summary and ask for confirmation:
- Plan ID and topic
- Current branch vs target branch
- Task count (completed/total)

### Activate the plan

1. If branch exists and not already on it: git checkout {branch}
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
