# Workflow Guides

Step-by-step guides for using Spec2Ship workflows.

## Guides

| Guide | Description |
|-------|-------------|
| [Specs Workflow](./specs-workflow.md) | Define requirements with `/s2s:specs` |
| [Design Workflow](./design-workflow.md) | Design architecture with `/s2s:design` |
| [Brainstorm Workflow](./brainstorm-workflow.md) | Creative exploration with `/s2s:brainstorm` |
| [Plan Workflow](./plan-workflow.md) | Create and execute implementation plans |
| [Session Management](./session-management.md) | Pause, resume, and validate sessions |

## Quick Reference

### Starting a New Project

```bash
# 1. Initialize project
/s2s:init

# 2. Define requirements
/s2s:specs

# 3. Design architecture
/s2s:design

# 4. Create implementation plan
/s2s:plan --new "first-feature"

# 5. Start implementation
/s2s:plan --session
```

### Returning to a Project

```bash
# Check current state
/s2s:session

# Resume if there's an active session
/s2s:roundtable --session

# Or start fresh
/s2s:specs
```

### Using Interactive Mode

```bash
# Interactive mode pauses after each round
/s2s:specs --interactive
```

Options when prompted:
- **continue**: Proceed to next round
- **skip**: Skip current topic
- **pause**: Save and exit (resume later)

---

*See also: [Concepts](../concepts/) | [Commands](../reference/commands.md)*
