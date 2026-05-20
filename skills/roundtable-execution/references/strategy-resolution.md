# Strategy Resolution Hierarchy

> **Status**: canonical reference (TECH-002 Phase 4)
> **Consumers**: `commands/roundtable.md` Phase 1 strategy resolution; documented in `roundtable-strategies/SKILL.md` "Strategy resolution hierarchy" section
> **D3 hierarchy**: established by Phase 4 plan §3.3 + ADR-0011 Phase 4 addendum

Phase 1 of `commands/roundtable.md` resolves the active strategy via the following hierarchy. The first source that yields a value wins; subsequent sources are NOT consulted.

## Resolution order (ASCII diagram)

```
CLI --strategy <value>                                 (highest priority)
  ├─ if set → use it
  └─ else → .s2s/config.yaml.roundtable.strategy.by_workflow_type[{workflow_type}]
            ├─ if set → use it
            └─ else → profiles/{workflow_type}.yaml.default_strategy
                      ├─ if set → use it
                      └─ else → error "no strategy resolvable for {workflow_type}"   (no fallback beyond this)
```

**Override that wins over all**: `profiles/{workflow_type}.yaml.strategy_constraints.forced == true`. When set, the profile `default_strategy` is used regardless of CLI/config.yaml. Only `brainstorm.yaml` currently sets `forced: true` (forces `disney`).

## Source roles (D3 hierarchy)

| Source | Role | Contains |
|--------|------|----------|
| `.s2s/config.yaml` | **User canonical**: created by `/s2s:init` from `templates/project/config.yaml`. Authoritative at runtime. | Per-project workflow strategies + participants + escalation triggers + consensus thresholds. |
| `skills/roundtable-execution/profiles/{workflow}.yaml` | **Plugin fallback**: consulted only when `config.yaml` lacks the key. | `default_strategy`, `strategy_constraints`, profile-specific gating (`has_phase_transition`), artifact_types, etc. |
| `skills/roundtable-strategies/SKILL.md` | **Human-facing documentation only**: NOT consumed at runtime. | Strategy descriptions, workflow defaults table (with `> Authoritative source: profiles/` disclaimer), this hierarchy diagram. |

## Worked examples

### Example 1: `/s2s:specs` (no `--strategy`, default config.yaml)

```
CLI --strategy → not set
→ config.yaml.roundtable.strategy.by_workflow_type.specs = "consensus-driven"   ✓ USE
   (profiles/specs.yaml.default_strategy = "consensus-driven"; never consulted because config.yaml resolved)
```

Result: `STRATEGY = "consensus-driven"`.

### Example 2: `/s2s:design --strategy debate`

```
CLI --strategy = "debate"   ✓ USE
   (skips config.yaml lookup; profile.yaml unconsulted)
```

Result: `STRATEGY = "debate"`. CLI wins over config.yaml's default for design (which is also `"debate"`; same result, different resolution path).

### Example 3: `/s2s:roundtable "topic"` (no `--strategy`, no `--workflow-type`)

```
workflow_type = "roundtable" (default when no --workflow-type)
CLI --strategy → not set
→ config.yaml.roundtable.strategy.by_workflow_type.roundtable → not set in default config
                                                              → falls through
→ profiles/roundtable.yaml.default_strategy = "standard"   ✓ USE (plugin fallback)
```

Result: `STRATEGY = "standard"`. This is the path where the profile fallback IS the source.

### Example 4: `/s2s:brainstorm --strategy debate`

```
workflow_type = "brainstorm"
profiles/brainstorm.yaml.strategy_constraints.forced = true   ✓ FORCED OVERRIDE
→ default_strategy = "disney" is used REGARDLESS of CLI
```

Result: `STRATEGY = "disney"`. CLI `--strategy debate` is IGNORED (with warning to user). `forced: true` always wins.

## Error case

If all three sources are exhausted without yielding a strategy:

```
Error: No strategy resolvable for workflow_type='{workflow_type}'.
Checked: CLI --strategy (not set), config.yaml.roundtable.strategy.by_workflow_type[{workflow_type}] (not set), profiles/{workflow_type}.yaml.default_strategy (not set).
Action: pass --strategy explicitly, or set config.yaml.roundtable.strategy.by_workflow_type.{workflow_type}, or report a bug (plugin profile YAML should always have default_strategy set).
```

This error path is defensive; in practice all plugin profile YAMLs ship with `default_strategy` set, so the path triggers only when the user has deleted profile content.

## Related

- ADR-0011 Phase 4 addendum: D3 hierarchy decision and rationale
- `skills/roundtable-strategies/SKILL.md`: human-facing strategy descriptions + this hierarchy summarized
- `skills/roundtable-execution/references/profile-schema.md`: profile YAML field definitions
- `templates/project/config.yaml`: user-canonical configuration template
