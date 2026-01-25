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

### Plugin File Locations (CRITICAL)

The above rules apply to **user project** files. For **plugin internal** files, different rules apply:

| Location | Purpose | Accessed by | Example |
|----------|---------|-------------|---------|
| `docs/` | Human documentation (GitHub readers) | Humans only | Architecture docs, README |
| `skills/*/references/` | LLM reference material | LLM during skill execution | Detailed guides, patterns |
| `templates/` | Files to copy to user project | LLM via `${CLAUDE_PLUGIN_ROOT}` | CONTEXT.md, config.yaml |
| `commands/` | Slash command instructions | LLM when command invoked | specs.md, plan.md |
| `agents/` | Agent system prompts | LLM when agent spawned | facilitator.md |

**Key Rule**: Documentation that the LLM needs to READ during skill/command execution goes in `skills/*/references/` or inline, **NOT** in `docs/`.

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Skill references `docs/workflow.md` | User can't access plugin files; LLM path unclear | Put in `skills/*/references/workflow.md` |
| Telling user "see docs/X.md" | User can't browse plugin internals | LLM reads reference, synthesizes answer |
| Creating new docs/ files for LLM | Wrong location; docs/ is for humans | Use skill references or inline content |

**When to use each:**
- **docs/**: Only for humans reading GitHub (architecture decisions, contributing guide)
- **skills/references/**: LLM needs to read it to answer user questions or execute skill
- **templates/**: Content that gets COPIED to user's project

### Path References in Commands/Agents (CRITICAL)

When a command or agent needs to READ a file from the plugin (skill, reference, template), it MUST use `${CLAUDE_PLUGIN_ROOT}`:

| Context | Wrong | Correct |
|---------|-------|---------|
| Command reads skill reference | `Read skills/roundtable-execution/references/diagnostic.md` | `Read the file at ${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/diagnostic.md` |
| Command reads template | `Read templates/project/config.yaml` | `Read the file at ${CLAUDE_PLUGIN_ROOT}/templates/project/config.yaml` |
| Agent reads check definitions | `Read skills/dev-testing/references/check-registry.md` | `Read the file at ${CLAUDE_PLUGIN_ROOT}/skills/dev-testing/references/check-registry.md` |

**Why this matters**:
1. Commands/agents execute in the **user's project directory**, not the plugin directory
2. Relative paths like `skills/...` resolve to the user's project, where those files don't exist
3. `${CLAUDE_PLUGIN_ROOT}` is expanded at runtime to the plugin's installation path
4. Without it, Claude will search and fail to find the file, then improvise behavior

**Exception**: Skill internal references (within SKILL.md referring to its own `references/` folder) can use relative paths because skills are loaded as a unit with their references.

### Skill Reference Triggers (IMPORTANT)

Reference files listed in a skill's reference table are **NOT automatically loaded**. Claude knows they exist but doesn't read them until triggered.

**Wrong** - just listing in reference table:
```markdown
## Reference Files
| File | Content |
| `references/verbose-dump-format.md` | Dump file format |
```

**Correct** - explicit trigger in SKILL.md body:
```markdown
**IF --verbose**: Write dump file (see `references/verbose-dump-format.md` for format)
```

**Key insight**: Reference files need explicit "when to read" triggers where the functionality is described, not just a table at the end.

**Verified**: 2026-01-21 - Fixed roundtable.md, specs.md, design.md diagnostic/agenda references

### Skill Structure: Core Inline + Reference Extensions (CRITICAL)

Skills should separate **always-executed** instructions from **optional** functionality using the Anchor + Reference pattern.

**Why this matters for LLMs**:

| Problem | Impact | Mitigation |
|---------|--------|------------|
| Context dilution | More files = instructions "dilute" | Keep core inline |
| Instruction forgetting | LLM may skip distributed instructions | Critical steps near execution point |
| Reference overhead | Each Read adds latency + context | Only load when needed |
| Anchor mismatch | Reference may not align with skill | Explicit anchor IDs |

**Pattern: Core inline, extensions via reference**

```markdown
# SKILL.md

## Step 2.1: Round Start {#anchor-round-start}

**Core actions** (ALWAYS executed):
1. Read session file
2. Prepare context
3. **IMMEDIATELY** update `.s2s/state.json` with active_session  ← Core, inline

**Extensions** (loaded on demand):
- **IF `--tokens`**: Read `references/token-tracking.md#round-init` → Execute
- **IF `--verbose`**: Read `references/verbose-dump-format.md` → Write dump
```

**Decision criteria: inline vs reference**

| Criterion | Inline | Reference |
|-----------|--------|-----------|
| Always needed | ✅ | |
| Optional (flag-dependent) | | ✅ |
| Simple (< 10 lines) | ✅ | |
| Complex (> 10 lines) | | ✅ |
| Must not be forgotten | ✅ | |
| Detailed format spec | | ✅ |

**Anchor conventions**:

```markdown
# In SKILL.md
## Step 2.1: Round Start {#round-start}

# In references/token-tracking.md
## Round Init {#round-start}
<!-- Anchor matches SKILL.md for alignment -->
```

**Anti-patterns**:

| Anti-Pattern | Problem | Correct |
|--------------|---------|---------|
| Core functionality in reference | May not be loaded | Inline critical steps |
| Everything inline | Token bloat | Extract optional to references |
| Reference chain (A → B → C) | Gets lost | Flat structure (Skill → Reference) |
| No anchor alignment | Confusion | Match anchor IDs |
| Optional without explicit trigger | Never loaded | "IF flag: Read reference" |

**Example: state.json management (TECH-007)**

State management is **always needed** (for resume suggestion, statusline), so it goes **inline**:

```markdown
## Step 2.1: Round Start

**IMMEDIATELY** update `.s2s/state.json`:
```json
{
  "active_session": {
    "id": "{session-id}",
    "workflow_type": "{workflow_type}",
    "round": {round_number}
  }
}
```⁣

**IF `--tokens`**: Read `references/token-tracking.md#round-init` → Execute
```

Token tracking is **optional**, so it stays in a **reference**.

---

### Optional Feature Hooks Pattern

Optional features (like `--diagnostic`, `--tokens`, `--verbose`) should be activated via **hooks in the skill**, not in commands.

**Why hooks in SKILL.md (not in commands):**
- Single source of truth for execution flow
- Reusable across all commands that include the skill
- Hooks are placed at exact execution points (after synthesis, before completion, etc.)

**Pattern:**
```markdown
**IF {flag}**: Read `${CLAUDE_PLUGIN_ROOT}/skills/.../references/{feature}.md` → Execute "{section}" section
```

**Command responsibility:**
- Parse the flag (e.g., `--diagnostic`)
- Pass it to skill via parameters (e.g., `diagnostic: {diagnostic_flag}`)
- Do NOT duplicate activation logic

**Example** (roundtable-execution SKILL.md):
```markdown
### Step 2.4: Facilitator Synthesis
...
**IF tokens_flag**: Read `${CLAUDE_PLUGIN_ROOT}/.../token-tracking.md` → Execute "Capture T3" section
**IF diagnostic_flag**: Read `${CLAUDE_PLUGIN_ROOT}/.../diagnostic.md` → Execute "Per-Round Diagnostic" section
```

**Verified**: 2026-01-22 - Aligned --tokens and --diagnostic in roundtable-execution SKILL.md

---

### Feature Activation Pattern for LLM Compliance (CRITICAL)

The "Optional Feature Hooks Pattern" above describes WHERE to place hooks. This section describes HOW to structure them so LLMs reliably execute them.

**Problem**: Distributed conditional instructions (`IF flag: Read → Execute` at 6+ points) have low compliance rate because:
1. Main flow dominates LLM attention
2. Each file read is a cognitive break
3. No commitment mechanism
4. No accountability if skipped

**Solution**: Feature Activation + Section References

**Pattern**:

```markdown
## PHASE 2: Execution

### Feature Activation (execute ONCE at phase start)

**IF tokens_flag**:
1. Read `references/token-tracking.md` NOW
2. Execute "Script Location" section
3. **CHECKPOINT CONTRACT**: Execute these sections at each step:
   - "Capture T1" → after Step 2.2
   - "Capture T2" → after Step 2.3
   - "Capture T3" + "Round Recap" → after Step 2.4

### Step 2.2: Facilitator Question
[... main instructions ...]

→ **IF tokens_flag**: Execute "Capture T1" section from token-tracking.md

### Step 2.3: Participants
[... main instructions ...]

→ **IF tokens_flag**: Execute "Capture T2" section from token-tracking.md
```

**Key elements**:

| Element | Purpose |
|---------|---------|
| Feature Activation block | Creates explicit commitment at phase start |
| Single file read | Loads reference once, not at each checkpoint |
| Checkpoint Contract | Lists all execution points upfront |
| Section reference at step | Lightweight reminder (no file read) |

**Why this works for LLMs**:
- Commitment upfront increases follow-through
- Single load reduces friction
- Inline reminders provide proximity
- Contract creates accountability (can be verified post-hoc)

**Trade-off accepted**: Section names appear in two places (Feature Activation + step). This mild DRY violation is intentional for LLM reliability.

**Verification**: Use post-hoc evidence-based validation (EXEC-* checks in session-qa) rather than inline checkpoints. Inline validation adds instructions that may themselves be skipped.

**Verified**: 2026-01-25 - Pattern documented based on LLM compliance analysis

---

### Validation Strategy: Post-Hoc Evidence-Based

**Principle**: Don't verify DURING execution (adds skippable instructions), verify AFTER by checking artifacts.

**Why NOT inline validation**:
- Validation instructions compete with execution instructions for LLM attention
- The problem (LLM skipping instructions) applies to validation instructions too
- Pollutes the clean instruction flow
- Increases cognitive load

**Correct approach**:

| Feature | Evidence to Check |
|---------|-------------------|
| `--tokens` | `.s2s/sessions/{id}.cache` has entries per round |
| `--verbose` | `rounds/*.yaml` dump files exist |
| `--diagnostic` | session-observer findings in session file |

**Tool assignment**:
- **session-qa**: Execution compliance checks (EXEC-*) - comprehensive, evidence files
- **session-observer**: Real-time anomaly hints - lightweight, per-round

**Workflow**:
```
Normal use:     /s2s:specs --tokens
Development:    /s2s:specs --tokens --diagnostic
Verification:   /s2s:session:validate {session-id}
```

**See also**: BACKLOG.md → QUAL-002 for EXEC-* check implementation status.

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

### Authoritative Format References

When modifying session/dump formats, consult these authoritative sources:

| Format | Authoritative Source | Notes |
|--------|---------------------|-------|
| Session file schema | `skills/roundtable-execution/references/session-schema.md` | Full session.yaml structure |
| rounds[] array | `skills/roundtable-execution/SKILL.md` Step 2.6 | Per-round fields |
| Verbose dump files | `skills/roundtable-execution/references/verbose-dump-format.md` | Structured YAML format |
| Artifact schemas (specs) | `skills/roundtable-execution/references/session-schema.md` | REQ-*, BR-*, NFR-*, etc. |
| Artifact schemas (design/brainstorm) | Inline in `commands/design.md`, `commands/brainstorm.md` | ARCH-*, IDEA-*, etc. (see TECH-003) |
| Output documents | `skills/output-generation/references/*.md` | requirements.md, architecture.md, etc. |

**Key principle**: Commands are authoritative for EXECUTION, skills/references are authoritative for FORMAT DEFINITIONS.

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
| `{placeholder-name}` | Simple values replaced by init | `{project-name}`, `{date}`, `{description}` |
| `{opt1 \| opt2 \| opt3}` | Finite choices | `{standalone \| workspace \| component}` |
| Human-readable default | User-visible hints | `TBD - run /s2s:design to define` |

**Why this pattern**:
1. All placeholders start with `{` and end with `}` - easy regex: `\{[^}]+\}`
2. LLM can identify ALL placeholders by pattern matching
3. `|` separator indicates valid options (LLM knows allowed values)
4. User-visible text (not in `{}`) serves as hint for future commands

**Key insight**: Users never see template placeholders - init replaces them. So:
- `{business-domain}` is fine (init replaces it)
- `TBD - run /s2s:design` is fine (user sees it after init, knows what to do)

**Anti-patterns to avoid**:
- `{description - run /s2s:init to populate}` - hint text inside placeholder is never seen
- Pseudo-code like `{Context.X}` - confuses (looks like code, not placeholder)
- Nested braces `{{...}}` - harder to parse

**Verified in**: TEMPL-001 test (2026-01-17), updated 2026-01-17 for simplified placeholders

---

## Output Generation Skill Pattern

### Templates vs Pseudo-Code (ADR-0012)

Two different patterns for generating files:

| Aspect | Templates (`templates/`) | Output Generation (`skills/output-generation/`) |
|--------|-------------------------|------------------------------------------------|
| **Content** | Static structure | Dynamic pseudo-code |
| **Placeholders** | Simple: `{name}` | Loops: `{for each artifact...}` |
| **Process** | Read → Replace → Write | Read → Interpret → Generate |
| **Used by** | `/s2s:init` | `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` |

### Output Generation Structure

```
skills/output-generation/
  ├── SKILL.md                   # Common logic (dispatch, merge, CONTEXT.md)
  └── references/
      ├── specs-srs.md           # SRS format pseudo-code
      ├── design-arc42.md        # Architecture + ADR pseudo-code
      └── brainstorm.md          # Summary + ideas pseudo-code
```

### How Commands Use It

```markdown
Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md`
and follow the instructions for workflow_type="specs"
```

The SKILL.md handles:
1. Format selection (based on workflow_type)
2. Merge vs override mode
3. CONTEXT.md update (specs/design only)
4. Dispatches to correct reference for format-specific pseudo-code

### Adding New Formats

1. Create `references/{workflow}-{format}.md` with pseudo-code template
2. Update SKILL.md format table
3. No changes to commands needed

**Example**: To add `specs-user-stories.md`:
- Add reference file with user story format
- Add to SKILL.md format table
- Commands can use `--format user-stories` (future)

### Why This Pattern

1. **DRY**: Common logic in SKILL.md, not duplicated across commands
2. **Progressive disclosure**: SKILL.md (~200 words) + reference (~150 words) loaded on-demand
3. **Extensibility**: New formats without touching commands
4. **Consistency**: Same pattern as `roundtable-strategies`

---

## Development Tools (/s2s:dev:*)

Development-only tools for verifying s2s plugin quality. These are in `commands/dev/` and `agents/dev/` and are **NOT shipped** with the plugin.

### Available Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/s2s:dev:check` | Verify instructions follow patterns | After modifying commands/agents |
| `/s2s:dev:test` | Run integration tests | After significant refactoring |

### Check Categories

**INST-* (Instruction Quality)**:
- Imperative voice in commands
- Explicit tool usage ("YOU MUST use X tool NOW")
- No ambiguity in steps
- Template/inline alignment
- Config from config.yaml, no hardcoded values
- ADR compliance (state field usage per ADR-0010)

**CONS-* (Consistency)**:
- Session ID format consistency across commands
- Snapshot file structure consistency
- Resume logic equivalence
- Verbose dump format consistency
- Error handling patterns
- Diagnostic mode consistency

**RES-* (Resume Capability)**:
- agent_id persistence
- last_round tracking
- context reconstruction for facilitator
- participant context propagation

**EDGE-* (Edge Cases)**:
- Empty session resume
- Mid-round interruption
- Partial participant failure
- Max rounds reached
- YAML special characters

### When to Run

| Scenario | Command |
|----------|---------|
| Modified a command file | `/s2s:dev:check --instructions` |
| Modified multiple commands | `/s2s:dev:check --consistency` |
| Changed resume logic | `/s2s:dev:test --resume` |
| Major refactoring | `/s2s:dev:test --all` |
| Pre-release validation | `/s2s:dev:check && /s2s:dev:test` |

### Structure

```
skills/dev-testing/
├── SKILL.md                    # Entry point, skill metadata
└── references/
    ├── check-registry.md       # Master list of all checks
    ├── inst-checks.md          # INST-* definitions
    ├── cons-checks.md          # CONS-* definitions
    ├── res-checks.md           # RES-* definitions
    └── edge-scenarios.md       # EDGE-* scenarios

agents/dev/
└── dev-validator.md            # Unified agent (reads from skill)

commands/dev/
├── check.md                    # /s2s:dev:check - INST-*, CONS-*
└── test.md                     # /s2s:dev:test - RES-*, EDGE-*
```

### Architecture

Check/test definitions are in **skill references** (easy to extend), while the **agent** handles execution logic. Commands orchestrate and display results.

```
/s2s:dev:check
    └── dev-validator agent
            └── reads skills/dev-testing/references/inst-checks.md
            └── reads skills/dev-testing/references/cons-checks.md
            └── executes checks, returns results

/s2s:dev:test
    └── dev-validator agent
            └── reads skills/dev-testing/references/res-checks.md
            └── reads skills/dev-testing/references/edge-scenarios.md
            └── executes tests, returns results
```

### Adding New Checks

**Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/dev-testing/references/extension-guide.md`** for complete instructions.

The guide includes:
- Category selection criteria
- Template for each check type (INST, CONS, RES, EDGE)
- Step-by-step process with examples
- Evidence schema patterns

Quick process:
1. Add entry to `check-registry.md`
2. Add full definition using template from `extension-guide.md`
3. Update count in `SKILL.md`
4. Test with `/s2s:dev:check --all` or `/s2s:dev:test --all`

### Release Exclusion

These folders are excluded from the shipped plugin via `.github/release.yml`:
- `commands/dev/`
- `agents/dev/`

**Future**: When v1.0 is released, these will move to a separate `spec2ship-devkit` repository (see DEBT-002).

### Specification

Full details: `.s2s/plans/20260118-session-resilience-verification.md`

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
