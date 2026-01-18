# Spec2Ship Development Backlog

**Updated**: 2026-01-17T18:30:00Z
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
| WORK | Workspace support | WORK-001 |
| BACK | Backlog management | BACK-001 |
| TEMPL | Templates | TEMPL-001 |

**Status values**: `draft` | `planned` | `in_progress` | `blocked` | `completed` | `rejected` | `merged`

---

## High Priority

### WORK-001: Workspace Support - Core Structure

**Status**: completed | **Created**: 2026-01-16 | **Completed**: 2026-01-17 | **Priority**: High

**Context**: S2S supports both standalone projects and multi-component workspaces (monorepo or multi-repo).

**Specification**: `.s2s/specs/WORK-001-workspace-specification.md` (complete functional spec)

**Terminology** (decided 2026-01-17):
- **Workspace**: Configuration that coordinates multiple projects
- **Component**: A project that is part of a workspace
- **Standalone**: A single project not part of any workspace

**Git Structure Support**:
- **Monorepo**: All components in one git repo
- **Multi-repo**: Components in separate git repos
- **Hybrid**: Mix of both

**Reference Patterns** (decided 2026-01-17):
- **Internal** (in .s2s/): Relative paths with `@` → `@../backend/.s2s/CONTEXT.md`
- **External** (in docs/): Absolute URLs → `[Backend](https://github.com/org/backend/docs/)`

**Implementation Phases**:

| Phase | ID | Description | Status |
|-------|-----|-------------|--------|
| 1 | WORK-001 | Core structure (workspace.yaml, init) | completed |
| 2 | WORK-002 | Roundtable scope (facilitator awareness) | completed |
| 3 | WORK-003 | Decision propagation (workspace→components) | planned |
| 4 | WORK-004 | Dependency graph (auto-detect, affected) | planned |

**Phase 1 Tasks**:
1. ✅ Enhance project-detector to detect workspace structure
2. ✅ Add workspace detection questions to init Phase 3
3. ✅ Generate appropriate config based on detected/selected mode
4. ✅ Warn if .s2s created in non-git folder
5. ✅ Create workspace.yaml template (TEMPL-002a)
6. ✅ Init creates workspace.yaml when --workspace or detected
7. ✅ Init links new component to existing workspace
8. ✅ Component config.yaml includes workspace reference (TEMPL-002c)

**Acceptance Criteria** (Phase 1):
- [x] Detect workspace vs standalone during init
- [x] Support monorepo/multi-repo/hybrid structures
- [x] Warn if .s2s created in non-git folder
- [x] workspace.yaml created with component registry
- [x] Components auto-linked when init run in subfolder
- [x] Reference patterns documented and working

**Related**: TEMPL-002, WORK-002, WORK-003, WORK-004

---

### WORK-002: Roundtable Scope Awareness

**Status**: completed | **Created**: 2026-01-17 | **Completed**: 2026-01-17 | **Depends on**: WORK-001

**Context**: Facilitator must understand workspace vs component scope and guide discussions appropriately.

**Specification**: `.s2s/specs/WORK-001-workspace-specification.md` Section 6

**Tasks**:
1. ✅ Facilitator reads project type from config-snapshot.yaml
2. ✅ For workspace-level: aggregate context from all components
3. ✅ For component-level: include workspace context as background
4. ✅ Validate topic appropriateness for scope
5. ✅ Suggest correct scope if topic mismatch detected

**Implementation**:
- Updated `roundtable-execution/SKILL.md` with Steps 1.3b, 1.3c, 1.4 for workspace scope
- Updated `facilitator.md` with project_scope, workspace_scope, cross_cutting_decisions inputs
- Updated specs.md, design.md, brainstorm.md to pass workspace context to facilitator
- **Simplified (post-review)**: Component CONTEXT.md includes @ reference to workspace context
  - No runtime aggregation needed - @ references resolved automatically
  - templates/project/CONTEXT.md has conditional "Workspace Context" section
  - init.md populates for component mode, removes for standalone

**Acceptance Criteria**:
- [x] Facilitator aggregates workspace + component contexts when appropriate
- [x] Topics outside scope trigger suggestion to run elsewhere
- [x] Workspace roundtable considers all components

---

### WORK-003: Decision Propagation

**Status**: planned | **Created**: 2026-01-17 | **Depends on**: WORK-001

**Context**: Workspace-level decisions must propagate to affected components as backlog items.

**Specification**: `.s2s/specs/WORK-001-workspace-specification.md` Section 5

**Tasks**:
1. [ ] ADR template includes `affects: [components]` field
2. [ ] Session close suggests creating backlog items in affected components
3. [ ] Backlog items include reference to originating workspace decision
4. [ ] workspace.yaml `cross_cutting` section tracks propagation status

**Acceptance Criteria**:
- [ ] Decisions with `affects` field trigger propagation prompt
- [ ] Component backlog items reference workspace ADR
- [ ] Propagation status tracked in workspace.yaml

---

### WORK-004: Dependency Graph

**Status**: planned | **Created**: 2026-01-17 | **Depends on**: WORK-001

**Context**: Auto-detect and maintain dependency relationships between components.

**Specification**: `.s2s/specs/WORK-001-workspace-specification.md` Section 4.3

**Tasks**:
1. [ ] Scan imports/requires during init to detect dependencies
2. [ ] Update workspace.yaml `depends_on` field for each component
3. [ ] `/s2s:init --update-deps` command to refresh dependencies
4. [ ] Consider dependencies when generating plans (affected analysis)

**Acceptance Criteria**:
- [ ] Dependencies auto-detected during component init
- [ ] Manual refresh command available
- [ ] Plan command considers dependency order

---

### TEMPL-001: Template Usage vs Command Inline

**Status**: completed | **Created**: 2026-01-16 | **Completed**: 2026-01-17 | **Priority**: High

**Context**: Templates exist in `templates/` but commands generate files inline with duplicated content. This creates potential inconsistencies.

**Investigation Results** (2026-01-17):

Test conducted with temporary command `test-template-copy.md`:

| Mechanism | Result |
|-----------|--------|
| `${CLAUDE_PLUGIN_ROOT}` expansion | ✅ Works - expands to plugin install path |
| Read template from plugin | ✅ Works - full path accessible |
| Placeholder substitution | ✅ Works - standard string replacement |
| Write to target location | ✅ Works - files created correctly |

**Decision**: **Templates = Source of Truth**

Commands (e.g., `init.md`) should:
1. Read templates from `${CLAUDE_PLUGIN_ROOT}/templates/`
2. Replace placeholders with actual values
3. Write populated content to target location

This approach:
- Eliminates content duplication between templates and commands
- Single place to maintain file structure/content
- Commands focus on logic, templates focus on content

**Next Steps**:
- Refactor `init.md` to use template copy approach (INIT-003)
- Align `plan.md` command with `templates/plan.md`

**Acceptance Criteria**:
- [x] Decision on template usage model
- [x] Align templates with command output OR vice versa (INIT-003 - completed 2026-01-17)
- [x] Document chosen approach in s2s-development.md (completed 2026-01-17)

---

### PLAN-001: Plan Generation Enhancement

**Status**: draft | **Created**: 2026-01-16 | **Updated**: 2026-01-17

**Context**: The `/s2s:plan` command may not fully leverage previous S2S phases (specs, design, decisions).

**Current Behavior**:
- plan.md searches for requirements.md and architecture.md
- Uses general-purpose agent to generate plan
- ~~Template has different structure than generated output~~ (fixed by PLAN-002)

**Proposed Enhancements**:
1. **Better context integration**:
   - Read decisions from `.s2s/decisions/` (ADRs influence implementation)
   - Reference session artifacts from specs/design phases
   - Include linked session context if available (LINK-001)

2. ~~**Template alignment**~~: ✅ Done in PLAN-002
   - ~~Ensure `templates/plan.md` matches command output~~
   - ~~Include "Acceptance Criteria" and "Integration Notes" in template~~
   - ~~Remove "Design Notes" if not generated by command~~

3. **Agent improvement**:
   - Consider specialized plan-generator agent instead of general-purpose
   - Include testing approach based on project tech stack
   - Consider existing plans when generating new ones (avoid duplication)

**Acceptance Criteria**:
- [ ] Plan considers decisions/ content
- [x] Template matches generated output (PLAN-002)
- [ ] Previous phases inform plan tasks

---

### TEMPL-002: Workspace Template Cleanup

**Status**: completed | **Created**: 2026-01-16 | **Completed**: 2026-01-17 | **Unblocked by**: WORK-001 spec

**Context**: Workspace templates need to align with WORK-001 specification.

**Specification Reference**: `.s2s/specs/WORK-001-workspace-specification.md`

**Tasks**:
1. ✅ Create `templates/workspace/workspace.yaml` per Section 3.1 of spec
2. ✅ Update `templates/workspace/CONTEXT.md` - remove non-existent command refs
3. N/A Create `templates/workspace/BACKLOG.md` - uses same template as project
4. ✅ Update `templates/project/config.yaml` to support `type: "component"` and `workspace:` section

**Files Changed**:
- `templates/workspace/workspace.yaml` - rewritten per spec (components[], cross_cutting[], roundtable_scope)
- `templates/workspace/CONTEXT.md` - simplified, valid commands only
- `templates/project/config.yaml` - added workspace reference section

**Acceptance Criteria**:
- [x] All referenced commands exist OR are removed from templates
- [x] workspace.yaml template matches init output
- [x] CONTEXT.md references only existing files/commands

---

### DEBT-001: Config Values Hardcoded in Commands

**Status**: completed | **Created**: 2026-01-15 | **Completed**: 2026-01-16

**Context**: Config values were hardcoded with inline defaults in commands:
- `{from config: X, default: 3}` repeated across files
- Potential for inconsistency if defaults changed

**Solution Implemented**:
- Removed inline ", default: X" from config-snapshot.yaml generation
- Changed `(default: 3)` to `(from config)` in enforcement sections
- Config.yaml (from init) is now single source of truth for defaults

**Files Modified**: specs.md, design.md, brainstorm.md, roundtable.md

**Acceptance Criteria**:
- [x] Values read from config.yaml (no inline defaults)
- [x] Defaults only in config template (init.md)
- [x] config-snapshot.yaml passes actual values

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

### EXT-003: Spec2Ship Guide Skill (s2s-guide)

**Status**: completed | **Created**: 2026-01-17 | **Completed**: 2026-01-17 | **Priority**: Medium

**Context**: Development guidelines were scattered in `.claude/guidelines/` (~6,800 words). Users needed a single entry point for both usage questions and extension guidance.

**Solution**: Created `skills/s2s-guide/` with progressive disclosure - a comprehensive guide for both **users** and **contributors**.

```
skills/s2s-guide/
├── SKILL.md              # Core guide (~700 words)
├── references/
│   ├── workflows.md      # Detailed workflow explanations
│   ├── commands.md       # Complete command reference
│   ├── glossary.md       # Terminology and artifact types
│   ├── extension-patterns.md  # LLM patterns for writing commands
│   ├── naming-conventions.md  # ID formats and naming rules
│   ├── state-machine.md  # State transitions
│   └── workspace.md      # Workspace architecture
└── examples/
    ├── new-agent.md      # Step-by-step guide
    ├── new-skill.md      # Step-by-step guide
    └── new-command.md    # Step-by-step guide
```

**Trigger Phrases** (in SKILL.md description):
- "what is s2s", "how do I use specs"
- "which command for requirements", "difference between specs and design"
- "how to create custom agent", "extend s2s", "add new command"
- "workspace vs standalone", "what are roundtables"
- "come funziona s2s", "quale comando uso", "come estendo il plugin"

**Key Features**:
- Single entry point for all s2s questions
- Progressive disclosure (SKILL.md ~700 words, details on demand)
- Covers usage AND extension
- Bilingual trigger phrases (EN/IT)
- Step-by-step examples for command/agent/skill creation

**Completed Cleanup**:
- [x] Removed confusing `@` notation from CLAUDE.md table
- [x] Deleted `.claude/guidelines/` (content consolidated in skill)
- [ ] Simplify `docs/` structure (in progress)

**Related**: EXT-001 (project agents), EXT-002 (custom participants)

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
| EXT-003 | Spec2Ship Guide Skill (s2s-guide) | 2026-01-17 | Comprehensive guide for usage and extension |
| WORK-002 | Roundtable Scope Awareness | 2026-01-17 | Facilitator workspace/component context, topic validation |
| WORK-001 | Workspace Support - Core Structure (Phase 1) | 2026-01-17 | workspace.yaml, init scenarios A-F, component linking |
| TEMPL-002 | Workspace Template Cleanup | 2026-01-17 | Aligned with WORK-001 spec |
| PLAN-002 | Refactor plan.md to use template copy | 2026-01-17 | Follows TEMPL-001 decision, merged template sections |
| INIT-003 | Refactor init.md to use template copy | 2026-01-17 | Follows TEMPL-001 decision |
| TEMPL-001 | Template usage model decision | 2026-01-17 | Templates = Source of Truth, ${CLAUDE_PLUGIN_ROOT} works |
| DEBT-001 | Config values hardcoded in commands | 2026-01-16 | Removed inline defaults |
| CLEAN-001 | Remove ARCH-001 residual files | 2026-01-16 | Already done, verified |
| BACK-001 | Backlog file creation in init | 2026-01-16 | Template + CONTEXT.md updated |
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
