# INIT-002: Intelligent Project Assessment

**Status**: draft
**Priority**: medium
**Category**: Init
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Currently, s2s commands (specs, design, brainstorm) don't assess the project's current state before starting. This leads to suboptimal experiences:

- Starting `/s2s:design` without requirements leads to poor results
- Starting `/s2s:specs` on a project that already has comprehensive docs is redundant
- Users don't know what the recommended "next step" is

The goal is to provide intelligent, context-aware suggestions based on:
- Existing artifacts (requirements.md, architecture.md, etc.)
- Project maturity (new vs. established)
- Repository state (published, has CI/CD, etc.)

## Proposal

### 1. Project State Analysis

Before each workflow command, analyze:
- Existence and completeness of `.s2s/CONTEXT.md`
- Existence of `docs/specifications/requirements.md`
- Existence of `docs/architecture/`
- Git status (commits, remote, branches)
- README.md quality and completeness

### 2. Intelligent Suggestions

- If no CONTEXT.md: "Run /s2s:init first"
- If no requirements but has code: "Generate baseline requirements from existing codebase?"
- If requirements exist but no architecture: "Proceed with /s2s:design"
- If project is mature/published: Ask before modifying structure

### 3. Specialized Roundtables

- Detect if project needs specific discussion (e.g., OSS governance)
- Propose appropriate roundtable with relevant participants (oss-community-manager, documentation-specialist)

### Files to Modify
- `commands/specs.md`
- `commands/design.md`
- `commands/brainstorm.md`
- Possibly: new `agents/exploration/project-assessor.md`

## Acceptance Criteria

- [ ] Project state analysis runs before workflow commands
- [ ] Clear suggestions based on detected state
- [ ] User can override suggestions
- [ ] No false positives (don't suggest specs if they exist)

## Related

- Depends on: INIT-001 (structure detection logic)
- Related to: RT-002 (start.md orchestration)
- Supersedes: Old P2-6, P2-7

## Open Questions

- How deep should codebase analysis go? Just file existence or content analysis?
- Should this use codebase-analyzer agent or be inline in commands?
- What's the UX for suggestions? Blocking prompt or informational message?

## Notes

This enables "what's next" intelligence - s2s guides user through the workflow based on project state.
