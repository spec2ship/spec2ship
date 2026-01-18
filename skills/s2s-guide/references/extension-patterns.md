# Extension Patterns

Patterns for writing commands, agents, and skills in Spec2Ship.

## Agent Invocation (CRITICAL)

The most important pattern when writing commands.

### Correct Pattern

```markdown
**Use the roundtable-{role} agent** with this input:

```yaml
{input}
```
```

This triggers Claude Code to load the agent file with its configuration, model, tools, and skills.

### Wrong Pattern

```markdown
# WRONG - Creates generic agent without config
Task(subagent_type="general-purpose", prompt="You are a facilitator...")
```

This creates a new generic agent that doesn't have the facilitator's specialized prompt.

---

## Positive/Negative Instructions

Use explicit emphasis for critical requirements.

```markdown
**YOU MUST** use Write tool NOW to create the file.

**NEVER** skip the validation step.
```

### When to Use

- Critical steps that must not be skipped
- Common mistakes that need prevention
- Tool invocation requirements

---

## Validation Steps

Add validation after critical operations.

```markdown
#### Step X.Xb: Validate {Operation}

**Non-blocking validation** - display warnings but continue execution.

1. **Verify {item}**:
   - Check {condition}
   - Expected: {value}

2. **If validation fails**:
   ```
   Warning: {CATEGORY} WARNING
   Missing: - {details}
   Continuing execution...
   ```
```

---

## Sequential Steps

Use numbered steps with clear tool instructions.

```markdown
### Step N.N: {Step Title}

**YOU MUST use {Tool} tool NOW** to {action}.

{Details or template}

**Result**: {expected outcome}
```

---

## Parallel Execution

Mark parallel operations explicitly.

```markdown
**Launch ALL participant agents in SINGLE message** (parallel execution):

For each of: product-manager, business-analyst, qa-lead

**Use the roundtable-{participant-id} agent** with this input:
```

---

## Conditional Logic

Structure conditions clearly.

```markdown
**IF** {condition}:
  {action}

**IF** {condition} **AND** {condition}:
  {action}

**IF** {condition}:
  {action}
**ELSE**:
  {action}
```

---

## YAML I/O for Agents

All roundtable agents use structured YAML for input/output.

### Input Example

```yaml
action: "question"
round: 1
topic: "Requirements for user authentication"
strategy: "consensus-driven"
phase: "proposal"
workflow_type: "specs"
```

### Output Example

```yaml
action: "question"
decision:
  focus_type: "agenda"
  topic_id: "user-auth"
  rationale: "Starting with core feature"
question: "What are the primary user authentication requirements?"
participants: "all"
```

---

## Context Section Rules

Context commands (prefixed with `!`) gather environment information.

**Allowed**:
```markdown
- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`
```

**NOT Allowed**:
- Shell operators: `|`, `&&`, `||`
- Redirects: `>`, `2>`
- Commands that can fail: `cat file.txt`
- Git commands (fail if not a repo)

### Git-Safe Pattern

```markdown
## Context

- Directory contents: !`ls -la`

## Interpret Context

- **Is git repo**: If `.git` appears in directory contents → "yes"

## Instructions

### Gather git info (if git repo)

If "Is git repo" is "yes", use Bash tool to run git commands.
```

---

## Template Placeholders

| Format | Use Case | Example |
|--------|----------|---------|
| `{placeholder-name}` | Simple values | `{project-name}`, `{date}` |
| `{opt1 \| opt2}` | Finite choices | `{standalone \| workspace}` |
| Human-readable default | User-visible hints | `TBD - run /s2s:design` |

**Rule**: All placeholders use `{...}` format for easy regex matching.

---

## allowed-tools Patterns

```yaml
# Pattern format (recommended)
allowed-tools: Bash(ls:*), Bash(git:*), Read, Write, Edit

# SlashCommand without arguments
allowed-tools: SlashCommand:/s2s:session:list

# SlashCommand with arguments (note :* suffix)
allowed-tools: SlashCommand:/s2s:roundtable:*
```

---

## Anti-Patterns to Avoid

### In Commands

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Shell operators in context | Blocked | Single commands only |
| Git commands in context | Fail if not repo | Check `.git` first |
| Bash code blocks as pseudo-code | Claude executes literally | Use prose instructions |
| Full Bash access | Security risk | Use `Bash(git:*)` pattern |

### In Agents

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Task with generic prompt | Loses agent config | Invoke by agent name |
| Vague trigger descriptions | Agent never launched | Exact trigger phrases |
| Subagent spawning subagent | Doesn't work | Orchestration in commands |

### In Skills

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Second person in description | Breaks trigger | Third person |
| All content in SKILL.md | Token bloat | Progressive disclosure |
| Generic trigger phrases | Skill never activates | Exact phrases |
