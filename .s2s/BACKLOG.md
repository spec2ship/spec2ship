# Spec2Ship Development Backlog

**Updated**: 2026-01-15T22:00:00Z
**Format**: Single markdown file for LLM consumption

---

## ID Conventions

| Prefix | Category | Example |
|--------|----------|---------|
| ARCH | Architecture decisions | ARCH-001 |
| PATH | Path/structure changes | PATH-001 |
| EXT | Extensions/customization | EXT-001 |
| QUAL | Quality/validation | QUAL-001 |
| TEST | Testing | TEST-001 |
| INIT | Initialization | INIT-001 |
| SESS | Session management | SESS-001 |
| RT | Roundtable features | RT-001 |
| CTX | Context optimization | CTX-001 |
| OUT | Output/export | OUT-001 |
| DEBT | Technical debt | DEBT-001 |
| MISC | Miscellaneous | MISC-001 |

**Status values**: `draft` | `planned` | `in_progress` | `blocked` | `completed` | `rejected` | `merged`

---

## High Priority

### DEBT-001: Config Values Hardcoded in Commands

**Status**: planned | **Created**: 2026-01-15

**Context**: Config values are hardcoded in commands instead of being read from config.yaml:
- `min_rounds: 3` repeated 12+ times
- `max_rounds: 20` hardcoded
- `confidence_below: 0.5` hardcoded

**Solution**: Read from config.yaml and pass via config-snapshot.yaml.

**Files**: specs.md, design.md, brainstorm.md, roundtable.md

**Acceptance Criteria**:
- [ ] Values read from config.yaml
- [ ] Defaults only in config template
- [ ] config-snapshot.yaml passes actual values

---

### CLEAN-001: Remove ARCH-001 Residual Files

**Status**: planned | **Created**: 2026-01-15

**Context**: ARCH-001 refactoring left residual files that should be deleted:
- `.s2s/state.yaml` - no longer used
- `.s2s/specs/sessions/` - old structure, replaced by `.s2s/sessions/`

**Acceptance Criteria**:
- [ ] state.yaml deleted
- [ ] Old session folders removed or migrated
- [ ] No references to old paths

---

### EXT-001: Custom Agents in Project .claude/

**Status**: draft | **Created**: 2026-01-11

**Context**: Projects may want specialized agents (e.g., project-specific code reviewer). These should be in `.claude/agents/` of the project, not in the plugin.

**Proposal**:
1. Roundtable commands scan `.claude/agents/` in project
2. Project agents available alongside plugin agents (named `project:{agent-name}`)
3. Agent creation command `/s2s:agent:create {name}`

**Acceptance Criteria**:
- [ ] Project agents discoverable by roundtable
- [ ] Agent creation wizard works
- [ ] Clear distinction between project and plugin agents

---

### QUAL-001: Code Review Agent for S2S Development

**Status**: draft | **Created**: 2026-01-11

**Context**: S2S development requires consistent adherence to patterns. Create `.claude/agents/s2s-code-reviewer.md` that verifies:
- Artifact types and states
- Agent invocation patterns
- Cross-component consistency

**Acceptance Criteria**:
- [ ] Code reviewer agent exists in .claude/
- [ ] All checklist items verified
- [ ] Not shipped with plugin

---

### QUAL-002: Validate Default to Full

**Status**: draft | **Created**: 2026-01-11

**Context**: `/s2s:session:validate` has different levels but default should run ALL checks.

**Proposal**:
1. Default runs all checks (structural + deep + strategy)
2. Add `--skip` flags for excluding specific checks

**Acceptance Criteria**:
- [ ] Default runs all checks
- [ ] Skip flags work

---

### TEST-001: Test Framework with s2s:test

**Status**: draft | **Created**: 2026-01-11

**Context**: Testing s2s commands is manual and cumbersome.

**Proposal**:
1. `/s2s:test specs|design|roundtable` subcommands
2. Creates test environment (temp dir, test CONTEXT.md, config)
3. Automatically adds `--diagnostic --verbose`

**Acceptance Criteria**:
- [ ] s2s:test command with subcommands
- [ ] Automatic test environment setup
- [ ] Test files not shipped with plugin

---

### INIT-001: Optional Structure Creation

**Status**: draft | **Created**: 2026-01-11 | **Updated**: 2026-01-15

**Context**: `/s2s:init` creates `.s2s/` structure. Users may want minimal setup.

**Note**: As of PATH-001, init no longer creates `docs/` - all output goes to `.s2s/`.

**Proposal**:
1. Add `--minimal` flag to create only config.yaml and CONTEXT.md
2. Interactive prompt when no flag provided
3. Detect existing `.s2s/` structure

**Acceptance Criteria**:
- [ ] `--minimal` flag works
- [ ] CONTEXT.md and config always created
- [ ] Existing .s2s/ structure detected

---

## Medium Priority

### RT-001: Phase Tracking for Multi-Phase Strategies

**Status**: draft | **Created**: 2026-01-11

**Context**: Strategies like Disney and Six Hats have phases. Currently phase tracking is not implemented in session file.

**Proposal**:
- Add `current_phase` field to session file
- Phase transitions in facilitator
- Validation in session-observer

**Phases by workflow**:
- **Specs**: Discovery → Definition → Refinement
- **Design**: Architecture → Components → Integration
- **Brainstorm**: Dreamer → Realist → Critic (existing)

**Acceptance Criteria**:
- [ ] Phases defined for specs and design
- [ ] Session schema supports phases
- [ ] `/compact` suggested at phase boundaries

---

### LINK-001: Optional Session Linking

**Status**: draft | **Created**: 2026-01-15

**Context**: Allow linking related sessions (e.g., specs → design → plan).

**Proposal**:
- `linked_sessions` optional field in session file
- Command to visualize session chain
- Context passing between linked sessions

**Acceptance Criteria**:
- [ ] linked_sessions schema defined
- [ ] Visualization command
- [ ] Context inheritance optional

---

### CTX-001: Simulate Mode

**Status**: draft | **Created**: 2026-01-11

**Context**: Context window limits are a fundamental constraint.

**Proposal**: `--simulate` mode where command impersonates participants WITHOUT spawning agents:
1. Read participant .md files
2. Generate responses inline as each role
3. No Task() invocations
4. Output marked as "SIMULATED"

**Acceptance Criteria**:
- [ ] `--simulate` flag in specs, design, brainstorm
- [ ] Token reduction measured (target: 70%+)

---

### SESS-002: Enhanced Interactive Mode

**Status**: draft | **Created**: 2026-01-11

**Context**: Users want to intervene during roundtables.

**Proposal**:
1. More frequent checkpoints in `--interactive`
2. After facilitator question: "Provide input or continue?"
3. User input passed to facilitator in next prompt

**Acceptance Criteria**:
- [ ] Enhanced checkpoints in --interactive
- [ ] User can provide input at checkpoints

---

### INIT-002: Intelligent Project Assessment

**Status**: draft | **Created**: 2026-01-11 | **Updated**: 2026-01-15

**Context**: Commands don't assess project state before starting.

**Proposal**:
1. Analyze project state using dual-path search (PATH-001):
   - First check `docs/` (exported/public documentation)
   - Then check `.s2s/` (internal working files)
2. Detect: CONTEXT.md, requirements.md, architecture.md, decisions/, git status
3. Suggest next step: "No requirements? Run /s2s:specs"

**Acceptance Criteria**:
- [ ] Project state analysis runs before workflow commands
- [ ] Clear suggestions based on detected state
- [ ] Dual-path search for documentation (docs/ → .s2s/)

---

### RT-002: Reduce Code Duplication in Workflow Commands

**Status**: draft | **Created**: 2026-01-11 | **Updated**: 2026-01-15

**Context**: specs.md, design.md, brainstorm.md have ~60% code duplication.

**Proposal**:
1. Extract common roundtable logic to shared skill
2. Workflow commands configure and invoke common logic

**Acceptance Criteria**:
- [ ] Code duplication reduced
- [ ] Shared logic in roundtable-execution skill

---

## Low Priority

### RT-003: Ready-to-Use Roundtable Templates

Pre-configured templates for common decisions (tech stack, API design, security review).

---

### RT-004: Context-Aware Roundtable Splitting

Suggest splitting large roundtables based on context size estimation.

---

### SESS-003: Product Owner Observer Agent

Silent observer that tracks discussion and speaks only when user intervenes.

---

### SESS-004: Workflow Configuration Wizard

Interactive wizard to configure roundtable options for new users.

---

### EXT-002: Custom Participants Skill

Skill for creating new participant types with templates.

---

### OUT-001: Parallel Transcriber Agent

Real-time structured output (JSON) for potential GUI consumption.

---

### OUT-002: Export Commands (Superseded by OUT-003)

**Status**: rejected | **Reason**: Consolidated into OUT-003

Original proposal was `/s2s:specs:export` and `/s2s:design:export` as subcommands.
New approach: Single `/s2s:export` command that handles all artifact types.

---

### OUT-003: Unified Export Command

**Status**: planned | **Created**: 2026-01-15 | **Priority**: High

**Context**: With PATH-001, all S2S output now goes to `.s2s/`. Need a way to export/publish artifacts to project `docs/` folder for public documentation.

**Proposal**: Single `/s2s:export` command:

```bash
# Export all artifacts
/s2s:export

# Export specific types
/s2s:export --specs          # .s2s/requirements.md → docs/specifications/
/s2s:export --design         # .s2s/architecture.md → docs/architecture/
/s2s:export --decisions      # .s2s/decisions/ → docs/decisions/

# Export with format conversion
/s2s:export --specs --format ieee830
/s2s:export --design --format arc42

# First-time export asks for target path confirmation
```

**Behavior**:
1. First export of each type asks user to confirm destination path
2. Subsequent exports use confirmed path (stored in config)
3. Warns if target file exists, asks to overwrite or merge
4. Adds header comment: `<!-- Exported by S2S from .s2s/requirements.md -->`

**Acceptance Criteria**:
- [ ] `/s2s:export` command created
- [ ] Supports --specs, --design, --decisions flags
- [ ] First-time path confirmation
- [ ] Overwrite/merge prompt for existing files
- [ ] Format conversion optional (ieee830, arc42)

**Design Considerations** (2026-01-16):
- **No `docs:` in config for now** - output paths will be determined at export time, not init time
- **Project may have existing structure** - don't assume `docs/` exists or is the right place
- **Possible approaches**:
  1. First export asks for target path, stores in config for subsequent exports
  2. Use documentation-specialist agent in 1-on-1 or roundtable to analyze project structure and propose organization
  3. Detect existing doc structure (`docs/`, `documentation/`, `wiki/`, etc.) and adapt
- **Config section `docs:` will be added by export command** when user confirms paths, not by init

---

### MISC-002: Rules Folder Best Practices

Research best practices for `.claude/rules/` vs `CLAUDE.md`.

---

### MISC-003: File Size Verification

Audit for large files that waste tokens.

---

## Ideas / Notes

_Unstructured ideas and observations for future consideration._

- Backlog management as optional plugin feature?
- Integration with GitHub Issues?
- Session templates for common scenarios

---

## Completed

| ID | Description | Completed | Notes |
|----|-------------|-----------|-------|
| PATH-001 | Consolidate output to .s2s with dual-path reading | 2026-01-15 | Commit 036e6e7 |
| ARCH-001 | Session management simplification | 2026-01-15 | 7 commits, ADR-0007 |
| OSS-001 | OSS compliance and documentation | 2026-01-14 | - |
| SESS-001 | Intelligent auto-resume | 2026-01-15 | Merged into ARCH-001 |

---

## Rejected

| ID | Description | Reason |
|----|-------------|--------|
| OUT-002 | Subcommand exports (specs:export, design:export) | Superseded by OUT-003 unified export |
| MISC-001 | Release v0.2.5 | Doc-only changes don't require version tags |
