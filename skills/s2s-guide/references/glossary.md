# Glossary

Terminology used throughout Spec2Ship.

## Core Concepts

| Term | Definition |
|------|------------|
| **Roundtable** | AI-facilitated discussion between specialized participants |
| **Round** | One cycle: question → responses → synthesis |
| **Facilitator** | Agent that orchestrates the discussion |
| **Participant** | Agent with specialized expertise |
| **Session** | A complete roundtable discussion |
| **Artifact** | Discrete output from a roundtable (requirement, decision, etc.) |

---

## Artifact Types

| Type | ID Pattern | Workflow | Description |
|------|------------|----------|-------------|
| **Requirement** | `REQ-NNN` | specs | Functional requirement with acceptance criteria |
| **Business Rule** | `BR-NNN` | specs | Business logic or constraint |
| **NFR** | `NFR-NNN` | specs | Non-functional requirement |
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

## Artifact States (ADR-0010)

All artifacts use a single `state` field (not separate status + agreement).

### Universal States

All artifact types can use these states:

| State | Description | Facilitator Action |
|-------|-------------|-------------------|
| **draft** | Initial state after creation | Passive (log) |
| **needs_discussion** | Queued for discussion | Passive (queue) |
| **in_progress** | Currently being discussed | Active (drive resolution) |
| **blocked** | Has blocking concern | Active (address block) |
| **deferred** | Postponed for later | Passive (review at close) |
| **rejected** | Explicitly rejected | Passive (archive) |

### Terminal States (by artifact type)

| Artifact Types | Terminal States |
|----------------|-----------------|
| REQ, BR, NFR, EX | `approved`, `implemented` |
| ARCH, DEC, COMP, INT | `accepted` |
| IDEA | `promoted`, `parked` |
| OQ, CONF | `resolved` |

### State Transitions

Tracked in `rounds[].artifacts_transitioned` for audit:

```yaml
artifacts_transitioned:
  - id: "REQ-001"
    from: "draft"
    to: "approved"
    reason: "consensus reached"
```

### Resolution Tracking

| Field | Structure | Description |
|-------|-----------|-------------|
| **resolved_conflicts** | `{conflict_id, resolution, method}` | How conflicts were resolved |
| **resolved_questions** | `{question_id, answer}` | How questions were answered |

Resolution methods: `consensus`, `facilitator`, `user_decision`

---

## Session States

| State | Description |
|-------|-------------|
| **active** | Session in progress, can be resumed |
| **closed** | Session finished |

---

## Topic States

| State | Description |
|-------|-------------|
| **open** | Not yet discussed |
| **partial** | Discussion started, criteria partially met |
| **closed** | All done_when criteria satisfied |

---

## Participant Roles

### By Workflow

| Workflow | Default Participants |
|----------|---------------------|
| **specs** | product-manager, ux-researcher, business-analyst, qa-lead, technical-lead |
| **design** | software-architect, security-champion, technical-lead, devops-engineer |
| **brainstorm** | Varies by --participants flag |

### Available Participants

| Agent | Primary Focus |
|-------|---------------|
| product-manager | User value, priorities |
| business-analyst | Domain modeling, use cases |
| qa-lead | Quality, testing, edge cases |
| ux-researcher | User needs, accessibility |
| software-architect | Structure, patterns |
| technical-lead | Implementation, tech stack |
| devops-engineer | Deploy, infra, operations |
| security-champion | Threats, OWASP, compliance |
| documentation-specialist | Clarity, docs |
| claude-code-expert | Claude Code platform |
| oss-community-manager | Community, adoption |

---

## Strategies

| Strategy | Description | Default For |
|----------|-------------|-------------|
| **standard** | Simple parallel discussion | - |
| **consensus-driven** | Proposal→refinement→convergence | specs |
| **debate** | Pro/con with structured rebuttal | design |
| **disney** | Dreamer→realist→critic phases | brainstorm |
| **six-hats** | Six thinking perspectives | - |

---

## Project Types

| Type | config.yaml `type` | Description |
|------|-------------------|-------------|
| **Standalone** | `standalone` | Single independent project |
| **Workspace** | `workspace` | Coordinates multiple components |
| **Component** | `component` | Part of a workspace |
