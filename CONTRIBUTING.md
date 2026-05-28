# Contributing to Spec2Ship

Thank you for your interest in contributing to Spec2Ship!

## Table of Contents

- [Quick Start](#-quick-start)
- [Development Setup](#️-development-setup)
- [Project Structure](#-project-structure)
- [Making Changes](#-making-changes)
- [Testing](#-testing)
- [Debugging](#-debugging)
- [Git Workflow](#-git-workflow)
- [What to Contribute](#-what-to-contribute)
- [Guidelines](#-guidelines)
- [Getting Help](#-getting-help)

## 🚀 Quick Start

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/spec2ship.git
   cd spec2ship
   ```

2. **Install the Plugin**
   ```bash
   # Remove existing installation
   /plugin marketplace remove spec2ship

   # Add your fork
   /plugin marketplace add https://github.com/YOUR-USERNAME/spec2ship.git#develop

   # Install
   /plugin install s2s@spec2ship
   ```

3. **Test in a Sample Project**
   ```bash
   cd /tmp
   mkdir test-project && cd test-project
   /s2s:init
   /s2s:specs --verbose
   ```

4. **Submit a PR**
   ```bash
   git checkout -b feature/your-feature
   git add .
   git commit -m "feat: your feature description"
   git push origin feature/your-feature
   ```

> [!TIP]
> Use `--verbose` flag when testing to see detailed logs in `.s2s/sessions/{id}/rounds/`.

## 🛠️ Development Setup

### Prerequisites

> [!NOTE]
> Spec2Ship requires Claude Code CLI to run. Make sure you have it installed before proceeding.

- [Claude Code](https://claude.ai) CLI installed
- Git
- A test project directory

### Installation for Development

**Recommended: Local plugin directory**

Clone your fork and use `--plugin-dir` to point Claude Code to it:

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/spec2ship.git ~/repos/spec2ship

# Create a test project
mkdir -p /tmp/test-project && cd /tmp/test-project

# Start Claude Code pointing to your local plugin
claude --plugin-dir ~/repos/spec2ship
```

Changes to the plugin are immediately available thanks to hot reload. No reinstallation needed.

**Alternative: Marketplace installation**

If you prefer the marketplace approach:

```bash
# Remove any existing installation
/plugin marketplace remove spec2ship

# Add your fork
/plugin marketplace add https://github.com/YOUR-USERNAME/spec2ship.git#develop

# Install with alias
/plugin install s2s@spec2ship
```

> [!NOTE]
> With marketplace installation, you must reinstall after pulling changes.

## 📁 Project Structure

```
spec2ship/
├── .claude/                  # Claude context and guidelines
│   ├── CLAUDE.md             # Main context file (read this first)
│   └── s2s-development.md    # Development patterns
├── .claude-plugin/           # Plugin manifest
├── commands/                 # Slash commands (/s2s:*)
├── agents/                   # AI agents (roundtable, exploration, validation)
├── skills/                   # Knowledge bases
├── templates/                # File templates
├── docs/                     # Documentation
│   ├── README.md             # Core concepts
│   └── architecture/         # Architecture docs and ADRs
└── examples/                 # Sample outputs
```

### Key Files to Understand

| File | Purpose |
|------|---------|
| `.claude/CLAUDE.md` | Main development context |
| `.claude/s2s-development.md` | Development patterns and anti-patterns |
| `commands/specs.md` | Example of workflow command |
| `agents/roundtable/facilitator.md` | Core orchestration agent |
| `docs/architecture/README.md` | Architecture overview |

## ✏️ Making Changes

1. Edit files in the repository
2. Changes take effect immediately (no rebuild needed)
3. Test in a separate project directory

## 🧪 Testing

### Common Test Scenarios

```bash
# Create test project
cd /tmp && mkdir s2s-test && cd s2s-test

# Test specs workflow
/s2s:init
/s2s:specs --verbose --interactive

# Test design workflow
/s2s:design --verbose

# Test brainstorm
/s2s:brainstorm "test topic" --verbose

# Test session management
/s2s:session:list
/s2s:session:validate
```

> [!TIP]
> **For smoother testing:** Disable auto-compact (`/config` → "Auto-compact" = false) to avoid mid-round interruptions during workflow tests.

> [!WARNING]
> **Recommended for testing:** Run `claude --dangerously-skip-permissions` to prevent permission prompts that disrupt roundtable execution.

### Regression testing (dogfood)

Spec2Ship has no automated test suite (it is a markdown/YAML plugin). Regression confidence comes from **dogfooding**: running the real `/s2s:*` workflows against a stable sample project and comparing outputs across code states.

Recommended pattern:

- Keep a dedicated **dogfood project** separate from this repo, with a small, well-bounded `CONTEXT.md` (a realistic but tiny domain exercises the full workflows without noise).
- Use a **bare repo + one worktree per experiment** (`exp1`, `exp2`, ...). Each worktree hosts one run and is then frozen as a reference, so the same workflow can run under different plugin states (e.g. pre-refactor vs post-refactor) and the outputs diffed.
- For a refactor, capture a **pre-change baseline** run, land the change, then **replay** and compare. Compare against schema/metric invariants, not artifact prose (LLM output varies run-to-run).

See [`.s2s/test-baselines/README.md`](.s2s/test-baselines/README.md) for how baseline summaries are stored in this repo and why raw session data stays in the dogfood repo.

## 🐛 Debugging

### Enable Verbose Mode

```bash
/s2s:specs --verbose
```

Creates detailed logs in `.s2s/sessions/{id}/rounds/`.

### Enable Diagnostic Mode

```bash
/s2s:specs --diagnostic
```

Adds post-round analysis and anomaly detection.

### Validate Sessions

```bash
/s2s:session:validate
```

Runs structural and strategy-specific consistency checks.

### Common Issues

> [!WARNING]
> **Plugin Not Updating?** If using marketplace installation, reinstall after pulling changes:

```bash
/plugin marketplace remove spec2ship
/plugin marketplace add https://github.com/YOUR-USERNAME/spec2ship.git#YOUR-BRANCH
/plugin install s2s@spec2ship
```

> [!TIP]
> Use `--plugin-dir` instead to avoid this issue entirely. See [Installation for Development](#installation-for-development).

**Agent Not Found**
- Check location: `agents/roundtable/{name}.md`
- Verify frontmatter has `name: roundtable-{name}`

**Skill Not Loading**
- Check location: `skills/{name}/SKILL.md`
- Verify frontmatter has `name` and `description`

## 🌿 Git Workflow

### Branches

- `main`: stable releases
- `develop`: development branch
- `feature/*`, `fix/*`, `chore/*`, `docs/*`: work branches (branch from `develop`)

### Versioning and tags

Spec2Ship uses a 3-tier flow with strict tag discipline:

- **Flow**: `feature/*` (or `fix/*`, `chore/*`, ...) → `develop` → `main`.
- **Version source of truth**: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (kept in sync) plus the matching `## [X.Y.Z] - YYYY-MM-DD` section in `CHANGELOG.md`.
- **`develop` carries the next version**: the manifest on `develop` reflects the upcoming release so anyone installing from `develop` knows what they got. No git tag is created on `develop`.
- **Tags live only on `main`**: a `vX.Y.Z` git tag is created only when `develop` is merged to `main`. The tag marks a fully validated release.
- **SemVer**: minor bumps (`0.x.0`) for feature releases until 1.0. The `1.0.0` major is reserved for the "API/contract stable" milestone, not mere feature accumulation. The "API" surface = command names, flags, `.s2s/` file/session schemas, and config schema.

Release sequence (no direct commits to `develop` or `main`):

1. Land work via PRs into `develop`.
2. When cutting a release, set the `CHANGELOG.md` date for the version in a small prep PR into `develop`.
3. Open a `release: vX.Y.Z` PR from `develop` to `main`. Merge with a merge commit, **without** `--delete-branch` (never delete `develop`).
4. Tag `vX.Y.Z` on `main` and push the tag. Optionally publish a GitHub Release from the tag.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git commit -m "feat(agents): add security-champion participant"
git commit -m "fix(specs): correct context propagation"
git commit -m "docs(roundtable): update architecture diagram"
```

### Pull Request Process

1. Create feature branch from `develop`
2. Make changes
3. Test thoroughly
4. Submit PR to `develop`
5. One feature per PR
6. Include tests or test evidence
7. Update documentation if needed

## 🤝 What to Contribute

### Good First Issues

- Documentation improvements
- Additional examples
- Bug fixes in commands

### Feature Contributions

- New agents
- New skills
- New strategies

> [!TIP]
> For extension guides, ask Claude: `"how to extend s2s"` (loads s2s-guide skill with step-by-step instructions).

### Core Contributions

- Command improvements
- Facilitator enhancements
- Session management

## 📋 Guidelines

### Code Style

- **Language**: English for all code and documentation
- **Markdown**: GitHub-flavored, CommonMark compatible
- **YAML**: 2-space indent, quoted strings with special chars

### Documentation

- Update relevant docs when changing functionality
- For architecture changes, consider adding an ADR

## ❓ Getting Help

- [GitHub Issues](https://github.com/spec2ship/spec2ship/issues)
- [Core Concepts](docs/)
- [Architecture](docs/architecture/)
