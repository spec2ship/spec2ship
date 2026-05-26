# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - YYYY-MM-DD

### Highlights

**TECH-002 Roundtable command unification complete**. The four roundtable commands (`specs`, `design`, `brainstorm`, `roundtable`) now share a single execution engine via `commands/roundtable.md` (master) plus profile-driven workflow shapes. Command-layer line count: 5301 (v0.3.0) to 956 (this release).

| File | v0.3.0 | v0.4.0 |
|------|--------|--------|
| `commands/specs.md` | 1717 | 172 |
| `commands/design.md` | 1607 | 114 |
| `commands/brainstorm.md` | 1575 | 78 |
| `commands/roundtable.md` | 402 | 592 (master) |
| Total | 5301 | 956 |

### Added
- **TECH-002 master command** (`commands/roundtable.md`): single orchestrator for all 4 workflow types. Profile-driven PHASE 0+1 (folder, snapshots, skeleton from profile); uniform PHASE 2 round loop via `phase-2-core.md`; PHASE 3 phase-2-core delegation; PHASE 4 completion with handoff variables (`OUTPUT_MERGE_MODE`, `OUTPUT_FORMAT`, `FOCUS_AREA`). Both native and delegated invocation modes.
- **TECH-002 thin launchers**: `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md` reduced to workflow-specific prep + Read-and-follow handoff to the master (Pattern 1).
- **`profiles/*.yaml`** (4 files in `skills/roundtable-execution/profiles/`): single source of truth for workflow shape. Drives both PHASE 1 setup and PHASE 2 round loop. Includes new `profiles/roundtable.yaml` for native generic mode.
- **`skills/roundtable-execution/references/phase-2-core.md`** (881 lines): canonical executable single-source for the round loop (Phase 7B deep extraction).
- **12 artifact-schemas extracted** under `skills/roundtable-execution/references/artifact-schemas/`.
- **`disney-phase-machine.md`** reference: extracted Disney phase logic.
- **`strategy-hooks.md`** contract: Option A/B/C decision matrix, formal hook resolution.
- **5 strategy reference docs** with uniform `## Strategy hooks` sections (`standard`, `disney`, `debate`, `consensus-driven`, `six-hats`); bidirectional cross-link `disney.md` <-> `disney-phase-machine.md`.
- **`output-generation/references/roundtable-summary.md`**: Phase 3 dispatch for native roundtable mode.
- **D3 hierarchy** codified: `config.yaml` (user-canonical) -> `profiles/*.yaml` (plugin fallback) -> `SKILL.md` (documentation-only).
- **Option B 3-branch dispatch** for strategy hooks: `{skip}`, policy dict, absent for pre-Phase-4 sessions.
- **TECH-009 Token tracking with progressive precision**: T1/T2/T3 checkpoints per round, measured-then-estimated precision pipeline (`token-tracker.sh` up to v5.3.0).
- **TECH-007 Unified project state**: `.s2s/state.json` as single source of truth for active session and plan; fast-path session resume across all roundtable commands.
- **TECH-004 Token tracker v2.x to v5.x**: session isolation, statusline integration, auto-setup, Windows support, `CONTEXT_SOURCE` visibility.
- **Context-reset hook**: `SessionStart` hook captures `/clear` and `/compact` events into `state.json`; graceful jq-optional degradation.
- **Context capacity check**: Step 2.0 in all roundtable commands stops sessions before context overflow (95% threshold).
- **`/s2s:dev:check` command**: development validation runner (ENV-*, INST-*, CONS-* checks) via `dev-validator` agent.
- **`/s2s:dev:test` command**: integration test runner (VAL-RT-*, RES-*, EDGE-*) on real or synthetic sessions.
- **`dev-validator` agent**: scalable check execution architecture.
- **`dev-testing` skill**: comprehensive test reference suite (check-registry, inst-checks, cons-checks, res-checks, edge-scenarios, roundtable-tests).
- **`output-generation` skill** (TECH-002 Phase 1): extracted output rendering from commands; references for SRS, arc42, brainstorm formats.
- **`round-validation` reference** (TECH-002 Phase 2): shared per-round validation logic across specs/design/brainstorm.
- **`--diagnostic` flag** for roundtable commands: progressive disclosure mode invoking `session-observer` agent.
- **`--tokens` flag** for roundtable command (later made always-active).
- **ADR-0010**: single state field model for artifacts.
- **ADR-0011**: roundtable command unification rationale (with Phase 7B and Phase 8 addenda).
- **ADR-0012**: output-generation skill rationale.
- **`.s2s/architecture.md`, `.s2s/requirements.md`, structured `.s2s/ideas.md`**.
- **Plans**: `context-restructure`, `session-resilience-verification`, `test-validation-architecture`, and the full TECH-002 Phase 3/7B/7-lite/4/8 plan + audit set under `.s2s/plans/`.
- **`.claude/s2s-development.md`**: contributor patterns guide (Feature Activation Pattern, Optional Feature Hooks, `CLAUDE_PLUGIN_ROOT` references, skill reference triggers).
- **Test baselines**: `.s2s/test-baselines/` directory for TECH-002 regression captures (exp42/43/44/45 across all 4 workflows).

### Changed
- **Roundtable execution**: workflow shape is now data (`profiles/*.yaml`) rather than duplicated procedural code across 4 commands.
- **Strategy hooks**: formalized contract with `skip` / policy / absent semantics; `Step 2.6d` renamed to `Step 2.10` across 18 sites in 6 files; strategy doc disclaimers point to `profiles/` as the authoritative source.
- **`roundtable-strategies/SKILL.md`** v1.1.0 to v1.2.0: drift fixes D1/D2, "authoritative source: profiles/" disclaimers.
- **`roundtable-execution/SKILL.md`** restructured 1002 to 178 lines (v2.7.0 to v3.0.0) following Phase 7B deep extraction.
- **Token tracking always-active** (v2.3.0): no longer behind a flag, integrated by default.
- **State.json fast-path** in all 4 roundtable commands' auto-detect.
- **`.s2s` structure reorganized** with proper artifact separation.
- **Validation simplified** (ADR-0008): consolidated into per-round shared reference.
- **Diagnostic moved** from command to skill (progressive disclosure pattern).
- **`CLAUDE_PLUGIN_ROOT`** used for skill references in agents and commands (portability).
- **Token tracker hooks** moved from command to skill.
- **Resume reads `round_number`** from session file (no longer hardcoded 0).
- **Token estimate formula** changed from `T3-T1` to `T3-T0` (more accurate).
- **Token tracking instructions** made explicit and mandatory (Feature Activation Pattern).
- **Statusline** renamed to `statusline.sh`, reads global config dynamically.
- **Single state field model** (ADR-0010) applied across artifact handling.

### Fixed
- **BUG-003**: `participant_context` propagation via inline content instead of `context_files` reference.
- **BUG-006**: token tracker now detects `/compact` events.
- **BUG-013** (TECH-002 Phase 7B FIX-S1): session-observer Step 2.6c output now persisted to `rounds/{NNN}-04-session-observer.yaml`.
- **Phase 3 drift elimination** (6 textual fixes across 3 commands): canonical verification schema, missing `conflicts_resolved` counters, missing `rationale`/`concerns`/`suggestions` in brainstorm verbose dump, header normalization, `min_rounds` correctly read from config in specs.
- **Phase 4 finding #4** (session_id timestamp format divergence between direct and master paths): auto-resolved by Phase 8 (no direct path remains).
- Token tracker portability: `sed` instead of `BASH_REMATCH`.
- JSONL path encoding: leading dash preserved.
- Float arithmetic in `statusline.sh`.
- Removed counterproductive 60s staleness check.
- Step 2.0 alignment for token tracking across commands.
- ADR-0008 reference correction.
- Artifact `state` field correction (was `status`).
- Missing `tokens` section in session template.
- Token field naming alignment across schemas.
- Path resolution in agent skill references.
- Resume: state.json and display alignment from session file.
- `CLAUDE_PLUGIN_ROOT` resolution at hook startup.
- Roundtable token tracking: Phase 3 step numbers and order alignment.
- Automatic continuation enforcement to prevent mid-session stops.

### Removed
- `.s2s/specs/WORK-001-workspace-specification.md` (superseded by `.s2s` reorganization).
- ~3300 lines of duplicated round-execution code from `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md` (Phase 7B + Phase 8).

### Pull requests delivered in this release
- PR #12: TECH-002 Phases 0, 1, 5, 6, 6b, 2.
- PR #13: TECH-002 Phase 3 (approach A, drift elimination + canonical reference).
- PR #14: TECH-002 Phase 7B (deep extraction, `phase-2-core.md` rewrite).
- PR #15: TECH-002 Phase 7-lite (strategy doc hardening, Step 2.6d to 2.10 rename).
- PR #16: TECH-002 Phase 4 (master + Option B + D3 + Option epsilon, `profiles/roundtable.yaml`).
- PR #17: TECH-002 Phase 8 (thin launchers + master PHASE 0+1 generalization).

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

[Unreleased]: https://github.com/spec2ship/spec2ship/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/spec2ship/spec2ship/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/spec2ship/spec2ship/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/spec2ship/spec2ship/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/spec2ship/spec2ship/releases/tag/v0.1.0
