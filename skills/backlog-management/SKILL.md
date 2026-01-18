---
name: Backlog Management
description: "This skill should be used when the user asks to 'add to backlog',
  'update backlog', 'check backlog', 'list backlog items', 'prioritize backlog'.
  Provides conventions for managing the project backlog in .s2s/BACKLOG.md."
version: 0.1.0
---

# Backlog Management

Conventions and patterns for managing the Spec2Ship project backlog.

## Backlog Location

The backlog is stored in `.s2s/BACKLOG.md` as a single markdown file optimized for LLM consumption.

## ID Conventions

| Prefix | Category | Use for |
|--------|----------|---------|
| ARCH | Architecture | Major structural decisions |
| EXT | Extensions | Customization, plugins |
| QUAL | Quality | Validation, testing quality |
| TEST | Testing | Test infrastructure |
| INIT | Initialization | Setup, onboarding |
| SESS | Sessions | Session management |
| RT | Roundtable | Discussion features |
| CTX | Context | Token optimization |
| OUT | Output | Export, formatting |
| DEBT | Technical debt | Code quality issues |
| CLEAN | Cleanup | Refactoring, removal |
| LINK | Linking | Cross-references |
| MISC | Miscellaneous | Other |

**Format**: `{PREFIX}-{NNN}` (e.g., ARCH-001, DEBT-002)

## Status Values

| Status | Meaning |
|--------|---------|
| `draft` | Initial idea, needs refinement |
| `planned` | Refined, ready for implementation |
| `in_progress` | Currently being worked on |
| `blocked` | Waiting on dependency |
| `completed` | Done and verified |
| `rejected` | Not doing, with reason |
| `merged` | Absorbed into another item |

## Item Structure

```markdown
### {ID}: {Title}

**Status**: {status} | **Created**: {date}

**Context**: Why this is needed.

**Proposal**: What to do (for draft/planned).

**Acceptance Criteria**:
- [ ] Criterion 1
- [ ] Criterion 2
```

## Priority Sections

Items are organized by priority in the backlog:

1. **High Priority** - Current focus, blocking issues
2. **Medium Priority** - Important but not urgent
3. **Low Priority** - Nice to have, future work
4. **Ideas / Notes** - Unstructured, for capture
5. **Completed** - Done items (table format)
6. **Rejected** - Not doing (table format)

## Operations

### Adding an Item

1. Choose appropriate prefix based on category
2. Get next available number for that prefix
3. Add to appropriate priority section
4. Set status to `draft`

### Updating Status

Edit the **Status** field inline. Add **Updated** date if significant changes.

### Completing an Item

1. Move to Completed table
2. Add completion date and notes
3. Remove from priority section

### Merging Items

1. Update absorbed item status to `merged`
2. Add note: "Merged into {ID}"
3. Update target item to reference merged items
