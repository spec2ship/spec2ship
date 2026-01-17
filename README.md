<p align="center">
  <img src=".github/hero.png" alt="Spec2Ship: Multi-agent development, from specs to shipping">
</p>

<p align="center">
  <strong>Structured multi-agent deliberation for Claude Code</strong><br>
  Transform specifications into implementations through expert roundtable discussions
</p>

<p align="center">
  <a href="#installation">Install</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#roundtable-the-core-primitive">Roundtable</a> •
  <a href="#why-spec2ship">Why Spec2Ship</a> •
  <a href="docs/">Docs</a>
</p>

---

## What Spec2Ship Is

Spec2Ship is a **Claude Code plugin** that orchestrates multi-agent deliberations for requirements, architecture, and planning. Instead of prompting a single AI, you convene a roundtable of specialized agents—Product Manager, Architect, QA Lead, Security Champion—who debate, challenge, and refine decisions collaboratively.

**It is:**
- A structured orchestration layer on top of Claude Code primitives (commands, skills, sessions)
- A spec-driven framework producing auditable artifacts (requirements, ADRs, plans)
- A deliberation engine with multiple facilitation strategies (Disney, Debate, Six Hats)

**It is not:**
- A prompt library or template collection
- A standalone CLI (requires Claude Code)
- A code generator (it produces specs and plans; you implement them)

---

## Why Spec2Ship

### The Problem with Single-Agent AI Development

When you prompt Claude Code directly for requirements or architecture:
- You get **one perspective** optimized for agreement
- Decisions lack **adversarial review** (security, edge cases, feasibility)
- There's no **structured format** for team review and audit
- Sessions are ephemeral—**context is lost** between conversations

### How Spec2Ship Solves This

| Challenge | Spec2Ship Solution |
|-----------|-------------------|
| Single perspective | 12 specialized agents with distinct viewpoints |
| No adversarial review | Strategies like Debate and Six Hats enforce critical analysis |
| Unstructured output | Standards-based artifacts (arc42, ISO 25010, MADR) |
| Lost context | Persistent sessions with resume capability |
| Black-box decisions | Full audit trail with conflict tracking |

---

## Comparison with Alternatives

| Feature | Spec2Ship | [Claude-Flow](https://github.com/ruvnet/claude-flow) | [Spec-Kit](https://github.com/github/spec-kit) | [OpenSpec](https://github.com/Fission-AI/OpenSpec) |
|---------|-----------|-------------|----------|----------|
| **Core approach** | Multi-agent deliberation | Swarm orchestration | Document checkpoints | Lightweight specs |
| **Agent model** | 12 specialized roles debating | 54+ task-focused workers | Single agent | Single agent |
| **Decision quality** | Adversarial review built-in | Speed-optimized | Human review points | Minimal overhead |
| **Facilitation strategies** | 5 (Disney, Debate, Six Hats...) | Hierarchical/mesh | Linear workflow | Linear workflow |
| **Output format** | arc42, ISO 25010, MADR | Custom | Markdown specs | Diff-based specs |
| **Session persistence** | Full resume + audit trail | Task queues | Git-based | File-based |
| **Best for** | Complex decisions needing debate | Parallel task execution | Greenfield features | Brownfield changes |
| **Platform** | Claude Code plugin | Standalone CLI | CLI + Copilot/Claude | Node.js CLI |

**When to choose Spec2Ship:**
- You need **multiple expert perspectives** on requirements or architecture
- Decisions require **adversarial review** (security, scalability, edge cases)
- You want **auditable artifacts** in standard formats
- You're already using **Claude Code** as your development environment

**When to choose alternatives:**
- **Claude-Flow**: You need to parallelize many independent tasks quickly
- **Spec-Kit**: You want lightweight specs for simple greenfield features
- **OpenSpec**: You're making incremental changes to existing codebases

---

## Installation

```bash
# Add the plugin marketplace
/plugin marketplace add spec2ship/spec2ship

# Install the plugin
/plugin install s2s
```

Requires [Claude Code](https://claude.ai/code) CLI.

---

## Quick Start

```bash
# 1. Initialize your project (analyzes codebase, creates context)
/s2s:init

# 2. Define requirements via roundtable discussion
/s2s:specs

# 3. Design architecture via roundtable discussion
/s2s:design

# 4. Generate implementation plan
/s2s:plan

# 5. Execute the plan
/s2s:plan --session "plan-id"
```

Each roundtable command (`specs`, `design`, `brainstorm`) convenes specialized agents who discuss, debate, and produce structured artifacts.

---

## Roundtable: The Core Primitive

Roundtable is not just a feature—it's the **fundamental abstraction** that makes Spec2Ship different. Every major decision flows through a structured multi-agent discussion.

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                         ROUNDTABLE                               │
│                                                                  │
│  ┌──────────┐    ┌──────────────────────────────────────────┐   │
│  │Facilitator│───▶│ Generates questions, manages rounds      │   │
│  └──────────┘    └──────────────────────────────────────────┘   │
│        │                                                         │
│        ▼                                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    PARTICIPANTS                           │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │   │
│  │  │   PM    │ │Architect│ │QA Lead  │ │Security │  ...   │   │
│  │  │         │ │         │ │         │ │Champion │        │   │
│  │  │ User    │ │ System  │ │ Edge    │ │ Threat  │        │   │
│  │  │ value   │ │ design  │ │ cases   │ │ model   │        │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘        │   │
│  └──────────────────────────────────────────────────────────┘   │
│        │                                                         │
│        ▼                                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                 STRUCTURED ARTIFACTS                      │   │
│  │  REQ-001, REQ-002...  │  ARCH-001, ARCH-002...           │   │
│  │  Conflicts tracked    │  Decisions documented            │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Participants (12 Specialized Agents)

| Agent | Perspective | Catches |
|-------|-------------|---------|
| **Product Manager** | User value, priorities, scope | Feature creep, unclear value |
| **Software Architect** | System structure, patterns | Scalability issues, tech debt |
| **Technical Lead** | Implementation feasibility | Unrealistic estimates, complexity |
| **QA Lead** | Testability, edge cases | Missing acceptance criteria |
| **Security Champion** | Threats, compliance | Vulnerabilities, OWASP gaps |
| **DevOps Engineer** | Deployment, monitoring | Ops burden, scaling limits |
| **UX Researcher** | Usability, accessibility | Poor user experience |
| **Business Analyst** | Domain rules, use cases | Business logic gaps |
| **Documentation Specialist** | Clarity, completeness | Undocumented decisions |

### Facilitation Strategies

Different decisions need different discussion structures:

| Strategy | Phases | Best For | Example |
|----------|--------|----------|---------|
| **Standard** | Single round | General input | "Review this API design" |
| **Disney** | Dreamer → Realist → Critic | Creative solutions | "New feature ideas" |
| **Debate** | Opening → Rebuttal → Closing | Controversial choices | "REST vs GraphQL" |
| **Consensus-Driven** | Propose → Refine → Converge | Fast agreement | "Sprint priorities" |
| **Six Hats** | Facts → Emotions → Risks → Benefits → Ideas → Process | Comprehensive analysis | "Major architecture change" |

```bash
# Auto-detected based on topic keywords
/s2s:roundtable "new payment integration"  # → Disney (creative)
/s2s:roundtable "microservices vs monolith" # → Debate (evaluation)

# Or explicitly specified
/s2s:roundtable "auth redesign" --strategy six-hats
```

### Output Artifacts

Roundtables produce numbered, trackable artifacts:

```markdown
## REQ-001: User Authentication
**Priority**: Must-have
**Source**: Roundtable 20250117-specs-auth, Round 2
**Acceptance Criteria**:
- User can log in with email/password
- Session expires after 24 hours of inactivity
- Failed attempts are rate-limited (5/minute)

**Participants**: PM (proposed), Architect (refined), Security (hardened)
**Status**: Consensus
```

---

## Autonomous vs Interactive Modes

Spec2Ship supports both modes—this is a **design feature**, not a limitation.

### Autonomous Mode (Default)

Roundtables run end-to-end without interruption:
- Facilitator manages all rounds automatically
- Escalation triggers pause execution when needed
- Results are written to session files for review

```bash
/s2s:specs  # Runs full requirements roundtable
```

### Interactive Mode

Human-in-the-loop for critical decisions:

```bash
/s2s:specs --interactive  # Pauses after each round for review
```

### Escalation Triggers

Even in autonomous mode, the system escalates to human review when:
- **Confidence drops below 50%** on a decision
- **Critical keywords detected**: "security vulnerability", "legal requirement", "breaking change"
- **Unresolved conflicts** after maximum rounds
- **Blocking open questions** prevent progress

This means Spec2Ship is **not a black-box generator**—it knows when to ask for help.

---

## Supported Standards

Spec2Ship produces artifacts in established formats:

| Standard | Used For | Example Output |
|----------|----------|----------------|
| **arc42** | Architecture documentation | Context, building blocks, runtime views |
| **ISO 25010** | Quality requirements | Performance, security, maintainability targets |
| **MADR** | Decision records | Options, rationale, consequences |
| **Conventional Commits** | Commit messages | `feat(auth): add OAuth2 support` |
| **STRIDE** | Threat modeling | Threat categories, mitigations |
| **DDD Strategic** | Domain modeling | Bounded contexts, ubiquitous language |

---

## Commands

### Workflow Commands

| Command | Purpose | Default Strategy | Output |
|---------|---------|------------------|--------|
| `/s2s:init` | Analyze project, create context | — | `.s2s/CONTEXT.md` |
| `/s2s:specs` | Define requirements | Consensus-driven | `requirements.md` |
| `/s2s:design` | Design architecture | Debate | `architecture.md` + ADRs |
| `/s2s:brainstorm "topic"` | Creative exploration | Disney | Ideas + risks |
| `/s2s:plan` | Generate implementation plan | — | `plans/*.md` |
| `/s2s:roundtable "topic"` | Generic discussion | Auto-detected | Depends on output-type |

### Session Management

| Command | Purpose |
|---------|---------|
| `/s2s:session` | Show current session status |
| `/s2s:session:list` | List all sessions |
| `/s2s:session:validate` | Check session consistency |
| `/s2s:session:close` | Close active session |

### Plan Management

| Command | Purpose |
|---------|---------|
| `/s2s:plan --new` | Create new plan |
| `/s2s:plan --session "id"` | Resume specific plan |
| `/s2s:plan:list` | List all plans |
| `/s2s:plan:close` | Mark plan as complete |

### Common Flags

| Flag | Effect |
|------|--------|
| `--strategy <name>` | Override facilitation strategy |
| `--participants <list>` | Specify which agents participate |
| `--interactive` | Pause after each round |
| `--verbose` | Save detailed round dumps |
| `--diagnostic` | Enable debugging analysis |

---

## Extensibility

Spec2Ship is designed to be extended:

| Extension | How | Example |
|-----------|-----|---------|
| **New agent role** | Add `agents/roundtable/{name}.md` | Domain Expert, Legal Reviewer |
| **New strategy** | Add to `skills/roundtable-strategies/` | Socratic method, Red Team |
| **New output format** | Add template to `templates/` | Custom spec format |
| **New workflow** | Add `commands/{name}.md` | `/s2s:review`, `/s2s:retrospective` |

For extension guides, ask Claude: `"how to extend s2s"` (loads the `s2s-guide` skill).

---

## Project Structure

```
.s2s/                    # Created in your project
├── config.yaml          # Project configuration
├── CONTEXT.md           # Project context for AI
├── sessions/            # Roundtable session files
├── plans/               # Implementation plans
└── decisions/           # Architecture decision records
```

---

## Documentation

- [Core Concepts](docs/concepts.md) — Workflows, roundtables, sessions explained
- [Architecture](docs/architecture/) — System design and ADRs

For interactive help, ask Claude:
- `"what commands does s2s have"` — Command reference
- `"how do roundtables work"` — Detailed explanation
- `"how to create a new agent"` — Extension guide

---

## Roadmap

See [BACKLOG.md](.s2s/BACKLOG.md) for planned features and improvements.

Key areas:
- [ ] Workspace support for monorepos
- [ ] Custom agent creation wizard
- [ ] Integration with external issue trackers
- [ ] Export to Notion/Confluence

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Key principles:
- Commands are imperative, agents are second-person, skills are third-person
- Use `**Use the roundtable-X agent**` pattern for agent invocation
- All artifacts must be numbered and trackable

---

## License

MIT License — see [LICENSE](LICENSE)

---

<p align="center">
  <em>Spec2Ship — From specifications to shipping, through structured deliberation</em>
</p>
