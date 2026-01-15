# Project Context

## Overview

Claude Code plugin that automates specs → planning → implementation → shipping. Spec2Ship (s2s) is a framework that guides software development through the full lifecycle using AI-assisted roundtable discussions and structured workflows.

## Business Domain

Developer Tools / DevOps

## Objectives

- New product development: Building a comprehensive AI-assisted development framework
- Adding capabilities: Extending functionality with new commands, agents, and skills

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

## Constraints

- Must work within Claude Code's plugin architecture
- No external dependencies - pure markdown/yaml implementation
- Commands cannot spawn subagents that spawn other subagents

## Technical Stack

- **Languages**: Markdown, YAML, JSON
- **Framework**: Claude Code Plugins
- **Architecture**: Component-based (Commands, Agents, Skills)

## Project Tracking

**Backlog**: `.s2s/BACKLOG.md` - Single source of truth for all planned work, ideas, and technical debt. Uses category-based IDs (ARCH-*, EXT-*, QUAL-*, etc.) with status tracking.

**Decisions**: `.s2s/decisions/` - Architecture Decision Records (ADRs) in MADR format.

## Open Questions

- Release strategy and versioning approach
- Marketplace distribution timeline

---
*Last updated: 2026-01-15*
