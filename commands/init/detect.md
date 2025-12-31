---
description: Analyze project structure and detect configuration (read-only). Does not create or modify any files.
allowed-tools: Bash(pwd:*), Bash(ls:*), Read, Glob, Grep
argument-hint: [--verbose]
---

# Detect Project State

Analyzes the current directory to understand the project structure. This command is **read-only** and does not create or modify any files.

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

---

## Interpret Context

Based on the Directory contents output, determine:

- **Directory name**: Extract the last segment from the `pwd` output
- **Is git repo**: If `.git` directory appears in listing → "yes", otherwise → "no"
- **S2S initialized**: If `.s2s` directory appears in listing → "yes", otherwise → "no"

---

## Instructions

### Detect Existing Project Files

Scan for common project configuration files:

1. **Package managers**:
   - `package.json` (Node.js) → extract name, description, dependencies
   - `Cargo.toml` (Rust) → extract name, description
   - `pyproject.toml`, `setup.py`, `requirements.txt` (Python)
   - `go.mod` (Go) → extract module name
   - `pom.xml`, `build.gradle` (Java/Kotlin)
   - `*.csproj`, `*.sln` (C#/.NET)
   - `Gemfile` (Ruby)
   - `composer.json` (PHP)

2. **Documentation**:
   - `README.md`, `README.txt`, `readme.*`
   - `docs/` folder structure
   - `CHANGELOG.md`, `CONTRIBUTING.md`

3. **Source structure**:
   - `src/`, `lib/`, `app/`, `cmd/`, `pkg/`, `internal/`
   - Test directories: `tests/`, `test/`, `__tests__/`, `spec/`

4. **Configuration**:
   - `.env`, `.env.example`
   - `docker-compose.yml`, `Dockerfile`
   - CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`

5. **OSS indicators**:
   - `LICENSE`, `LICENSE.md`
   - `CODE_OF_CONDUCT.md`
   - `SECURITY.md`

Use Glob and Read tools to examine files.

### Detect S2S State (if initialized)

If `.s2s` directory exists:

1. Read `.s2s/config.yaml` or `.s2s/workspace.yaml` or `.s2s/component.yaml`
2. Determine project type: standalone, workspace, component
3. Read `.s2s/CONTEXT.md` if exists
4. Read `.s2s/state.yaml` to check for active plans/sessions
5. List files in `.s2s/plans/` to count existing plans

### Compare Current vs Stored State

If S2S is initialized, compare:

1. **README changes**: Has README.md been modified since CONTEXT.md was created?
2. **New config files**: Any new package.json, Cargo.toml, etc.?
3. **Structure changes**: New directories added?
4. **Dependencies**: New dependencies added to project?

### Output Report

Display detection results:

```
Project Detection Report
════════════════════════

Directory: {name}
Git repo: {yes/no}
S2S initialized: {yes/no}

Detected Files:
───────────────
Package config: {file} ({type})
README: {yes/no}
Documentation: {docs structure or "none"}
Source: {directories found}
Tests: {test directories}
CI/CD: {detected or "none"}
OSS files: {list or "none"}

Tech Stack (inferred):
──────────────────────
Language: {detected}
Framework: {detected or "unknown"}
Package manager: {detected}

{If S2S initialized}
S2S Status:
───────────
Type: {standalone/workspace/component}
Plans: {count}
Active plan: {id or "none"}
Context last updated: {date}
Changes detected: {yes/no}
  - {list of changes if any}
{/If}

{If verbose flag}
Detailed findings:
──────────────────
{Full file contents and analysis}
{/If}
```

### Suggest Next Steps

Based on detection results:

**If NOT initialized**:
```
Recommendation: Run /s2s:init to set up Spec2Ship for this project.
```

**If initialized and up to date**:
```
Project is configured and up to date.
Run /s2s:plan:list to see existing plans.
```

**If initialized with changes**:
```
Changes detected since last update.
Run /s2s:init to review and update configuration.
Or run /s2s:init:context to update CONTEXT.md only.
```
