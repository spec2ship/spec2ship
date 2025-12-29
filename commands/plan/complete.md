---
description: Mark the current implementation plan as completed. Optionally merge the branch.
allowed-tools: Bash(git:*), Bash(cat:*), Read, Write, Edit, TodoWrite, AskUserQuestion
argument-hint: [--merge] [--no-delete-branch]
---

# Complete Implementation Plan

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"
- **Is git repo**: If `.git` directory appears in Directory contents → "yes", otherwise → "no"

If S2S is initialized, use Read tool to:
- Read `.s2s/state.yaml` to get current_plan value

## Instructions

### Check for active plan

If current plan is "none", display this message and stop:

    No active plan found.

    Use /s2s:plan:list to see available plans.
    Use /s2s:plan:start "plan-id" to activate a plan.

### Gather git information (if git repo)

If "Is git repo" is "yes", use Bash tool to gather:
1. Run `git status --porcelain` to check for uncommitted changes
   - Store result: **Git status clean** = "clean" if output is empty, otherwise "dirty"
2. Run `git branch --show-current` to get current branch name
   - Store result: **Current branch**
3. Run `git symbolic-ref refs/remotes/origin/HEAD` to get default branch
   - Store result: **Default branch** (extract branch name from output)
   - If command fails (no remote), default to "main"

If "Is git repo" is "no":
- **Git status clean** = "N/A"
- **Current branch** = "N/A"
- **Default branch** = "N/A"

### Read plan file

Read .s2s/plans/{current-plan}.md and extract:
- Topic from "# Implementation Plan: " line
- Branch from "**Branch**: " line
- Created date from "**Created**: " line
- Tasks: count lines with "- [ ]" (incomplete) and "- [x]" (complete)

### Check task completion

If there are incomplete tasks:
- List them to the user
- Ask: "Complete plan with {n} incomplete tasks?" using AskUserQuestion
- If user declines, stop

### Parse arguments

Check $ARGUMENTS for:
- **--merge**: Merge feature branch to default branch
- **--no-delete-branch**: Keep branch after merge (only with --merge)

### Confirm completion

Present summary and ask for confirmation:
- Plan ID and topic
- Task completion status
- Branch operation (merge/keep/none)

### Git operations (if --merge)

If --merge flag is present:

1. If "Is git repo" is "no":
   - Display error: "Cannot merge: not a git repository."
   - Stop execution

2. If plan's branch is "N/A":
   - Display error: "Cannot merge: plan has no associated branch."
   - Stop execution

3. If "Git status clean" is "dirty":
   - Warn user and ask them to commit first
   - Stop if they don't want to commit

4. Checkout default branch: `git checkout {default-branch}`

5. Pull latest: `git pull origin {default-branch}`

6. Merge feature branch: `git merge {branch}`
   - If merge conflict, report and stop (user must resolve manually)

7. If --no-delete-branch NOT present:
   - Delete the feature branch: `git branch -d {branch}`

### Update plan file

Edit .s2s/plans/{current-plan}.md:
- Change "**Status**: active" to "**Status**: completed"
- Update "**Updated**:" to current ISO timestamp
- Add "**Completed**: {current ISO timestamp}" after Updated line

### Update state

Update .s2s/state.yaml:
- Set current_plan to null
- Update the plan entry status to "completed"

### Output

Display confirmation:

    Plan completed!

    Plan: {plan-id}
    Topic: {topic}
    Tasks: {completed}/{total} completed
    Duration: {days since created} days

    {if --merge}
    Branch merged: {branch} → {default-branch}
    Branch deleted: {yes/no}
    {end if}

    Next steps:
    - View completed plans: /s2s:plan:list --status completed
    - Create new plan: /s2s:plan:new "next feature"
