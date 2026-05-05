# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-05-05

### Added
- **TECH-009 Token tracking with progressive precision**: T1/T2/T3 checkpoints per round, measured-then-estimated precision pipeline (token-tracker.sh up to v5.3.0)
- **TECH-007 Unified project state**: `.s2s/state.json` as single source of truth for active session and plan; fast-path session resume across all roundtable commands
- **TECH-004 Token tracker v2.x→v5.x**: session isolation, statusline integration, auto-setup, Windows support, `CONTEXT_SOURCE` visibility
- **Context-reset hook**: `SessionStart` hook captures `/clear` and `/compact` events into `state.json`; graceful jq-optional degradation
- **Context capacity check**: Step 2.0 in all roundtable commands stops sessions before context overflow (95% threshold)
- **`/s2s:dev:check` command**: development validation runner (ENV-*, INST-*, CONS-* checks) via `dev-validator` agent
- **`/s2s:dev:test` command**: integration test runner (VAL-RT-*, RES-*, EDGE-*) on real or synthetic sessions
- **`dev-validator` agent**: scalable check execution architecture
- **`dev-testing` skill**: comprehensive test reference suite (check-registry, inst-checks, cons-checks, res-checks, edge-scenarios, roundtable-tests)
- **`output-generation` skill**: extracted output rendering from commands (TECH-002 Phase 1); references for SRS, arc42, brainstorm formats
- **`round-validation` reference**: shared per-round validation logic across specs/design/brainstorm (TECH-002 Phase 2)
- **`--diagnostic` flag** for roundtable commands: progressive disclosure mode invoking `session-observer` agent
- **`--tokens` flag** for roundtable command (later made always-active)
- **ADR-0010**: single state field model for artifacts
- **ADR-0011**: roundtable command unification rationale
- **ADR-0012**: output-generation skill rationale
- **`.s2s/architecture.md`, `.s2s/requirements.md`, structured `.s2s/ideas.md`**
- **Plans**: `context-restructure`, `session-resilience-verification`, `test-validation-architecture`
- **`.claude/s2s-development.md`**: contributor patterns guide (Feature Activation Pattern, Optional Feature Hooks, `CLAUDE_PLUGIN_ROOT` references, skill reference triggers)
- **Test baselines**: `.s2s/test-baselines/` directory for TECH-002 regression captures

### Changed
- **Token tracking always-active** (v2.3.0): no longer behind a flag, integrated by default
- **State.json fast-path** in all 4 roundtable commands' auto-detect
- **`.s2s` structure reorganized** with proper artifact separation
- **Validation simplified** (ADR-0008): consolidated into per-round shared reference
- **Diagnostic moved** from command to skill (progressive disclosure pattern)
- **`CLAUDE_PLUGIN_ROOT`** used for skill references in agents and commands (portability)
- **Token tracker hooks** moved from command to skill
- **Resume reads `round_number`** from session file (no longer hardcoded 0)
- **Token estimate formula** changed from `T3-T1` to `T3-T0` (more accurate)
- **Token tracking instructions** made explicit and mandatory (Feature Activation Pattern)
- **Statusline** renamed to `statusline.sh`, reads global config dynamically
- **Single state field model** (ADR-0010) applied across artifact handling

### Fixed
- **BUG-003**: `participant_context` propagation via inline content instead of `context_files` reference
- **BUG-006**: token tracker now detects `/compact` events
- Token tracker portability: `sed` instead of `BASH_REMATCH`
- JSONL path encoding: leading dash preserved
- Float arithmetic in `statusline.sh`
- Removed counterproductive 60s staleness check
- Step 2.0 alignment for token tracking across commands
- ADR-0008 reference correction
- Artifact `state` field correction (was `status`)
- Missing `tokens` section in session template
- Token field naming alignment across schemas
- Path resolution in agent skill references
- Resume: state.json and display alignment from session file
- `CLAUDE_PLUGIN_ROOT` resolution at hook startup
- Roundtable token tracking: Phase 3 step numbers and order alignment
- Automatic continuation enforcement to prevent mid-session stops

### Removed
- `.s2s/specs/WORK-001-workspace-specification.md` (superseded by `.s2s` reorganization)

### Notes
- **TECH-002 (roundtable command unification) remains in_progress**: phases 0, 1, 2, 5, 6, 6b complete; phases 3, 7, 4, 8 pending. Commands are temporarily +163 lines vs v0.3.0 due to inline token + state code added in Phase 6/6b; the line reduction promised by TECH-002 will land when Phase 8 (thin launchers) is delivered in a future release.

## [0.3.0] - 2026-01-18

### Added
- **s2s-guide skill**: Comprehensive usage and extension guide, activated by questions like "what is s2s", "how to extend s2s"
- **Workspace structure detection**: Init command now detects existing project structure and adapts accordingly
- **BACKLOG.md template**: Automatic backlog creation during init for tracking project work
- **Workspace scope awareness**: Roundtable participants now receive project context via `@.s2s/CONTEXT.md` references
- **Template-based generation**: Plans and init files now use templates with placeholder substitution
- **Backlog management skill**: Track development artifacts in `.s2s/BACKLOG.md`
- `--plugin-dir` development workflow documented in CONTRIBUTING.md (hot reload support)
- GitHub alerts and execution tips in documentation

### Changed
- **Output consolidation**: All artifacts now under `.s2s/` directory (requirements.md, architecture.md, plans/, sessions/)
- **Session architecture**: Simplified to ARCH-001 with embedded artifacts in single YAML file
- **Config handling**: Removed hardcoded defaults from workflow commands; config.yaml is single source of truth
- **Strategy selection**: Workflow-specific fallbacks instead of global default
- **Validation system**: Unified session validation with script-first approach
- **Requirement IDs**: Standardized from FR-* to REQ-* pattern
- **Documentation**: Comprehensive README rewrite with positioning, comparison table, and visual improvements
- **CONTRIBUTING.md**: Added `--plugin-dir` as recommended dev workflow with hot reload

### Fixed
- Missing ux-researcher and security-champion in default participants
- Broken links in templates, examples, and documentation
- ASCII diagram alignment in README
- Session schema alignment with ARCH-001 structure
- Plan states now correctly use active|closed only

### Removed
- Hardcoded defaults from workflow commands (now read from config.yaml)
- Redundant documentation (consolidated into s2s-guide skill)
- `.claude/decisions/` folder (decisions now in `.s2s/decisions/` local to user projects)

## [0.2.0] - 2026-01-10

### Added
- Complete roundtable system with 12 specialized agents
- 5 facilitation strategies: standard, disney, debate, consensus-driven, six-hats
- Session management commands: list, status, validate, cleanup
- Verbose and diagnostic modes for debugging
- Critical Stance and Context Check for anti-sycophancy
- Plan management: list, close (unified create/start into plan command)

### Changed
- Session architecture: embedded artifacts in single YAML file
- Agent model tiers: opus (critical), inherit (default), haiku (fast)

## [0.1.0] - 2024-12-28

### Added
- Initial release
- Core workflows: init, specs, design, brainstorm, plan
- Basic roundtable implementation
- Arc42, ISO 25010, MADR skills
- Project templates

[Unreleased]: https://github.com/spec2ship/spec2ship/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/spec2ship/spec2ship/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/spec2ship/spec2ship/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/spec2ship/spec2ship/releases/tag/v0.1.0
