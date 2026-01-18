# WORK-001: Workspace Management Specification

**Status**: draft
**Created**: 2026-01-17
**Updated**: 2026-01-17 (v2 - clarifications on references, dependencies, interactivity)

---

## 1. Terminology

| Term | Definition | Example |
|------|------------|---------|
| **Workspace** | Configuration that coordinates multiple related projects | Parent folder with workspace.yaml |
| **Component** | A project that is part of a workspace | frontend/, backend/, mobile/ |
| **Standalone** | A single project not part of any workspace | Simple app with one .s2s/ |
| **Monorepo** | Workspace where all components share ONE git repo | Google-style single repo |
| **Multi-repo** | Workspace where components have SEPARATE git repos | Microservices with own repos |

**Decision**: S2S uses "workspace" as the primary term. It's agnostic to git structure (works for both monorepo and multi-repo).

---

## 2. Workspace Structures Supported

### 2.1 Monorepo Structure

```
workspace/
├── .git/                    # Single git repo
├── .s2s/                    # Workspace-level S2S
│   ├── workspace.yaml       # Component registry
│   ├── config.yaml
│   ├── CONTEXT.md           # System-level context
│   ├── BACKLOG.md           # Cross-component backlog
│   ├── requirements.md      # System requirements
│   ├── architecture.md      # System architecture
│   ├── decisions/           # Cross-component ADRs
│   ├── plans/
│   └── sessions/
├── frontend/
│   └── .s2s/                # Component-level S2S
│       ├── config.yaml
│       ├── CONTEXT.md       # Component context
│       ├── BACKLOG.md       # Component backlog
│       └── ...
├── backend/
│   └── .s2s/
└── shared-lib/
    └── .s2s/
```

### 2.2 Multi-Repo Structure

```
parent-folder/               # NO .git here (or separate docs repo)
├── system-docs/             # Dedicated docs project
│   ├── .git/                # Own git repo for docs
│   └── .s2s/                # Workspace-level S2S
│       ├── workspace.yaml
│       └── ...
├── frontend/
│   ├── .git/                # Own git repo
│   └── .s2s/
├── backend/
│   ├── .git/
│   └── .s2s/
└── shared-lib/
    ├── .git/
    └── .s2s/
```

### 2.3 Hybrid Structure

```
parent-folder/
├── .git/                    # Parent has git (optional)
├── .s2s/                    # Workspace-level (if parent has git)
├── frontend/
│   ├── .git/                # Some components have own repos
│   └── .s2s/
├── backend/                 # Some don't (part of parent repo)
│   └── .s2s/
└── shared-lib/
    └── .s2s/
```

---

## 3. File Specifications

### 3.1 workspace.yaml

Location: `.s2s/workspace.yaml` (only in workspace-level .s2s/)

```yaml
# Workspace Configuration
# Coordinates multiple related projects

name: "my-workspace"
version: "0.1.0"

# === GIT STRUCTURE ===
# Detected automatically by init, informs reference patterns
structure: "monorepo"  # monorepo | multi-repo | hybrid

# === COMPONENT REGISTRY ===
components:
  - id: "frontend"
    name: "Web Application"
    path: "./frontend"              # Relative to workspace root
    type: "application"             # application | service | library
    owner: "@team-frontend"         # Team owner (optional)
    has_own_git: false              # Detected by init

  - id: "backend"
    name: "API Server"
    path: "./backend"
    type: "service"
    owner: "@team-backend"
    has_own_git: false
    depends_on:                     # Maintained by init (auto-detected)
      - "shared-lib"

  - id: "shared-lib"
    name: "Shared Library"
    path: "./shared-lib"
    type: "library"
    owner: "@team-platform"
    has_own_git: true               # Has its own .git

# === CROSS-CUTTING CONCERNS ===
# Decisions that affect multiple components
cross_cutting:
  - id: "authentication"
    decision: "ADR-001"             # Reference to decision
    affects: ["frontend", "backend", "mobile"]
    propagated_to:                  # Auto-maintained: which components have backlog items
      - component: "frontend"
        backlog_item: "TECH-003"
      - component: "backend"
        backlog_item: "TECH-001"

# === ROUNDTABLE SCOPE ===
# Guides facilitator on appropriate discussion levels
# Uses PRINCIPLES (for LLM reasoning) instead of topic lists (brittle matching)
roundtable_scope:
  workspace_level:
    # Core decision principle for facilitator
    decision_principle: |
      Workspace discussions focus on decisions that AFFECT MULTIPLE components.
      Key question: "Does this decision require coordination between teams?"
      If yes → workspace level. If no → component level.

    # Keywords that indicate workspace-level scope
    indicators:
      - "cross-component"
      - "shared"
      - "interface"
      - "contract"
      - "system-wide"
      - "platform"
      - "authentication"
      - "authorization"
      - "API versioning"
      - "security policy"

    # Keywords that indicate should defer to component
    defer_indicators:
      - "internal"
      - "implementation detail"
      - "refactoring"
      - "UI specific"
      - "only affects"
      - "database schema"

    context_note: |
      Facilitator must aggregate context from ALL component CONTEXT.md files.
      Decisions made here may generate backlog items in components.

  component_level:
    inherits_context_from: "workspace"  # Include workspace CONTEXT.md as background

    decision_principle: |
      Component discussions focus on decisions INTERNAL to this component.
      Key question: "Does this affect only this component's implementation?"
      If yes → component level. If no → escalate to workspace.

    escalate_indicators:
      - "affects other components"
      - "changes interface"
      - "new shared requirement"
      - "cross-component dependency"
```

### 3.2 Component config.yaml additions

When a project is part of a workspace, its `config.yaml` includes:

```yaml
name: "frontend"
type: "component"                    # NOT "standalone"
version: "0.1.0"

# === WORKSPACE REFERENCE ===
workspace:
  path: ".."                         # Relative path to workspace root
  workspace_yaml: "../.s2s/workspace.yaml"

# Rest of config unchanged...
```

### 3.3 Reference Patterns

**Key distinction**:
- **Internal** (`.s2s/` files): ALWAYS relative paths - local filesystem structure is predictable
- **External** (`docs/` public files): ALWAYS absolute URLs - must work when published

| Context | Pattern | Example | Rationale |
|---------|---------|---------|-----------|
| **Internal** (in .s2s/) | Relative `@` | `@../backend/.s2s/CONTEXT.md` | Local structure: parent + subfolders |
| **External** (in docs/) | Absolute URL | `[Backend](https://github.com/org/backend/docs/)` | Must work when published |
| **Workspace→component** | Relative down | `@./frontend/.s2s/CONTEXT.md` | Same filesystem |
| **Component→workspace** | Relative up | `@../.s2s/architecture.md` | Same filesystem |
| **Cross-component** | Relative sibling | `@../backend/.s2s/CONTEXT.md` | Same parent folder |

**Note**: If discovery doesn't find a component (user cloned repos elsewhere), user will notice and can manually specify paths. S2S assumes standard structure: parent folder with component subfolders.

---

## 4. Init Behavior

### 4.1 Detection Logic

When `/s2s:init` runs, detect:

```
1. Is current folder already initialized?
   └─ Check for .s2s/config.yaml

2. Is current folder part of a workspace?
   └─ Check parent folders for .s2s/workspace.yaml
   └─ Check sibling folders for .s2s/ with workspace references

3. Is current folder a workspace root?
   └─ Check for .s2s/workspace.yaml
   └─ Check for multiple subfolders with potential projects

4. Should this BE a workspace?
   └─ User specified --workspace
   └─ Multiple significant subfolders detected (frontend/, backend/, etc.)
   └─ Complex project indicators (package.json with workspaces, nx.json, etc.)
```

### 4.2 Scenarios and Behavior

#### Scenario A: New Standalone Project

```
User runs: /s2s:init
Detection: Empty folder or simple project, no workspace indicators
Action: Create standard .s2s/ structure
Result: Standalone project
```

#### Scenario B: New Workspace (explicit)

```
User runs: /s2s:init --workspace
Detection: N/A (explicit flag)
Action:
  1. Create .s2s/ with workspace.yaml
  2. Ask: "Do you want to create component folders now?"
     - If yes: Ask for component names, create folders with .s2s/
     - If no: Just create workspace structure, components added later
  3. If creating components, initialize each with linked config.yaml
Result: Workspace with 0+ components
```

#### Scenario C: New Workspace (detected)

```
User runs: /s2s:init
Detection: Multiple subfolders detected (frontend/, backend/, api/, etc.)
Action:
  1. Display: "Detected potential workspace structure with components: frontend, backend, api"
  2. Ask: "Initialize as workspace?"
     - Yes → Proceed as Scenario B
     - No → Initialize current folder as standalone
Result: Workspace or standalone based on user choice
```

#### Scenario D: Adding Component to Existing Workspace

```
User runs: /s2s:init (from a subfolder of an existing workspace)
Detection: Parent has .s2s/workspace.yaml
Action:
  1. Display: "Detected workspace at: ../workspace-name"
  2. Confirm: "Initialize this folder as a component of that workspace?"
  3. If yes:
     a. Create .s2s/ with component config (type: "component", workspace reference)
     b. Update ../s2s/workspace.yaml to add this component
     c. Auto-detect dependencies (scan imports/references)
Result: New component linked to workspace
```

#### Scenario E: Existing Standalone → Convert to Workspace

```
User runs: /s2s:init --workspace (from existing standalone project)
Detection: Already has .s2s/config.yaml with type: "standalone"
Action:
  1. Warn: "This will convert standalone to workspace structure"
  2. If confirmed:
     a. Create workspace.yaml
     b. Update config.yaml: type → "workspace"
     c. Ask about component structure
Result: Converted to workspace
```

#### Scenario F: Multi-repo Workspace (sibling docs folder)

```
User runs: /s2s:init --workspace (from a folder without git, siblings have git)
Detection: No .git in current, siblings have .git
Action:
  1. Explain situation:
     "Current folder has no git repository. Workspace documentation
      should be versioned for collaboration and history.

      Detected sibling projects with git: frontend/, backend/, mobile/"

  2. Present options (via AskUserQuestion):
     a. "Create system-docs/ sibling folder with git" (Recommended)
     b. "Initialize git in current folder"
     c. "Proceed anyway (documentation won't be versioned)" - with warning

  3. Based on choice:
     - Option a: Guide user through creation OR offer to do it
       "I can create the folder and initialize git, or you can do it manually.
        Would you like me to proceed?"
     - Option b: Initialize git here, then continue
     - Option c: Warn again, then proceed if confirmed

  4. Register existing sibling projects as components
     For each detected project, confirm: "Add frontend/ as component? [Y/n]"

Result: Multi-repo workspace with user-confirmed structure
```

**Note**: Init evaluates complexity and asks for guidance when needed. If the situation is straightforward, it can proceed with minimal prompts. If complex or ambiguous, it engages the user more.

### 4.3 Dependency Auto-Detection

**Scope**: Only detect dependencies between WORKSPACE COMPONENTS (macro-level), NOT third-party libraries.

The goal is to understand which components of the system depend on each other for coordination purposes.

**Detection approach**:
```
For each component in workspace:
  1. Look for references in .s2s/ files (@../other-component/)
  2. Scan for local workspace imports (e.g., "../shared-lib")
  3. Check for explicit references in package.json/go.mod to sibling folders

  If uncertain: ASK USER to confirm detected dependencies

  Update component's depends_on in workspace.yaml
```

**Behavior**:
- Auto-detect during init when adding component to workspace
- If detection is uncertain, prompt user: "It looks like backend depends on shared-lib. Is this correct?"
- User can always manually edit workspace.yaml to add/remove dependencies
- NO separate command needed - init handles everything interactively

**Note**: Init is ALWAYS interactive (no --interactive flag) precisely to handle these decisions with user input.

### 4.4 Workspace Structure Creation

**Question**: Should init create all component .s2s/ folders, or just the workspace?

**Decision**: **Create only workspace structure initially. Components initialized on-demand.**

**Rationale**:
- User may not want all subfolders as components
- Some folders may be utilities, not real components
- Each team should init their own component when ready
- Avoids creating unused configuration

**Exception**: If user explicitly provides component list:
```
/s2s:init --workspace --components "frontend,backend,shared-lib"
```
Then create .s2s/ for each specified component.

---

## 5. Decision Propagation

### 5.1 Mechanism

When a decision at workspace level affects components:

```
┌─────────────────────────────────────────────────────────────┐
│ WORKSPACE: ADR-001 - Use JWT for authentication            │
│ affects: [frontend, backend, mobile]                        │
└──────────────────────────────┬──────────────────────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           ▼                   ▼                   ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ FRONTEND         │ │ BACKEND          │ │ MOBILE           │
│ BACKLOG.md:      │ │ BACKLOG.md:      │ │ BACKLOG.md:      │
│ TECH-003:        │ │ TECH-001:        │ │ TECH-002:        │
│ Implement JWT    │ │ Implement JWT    │ │ Implement JWT    │
│ auth             │ │ validation       │ │ token storage    │
│                  │ │                  │ │                  │
│ References:      │ │ References:      │ │ References:      │
│ @../.s2s/        │ │ @../.s2s/        │ │ @../.s2s/        │
│ decisions/       │ │ decisions/       │ │ decisions/       │
│ ADR-001.md       │ │ ADR-001.md       │ │ ADR-001.md       │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

### 5.2 Workflow

1. **Workspace roundtable** produces decision (ADR) with `affects: [components]`
2. **S2S command** (or user) creates backlog items in affected components:
   ```markdown
   ### TECH-001: Implement JWT Authentication

   **Status**: planned | **Created**: 2026-01-17
   **Origin**: Workspace decision @../.s2s/decisions/ADR-001.md

   **Context**: Implement JWT authentication as decided at workspace level.

   **Acceptance Criteria**:
   - [ ] Follows ADR-001 specifications
   - [ ] Integration tests with other components
   ```

3. **workspace.yaml** tracks propagation:
   ```yaml
   cross_cutting:
     - id: "authentication"
       decision: "ADR-001"
       affects: ["frontend", "backend", "mobile"]
       propagated_to:
         - component: "frontend"
           backlog_item: "TECH-003"
           status: "planned"
         - component: "backend"
           backlog_item: "TECH-001"
           status: "in_progress"
   ```

### 5.3 Commands for Propagation

**Option A**: Automatic during roundtable close
```
When /s2s:session:close is run on a workspace-level session:
  For each decision with affects[]:
    Ask user: "Create backlog items in affected components?"
    If yes: Create items with workspace reference
```

**Option B**: Explicit command
```
/s2s:propagate ADR-001
  - Reads decision
  - Identifies affected components
  - Creates backlog items in each
  - Updates workspace.yaml cross_cutting
```

**Recommendation**: Start with Option A (automatic suggestion), add Option B later.

---

## 6. Roundtable Scope

### 6.1 Facilitator Behavior

When facilitator starts, it must determine the scope:

```yaml
# Facilitator reads from config-snapshot.yaml:
project:
  type: "workspace"  # or "component" or "standalone"
  workspace_path: null  # or "../" if component

# If workspace: read roundtable_scope from workspace.yaml
# If component: read component context + workspace context
```

### 6.2 Scope Detection

```
IF session started from workspace-level .s2s/:
  scope = "workspace"
  context = [workspace CONTEXT.md] + [summary of all component CONTEXT.md]
  appropriate_topics = workspace.yaml → roundtable_scope.workspace_level.appropriate_topics

IF session started from component-level .s2s/:
  scope = "component"
  context = [component CONTEXT.md] + [workspace CONTEXT.md as background]
  appropriate_topics = component-specific topics

IF session started from standalone .s2s/:
  scope = "standalone"
  context = [CONTEXT.md]
  appropriate_topics = all topics (no restrictions)
```

### 6.3 Topic Validation

Facilitator should validate topic against scope:

```
User: /s2s:specs "Implement login button styling"

Facilitator checks:
  - Current scope: workspace
  - Topic: "login button styling"
  - Is this appropriate for workspace level?
    → NO, this is UI-specific, should be component-level

Facilitator response:
  "This topic appears to be component-specific (UI implementation).
   Workspace-level discussions focus on cross-component concerns.

   Suggestion: Run this roundtable from the frontend component:
     cd frontend && /s2s:specs "Implement login button styling"

   Do you want to:
   1. Continue here anyway (treat as cross-component UI pattern)
   2. Exit and run from frontend/"
```

### 6.4 Context Aggregation

For workspace-level roundtables, facilitator aggregates context:

```markdown
## System Context (from workspace)
{workspace CONTEXT.md content}

## Component Contexts (summaries)

### Frontend
{first 500 chars of frontend CONTEXT.md}
Key concerns: {extracted from backlog}

### Backend
{first 500 chars of backend CONTEXT.md}
Key concerns: {extracted from backlog}

## Cross-Cutting Decisions
{list of decisions from workspace.yaml cross_cutting}

## Open Items Across Components
{aggregated from component backlogs}
```

---

## 7. Commands Affected

| Command | Workspace-Aware Changes |
|---------|------------------------|
| `/s2s:init` | Detect workspace structure, create workspace.yaml, link components |
| `/s2s:specs` | Facilitator uses scope from workspace.yaml |
| `/s2s:design` | Same as specs |
| `/s2s:brainstorm` | Same as specs |
| `/s2s:roundtable` | Same as specs |
| `/s2s:plan` | Consider cross-component dependencies |
| `/s2s:session:close` | Offer decision propagation to components |
| `/s2s:session:validate` | Check cross-component references, dependency graph |

---

## 8. Resolved Questions

1. **Dependency detection accuracy**:
   - RESOLVED: Only detect workspace component dependencies (macro-level), not third-party libraries
   - If uncertain, ask user for confirmation
   - User can always manually edit workspace.yaml

2. **Propagation automation level**:
   - RESOLVED: User-confirmed (suggest during session:close, user decides)

3. **Component discovery**:
   - RESOLVED: Only on explicit init from component folder
   - Init detects parent workspace and offers to link

4. **Reference patterns**:
   - RESOLVED: Internal (.s2s/) = relative paths, External (docs/) = absolute URLs
   - Structure field (monorepo/multi-repo) is informational, not deterministic

## 8.1 Remaining Open Questions

1. **Versioning sync**: Should workspace version bump trigger component version checks? (Likely out of scope for v1)

---

## 9. Implementation Phases

### Phase 1: Core Structure (WORK-001)
- [ ] workspace.yaml schema
- [ ] Init detects workspace structure
- [ ] Init creates workspace configuration
- [ ] Init links components to workspace
- [ ] Component config.yaml workspace reference

### Phase 2: Roundtable Scope (WORK-002)
- [ ] Facilitator reads scope from workspace.yaml
- [ ] Context aggregation for workspace-level
- [ ] Topic validation and suggestions
- [ ] Defer-to-component behavior

### Phase 3: Decision Propagation (WORK-003)
- [ ] cross_cutting section in workspace.yaml
- [ ] Session close offers propagation
- [ ] Backlog item creation with workspace reference
- [ ] Propagation tracking

### Phase 4: Dependency Graph (WORK-004)
- [ ] Auto-detect dependencies on init
- [ ] Update dependencies command
- [ ] Affected analysis for plans
- [ ] Validation of dependency consistency

---

*This specification defines the functional requirements for workspace management in Spec2Ship.*
