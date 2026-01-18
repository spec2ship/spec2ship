# Core Concepts

This page provides a conceptual overview of Spec2Ship.

> [!TIP]
> For detailed reference, ask Claude: `"how do roundtables work in s2s"` (loads the `s2s-guide` skill).

## Workflow Phases

```
init → brainstorm → specs → design → plan → execute
       (optional)
```

| Phase | Command | Purpose | Output |
|-------|---------|---------|--------|
| **Init** | `/s2s:init` | Analyze project, set up context | `.s2s/CONTEXT.md` |
| **Brainstorm** | `/s2s:brainstorm "topic"` | Creative exploration | Ideas, risks |
| **Specs** | `/s2s:specs` | Define requirements | `requirements.md` |
| **Design** | `/s2s:design` | Architect solution | `architecture.md`, ADRs |
| **Plan** | `/s2s:plan` | Create implementation roadmap | `plans/*.md` |
| **Execute** | `/s2s:plan --session` | Implement with guidance | Code, commits |

Each phase can run independently. Missing prerequisites trigger helpful prompts, not hard failures.

---

## Roundtable

The Roundtable is Spec2Ship's multi-agent discussion system.

### How It Works

1. **Facilitator** generates a question based on the agenda
2. **Participants** respond in parallel (blind voting, cannot see each other's responses)
3. **Facilitator** synthesizes responses into artifacts and decisions
4. **Session** is updated with round summary and artifacts
5. Repeat until topics are covered or escalation triggered

### Why Blind Voting

Participants respond without seeing each other's responses:
- Prevents anchoring bias
- Reduces sycophancy
- Produces genuine disagreements
- Enables honest positions

### Artifacts

| Workflow | Artifact Types |
|----------|----------------|
| **specs** | REQ (requirements), BR (business rules), NFR (non-functional), EX (exclusions) |
| **design** | ARCH (decisions), COMP (components), INT (interfaces) |
| **brainstorm** | IDEA (ideas), RISK (risks), MIT (mitigations) |
| **all** | OQ (open questions), CONF (conflicts) |

---

## Strategies

Strategies define how roundtable discussions are facilitated.

| Strategy | Phases | Best For |
|----------|--------|----------|
| **Standard** | 1 | General discussions |
| **Disney** | 3: Dreamer → Realist → Critic | Creative ideation |
| **Debate** | 4: Opening → Rebuttal → Closing → Synthesis | Evaluating options |
| **Consensus-Driven** | 3: Proposal → Refinement → Convergence | Building agreement |
| **Six Hats** | 7: Blue → White → Red → Black → Yellow → Green → Blue | Comprehensive analysis |

Default strategies:
- `specs` → Consensus-Driven
- `design` → Debate
- `brainstorm` → Disney

---

## Participants

12 specialized agents provide domain expertise:

| Agent | Focus |
|-------|-------|
| Product Manager | User value, priorities |
| Software Architect | System structure, patterns |
| Technical Lead | Implementation feasibility |
| QA Lead | Testability, edge cases |
| Security Champion | Threats, compliance |
| DevOps Engineer | Deployment, monitoring |
| UX Researcher | Usability, accessibility |
| Business Analyst | Domain rules, use cases |
| Documentation Specialist | Clarity, completeness |
| Claude Code Expert | Platform constraints |
| OSS Community Manager | Contributor experience |

---

## Sessions

Sessions persist roundtable state in `.s2s/sessions/*.yaml`:

- **Status**: active, paused, closed
- **Rounds**: all round summaries and positions
- **Artifacts**: requirements, decisions, conflicts
- **Agent state**: for resume capability

### Session Commands

| Command | Purpose |
|---------|---------|
| `/s2s:session` | Show current status |
| `/s2s:session:list` | List all sessions |
| `/s2s:session:validate` | Check consistency |
| `/s2s:session:close` | Close active session |

---

## Standards

Spec2Ship produces artifacts in established formats:

| Standard | Used For |
|----------|----------|
| **arc42** | Architecture documentation |
| **ISO 25010** | Quality requirements |
| **MADR** | Decision records |
| **Conventional Commits** | Commit messages |
| **STRIDE** | Threat modeling |

