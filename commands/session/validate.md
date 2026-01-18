---
description: Validate session consistency with unified structural, strategy, and diagnostic checks.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(grep:*), Read, Edit, Glob, Task, AskUserQuestion
argument-hint: [session-id]
---

# Validate Session

## Purpose

This command delegates ALL validation to the `session-qa` agent, which auto-determines applicable checks based on session context.

**Check categories:**
- **STR-*** - Structural checks (always run)
- **STRAT-*** - Strategy-specific checks (auto-detected)
- **DIAG-*** - Diagnostic checks (if session used --diagnostic)

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Use Glob to find session files: `.s2s/sessions/*.yaml`

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Determine session ID

**IF** $ARGUMENTS contains a session ID:
- Use that ID

**ELSE** find active sessions:
- Use Bash: `grep -l 'status: active' .s2s/sessions/*.yaml 2>/dev/null`
- **IF** no active sessions found:

      Error: No session specified and no active session found.
      Usage: /s2s:session:validate <session-id>

- **IF** multiple active sessions:
  - List them and ask user which to validate using AskUserQuestion

- **IF** single active session:
  - Use that session

### Read session file

**YOU MUST use Read tool** to read `.s2s/sessions/{session-id}.yaml`.

**IF** file doesn't exist:

    ⚠️ SESSION NOT FOUND
    Session '{session-id}' does not exist.

Extract from session file:
- `id`
- `workflow_type`
- `strategy`
- `status`
- `metrics.rounds_completed`

### Read config-snapshot for participant list

**YOU MUST use Read tool** to read `.s2s/sessions/{session-id}/config-snapshot.yaml`.

Extract:
- `participants` (array)
- `diagnostic` (boolean)

**IF** config-snapshot doesn't exist:
- Set `diagnostic_mode = false`
- Use default participants from session `workflow_type`

### Display header

    Session Validation
    ═══════════════════════════════════════

    Session:  {id}
    Workflow: {workflow_type}
    Strategy: {strategy}
    Rounds:   {metrics.rounds_completed}
    Mode:     {diagnostic_mode ? "Diagnostic" : "Standard"}

---

## Invoke session-qa Agent

**Use the session-qa agent** with this input:

```yaml
session_id: "{id}"
session_path: ".s2s/sessions/{id}"
session_file: ".s2s/sessions/{id}.yaml"
workflow_type: "{workflow_type}"
strategy: "{strategy}"
diagnostic_mode: {true|false from config-snapshot}
rounds_completed: {metrics.rounds_completed}
configured_participants:
  - "{participant-1}"
  - "{participant-2}"
  - "{participant-3}"
  - "{participant-4}"
```

The agent will:
1. Auto-determine which checks to run
2. Execute STR-* checks (always)
3. Execute STRAT-* checks (if strategy matches)
4. Execute DIAG-* checks (if diagnostic_mode)
5. Write evidence to `.s2s/qa/evidence/{session-id}.yaml`
6. Return structured summary

---

## Display Results

Based on session-qa agent response:

    VALIDATION RESULTS
    ═══════════════════════════════════════

    Status: {status}

    Checks Summary:
    ───────────────────────────────────────
    Total:   {checks_run}
    Passed:  {passed}
    Failed:  {failed}
    Warnings: {warn}
    Skipped: {skipped}

    By Category:
    ───────────────────────────────────────
    Structural: {by_category.structural}
    Strategy:   {by_category.strategy}
    Diagnostic: {by_category.diagnostic}

    {IF critical_findings}
    Critical Findings:
    ───────────────────────────────────────
    {for each finding}
    ✗ {finding}
    {/for}
    {/IF}

    {IF warnings}
    Warnings:
    ───────────────────────────────────────
    {for each warning}
    ⚠️ {warning}
    {/for}
    {/IF}

    Evidence: {evidence_file}

    {IF recommendations}
    Recommendations:
    ───────────────────────────────────────
    {for each recommendation}
    → {recommendation}
    {/for}
    {/IF}

    ─────────────────────────────────────
    RESULT: {PASS|WARN|FAIL}

---

## Update Validation State

**YOU MUST use Edit tool NOW** to update session file:

```yaml
validation:
  last_check: "{ISO timestamp}"
  status: "{pass|warn|fail}"
  checks_run: {checks_run}
  evidence_file: "{evidence_file}"
```

---

## Exit Codes

| Result | Description |
|--------|-------------|
| PASS | All checks passed |
| WARN | No failures but warnings found |
| FAIL | At least one check failed |
