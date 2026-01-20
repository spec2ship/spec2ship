# Spec2Ship Ideas

**Updated**: 2026-01-20
**Format**: Structured ideas from analysis and brainstorming

---

## ID conventions

| Prefix | Category | Example |
|--------|----------|---------|
| IDEA | Ideas and concepts | IDEA-001 |

**Status values**: `draft` | `validated` | `promoted` | `parked` | `rejected`

---

## Active

### IDEA-001: Custom agents in user projects

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Projects may want specialized agents (e.g., project-specific code reviewer) without modifying the plugin.

**Solution outline**:
- Roundtable commands scan `.claude/agents/` in project
- Project agents available alongside plugin agents (named `project:{agent-name}`)
- Agent creation command `/s2s:agent:create {name}`

**Next**: Consider for /s2s:specs when extension system is prioritized

---

### IDEA-002: Dynamic context-aware roundtables

**Status**: draft | **Created**: 2026-01-18
**Origin**: manual (post-roundtable analysis)

**Problem**: During roundtables, participants propose elaborate patterns without awareness of project-specific constraints. Example: proposing WAL/transaction patterns for a system that has no persistent state.

**Solution outline**:
1. Facilitator builds `execution_context` at session start by reading ADRs, requirements, architecture
2. Context includes: executor capabilities, limitations, established principles, guardrails
3. Participants receive context before formulating positions
4. Facilitator validates proposals against context in synthesis
5. Context evolves: new principles captured at session close

**Key insight**: Not s2s-specific - every project has execution constraints that should inform proposals.

**Complexity**: High - requires changes to facilitator, participants, session schema

**Next**: Validate with /s2s:specs roundtable on "execution context design"

---

### IDEA-003: Simulate mode for context efficiency

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Context window limits constrain roundtable depth. Spawning multiple agents uses significant tokens.

**Solution outline**:
- `--simulate` flag where command impersonates participants WITHOUT spawning agents
- Read participant .md files, generate responses inline as each role
- No Task() invocations
- Output marked as "SIMULATED"
- Target: 70%+ token reduction

**Risk**: Quality may be lower without true multi-agent deliberation

**Next**: Prototype and measure token savings vs quality trade-off

---

### IDEA-004: Phase tracking for multi-phase strategies

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Strategies like Disney and Six Hats have phases, but phase tracking is not explicit in session files.

**Solution outline**:
- Add `current_phase` field to session schema
- Phase transitions managed by facilitator
- Validation in session-observer
- `/compact` suggested at phase boundaries

**Phases by workflow**:
- Specs: Discovery → Definition → Refinement
- Design: Architecture → Components → Integration
- Brainstorm: Dreamer → Realist → Critic (already exists)

**Next**: Define phase schemas for specs and design

---

### IDEA-005: Optional session linking

**Status**: draft | **Created**: 2026-01-15
**Origin**: manual

**Problem**: Related sessions (specs → design → plan) are not formally linked.

**Solution outline**:
- `linked_sessions` field in session file
- Command to visualize session chain
- Context inheritance between linked sessions

**Next**: Low priority - manual linking works for now

---

### IDEA-006: Enhanced interactive mode

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Users want more intervention points during roundtables.

**Solution outline**:
- More frequent checkpoints in `--interactive`
- After facilitator question: "Provide input or continue?"
- User input passed to facilitator in next prompt

**Next**: Evaluate complexity vs benefit

---

### IDEA-007: Intelligent project assessment

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Commands don't assess project state before starting.

**Solution outline**:
- Analyze project state before workflow commands
- Detect: CONTEXT.md, requirements.md, architecture.md, decisions/, git status
- Suggest next step: "No requirements? Run /s2s:specs"

**Next**: Could be integrated into existing commands

---

### IDEA-009: Test framework with s2s:test

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Testing s2s commands is manual and cumbersome.

**Solution outline**:
- `/s2s:test specs|design|roundtable` subcommands
- Creates test environment (temp dir, test CONTEXT.md, config)
- Automatically adds `--diagnostic --verbose`

**Next**: Define test scenarios and expected outcomes

---

### IDEA-010: Unified export command

**Status**: draft | **Created**: 2026-01-15 | **Updated**: 2026-01-19
**Origin**: manual

**Problem**: With PATH-001, all output goes to `.s2s/`. Need a way to export/publish to project `docs/` for public documentation.

**Solution outline**:
- Single `/s2s:export` command
- Flags: `--specs`, `--design`, `--decisions`
- Format conversion: `--format ieee830`, `--format arc42`
- First export asks for target path, stores in config

**Implementation notes** (added 2026-01-19):
- Currently specs.md and design.md have output format pseudo-code inline
- When implementing export with format conversion, consider:
  1. Create `skills/output-formats/` with format templates (srs, ieee830, arc42, c4)
  2. Each format = pseudo-code that LLM interprets to generate output
  3. Export command reads source (.s2s/requirements.md), applies format template, writes to docs/
  4. Alternative: export just copies + reformats headers (simpler, less flexible)
- Decision needed: transform at export time vs transform at generation time

**Next**: Define export behavior, evaluate format template approach

---

### IDEA-011: Validate default to full

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: `/s2s:session:validate` has different levels but default should run ALL checks.

**Solution outline**:
- Default runs all checks (structural + deep + strategy)
- Add `--skip` flags for excluding specific checks

**Next**: Low priority - current behavior is acceptable

---

### IDEA-012: Optional init structure

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: `/s2s:init` creates full structure. Users may want minimal setup.

**Solution outline**:
- `--minimal` flag creates only config.yaml and CONTEXT.md
- Interactive prompt when no flag provided
- Detect existing `.s2s/` structure

**Next**: Evaluate user demand

---

---

## Parked

### IDEA-020: Ready-to-use roundtable templates

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Focus on core stability first

**Problem**: Users might want pre-configured templates for common decisions.

**Solution outline**: Templates for tech stack selection, API design review, security review, etc.

**Revisit when**: v1.0 stable, user feedback indicates demand

---

### IDEA-021: Context-aware roundtable splitting

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Context management is improving with other features

**Problem**: Large roundtables may exceed context limits.

**Solution outline**: Suggest splitting based on context size estimation.

**Revisit when**: Context limits become a proven bottleneck

---

### IDEA-022: Product owner observer agent

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Low priority, niche use case

**Problem**: Need a silent observer that tracks discussion and speaks only when user intervenes.

**Solution outline**: Observer agent that summarizes but doesn't participate unless prompted.

**Revisit when**: User feedback indicates demand

---

### IDEA-023: Workflow configuration wizard

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Current defaults work well

**Problem**: New users may find roundtable configuration overwhelming.

**Solution outline**: Interactive wizard to configure roundtable options.

**Revisit when**: Onboarding feedback indicates confusion

---

### IDEA-024: Custom participants skill

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Related to IDEA-001

**Problem**: Creating new participant types requires manual work.

**Solution outline**: Skill with templates for creating new participants.

**Revisit when**: Extension system is prioritized

---

### IDEA-025: Parallel transcriber agent

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: No GUI planned currently

**Problem**: Real-time structured output for potential GUI consumption.

**Solution outline**: Agent that produces JSON output stream.

**Revisit when**: GUI development starts

---

### IDEA-026: Rules folder best practices

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Current CLAUDE.md approach works

**Problem**: Unclear best practices for `.claude/rules/` vs `CLAUDE.md`.

**Solution outline**: Research and document best practices.

**Revisit when**: Claude Code documentation clarifies

---

### IDEA-027: File size verification

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Dev tools cover this

**Problem**: Large files may waste tokens.

**Solution outline**: Audit for large files, add to dev-check.

**Revisit when**: Part of QUAL-001 dev tools

---

### IDEA-028: GitHub Issues integration

**Status**: parked | **Created**: 2026-01-19 | **Parked**: 2026-01-19
**Origin**: manual (from notes)
**Reason**: Out of scope for v1

**Problem**: Backlog management could sync with GitHub Issues.

**Solution outline**: Bidirectional sync between BACKLOG.md and GitHub Issues.

**Revisit when**: v1.0 stable, user demand for integration

---

### IDEA-029: Session templates for common scenarios

**Status**: parked | **Created**: 2026-01-19 | **Parked**: 2026-01-19
**Origin**: manual (from notes)
**Reason**: Related to IDEA-020

**Problem**: Starting roundtables requires specifying many options.

**Solution outline**: Pre-configured session templates (quick-specs, deep-design, etc.)

**Revisit when**: User feedback indicates demand

---

## Promoted

<!-- Ideas that became work items - kept for traceability -->

### IDEA-008: Reduce code duplication in workflow commands

**Status**: promoted | **Created**: 2026-01-11 | **Promoted**: 2026-01-20
**Origin**: manual
**Promoted to**: [TECH-002](BACKLOG.md#tech-002-roundtable-command-unification) | [ADR-0011](decisions/0011-roundtable-command-unification.md)

**Problem**: specs.md, design.md, brainstorm.md have ~60% code duplication (~1600+ lines each).

**Solution outline**:
- Extract output generation to on-demand skills
- Use session-qa agent for validation
- Uniformize Phase 2 (Round Execution) across commands
- Align roundtable.md to have same capabilities
- Slim roundtable-execution skill to reference only

**Analysis completed**: Full comparison of skill vs commands documented in ADR-0011.

**Implementation**: See TECH-002 in BACKLOG.md for 6-phase plan.

---

## Rejected

<!-- Ideas that were evaluated and rejected -->
