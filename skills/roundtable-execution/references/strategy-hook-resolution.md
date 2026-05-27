# Strategy Hook Resolution Fixture

> **Status**: deterministic fixture (TECH-002 Phase 4, Option B)
> **Consumers**: `commands/roundtable.md` Phase 1 "Resolve strategy hooks" parser block; `phase-2-core.md` Step 2.2c 3-branch dispatch via `agent_state.facilitator.hook_overrides`
> **Drift check**: `skills/dev-testing/references/strategy-hook-anchor-check.md` (run before any docs PR touching strategy docs)
> **Disambiguation**: this file is the fixture/parser table; the contract doc is `strategy-hooks.md` (Phase 7B). Different responsibilities.

This file is the **deterministic fixture** consumed by `commands/roundtable.md` Phase 1 strategy-hook resolution (Option B per Phase 4 plan §3.2). Keep in sync with `roundtable-strategies/references/{strategy}.md` `## Strategy hooks` section opening lines. If a strategy doc's opening line changes, the matching regex below MUST be updated to match; the drift check script catches mismatches.

## Two override dict shapes

Two semantically-distinct dict shapes are produced by the parser:

1. **`{skip: true}`**: strategy declares no per-round overrides. Used for `standard`, `consensus-driven`, `disney`, `six-hats` (latter pending baseline). Facilitator emits no overrides at Step 2.2c.
2. **Policy dict** `{participant_response_field: X, round_summary_field: Y, policy: "facilitator_emergent" | <coded_rule>}`: strategy has hooks. Facilitator populates `participant_context.overrides.{participant-id}.{field}` per the policy. Currently only `debate` uses this shape; future six-hats (post baseline) will join.

## Anchor table

For each strategy doc, the parser:
1. Reads `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{strategy}.md`.
2. Extracts the first non-empty line of the `## Strategy hooks` section.
3. Matches against the regex column below; first match wins.
4. Produces the override dict and persists to session.yaml at `agent_state.facilitator.hook_overrides`.

| Strategy | Opening-line regex (matches first non-empty line of `## Strategy hooks`) | Override dict |
|----------|--------------------------------------------------------------------------|----------------|
| `standard` | `^No per-round hooks\.` | `{skip: true}` |
| `consensus-driven` | `^No per-round hooks\.` | `{skip: true}` (same regex as standard; both share opening phrase) |
| `disney` | `^Phase progression determined by` | `{skip: true}` (Step 2.10 phase machine handles transitions; no Step 2.2c overrides emitted) |
| `six-hats` | `^No per-round overrides` | `{skip: true}` (until empirical baseline acquired; post-baseline transitions to policy dict per session-qa) |
| `debate` | `^Facilitator-driven, LLM-emergent` | `{participant_response_field: "debate_role", round_summary_field: "debate_phase", policy: "facilitator_emergent"}` |

> Note on shared regex: `standard` and `consensus-driven` share the regex `^No per-round hooks\.` and the same override dict `{skip: true}`. First-match-wins iteration order is therefore irrelevant for these two rows; both rows are preserved in the table for documentation clarity (one entry per strategy).

## Parser pseudocode

```
# In commands/roundtable.md "Resolve strategy hooks" section.

Read this file's anchor table → ANCHOR_TABLE
Read strategy doc → STRATEGY_DOC
Extract "## Strategy hooks" section → STRATEGY_HOOKS_SECTION
Take first non-empty line → OPENING_LINE

For (regex, override_dict) in ANCHOR_TABLE:
  if regex matches OPENING_LINE:
    HOOK_OVERRIDES = override_dict
    break
else:
  Display error to user: "Strategy doc opening line did not match any anchor in strategy-hook-resolution.md. Edit the doc or update this fixture."
  Stop session creation.

Write HOOK_OVERRIDES to session.yaml at agent_state.facilitator.hook_overrides
```

## 3-branch dispatch (phase-2-core.md Step 2.2c)

At each round, `phase-2-core.md` Step 2.2c reads `session.yaml.agent_state.facilitator.hook_overrides` and dispatches:

| Branch | Trigger | Facilitator agent input | Behavior |
|--------|---------|-------------------------|----------|
| 1 | `hook_overrides.skip == true` | `hook_overrides: {skip: true}` | Emit no per-round overrides (strategy declares no hooks) |
| 2 | policy fields present | full dict | Populate `participant_context.overrides.{participant-id}.{field}` per policy |
| 3 | `hook_overrides` field absent in session.yaml | (key not included in agent input) | Fall back to LLM-emergent inference (pre-Phase-4 resumed session OR generic-mode legacy path) |

## Maintenance

If you edit `roundtable-strategies/references/{strategy}.md` `## Strategy hooks` opening line, you MUST update the corresponding regex in this fixture's anchor table. Run `skills/dev-testing/references/strategy-hook-anchor-check.md` script to validate before merging any docs PR touching strategy docs.

## Related

- ADR-0011 Phase 4 addendum: Option B decision rationale
- `skills/roundtable-execution/references/strategy-hooks.md`: contract doc (Phase 7B) describing the runtime hook fields and their per-strategy contracts
- `skills/roundtable-strategies/references/{strategy}.md`: 5 strategy docs with `## Strategy hooks` sections (opening lines are the load-bearing anchors)
- `commands/roundtable.md`: parser block that consumes this fixture
- `agents/roundtable/facilitator.md`: agent that consumes the resolved overrides at runtime (Hook override consumption section)
