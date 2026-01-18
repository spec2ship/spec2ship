# {project-name} - Component Context

<!--
This file is maintained by Spec2Ship init command.
Import this in CLAUDE.md using @.s2s/CONTEXT.md
Run /s2s:init to populate or update this file.

MEMORY LOADING:
- This file should be imported in CLAUDE.md via @.s2s/CONTEXT.md
- For components, the workspace context below uses @ cascade (max 5 hops)
- Claude Code automatically loads referenced files into memory at session start
- Path must be RELATIVE (e.g., "../.s2s/CONTEXT.md") for team portability

HEADER CONVENTION:
- Headers use "Component" prefix to avoid ambiguity with workspace context
- When loaded alongside workspace CONTEXT.md, Claude can distinguish
- See ADR-0009 for rationale on @ cascade design and header naming

NOTE: S2S paths and how-to documentation are in README.md (not loaded in memory)
-->

<!-- WORKSPACE_CONTEXT_START - Only present for type: component -->
## Workspace Context

This component is part of **{workspace-name}** workspace.

**Role**: {component-role-description}

**Workspace path**: `{workspace-path}`

<!-- @ cascade: This reference is resolved when CLAUDE.md imports this file -->
@{workspace-path}/.s2s/CONTEXT.md

---
<!-- WORKSPACE_CONTEXT_END -->

<!-- STANDALONE_CONTEXT_START - Only present for type: standalone -->
## Business Domain

{business-domain}

## Project Objectives

- {objective-1}
- {objective-2}

## Project Constraints

- {constraint-1}
- {constraint-2}
<!-- STANDALONE_CONTEXT_END -->

## Component Overview

{description}

## Scope

**Type**: {scope-type}

**In scope**:
- {in-scope}

**Out of scope**:
- {out-of-scope}

## Technical Stack

<!-- Populated by /s2s:design or manually -->
TBD - run `/s2s:design` to define architecture and stack

<!-- COMPONENT_CONSTRAINTS_START - Only present for type: component -->
## Component Constraints

- {component-constraints}
<!-- COMPONENT_CONSTRAINTS_END -->

## Component Open Questions

<!-- Populated during /s2s:specs or /s2s:design sessions -->
- None identified yet

---
*Last updated: {date}*
*Phase: init*
