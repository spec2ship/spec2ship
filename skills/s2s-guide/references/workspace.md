# Workspace Architecture

How Spec2Ship supports multi-component projects.

## Terminology

| Term | Definition |
|------|------------|
| **Workspace** | Configuration coordinating multiple related projects |
| **Component** | A project that is part of a workspace |
| **Standalone** | A single project not part of any workspace |
| **Monorepo** | All components in ONE git repo |
| **Multi-repo** | Components in SEPARATE git repos |

---

## Supported Structures

### Monorepo

All components in one git repository.

```
workspace/
├── .git/                    # Single git repo
├── .s2s/                    # Workspace-level S2S
│   ├── workspace.yaml       # Component registry
│   ├── config.yaml
│   ├── CONTEXT.md
│   └── README.md
├── frontend/
│   └── .s2s/                # Component-level S2S
├── backend/
│   └── .s2s/
└── shared-lib/
    └── .s2s/
```

### Multi-repo

Components in separate git repositories.

```
parent-folder/               # NO .git here
├── system-docs/             # Dedicated docs project
│   ├── .git/                # Own git repo
│   └── .s2s/                # Workspace-level S2S
│       └── workspace.yaml
├── frontend/
│   ├── .git/                # Own git repo
│   └── .s2s/
└── backend/
    ├── .git/
    └── .s2s/
```

---

## Context Cascade (@ References)

Component CONTEXT.md can reference workspace context using @ import:

```markdown
# In component/.s2s/CONTEXT.md

## Workspace Context

@../.s2s/CONTEXT.md
```

This loads workspace context into Claude's memory alongside component context.

### Rules

1. **Component → Workspace**: Use @ reference
2. **Workspace → Components**: TEXT ONLY (avoid memory bloat)
3. **Sibling components**: Load on-demand when needed
4. **All paths**: Must be RELATIVE

### Header Convention

To avoid ambiguity when contexts are loaded together:

| Workspace Header | Component Header |
|------------------|------------------|
| `## System Overview` | `## Component Overview` |
| `## System Objectives` | (inherited) |
| `## System Constraints` | `## Component Constraints` |
| `## Workspace Open Questions` | `## Component Open Questions` |

---

## Configuration Files

### workspace.yaml

Located at workspace root: `.s2s/workspace.yaml`

```yaml
name: "my-system"
version: "1.0.0"

components:
  - name: "frontend"
    path: "./frontend"
    type: "application"
    depends_on: ["shared-lib"]
  - name: "backend"
    path: "./backend"
    type: "service"
    depends_on: ["shared-lib"]
  - name: "shared-lib"
    path: "./shared-lib"
    type: "library"
    depends_on: []

cross_cutting:
  decisions: []
  concerns: []
```

### Component config.yaml

```yaml
name: "frontend"
type: "component"           # NOT "standalone"

workspace:
  path: ".."                # Relative path to workspace root
```

---

## Init Behavior

Init detects context and guides user:

| Scenario | Detection | Result |
|----------|-----------|--------|
| New standalone | No workspace indicators | Create `.s2s/` |
| New workspace | `--workspace` flag | Create `workspace.yaml` |
| Detected workspace | Multiple subfolders | Suggest workspace |
| Adding component | Parent has `workspace.yaml` | Link as component |

---

## Roundtable Scope

Facilitator uses **decision principles** to determine scope:

**Workspace-level**: Does this require coordination between teams?

**Component-level**: Does this affect only this component's implementation?

If topic doesn't match scope, facilitator suggests running from appropriate location.

---

## Versioning

### Always Version (commit to git)

- `workspace.yaml`
- `config.yaml`
- `CONTEXT.md`
- `README.md`
- `BACKLOG.md`
- `decisions/`
- `plans/`

### Never Version (add to .gitignore)

- `sessions/` (volatile, large)
