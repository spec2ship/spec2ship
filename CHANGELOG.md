# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
