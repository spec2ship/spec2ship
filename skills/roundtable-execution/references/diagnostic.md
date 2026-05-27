# Diagnostic Mode Instructions

This file contains instructions for diagnostic mode execution.
Only read this file when `--diagnostic` flag is passed.

---

## Per-Round Diagnostic (after each synthesis)

**Use the session-observer agent** with this input:

```yaml
mode: "per-round"
session_path: ".s2s/sessions/{session-id}"
round: {current_round_number}
workflow_type: "{workflow_type}"
strategy: "{strategy}"
```

The observer will return:
```yaml
round: {N}
status: "ok" | "warning" | "anomaly"
findings: [...]
recommendation: "Continue" | "Review findings" | "Stop for investigation"
```

**Display observer result**:
```
[DIAGNOSTIC] Round {N}: {status}
{IF findings not empty}
Findings:
- {for each finding: type, detail, severity}
{/IF}
Recommendation: {recommendation}
```

**IF** recommendation == "Stop for investigation":
- Display warning and pause for user review
- Ask using AskUserQuestion: "Diagnostic observer recommends stopping. What would you like to do?"
  - Options: "Investigate now" / "Continue anyway" / "Abort session"

**ELSE**: Continue to next step.

---

## End-Session Diagnostic Report (before completion)

**Use the session-observer agent** with this input:

```yaml
mode: "end-session"
session_path: ".s2s/sessions/{session-id}"
workflow_type: "{workflow_type}"
strategy: "{strategy}"
```

The observer will return a final diagnostic summary.

**Display final diagnostic report**:
```
╔════════════════════════════════════════════════════════════╗
║                    DIAGNOSTIC REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Session: {session-id}                                       ║
║ Workflow: {workflow_type} | Strategy: {strategy} | Rounds: {N} ║
╠════════════════════════════════════════════════════════════╣
{for each round's diagnostic result}
║ Round {N}: {status} {findings count if > 0}                ║
{/for}
╠════════════════════════════════════════════════════════════╣
║ Session-level findings:                                     ║
{list session-level findings from end-session mode}
╠════════════════════════════════════════════════════════════╣
║ RESULT: {PASS|PASS with warnings|NEEDS REVIEW}             ║
╚════════════════════════════════════════════════════════════╝
```

---

## Variables Reference

When following these instructions, substitute:
- `{session-id}`: Current session ID from session file
- `{current_round_number}`: The round number just completed
- `{workflow_type}`: The workflow type (specs, design, brainstorm, roundtable)
- `{strategy}`: The facilitation strategy being used
