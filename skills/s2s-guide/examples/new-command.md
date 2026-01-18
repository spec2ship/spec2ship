# Example: Creating a New Command

Step-by-step guide to create a new slash command.

## Overview

Commands are the primary interface for users. Each command has:
- Frontmatter with metadata and permissions
- Context section (environment data)
- Instructions section (what to do)

## File Location

```
commands/{command-name}.md           # Top-level command
commands/{category}/{operation}.md   # Subcommand
```

**Naming**: `/s2s:{command}` or `/s2s:{category}:{operation}`

---

## Step 1: Create the File

### Frontmatter (REQUIRED)

```yaml
---
description: "Brief description of what this command does"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), Task
argument-hint: "[topic]"  # Optional, shown in autocomplete
---
```

### Allowed Tools Patterns

```yaml
# Basic tools
allowed-tools: Read, Write, Edit, Glob, Grep

# Restricted Bash (security-conscious)
allowed-tools: Bash(git:*), Bash(ls:*), Bash(mkdir:*)

# SlashCommand (without arguments)
allowed-tools: SlashCommand:/s2s:session:list

# SlashCommand (with arguments - note :*)
allowed-tools: SlashCommand:/s2s:roundtable:*

# Task for spawning agents
allowed-tools: Task
```

---

## Step 2: Write Context Section

Context gathers environment information using `!` prefix commands.

### Allowed in Context

```markdown
## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`
```

### NOT Allowed in Context

- Shell operators: `|`, `&&`, `||`, `()`
- Redirects: `>`, `2>`
- Commands that can fail: `cat file.txt`
- Git commands (fail if not a repo)

### Git-Safe Pattern

```markdown
## Context

- Directory contents: !`ls -la`

## Interpret Context

- **Is git repo**: If `.git` appears in directory contents → "yes"
```

---

## Step 3: Write Instructions Section

Use prose instructions, NOT code blocks.

### Wrong (Code Block)

```markdown
## Process files

```bash
for file in *.md; do
  grep "pattern" "$file"
done
```
```

Claude may try to execute this literally.

### Correct (Prose)

```markdown
## Process files

For each markdown file in the directory:
1. Read the file using Read tool
2. Search for the pattern
3. Collect matching lines
```

---

## Step 4: Use Imperative Patterns

### Tool Invocation

```markdown
**YOU MUST use Write tool NOW** to create the file.

**YOU MUST use Task tool** to launch the agent.
```

### Conditional Logic

```markdown
**IF** config.yaml exists:
  Read configuration
**ELSE**:
  Use default values

**IF** project type == "workspace":
  Load workspace.yaml
```

### Validation Steps

```markdown
#### Step 2.1b: Validate Output

**Non-blocking validation** - display warnings but continue.

1. **Verify file exists**:
   - Check `.s2s/config.yaml` created

2. **If validation fails**:
   ```
   Warning: VALIDATION WARNING
   Missing: config.yaml not created
   Continuing execution...
   ```
```

---

## Step 5: Agent Invocation (if needed)

### Correct Pattern

```markdown
**Use the roundtable-facilitator agent** with this input:

```yaml
action: "question"
round: 1
topic: "{topic}"
```
```

### Wrong Pattern

```markdown
# WRONG - Creates generic agent without config
Task(subagent_type="general-purpose", prompt="You are a facilitator...")
```

---

## Complete Example: Simple Report Command

```markdown
---
description: "Generate a project status report"
allowed-tools: Read, Glob, Grep, Write
---

# Generate Status Report

## Context

- Current directory: !`pwd`
- Timestamp: !`date +"%Y-%m-%d"`

## Instructions

### Step 1: Gather Information

1. **Read project context**:

   Read `.s2s/CONTEXT.md` to understand the project.

2. **Find sessions**:

   Use Glob to find all files matching `.s2s/sessions/*.yaml`.

3. **Read backlog**:

   Read `.s2s/BACKLOG.md` if it exists.

### Step 2: Generate Report

**YOU MUST use Write tool NOW** to create `.s2s/status-report.md`:

```markdown
# Status Report - {project-name}

**Generated**: {timestamp}

## Project Overview

{Summary from CONTEXT.md}

## Recent Sessions

{List of recent sessions with status}

## Backlog Summary

{Count of items by status}
```

### Step 3: Display Summary

Display to user:

```
Status report generated: .s2s/status-report.md

Sessions: {count}
Backlog items: {count}
```
```

---

## Subcommand Example

For `/s2s:report:weekly`, create:

```
commands/report/weekly.md
```

The command path becomes the subcommand structure.

---

## Best Practices

### DO

- Use prose instructions, not code blocks
- Use `**YOU MUST**` for critical steps
- Add validation after important operations
- Use pattern-based Bash permissions (`Bash(git:*)`)
- Follow imperative voice

### DON'T

- Use shell operators in Context section
- Put bash scripts in code blocks as pseudo-code
- Grant full Bash access
- Skip validation for file operations
- Use generic Task prompts for agents

---

## Checklist

- [ ] Created `commands/{name}.md`
- [ ] Added frontmatter with description and allowed-tools
- [ ] Context section uses only safe `!` commands
- [ ] Instructions use prose, not code blocks
- [ ] Critical steps use `**YOU MUST**` emphasis
- [ ] Validation steps added after file operations
- [ ] Agent invocation uses `**Use the X agent**` pattern
- [ ] Tested command end-to-end
