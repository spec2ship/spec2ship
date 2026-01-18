# Skills Progressive Disclosure

## Status

accepted

## Context and Problem Statement

Skills provide domain knowledge (MADR, arc42, ISO 25010, etc.) but loading all content upfront wastes tokens. How should skill content be organized for efficient loading?

## Decision Drivers

- Context window has token limits
- SKILL.md is always loaded when skill is invoked
- Most invocations need core concepts only
- Detailed examples and references needed occasionally
- Want consistent structure across skills

## Considered Options

- Single large SKILL.md with everything
- Multiple small files, load selectively
- Progressive disclosure (core + references + examples)

## Decision Outcome

Chosen option: "Progressive disclosure", because it balances immediate utility with on-demand detail.

```
skills/{name}/
├── SKILL.md          # Always loaded (~1,500-2,000 words)
├── references/       # Loaded on demand
└── examples/         # Loaded on demand
```

### Consequences

- Good, because SKILL.md provides immediate value
- Good, because detailed content available when needed
- Good, because consistent structure across skills
- Good, because respects token limits
- Bad, because requires discipline in what goes in SKILL.md
- Neutral, because commands/agents must explicitly load references

## Pros and Cons of the Options

### Single large SKILL.md

Everything in one file.

- Good, because simple structure
- Good, because complete context always available
- Bad, because wastes tokens when detail not needed
- Bad, because may exceed context limits

### Multiple small files

Many small files, command decides what to load.

- Good, because minimal token usage
- Bad, because complex loading logic
- Bad, because inconsistent structure
- Bad, because hard to know what's available

### Progressive disclosure

Three-tier structure: core, references, examples.

- Good, because predictable structure
- Good, because core always fits in context
- Good, because depth available when needed
- Neutral, because requires explicit loading of extras

## More Information

SKILL.md should contain:
- Purpose and when to use
- Core concepts (essential knowledge)
- Quick reference (templates, patterns)
- Pointers to references/ and examples/

References and examples are loaded via Read tool when deeper detail is needed.

Example structure:
```
skills/madr-decisions/
├── SKILL.md              # Template, status lifecycle, naming
├── references/
│   └── full-template.md  # Complete MADR template
└── examples/
    ├── technology.md     # Technology choice example
    └── architecture.md   # Architecture pattern example
```
