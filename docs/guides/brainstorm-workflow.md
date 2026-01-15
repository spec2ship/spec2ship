# Brainstorm Workflow Guide

The brainstorm workflow uses a roundtable discussion with the Disney creative strategy to explore ideas.

## Overview

```bash
/s2s:brainstorm "topic" [--participants <list>] [--verbose] [--interactive] [--diagnostic]
```

**Purpose**: Creative exploration of ideas without constraints.

**Output**: `.s2s/sessions/{id}-summary.md` (ideas, risks, mitigations)

## When to Use

- Exploring new feature ideas
- Finding solutions to complex problems
- Evaluating multiple approaches
- Early-stage project ideation

## Default Configuration

| Setting | Value |
|---------|-------|
| Strategy | `disney` (fixed) |
| Participants | product-manager, software-architect, technical-lead, devops-engineer |
| Minimum rounds | 3 (one per phase minimum) |

## The Disney Strategy

Based on Walt Disney's creative process, the discussion moves through three distinct phases:

### Phase 1: Dreamer

**Mindset**: Blue-sky thinking, no constraints

- Wild ideas welcome
- No criticism allowed
- "What if..." thinking
- Quantity over quality

**Output**: Raw ideas (IDEA-*)

### Phase 2: Realist

**Mindset**: Practical evaluation

- How would we build this?
- What resources needed?
- What's the timeline?
- Refine promising ideas

**Output**: Refined ideas with implementation notes

### Phase 3: Critic

**Mindset**: Risk assessment

- What could go wrong?
- What are we missing?
- What are the blockers?
- Identify mitigations

**Output**: Risks (RISK-*) and mitigations (MIT-*)

## Running the Workflow

### Basic Usage

```bash
/s2s:brainstorm "How should we implement real-time notifications?"
```

The roundtable will:
1. Enter Dreamer phase - generate ideas without judgment
2. Move to Realist phase - evaluate feasibility
3. Enter Critic phase - identify risks
4. Synthesize into actionable output

### With Options

```bash
# See detailed output
/s2s:brainstorm "API versioning strategy" --verbose

# Control each phase manually
/s2s:brainstorm "Mobile app features" --interactive

# Add UX perspective
/s2s:brainstorm "Onboarding flow" --participants +ux-researcher
```

## Understanding the Flow

### Dreamer Phase

```
Round 1 (Dreamer)
━━━━━━━━━━━━━━━━
Topic: Real-time notifications

Product Manager: "What if users could set notification priorities?"
Architect: "We could use WebSockets for instant delivery"
Tech Lead: "AI-powered smart notifications that learn preferences"
DevOps: "Edge-deployed notification service for low latency"

Ideas Generated: IDEA-001, IDEA-002, IDEA-003, IDEA-004
```

### Realist Phase

```
Round 2 (Realist)
━━━━━━━━━━━━━━━━
Evaluating: IDEA-001 through IDEA-004

Product Manager: "Priority notifications - 2 weeks, uses existing prefs"
Architect: "WebSockets feasible, need to handle reconnection"
Tech Lead: "AI notifications - 6 weeks, needs training data"
DevOps: "Edge deployment - 3 weeks, adds complexity"

Refined: IDEA-001 (viable), IDEA-002 (viable), IDEA-003 (deferred), IDEA-004 (viable)
```

### Critic Phase

```
Round 3 (Critic)
━━━━━━━━━━━━━━━━
Critiquing refined ideas

Product Manager: "RISK-001: Users overwhelmed by notifications"
Architect: "RISK-002: WebSocket connection management at scale"
Tech Lead: "RISK-003: Browser compatibility issues"
DevOps: "RISK-004: Edge service monitoring complexity"

Mitigations proposed: MIT-001 through MIT-004
```

## Understanding the Output

### Session Summary

The output file contains:

```markdown
# Brainstorm Summary: Real-time Notifications

## Ideas

### IDEA-001: Priority-based Notifications
- **Status**: Viable
- **Effort**: 2 weeks
- **Description**: Allow users to set priority levels...
- **Proposed by**: Product Manager

### IDEA-002: WebSocket Delivery
- **Status**: Viable
- **Effort**: 3 weeks
- **Description**: Real-time delivery via WebSockets...
- **Proposed by**: Software Architect

## Risks

### RISK-001: Notification Overload
- **Severity**: Medium
- **Related to**: IDEA-001
- **Description**: Users may be overwhelmed...

## Mitigations

### MIT-001: Smart Defaults
- **Addresses**: RISK-001
- **Description**: Sensible default settings...

## Recommendations

1. Start with IDEA-001 + IDEA-002
2. Address RISK-001 with MIT-001 before launch
3. Defer IDEA-003 (AI notifications) to phase 2
```

## Interactive Mode

With `--interactive`, you control phase transitions:

```
Round 2 Complete (Realist Phase)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ideas evaluated: 4
Viable ideas: 3
Deferred ideas: 1

What would you like to do?
› continue - Move to Critic phase
  more     - Another Realist round
  exit     - Save and exit
```

## Tips for Better Results

### Crafting Good Topics

**Good topics**:
- "How should we handle user authentication?"
- "What features would make onboarding delightful?"
- "Ways to improve API performance"

**Too vague**:
- "Make it better"
- "New features"

**Too specific**:
- "Should we use JWT or sessions?" (use debate for this)

### During Brainstorm

1. **Don't skip Dreamer phase** - wild ideas often spark good ones
2. **Be patient in Realist** - quick dismissal kills creativity
3. **Take Critic seriously** - risks identified early save time later

### After Completion

1. **Review all ideas** - even deferred ones may have value later
2. **Prioritize by value/effort** - not all viable ideas should be built
3. **Feed into specs** - use output to inform `/s2s:specs`

## Participant Selection

### Default Participants

| Participant | Contribution |
|-------------|--------------|
| Product Manager | User value, business ideas |
| Software Architect | Technical possibilities |
| Technical Lead | Implementation reality |
| DevOps Engineer | Operations perspective |

### Adding Specialists

```bash
# For user-facing features
/s2s:brainstorm "Onboarding flow" --participants +ux-researcher

# For security-sensitive topics
/s2s:brainstorm "Auth strategy" --participants +security-champion

# For API design
/s2s:brainstorm "API evolution" --participants +documentation-specialist
```

## Troubleshooting

### Ideas too conservative

The Dreamer phase may not be wild enough. Try:
- More specific topic framing
- Adding creative participants
- Using `--interactive` to encourage more rounds

### Realist phase kills everything

Common in risk-averse teams. Remember:
- Realist evaluates, doesn't eliminate
- "Deferred" is not "rejected"
- Some risk is acceptable

### Critic phase too negative

Ensure mitigations are proposed:
- Every RISK should have at least one MIT
- Focus on "how to address" not just "what's wrong"

---

*See also: [Specs Workflow](./specs-workflow.md) | [Design Workflow](./design-workflow.md)*
