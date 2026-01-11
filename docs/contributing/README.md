# Contributing to Spec2Ship

Thank you for your interest in contributing to Spec2Ship!

## Contents

| Document | Description |
|----------|-------------|
| [Development Setup](./development.md) | Set up your development environment |
| [Architecture](./architecture.md) | System architecture overview |

## Quick Start

### 1. Fork and Clone

```bash
git clone https://github.com/YOUR-USERNAME/spec2ship.git
cd spec2ship
```

### 2. Install the Plugin

```bash
# Remove existing installation
/plugin marketplace remove spec2ship

# Add your fork
/plugin marketplace add https://github.com/YOUR-USERNAME/spec2ship.git#develop

# Install
/plugin install s2s@spec2ship
```

### 3. Make Changes

Edit files in the repository. Changes take effect immediately.

### 4. Test

```bash
# Test in a sample project
cd /tmp
mkdir test-project && cd test-project
/s2s:init
/s2s:specs --verbose
```

### 5. Submit PR

```bash
git checkout -b feature/your-feature
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature
```

## What to Contribute

### Good First Issues

- Documentation improvements
- Additional examples
- Bug fixes in commands

### Feature Contributions

- New agents (see [Extending: New Agent](../extending/new-agent.md))
- New skills (see [Extending: New Skill](../extending/new-skill.md))
- New strategies (see [Extending: New Strategy](../extending/new-strategy.md))

### Core Contributions

- Command improvements
- Facilitator enhancements
- Session management

## Guidelines

### Code Style

- **Language**: English for all code and documentation
- **Markdown**: GitHub-flavored, CommonMark compatible
- **YAML**: 2-space indent, quoted strings with special chars

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new security-champion agent
fix: correct context propagation in specs
docs: update roundtable architecture diagram
refactor: simplify session validation logic
```

### Pull Requests

1. One feature per PR
2. Include tests or test evidence
3. Update documentation if needed
4. Reference issues if applicable

## Getting Help

- [GitHub Issues](https://github.com/spec2ship/spec2ship/issues)
- [Documentation](../README.md)

---

*See also: [Architecture](./architecture.md) | [Extending](../extending/)*
