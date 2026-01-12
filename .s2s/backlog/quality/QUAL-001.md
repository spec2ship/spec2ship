# QUAL-001: Code Review Agent for s2s

**Status**: draft
**Priority**: high
**Category**: Quality
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

S2s development requires consistent adherence to:
- Claude Code plugin guidelines
- S2s-specific patterns (CLAUDE.md)
- Cross-component consistency (specs ↔ design ↔ brainstorm)

A specialized code reviewer would verify coherence with every modification.

## Proposal

### 1. S2s Code Reviewer Agent

- Location: `.claude/agents/s2s-code-reviewer.md` (in s2s repo)
- Not shipped with plugin
- Used during development

### 2. Verification Checklist

| Check | What to Verify |
|-------|----------------|
| Artifact types | REQ/BR/NFR for specs, ARCH/COMP/INT for design, IDEA/RISK/MIT for brainstorm |
| States | active\|amended\|superseded\|withdrawn for standard, open\|resolved for OQ/CONF |
| Agreement | consensus\|draft\|conflict |
| Participants | Correct for workflow |
| Strategy | Default correct for workflow |
| YOU MUST | Used for critical actions |
| Agent invocation | "**Use the roundtable-X agent**" pattern |
| Warning format | `⚠️ VALIDATION WARNING` (uppercase) |
| Immutability | Headers in generated docs |
| Embedded artifacts | Maps keyed by ID |

### 3. Cross-Component Checks

- If specs.md modified → verify design.md and brainstorm.md
- If agent template changed → verify all agents updated
- If schema changed → verify all usages

### 4. Integration

- Run before commits
- Or as pre-PR check
- Report findings clearly

### 5. Guidelines as Skills

- Convert `.claude/guidelines/` to skills
- Code reviewer agent loads and uses them
- Reusable by other projects

### Files to Create
- `.claude/agents/s2s-code-reviewer.md` (new, in s2s repo)
- Possibly: `.claude/skills/s2s-guidelines/SKILL.md`

## Acceptance Criteria

- [ ] Code reviewer agent exists in .claude/
- [ ] All checklist items verified
- [ ] Cross-component consistency checked
- [ ] Clear report of findings
- [ ] Not shipped with plugin

## Related

- Related to: EXT-001 (Custom Agents in .claude/)
- Related to: QUAL-002 (Validate improvements)

## Open Questions

- Should this be an agent or a command?
- How to trigger: manual, pre-commit hook, or CI?
- Should it auto-fix or just report?

## Notes

This agent would use the verification checklist from the previous plan:
- Artifact types per workflow
- State machine compliance
- LLM patterns (YOU MUST, agent invocation)
- Cross-component consistency
