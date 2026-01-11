# Development Setup

How to set up your environment for developing Spec2Ship.

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI installed
- Git
- A test project directory

## Installation for Development

### 1. Clone the Repository

```bash
git clone https://github.com/spec2ship/spec2ship.git
cd spec2ship
```

### 2. Install as Plugin

```bash
# Remove any existing installation
/plugin marketplace remove spec2ship

# Add from local path or your fork
/plugin marketplace add https://github.com/YOUR-USERNAME/spec2ship.git#develop

# Install with alias
/plugin install s2s@spec2ship
```

### 3. Verify Installation

```bash
# Check plugin is loaded
/plugin list

# Test a command
/s2s:init --help
```

## Development Workflow

### Making Changes

1. Edit files in the repository
2. Changes take effect immediately (no rebuild needed)
3. Test in a separate project directory

### Testing

```bash
# Create test project
cd /tmp
mkdir s2s-test && cd s2s-test

# Initialize
/s2s:init

# Test your changes
/s2s:specs --verbose
```

### Common Test Scenarios

```bash
# Test specs workflow
/s2s:specs --verbose --interactive

# Test design workflow
/s2s:design --verbose

# Test brainstorm
/s2s:brainstorm "test topic" --verbose

# Test session management
/s2s:session:list
/s2s:session:validate
```

## Project Structure

```
spec2ship/
├── .claude/                  # Development context
│   ├── CLAUDE.md             # Main context (read this first)
│   ├── s2s-development.md    # Development patterns
│   └── guidelines/           # Conventions
├── commands/                 # Edit commands here
├── agents/                   # Edit agents here
├── skills/                   # Edit skills here
├── templates/                # File templates
└── docs/                     # Documentation
```

## Key Files to Understand

| File | Purpose |
|------|---------|
| `.claude/CLAUDE.md` | Main architecture context |
| `.claude/s2s-development.md` | Development patterns and anti-patterns |
| `.claude/guidelines/glossary.md` | Terminology |
| `commands/specs.md` | Example of workflow command |
| `agents/roundtable/facilitator.md` | Core orchestration agent |

## Debugging

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
/s2s:session:validate --level deep
```

Checks session consistency with semantic analysis.

## Common Issues

### Plugin Not Updating

```bash
# Force reinstall
/plugin marketplace remove spec2ship
/plugin marketplace add https://github.com/YOUR-USERNAME/spec2ship.git#YOUR-BRANCH
/plugin install s2s@spec2ship
```

### Agent Not Found

Check agent file:
- Correct location: `agents/roundtable/{name}.md`
- Valid frontmatter with `name: roundtable-{name}`

### Skill Not Loading

Check skill file:
- Correct location: `skills/{name}/SKILL.md`
- Valid frontmatter with `name`, `description`

## Git Workflow

### Branches

- `main` - Stable releases
- `develop` - Development branch
- `feature/*` - Feature branches

### Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git commit -m "feat(agents): add security-champion participant"
git commit -m "fix(specs): correct context propagation"
git commit -m "docs(roundtable): update architecture diagram"
```

### Pull Requests

1. Create feature branch from `develop`
2. Make changes
3. Test thoroughly
4. Submit PR to `develop`

---

*See also: [Architecture](./architecture.md) | [Contributing](./README.md)*
