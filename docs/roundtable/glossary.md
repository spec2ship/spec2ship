# Roundtable Glossary

This document defines the terminology used in s2s Roundtable discussions.

## Core Concepts

| Term | Definition | Example |
|------|------------|---------|
| **Workflow Type** | The s2s workflow that invokes a roundtable | `specs`, `design`, `brainstorm` |
| **Strategy** | The facilitation method used for the discussion | `standard`, `disney`, `debate`, `consensus-driven`, `six-hats` |
| **Phase** | An internal stage within a strategy | `dreamer`, `realist`, `critic` (in Disney strategy) |
| **Round** | A single question-response cycle within a phase | Round 1, Round 2 within the `realist` phase |
| **Participant** | An agent contributing to the discussion | `software-architect`, `qa-lead`, `devops-engineer` |
| **Inline Orchestration** | Loop logic in command, not separate agent (v4) | start.md calls Task(facilitator) and Task(participants) |
| **Session** | A specific instance of a roundtable discussion | `20241230-143000-api-design` |
| **Consensus** | Agreement reached between participants | List of agreed points |
| **Conflict** | Unresolved disagreement between participants | Divergent positions on a topic |

## Strategy-Specific Terms

### Standard Strategy
| Term | Definition |
|------|------------|
| **Round-robin** | Each participant speaks once per round in order |
| **Equal voice** | All participants have the same weight in consensus |

### Disney Strategy
| Term | Definition |
|------|------------|
| **Dreamer Phase** | Ideation without constraints, "what if" thinking |
| **Realist Phase** | Practical evaluation, "how to" planning |
| **Critic Phase** | Risk assessment, "what could go wrong" analysis |

### Debate Strategy
| Term | Definition |
|------|------------|
| **Pro Position** | Arguments in favor of a proposal |
| **Con Position** | Arguments against a proposal |
| **Rebuttal** | Response to opposing arguments |

### Six Hats Strategy
| Term | Definition |
|------|------------|
| **White Hat** | Facts and information only |
| **Red Hat** | Emotions and intuition |
| **Black Hat** | Caution and critical judgment |
| **Yellow Hat** | Optimism and benefits |
| **Green Hat** | Creativity and alternatives |
| **Blue Hat** | Process control and organization |

### Consensus-Driven Strategy
| Term | Definition |
|------|------------|
| **Convergence** | Process of moving toward agreement |
| **Proposal** | Specific suggestion for group consideration |
| **Stand-aside** | Disagreement that doesn't block consensus |

## Session States

| State | Description |
|-------|-------------|
| `active` | Session is currently in progress |
| `paused` | Session interrupted, can be resumed |
| `completed` | Session finished with outcome |

## Participation Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `parallel` | All participants respond simultaneously (blind voting) | Default, prevents sycophancy |
| `sequential` | Participants respond one at a time | Iterative discussion |
| `targeted` | Facilitator selects relevant participants | Topic-specific input |
| `simulate` | Single agent simulates all roles | Quick mode, simple tasks |

## Escalation Triggers

| Trigger | Description |
|---------|-------------|
| `max_rounds_per_conflict` | Escalate if same conflict persists for N rounds |
| `confidence_below` | Escalate when participant confidence is too low |
| `critical_keywords` | Escalate on security, legal, or blocking issues |

## Output Types

| Type | Description | When Generated |
|------|-------------|----------------|
| `adr` | Architecture Decision Record | Design decisions |
| `requirements` | Functional requirements list | Specs workflow |
| `architecture` | Architecture documentation | Design workflow |
| `summary` | Discussion summary | Brainstorm, general |

---
*This glossary is part of Spec2Ship Roundtable v4 documentation.*
