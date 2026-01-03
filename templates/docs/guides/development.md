# Development Guide

## Prerequisites

| Tool | Version | Installation |
|------|---------|--------------|
| | | |

## Getting Started

### 1. Clone Repository

```bash
git clone {repository-url}
cd {project-name}
```

### 2. Install Dependencies

```bash
{installation command}
```

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

### 4. Run Development Server

```bash
{run command}
```

## Project Structure

```
{project-name}/
├── src/                    # Source code
├── tests/                  # Test files
├── docs/                   # Documentation
├── .s2s/                   # Spec2Ship configuration
└── ...
```

## Development Workflow

### Creating Features

1. Create implementation plan:
   ```
   /s2s:plan:create "feature name" --branch
   ```

2. Start working on plan:
   ```
   /s2s:plan:start "plan-id"
   ```

3. Implement and test

4. Complete plan:
   ```
   /s2s:plan:complete
   ```

### Code Style

{Description of code style guidelines or link to linter config}

### Commit Messages

Follow Conventional Commits format:

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Common Tasks

### Running Linter

```bash
{lint command}
```

### Formatting Code

```bash
{format command}
```

### Building

```bash
{build command}
```

## Troubleshooting

### {Common Issue}

**Problem**: {Description}

**Solution**: {Steps to resolve}
