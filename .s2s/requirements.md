# Spec2Ship Requirements

**Updated**: 2026-01-19
**Format**: Structured requirements extracted from implemented features and specifications

---

## ID conventions

| Prefix | Category | Example |
|--------|----------|---------|
| REQ | Functional requirements | REQ-001 |
| NFR | Non-functional requirements | NFR-001 |
| BR | Business rules | BR-001 |

**Status values**: `draft` | `approved` | `implemented`

**Priority values**: `must` | `should` | `could` | `wont`

---

## 1. Initialization and project setup

### REQ-001: Project initialization

**Status**: implemented | **Priority**: must

**Description**: The system must initialize a new s2s project by creating the `.s2s/` directory structure with configuration and context files.

**Acceptance criteria**:
- [x] Creates `.s2s/` directory
- [x] Generates `config.yaml` with defaults
- [x] Generates `CONTEXT.md` with project information
- [x] Generates `BACKLOG.md` for tracking work
- [x] Generates `ideas.md` for idea tracking
- [x] Detects existing tech stack

**Implements**: `/s2s:init`

---

### REQ-002: Workspace detection and support

**Status**: implemented | **Priority**: should

**Description**: The system must detect if a project is part of a workspace (monorepo/multi-repo) and configure accordingly.

**Acceptance criteria**:
- [x] Detect workspace structure during init
- [x] Support monorepo, multi-repo, and hybrid structures
- [x] Create `workspace.yaml` for workspace roots
- [x] Link components to parent workspace
- [x] Warn if `.s2s/` created in non-git folder

**Specification**: Former `.s2s/specs/WORK-001-workspace-specification.md`

**Implements**: `/s2s:init --workspace`

---

## 2. Roundtable discussion system

### REQ-010: Multi-agent roundtable discussions

**Status**: implemented | **Priority**: must

**Description**: The system must support structured discussions with multiple AI participants (agents) coordinated by a facilitator.

**Acceptance criteria**:
- [x] Facilitator agent orchestrates discussions
- [x] Multiple participant agents provide perspectives
- [x] Parallel participant responses (blind voting)
- [x] Synthesis after each round
- [x] Session file tracks all state

**Implements**: `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm`, `/s2s:roundtable`

---

### REQ-011: Facilitation strategies

**Status**: implemented | **Priority**: must

**Description**: The system must support multiple facilitation strategies for different discussion types.

**Acceptance criteria**:
- [x] Standard (round-robin) strategy
- [x] Disney (dreamer/realist/critic) strategy
- [x] Debate (pro/con) strategy
- [x] Consensus-driven strategy
- [x] Six Thinking Hats strategy
- [x] Auto-detect strategy from topic keywords

**Implements**: `--strategy` flag, `skills/roundtable-strategies/`

---

### REQ-012: Session management

**Status**: implemented | **Priority**: must

**Description**: The system must persist session state and support resume after interruption.

**Acceptance criteria**:
- [x] Session file is single source of truth
- [x] Auto-detect active sessions
- [x] Resume from any interruption point
- [x] Track agent_ids for facilitator and participants
- [x] Close sessions when complete

**Implements**: `/s2s:session:list`, `/s2s:session:status`, `/s2s:session:close`

---

### REQ-013: Interactive and verbose modes

**Status**: implemented | **Priority**: should

**Description**: The system must support user interaction during roundtables and detailed output for debugging.

**Acceptance criteria**:
- [x] `--interactive` pauses after each round for user input
- [x] `--verbose` includes full responses in session file
- [x] `--diagnostic` triggers observer agent for analysis

**Implements**: Command flags

---

## 3. Workflow commands

### REQ-020: Specs workflow

**Status**: implemented | **Priority**: must

**Description**: The system must support requirements definition through roundtable discussion.

**Acceptance criteria**:
- [x] Reads CONTEXT.md and ideas.md as input
- [x] Produces requirements.md with REQ-*, NFR-* artifacts
- [x] Supports SRS and other output formats
- [x] Smart source detection (proposes recent sources)

**Implements**: `/s2s:specs`

---

### REQ-021: Design workflow

**Status**: implemented | **Priority**: must

**Description**: The system must support architecture design through roundtable discussion.

**Acceptance criteria**:
- [x] Reads requirements.md as input (warns if missing)
- [x] Produces architecture.md with COMP-*, INT-* artifacts
- [x] Creates ADRs in decisions/ folder
- [x] Supports arc42 and other output formats

**Implements**: `/s2s:design`

---

### REQ-022: Brainstorm workflow

**Status**: implemented | **Priority**: must

**Description**: The system must support creative ideation through roundtable discussion.

**Acceptance criteria**:
- [x] Uses Disney strategy by default (dreamer/realist/critic)
- [x] Produces ideas.md with IDEA-* artifacts
- [x] Links ideas to subsequent specs/design sessions

**Implements**: `/s2s:brainstorm`

---

### REQ-023: Plan workflow

**Status**: implemented | **Priority**: must

**Description**: The system must generate implementation plans from requirements and architecture.

**Acceptance criteria**:
- [x] Reads BACKLOG, requirements.md, architecture.md
- [x] Generates structured plan in plans/ folder
- [x] Smart source detection (ID lookup, search)
- [x] Warns if planning from unvalidated IDEA

**Implements**: `/s2s:plan`

---

## 4. Artifact traceability

### REQ-030: Artifact flow

**Status**: implemented | **Priority**: must

**Description**: The system must maintain traceability between artifacts across the workflow.

**Acceptance criteria**:
- [x] ideas.md → BACKLOG.md (promote)
- [x] BACKLOG.md → requirements.md (specs)
- [x] requirements.md → architecture.md (design)
- [x] All artifacts → plans/ (plan)
- [x] Bidirectional references

**Specification**: FLOW-001 in former BACKLOG

---

### REQ-031: Artifact state model

**Status**: implemented | **Priority**: must

**Description**: Artifacts must have a single state field for deterministic lifecycle tracking.

**Acceptance criteria**:
- [x] Single `state` field (not status + agreement)
- [x] Universal states: draft, needs_discussion, in_progress, blocked, deferred, rejected
- [x] Terminal states by type (approved, accepted, promoted, resolved)
- [x] Deterministic transitions

**ADR**: decisions/0010-artifact-state-model.md

---

## 5. Configuration and templates

### REQ-040: Configuration cascade

**Status**: implemented | **Priority**: must

**Description**: Configuration must flow from config.yaml through snapshots to subagent prompts.

**Acceptance criteria**:
- [x] config.yaml is single source of truth for defaults
- [x] Command arguments override config values
- [x] config-snapshot.yaml passed to subagents
- [x] No hardcoded defaults in commands

**ADR**: Related to DEBT-001 resolution

---

### REQ-041: Template-based generation

**Status**: implemented | **Priority**: should

**Description**: File generation should use templates as source of truth.

**Acceptance criteria**:
- [x] Templates in `templates/` folder
- [x] Commands read and populate templates
- [x] `${CLAUDE_PLUGIN_ROOT}` expansion works
- [x] Placeholder substitution supported

**Specification**: TEMPL-001 in former BACKLOG

---

## 6. Workspace scope (advanced)

### REQ-050: Roundtable scope awareness

**Status**: implemented | **Priority**: should

**Description**: Roundtables must be aware of workspace vs component scope.

**Acceptance criteria**:
- [x] Facilitator aggregates workspace + component contexts
- [x] Topics outside scope trigger suggestions
- [x] Workspace roundtable considers all components

**Specification**: WORK-002 in former BACKLOG

---

### REQ-051: Decision propagation

**Status**: draft | **Priority**: could

**Description**: Workspace-level decisions should propagate to affected components as backlog items.

**Acceptance criteria**:
- [ ] ADR template includes `affects: [components]` field
- [ ] Session close suggests creating component backlog items
- [ ] workspace.yaml tracks propagation status

**Specification**: WORK-003 in former BACKLOG

---

### REQ-052: Dependency graph

**Status**: draft | **Priority**: could

**Description**: The system should auto-detect and maintain component dependencies.

**Acceptance criteria**:
- [ ] Scan imports during init to detect dependencies
- [ ] Update workspace.yaml with depends_on
- [ ] Plan command considers dependency order

**Specification**: WORK-004 in former BACKLOG

---

## Non-functional requirements

### NFR-001: No external dependencies

**Status**: implemented | **Priority**: must

**Category**: Maintainability

**Description**: The plugin must work with pure markdown/yaml, no external runtime dependencies.

**Measurement**: No npm/pip/cargo dependencies required.

---

### NFR-002: Progressive disclosure

**Status**: implemented | **Priority**: should

**Category**: Usability

**Description**: Skills should use progressive disclosure - core content in SKILL.md (< 2000 words), details in references/.

**Measurement**: SKILL.md word count, INST-010 check.

---

### NFR-003: Context efficiency

**Status**: implemented | **Priority**: should

**Category**: Performance

**Description**: The system should minimize context window usage through smart loading and caching.

**Measurement**: Token usage per session.

---

### NFR-004: Resume capability

**Status**: implemented | **Priority**: must

**Category**: Reliability

**Description**: Sessions must be resumable from any interruption point.

**Measurement**: RES-* checks pass.

---

## Business rules

### BR-001: Agent invocation pattern

**Status**: implemented

**Description**: Agents must be invoked using `**Use the {name} agent**` pattern, not generic Task prompts.

**Rationale**: Ensures agent configuration (model, tools) is applied correctly.

**ADR**: decisions/0002-inline-orchestration.md

---

### BR-002: Subagent spawning prohibition

**Status**: implemented

**Description**: Agents cannot spawn other subagents. Orchestration must happen in commands.

**Rationale**: Claude Code architecture constraint - Task tool only available to main agent.

**Check**: INST-008

---

### BR-003: Session file as single source of truth

**Status**: implemented

**Description**: All session state must be in the session YAML file. No separate state files.

**Rationale**: Simplifies recovery, debugging, and validation.

**ADR**: decisions/0006-session-embedded-artifacts.md

---

## Open questions

- **OQ-001**: Release strategy and versioning approach
- **OQ-002**: Marketplace distribution timeline
