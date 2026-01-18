# Spec2Ship - Component Context

<!--
This file is maintained by Spec2Ship init command.
Import this in CLAUDE.md using @.s2s/CONTEXT.md
Run /s2s:init to populate or update this file.

MEMORY LOADING:
- This file should be imported in CLAUDE.md via @.s2s/CONTEXT.md
- Claude Code automatically loads referenced files into memory at session start
- This is a standalone project (not part of a workspace)

HEADER CONVENTION:
- Headers use "Component" or "Project" prefix for consistency
- If converted to a workspace component later, headers are already compatible
- See ADR-0009 for rationale on header naming conventions

NOTE: S2S paths and how-to documentation are in README.md (not loaded in memory)
-->

## Business Domain

Developer Tools / DevOps

## Project Objectives

- New product development: Building a comprehensive AI-assisted development framework
- Adding capabilities: Extending functionality with new commands, agents, and skills

## Project Constraints

- Must work within Claude Code's plugin architecture
- No external dependencies - pure markdown/yaml implementation
- Commands cannot spawn subagents that spawn other subagents

## Component Overview

Claude Code plugin that automates specs → planning → implementation → shipping. Spec2Ship (s2s) is a framework that guides software development through the full lifecycle using AI-assisted roundtable discussions and structured workflows.

## Scope

**Type**: Full implementation

**In scope**:
- Complete roundtable discussion system with multiple facilitation strategies
- Structured workflow commands (init, specs, design, brainstorm, plan)
- Specialized AI agents for different perspectives (architect, tech-lead, PM, QA, etc.)
- Knowledge skills library (arc42, MADR, ISO 25010, conventional commits)
- Session management and state persistence
- Template system for standardized artifacts

**Out of scope**:
- Non-Claude AI models (GPT, Gemini, etc.)
- IDE integrations (VS Code, JetBrains, etc.)

## Technical Stack

- **Languages**: Markdown, YAML, JSON
- **Framework**: Claude Code Plugins
- **Architecture**: Component-based (Commands, Agents, Skills)

## Component Open Questions

- Release strategy and versioning approach
- Marketplace distribution timeline

---
*Last updated: 2026-01-17*
