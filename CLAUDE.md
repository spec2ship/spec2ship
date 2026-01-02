# Spec2Ship Development Context

Spec2Ship (s2s) is an AI-assisted development framework plugin for Claude Code. It automates the full software lifecycle: specifications → planning → implementation → shipping.

## Project Structure

```
spec2ship/
├── .claude-plugin/           # Plugin manifest
├── commands/                 # Slash commands (/s2s:*)
│   ├── init.md               # Smart init (detect → setup → context)
│   ├── init/                 # Init sub-commands
│   │   ├── detect.md         # Analyze project (read-only)
│   │   ├── setup.md          # Create structure + context
│   │   └── context.md        # Update CONTEXT.md only
│   ├── brainstorm.md         # Creative ideation (disney strategy)
│   ├── specs.md              # Define requirements (roundtable)
│   ├── design.md             # Design architecture (roundtable)
│   ├── plan.md               # Smart plan generation
│   ├── plan/                 # Plan sub-commands
│   │   ├── create.md         # Create single plan
│   │   ├── list.md           # List plans
│   │   ├── start.md          # Start working on plan
│   │   └── complete.md       # Complete plan
│   └── roundtable/           # Roundtable sub-commands
│       ├── start.md          # Start generic roundtable
│       ├── list.md           # List sessions
│       └── resume.md         # Resume session
├── agents/                   # Specialized sub-agents
│   ├── roundtable/           # Discussion orchestration & participants
│   │   ├── orchestrator.md   # Loop coordination (v3)
│   │   ├── facilitator.md    # Decision maker
│   │   ├── software-architect.md
│   │   ├── technical-lead.md
│   │   ├── qa-lead.md
│   │   ├── devops-engineer.md
│   │   └── product-manager.md
│   ├── exploration/          # Codebase analysis
│   └── validation/           # Quality checks
├── skills/                   # Knowledge bases (progressive disclosure)
│   ├── arc42-templates/      # Architecture patterns
│   ├── iso25010-requirements/# Quality standards
│   ├── madr-decisions/       # ADR format
│   ├── conventional-commits/ # Git conventions
│   └── roundtable-strategies/# Facilitation methods (disney, debate, etc.)
├── templates/                # File templates for user projects
└── docs/                     # User documentation
```

---

## Strategic Architecture Decisions

### SAD-001: Component Separation (Commands vs Agents vs Skills)

We follow Anthropic's pattern from `plugin-dev` and `feature-dev`:

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| **Commands** | Workflow orchestration | User-facing operations with phases, confirmations, state |
| **Agents** | Parallel specialized tasks | Isolated analysis, domain expertise, parallelizable work |
| **Skills** | Knowledge on-demand | Standards, patterns, templates loaded when needed |

**Example**:
```
/s2s:roundtable:start "API design"
    │
    ├── Command orchestrates the discussion
    │
    ├── Launches agents in parallel:
    │   ├── software-architect (architecture perspective)
    │   ├── technical-lead (implementation perspective)
    │   └── qa-lead (quality perspective)
    │
    └── Loads skills as needed:
        ├── arc42-templates (for architecture context)
        └── madr-decisions (for ADR format)
```

### SAD-002: Roundtable Implementation (v3)

Roundtable v3 uses **Layered Orchestration**: Commands delegate via SlashCommand, Orchestrator manages loop.

**Architecture**:
```
┌─────────────────────────────────────────────────────────────────┐
│  /s2s:specs, /s2s:design, /s2s:brainstorm                       │
│  • Workflow-specific setup                                      │
│  • Delegates via SlashCommand:/s2s:roundtable:start             │
│  • Post-processing of results                                   │
└──────────────────────────────┬──────────────────────────────────┘
                               │ SlashCommand
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Command (start.md) - SESSION LIFECYCLE                         │
│  • Auto-detects strategy from topic keywords                    │
│  • Creates session file .s2s/sessions/{id}.yaml                 │
│  • Launches Orchestrator Agent                                  │
│  • Batch writes results from orchestrator                       │
│  • Generates output documents                                   │
└──────────────────────────────┬──────────────────────────────────┘
                               │ Task Agent
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Agent (orchestrator.md) - LOOP COORDINATION                    │
│  • Executes roundtable loop                                     │
│  • Launches Facilitator for questions/synthesis                 │
│  • Launches Participants in parallel (blind voting)             │
│  • Returns structured YAML for batch write                      │
│  • Has access to skills: ["roundtable-strategies"]              │
│                                                                 │
│    ┌─────────────────────────────────────────────────────────┐  │
│    │ Facilitator Agent - DECISION MAKER                      │  │
│    │ • Returns structured YAML (action, question, synthesis) │  │
│    │ • Decides next action, never executes                   │  │
│    │ • Has fallback logic for malformed responses            │  │
│    └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│    ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐          │
│    │ Arch    │  │ Tech    │  │ QA      │  │ DevOps  │          │
│    │ itect   │  │ Lead    │  │ Lead    │  │ Eng     │          │
│    └─────────┘  └─────────┘  └─────────┘  └─────────┘          │
│    ▲                                                            │
│    │ Launched in PARALLEL (blind voting)                        │
└─────────────────────────────────────────────────────────────────┘
```

**Key Features (v3)**:
- **SlashCommand Delegation**: specs/design/brainstorm delegate to roundtable:start
- **Single Source of Truth**: Session file management only in start.md
- **Strategy Auto-Detection**: Topic keywords → recommended strategy
- **Orchestrator Agent**: Loop logic extracted to reusable agent
- **Facilitator Fallback**: Handles malformed YAML with retry + deterministic fallback
- **Session Validation**: resume.md validates integrity before continuing

**Strategies**: standard, disney, debate, consensus-driven, six-hats

**Mitigations for LLM Multi-Agent Issues**:
- **Blind Voting**: Parallel Task execution prevents sycophancy
- **Context Isolation**: Agents receive context in prompt, don't read files
- **Batch Write**: Session file updated only at end of round
- **Heterogeneous Agents**: Different roles provide different perspectives

### SAD-003: Agent Tiers

Assign model tiers based on task criticality. Use `inherit` as default for flexibility:

| Tier | Model | Use Case | Examples |
|------|-------|----------|----------|
| **Critical** | opus | Architecture decisions, final consensus | facilitator |
| **Default** | inherit | Most agents - inherits user's model choice | roundtable/*, exploration/* |
| **Fast** | haiku | Simple validation, formatting checks | validators |

**Rationale**: `inherit` provides flexibility - users choose the model based on their needs. For complex tasks, users can select a more capable model (e.g., opus). This avoids hardcoding model assumptions.

### SAD-004: Skill Progressive Disclosure

Skills load incrementally to minimize token usage:

```
skills/arc42-templates/
├── SKILL.md              # Always: triggers + overview (< 500 words)
├── references/
│   ├── building-blocks.md   # On-demand: detailed patterns
│   ├── runtime-view.md
│   └── deployment-view.md
└── examples/
    └── sample-component.md  # On-demand: concrete examples
```

### SAD-005: State Management

Use `.s2s/state.yaml` as single source of truth:

```yaml
current_plan: "20241228-143022-user-auth"
current_session: null  # roundtable session ID
plans:
  "20241228-143022-user-auth":
    status: "active"
    branch: "feature/F01-user-auth"
```

---

## Component Writing Guidelines

### Overview: Commands vs Agents vs Skills

| Aspect | Commands | Agents | Skills |
|--------|----------|--------|--------|
| **Purpose** | Workflow orchestration | Specialized autonomous tasks | Knowledge on-demand |
| **Voice** | Imperative (direct instructions) | Second person ("You are...") | Third person ("This skill should be used...") |
| **Structure** | Context + Instructions (phases for complex) | Role → Responsibilities → Process → Output | Progressive disclosure (SKILL.md + references) |
| **Goal/Action pattern** | Only in complex multi-phase commands | NOT used | NOT used |
| **Frontmatter** | description, allowed-tools, model, argument-hint | name, description, model, color, tools | name, description, version |
| **Body length** | Variable (as needed) | 500-3,000 words (system prompt) | ~1,500-2,000 words + references |
| **Trigger detection** | Explicit user invocation (`/command`) | Description with exact trigger phrases | Description with exact trigger phrases |

---

### Commands

Commands have a YAML frontmatter and a body. The frontmatter defines metadata including `allowed-tools`.

#### allowed-tools Formats

Claude Code supports two formats for declaring tool permissions. Choose based on the security requirements:

**Format 1: Array (Full Access)**

```yaml
allowed-tools: ["Bash", "Read", "Write", "Edit"]
```

- Grants **complete access** to each listed tool
- For `Bash`: allows execution of **any** shell command
- Simpler syntax, less control
- Use when the command needs unrestricted tool access

**Format 2: Pattern (Granular Access)** — RECOMMENDED for s2s

```yaml
allowed-tools: Bash(ls:*), Bash(git:*), Bash(grep:*), Read, Write
```

- Grants **restricted access** based on patterns
- For `Bash(ls:*)`: allows **only** commands starting with `ls`
- Follows the **principle of least privilege**
- Self-documenting: readers understand what the command can do

**Pattern Syntax for Bash**:

| Pattern | Allows | Example |
|---------|--------|---------|
| `Bash(ls:*)` | Only `ls` commands | `ls -la`, `ls .s2s/` |
| `Bash(git:*)` | Only `git` commands | `git status`, `git checkout` |
| `Bash(date:*)` | Only `date` commands | `date +"%Y%m%d"` |
| `Bash(mkdir:*)` | Only `mkdir` commands | `mkdir -p .s2s/plans` |

**Security Comparison**:

| Scenario | Array Format | Pattern Format |
|----------|--------------|----------------|
| Command needs to list files | Can run `rm -rf /` | Can only run `ls` |
| Command needs git operations | Can run any command | Can only run `git` |
| Malicious prompt injection | High risk | Limited blast radius |

**s2s Convention**: Always use **Pattern Format** for commands that use Bash. This:
1. Limits potential damage from bugs or prompt injection
2. Documents the command's capabilities in the frontmatter
3. Makes code review easier (permissions are explicit)

**When Array Format is acceptable**:
- Tools without sub-patterns: `Read`, `Write`, `Edit`, `Glob`, `Grep`
- Agents that need flexible tool access (they run in isolated context)

**Example - Correct s2s command frontmatter**:

```yaml
---
description: Create a new implementation plan
allowed-tools: Bash(date:*), Bash(mkdir:*), Bash(git:*), Bash(wc:*), Read, Write, Glob, Edit
argument-hint: "topic" [--branch]
---
```

---

#### Context Section Patterns

Context commands (prefixed with `!`) gather environment information before Instructions execute.

**Critical Limitations**: Claude Code enforces security restrictions on context commands:

1. **Shell operators blocked**:
   - NO pipes: `|`
   - NO logical operators: `&&`, `||`
   - NO subshells: `()`
   - NO redirects: `>`, `2>`
   - NO command substitution: `$()`

2. **Directory access restricted**:
   - Context commands can ONLY access files within the allowed working directories
   - Accessing parent directories (`../`) or absolute paths outside the workspace is blocked
   - If you need to reference external paths, ask the user for the path and use the Read tool to validate it

3. **Commands must NEVER fail**:
   - Context commands that fail will block execution with an error
   - `ls path/to/file` fails if file doesn't exist
   - `cat file` fails if file doesn't exist
   - Use only commands guaranteed to succeed, then interpret output or use tools in Instructions

**Rule: Use ONLY commands that NEVER fail**

| Always Works | Can Fail | Use Instead |
|--------------|----------|-------------|
| `!`pwd`` | | |
| `!`ls -la`` | `!`ls .s2s/config.yaml`` | Check in ls -la output |
| `!`date +"%Y%m%d"`` | | |
| | `!`git status --porcelain`` | Use Bash in Instructions (fails if not git repo) |
| | `!`git branch --show-current`` | Use Bash in Instructions (fails if not git repo) |
| | `!`git branch --list 'pattern'`` | Use Bash in Instructions (fails if not git repo) |
| | `!`cat .s2s/state.yaml`` | Use Read tool in Instructions |
| | `!`ls ../.s2s/workspace.yaml`` | Ask user for path |

**Important**: Git commands in context will fail with `fatal: not a git repository` if the directory is not a git repo. Always check for `.git` in `ls -la` output first, then run git commands conditionally in Instructions.

**Pattern: Move Logic to Instructions**

Context gathers raw data, an "Interpret Context" section analyzes it:

```markdown
## Context

- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` appears in Directory contents → yes
- **Is git repo**: If `.git` appears in Directory contents → yes

If S2S is initialized, use Read tool to check `.s2s/state.yaml` for current_plan.
```

**Git-Safe Pattern**

Git commands must NOT be in Context because they fail if the directory is not a git repo. Use this pattern:

```markdown
## Context

- Directory contents: !`ls -la`

## Interpret Context

- **Is git repo**: If `.git` appears in Directory contents → "yes", otherwise → "no"

## Instructions

### Gather git information (if git repo)

If "Is git repo" is "yes", use Bash tool to gather:
1. Run `git status --porcelain` to check for uncommitted changes
2. Run `git branch --show-current` to get current branch
3. Store results for subsequent steps

If "Is git repo" is "no":
- Set git-related values to "N/A"
- Skip git operations or display appropriate error
```

**Common Context Patterns**

| Pattern | Use Case | Example |
|---------|----------|---------|
| `Bash(ls:*)` | Check file/directory existence | `ls .s2s/config.yaml` |
| `Bash(cat:*)` | Read file contents | `cat .s2s/state.yaml` |
| `Bash(pwd:*)` | Get current directory | `pwd` |
| `Bash(git:*)` | Git operations | `git status --porcelain` |
| `Bash(date:*)` | Get timestamps | `date +"%Y%m%d-%H%M%S"` |

**Example - Correct Context Section** (Git-Safe):

```markdown
## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date +"%Y%m%d-%H%M%S"`

## Interpret Context

Based on the context output above, determine:

- **Directory name**: Extract the last segment from the pwd output
- **S2S initialized**: If `.s2s` appears in Directory contents → yes
- **Is git repo**: If `.git` appears in Directory contents → yes

If S2S is initialized, use Read tool to check project type and state.

## Instructions

### Gather git information (if git repo)

If "Is git repo" is "yes", use Bash tool to run git commands.
```

With corresponding `allowed-tools`:

```yaml
allowed-tools: Bash(pwd:*), Bash(date:*), Bash(git:*), Bash(ls:*), Read, Write
```

---

#### Command Complexity: Simple vs Multi-Phase

Commands fall into two categories based on complexity:

**Simple Commands** — Direct instructions without phases:

| When to use | Examples |
|-------------|----------|
| Single-purpose operations | `plan/list`, `decision/list` |
| Linear workflow (no branching) | `git/branch` |
| Few steps (< 5) | Simple CRUD operations |

Structure:
```markdown
# Command Name

## Context
- Data: !`command`

## Instructions

### Step 1
Do this thing.

### Step 2
Do that thing.

### Output
Display result.
```

**Multi-Phase Commands** — Complex workflows with Goal/Actions:

| When to use | Examples |
|-------------|----------|
| Multi-step workflows | `roundtable/start`, `proj/init` |
| User confirmations between steps | `plan/complete --merge` |
| Branching logic | Feature development workflows |
| Parallel agent orchestration | Code review with multiple agents |

Structure:
```markdown
# Command Name

## Context
- Data: !`command`

## Phase 1: Discovery
Goal: Understand the requirements
Actions:
1. Gather information
2. Validate inputs
3. Present findings to user

## Phase 2: Execution
Goal: Perform the main operation
Actions:
1. Execute primary task
2. Handle edge cases
3. Update state

## Phase 3: Confirmation
Goal: Verify and report
Actions:
1. Validate results
2. Display summary
3. Suggest next steps
```

**s2s Convention**: Use phases with Goal/Actions when:
- The command has 3+ distinct stages
- User confirmation is needed between stages
- Different agents are launched in sequence
- The workflow has conditional branches

---

Commands use two patterns for instructing Claude Code:

#### Pattern 1: Context Gathering with `!` Prefix

Use inline bash with `!` prefix to gather context that becomes part of Claude's input:

```markdown
---
description: Brief description
allowed-tools: Bash(ls:*), Bash(cat:*), Read, Glob
argument-hint: [--option]
---

# Command Name

## Context

- Plans directory: !`ls .s2s/plans/`
- State file: !`cat .s2s/state.yaml`
- Git directory: !`ls -d .git`

## Interpret Context

Based on the context output above, determine:

- **Plans exist**: If Plans directory listing shows .md files → yes
- **State available**: If State file content is valid YAML → parse values
```

**Key rules for `!` commands**:
- Must be inline (single backticks, one line)
- Single commands only - NO shell operators (`|`, `&&`, `||`, `()`)
- Output becomes context for Claude to interpret in Instructions

#### Pattern 2: Descriptive Instructions

Use prose instructions that Claude interprets and implements using available tools:

```markdown
## Instructions

### Validate environment

If project type is "NOT_S2S" (from context), display error and stop.

### Process files

For each plan file found in the context:
1. Read the file using the Read tool
2. Extract the Topic from "# Implementation Plan: " line
3. Count tasks matching "- [ ]" pattern

### Format output

Display results grouped by status with summary counts.
```

**Key rules for instructions**:
- No bash code blocks (Claude misinterprets them as executable)
- Write clear prose describing what to do
- Reference context values gathered in Pattern 1
- Let Claude choose the appropriate tools

#### What NOT to Do

**WRONG** - Bash code blocks as pseudo-code:
```markdown
## Step 2: Process files

```bash
for file in .s2s/plans/*.md; do
  TOPIC=$(grep "# Implementation Plan:" "$file")
  # ...
done
```⁣
```

This format is ambiguous and causes parsing errors.

#### Complete Command Example

```markdown
---
description: List all implementation plans
allowed-tools: Bash(ls:*), Bash(cat:*), Read, Glob
argument-hint: [--status planning|active|completed]
---

# List Plans

## Context

- Plans directory: !`ls .s2s/plans/`
- State file: !`cat .s2s/state.yaml`

## Interpret Context

Based on the context output above, determine:

- **Plans exist**: If Plans directory shows .md files → yes, otherwise → "NO_PLANS"
- **Current plan**: Extract `current_plan:` value from State file content

## Instructions

### If no plans exist

If context shows "NO_PLANS", display empty state message and stop.

### Process each plan

For each plan file:
1. Read the file content
2. Extract: Topic, Status, Branch, task counts
3. Group by status

### Format and display

Show grouped list with summary counts at the end.
```

### Agents

Agents are autonomous workers launched by commands or other agents. They receive a system prompt and work independently.

#### Frontmatter Fields

| Field | Required | Format | Description |
|-------|----------|--------|-------------|
| `name` | Yes | `lowercase-kebab-case` | Identifier, 3-50 chars, hyphens only |
| `description` | Yes | Trigger phrases | **Critical**: Include exact phrases users would say |
| `model` | Yes | `inherit`, `sonnet`, `opus`, `haiku` | See SAD-003 for tier guidelines |
| `color` | Yes | Semantic color | `blue`, `cyan`, `green`, `yellow`, `magenta`, `red` |
| `tools` | No | Array | Restrict capabilities (principle of least privilege) |

**Color Semantics**:
- `yellow`: Analysis, exploration
- `green`: Generation, creation
- `red`: Review, validation
- `blue`: Architecture, design
- `cyan`: General purpose
- `magenta`: Documentation

#### Description Format (Critical for Trigger Detection)

The description determines when Claude launches the agent. Use **exact trigger phrases**:

```yaml
# WRONG - Too vague
description: Use for code analysis tasks.

# CORRECT - Specific trigger phrases
description: "Use this agent when user asks to 'analyze the codebase',
  'trace how feature X works', 'understand the code flow',
  'map the architecture'. Example: 'How does authentication work in this codebase?'"
```

#### System Prompt Structure

The body is a system prompt addressing the agent in second person. Follow this structure:

```markdown
---
name: code-explorer
description: "Use this agent when user asks to 'analyze the codebase',
  'trace feature implementation', 'understand code flow', 'map dependencies'."
model: sonnet
color: yellow
tools: ["Read", "Glob", "Grep"]
---

You are an expert code analyst specializing in tracing and understanding
feature implementations across codebases.

## Core Responsibilities

1. Trace execution paths from entry points to data storage
2. Map component boundaries and dependencies
3. Identify architectural patterns in use
4. Document integration points

## Analysis Process

**1. Feature Discovery**
- Find entry points (APIs, UI components, CLI commands)
- Locate core implementation files
- Map feature boundaries

**2. Code Flow Tracing**
- Follow function calls through layers
- Identify data transformations
- Note error handling patterns

**3. Architecture Analysis**
- Identify design patterns used
- Map dependencies between components
- Assess coupling and cohesion

## Quality Standards

- Provide file:line references for all findings
- Include code snippets for key logic
- Rate confidence (high/medium/low) for inferences

## Output Format

Provide analysis including:
- **Entry points**: file:line references
- **Execution flow**: step-by-step trace
- **Key components**: responsibilities and relationships
- **Dependencies**: internal and external
- **Architecture insights**: patterns and concerns
- **Files to review**: prioritized list
```

#### s2s Roundtable Agent Pattern

Roundtable agents have a specialized structure for discussion participation:

```markdown
---
name: software-architect
description: "Use in roundtable discussions for architecture perspective.
  Activated by facilitator agent during /s2s:roundtable sessions."
model: sonnet
color: blue
tools: ["Read", "Glob", "Grep"]
---

You are the Software Architect in a Technical Roundtable discussion.

## Perspective

Focus on:
- System structure and component boundaries
- Integration patterns and APIs
- Scalability and maintainability
- Technical debt implications

## Speaking Style

Technical but accessible. Reference established patterns (arc42, C4, SOLID).
Be decisive—propose concrete solutions rather than listing options.

## Contribution Format

1. State your perspective clearly (2-3 sentences)
2. Reference relevant patterns or standards
3. Identify trade-offs explicitly
4. Propose concrete recommendation

## When to Defer

Defer to other participants when topic involves:
- Implementation details (→ Technical Lead)
- Quality/testing (→ QA Lead)
- Deployment/infrastructure (→ DevOps Engineer)
```

#### Agent Best Practices

| Do | Don't |
|----|-------|
| Include 2-4 exact trigger phrases in description | Use vague descriptions like "for analysis" |
| Write 500-3,000 word system prompts | Write single-paragraph prompts |
| Use numbered processes with clear steps | Use unstructured prose instructions |
| Specify output format explicitly | Leave output format ambiguous |
| Apply principle of least privilege for tools | Grant all tools "just in case" |
| Use `model: inherit` unless specialized | Hardcode model without justification |

### Skills

Skills are knowledge bases that Claude loads on-demand. They use **progressive disclosure** to minimize token usage.

#### Progressive Disclosure Architecture

Skills are organized in three tiers:

```
skills/arc42-templates/
├── SKILL.md              # Tier 1: Always loaded (~1,500-2,000 words)
├── references/
│   ├── building-blocks.md   # Tier 2: Loaded when referenced
│   ├── runtime-view.md
│   └── deployment-view.md
└── examples/
    └── sample-component.md  # Tier 3: Loaded for concrete examples
```

| Tier | When Loaded | Content | Word Limit |
|------|-------------|---------|------------|
| **1: SKILL.md** | When skill triggers | Core concepts, quick reference | ~1,500-2,000 |
| **2: references/** | When user needs details | Detailed guides, specifications | No limit |
| **3: examples/** | When user needs samples | Working code, templates | No limit |

#### Frontmatter Fields

| Field | Required | Format | Description |
|-------|----------|--------|-------------|
| `name` | Yes | `Skill Name` | Human-readable identifier |
| `description` | Yes | Third person + trigger phrases | **Critical**: Exact phrases for detection |
| `version` | Yes | `X.Y.Z` | Semantic versioning |

#### Description Format (Critical for Trigger Detection)

Skills use **third person** voice with **exact trigger phrases**:

```yaml
# WRONG - First/second person, vague
description: Use this when you need architecture help.

# CORRECT - Third person, specific triggers
description: "This skill should be used when the user asks to 'document architecture',
  'create component diagram', 'write arc42 section', 'design system structure'.
  Provides arc42 templates and architecture documentation patterns."
```

#### SKILL.md Structure

```markdown
---
name: arc42 Templates
description: "This skill should be used when the user asks to 'document architecture',
  'create arc42 section', 'design component structure', 'write architecture decision'."
version: 0.1.0
---

# arc42 Templates

## Purpose

Provides templates and guidance for documenting software architecture
using the arc42 method. Covers all 12 sections from context to glossary.

## When to Use This Skill

- Creating new architecture documentation
- Updating existing arc42 sections
- Reviewing architecture for completeness
- Preparing architecture for review

## Core Concepts

**arc42** is a template for software architecture documentation with 12 sections:
1. Introduction and Goals
2. Constraints
3. Context and Scope
4. Solution Strategy
5. Building Block View
6. Runtime View
7. Deployment View
8. Crosscutting Concepts
9. Architecture Decisions
10. Quality Requirements
11. Risks and Technical Debt
12. Glossary

## Quick Reference

### Minimal Documentation Set

For most projects, focus on:
- Section 1: Goals and stakeholders
- Section 3: Context diagram
- Section 5: Component overview
- Section 9: Key decisions (ADRs)

### Section Templates

Each section follows the pattern:
- **Purpose**: Why this section exists
- **Content**: What to include
- **Format**: How to structure it
- **Examples**: Links to references/

## Workflow

1. Start with Section 1 (goals) and Section 3 (context)
2. Add Section 5 (building blocks) as system takes shape
3. Document decisions in Section 9 as they're made
4. Fill remaining sections based on project needs

## Additional Resources

### Reference Files
- **`references/building-blocks.md`** - Detailed component documentation patterns
- **`references/runtime-view.md`** - Sequence and flow documentation
- **`references/deployment-view.md`** - Infrastructure documentation

### Example Files
- **`examples/sample-context.md`** - Context diagram example
- **`examples/sample-building-block.md`** - Component documentation example
```

#### Writing Style Requirements

| Aspect | Requirement | Example |
|--------|-------------|---------|
| **Voice** | Third person | "This skill should be used when..." |
| **Instructions** | Imperative, verb-first | "Configure X", "Validate Y" |
| **Length** | SKILL.md under 2,000 words | Move details to references/ |
| **References** | Explicit file descriptions | "See `references/X.md` for..." |

#### Skill Best Practices

| Do | Don't |
|----|-------|
| Use third person: "This skill should be used when..." | Use second person: "You should use this when..." |
| Include 3-5 exact trigger phrases | Use generic triggers like "when needed" |
| Keep SKILL.md under 2,000 words | Put all content in SKILL.md |
| Move detailed content to references/ | Duplicate content across files |
| Provide working examples in examples/ | Describe without showing |
| Use imperative form: "Configure X" | Use passive: "X should be configured" |
| Document each reference file purpose | Leave references unexplained |

---

### Anti-Patterns to Avoid

Common mistakes when writing plugin components:

#### Commands

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Using shell operators in context | `\|`, `&&`, `\|\|`, `()` blocked | Single commands only |
| Accessing parent directories in context | `../` paths blocked by sandbox | Ask user for path, validate with Read tool |
| Commands that can fail in context | `ls file`, `cat file` fail if missing | Use `ls -la` + interpret, or Read tool |
| **Git commands in context** | Fail with `fatal: not a git repository` | Check `.git` in ls output, run git in Instructions |
| Complex logic in context | Can't conditionally output | Move logic to Interpret Context section |
| Bash code blocks as pseudo-code | Claude executes them literally | Use prose instructions |
| Goal/Action in simple commands | Over-engineering, adds noise | Direct step-by-step instructions |
| Full Bash access when not needed | Security risk | Use pattern format: `Bash(git:*)` |
| Vague descriptions | Poor discoverability | Action verb + object + outcome |

#### Agents

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Vague trigger descriptions | Agent never gets launched | Include 2-4 exact trigger phrases |
| Single-paragraph system prompts | Insufficient guidance | 500-3,000 words with clear structure |
| Missing output format | Inconsistent results | Specify exact output structure |
| Hardcoded model without reason | Inefficient resource use | Use `model: inherit` as default |
| All tools granted | Security risk | Principle of least privilege |

#### Skills

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Second person in description | Breaks trigger detection | Third person: "This skill should be used when..." |
| All content in SKILL.md | Token bloat | Progressive disclosure with references/ |
| Generic trigger phrases | Skill never activates | Exact phrases users would say |
| Passive voice instructions | Unclear directives | Imperative: "Configure X", "Validate Y" |
| Undocumented references | Users don't know what's available | Describe each file's purpose |

#### Cross-Component

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Inconsistent naming | Confusion, broken references | Follow naming conventions strictly |
| Duplicated content | Maintenance burden | Single source of truth, reference it |
| Missing examples | Users can't understand usage | Provide 3-5 working examples |
| Overly complex structure | Hard to maintain | Start simple, add complexity when needed |

---

## Naming Conventions

| Type | Format | Example |
|------|--------|---------|
| Plan ID | `YYYYMMDD-HHMMSS-slug` | `20241228-143022-user-auth` |
| ADR | `YYYYMMDD-HHMMSS-slug.md` | `20241228-100000-api-versioning.md` |
| Branch | `feature/F{NN}-slug` | `feature/F01-user-auth` |
| Session | `YYYYMMDD-HHMMSS-topic` | `20241228-150000-auth-strategy` |

### Command Structure Convention

s2s uses **subfolders** for command organization instead of Anthropic's flat pattern. This provides better organization for larger projects.

**Pattern**: `commands/{category}/{operation}.md` → `/s2s:{category}:{operation}`

**Rule**: **Subcommands = operations** (what to do), **Flags = configuration** (how to do it)

```
OPERATIONS (different actions) → subcommands (separate files in subfolder)
  /s2s:roundtable:list      → commands/roundtable/list.md
  /s2s:roundtable:start     → commands/roundtable/start.md
  /s2s:roundtable:resume    → commands/roundtable/resume.md

CONFIGURATION (modifiers) → flags
  /s2s:roundtable:list --status active
  /s2s:plan:list --status completed
  /s2s:plan:create "topic" --branch
```

**Correct vs Incorrect**:

| Correct | Incorrect | Reason |
|---------|-----------|--------|
| `/s2s:roundtable:list` | `/s2s:roundtable --list` | `list` is an operation, not config |
| `/s2s:plan:list --status active` | `/s2s:plan:list:active` | `status` is a filter, not operation |
| `/s2s:roundtable:resume <id>` | `/s2s:roundtable --resume <id>` | `resume` is an operation |

**Rationale**: This deviates from Anthropic's flat pattern (`commands/*.md`) for:
- Better organization for projects with many commands
- Consistency with existing s2s structure
- Similarity to Claude Flow hierarchical pattern

---

## Implementation Phases

### Phase 1: Core Foundation ✓
- Commands: plan/create, plan/list, plan/start, plan/complete
- Templates: project, workspace, docs

### Phase 2: Workflow + Roundtable ✓
- Workflow commands: specs, design (renamed from tech)
- Roundtable v2: executor pattern, strategy skills
- Agents: roundtable/* (facilitator, architect, tech-lead, qa-lead, devops, product-manager)
- Skills: roundtable-strategies/ (standard, disney, debate, consensus-driven, six-hats)
- Commands: roundtable/start, roundtable/resume, roundtable/list

### Phase 3: Workflow Simplification ✓
- Smart init command: init.md + init/detect, init/setup, init/context
- Brainstorm command: standalone disney-strategy roundtable
- Smart plan command: auto-generates from docs or prompts for topic
- Command renames: proj:init→init, tech→design, plan:new→plan:create
- Merged discover into init:setup

### Phase 3.5: Roundtable Architecture Refactor (v3) ✓
- Orchestrator agent: agents/roundtable/orchestrator.md for loop coordination
- SlashCommand delegation: specs/design/brainstorm → roundtable:start
- Strategy auto-detection: topic keywords → recommended strategy
- Session validation: resume.md validates integrity before continuing
- Facilitator fallback: handles malformed YAML with retry + deterministic fallback
- Single source of truth: session files created only by start.md

### Phase 4: Skills + Standards (Current)
- Skills: arc42-templates, iso25010-requirements, madr-decisions
- Integration with commands and agents
- Agents: exploration/*, validation/*

### Phase 5: Multi-Repo Support
- Workspace coordination across components

### Phase 6: Documentation
- User guides, command reference, workflow examples

---

## Code Style

- **Language**: English for code, comments, and documentation
- **Markdown**: GitHub-flavored, CommonMark compatible
- **YAML**: 2-space indent, quoted strings for values with special chars
- **File encoding**: UTF-8, LF line endings

---

## Testing Commands

After changes, test with:
```bash
/plugin marketplace remove spec2ship
/plugin marketplace add https://github.com/spec2ship/spec2ship.git#develop
/plugin install s2s@spec2ship
```

---

## References

### Patterns We Follow
- [Anthropic plugin-dev](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev) - Commands + Agents + Skills structure
- [Anthropic feature-dev](https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev) - Agent parallelism pattern
- [wshobson/agents](https://github.com/wshobson/agents) - Tiered agent architecture
- [ContextKit](https://github.com/FlineDev/ContextKit) - Workflow phases pattern

### Standards We Implement
- arc42 for architecture documentation
- ISO 25010 for quality requirements
- MADR for architecture decisions
- Conventional Commits for git messages
