# Spec2Ship Glossary

This document defines the terminology used throughout Spec2Ship.

---

## Artifact Types

Artifacts are the discrete outputs of roundtable discussions.

| Type | ID Pattern | Workflow | Description |
|------|------------|----------|-------------|
| **Requirement** | `REQ-NNN` | specs | Functional requirement with acceptance criteria |
| **Business Rule** | `BR-NNN` | specs | Business logic or constraint |
| **NFR** | `NFR-NNN` | specs | Non-functional requirement (performance, security, etc.) |
| **Exclusion** | `EX-NNN` | specs | Explicitly out-of-scope item |
| **Open Question** | `OQ-NNN` | all | Unresolved question requiring decision |
| **Conflict** | `CONF-NNN` | all | Disagreement between participants |
| **Architecture Decision** | `ARCH-NNN` | design | Technical architecture choice |
| **Component** | `COMP-NNN` | design | System component definition |
| **Interface** | `INT-NNN` | design | API or integration interface |
| **Idea** | `IDEA-NNN` | brainstorm | Creative idea from discussion |
| **Risk** | `RISK-NNN` | brainstorm | Identified risk |
| **Mitigation** | `MIT-NNN` | brainstorm | Risk mitigation strategy |

---

## Artifact States

Artifacts have two types of state tracking:

### Standard Artifacts

Standard artifacts (REQ, BR, NFR, EX, IDEA, RISK, MIT, ARCH, COMP) use:

| Field | Values | Description |
|-------|--------|-------------|
| **status** | `active` | Lifecycle status (always "active") |
| **agreement** | `consensus`, `draft`, `conflict` | Participant consensus level |

**Note**: Standard artifacts are immutable once created. If refinement is needed, create a NEW artifact with the updated content.

### Resolution Artifacts

Open Questions and Conflicts have their own lifecycle:

| Type | States | Notes |
|------|--------|-------|
| **open_questions** | `open` → `resolved` | Resolution stored in `resolution` field |
| **conflicts** | `open` → `resolved` | Resolution stored in `resolution.summary` and `resolution.method` |

#### Conflict Resolution Methods

| Method | Description |
|--------|-------------|
| **consensus** | Participants reached agreement through discussion |
| **facilitator** | Facilitator made judgment call based on positions |
| **user_decision** | User intervened via escalation |

---

## Agreement Level

Artifacts have an `agreement` field indicating participant consensus when created.

| Level | Description |
|-------|-------------|
| **consensus** | All participants agreed |
| **draft** | Tentative, needs further discussion |
| **conflict** | Disagreement exists, separate CONF artifact created |

**Note**: `agreement` is separate from lifecycle `status`. An artifact can be `status: "active"` with `agreement: "draft"`.

---

## Topic States

Topics are agenda items discussed in roundtable sessions.

| State | Description | Entry Condition |
|-------|-------------|-----------------|
| **open** | Not yet discussed or minimal progress | Initial state |
| **partial** | Discussion started, criteria partially met | Some coverage items addressed |
| **closed** | All done_when criteria satisfied | min_requirements met AND all criteria covered |

---

## Session States

Sessions track the lifecycle of a roundtable discussion.

| State | Description | Transitions |
|-------|-------------|-------------|
| **active** | Session in progress, can be resumed | closed |
| **closed** | Session finished (successfully or not) | - (terminal) |

---

## Artifact Immutability

Standard artifacts are **immutable** once created. This simplifies the state model and provides a clear audit trail.

**If refinement is needed**:
1. Create a NEW artifact with updated content
2. The new artifact supersedes the old one semantically (not via status field)
3. Both artifacts remain in the session for audit purposes

**Example**: If REQ-001 needs refinement, create REQ-002 with the improved definition. REQ-001 remains `status: "active"` but is effectively replaced by REQ-002.

---

## Participant Roles

Standard participants for each workflow.

| Workflow | Default Participants |
|----------|---------------------|
| **specs** | product-manager, ux-researcher, business-analyst, qa-lead |
| **design** | software-architect, security-champion, technical-lead, devops-engineer |
| **brainstorm** | Varies by --participants flag |

**Override Participants** (available for custom use):
- documentation-specialist
- claude-code-expert
- oss-community-manager
- security-champion (also default for design)
- ux-researcher (also default for specs)

### Workflow-Specific Behavior

Participants adapt their contribution based on workflow type:

| Participant | specs | design | brainstorm |
|-------------|-------|--------|------------|
| product-manager | Primary: user value | Advisory: UX impact | Champion ideas |
| ux-researcher | Primary: user needs | Reviewer: API usability | User advocate |
| business-analyst | Primary: domain model | Validator: alignment | Grounding |
| qa-lead | Primary: testability | Reviewer: quality | Risk spotter |
| software-architect | Feasibility | Primary: structure | Evaluator |
| security-champion | NFR: security reqs | Primary: threat model | Risk identifier |
| technical-lead | Complexity | Primary: code | Practical |
| devops-engineer | Early warning | Primary: ops | Operations lens |
| documentation-specialist | Clarity | Planning | Capture |
| claude-code-expert | Platform | Primary: plugin | Enabler |
| oss-community-manager | Contributor | Extension | Adoption |

---

## Strategies

Discussion strategies determine how rounds are conducted.

| Strategy | Description | Default For |
|----------|-------------|-------------|
| **standard** | Simple parallel discussion | - |
| **consensus-driven** | Proposal→refinement→convergence | specs |
| **debate** | Pro/con with structured rebuttal | design |
| **disney** | Dreamer→realist→critic phases | brainstorm |
| **six-hats** | Six thinking perspectives | - |

---

## Facilitator Actions

The facilitator agent performs two main actions per round.

| Action | Input | Output |
|--------|-------|--------|
| **question** | Session state, agenda | Question, participant_context |
| **synthesis** | Participant responses | Artifacts, next action |

---

## Common Terms

| Term | Definition |
|------|------------|
| **Roundtable** | AI-facilitated discussion between specialized participants |
| **Round** | One cycle of: question → responses → synthesis |
| **Agenda** | Ordered list of topics to discuss |
| **Coverage** | List of criteria already addressed for a topic |
| **done_when** | Criteria that must be met to close a topic |
| **Escalation** | User intervention when consensus cannot be reached |
| **Context Reconciliation** | Block sent to resumed agents about changes since last round |
| **Diagnostic Mode** | Optional validation mode (`--diagnostic`) that analyzes roundtable execution |

---

## Diagnostic Mode

Diagnostic mode (`--diagnostic` flag) enables post-round analysis to detect anomalies during roundtable execution.

### Observer Agent

The `session-observer` agent (haiku model) analyzes verbose dumps after each round.

**Input**:
```yaml
mode: "per-round" | "end-session"
session_path: ".s2s/sessions/{session-id}"
round: {N}  # for per-round mode
workflow_type: "specs" | "design" | "brainstorm"
strategy: "{strategy}"
```

**Output**:
```yaml
status: "ok" | "warning" | "anomaly"
findings:
  - type: "missing_context" | "strategy_deviation" | "participant_signal"
    detail: "{description}"
    severity: "low" | "medium" | "high"
recommendation: "Continue" | "Review findings" | "Stop for investigation"
```

### Diagnostic Report Format

Final report displayed at session completion:

```
╔════════════════════════════════════════════════════════════╗
║                    DIAGNOSTIC REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Session: {session-id}                                       ║
║ Workflow: {type} | Strategy: {strategy} | Rounds: {N}       ║
╠════════════════════════════════════════════════════════════╣
║ Round 1: ok                                                 ║
║ Round 2: warning (2 findings)                               ║
║ Round 3: ok                                                 ║
╠════════════════════════════════════════════════════════════╣
║ Session-level findings:                                     ║
║ - [medium] strategy_deviation: ...                          ║
╠════════════════════════════════════════════════════════════╣
║ RESULT: PASS | PASS with warnings | NEEDS REVIEW            ║
╚════════════════════════════════════════════════════════════╝
```

### Severity Guidelines

| Severity | Meaning | Action |
|----------|---------|--------|
| **low** | Minor, likely false positive | Continue |
| **medium** | Worth reviewing | Review findings |
| **high** | Significant issue | Stop for investigation |
