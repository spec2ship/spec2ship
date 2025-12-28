---
description: List all implementation plans with their status.
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(grep:*), Bash(cut:*), Bash(tr:*), Bash(echo:*), Read, Glob, Grep
argument-hint: [--status planning|active|completed|blocked]
---

# List Implementation Plans

## Context

- Plans directory contents: !`ls .s2s/plans/*.md 2>/dev/null || echo "NO_PLANS"`
- Current active plan: !`(grep "current_plan:" .s2s/state.yaml 2>/dev/null | cut -d: -f2 | tr -d ' "') || echo "none"`

## Instructions

### If no plans exist

If the context shows "NO_PLANS", display this message and stop:

    No implementation plans found.

    Create your first plan:
      /s2s:plan:new "feature name"

    Or with a git branch:
      /s2s:plan:new "feature name" --branch

### If plans exist

For each plan file found in the context:

1. Read the file using the Read tool
2. Extract these fields from the content:
   - **Plan ID**: filename without .md extension
   - **Topic**: text after "# Implementation Plan: "
   - **Status**: value after "**Status**: "
   - **Branch**: value after "**Branch**: "
   - **Created**: value after "**Created**: "
   - **Updated**: value after "**Updated**: "
3. Count tasks by searching for checkbox patterns:
   - Total tasks: count lines containing "- [ ]" or "- [x]"
   - Completed tasks: count lines containing "- [x]"

### Filter by status (if requested)

If $ARGUMENTS contains "--status", filter the results to show only plans matching that status.

### Format output

Group plans by status and display:

**Active plans** (prefix with *):
- Show plan ID, topic, branch, progress (completed/total tasks), start date

**Planning plans** (prefix with -):
- Show plan ID, topic, task count, creation date

**Completed plans** (prefix with ✓):
- Show plan ID, topic, completion date

**Blocked plans** (prefix with !):
- Show plan ID, topic, branch

End with a summary line showing total counts by status.

### Mark current plan

If the "current active plan" from context matches a plan ID, highlight it in the output.
