# Spec2Ship Development Guide

This document contains detailed patterns, examples, and lessons learned for developing and extending Spec2Ship. Reference this when implementing new commands, agents, or skills.

---

## Agent Invocation Pattern (CRITICAL)

### Correct Pattern: Invoke by Name

When a command needs to call a roundtable agent, use the agent's name in the prompt:

```markdown
**Use the roundtable-facilitator agent** with this input:
```yaml
action: "question"
round: 1
topic: "Requirements for user authentication"
...
```
```

This triggers Claude Code to load and execute the agent defined in `agents/roundtable/facilitator.md`.

### Wrong Pattern: Task with Generic Prompt

```markdown
# WRONG - Creates a generic agent, NOT the facilitator agent
Task(
  subagent_type="general-purpose",
  prompt="You are a facilitator. Generate a question..."
)
```

This creates a new generic agent that doesn't have the facilitator's specialized prompt, tools, or configuration.

### Why This Matters

- Agent files define: model tier, tools, skills, specialized system prompt
- Using "general-purpose" with inline prompt loses all of this
- The agent never "sees" its own definition file

---

## YAML I/O Pattern for Agents

All roundtable agents use structured YAML for input/output to ensure consistent, parseable responses.

### Input Format

```yaml
# Facilitator Question Input
action: "question"
round: {N}
topic: "{session topic}"
strategy: "{strategy}"
phase: "{current phase}"
workflow_type: "{specs|design|brainstorm}"

escalation_config:
  min_rounds: 3
  max_rounds: 20
  max_rounds_per_conflict: 3
  confidence_below: 0.5

full_agenda:
  - id: "{topic_id}"
    status: "{open|partial|closed}"
    priority: "{critical|normal}"
  # ... all topics

open_conflicts: []
artifacts_count: {N}
previous_synthesis: "{text or null}"
```

### Output Format

```yaml
# Facilitator Question Output
action: "question"
decision:
  focus_type: "{agenda|conflict|open_question}"
  topic_id: "{topic}"
  rationale: "{reason}"
question: "{the question}"
exploration: "{exploration prompt}"
participants: "all"
context_files: ["context-snapshot.yaml", ...]
```

---

## Command Writing Patterns

### Context Section Rules

Context commands (prefixed with `!`) gather environment information:

**Allowed:**
```markdown
- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`
```

**NOT Allowed:**
- Shell operators: `|`, `&&`, `||`, `()`
- Redirects: `>`, `2>`
- Commands that can fail: `cat file.txt`, `ls specific-file`
- Git commands (fail if not a repo)

**Pattern: Git-Safe Context**

```markdown
## Context

- Directory contents: !`ls -la`

## Interpret Context

- **Is git repo**: If `.git` appears in Directory contents → "yes"

## Instructions

### Gather git information (if git repo)

If "Is git repo" is "yes", use Bash tool to run git commands.
```

### Prose Instructions vs Code Blocks

**Wrong** - Bash code blocks interpreted literally:
```markdown
## Process files

```bash
for file in *.md; do
  grep "pattern" "$file"
done
```⁣
```

**Correct** - Prose instructions:
```markdown
## Process files

For each markdown file in the directory:
1. Read the file using Read tool
2. Search for the pattern
3. Collect matching lines
```

---

## Multi-Agent Orchestration

### Key Constraint: Subagents Cannot Spawn Subagents

Claude Code subagents cannot use the Task tool to spawn further subagents.

```
# WRONG - Does not work!
orchestrator.md (agent) → Task(facilitator) → Task(participant)

# CORRECT - Orchestration inline in command
roundtable.md (command) → Task(facilitator) → Task(participant)
```

**Solution**: All orchestration logic must be in commands, not agents.

### Parallel Execution for Blind Voting

Launch all participant agents in a single message to prevent sycophancy:

```markdown
**Launch ALL participant agents in SINGLE message** (parallel execution):

For each of: product-manager, business-analyst, qa-lead

**Use the roundtable-{participant-id} agent** with this input:
```yaml
round: {N}
question: "{facilitator's question}"
...
```
```

### Emphasis for Critical Instructions

Claude Code respects instructions better when emphasized:

```markdown
**YOU MUST** use the Task tool NOW to call the facilitator.

IMPORTANT: Do NOT proceed to Step 3 until you have received the response.
```

Source: [GitHub Issue #1078](https://github.com/anthropics/claude-code/issues/1078)

---

## SlashCommand Behavior

**SlashCommand is ASYNCHRONOUS** - the calling command continues without waiting for results.

```markdown
# WRONG - specs.md continues without waiting
Phase 1: Use SlashCommand to start roundtable
  SlashCommand:/s2s:roundtable "topic"

# CORRECT - Execute inline following skill
Phase 1: Execute roundtable following skill instructions
  Task(facilitator) → question
  Task(participants) → responses (parallel)
  Task(facilitator) → synthesis
```

---

## allowed-tools Patterns

### Pattern Format (Recommended)

```yaml
allowed-tools: Bash(ls:*), Bash(git:*), Bash(mkdir:*), Read, Write, Edit
```

- `Bash(ls:*)`: Only allows `ls` commands
- `Bash(git:*)`: Only allows `git` commands
- Follows principle of least privilege

### SlashCommand Patterns

```yaml
# Without arguments
allowed-tools: SlashCommand:/s2s:session:list

# With arguments (note the :* suffix)
allowed-tools: SlashCommand:/s2s:roundtable:*
```

**IMPORTANT**: If target command accepts arguments, you MUST use `:*` suffix!

---

## Adding New Skills

### Checklist

1. Create directory: `skills/{skill-name}/`
2. Create `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: Display Name
   description: "This skill should be used when the user asks to
     'trigger phrase 1', 'trigger phrase 2'. Purpose."
   version: 0.1.0
   ---
   ```
3. Keep SKILL.md under 2,000 words
4. Use third-person description
5. Include 3-5 exact trigger phrases
6. Create `references/` for detailed patterns
7. Create `examples/` for working samples

### Progressive Disclosure

| Tier | Location | When Loaded |
|------|----------|-------------|
| 1 | SKILL.md | Always (on trigger) |
| 2 | references/*.md | On demand |
| 3 | examples/*.md | On demand |

---

## Adding New Strategies

### Checklist

1. Create: `skills/roundtable-strategies/references/{strategy}.md`
2. Define:
   - `defaults.participation`: parallel or sequential
   - `defaults.phases`: array of phase definitions
   - `defaults.consensus`: policy and threshold
   - `validation`: rules and constraints
3. Add auto-detection keywords to SKILL.md
4. Test: `/s2s:roundtable "topic" --strategy {strategy}`

### Strategy Configuration Structure

```yaml
defaults:
  participation: "parallel" | "sequential"
  phases:
    - name: "{phase-name}"
      prompt_suffix: |
        {Instructions for this phase}
      participants: "all" | ["specific", "list"]
  consensus:
    policy: "weighted_majority" | "unanimous" | "facilitator_judgment"
    threshold: 0.6

validation:
  requires_sequential_phases: true | false
  min_participants: 2
```

---

## Pattern Reinforcement

In complex multi-agent systems, LLMs can "forget" instructions from earlier context.

### Where to Apply

| Component | Reinforcement | Why |
|-----------|---------------|-----|
| Facilitator prompt | Strategy phases from skill | Ensures correct phase behavior |
| Facilitator prompt | Escalation config | Ensures triggers are checked |
| Participant prompts | Contribution format | Ensures consistent output |

### How to Apply

1. **Define once** in skill/agent definition
2. **Inject into prompt** when launching sub-agent
3. **Keep critical info near end** of prompt (recency bias)

---

## Anti-Patterns Reference

### Commands

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Shell operators in context | `\|`, `&&` blocked | Single commands only |
| Git commands in context | Fail if not git repo | Check `.git` first, run in Instructions |
| Bash code blocks as pseudo-code | Claude executes literally | Use prose instructions |
| Full Bash access | Security risk | Use pattern format: `Bash(git:*)` |

### Agents

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Task with generic prompt | Loses agent configuration | Invoke by agent name |
| Vague trigger descriptions | Agent never launched | Include exact trigger phrases |
| Subagent spawning subagent | Doesn't work in Claude Code | Orchestration in commands |

### Skills

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Second person in description | Breaks trigger detection | Third person: "This skill should be used when..." |
| All content in SKILL.md | Token bloat | Progressive disclosure |
| Generic trigger phrases | Skill never activates | Exact phrases users would say |

### File Writing (CRITICAL)

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Writing to `docs/` directly | Bypasses export control | Write to `.s2s/`, export via command |
| Creating ADRs in `docs/decisions/` | Public docs without review | Write to `.s2s/decisions/`, export later |

**File Output Boundaries:**

| Scope | Path | Written By |
|-------|------|------------|
| **Internal (working)** | `.s2s/decisions/`, `.s2s/sessions/`, `.s2s/plans/` | All commands |
| **External (public)** | `docs/decisions/`, `docs/specifications/`, `docs/architecture/` | `/s2s:export` only (TBD) |

Commands write to `.s2s/` ONLY. Public documentation in `docs/` is created ONLY via explicit export command (to be implemented).

See also: `skills/madr-decisions/SKILL.md` for ADR-specific rules.

---

## Session File Management

### Per-Round Persistence

Session file MUST be written after EACH round, not batched at the end:

```markdown
#### Step 2.6: Update Session File

**YOU MUST use Edit tool NOW** to update session file with:
1. Append round to `rounds:` array
2. Update agenda status
3. Update metrics
```

### Immutability Rules

- NEVER modify existing rounds in `rounds[]` array
- Only APPEND new round at end of array
- If conflict resolved, add to new round's `resolved[]`
- Previous round data is READ-ONLY

---

## Config Priority

Values should flow: **config.yaml → arguments → snapshot → subagent prompt**

```
1. Arguments (--strategy debate) - highest priority
2. Config file (.s2s/config.yaml)
3. Command defaults - lowest priority
```

### Current Issue (P1-1)

Config values are hardcoded in commands instead of read from config.yaml:
- `min_rounds: 3` repeated 12+ times
- `max_rounds: 20` hardcoded
- `confidence_below: 0.5` hardcoded

These should be read from config and passed via config-snapshot.yaml.

---

## Lessons Learned

### 1. Skills as Documentation vs Execution

Skills are reference documentation, not executable contracts. Claude reads the skill and creates a "mental model" but may optimize or skip steps.

**Solution**: Critical steps must be explicit in commands with imperative language.

### 2. Claude Optimizes/Batches Operations

Claude may decide to batch operations for efficiency:
- "Write after each round" → "Write all at end"
- Conditional steps may be skipped

**Solution**: Use `**YOU MUST**` emphasis and explicit tool calls.

### 3. Agent Invocation Discovery

Initially used `Task(subagent_type="general-purpose", prompt="...")` which created generic agents without the specialized configuration.

**Solution**: Use `**Use the roundtable-X agent**` pattern to trigger proper agent loading.

---

## Deferred Features

Features intentionally not implemented due to current limitations. Track here with reintroduction conditions.

### Validation: LLM-Based Semantic Checks

**ADR**: `.s2s/decisions/0008-validation-simplification.md`
**Deferred in**: v0.x (2026-01-16)

| Feature | Why Deferred | Reintroduce When |
|---------|--------------|------------------|
| State Transitions Valid | Session file has current state only, no history | Track `state_history[]` per artifact |
| Participant Coherence Check | Requires cross-round memory; LLM forgets earlier positions | Vector store or persistent memory for session history |
| Context Integrity Check | Massive cross-reference, high error rate | Track `context_hash` per round for deterministic comparison |
| Quality Assessment Check | Too subjective, high false positive rate | Define quantitative criteria (word count, structure patterns) |
| Blocking Concerns Resolution | Semantic parsing unreliable | Structured output format for concerns in participant responses |

### Validation: Strategy-Specific Phase Tracking

**ADR**: `.s2s/decisions/0008-validation-simplification.md`
**Deferred in**: v0.x (2026-01-16)

| Feature | Why Deferred | Reintroduce When |
|---------|--------------|------------------|
| Consensus Phase Validation | Field `consent_phase` not in session schema | Add `consent_phase` to session file and command writes |
| Disney Phase Validation | Field `disney_phase` not in session schema | Add `disney_phase` to session file and command writes |
| Phase Tone Analysis | Too subjective for reliable validation | Likely not reintroducible; tone is inherently qualitative |

### Wisdom Gained

1. **Script-first for structural checks**: yq/bash are deterministic, LLM is not
2. **Only validate what you track**: If a field doesn't exist in the session file, you can't validate it
3. **LLM judgment is expensive**: Reserve for genuinely qualitative assessments, not counting or cross-referencing
4. **Deferred ≠ deleted**: Track conditions so future work can reintroduce features systematically

---

## Template-Based File Generation

### Pattern: Templates as Source of Truth

Commands that generate files (e.g., `init.md`) should read from templates instead of inlining content.

**Why**:
- Single source of truth for file structure/content
- Commands focus on logic, templates focus on content
- Easier maintenance (change template once, all commands use it)
- Guaranteed consistency between templates and generated output

**How**:

```markdown
### Generate config.yaml

**Read template from plugin**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/config.yaml`

**Replace placeholders**:
- `{project-name}` → `{Detected.project.name}`
- `"standalone"` → `"{mode}"`

**Write**: Save the modified content to `.s2s/config.yaml`
```

**Key Points**:
1. `${CLAUDE_PLUGIN_ROOT}` is expanded to the plugin installation path at runtime
2. Works for all template types: YAML, Markdown, etc.
3. Commands specify which placeholders to replace and with what values
4. Templates use consistent placeholder format: `{placeholder-name}`

### Template Placeholder Conventions

**Placeholder formats** (in order of preference):

| Format | Use Case | Example |
|--------|----------|---------|
| `{placeholder-name}` | Simple values | `{project-name}`, `{date}` |
| `{opt1 \| opt2 \| opt3}` | Finite choices | `{standalone \| workspace \| component}` |
| `{description - hint}` | Self-documenting | `{Project description - run /s2s:init to populate}` |

**Why this pattern**:
1. All placeholders start with `{` and end with `}` - easy regex: `\{[^}]+\}`
2. LLM can identify ALL placeholders by pattern matching
3. `|` separator indicates valid options (LLM knows allowed values)
4. Hint text helps LLM understand intent without reading command

**Anti-patterns to avoid**:
- Fixed values like `"standalone"` - LLM may not know to replace
- Pseudo-code like `{Context.X}` - confuses (looks like code, not placeholder)
- Nested braces `{{...}}` - harder to parse

**Verified in**: TEMPL-001 test (2026-01-17)

---

## External References

### Patterns We Follow
- [Anthropic plugin-dev](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev)
- [Anthropic feature-dev](https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev)
- [PubNub Best Practices](https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/)

### Standards We Implement
- arc42 for architecture documentation
- ISO 25010 for quality requirements
- MADR for architecture decisions
- Conventional Commits for git messages
