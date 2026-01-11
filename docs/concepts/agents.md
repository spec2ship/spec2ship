# Agents

Agents are specialized AI participants in roundtable discussions. Each agent brings domain expertise and a unique perspective.

## Agent Types

### Orchestration

| Agent | Role |
|-------|------|
| **Facilitator** | Orchestrates discussion, synthesizes responses, manages flow |

### Workflow Participants

| Agent | Primary Workflow | Focus |
|-------|------------------|-------|
| **Product Manager** | specs, brainstorm | User value, priorities, business alignment |
| **Business Analyst** | specs | Domain modeling, use cases, business rules |
| **QA Lead** | specs | Quality, testability, edge cases, acceptance criteria |
| **UX Researcher** | specs | User needs, accessibility, usability |
| **Software Architect** | design, brainstorm | System structure, patterns, scalability |
| **Technical Lead** | design, brainstorm | Implementation feasibility, tech stack |
| **DevOps Engineer** | design, brainstorm | Deployment, infrastructure, operations |
| **Security Champion** | design | Threat modeling, OWASP, compliance |

### Override Participants

These agents are available but not included by default:

| Agent | When to Use |
|-------|-------------|
| **Documentation Specialist** | API docs, user guides focus |
| **Claude Code Expert** | Plugin architecture, tool usage |
| **OSS Community Manager** | Open source projects |

## Agent Characteristics

### 1. Workflow-Specific Focus

Each agent adapts their contribution based on the workflow:

```
Software Architect in specs → Advisory role, high-level constraints
Software Architect in design → Primary role, detailed decisions
Software Architect in brainstorm → Feasibility evaluation
```

### 2. Strategy-Specific Behavior

Agents adapt to the active strategy:

```
QA Lead in debate (Pro) → Defend the approach vigorously
QA Lead in debate (Con) → Attack weaknesses systematically
QA Lead in disney (critic) → Maximum criticism, find every flaw
```

### 3. Critical Stance (Anti-Sycophancy)

All agents are designed to resist premature agreement:

- **Anchor to Principles**: Positions derive from domain expertise
- **Resist Premature Consensus**: Express disagreement professionally
- **Constructive Dissent**: Disagree with alternatives, not just criticism
- **Confidence Scaling**: Lower confidence when pressured or context is insufficient

### 4. Context Completeness Check

Agents evaluate whether they have sufficient information:

| Confidence | Meaning |
|------------|---------|
| 0.8 - 1.0 | Full context, can make informed recommendation |
| 0.3 - 0.5 | Context gaps exist, recommendation is tentative |
| < 0.3 | Cannot evaluate properly, signals CONTEXT GAP |

## Specifying Participants

```bash
# Use specific participants
/s2s:design --participants architect,tech-lead,security-champion

# Add to defaults
/s2s:specs --participants +documentation-specialist
```

## Agent Invocation

Agents are invoked by the workflow command, not directly by users. The facilitator prepares context for each participant, who then responds based solely on that context (no file access).

```
Workflow Command
     │
     ├── Facilitator (generates question + context)
     │
     └── Participants (respond in parallel)
           ├── product-manager
           ├── software-architect
           └── qa-lead
```

---

*See also: [Roundtable](./roundtable.md) | [Extending: New Agent](../extending/new-agent.md)*
