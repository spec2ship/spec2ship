---
description: Generate implementation plans. Smart behavior - reads from specs/architecture docs if available, otherwise prompts for topic. Auto-detects active plans.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(git:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: [--component <name>] [--all] [--with-branches] [--new] [--session <id>]
---

# Generate Implementation Plans

Smart command that generates implementation plans based on available documentation.

**Behavior:**
- If specs + architecture exist → analyzes docs and generates plans for work items
- If only CONTEXT.md exists → asks for topic and creates single plan
- Supports generating all plans at once or selecting specific items

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date +"%Y%m%d-%H%M%S"`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"
- **Is git repo**: If `.git` directory appears in Directory contents → "yes", otherwise → "no"

If S2S is initialized, use Read tool to:
- Read `.s2s/CONTEXT.md` for project context and phase
- **Search for requirements** (use first found, prefer docs/ if both exist):
  - First check `docs/specifications/requirements.md` (exported/public)
  - Then check `.s2s/requirements.md` (internal/working)
- **Search for architecture** (use first found, prefer docs/ if both exist):
  - First check `docs/architecture/` (exported/public)
  - Then check `.s2s/architecture.md` (internal/working)
- List existing plans in `.s2s/plans/`

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S", display this message and stop:

    Error: Not an s2s project. Run /s2s:init first.

### Determine Planning Mode

Based on available documentation:

**Full Documentation Mode** (specs + architecture exist):
- requirements.md has content
- architecture docs have content
- → Analyze docs and identify work items

**Basic Mode** (only CONTEXT.md):
- No requirements or architecture docs
- → Ask user for topic, create single plan
- Suggest: "For better planning, consider running /s2s:specs and /s2s:design first"

### Display Status

    Implementation Planning
    ═══════════════════════

    Project: {name}
    Phase: {phase from CONTEXT.md}

    Available inputs:
    ✓ Project context (.s2s/CONTEXT.md)
    {✓ or ✗} Requirements ({source path found, or "not found"})
    {✓ or ✗} Architecture ({source path found, or "not found"})

    Mode: {Full Documentation | Basic}

Note: Requirements/Architecture are searched in `docs/` first (exported), then `.s2s/` (internal).

### Parse arguments

Extract from $ARGUMENTS:
- **--component**: Generate plan for specific component only
- **--all**: Generate plans for all identified components/features
- **--with-branches**: Create git branches for each plan
- **--new**: Force create new plan (skip auto-detect)
- **--session**: Resume specific plan by ID

**Also check for positional argument** (topic or ID):
- Extract any non-flag argument as `plan_target`
- Examples: `plan "user authentication"`, `plan FEAT-001`, `plan IDEA-003`

---

## Smart Source Detection (no flags needed)

**IF `plan_target` is provided**:

### ID Pattern Detection

Check if `plan_target` matches a known ID pattern:

| Pattern | Source | Action |
|---------|--------|--------|
| `FEAT-*`, `BUG-*`, `TECH-*`, `DEBT-*` | `.s2s/BACKLOG.md` | Read item, use as plan input |
| `REQ-*`, `NFR-*` | `.s2s/requirements.md` or `docs/specifications/requirements.md` | Read requirement, use as plan input |
| `COMP-*`, `INT-*` | architecture docs | Read component/interface, use as plan input |
| `ARCH-*` | `.s2s/decisions/` | Read ADR, use as plan input |
| `IDEA-*` | `.s2s/ideas.md` | **WARNING** + confirmation required |

**IF IDEA-* pattern detected**:

```
⚠️  WARNING: Planning from unvalidated idea
═══════════════════════════════════════════

You're trying to create a plan from IDEA-{NNN}: "{title}"

Ideas should typically go through requirements validation first:
  1. /s2s:specs - Define and validate requirements
  2. /s2s:plan  - Then create implementation plan

Planning directly from ideas may result in:
- Missing edge cases not caught by requirements analysis
- Incomplete acceptance criteria
- Scope creep during implementation
```

Ask using AskUserQuestion:
- "How would you like to proceed?"
  - Options:
    - "Run /s2s:specs first (recommended)" - stop and suggest specs command
    - "Proceed anyway" - create plan from idea (explicit confirmation)
    - "Cancel" - abort

**IF user selects "Proceed anyway"**:
- Display: "Proceeding with plan from IDEA-{NNN}. Note: Consider running /s2s:specs after implementation for validation."
- Continue with idea as plan input

**IF user selects "Run /s2s:specs first"**:
- Display: "Run: /s2s:specs IDEA-{NNN}"
- Stop execution

### Text Search (if not an ID pattern)

If `plan_target` does not match an ID pattern, search for it:

1. **Search BACKLOG.md** first:
   - Look for items with matching title or description
   - Prioritize `status: planned` items

2. **Search requirements.md**:
   - Look for REQ-* with matching title or description

3. **Search architecture docs**:
   - Look for components or interfaces with matching name

4. **Search ideas.md** last:
   - Look for ideas with matching title or problem
   - **IF found in ideas.md only**: Apply same IDEA-* warning as above

**IF match found**:
- Display: "Found: {ID} - {title} in {source}"
- Use as plan input

**IF no match found**:
- Display: "No existing item found for '{plan_target}'"
- Ask: "Would you like to create a new plan for this topic?"

### No Target Provided (show planned items)

**IF no `plan_target` and no --all and no --component**:

Read `.s2s/BACKLOG.md` and list items with `status: planned`:

```
Planned Items Ready for Implementation
══════════════════════════════════════

From BACKLOG.md:
1. FEAT-001: {title}
   Status: planned | Priority: {priority}
   {brief description}

2. FEAT-002: {title}
   Status: planned | Priority: {priority}
   {brief description}

{IF no planned items}
No planned items found in BACKLOG.md.
Run /s2s:specs to define requirements, or specify a topic directly.
{/IF}
```

Ask using AskUserQuestion:
- "Which item would you like to plan?"
  - Options: list each planned item, plus "Enter custom topic"

---

## Auto-detect Active Plans

**IF** --session flag is present:
- Verify plan exists: `.s2s/plans/{plan-id}.md`
- If exists, read plan and display status, then ask what to do
- If not exists, display error and list available plans

**IF** --new flag is present:
- Skip auto-detect
- Continue to Planning Mode

**OTHERWISE** check for active plans:

Use Glob to find plan files: `.s2s/plans/*.md`

For each plan file, read and check for `**Status**: active`:

**IF** active plans found:

1. Display list:

```
Active implementation plans found:
══════════════════════════════════

1. {plan-id}
   Topic: {title from plan}
   Status: active
   Tasks: {completed}/{total}

2. {plan-id}
   ...

[n] Create new plan

What would you like to do?
```

2. Ask using AskUserQuestion with options:
   - For each plan: "Continue {plan-id}"
   - "Create new plan"

3. Based on user choice:
   - If existing plan selected → Display plan tasks and suggest `/s2s:plan --session "{plan-id}"`
   - If "Create new plan" → Continue to Planning Mode

---

## Full Documentation Mode

### Phase 1: Analyze and Identify Work Items

Analyze all available documentation to identify implementation work items:

```
Task(
  subagent_type="general-purpose",
  prompt="Analyze the project documentation and identify implementation work items.

Project Context:
{CONTEXT.md content}

Requirements:
{requirements.md content if available}

Architecture:
{architecture docs content if available}

Your task:
1. Identify distinct implementation units:
   - Features from requirements (user-facing functionality)
   - Components from architecture (system building blocks)
   - Infrastructure items (deployment, CI/CD, monitoring)

2. For each work item, determine:
   - ID: feature-{slug} or component-{slug} or infra-{slug}
   - Name: human-readable title
   - Type: feature | component | infrastructure
   - Description: what needs to be built
   - Dependencies: other work items that must be done first
   - Estimated complexity: small | medium | large
   - Requirements covered: list of REQ-xxx IDs
   - Architecture references: list of ARCH-xxx or component names

3. Order work items by:
   - Dependencies (items with no deps first)
   - Complexity (smaller items first when no dep constraints)
   - Priority (from requirements MoSCoW)

Return a structured list of work items ready for plan generation."
)
```

### Phase 2: Present Work Items

Display identified work items:

    Identified Work Items:
    ══════════════════════

    Features:
    ─────────
    1. feature-{slug}: {name}
       Complexity: {small|medium|large}
       Dependencies: {list or "none"}
       Requirements: {REQ-xxx list}

    2. feature-{slug}: {name}
       ...

    Components:
    ───────────
    1. component-{slug}: {name}
       Complexity: {small|medium|large}
       Dependencies: {list or "none"}

    Infrastructure:
    ───────────────
    1. infra-{slug}: {name}
       ...

    Suggested order: {ordered list of IDs}

### Phase 3: User Selection

If --all is NOT present and --component is NOT specified:

Ask user using AskUserQuestion:
- "Which items would you like to create plans for?"
  - Options: "All items" / "Select specific items" / "Just the first item"

If "Select specific items":
- Present numbered list
- Ask for selection

### Phase 4: Generate Plans

For each selected work item, generate a detailed implementation plan.

Jump to **Plan Generation** section below.

---

## Basic Mode

### Gather Topic

If no requirements/architecture docs:

Ask user using AskUserQuestion:
- "What would you like to plan?"
- Free text input

Display suggestion:

    Tip: For comprehensive planning with work item breakdown, run:
    1. /s2s:specs    - Define requirements
    2. /s2s:design   - Design architecture
    3. /s2s:plan     - Generate all plans

### Generate Single Plan

Use the topic to generate a plan.

Jump to **Plan Generation** section below.

---

## Plan Generation

For each work item or topic, generate a detailed implementation plan:

```
Task(
  subagent_type="general-purpose",
  prompt="Generate a detailed implementation plan for:

Work Item: {id or topic}
Name: {name}
Type: {type}
Description: {description}

Context:
{relevant sections from CONTEXT.md}

Requirements covered (if available):
{relevant requirements from requirements.md}

Architecture references (if available):
{relevant sections from architecture docs}

Dependencies:
{list of prerequisite work items}

Your task:
1. Break down the implementation into concrete tasks
2. Each task should be:
   - Specific and actionable
   - Completable in a reasonable session
   - Testable/verifiable

3. Include tasks for:
   - Setup/scaffolding (if first component)
   - Core implementation
   - Tests (unit, integration as appropriate)
   - Documentation updates
   - Integration with other components

4. Order tasks by implementation sequence

Return the plan in this format:
- Task list with checkboxes
- Acceptance criteria
- Testing approach
- Integration notes"
)
```

**Write plan file** `.s2s/plans/{timestamp}-{slug}.md`:

**Read template from plugin**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`

**Replace placeholders**:
- `{topic}` → `{Name}`
- `{plan-id}` → `{timestamp}-{slug}`
- `{branch-name}` → `{branch-name if --with-branches, else "N/A"}`
- `{created-timestamp}` → `{ISO timestamp}`
- `{updated-timestamp}` → `{ISO timestamp}`
- `{source-id}` → `{FEAT-001, REQ-001, IDEA-001, etc. - the source item this plan was created from}`
- `{source-type}` → `{backlog | requirement | idea | architecture | topic}`
- `{requirements-list}` → `{list of REQ-xxx covered, or "N/A"}`
- `{architecture-list}` → `{list of ARCH-xxx or component references, or "N/A"}`
- `{decisions-list}` → `{relevant ADRs, or "N/A"}`
- `{dependencies-list}` → `{list of other plan IDs that must complete first, or "none"}`
- `{overview-description}` → `{description of what this plan implements}`
- `{task-1}`, `{task-2}`, `{task-3}` → `{generated task list from agent response}`
- `{criterion-1}`, `{criterion-2}` → `{generated acceptance criteria}`
- `{testing-description}` → `{how to verify this implementation}`
- `{integration-description}` → `{how this connects to other components}`

**Add traceability note** if source is IDEA-*:
```markdown
> ⚠️ **Note**: This plan was created directly from an idea (IDEA-{NNN}) without formal requirements validation.
> Consider running `/s2s:specs` after implementation to validate against user needs.
```

**Write**: Save the modified content to `.s2s/plans/{timestamp}-{slug}.md`

### Create Git Branches (if --with-branches)

If --with-branches is present and "Is git repo" is "yes":

For each plan created:
1. Determine branch number from existing feature branches
2. Create branch: `git checkout -b feature/F{NN}-{slug}`
3. Checkout back to original branch
4. Update plan file with branch name

### Update CONTEXT.md

Update `.s2s/CONTEXT.md`:
- Update phase to "plan"
- Update "Last updated" date

### Output Summary

    Implementation plans created!

    Plans generated: {count}
    ─────────────────────────

    {for each plan}
    • {plan-id}
      Topic: {name}
      Tasks: {count}
      Branch: {branch or "N/A"}

    Suggested execution order:
    1. {first plan id} - {name}
    2. {second plan id} - {name}
    ...

    Next steps:

    Start working on a plan:
      /s2s:plan --session "{first-plan-id}"

    View all plans:
      /s2s:plan:list

    Close a plan:
      /s2s:plan:close
