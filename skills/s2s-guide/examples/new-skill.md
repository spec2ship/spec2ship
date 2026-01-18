# Example: Creating a New Skill

Step-by-step guide to create a new knowledge skill.

## Overview

Skills are knowledge bases that provide patterns, standards, and templates. They use **progressive disclosure**:

- **SKILL.md**: Core concepts (~1,500-2,000 words max), always loaded
- **references/**: Detailed patterns, loaded on demand
- **examples/**: Working samples, loaded on demand

## Directory Structure

```
skills/{skill-name}/
├── SKILL.md              # Required: Core knowledge
├── references/           # Optional: Detailed patterns
│   ├── pattern-1.md
│   └── pattern-2.md
└── examples/             # Optional: Working samples
    └── example-1.md
```

---

## Step 1: Create Directory

```bash
mkdir -p skills/{skill-name}/references
mkdir -p skills/{skill-name}/examples
```

---

## Step 2: Write SKILL.md

### Frontmatter (REQUIRED)

```yaml
---
name: Display Name
description: "This skill should be used when the user asks to
  'trigger phrase 1', 'trigger phrase 2', 'trigger phrase 3'.
  Brief purpose statement."
version: 0.1.0
---
```

**Critical rules**:
- Use **third-person** in description
- Include **3-5 specific trigger phrases**
- Trigger phrases should be **exact things users would say**

### Body Structure

```markdown
# Display Name

## Purpose

{1-2 sentences explaining what this skill provides}

## When to Use This Skill

- {Scenario 1}
- {Scenario 2}
- {Scenario 3}

## Core Concepts

{3-5 key concepts with brief explanations}

## Quick Reference

{Table or reference for common use cases}

## Templates

{Key templates users need}

## Additional Resources

- `references/pattern-1.md` - {Description}
- `examples/example-1.md` - {Description}
```

---

## Step 3: Add References (Optional)

For detailed patterns that don't need to be in core SKILL.md:

```markdown
# Pattern Name

## When to Use

{When this specific pattern applies}

## Structure

{Detailed structure or template}

## Example

{Working example}

## Variations

{Common variations}
```

---

## Step 4: Add Examples (Optional)

Working samples that users can copy:

```markdown
# Example: {Use Case}

## Context

{When you'd use this example}

## Complete Template

{Copy-paste ready content}

## Customization Points

{What to modify for your use case}
```

---

## Step 5: Reference from Agents

Agents declare skill dependencies in frontmatter:

```yaml
---
name: my-agent
description: "..."
tools: []
skills: skill-name
---
```

**Format**: Comma-separated string (not array)

```yaml
# Single skill
skills: iso25010-requirements

# Multiple skills
skills: iso25010-requirements, arc42-templates
```

---

## Complete Example: REST API Patterns

### Directory Structure

```
skills/rest-api-patterns/
├── SKILL.md
├── references/
│   ├── resource-naming.md
│   ├── error-handling.md
│   └── pagination.md
└── examples/
    └── user-api.md
```

### SKILL.md

```markdown
---
name: REST API Patterns
description: "This skill should be used when the user asks to
  'design REST API', 'create API endpoints', 'write API specification',
  'define resource structure'. Provides patterns for RESTful API design."
version: 0.1.0
---

# REST API Patterns

## Purpose

Provides patterns and conventions for designing RESTful APIs.

## When to Use This Skill

- Designing new API endpoints
- Reviewing API structure
- Creating OpenAPI/Swagger specifications

## Core Concepts

### Resources

- Nouns, not verbs: `/users` not `/getUsers`
- Plural form: `/orders` not `/order`
- Hierarchical: `/users/{id}/orders`

### HTTP Methods

| Method | Purpose | Idempotent |
|--------|---------|------------|
| GET | Read | Yes |
| POST | Create | No |
| PUT | Replace | Yes |
| PATCH | Update | No |
| DELETE | Remove | Yes |

## Quick Reference

| Action | Method | Endpoint | Status |
|--------|--------|----------|--------|
| List | GET | /resources | 200 |
| Create | POST | /resources | 201 |
| Read | GET | /resources/{id} | 200 |
| Update | PATCH | /resources/{id} | 200 |
| Delete | DELETE | /resources/{id} | 204 |

## Additional Resources

- `references/resource-naming.md` - Naming conventions
- `references/error-handling.md` - Error response patterns
- `examples/user-api.md` - Complete user API example
```

---

## Best Practices

### DO

- Use third-person in description
- Include 3-5 specific trigger phrases
- Keep SKILL.md under 2,000 words
- Move detailed content to references/
- Document each reference file's purpose
- Use imperative voice in instructions

### DON'T

- Use second person ("You should...")
- Put all content in SKILL.md
- Use vague triggers ("when needed")
- Duplicate content across files
- Create deeply nested directories

---

## Checklist

- [ ] Created `skills/{skill-name}/` directory
- [ ] Created SKILL.md with proper frontmatter
- [ ] Used **third-person** description
- [ ] Included **3-5 trigger phrases**
- [ ] SKILL.md under 2,000 words
- [ ] Created references/ for detailed patterns
- [ ] Created examples/ for working samples
- [ ] Documented all files in SKILL.md "Additional Resources"
