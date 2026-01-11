---
name: Threat Modeling for Secure Design
description: "This skill should be used when the user asks to 'identify security threats',
  'perform threat modeling', 'analyze attack surface', 'apply STRIDE', 'design secure architecture',
  'identify trust boundaries'. Provides threat modeling frameworks for security-by-design."
version: 1.0.0
---

# Threat Modeling for Secure Design

## Purpose

Threat modeling is a structured approach to identifying security threats, vulnerabilities, and countermeasures during the design phase. This skill helps security champions and architects analyze systems before implementation.

## When to Use This Skill

- During design workflow roundtables
- When evaluating architecture proposals
- Identifying security NFRs in specs workflow
- Reviewing API and data flow designs
- Assessing third-party integrations

## Core Concepts

- **Threat**: A potential adverse action that could harm the system
- **Vulnerability**: A weakness that can be exploited
- **Attack Surface**: All points where an attacker can try to enter or extract data
- **Trust Boundary**: Where data or control passes between entities with different trust levels
- **Countermeasure**: A control that mitigates a threat

---

## STRIDE Framework

Microsoft's STRIDE categorizes threats by what they violate:

| Threat | Violates | Description | Example |
|--------|----------|-------------|---------|
| **S**poofing | Authentication | Pretending to be someone else | Stolen credentials, session hijacking |
| **T**ampering | Integrity | Modifying data or code | SQL injection, man-in-the-middle |
| **R**epudiation | Non-repudiation | Denying an action occurred | Missing audit logs |
| **I**nformation Disclosure | Confidentiality | Exposing data to unauthorized parties | Data breach, error message leaks |
| **D**enial of Service | Availability | Making system unavailable | DDoS, resource exhaustion |
| **E**levation of Privilege | Authorization | Gaining unauthorized access | Privilege escalation, IDOR |

### STRIDE per Element

Apply STRIDE based on DFD element type:

| Element | S | T | R | I | D | E |
|---------|---|---|---|---|---|---|
| External Entity | ✓ | | | | | |
| Process | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Data Store | | ✓ | ✓ | ✓ | ✓ | |
| Data Flow | | ✓ | | ✓ | ✓ | |

---

## Trust Boundaries

A trust boundary exists wherever:
- Data crosses between different trust levels
- Control passes between systems
- User input enters the system
- Data leaves for external systems

### Common Trust Boundaries

```
[Internet] ──┬── [DMZ/WAF] ──┬── [App Server] ──┬── [Database]
             │               │                  │
         Boundary 1      Boundary 2         Boundary 3
         (Untrusted)     (Semi-trusted)     (Trusted)
```

**Key Questions at Each Boundary:**
- Who/what is on each side?
- What data crosses?
- How is it validated?
- How is it authenticated?

---

## Data Flow Diagrams (DFD) for Threat Modeling

### DFD Elements

| Symbol | Element | Description |
|--------|---------|-------------|
| ○ | Process | Transforms data |
| ═══ | Data Flow | Data movement |
| ▭ | Data Store | Persistent storage |
| □ | External Entity | Outside system boundary |
| ╌╌╌ | Trust Boundary | Security perimeter |

### Example DFD Pattern

```
[User] ─── Login Request ───> (Auth Service) ─── Query ───> [User DB]
   │                              │
   └─── Session Token <───────────┘

Trust Boundary: ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
                Between User and Auth Service
```

---

## PASTA Framework (7 Stages)

Process for Attack Simulation and Threat Analysis:

| Stage | Activity | Roundtable Focus |
|-------|----------|------------------|
| 1. Define Objectives | Business impact analysis | What are we protecting? Why? |
| 2. Define Technical Scope | Architecture decomposition | What components exist? |
| 3. Application Decomposition | DFD creation | How does data flow? |
| 4. Threat Analysis | STRIDE application | What can go wrong? |
| 5. Vulnerability Analysis | Weakness identification | Where are we weak? |
| 6. Attack Modeling | Attack tree creation | How would attackers proceed? |
| 7. Risk & Impact | Prioritization | What matters most? |

---

## Attack Trees

Hierarchical decomposition of attack goals:

```
[Goal: Steal User Data]
    │
    ├── [Subgoal: Access Database]
    │       ├── SQL Injection (OR)
    │       ├── Credential Theft (OR)
    │       └── Insider Access (OR)
    │
    └── [Subgoal: Intercept Traffic]
            ├── Man-in-the-Middle (AND)
            │       ├── ARP Spoofing
            │       └── SSL Stripping
            └── Compromised Endpoint (OR)
```

**Operators:**
- **OR**: Any child achieves parent goal
- **AND**: All children required

---

## Zero Trust Principles

Modern security architecture assumes breach:

| Principle | Description | Design Implication |
|-----------|-------------|-------------------|
| **Never Trust, Always Verify** | No implicit trust based on location | Authenticate every request |
| **Least Privilege** | Minimum access required | Role-based, time-limited access |
| **Assume Breach** | Design for containment | Micro-segmentation, blast radius |
| **Verify Explicitly** | All signals considered | Device, location, behavior |
| **Secure by Default** | Fail closed, not open | Default deny policies |

---

## OWASP ASVS Levels

Application Security Verification Standard defines 3 levels:

| Level | For | Verification Depth |
|-------|-----|-------------------|
| **L1** | All applications | Opportunistic threats |
| **L2** | Sensitive data apps | Most threats |
| **L3** | Critical/High-value | Advanced persistent threats |

### Key ASVS Categories

| Category | Focus Areas |
|----------|-------------|
| V1: Architecture | Security architecture, threat modeling |
| V2: Authentication | Identity verification, credential handling |
| V3: Session | Session management, tokens |
| V4: Access Control | Authorization, RBAC/ABAC |
| V5: Validation | Input validation, output encoding |
| V7: Cryptography | Key management, algorithms |
| V8: Data Protection | Data classification, privacy |
| V9: Communications | TLS, certificate validation |
| V10: Malicious Code | Integrity verification |
| V13: API | REST/GraphQL security |

---

## Threat Modeling in Roundtables

### Questions to Ask in specs Workflow

- What data are we handling? (Classification: PII, PHI, Financial?)
- Who are the users? (Trusted employees vs. anonymous internet?)
- What compliance applies? (GDPR, HIPAA, PCI-DSS, SOC2?)
- What's the blast radius of a breach?

### Questions to Ask in design Workflow

- Where are the trust boundaries?
- What crosses each boundary?
- How is each crossing authenticated and authorized?
- What happens if Component X is compromised?
- How do we detect an attack?
- How do we recover?

### Security NFR Patterns

```yaml
# Template for security requirements
NFR-SEC-{NNN}:
  category: "Authentication|Authorization|DataProtection|Audit|Cryptography"
  requirement: "{specific measurable requirement}"
  rationale: "{threat being mitigated}"
  verification: "{how to test this}"
  asvs_reference: "V{N}.{N}.{N}"
```

---

## Quick Reference: Common Threats by Component

| Component | Top Threats | Key Controls |
|-----------|-------------|--------------|
| **API Endpoint** | Injection, Broken Auth, BOLA | Input validation, AuthN/AuthZ, Rate limiting |
| **Database** | SQLi, Data exposure, Privilege escalation | Parameterized queries, Encryption, Least privilege |
| **File Upload** | Malware, Path traversal, Storage DoS | Type validation, Sandboxing, Quotas |
| **Session** | Hijacking, Fixation, CSRF | Secure cookies, Rotation, CSRF tokens |
| **Authentication** | Credential stuffing, Brute force, Phishing | MFA, Rate limiting, Breach detection |
| **Third-party API** | Supply chain, Data leakage, Availability | Vendor assessment, Data minimization, Fallbacks |

---

## References

- OWASP Threat Modeling: https://owasp.org/www-community/Threat_Modeling
- Microsoft STRIDE: https://docs.microsoft.com/en-us/azure/security/develop/threat-modeling-tool
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- NIST SP 800-154: Guide to Data-Centric Threat Modeling
