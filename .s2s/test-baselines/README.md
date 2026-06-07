# Test baselines

Structural fingerprints of dogfood regression runs, used to verify that refactors do not change observable workflow behavior.

Spec2Ship has no automated test suite (markdown/YAML plugin), so regression confidence comes from running real `/s2s:*` workflows and comparing outputs across code states. See [CONTRIBUTING.md → Regression testing (dogfood)](../../CONTRIBUTING.md#regression-testing-dogfood) for the method.

## What lives here vs. in the dogfood repo

Test artifacts are split across two locations:

| Artifact | Where | Why |
|----------|-------|-----|
| **Raw session data, verbose dumps, generated requirements/architecture/ideas** | the dogfood repo (separate, no public remote) | domain content + large, noisy, run-specific; not useful to a public reader |
| **Structural summary** (this folder) | `spec2ship/.s2s/test-baselines/` | schema invariants + metric tables + findings status; enough to re-run a regression check without exposing domain content |

A structural summary contains: dump file counts, schema/field invariants, metric deltas (rounds, tokens), agenda/phase progression, and findings status. It contains **no** domain-specific prose (no requirements text, no game design, no NFR wording).

Each structural summary references the raw run's commit SHA in the dogfood repo, so the full data is auditable without being committed here.

## Naming

```
exp{N}-{workflow}-{pre|post}-{phase}.md
```

Examples:
- `exp42-specs-pre-phase3.md`: specs run captured before TECH-002 Phase 3
- `exp44-design-post-phase7b.md`: design run after Phase 7B deep extraction
- `exp45-roundtable-native-pre-phase4.md`: native roundtable before Phase 4

`exp{N}` matches the worktree name in the dogfood repo (one worktree per experiment). Pairing a `pre` and `post` summary for the same workflow gives the before/after regression comparison.

## How to use for a refactor

1. Capture a baseline run in a fresh experiment worktree; write its structural summary here as `exp{N}-{workflow}-pre-{phase}.md`.
2. Land the refactor.
3. Replay the same workflow in another worktree synced to the same init point; write `exp{M}-{workflow}-post-{phase}.md`.
4. Compare the two summaries on schema/metric invariants. Text variance is expected (LLM nondeterminism); structural divergence is the signal.
