# Examples

This folder contains sample outputs from Spec2Ship workflows.

## Sample Projects

| Project | Description |
|---------|-------------|
| [demo-project](./demo-project/) | Complete example showing all workflow outputs |

## What's Included

Each sample project includes:

```
{project}/
├── CONTEXT.md              # Project context (input to s2s)
├── requirements.md         # Output from /s2s:specs
└── architecture.md         # Output from /s2s:design
```

## Using Examples

These examples show what Spec2Ship produces. To create your own:

```bash
# Initialize your project
cd your-project
/s2s:init

# Generate requirements
/s2s:specs

# Generate architecture
/s2s:design
```

## Notes

- Examples are representative outputs, not templates
- Your actual output will vary based on project context
- Session files (`.s2s/sessions/`) are not included

---

*See also: [Core Concepts](../docs/)*
