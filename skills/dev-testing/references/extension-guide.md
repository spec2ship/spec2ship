# Extension Guide

How to add new checks and tests to the dev-testing suite.

---

## When to Add a Check

Add a new check when you identify:
- A pattern that should be enforced across commands/agents
- A consistency rule between files
- A resume/recovery scenario to verify
- An edge case that caused issues

## Overview: Adding a Check

1. **Decide category**: INST, CONS, RES, or EDGE
2. **Choose ID**: Next number in sequence (e.g., INST-007)
3. **Add to registry**: Entry in `check-registry.md`
4. **Add definition**: Full definition in category file
5. **Update SKILL.md**: Increment count
6. **Test**: Run `/s2s:dev:check --all` or `/s2s:dev:test --all`

---

## Category Selection

| Category | Use When | Target |
|----------|----------|--------|
| **INST-*** | Verifying instruction quality in individual files | Single file analysis |
| **CONS-*** | Comparing patterns across multiple commands | Cross-file comparison |
| **RES-*** | Testing session resume capability | Session state analysis |
| **EDGE-*** | Verifying edge case handling | Scenario simulation |

---

## Step 1: Add Registry Entry

Open `check-registry.md` and add entry to appropriate section.

### Template: INST/CONS Check

```markdown
| INST-007 | {Check Name} | {medium|high|critical} | {target files} | inst-checks.md |
```

### Template: RES Test

```markdown
| RES-008 | {Test Name} | {medium|high|critical} | {Interruption Point} | res-checks.md |
```

### Template: EDGE Scenario

```markdown
| EDGE-008 | {Scenario Name} | {medium|high|critical} | {Scenario description} | edge-scenarios.md |
```

---

## Step 2: Add Full Definition

### Template: INST-* Check

Add to `inst-checks.md`:

```markdown
---

## INST-{NNN}: {Check Name}

| Property | Value |
|----------|-------|
| **Severity** | {medium | high | critical} |
| **Target** | {commands/*.md | agents/**/*.md | both} |
| **Reference** | {.claude/s2s-development.md section or ADR} |

### Purpose

{One paragraph explaining why this check matters.}

### Good Patterns

```markdown
{Example of correct pattern}
```

### Bad Patterns

```markdown
{Example of incorrect pattern - what to flag}
```

### Verification

1. {Step 1 - what to search/read}
2. {Step 2 - what to compare}
3. {Step 3 - what to flag}

### Evidence Schema

```yaml
check: INST-{NNN}
status: pass | fail | warn
files_checked: {N}
issues:
  - file: "{path}"
    line: {N}
    text: "{matched text}"
    issue: "{description}"
    suggestion: "{how to fix}"
```
```

---

### Template: CONS-* Check

Add to `cons-checks.md`:

```markdown
---

## CONS-{NNN}: {Check Name}

| Property | Value |
|----------|-------|
| **Severity** | {medium | high | critical} |
| **Comparison** | {All 4 commands | Specific subset} |

### Purpose

{One paragraph explaining why consistency matters here.}

### Expected Pattern

{Description of what all commands should have in common.}

### Verification

1. {Step 1 - what to extract from each command}
2. {Step 2 - how to compare}
3. {Step 3 - what differences to flag}

### Evidence Schema

```yaml
check: CONS-{NNN}
status: pass | fail
comparison:
  specs.md: "{pattern/value}"
  design.md: "{pattern/value}"
  brainstorm.md: "{pattern/value}"
  roundtable.md: "{pattern/value}"
differences:
  - command: "{file}"
    issue: "{description}"
```
```

---

### Template: RES-* Test

Add to `res-checks.md`:

```markdown
---

## RES-{NNN}: {Test Name}

| Property | Value |
|----------|-------|
| **Severity** | {medium | high | critical} |
| **Interruption Point** | {When in round this tests} |

### Purpose

{One paragraph explaining what resume capability this verifies.}

### Expected State

{Description or YAML of what session file should contain.}

```yaml
{Example expected state}
```

### Test Steps

1. {Setup - create or use test session}
2. {Action - what to check}
3. {Verify - what to compare}

### Failure Indicates

{What went wrong if this test fails - helps debugging.}

### Evidence Schema

```yaml
check: RES-{NNN}
status: pass | fail
session_file: "{path}"
evidence:
  {relevant fields checked}
notes: "{explanation}"
```
```

---

### Template: EDGE-* Scenario

Add to `edge-scenarios.md`:

```markdown
---

## EDGE-{NNN}: {Scenario Name}

| Property | Value |
|----------|-------|
| **Severity** | {medium | high | critical} |
| **Scenario** | {Brief description} |

### Setup

{How to create the edge condition.}

1. {Step 1}
2. {Step 2}

### Expected Behavior

{What should happen - the correct handling.}

### Failure Modes

| Failure | Impact |
|---------|--------|
| {What could go wrong} | {Why it matters} |

### Test Steps

1. {Create condition}
2. {Execute or simulate}
3. {Verify handling}

### Evidence Schema

```yaml
check: EDGE-{NNN}
status: pass | fail
scenario:
  {setup details}
behavior:
  {observed behavior}
  {expected vs actual}
```
```

---

## Step 3: Update SKILL.md

Update the count in the Check Categories table:

```markdown
| Category | Purpose | Count | Severity Range |
|----------|---------|-------|----------------|
| INST-* | Instruction quality | 7 | medium-high |  ← was 6
```

And update total:

```markdown
Total: **27 checks**  ← was 26
```

---

## Step 4: Test

Run the appropriate command to verify:

```bash
# For INST or CONS checks
/s2s:dev:check --all

# For RES or EDGE tests
/s2s:dev:test --all
```

Verify:
- [ ] New check appears in output
- [ ] Status is as expected (pass/fail based on current state)
- [ ] Evidence is collected correctly

---

## Examples

### Example: Adding INST-007 (Frontmatter Completeness)

**1. Registry entry** in `check-registry.md`:

```markdown
| INST-007 | Frontmatter Completeness | medium | commands | inst-checks.md |
```

**2. Definition** in `inst-checks.md`:

```markdown
## INST-007: Frontmatter Completeness

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Target** | commands/*.md, commands/**/*.md |
| **Reference** | .claude/CLAUDE.md → "Component Guidelines" |

### Purpose

Commands should have complete frontmatter with description, allowed-tools, and argument-hint.

### Good Patterns

```yaml
---
description: Does something useful
allowed-tools: Bash(pwd:*), Read, Write
argument-hint: "[--flag] <required>"
---
```

### Bad Patterns

```yaml
---
description: Does something
---
# Missing allowed-tools and argument-hint
```

### Verification

1. Read each command file
2. Parse frontmatter
3. Check for required fields: description, allowed-tools
4. Warn if argument-hint missing (optional but recommended)

### Evidence Schema

```yaml
check: INST-007
status: pass | fail | warn
files_checked: 15
issues:
  - file: "commands/dev/check.md"
    issue: "Missing argument-hint"
    suggestion: "Add argument-hint field"
```
```

**3. Update SKILL.md**: Change count from 6 to 7

**4. Test**: `/s2s:dev:check --instructions`

---

## Tips

1. **Severity**: Use `critical` sparingly (blocks release)
2. **Evidence**: Always include enough to locate and fix the issue
3. **Verification steps**: Be specific enough for Claude to execute
4. **Good/Bad patterns**: Real examples from codebase when possible
5. **Test immediately**: Verify the check works before committing

---

## Future: Command Automation

If extension becomes frequent, consider adding `/s2s:dev:add-check` command that:
1. Asks for category, name, severity
2. Generates template in correct file
3. Updates registry and SKILL.md

For now, this guide + templates is sufficient for occasional additions.
