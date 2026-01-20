# Workspace Scope Handling

Instructions for workspace and component project types during roundtable sessions.

> **Note**: Standalone projects skip all workspace scope handling.

## Step 1.3b: Load Workspace Scope

### For workspace projects

**IF project.type == "workspace"**:

Read `.s2s/workspace.yaml` and update config-snapshot.yaml:
```yaml
workspace_scope:
  decision_principle: "{from workspace.yaml: roundtable_scope.workspace_level.decision_principle}"
  indicators: ["{from workspace.yaml: roundtable_scope.workspace_level.indicators}"]
  defer_indicators: ["{from workspace.yaml: roundtable_scope.workspace_level.defer_indicators}"]
```

### For component projects

**IF project.type == "component"**:

Read parent workspace.yaml at `{workspace_path}/.s2s/workspace.yaml` and update config-snapshot.yaml:
```yaml
workspace_scope:
  decision_principle: "{from parent workspace.yaml: roundtable_scope.component_level.decision_principle}"
  escalate_indicators: ["{from parent workspace.yaml: roundtable_scope.component_level.escalate_indicators}"]
  inherits_context_from: "workspace"
```

---

## Step 1.3c: Context Loading Strategy (ADR-0009)

**Workspace context is handled via @ cascade in CLAUDE.md files:**

```
CLAUDE.md → @.s2s/CONTEXT.md → @../.s2s/CONTEXT.md (workspace)
```

- **Component sessions**: Workspace context is already in memory (loaded at session start)
- **Workspace sessions**: Only workspace CONTEXT.md is in memory (components listed as text)
- **No runtime aggregation needed** for workspace context

**Path resolution**: All @ paths are relative to the file containing them (not CWD).

### Cross-component discussions (workspace projects only)

**IF project.type == "workspace"**:

1. Read cross_cutting decisions from workspace.yaml and add to context-snapshot:
```yaml
cross_cutting_decisions:
  - id: "{from workspace.yaml: cross_cutting[].id}"
    decision: "{ADR reference}"
    affects: ["{component ids}"]
```

2. **On-demand sibling loading**: When topic involves specific components:
   - Read component list from workspace CONTEXT.md or workspace.yaml
   - For each relevant component, read `{component-path}/.s2s/CONTEXT.md`
   - Include in facilitator's context for that round
   - This keeps memory low (~1K tokens) for normal discussions
   - Only loads siblings (~300-500 tokens each) when cross-component context needed

**Example**: Topic "API contract between frontend and backend"
- Load `./frontend/.s2s/CONTEXT.md` (relevant component)
- Load `./backend/.s2s/CONTEXT.md` (relevant component)
- Skip `./mobile/.s2s/CONTEXT.md` (not involved in this topic)

---

## Step 1.4: Topic Validation

### For workspace projects

**IF project.type == "workspace"**:

Check if topic appears component-specific:
1. Compare topic against `workspace_scope.defer_indicators`
2. If any indicator matches:
   ```
   SCOPE NOTICE
   ---
   This topic appears component-specific:
   Topic: "{topic}"
   Matched indicator: "{matched indicator}"

   Workspace-level discussions focus on:
   {workspace_scope.decision_principle}

   Options:
   1. Continue here (treat as cross-component pattern)
   2. Run from component folder instead
   ```
   Use AskUserQuestion to let user decide.

### For component projects

**IF project.type == "component"**:

Check if topic should escalate to workspace:
1. Compare topic against `workspace_scope.escalate_indicators`
2. If any indicator matches:
   ```
   SCOPE NOTICE
   ---
   This topic may affect other components:
   Topic: "{topic}"
   Matched indicator: "{matched indicator}"

   Component discussions focus on:
   {workspace_scope.decision_principle}

   Options:
   1. Continue here (internal to this component)
   2. Run from workspace folder instead
   ```
   Use AskUserQuestion to let user decide.

### For standalone projects

**IF project.type == "standalone"**:

No topic validation needed. All topics are appropriate.
