# {workspace-name} - Workspace Context

<!--
This file is maintained by Spec2Ship init command.
Import this in CLAUDE.md using @.s2s/CONTEXT.md
Run /s2s:init to populate or update this file.

MEMORY LOADING:
- This file is loaded via @ import from CLAUDE.md
- Component CONTEXT.md files reference THIS file via @ cascade
- DO NOT use @ references to component CONTEXT.md files here (memory bloat)
- Components are listed as TEXT only - details loaded on-demand when needed

HEADER CONVENTION:
- Headers use "System" or "Workspace" prefix to avoid ambiguity
- When loaded alongside component CONTEXT.md, Claude can distinguish
- See ADR-0009 for rationale on @ cascade design and header naming

NOTE: S2S commands, paths, and how-to documentation are in README.md (not loaded in memory)
-->

## System Overview

{description}

## Business Domain

{business-domain}

## System Objectives

- {objective-1}
- {objective-2}

## System Constraints

- {constraint-1}
- {constraint-2}

## Cross-Cutting Concerns

<!-- Populated by /s2s:design or manually -->
- **Authentication**: TBD
- **Authorization**: TBD
- **Logging**: TBD
- **Monitoring**: TBD

## Components

<!-- TEXT ONLY - No @ references to avoid loading all components into memory -->
| Component | Role |
|-----------|------|
| {component-name} | {component-role} |

*Component registry is maintained in `.s2s/workspace.yaml`*

## Architecture Principles

<!-- Populated by /s2s:design -->
TBD - run `/s2s:design` to define architecture

## Workspace Open Questions

<!-- Populated during /s2s:specs or /s2s:design sessions -->
- None identified yet

---

*Last updated: {date}*
