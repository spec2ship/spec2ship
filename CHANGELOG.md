# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `CONTRIBUTING.md` in repository root (OSS standard)
- `docs/architecture/` with architecture overview and ADR structure
- `CHANGELOG.md` (this file)
- `CODE_OF_CONDUCT.md`
- GitHub issue and PR templates

### Changed
- MADR skill updated to official MADR format (4-digit padding)
- Documentation restructured: `docs/contributing/` → root `CONTRIBUTING.md` + `docs/architecture/`
- ADR naming convention: `NNNN-slug.md` instead of `SAD-NNN-slug.md`

### Removed
- `docs/contributing/` folder (content merged into `CONTRIBUTING.md` and `docs/architecture/`)
- `.claude/decisions/` folder (decisions now in `.s2s/decisions/` local)
- Inline SAD references from `CLAUDE.md`

## [0.2.0] - 2026-01-10

### Added
- Complete roundtable system with 12 specialized agents
- 5 facilitation strategies: standard, disney, debate, consensus-driven, six-hats
- Session management commands: list, status, validate, cleanup
- Verbose and diagnostic modes for debugging
- Critical Stance and Context Check for anti-sycophancy
- Plan management: create, list, start, complete

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

[Unreleased]: https://github.com/spec2ship/spec2ship/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/spec2ship/spec2ship/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/spec2ship/spec2ship/releases/tag/v0.1.0
