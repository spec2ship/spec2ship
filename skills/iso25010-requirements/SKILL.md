---
name: ISO 25010 Requirements Structure
description: "This skill should be used when the user asks to 'define quality requirements',
  'write non-functional requirements', 'structure NFRs', 'apply ISO 25010', 'specify quality characteristics'.
  Provides ISO 25010 quality model patterns for comprehensive requirements coverage."
version: 0.1.0
---

# ISO 25010 Requirements Structure

## Purpose

ISO 25010 defines a product quality model with 8 characteristics and 31 sub-characteristics. This skill helps structure requirements to ensure comprehensive quality coverage.

## When to Use This Skill

- Defining project requirements
- Specifying quality goals
- Creating acceptance criteria
- Reviewing requirement completeness
- Prioritizing quality characteristics

## Core Concepts

- **8 Quality Characteristics**: Functional Suitability, Performance, Compatibility, Usability, Reliability, Security, Maintainability, Portability
- **FR vs NFR**: Functional Requirements (what it does) vs Non-Functional Requirements (how well it does it)
- **Measurable Criteria**: Every requirement needs quantifiable acceptance criteria
- **Traceability**: Requirements link to tests, implementations, and decisions

## Quality Characteristics Quick Reference

| Characteristic | Sub-characteristics | Key Questions |
|---------------|---------------------|---------------|
| **Functional Suitability** | Completeness, Correctness, Appropriateness | Does it do what users need? |
| **Performance Efficiency** | Time behavior, Resource utilization, Capacity | Is it fast and efficient? |
| **Compatibility** | Co-existence, Interoperability | Does it work with other systems? |
| **Usability** | Learnability, Operability, Accessibility | Can users use it effectively? |
| **Reliability** | Maturity, Availability, Fault tolerance, Recoverability | Does it work consistently? |
| **Security** | Confidentiality, Integrity, Non-repudiation, Accountability, Authenticity | Is it secure? |
| **Maintainability** | Modularity, Reusability, Analysability, Modifiability, Testability | Can it be maintained? |
| **Portability** | Adaptability, Installability, Replaceability | Can it run in different environments? |

## Artifact ID Schema (S2S Canonical)

**These IDs are immutable across roundtable rounds and output formats.**

### Specs Workflow (Requirements)

| Prefix | Description | Example |
|--------|-------------|---------|
| `REQ-{NNN}` | Generic requirement | REQ-001 |
| `FR-{AREA}-{NNN}` | Functional requirement (with area) | FR-AUTH-001 |
| `NFR-{QUAL}-{NNN}` | Non-functional requirement | NFR-PERF-001 |
| `BR-{NNN}` | Business rule | BR-001 |
| `EX-{NNN}` | Exclusion (out-of-scope) | EX-001 |

### Design Workflow (Architecture)

| Prefix | Description | Example |
|--------|-------------|---------|
| `ARCH-{NNN}` | Architecture decision | ARCH-001 |
| `COMP-{NNN}` | Component definition | COMP-001 |

### Brainstorm Workflow (Ideas)

| Prefix | Description | Example |
|--------|-------------|---------|
| `IDEA-{NNN}` | Idea from dreamer phase | IDEA-001 |
| `RISK-{NNN}` | Risk from critic phase | RISK-001 |
| `MIT-{NNN}` | Mitigation for risk | MIT-001 |

### Cross-Workflow (Shared)

| Prefix | Description | Example |
|--------|-------------|---------|
| `OQ-{NNN}` | Open question | OQ-001 |
| `CONF-{NNN}` | Conflict between participants | CONF-001 |
| `UC-{NNN}` | Use case / user workflow | UC-001 |
| `CN-{NNN}` | Technical/business constraint | CN-001 |
| `AS-{NNN}` | Assumption to validate | AS-001 |

**Area codes for FR-** (functional):
- AUTH: Authentication/Authorization
- USER: User management
- DATA: Data handling
- API: API/Integration
- UI: User interface
- NOTIF: Notifications
- REPORT: Reporting

**Quality codes for NFR-** (non-functional):
- PERF: Performance Efficiency
- REL: Reliability
- SEC: Security
- MAINT: Maintainability
- USE: Usability
- COMPAT: Compatibility

**Mapping to Output Formats**:

| Internal ID | SRS Section | Volere | Checklist |
|-------------|-------------|--------|-----------|
| FR-AUTH-001 | 3.1.1 | FR-1 | ☐ Feature |
| NFR-PERF-001 | 4.1 | NFR-1 | ☐ Quality |
| EX-001 | 5.x | Excluded | (omitted) |

```
Examples:
FR-AUTH-001          Login with email/password
FR-USER-002          View user profile
NFR-PERF-001         Response time < 2s
NFR-SEC-001          Data encryption at rest
BR-001               Maximum 5 login attempts
UC-001               New user registration flow
EX-001               Mobile app (future phase)
CN-001               Must use existing PostgreSQL
AS-001               Users have stable internet
```

## Requirement Template

```markdown
### {FR|NFR}-{ID}: {Title}

**Priority**: {P0|P1|P2|P3} or {Must|Should|Could|Won't}
**Status**: {Draft|Approved|Implemented|Verified}

**Description**:
{Clear statement of what is required}

**Rationale**:
{Why this requirement exists}

**Acceptance Criteria**:
- [ ] {Measurable criterion 1}
- [ ] {Measurable criterion 2}

**Dependencies**:
- Depends on: {requirement IDs}
- Enables: {requirement IDs}
```

## Quality Requirement Patterns

### Performance (NFR-PERF)
```markdown
### NFR-PERF-001: Response Time

**Metric**: API response time
**Target**: p95 < 200ms, p99 < 500ms
**Measurement**: Application metrics under normal load

**Acceptance Criteria**:
- [ ] 95th percentile response time under 200ms
- [ ] No request exceeds 2 second timeout
- [ ] Measured under expected peak load
```

### Reliability (NFR-REL)
```markdown
### NFR-REL-001: System Availability

**Metric**: System uptime
**Target**: 99.9% availability (monthly)
**Measurement**: Monitoring system alerts

**Acceptance Criteria**:
- [ ] Monthly uptime ≥ 99.9%
- [ ] No single outage exceeds 15 minutes
- [ ] Recovery time objective: 5 minutes
```

### Security (NFR-SEC)
```markdown
### NFR-SEC-001: Authentication Security

**Metric**: Authentication strength
**Standard**: OWASP ASVS Level 2

**Acceptance Criteria**:
- [ ] Passwords hashed with bcrypt (cost ≥ 12)
- [ ] Session tokens are cryptographically random
- [ ] Failed login attempts are rate-limited
- [ ] No sensitive data in URLs or logs
```

## Integration with S2S

In Spec2Ship projects:
- Requirements go in `docs/specifications/requirements.md`
- Use consistent ID format (FR-*, NFR-*)
- Reference requirements in plans
- Link to ADRs for quality decisions
