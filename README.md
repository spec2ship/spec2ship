<p align="center">
  <img src=".github/hero.png" alt="Spec2Ship" width="100%">
</p>

<h3 align="center">
  Spec-driven development framework that orchestrates multi-agent workflows on top of Claude Code
</h3>

<p align="center">
  A Claude Code plugin for structured spec-driven design, planning, and execution.
</p>

---

## What Spec2Ship Is

Spec2Ship is a **Claude Code plugin** that adds structured orchestration for requirements, architecture, and implementation planning.

The core idea: instead of prompting Claude Code directly, you run **roundtable discussions** where multiple agents—each representing a real role (Product Manager, Architect, QA Lead, Security Champion)—debate and refine decisions collaboratively.

**It is:**
- A spec-driven framework where specifications are treated as executable intent
- An orchestration layer built on Claude Code primitives (commands, skills, sessions)
- A deliberation system with configurable facilitation strategies

**It is not:**
- A standalone CLI or generic tool (requires Claude Code)
- A prompt library or template pack
- A code generator (it produces specs and plans; you write the code)

---

## Why Not Just Prompt Claude Code Directly?

When you prompt Claude Code for requirements or architecture decisions:

| What happens | The problem |
|--------------|-------------|
| Single perspective | Optimized for agreement, not rigor |
| No adversarial review | Security gaps, edge cases, feasibility issues missed |
| Freeform output | Hard to review, audit, or hand off to team |
| Ephemeral sessions | Context lost between conversations |
| No structure | Each session starts from scratch |

**Spec2Ship solves this** by:
- Convening **12 specialized agents** with distinct viewpoints
- Enforcing **structured discussion** via facilitation strategies
- Producing **standards-based artifacts** (arc42, ISO 25010, MADR)
- Persisting **sessions with full audit trail**
- Supporting **escalation triggers** for human review

---

## How Spec2Ship Compares

| Aspect | Spec2Ship | [Claude-Flow](https://github.com/ruvnet/claude-flow) | [Spec-Kit](https://github.com/github/spec-kit) | [OpenSpec](https://github.com/Fission-AI/OpenSpec) |
|--------|-----------|-------------|----------|----------|
| **Approach** | Multi-agent deliberation | Swarm task execution | Document checkpoints | Lightweight diffs |
| **Agents** | 12 specialized roles debating | 54+ task workers | Single agent | Single agent |
| **Quality mechanism** | Adversarial review built-in | Speed optimization | Human review points | Minimal overhead |
| **Strategies** | 5 facilitation methods | Hierarchical/mesh | Linear | Linear |
| **Output** | arc42, ISO 25010, MADR | Custom | Markdown | Diff-based |
| **Best for** | Decisions needing debate | Parallel task execution | Greenfield features | Brownfield changes |

**Choose Spec2Ship when:**
- Decisions need multiple expert perspectives
- You want adversarial review (security, scalability, edge cases)
- Artifacts must be auditable and standards-based
- You're already using Claude Code

**Choose alternatives when:**
- **Claude-Flow**: You need to parallelize many independent tasks
- **Spec-Kit**: Simple greenfield specs with checkpoint review
- **OpenSpec**: Incremental changes to existing codebases

---

## Quick Start

```bash
# 1. Add the plugin
/plugin marketplace add spec2ship/spec2ship

# 2. Install it
/plugin install s2s

# 3. Initialize your project
/s2s:init

# 4. Run your first roundtable
/s2s:specs
```

After `/s2s:specs` completes, you'll have:
- `.s2s/sessions/YYYYMMDD-specs-*.yaml` — full discussion transcript
- `.s2s/requirements.md` — structured requirements with IDs (REQ-001, REQ-002...)

---

## Roundtable: The Core Primitive

Roundtable is not a feature—it's **the fundamental abstraction** of Spec2Ship.

Every major decision flows through a structured discussion:

```
┌────────────────────────────────────────────────────────────────┐
│                        ROUNDTABLE                              │
│                                                                │
│   FACILITATOR                                                  │
│   ├── Generates questions from agenda                         │
│   ├── Prepares context for each participant                   │
│   └── Synthesizes responses into artifacts                    │
│                                                                │
│   PARTICIPANTS (respond in parallel, blind to each other)     │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│   │    PM    │ │ Architect│ │ QA Lead  │ │ Security │  ...   │
│   │          │ │          │ │          │ │ Champion │        │
│   │  Value   │ │  System  │ │  Edge    │ │  Threat  │        │
│   │ & scope  │ │  design  │ │  cases   │ │  model   │        │
│   └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
│                                                                │
│   OUTPUT: Numbered artifacts with provenance                   │
│   REQ-001, ARCH-002, CONF-003...                              │
└────────────────────────────────────────────────────────────────┘
```

### Why This Matters

**Blind voting**: Participants respond without seeing each other. This prevents anchoring, reduces sycophancy, and surfaces genuine disagreements.

**Role-based expertise**: Each agent anchors to domain principles:
- **Product Manager** catches feature creep and unclear value
- **Architect** catches scalability issues and tech debt
- **QA Lead** catches missing acceptance criteria and edge cases
- **Security Champion** catches vulnerabilities and compliance gaps
- **DevOps Engineer** catches operational burden and scaling limits

**Concrete output**: Not chat transcripts—structured artifacts:

```markdown
## REQ-001: User Authentication
**Priority**: Must-have
**Source**: Roundtable 20250117-specs-auth, Round 2
**Acceptance Criteria**:
- User can log in with email/password
- Session expires after 24h inactivity
- Failed attempts rate-limited (5/min)

**Participants**: PM (proposed), Architect (refined), Security (hardened)
**Agreement**: Consensus
```

### Facilitation Strategies

Different decisions need different discussion structures:

| Strategy | Phases | When to use |
|----------|--------|-------------|
| **Standard** | Single round | General input, simple decisions |
| **Disney** | Dreamer → Realist → Critic | Creative exploration, new features |
| **Debate** | Opening → Rebuttal → Closing | Trade-offs, technology choices |
| **Consensus-Driven** | Propose → Refine → Converge | Requirements, team alignment |
| **Six Hats** | Facts → Emotions → Risks → Benefits → Ideas → Process | Complex decisions needing thorough analysis |

Strategies are auto-detected from topic keywords or explicitly specified:

```bash
/s2s:roundtable "new payment flow"           # → Disney (creative keyword)
/s2s:roundtable "REST vs GraphQL"            # → Debate (comparison keyword)
/s2s:design --strategy six-hats              # → Explicit override
```

---

## Operational Flow

Spec2Ship guides you through a real development pipeline:

```
┌──────────┐    ┌───────────┐    ┌───────┐    ┌────────┐    ┌──────┐
│   init   │───▶│ brainstorm│───▶│ specs │───▶│ design │───▶│ plan │
│          │    │ (optional)│    │       │    │        │    │      │
│ Analyze  │    │ Explore   │    │ Define│    │ Decide │    │ Break│
│ project  │    │ ideas     │    │ WHAT  │    │ HOW    │    │ down │
└──────────┘    └───────────┘    └───────┘    └────────┘    └──────┘
```

### What happens at each phase

| Command | What runs | What's produced |
|---------|-----------|-----------------|
| `/s2s:init` | Project analysis | `.s2s/CONTEXT.md`, `config.yaml` |
| `/s2s:brainstorm "topic"` | Disney roundtable | Ideas, risks, mitigations |
| `/s2s:specs` | Consensus-driven roundtable | `requirements.md` with REQ-*, BR-*, NFR-* |
| `/s2s:design` | Debate roundtable | `architecture.md` + ADRs with ARCH-*, COMP-* |
| `/s2s:plan` | Plan generation | `plans/*.md` with tasks and dependencies |

Each phase can run independently. Missing prerequisites trigger prompts, not failures.

---

## Autonomous vs Interactive Mode

Spec2Ship supports both modes—this is a **design choice**, not a limitation.

### Autonomous Mode (default)

Roundtables run end-to-end without interruption:

```bash
/s2s:specs    # Runs complete requirements roundtable
```

The facilitator manages all rounds automatically. Results are written to session files for review after completion.

### Interactive Mode

Human-in-the-loop when you want control:

```bash
/s2s:specs --interactive    # Pauses after each round
```

You review each round's output and can redirect the discussion.

### Escalation Triggers

Even in autonomous mode, the system pauses for human input when:
- **Low confidence** (<50%) on a decision
- **Critical keywords**: "security vulnerability", "legal requirement", "breaking change"
- **Unresolved conflicts** after maximum rounds
- **Blocking questions** that prevent progress

This means Spec2Ship knows when to ask for help—it's not a black-box generator.

---

## Supported Standards

Specifications and designs use established formats:

| Standard | Used for | Output example |
|----------|----------|----------------|
| **arc42** | Architecture documentation | Context, components, runtime views |
| **ISO 25010** | Quality requirements | Performance, security, maintainability targets |
| **MADR** | Decision records | Options, rationale, consequences |
| **STRIDE** | Threat modeling | Threat categories, mitigations |
| **Conventional Commits** | Commit messages | `feat(auth): add OAuth2 support` |

Why this matters:
- **Determinism**: Same input → predictable structure
- **Reviewability**: Teams can audit decisions
- **Handoff**: Artifacts work across tools and people

---

## Commands

### Workflow

| Command | Purpose | Default strategy |
|---------|---------|------------------|
| `/s2s:init` | Analyze project, create context | — |
| `/s2s:brainstorm "topic"` | Creative exploration | Disney |
| `/s2s:specs` | Define requirements | Consensus-driven |
| `/s2s:design` | Design architecture | Debate |
| `/s2s:plan` | Generate implementation plan | — |
| `/s2s:roundtable "topic"` | Generic roundtable | Auto-detected |

### Session management

| Command | Purpose |
|---------|---------|
| `/s2s:session` | Current session status |
| `/s2s:session:list` | List all sessions |
| `/s2s:session:validate` | Check consistency |
| `/s2s:session:close` | Close active session |

### Flags

| Flag | Effect |
|------|--------|
| `--strategy <name>` | Override facilitation strategy |
| `--participants <list>` | Specify which agents participate |
| `--interactive` | Pause after each round |
| `--verbose` | Save detailed round dumps |

---

## Extensibility

Spec2Ship is designed to be extended:

| What | How |
|------|-----|
| New agent role | Add `agents/roundtable/{name}.md` |
| New strategy | Add to `skills/roundtable-strategies/` |
| New output format | Add template to `templates/` |
| New workflow | Add `commands/{name}.md` |

For extension guides, ask Claude: `"how to extend s2s"`

---

## Documentation

- [Core Concepts](docs/concepts.md) — Workflows, roundtables, sessions
- [Architecture](docs/architecture/) — System design and ADRs

For interactive help:
- `"what commands does s2s have"` — Command reference
- `"how do roundtables work"` — Detailed explanation
- `"how to create a new agent"` — Extension guide

---

## Roadmap

See [BACKLOG.md](.s2s/BACKLOG.md) for planned work.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT — see [LICENSE](LICENSE)
