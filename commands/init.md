---
description: Initialize or update a Spec2Ship project. Analyzes existing structure, creates .s2s/ configuration, and gathers project context.
allowed-tools: Bash(mkdir:*), Bash(git:*), Bash(ls:*), Read, Write, Edit, Task, AskUserQuestion
argument-hint: [--workspace [--components "a,b,c"]] [--detect]
---

# Initialize Spec2Ship Project

Orchestrates project initialization by delegating detection to an agent and handling user interaction and file generation directly.

**Modes:**
- **(default)**: Full initialization - detect → interact → generate
- **--detect**: Detection only - analyze project, report findings (read-only)
- **--workspace**: Initialize as parent workspace
- **--workspace --components "a,b,c"**: Initialize workspace with specified components

**Note**: Init is ALWAYS interactive. Detection guides the flow, but user confirms decisions.

---

## Phase 0: Parse Arguments

Parse $ARGUMENTS:
- **--detect**: If present, run only Phase 1 and display report
- **--workspace**: Set mode to "workspace"
- **--workspace --components "a,b,c"**: Set mode to "workspace", store component list
- **(no flags)**: Set mode to "auto-detect" (determined in Phase 3)

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

## Phase 3: Determine Mode

Determine the initialization mode based on detection results and user input.

### Scenario A: New Standalone Project

**Applies when:**
- mode is "auto-detect"
- Detected.s2s.initialized is false
- Detected.workspace_context.parent_has_s2s is false
- Detected.workspace_context.sibling_count < 3 (few subfolders)

**Action:**
- Set mode to "standalone"
- Continue to Phase 4

### Scenario B: New Workspace (explicit)

**Applies when:**
- mode is "workspace" (--workspace flag)

**Action:**
1. Check for git:
   ```
   If Detected.git.initialized is false:
     Ask: "Initialize git repository?"
     Options: "Yes, initialize git" / "No, continue without git"
     If yes: run git init
   ```

2. If --components was provided:
   - Store component list for Phase 5

3. If --components was NOT provided:
   - Ask using AskUserQuestion:
     "Do you want to create component folders now?"
     Options:
       - "Yes, let me specify components"
       - "No, I'll add components later"
   - If yes: ask for component names (comma-separated)

4. Set mode to "workspace"
5. Continue to Phase 4

### Scenario C: New Workspace (detected)

**Applies when:**
- mode is "auto-detect"
- Detected.s2s.initialized is false
- Detected.workspace_context.sibling_count >= 3 (multiple subfolders)
- OR Detected.workspace_context has complex project indicators (package.json with workspaces, nx.json)

**Action:**
1. Display detection:
   ```
   Detected potential workspace structure:
   ───────────────────────────────────────
   Subfolders found: {list subfolder names}
   Potential components: {Detected.workspace_context.potential_components}
   ```

2. Ask using AskUserQuestion:
   "Initialize as workspace?"
   Options:
     - "Yes, create workspace with detected components" (Recommended)
     - "Yes, but let me choose which subfolders are components"
     - "No, initialize as standalone project"

3. Based on selection:
   - **"Yes, detected"**: Set mode to "workspace", use detected components
   - **"Yes, let me choose"**: Ask for component selection, set mode to "workspace"
   - **"No, standalone"**: Set mode to "standalone"

4. Continue to Phase 4

### Scenario D: Adding Component to Existing Workspace

**Applies when:**
- mode is "auto-detect"
- Detected.s2s.initialized is false
- Detected.workspace_context.parent_has_s2s is true

**Action:**
1. Display detection:
   ```
   Detected workspace at: {Detected.workspace_context.parent_path}
   Workspace name: {read from parent workspace.yaml}
   ```

2. Ask using AskUserQuestion:
   "Initialize this folder as a component of that workspace?"
   Options:
     - "Yes, add as component" (Recommended)
     - "No, initialize as standalone"

3. If "Yes, add as component":
   - Set mode to "component"
   - Set workspace_path to parent path

4. Continue to Phase 4

### Scenario E: Convert Standalone to Workspace

**Applies when:**
- mode is "workspace" (--workspace flag)
- Detected.s2s.initialized is true
- Detected.s2s.type is "standalone"

**Action:**
1. Display warning:
   ```
   ⚠️ This project is already initialized as standalone.
   Converting to workspace will:
   - Add workspace.yaml
   - Change config.yaml type to "workspace"
   - Keep existing CONTEXT.md, BACKLOG.md, etc.
   ```

2. Ask: "Proceed with conversion?"
   Options: "Yes, convert to workspace" / "No, cancel"

3. If confirmed:
   - Set mode to "workspace"
   - Set converting_from_standalone to true
   - Continue to Phase 4

4. If cancelled: Stop execution

### Scenario F: Multi-repo (no git, siblings have git)

**Applies when:**
- mode is "workspace" (--workspace flag)
- Detected.git.initialized is false
- Detected.workspace_context.siblings_with_git > 0

**Action:**
1. Display situation:
   ```
   Multi-repo structure detected:
   ───────────────────────────────
   This folder has no git repository.
   Sibling projects with git: {list sibling names with .git}

   Workspace documentation should be versioned for collaboration.
   ```

2. Ask using AskUserQuestion:
   "How would you like to handle the workspace configuration?"
   Options:
     - "Create 'system-docs' sibling folder with git" (Recommended)
     - "Initialize git in current folder"
     - "Proceed without git (documentation won't be versioned)"

3. Based on selection:
   - **"system-docs"**:
     - Ask: "I can create the folder and initialize git, or you can do it manually. Proceed?"
     - If yes: create ../system-docs, git init, target that folder
   - **"Initialize here"**: run git init, continue
   - **"Proceed without"**: warn again, then continue if confirmed

4. After git decision, register sibling projects:
   ```
   For each sibling with potential component structure:
     Ask: "Add {sibling-name}/ as component? [Y/n]"
   ```

5. Continue to Phase 4

### Dependency Detection (for workspace and component modes)

**After mode is determined**, if mode is "workspace" OR "component":

1. If adding component to workspace:
   - Scan for references to sibling components (imports, @../references)
   - If dependencies found:
     ```
     Detected dependencies:
     - {component} → {dependency1}
     - {component} → {dependency2}

     Is this correct? Would you like to add or remove any?
     ```
   - Store confirmed dependencies for Phase 5

2. If creating workspace with components:
   - After components are created, scan each for inter-component dependencies
   - Ask user to confirm detected dependencies

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
- `{standalone | workspace | component}` → `{mode}` (the actual mode value)

**For component mode**, also uncomment and populate workspace section:
```yaml
workspace:
  path: "{workspace_path}"                    # e.g., ".."
  workspace_yaml: "{workspace_path}/.s2s/workspace.yaml"
```

**Write**: Save the modified content to `.s2s/config.yaml`

### 5.2b Generate workspace.yaml (workspace mode only)

**IF mode is "workspace"**:

**Read template from plugin**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/workspace/workspace.yaml`

**Replace placeholders**:
- `{workspace-name}` → `{Detected.project.name or Context.name}`
- `{monorepo | multi-repo | hybrid}` → `{detected git structure}`
  - If single .git at workspace root → "monorepo"
  - If no .git here but components have .git → "multi-repo"
  - If mixed → "hybrid"

**If components were specified (--components or user input)**:

Replace `components: []` with populated component array:
```yaml
components:
  - id: "{component-name-kebab}"
    name: "{Component Name}"
    path: "./{component-folder}"
    type: "application"                  # Default, can be changed
    has_own_git: {true if component has .git, else false}
    depends_on: []                       # Populated after dependency detection
```

**Write**: Save the modified content to `.s2s/workspace.yaml`

### 5.2c Update parent workspace.yaml (component mode only)

**IF mode is "component"**:

1. Read `{workspace_path}/.s2s/workspace.yaml`
2. Add this component to the `components:` array:
   ```yaml
   - id: "{current-folder-name}"
     name: "{Context.name or Detected.project.name}"
     path: "./{current-folder-name}"
     type: "{application | service | library}"  # Ask user or detect
     has_own_git: {Detected.git.initialized}
     depends_on: {detected dependencies or []}
   ```
3. Write the updated workspace.yaml

### 5.3 Create sessions folder

Create `.s2s/sessions/` directory for session files.

### 5.4 Generate CONTEXT.md

> **Header Convention**: CONTEXT.md files use prefixed headers to avoid ambiguity when
> workspace and component contexts are loaded together via @ cascade.
> - Workspace: "System Overview", "System Objectives", "System Constraints", "Workspace Open Questions"
> - Component: "Component Overview", "Component Constraints", "Component Open Questions"
> See ADR-0009 for rationale.

**For standalone mode**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/CONTEXT.md`

**Remove conditional sections**:
- Delete everything between `<!-- WORKSPACE_CONTEXT_START -->` and `<!-- WORKSPACE_CONTEXT_END -->` (inclusive)
- Delete everything between `<!-- COMPONENT_CONSTRAINTS_START -->` and `<!-- COMPONENT_CONSTRAINTS_END -->` (inclusive)
- **Keep** everything between `<!-- STANDALONE_CONTEXT_START -->` and `<!-- STANDALONE_CONTEXT_END -->` (remove only the HTML comments)

**Replace placeholders**:
- `{project-name}` → `{Detected.project.name or Context.name}`
- `{business-domain}` → `{Context.domain}`
- `{objective-1}` → `{Context.objectives[0]}`
- `{objective-2}` → `{Context.objectives[1] or remove line}`
- `{constraint-1}` → `{Context.constraints[0] or "None identified"}`
- `{constraint-2}` → `{Context.constraints[1] or remove line}`
- `{description}` → `{Context.description or Detected.project.description}`
- `{scope-type}` → `{Context.scope_type}`
- `{in-scope}` → `{inferred from objectives}`
- `{out-of-scope}` → `{Context.out_of_scope or "TBD"}`
- `{date}` → `{current ISO date}`

**Keep as-is** (user-visible hints for future commands):
- "TBD - run `/s2s:design`..." → Keep if tech stack not detected
- "None identified yet" → Keep for open questions

**Remove**: The `*Phase: init*` line at the end.

**For component mode**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/CONTEXT.md`

**Remove conditional sections**:
- Delete everything between `<!-- STANDALONE_CONTEXT_START -->` and `<!-- STANDALONE_CONTEXT_END -->` (inclusive)
- **Keep** everything between `<!-- WORKSPACE_CONTEXT_START -->` and `<!-- WORKSPACE_CONTEXT_END -->` (remove only the HTML comments)
- **Keep** everything between `<!-- COMPONENT_CONSTRAINTS_START -->` and `<!-- COMPONENT_CONSTRAINTS_END -->` (remove only the HTML comments)

**Populate Workspace Context section**:
- `{workspace-name}` → name from parent `workspace.yaml`
- `{component-role-description}` → description from this component's entry in parent `workspace.yaml`, or "Component of {workspace-name}"
- `{workspace-path}` → `{workspace_path}` (e.g., "..")

**Replace other placeholders**:
- `{project-name}` → `{Detected.project.name or Context.name}`
- `{description}` → `{Context.description or Detected.project.description}`
- `{scope-type}` → `{Context.scope_type}`
- `{in-scope}` → `{inferred from objectives}`
- `{out-of-scope}` → `{Context.out_of_scope or "TBD"}`
- `{component-constraints}` → `{Context.constraints or "None identified"}`
- `{date}` → `{current ISO date}`

**Keep as-is**: "TBD - run `/s2s:design`...", "None identified yet"

**Note**: The `@{workspace-path}/.s2s/CONTEXT.md` reference uses @ cascade to load workspace context into memory automatically.

**For workspace mode**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/workspace/CONTEXT.md`

**Replace placeholders**:
- `{workspace-name}` → `{Context.name or Detected.project.name}`
- `{description}` → `{Context.description}`
- `{business-domain}` → `{Context.domain}`
- `{objective-1}` → `{Context.objectives[0]}`
- `{objective-2}` → `{Context.objectives[1] or remove line}`
- `{constraint-1}` → `{Context.constraints[0] or "None identified"}`
- `{constraint-2}` → `{Context.constraints[1] or remove line}`
- `{component-name}` / `{component-role}` → one row per registered component
- `{date}` → `{current ISO date}`

**Keep as-is**: Cross-cutting "TBD", Architecture "TBD - run `/s2s:design`...", "None identified yet"

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

### 5.7 Generate README.md

> **Purpose**: README.md contains S2S documentation for humans (paths, commands, how-to).
> This content is NOT loaded into Claude's memory - only CONTEXT.md is loaded via @ cascade.
> See ADR-0009 for rationale on separating semantic context from documentation.

**For workspace mode**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/workspace/README.md`

**Replace placeholders**:
- `{workspace-name}` → `{Context.name or Detected.project.name}`

**Write**: Save the modified content to `.s2s/README.md`

**For standalone mode**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/README.md`

**Remove conditional sections**:
- Delete everything between `<!-- WORKSPACE_SECTION_START -->` and `<!-- WORKSPACE_SECTION_END -->` (inclusive)

**Replace placeholders**:
- `{project-name}` → `{Detected.project.name or Context.name}`

**Write**: Save the modified content to `.s2s/README.md`

**For component mode**:

Read the file at `${CLAUDE_PLUGIN_ROOT}/templates/project/README.md`

**Populate Workspace section** (keep the section, replace placeholders):
- `{workspace-name}` → name from parent `workspace.yaml`
- `{workspace-path}` → `{workspace_path}` (e.g., "..")
- Remove the HTML comments but keep the content

**Replace other placeholders**:
- `{project-name}` → `{Detected.project.name or Context.name}`

**Write**: Save the modified content to `.s2s/README.md`

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
- .s2s/CONTEXT.md (semantic context, loaded in Claude's memory)
- .s2s/README.md (documentation for humans, NOT loaded in memory)
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
