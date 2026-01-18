# Workspace Context Loading via @ Cascade

## Status

accepted

## Context and Problem Statement

In a workspace with multiple components, how should context be shared between workspace and components? We need components to have access to workspace-level context (business domain, cross-cutting decisions, constraints) without excessive memory usage.

### Key Constraints

1. **Memory efficiency**: Loading all component CONTEXT.md files into memory bloats context (~300-500 tokens each)
2. **Team portability**: Paths must be relative, not absolute (works on any developer's machine)
3. **Automatic loading**: Developers shouldn't need to manually include context
4. **Claude Code behavior**: @ references work only in CLAUDE.md and its imported files (not in arbitrary .md files)

## Decision Drivers

- Memory footprint per session (token cost)
- Quality of LLM responses (having right context available)
- Developer experience (automatic vs manual context loading)
- Maintenance burden (keeping context in sync)

## Considered Options

### Option A: Runtime Aggregation

Commands read and aggregate context from multiple files at execution time.

- Good, because complete context when needed
- Bad, because complex command implementation
- Bad, because context may be stale or inconsistent

### Option B: @ Cascade (Child → Parent only)

Component CONTEXT.md includes `@../.s2s/CONTEXT.md` to load workspace context. Workspace does NOT reference components.

- Good, because automatic loading via Claude Code's @ cascade (max 5 hops)
- Good, because low memory footprint (~600-1000 tokens total)
- Good, because component always has workspace context
- Bad, because workspace doesn't automatically see component details

### Option C: Bidirectional @ References

Both workspace → components and components → workspace.

- Good, because complete visibility everywhere
- Bad, because high memory footprint (grows with component count)
- Bad, because potential for confusion with duplicate content

### Option D: Inline Duplication

Copy workspace context into each component during init.

- Good, because simple implementation
- Bad, because content goes stale when workspace changes
- Bad, because maintenance nightmare

## Decision Outcome

Chosen option: **Option B: @ Cascade (Child → Parent only)** + **Option E: Content Separation**, because it balances memory efficiency with useful context availability while avoiding ambiguity.

### Secondary Problem: Flat Memory Ambiguity

When workspace and component CONTEXT.md are loaded via @ cascade, Claude sees them "flat" in memory. If both files have identical headers (e.g., `## Open Questions`), Claude cannot distinguish which belongs to which.

**Solution**:
1. **Content separation**: CONTEXT.md contains only semantic info for LLM. Paths, commands, how-to go in README.md (not loaded in memory).
2. **Header naming convention**: Use prefixed headers to disambiguate.

### Architecture

```
CLAUDE.md
└── @.s2s/CONTEXT.md (component - semantic only, ~300-500 tokens)
    └── @../.s2s/CONTEXT.md (workspace - semantic only, ~300-500 tokens)
        └── STOP (no @ to siblings)

.s2s/README.md (NOT loaded in memory)
└── Paths, commands, how-to documentation for humans
```

### Header Naming Convention

| Workspace Header | Component Header | Rationale |
|------------------|------------------|-----------|
| `# ... - Workspace Context` | `# ... - Component Context` | Clear document identity |
| `## System Overview` | `## Component Overview` | "System" = workspace level |
| `## System Objectives` | (inherited) | Component inherits from workspace |
| `## System Constraints` | `## Component Constraints` | Both may have constraints |
| `## Workspace Open Questions` | `## Component Open Questions` | Critical disambiguation |

### Rules

1. **Component → Workspace**: Always use @ reference in CONTEXT.md
2. **Workspace → Components**: TEXT ONLY (name, role table)
3. **Sibling components**: Load on-demand when cross-component discussion needed
4. **All paths**: Must be RELATIVE for team portability
5. **S2S paths and commands**: Go in README.md, NOT in CONTEXT.md
6. **Headers**: Use "System/Workspace" prefix in workspace, "Component" prefix in component

### Memory Budget

| Scenario | Tokens (estimated) |
|----------|-------------------|
| Standalone project | ~300-500 |
| Component (with workspace) | ~600-1000 |
| Workspace-level (all siblings loaded) | ~2000-3500 (only when needed) |

### Consequences

- Good, because workspace context automatically available in components
- Good, because memory stays under 1K tokens for normal development
- Good, because paths are relative and portable
- Good, because @ cascade is native Claude Code feature (no custom code)
- Neutral, because cross-component discussions require explicit sibling loading
- Bad, because workspace doesn't "see" component details by default

## Technical Details

### Claude Code @ Cascade Behavior (Verified)

- CLAUDE.md can import files with `@path/to/file`
- Imported files can recursively import (max 5 hops)
- Paths are resolved **relative to the file containing the @** (not CWD)
- Loop detection: Claude deduplicates files (no infinite loops)
- Sibling resolution works: `@../component-b/...` from workspace resolves correctly

### On-Demand Loading

For cross-component discussions, roundtable-execution SKILL instructs facilitator to:
1. Check if topic involves specific components
2. Read those component CONTEXT.md files explicitly
3. Include relevant details in synthesis

## More Information

- Verified empirically with test workspace structure
- Claude Code documentation confirms recursive import with 5-hop limit
- Related: WORK-002 (roundtable scope awareness)
- Implementation plan: `.s2s/plans/20260117-context-restructure.md`
- Option E (Content Separation) added 2026-01-17 to address flat memory ambiguity
