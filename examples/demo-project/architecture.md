# Architecture Documentation

**Project**: TaskTracker
**Generated**: 2026-01-11
**Strategy**: debate

---

## 1. Introduction

This document describes the architecture for TaskTracker, a CLI-based task management application.

## 2. Architecture Decisions

### ARCH-001: Storage Format - JSON Files
- **Status**: Accepted
- **Context**: Need local, portable storage without dependencies.
- **Decision**: Use JSON files for task storage.
- **Rationale**:
  - Human-readable and editable
  - No external dependencies
  - Easy to version control
  - Sufficient performance for target scale
- **Trade-offs**:
  - Slower than SQLite for large datasets
  - No built-in querying
- **Alternatives Considered**:
  - SQLite: Rejected (adds dependency)
  - YAML: Rejected (parsing slower, less tooling)

### ARCH-002: Single Binary Distribution
- **Status**: Accepted
- **Context**: Cross-platform distribution without installation.
- **Decision**: Compile to single static binary per platform.
- **Rationale**:
  - No installation required
  - No runtime dependencies
  - Easy distribution via GitHub releases
- **Trade-offs**:
  - Larger binary size
  - Separate builds per platform

### ARCH-003: Command Pattern for CLI
- **Status**: Accepted
- **Context**: Need extensible command structure.
- **Decision**: Use command pattern with subcommands.
- **Rationale**:
  - Clear separation of concerns
  - Easy to add new commands
  - Familiar pattern (git, docker)
- **Syntax**: `tt <command> [args] [flags]`

---

## 3. Component Structure

```
┌─────────────────────────────────────────────────────────────┐
│                          CLI Layer                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │   add   │ │  list   │ │  start  │ │  done   │   ...     │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
└───────┼──────────┼──────────┼──────────┼───────────────────┘
        │          │          │          │
        ▼          ▼          ▼          ▼
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Task      │  │   TaskList   │  │  Workflow    │      │
│  │   (Entity)   │  │  (Aggregate) │  │  (Service)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ JsonStorage  │  │  GitClient   │  │   Config     │      │
│  │              │  │  (optional)  │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Components

| Component | Responsibility |
|-----------|----------------|
| **CLI Layer** | Parse commands, validate input, format output |
| **Domain Layer** | Business logic, entities, validation rules |
| **Infrastructure Layer** | Storage, external integrations |

---

## 4. Data Model

### Task Entity

```yaml
Task:
  id: integer          # Unique, sequential, never reused
  title: string        # Required, non-empty
  description: string  # Optional
  status: enum         # todo | in-progress | done
  priority: enum       # high | medium | low
  created_at: datetime
  updated_at: datetime
  completed_at: datetime  # null if not done
  tags: string[]       # Optional
  git_refs: GitRef[]   # Optional
```

### Storage Schema

```json
{
  "version": 1,
  "next_id": 43,
  "tasks": [
    {
      "id": 42,
      "title": "Implement add command",
      "status": "done",
      "priority": "high",
      "created_at": "2026-01-10T10:00:00Z",
      "completed_at": "2026-01-11T14:30:00Z"
    }
  ],
  "archived": []
}
```

---

## 5. Key Interfaces

### TaskRepository

```
interface TaskRepository:
  create(task: Task) -> Task
  get(id: int) -> Task | None
  list(filters: Filters) -> Task[]
  update(task: Task) -> Task
  delete(id: int) -> bool
  archive_completed(older_than: Duration) -> int
```

### WorkflowService

```
interface WorkflowService:
  start_task(id: int) -> Result<Task, Error>
  complete_task(id: int) -> Result<Task, Error>
  validate_transition(from: Status, to: Status) -> bool
```

---

## 6. File Structure

```
~/.tasktracker/
├── config.json       # User configuration
├── tasks.json        # Active tasks
└── archive/          # Archived tasks by year
    └── 2026.json
```

---

## 7. Open Questions

| ID | Question | Status |
|----|----------|--------|
| OQ-001 | Conflict resolution for concurrent edits? | Open |
| OQ-002 | Encryption for sensitive task data? | Deferred |

---

## 8. Summary

| Decision | Choice |
|----------|--------|
| Storage | JSON files |
| Distribution | Single binary |
| CLI Pattern | Subcommands |
| Architecture | 3-layer (CLI, Domain, Infrastructure) |

---

*Generated by Spec2Ship `/s2s:design`*
*This is an example output for demonstration purposes.*
