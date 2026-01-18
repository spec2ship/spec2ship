---
name: Conventional Commits
description: "This skill should be used when the user asks to 'write commit message', 'create conventional commit',
  'format git commit', 'follow commit conventions', 'structure commit message'.
  Provides Conventional Commits patterns for consistent, machine-readable commit messages."
version: 0.1.0
---

# Conventional Commits

## Purpose

Conventional Commits is a specification for adding human and machine readable meaning to commit messages. This skill provides patterns for consistent, informative commit messages.

## When to Use This Skill

- Writing commit messages for changes
- Formatting commits for changelog generation
- Indicating breaking changes
- Referencing issues in commits
- Following team commit conventions

## Core Concepts

- **Type**: Category of change (feat, fix, docs, etc.)
- **Scope**: Optional area affected (auth, api, ui)
- **Breaking Change**: Indicated by `!` or `BREAKING CHANGE` footer
- **Machine Readable**: Enables automated changelog and versioning

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types Quick Reference

| Type | When to Use | Example |
|------|-------------|---------|
| `feat` | New feature | `feat: add user login` |
| `fix` | Bug fix | `fix: resolve login timeout` |
| `docs` | Documentation only | `docs: update API readme` |
| `style` | Formatting, no code change | `style: fix indentation` |
| `refactor` | Code change, no feature/fix | `refactor: extract auth service` |
| `perf` | Performance improvement | `perf: cache user queries` |
| `test` | Adding/fixing tests | `test: add login unit tests` |
| `build` | Build system changes | `build: update webpack config` |
| `ci` | CI configuration | `ci: add deploy workflow` |
| `chore` | Other changes | `chore: update dependencies` |
| `revert` | Revert previous commit | `revert: undo login changes` |

## Scope Conventions

Scope indicates the area of change:

```
feat(auth): add password reset
fix(api): handle null response
docs(readme): update installation steps
refactor(core): simplify validation logic
```

Common scopes:
- `auth`, `api`, `ui`, `db`, `core`
- Component/module names
- Feature names

## Breaking Changes

Indicate breaking changes with `!` or footer:

```
feat!: remove deprecated API endpoints

BREAKING CHANGE: The /v1/users endpoint has been removed.
Use /v2/users instead.
```

Or with footer:
```
feat(api): update response format

BREAKING CHANGE: Response now uses camelCase keys.
```

## Commit Message Examples

### Simple Feature
```
feat: add email notification on signup
```

### Feature with Scope
```
feat(auth): implement OAuth2 login with Google

- Add OAuth2 flow for Google provider
- Store refresh tokens securely
- Update user model for external providers
```

### Bug Fix with Issue Reference
```
fix(api): prevent duplicate user creation

Race condition allowed duplicate signups with same email.
Added database constraint and application-level check.

Fixes #123
```

### Breaking Change
```
feat(api)!: change authentication to JWT

Previous session-based auth replaced with stateless JWT.
All clients must update to include Bearer token.

BREAKING CHANGE: Session cookies no longer work.
Clients must use Authorization header with JWT.

Migration guide: .s2s/guides/jwt-auth.md
```

### Documentation
```
docs: add architecture decision records

- Create ADR template in .s2s/decisions
- Document database selection (ADR-001)
- Document API versioning (ADR-002)
```

## Footer Conventions

| Footer | Purpose | Example |
|--------|---------|---------|
| `Fixes #N` | Close issue | `Fixes #123` |
| `Refs #N` | Reference issue | `Refs #456` |
| `BREAKING CHANGE` | Breaking change | See above |
| `Co-authored-by` | Credit co-author | `Co-authored-by: Name <email>` |
| `Reviewed-by` | Credit reviewer | `Reviewed-by: Name <email>` |

## Integration with S2S

In Spec2Ship projects:
- Git config in `.s2s/config.yaml`:
  ```yaml
  git:
    commit_convention: "conventional"
  ```
- Branch naming: `feature/F{NN}-{slug}`
- Reference plan IDs in commits when relevant
- Use scope matching component/feature name
