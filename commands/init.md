---
description: Initialize or update a Spec2Ship project. Analyzes existing structure, creates .s2s/ configuration, and gathers project context.
allowed-tools: Bash(mkdir:*), Bash(git:*), Read, Write, Edit, Task, AskUserQuestion
argument-hint: [--workspace | --component [path]] [--detect]
---

# Initialize Spec2Ship Project

Orchestrates project initialization by delegating detection to an agent and handling user interaction and file generation directly.

**Modes:**
- **(default)**: Full initialization - detect → interact → generate
- **--detect**: Detection only - analyze project, report findings (read-only)
- **--workspace**: Initialize as parent workspace
- **--component [path]**: Initialize as component of existing workspace

---

## Phase 0: Parse Arguments

Parse $ARGUMENTS:
- **--detect**: If present, run only Phase 1 and display report
- **--workspace**: Set mode to "workspace"
- **--component [path]**: Set mode to "component", extract workspace path
- **(no flags)**: Set mode to "standalone"

---

## Phase 1: Detect

**Use the project-detector agent** with this input:

```yaml
directory: {current directory}
check_changes: true
check_workspace: true
```

Store the agent's YAML output as **Detected**.

### If --detect flag

Display the Detected report and stop:

```
Project Detection Report
════════════════════════

Directory: {Detected.project.directory}
Project: {Detected.project.name}
Git: {Detected.git.initialized ? "yes" : "no"}
S2S: {Detected.s2s.initialized ? "yes (" + Detected.s2s.type + ")" : "no"}

Tech Stack:
  Languages: {Detected.tech_stack.languages}
  Frameworks: {Detected.tech_stack.frameworks}
  Package managers: {Detected.tech_stack.package_managers}

Complexity: {Detected.complexity.level}
  {Detected.complexity.reasons}

{If Detected.s2s.initialized}
S2S Status:
  Plans: {Detected.s2s.plans_count}
  Active plan: {Detected.s2s.current_plan or "none"}
  Active sessions: {Detected.s2s.active_sessions_count}
  Changes detected: {Detected.changes_detected.any_changes}
{/If}

{If Detected.workspace_context.suggested_mode is NOT null AND NOT "standalone"}
Workspace Context:
  Parent has git: {Detected.workspace_context.parent_has_git}
  Parent has .s2s: {Detected.workspace_context.parent_has_s2s}
  Sibling count: {Detected.workspace_context.sibling_count}
  Siblings with .s2s: {Detected.workspace_context.sibling_s2s_folders}
  Suggested mode: {Detected.workspace_context.suggested_mode}
{If Detected.workspace_context.warning}
  ⚠️ {Detected.workspace_context.warning}
{/If}
{/If}

{Detected.recommendations}
```

**Stop execution here.**

---

## Phase 2: Handle Existing S2S

If **Detected.s2s.initialized** is true:

### Check for incomplete initialization

If `.s2s` exists but is missing essential files (config.yaml, CONTEXT.md):

Display:
```
S2S directory found but incomplete.
Missing: {list missing files}
```

Ask using AskUserQuestion:
- "How would you like to proceed?"
- Options:
  - "Complete initialization (add missing files)"
  - "Reinitialize completely"
  - "Cancel"

**If "Complete initialization"**: Skip to Phase 5, generate only missing files
**If "Reinitialize"**: Continue to Phase 3
**If "Cancel"**: Stop execution

### If changes detected

Display changes and ask:

```
S2S already initialized. Changes detected:
{Detected.changes_detected.details}
```

Ask using AskUserQuestion:
- "How would you like to proceed?"
- Options:
  - "Update CONTEXT.md with changes"
  - "Reinitialize completely"
  - "No changes needed"

**If "Update CONTEXT.md"**: Jump to Phase 5 (Context Update)
**If "Reinitialize"**: Continue to Phase 3
**If "No changes"**: Display "Project is up to date." and stop

### If no changes detected

Display:
```
Spec2Ship is already initialized and up to date.

Project: {Detected.project.name}
Type: {Detected.s2s.type}
Plans: {Detected.s2s.plans_count}

Next steps:
  /s2s:plan:list    - View existing plans
  /s2s:specs        - Define requirements
  /s2s:design       - Design architecture
```

**Stop execution.**

---

## Phase 3: Validate Environment

### Git Check (standalone/workspace only)

If **Detected.git.initialized** is false AND mode is not "component":

Ask using AskUserQuestion:
- "Initialize git repository?"
- Options: "Yes, initialize git" / "No, continue without git"

If yes: run `git init`

### Workspace Relationship (standalone only)

If mode is "standalone":

**Check if workspace context was detected:**

If **Detected.workspace_context.suggested_mode** is NOT "standalone" AND NOT null:

Display detected workspace context:
```
Workspace structure detected:
─────────────────────────────
Parent folder git: {Detected.workspace_context.parent_has_git}
Parent folder .s2s: {Detected.workspace_context.parent_has_s2s}
Sibling folders: {Detected.workspace_context.sibling_count}
Siblings with .s2s: {Detected.workspace_context.sibling_s2s_folders}

Suggested configuration: {Detected.workspace_context.suggested_mode}
```

**If Detected.workspace_context.warning is NOT null**:
Display warning prominently:
```
⚠️ WARNING: {Detected.workspace_context.warning}
```

Ask using AskUserQuestion:
- "This appears to be part of a workspace. How would you like to configure it?"
- Options:
  - "Option A: Per-component .s2s (each component has own .s2s, versioned separately)"
  - "Option B: Single .s2s in parent (monorepo style, shared documentation)"
  - "Option C: Sibling docs folder (separate docs repo alongside components)"
  - "Option D: Hybrid (system-level docs + component-specific .s2s)"
  - "Standalone (ignore workspace structure)"

Based on selection:
- **Option A**: Set mode to "standalone" (each component independent)
- **Option B**: Set mode to "workspace", target parent folder
- **Option C**: Ask for sibling docs folder name, set mode to "workspace"
- **Option D**: Set mode to "hybrid" (generate both workspace.yaml and component.yaml)
- **Standalone**: Continue as standalone

**Else** (no workspace detected or suggested_mode is "standalone"):

Ask using AskUserQuestion:
- "Is this project part of a workspace?"
- Options: "No, standalone project" / "Yes, it's a component"

If component: ask for workspace path and switch mode to "component"

### Validate Component Workspace

If mode is "component":
- If workspace path not in $ARGUMENTS, ask for it
- Read workspace path + `/.s2s/workspace.yaml`
- If not found: error and ask for correct path

---

## Phase 4: Gather Context

Collect project information through quick questions.

### 4.1 Confirm Project Description

Ask using AskUserQuestion:
- Question: "Project: **{Detected.project.name}** - {Detected.project.description or 'No description found'}. Is this correct?"
- Options: "Yes, continue" / "Let me provide corrections"

If corrections: ask for name and description separately.

### 4.2 Tech Stack

**If tech stack WAS detected** (Detected.tech_stack.languages is not empty):

Ask using AskUserQuestion:
- Question: "Detected tech stack: **{Detected.tech_stack.languages}**{If frameworks: ', ' + Detected.tech_stack.frameworks}. Is this correct?"
- Options: "Yes, continue" / "Let me provide corrections"

If corrections: ask what tech stack to use.

**If tech stack was NOT detected** (Detected.tech_stack.languages is empty):

Ask using AskUserQuestion:
- "What tech stack will this project use?"
- Options:
  - "JavaScript/TypeScript"
  - "Python"
  - "Rust"
  - "TBD - to be defined during design phase"

Store selection as **Context.tech_stack** (or "TBD" if deferred).

### 4.3 Business Domain

Ask using AskUserQuestion:
- "What is the business domain?"
- Options:
  - "E-commerce / Retail"
  - "Developer Tools / DevOps"
  - "Data / Analytics"
  - "Web Application"

### 4.4 Objectives

Ask using AskUserQuestion (multiSelect: true):
- "What are the main objectives?"
- Options:
  - "New product/feature development"
  - "Modernization/refactoring"
  - "Performance optimization"
  - "Adding capabilities to existing product"

Follow up: "Briefly describe the specific goals:"

### 4.5 Scope

Ask using AskUserQuestion:
- "What type of project is this?"
- Options:
  - "MVP - minimal viable, speed over completeness"
  - "Full implementation - complete feature set"
  - "Proof of concept - experimental"

Ask: "What is explicitly OUT of scope?"

### 4.6 Constraints

Ask using AskUserQuestion (multiSelect: true):
- "Are there technical constraints?"
- Options:
  - "Must use specific tech stack"
  - "Must integrate with existing systems"
  - "Performance requirements"
  - "Security/compliance requirements"

If constraints selected, ask for details.

Store all answers as **Context**.

---

## Phase 5: Generate Files

> **Template-based generation**: Files are generated by reading templates from the plugin
> (`${CLAUDE_PLUGIN_ROOT}/templates/project/`) and replacing placeholders with collected values.
> This ensures consistency between templates and generated output.

### 5.1 Create Directories

**Standalone/Workspace:**
```bash
mkdir -p .s2s/plans
mkdir -p .s2s/sessions
mkdir -p .s2s/decisions
mkdir -p .claude
```

**Component:**
```bash
mkdir -p .s2s/plans
mkdir -p .s2s/decisions
mkdir -p .claude
```

### 5.2 Generate config.yaml

**Read template from plugin**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/config.yaml`

**Replace placeholders**:
- `{project-name}` → `{Detected.project.name or Context.name}`
- `"standalone"` (on the `type:` line) → `"{mode}"` (standalone | workspace | component)

**Write**: Save the modified content to `.s2s/config.yaml`

**For workspace mode**, also create `.s2s/workspace.yaml`:
```yaml
name: "{project-name}"
type: "workspace"
components: []
```

**For component mode**, use `.s2s/component.yaml` instead:
```yaml
name: "{project-name}"
workspace:
  path: "{workspace-path}"
```

### 5.3 Create sessions folder

Create `.s2s/sessions/` directory for session files.

### 5.4 Generate CONTEXT.md

**Read template from plugin**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/CONTEXT.md`

**Replace placeholders**:
- `{Project description - run /s2s:init to populate}` → `{Context.description or Detected.project.description}`
- `{Business domain - run /s2s:init to populate}` → `{Context.domain}`
- `- {Objectives - run /s2s:init to populate}` → `{Context.objectives as bullet points, each on its own line}`
- `{MVP | Full Implementation | Proof of Concept}` → `{Context.scope_type}`
- First `- {To be defined}` (In scope) → `- {inferred from objectives}`
- Second `- {To be defined}` (Out of scope) → `- {Context.out_of_scope}`
- `{Constraints - run /s2s:init to populate}` → `{Context.constraints or "No significant constraints identified."}`
- `{To be determined - run /s2s:design to define}` → `{Detected.tech_stack formatted or Context.tech_stack or "TBD - to be defined during design phase"}`
- `- {Questions to be resolved}` → `- {any unresolved items or "None identified"}`
- `{date}` → `{current ISO date}`

**Keep unchanged**: The "Project Tracking" section with Backlog and Decisions references.

**Remove**: The `*Phase: init*` line at the end.

**Write**: Save the modified content to `.s2s/CONTEXT.md`

### 5.5 Generate CLAUDE.md

Write `.claude/CLAUDE.md` with project-specific content:

```markdown
# {Detected.project.name or Context.name}

@../.s2s/CONTEXT.md

{If Detected.tech_stack.languages is not empty}
## Tech Stack

{For each language in Detected.tech_stack.languages}
- {language}
{/For}
{If Detected.tech_stack.frameworks is not empty}
- Frameworks: {Detected.tech_stack.frameworks joined by ", "}
{/If}
{/If}

## Spec2Ship Commands

- `/s2s:specs` - Define requirements via roundtable
- `/s2s:design` - Design architecture via roundtable
- `/s2s:plan --new` - Create implementation plan
- `/s2s:brainstorm` - Creative ideation session
```

**Note**: The `@../.s2s/CONTEXT.md` directive automatically includes CONTEXT.md content in Claude's memory. User can add custom directives (code style, testing requirements, etc.) after the generated content.

### 5.6 Generate BACKLOG.md

**Read template from plugin**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/BACKLOG.md`

**Replace placeholders**:
- `{project-name}` → `{Detected.project.name or Context.name}`
- `{date}` → `{current ISO date}`

**Write**: Save the modified content to `.s2s/BACKLOG.md`

---

## Phase 5 (Context Update): Update CONTEXT.md Only

If user selected "Update CONTEXT.md" in Phase 2:

1. Read current `.s2s/CONTEXT.md`
2. For each change in **Detected.changes_detected.details**:
   - Ask user: "Update {section} with detected changes?"
   - Options: "Yes" / "No" / "Let me edit"
3. Apply confirmed changes using Edit tool
4. Update "Last updated" date

Display:
```
Context updated!

Changes applied:
- {list}

Unchanged:
- {list}
```

**Stop execution.**

---

## Phase 6: Output

Display completion:

```
Spec2Ship initialized successfully!

Project: {name}
Type: {mode}
Domain: {Context.domain}
Scope: {Context.scope_type}

Created:
- .s2s/config.yaml
- .s2s/CONTEXT.md
- .s2s/BACKLOG.md
- .s2s/sessions/
- .s2s/plans/
- .s2s/decisions/
- .claude/CLAUDE.md (with @../.s2s/CONTEXT.md reference)

What's next?

{If Context.scope_type is "Full implementation"}
For in-depth project setup with stakeholder discussion:
  /s2s:roundtable --workflow setup
  (Participants: product-manager, documentation-specialist, oss-community-manager)

{/If}
For requirement definition:
  /s2s:specs

For architecture design:
  /s2s:design

For creative ideation:
  /s2s:brainstorm "your idea"

For a quick task:
  /s2s:plan --new "task name"
```
