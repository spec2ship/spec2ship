# TECH-002 Phase 8: thin launcher conversion (specs/design/brainstorm)

**Plan ID**: `20260521-tech002-phase8-thin-launchers`
**Branch**: `feature/TECH-002-phase8-thin-launchers`
**Forked from**: `develop` @ `773fb75` (post Phase 4 PR #16 merge)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: draft (self-review rounds 1-2 applied 2026-05-21)
**Created**: 2026-05-21
**Predecessor plan**: `.s2s/plans/20260518-tech002-phase4-roundtable-master.md` (Phase 4, completed)
**Baselines**:
- `.s2s/test-baselines/exp44-{specs,design,brainstorm}-post-phase7b.md` (structural reference, 3 workflows)
- `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md` (roundtable native)
- Phase 4 §4.5 8-run dogfood scoreboard (master path equivalence already proven)

---

## 1. Goal

Collapse `commands/{specs,design,brainstorm}.md` from their current post-Phase-4 sizes (specs 600, design 536, brainstorm 482) into **thin launchers (~150 lines each)** that delegate execution to the `roundtable.md` master. This is the final step of the TECH-002 command-unification arc.

**The substantive work is not the launcher rewrite.** Phase 4 made the master's **PHASE 2** (round loop) profile-driven and capable of all 4 workflow types, but it did **not** touch the master's **PHASE 0-1** (auto-detect + session setup). roundtable.md's PHASE 1 is still roundtable-shaped and, in places, inconsistent with the 3 inline commands (it skips snapshot-file creation that `phase-2-core.md` canonically reads, see §2). The 3 inline commands each have a complete but workflow-specific PHASE 1.

Phase 8 therefore has two coupled deliverables:

- **(a) Generalize the master's PHASE 0+1 to be profile-driven**: the real work. One session-setup path, parametrized by `profiles/{workflow}.yaml`, replacing both roundtable.md's reduced PHASE 1 and the 3 commands' inline PHASE 1.
- **(b) Collapse specs/design/brainstorm into thin launchers**: the mechanical payoff. Once the master's PHASE 0+1 is universal, the launchers keep only what is genuinely workflow-specific and delegate everything else.

Phase 8 delivers five wins:

1. **Command-layer LOC collapse**: ~2097 lines (600 + 536 + 482 + 479) drop to roughly ~1000 (≈150×3 thin launchers + ≈555 master; the master grows because it absorbs the generalized PHASE 1). TECH-002 acceptance criterion #6 satisfied for the command layer.
2. **Single execution path, end to end**: all 4 workflows run PHASE 0 → PHASE 1 → `phase-2-core.md` → completion through one master. Zero inline duplication remains. Acceptance criterion #4 ("skills actually used") becomes structurally airtight, including session setup (not just the round loop).
3. **A latent inconsistency fixed**: roundtable native currently relies on in-context flag variables instead of the `config-snapshot.yaml`/`context-snapshot.yaml` that `phase-2-core.md` documents as canonical inputs. The generalized PHASE 1 makes the master create them for all 4 workflows. Net correctness gain.
4. **Acceptance criterion #3 DONE**: specs/design/brainstorm are thin launchers (~150 lines each).
5. **v0.4.0 → main release unblocked**: Phase 8 is the last item in milestone v0.4.0 (6th of 6).

### Non-goals (explicit deferrals)

- **No behavior change** for any of the 4 workflows. Output must replay structurally identically vs the exp44/exp45 baselines. Any deviation is a regression and the PR cannot merge.
- **No new strategies, no new flags, no flag renames.** Every existing per-command flag is preserved with current semantics.
- **roundtable.md is NOT shrunk into a launcher.** It stays the fat master per the BACKLOG target architecture. Phase 8 generalizes its PHASE 0+1 (+~30 lines) but does not refactor it into a skill.
- **`phase-2-core.md` is not modified.** Phase 8 makes the master *feed* phase-2-core.md the canonical snapshot inputs it already expects; the round-loop algorithm itself is frozen.
- **Six-hats wiring**: still prerequisite-blocked on baseline acquisition. Separate task, unchanged by Phase 8.
- **3 unrelated Phase 4 diagnostic findings** (agent-resume gap, R1 observer false-positive, token-tracker.sh exit 1): out of scope, remain tracked in Phase 4 plan §8. The 4th finding (session_id format divergence) is auto-resolved by Phase 8, see §8.6.

## 2. Inputs and constraints

### What we know (post Phase 4)

- `roundtable.md` master (479 lines) runs all 4 workflow types. Phase 4 §4.5 dogfood proved `/s2s:roundtable --workflow-type {specs,design,brainstorm}` produces output structurally equivalent to the direct commands. But that equivalence currently depends on the executing LLM filling gaps in the master's PHASE 1 from the profile *by inference*, because the PHASE 1 template itself is roundtable-shaped (see below). Phase 8 makes that profile-driven *by construction*, not by inference.
- The 3 commands post Phase 7B already delegate **Phase 2 only** to `phase-2-core.md` (specs.md:452-476 and equivalents). Phase 8 removes the remaining inline scaffolding (PHASE 0 generic parts, PHASE 1 session setup, PHASE 3 completion).
- The master's **completion phase is already workflow-aware**: roundtable.md:463-470 has the per-workflow output dispatch table. No new output wiring needed.
- The **profile schema already carries the PHASE 1 parametrization**: `specs.yaml` has `topic.source: "context-snapshot.project_name"`, `progress.agenda_reference: "references/agenda-specs.md"`, `artifact_types`, `participants`. Phase 4 consumed these in PHASE 2; Phase 8 extends consumption to PHASE 1.

### Finding: the master's PHASE 0+1 is not profile-driven

Static read of the four command files (2026-05-21) shows roundtable.md's PHASE 1 diverges from the 3 inline commands in five concrete ways:

| PHASE 1 concern | roundtable.md (master) | specs/design/brainstorm (inline) | `phase-2-core.md` dependency |
|-----------------|------------------------|----------------------------------|------------------------------|
| Session folder | `mkdir .s2s/sessions` only | `mkdir .s2s/sessions/{id}/` + `rounds/` when verbose | verbose dumps land in `{id}/rounds/` |
| `config-snapshot.yaml` | **not created** | created from config.yaml + flags | **read** for `VERBOSE/DIAGNOSTIC/INTERACTIVE_FLAG`, `limits`, `escalation`, `strategy` (phase-2-core.md L63-65, 176-181, 534, 785-795, 843-849) |
| `context-snapshot.yaml` | **not created** | created from CONTEXT.md (+ input_sources for specs) | **read** for project context (phase-2-core.md L183) |
| `agenda.yaml` | not created | specs/design create it from `agenda-{workflow}.md` | agenda axis source for resume/audit |
| Session-file skeleton | artifacts `{decisions,open_questions,conflicts}`; agenda single `main`; no `metrics.by_state`, no `metrics.topics`, no `validation:` block | artifacts per workflow (specs: 6 types; brainstorm: `phases:`+`current_phase:` not `agenda:`); full `metrics` + `validation:` block | artifact maps must pre-exist for Step 2.x writes |

roundtable native "works" today because roundtable.md PHASE 3 passes `VERBOSE_FLAG`/`DIAGNOSTIC_FLAG`/etc. as in-context variables (roundtable.md:388-392), and `phase-2-core.md` tolerates that as a fallback to its documented "from config-snapshot.yaml" source. This is exactly the kind of drift TECH-002 exists to remove. Phase 8 fixes it: the master creates the canonical snapshot files for **all 4** workflows.

`phase-2-core.md` anticipated this work explicitly. Its §3 closing line (L859) states: *"Phase 1 (init, profile-aware Phase 1 setup) and Phase 3 (output generation) remain inline in each command. They are out of scope for 7B; cleanup deferred to Phase 8."* Phase 8 is the named owner of profile-aware PHASE 1; the profile schema was designed to drive it.

### Other master hardcode sites (workflow_type literals)

- `roundtable.md:108`: fallback grep `grep -l 'workflow_type: roundtable'` (hardcoded scope).
- `roundtable.md:260`: session file body `workflow_type: "roundtable"` (literal).
- `roundtable.md:323`: display banner `Workflow: roundtable` (literal).
- `roundtable.md:346,352`: resume `PHASE 2` state.json `"workflow_type": "roundtable"` (literal).
- `roundtable.md:75`: fast-path checks `workflow_type IN [roundtable, specs, design, brainstorm]` (too broad: a `/s2s:specs` should not be offered a `design` session to resume).

### What is genuinely workflow-specific (stays in the thin launcher)

| Concern | specs | design | brainstorm |
|---------|-------|--------|------------|
| Frontmatter (description, argument-hint, skills) | yes (`iso25010-requirements` skill, `--format`/`--skip-roundtable`) | yes (`--focus`/`--skip-roundtable`) | yes (`topic` + `--participants`) |
| Prerequisite gate | CONTEXT.md populated (not placeholder) | requirements.md absent → warn/continue choice | S2S-init only |
| Smart Source Detection | yes (~60 lines: brainstorm sessions / ideas.md / BACKLOG.md → `INPUT_SOURCES`; `IDEA-*`/`FEAT-*` ID parsing) | no | no |
| Existing-output handling | requirements.md → override/merge/cancel | architecture.md → override/merge/cancel | no |
| Workflow flags | `--format srs\|volere\|simple` | `--focus components\|api\|deployment` | `--participants` |
| Skip-roundtable mode | yes (~6 lines) | yes (~5 lines) | no |

Everything else (generic flag parse, auto-detect, session-id generation, **session folder + snapshot creation, profile-driven session-file skeleton**, Phase 2 round loop, diagnostic report, status update, summary, output dispatch) belongs to the generalized master and is removed from the launchers. Strategy and default output-type are also master-resolved (D3 hierarchy `CLI → config.yaml → profile.default_strategy`, and `workflow_type → output_type` dispatch), so the launcher does **not** pass them.

### Hard constraints

- **Backward-compatible output**. exp44-post-phase7b (specs/design/brainstorm) and exp45-roundtable-native-post-phase4 baselines must replay structurally identically. Verified in §8.5.
- **Generalized session-file skeleton is a superset**. Adding `metrics.by_state` / `validation:` to roundtable native sessions is additive; no field is removed from any workflow's current skeleton.
- **CLI surface frozen**. Every flag of every command keeps current name and semantics. `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` UX is unchanged from the user's perspective.
- **`phase-2-core.md` Step 2.0-2.10 frozen**. Phase 8 changes command files and the master only.
- **Native `/s2s:roundtable` end-to-end unchanged behaviorally**. The generalized PHASE 1 now also creates snapshot files for it (a correctness fix), but artifacts, agenda, rounds, output are identical.
- **No new third-party dependencies**.
- **Atomic PR** → `develop`, milestone v0.4.0 (6th and final milestone item).

## 3. Approach

The architecturally hard decisions were made in Phases 7B (extraction) and 4 (master + Option B). Phase 8 finishes the job: it makes the master's PHASE 0+1 as profile-driven as Phase 4 made PHASE 2, then collapses the 3 commands. Its one genuine design choice is the launcher→master handoff mechanism (§3.1).

### 3.1 Handoff mechanism: Pattern 1 (delegate to master) vs Pattern 2 (shared core skill)

| Criterion | Pattern 1: launcher Read-and-follows `commands/roundtable.md` | Pattern 2: extract the master's generic orchestration into `roundtable-execution/references/command-orchestration.md`; all 4 commands Read it |
|-----------|---------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| **Matches BACKLOG target architecture** | Yes (roundtable.md = fat master ~510; others = thin launchers) | No (roundtable.md would also become thin, contradicting "roundtable.md ~600 lines full implementation") |
| **Reuses Phase 4 deliverable** | Yes (roundtable.md master consumed as-is + generalized) | Partially (master's body migrates into a new skill file) |
| **Blast radius** | Medium: 3 launchers rewritten + master PHASE 0+1 generalized | High: master gutted into a skill ref + 4 commands rewired + new reference file + regression surface on roundtable native |
| **Precedent in codebase** | `phase-2-core.md` is a non-command file Read-and-followed by commands; Reading `roundtable.md` the same way is mechanically identical | `phase-2-core.md` itself is this pattern, applied to the *whole* orchestration |
| **Reversibility** | Easy (launchers are small) | Hard (master decomposition is a one-way refactor) |
| **Anti-pattern risk** | A command Reading another command file is unusual; mitigated because it is a plain `Read`, not a `SlashCommand` invocation (async, per CLAUDE.md) | Cleaner separation (no command Reads a command) |

**Recommendation: Pattern 1.** It matches the BACKLOG target architecture and Phase 4's design intent (roundtable.md *is* the master), and the PHASE 1 generalization is needed under either pattern. Pattern 2 additionally re-homes the whole master body into a skill, which is more regression surface for no behavioral gain. Pattern 2 is recorded as the rejected alternative; if Pattern 1's "command Reads a command" proves awkward in dogfood, Pattern 2 is the documented escalation.

### 3.2 Thin launcher anatomy (Pattern 1)

Each thin launcher executes, in order:

1. **`## Context` block**: `pwd`, `ls -la`, `date` timestamp, ISO timestamp. This block MUST be a superset of what `roundtable.md`'s own Context block provides, because Read-and-follow does **not** re-execute the master's `!`-prefixed directives (they run only when a file is invoked as a slash command). The launcher's Context block is the single context-capture point. (Risk R1.)
2. **`## Interpret Context`**: S2S-init check; workflow-specific file reads (CONTEXT.md, requirements.md).
3. **Parse session flags**: `--session`, `--new`. **If `--session` is present, delegate to the master immediately** (skip steps 4-6): resume must not be gated behind new-session prerequisite checks, matching today's specs.md:39-42 ordering.
4. **Workflow-specific Phase 0 prep** (new-session path only): prerequisite gate; Smart Source Detection (specs only); existing-output override/merge/cancel.
5. **Parse workflow-specific flags**: `--format` (specs), `--focus` (design), `--participants` (brainstorm), `--skip-roundtable` (specs/design).
6. **`--skip-roundtable` branch**: if present, run the inline skip mode and exit. Unchanged logic, kept in the launcher (workflow-specific, never touches the master).
7. **Set handoff variables** (minimal contract, simplified in review round 2): `WORKFLOW_TYPE` (mandatory), plus only values the master cannot derive from `workflow_type` + profile: `INPUT_SOURCES` (specs, a source-detection result), `OUTPUT_MERGE_MODE` (specs/design, an existing-output decision), `OUTPUT_FORMAT` (specs `--format`), `FOCUS_AREA` (design `--focus`). Strategy and default output-type are NOT passed: the master resolves strategy via the D3 hierarchy and output-type from `workflow_type`.
8. **Delegate**: Read `${CLAUDE_PLUGIN_ROOT}/commands/roundtable.md` and follow it from `PHASE 0`, treating the invocation as if `--workflow-type {WORKFLOW_TYPE}` were passed.

The launcher does **not** auto-detect sessions itself (Risk R2): auto-detect lives entirely in the master's PHASE 0, scoped to `WORKFLOW_TYPE` after §8.1.

### 3.3 Master generalization: profile-driven PHASE 0+1 (§8.1, the keystone)

The master's PHASE 0 and PHASE 1 become driven by `profiles/{workflow}.yaml` for all 4 workflow types:

- **Session folder + snapshots**: master creates `.s2s/sessions/{id}/` (+ `rounds/` when verbose/diagnostic), `config-snapshot.yaml` (config.yaml + resolved flags, **all** workflows), `context-snapshot.yaml` (CONTEXT.md + `INPUT_SOURCES` handoff var), and `agenda.yaml` when `PROFILE.progress.agenda_reference` is set.
- **Profile-driven session-file skeleton**: `topic` per `PROFILE.topic` (`source: cli-arg.topic` uses the CLI topic; `source: context-snapshot.*` synthesizes via `pattern`); the "Validate topic" prompt fires only when `source == cli-arg.topic` and no topic was given. `artifacts:` block from `PROFILE.artifact_types` (one empty map per `session_key`). Progress block discriminated by `PROFILE.progress.axis`: `axis: agenda` builds `agenda:` (multi-topic from `agenda_reference`, or single `main` when absent) + `metrics.topics`; `axis: disney_phase` builds `phases:` + `current_phase:` + `metrics.phases`. `metrics` always includes `by_state`; `validation:` block always present.
- **Runtime-context alignment**: roundtable.md's caller-side "Set runtime context" block (PHASE 3) is rewritten to read `VERBOSE/DIAGNOSTIC/INTERACTIVE_FLAG` from `config-snapshot.yaml`, matching `phase-2-core.md` §3, instead of the current undocumented in-context-variable shortcut.
- **workflow_type resolution + parametrization**: workflow_type resolves as handoff `WORKFLOW_TYPE` → `--workflow-type` flag → default `roundtable` for new sessions, and from the session file on resume. The 5 hardcode sites from §2 (L260 session file, L323 banner, L346/352 resume state.json, L108 grep, L75 fast-path scope) use the resolved value.
- **`## Invocation modes` contract note**: a new section near the top of roundtable.md documenting native vs delegated entry and the minimal handoff-variable contract (§3.2 step 7).

When invoked natively, `WORKFLOW_TYPE` defaults to `roundtable`; the generalized skeleton resolves through `profiles/roundtable.yaml` to the same artifacts/agenda roundtable native produces today, plus the additive `by_state`/`validation`/snapshot files. Native behavior is a superset, not a change. Re-verified in §8.5.

### 3.4 Work breakdown

Phase 8 delivers in 7 sub-phases over an estimated **~8.5 hours**:

- **8.0** audit (~1.25h): reconcile the 4 PHASE 1 variants into one canonical profile-driven skeleton; confirm which snapshot files `phase-2-core.md` consumes and where; per-command keep/delete inventory; finalize the handoff contract; capture pre-Phase-8 line counts; write the audit file.
- **8.1** master generalization (~2.5h): profile-driven PHASE 0+1 (folder + snapshots + session-file skeleton); workflow_type parametrization (5 sites); `## Invocation modes` note. The keystone sub-phase.
- **8.2** specs thin launcher (~1.25h).
- **8.3** design thin launcher (~1h).
- **8.4** brainstorm thin launcher (~0.75h).
- **8.5** regression replay (~1.25h): dogfood all 4 workflows via thin launchers + roundtable native; structural compare to exp44/exp45 baselines; backward-compat resume probe.
- **8.6** close-out (~0.5h): BACKLOG, ADR-0011 Phase 8 addendum, plan Status, MEMORY, refreshed line-count table, v0.4.0 release-readiness note.

## 4. Sub-phases

**Execution order**: 8.0 → 8.1 → 8.2 → 8.3 → 8.4 → 8.5 → 8.6.

(8.1 precedes the launcher rewrites: a launcher cannot be regression-tested against a master whose PHASE 1 is not yet profile-driven.)

### 8.0: audit current state (~1.25h)

**Status**: COMPLETED 2026-05-21. Output: `.s2s/plans/20260521-tech002-phase8-8.0-audit.md`. Empirical finding: master-path dogfood sessions (exp49/51/52) carry the correct `workflow_type` but **no snapshot files** (round-1 finding proven). Canonical skeleton + snapshot spec + handoff contract frozen; Smart Source Detection stays inline.

**Goal**: produce a definitive inventory so 8.1 is generalization-by-spec, not redesign-in-flight.

**Actions**:
1. **Reconcile the 4 PHASE 1 variants** into one canonical profile-driven session-file skeleton + snapshot set. Tabulate every field of each command's session file and snapshot files; classify each as common / axis-specific / workflow-specific; map each to the profile field that drives it.
2. **Snapshot-consumption audit**: grep `phase-2-core.md` and the agents for every read of `config-snapshot.yaml`, `context-snapshot.yaml`, `agenda.yaml`. Confirm whether `agenda.yaml` is still consumed at runtime or is resume/audit-only. Decide: master creates it always / only when `agenda_reference` set / never.
3. For each of specs/design/brainstorm, classify every section as keep-in-launcher or delete-delegate, with a per-command line-range table.
4. Re-verify the 5 master hardcode sites against an actual Phase 4 dogfood session file (an `exp49`/`exp51`/`exp52` `--workflow-type` run if the worktree survives; else static read). Record whether the written `workflow_type` field is correct or stale.
5. Finalize the handoff-variable contract (names, setter, master consumption point). Decide whether `--focus` (design) feeds only output or also the facilitator's discussion context.
6. Decide specs Smart Source Detection placement: inline (~150-180 line budget) vs extract to `roundtable-execution/references/specs-source-detection.md` (keeps specs.md ≤150). Record rationale.
7. Capture pre-Phase-8 line counts; write `.s2s/plans/20260521-tech002-phase8-8.0-audit.md`.

**Exit condition**: audit file exists; canonical skeleton + snapshot spec frozen; every line of the 3 commands classified keep/delete; 5 hardcode sites confirmed; handoff contract frozen.

### 8.1: generalize roundtable.md master, profile-driven PHASE 0+1 (~2.5h)

**Status**: COMPLETED 2026-05-21. `commands/roundtable.md` 479 → 587 lines (≤600). All 7 actions applied: `## Invocation modes` note; workflow_type resolution + 5 hardcode sites parametrized; profile load in PHASE 1; profile-driven `Create session` (folder + 3 snapshots + profile-driven skeleton, 4 ordered steps); runtime-context alignment to `config-snapshot.yaml`; PHASE 2 resume reads `workflow_type` from session file. Native smoke check (action 7) is a runtime test, deferred to §8.5 dogfood.

**Goal**: one session-setup path for all 4 workflows; native roundtable behavior preserved as a superset.

**Actions**:
1. **Session folder + snapshots**: master PHASE 1 creates `.s2s/sessions/{id}/` (+ `rounds/` on verbose/diagnostic); writes `config-snapshot.yaml`, `context-snapshot.yaml`, and `agenda.yaml` (per 8.0 step 2 decision) for all workflow types.
2. **Profile-driven session-file skeleton** per §3.3: `topic` per `PROFILE.topic`; `artifacts:` from `PROFILE.artifact_types`; progress block discriminated by `PROFILE.progress.axis` (`agenda` → `agenda:` + `metrics.topics`; `disney_phase` → `phases:`/`current_phase:` + `metrics.phases`); `metrics.by_state` + `validation:` block always.
3. **Runtime-context alignment**: rewrite roundtable.md PHASE 3 "Set runtime context" to read `VERBOSE/DIAGNOSTIC/INTERACTIVE_FLAG` from `config-snapshot.yaml`, matching `phase-2-core.md` §3 (removes the undocumented context-variable shortcut).
4. **workflow_type resolution + parametrization**: resolve workflow_type (handoff var → `--workflow-type` → default `roundtable` for new; session file on resume); fix the 5 hardcode sites (L260, L323, L346/352, L108 grep, L75 fast-path) to use it.
5. **`## Invocation modes`** section: native vs delegated entry; minimal handoff-variable contract; note that "Validate topic" prompts only when `PROFILE.topic.source == cli-arg.topic`.
6. **Verify** Phase 4 output dispatch table (L463-470) still covers all 4 workflows (no change expected).
7. **Native smoke check**: run `/s2s:roundtable "..." --diagnostic`; confirm session folder + snapshots created, artifacts/agenda/rounds identical to `exp45-roundtable-native-post-phase4.md` modulo additive fields.

**Exit condition**: master PHASE 0+1 fully profile-driven; one session-setup path serves all 4 workflows; native roundtable re-verified as superset-equivalent; `wc -l commands/roundtable.md` ≤ 600 (BACKLOG-sanctioned master budget); no hardcoded `workflow_type` literal where a parameter belongs.

### 8.2: convert specs.md to thin launcher (~1.25h)

**Status**: COMPLETED 2026-05-21. `commands/specs.md` 600 → 172 lines (≤180). Smart Source Detection kept inline per 8.0 §7.

**Goal**: `commands/specs.md` ~150 lines, delegating to the master.

**Actions**:
1. Keep: frontmatter; Context + Interpret Context; parse `--session`/`--new` (delegate immediately on `--session`); Check prerequisites (CONTEXT.md populated); Smart Source Detection (or its Read pointer per 8.0 step 6); Check existing requirements.md (override/merge/cancel); parse `--format`/`--skip-roundtable`; Skip Roundtable Mode.
2. Delete: generic flag parse, auto-detect, PHASE 1 Session Setup (snapshots, session file, folder), Phase 2 inline block, Phase 3 Completion.
3. Add the handoff block (§3.2 steps 7-8): `WORKFLOW_TYPE=specs`, carry `INPUT_SOURCES`/`OUTPUT_MERGE_MODE`/`OUTPUT_FORMAT`; Read and follow `roundtable.md`. Strategy (`consensus-driven`) and output-type (`requirements`) are resolved by the master from `profiles/specs.yaml` + workflow_type, not passed.
4. `wc -l` budget: ≤180 (≤150 if Smart Source Detection extracted per 8.0 step 6).

**Exit condition**: specs.md ≤180 lines; no inline Phase 1/2/3.

### 8.3: convert design.md to thin launcher (~1h)

**Status**: COMPLETED 2026-05-21. `commands/design.md` 536 → 114 lines (≤150).

**Actions**:
1. Keep: frontmatter; Context + Interpret; parse `--session`/`--new`; Check prerequisites (requirements.md absent → warn/continue); Check existing architecture.md (override/merge/cancel); parse `--focus`/`--skip-roundtable`; Skip Roundtable Mode.
2. Delete: same generic blocks as §8.2.
3. Handoff: `WORKFLOW_TYPE=design`, carry `OUTPUT_MERGE_MODE`/`FOCUS_AREA`. Strategy (`debate`) and output-type (`architecture`) resolved by the master from `profiles/design.yaml`.
4. `wc -l` budget: ≤150.

**Exit condition**: design.md ≤150 lines; no inline Phase 1/2/3.

### 8.4: convert brainstorm.md to thin launcher (~0.75h)

**Actions**:
1. Keep: frontmatter; Context + Interpret; parse `--session`/`--new`; Validate environment; parse `topic`/`--participants`; the Disney intro display (optional, workflow-flavored UX, keep ~8 lines).
2. Delete: same generic blocks; brainstorm has no prereq doc, no existing-output check, no skip-roundtable mode, so it is the cleanest conversion.
3. Handoff: `WORKFLOW_TYPE=brainstorm`, carry `--participants` override. Strategy (`disney`, forced by `profiles/brainstorm.yaml` `strategy_constraints.forced`) and output-type (`summary`) resolved by the master.
4. `wc -l` budget: ≤130.

**Exit condition**: brainstorm.md ≤130 lines; no inline Phase 1/2/3.

### 8.5: regression replay + backward-compat probe (~1.25h)

**Goal**: confirm zero behavioral regression across all 4 workflows.

**Actions**:
1. Dogfood replay (ElfGiftRush_s2s worktrees, per `project_dogfood_test_env`):
   - `/s2s:specs "..."` → structural compare to `exp44-specs-post-phase7b.md`.
   - `/s2s:design "..."` → compare to `exp44-design-post-phase7b.md`.
   - `/s2s:brainstorm "..."` → compare to `exp44-brainstorm-post-phase7b.md`.
   - `/s2s:roundtable "..." --diagnostic` (native) → compare to `exp45-roundtable-native-post-phase4.md` (allowing additive `by_state`/`validation`/snapshot files).
2. Verify each run creates the session folder + `config-snapshot.yaml` + `context-snapshot.yaml`, a session file with the **correct** `workflow_type`, and a `{ts}-{workflow_type}-{slug}` id.
3. **Backward-compat resume probe** (folds in Phase 4 plan §6 deferred item): resume a pre-Phase-8 specs/design/brainstorm session via the thin launcher; assert the master's resume path (Phase 4 §4.3 step 4) handles it without error.
4. `--skip-roundtable` probe: `/s2s:specs --skip-roundtable` and `/s2s:design --skip-roundtable` produce output without entering the round loop.
5. Acceptable deltas: additive session-file fields for roundtable native; session-id format now uniform across all paths (resolves Phase 4 §8 finding #4). Unacceptable deltas: any artifact-schema change, missing artifacts, Phase 2 numbering change, removed session-file field, all of which block the PR.

**Exit condition**: 4 baselines match structurally; snapshots created for all workflows; resume probe passes; skip-roundtable passes.

### 8.6: close-out (~0.5h)

**Actions**:
1. `.s2s/BACKLOG.md` TECH-002 block: Phase 8 row → ✅ completed; acceptance criteria #3 and #6 marked DONE; refresh the line-count table with **actuals**; update "Current state" block; set TECH-002 status `completed`.
2. `.s2s/decisions/0011-roundtable-command-unification.md` Phase 8 addendum: Pattern 1 handoff decision; **PHASE 0+1 profile-driven generalization** (the keystone); snapshot-creation consistency fix; final architecture (1 master + 3 thin launchers); final LOC table; session_id divergence resolved.
3. Plan Status: `draft` → `completed (PR #XX merged YYYY-MM-DD)` post-merge.
4. `MEMORY.md` `project_tech002_progress.md`: TECH-002 complete; v0.4.0 ready for `develop → main`; index entry updated.

**Exit condition**: BACKLOG + ADR + plan + memory consistent with post-Phase-8 state; v0.4.0 release-readiness explicitly stated.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Read-and-follow does not execute the master's `## Context` `!` directives; the master runs without pwd/ls/timestamp | high | high | §3.2: the launcher's Context block is the single capture point and must be a superset of the master's. §8.0 audits this; §8.5 dogfood is the proof. |
| R2 | Launcher and master both run auto-detect → double prompt or conflicting resume | medium | medium | §3.2: launcher does NO auto-detect; it lives entirely in master PHASE 0, scoped to `WORKFLOW_TYPE` after §8.1. |
| R3 | specs.md cannot reach ~150 lines with Smart Source Detection inline (~60 lines) | medium | low | §8.0 step 6 decides: inline (budget ≤180) or extract to a skill reference (≤150). Budget is a soft target. |
| R4 | Workflow-specific flags (`--format`, `--focus`) consumed by the launcher never reach output generation in the master | medium | medium | Handoff-variable contract (§3.2 step 7) carries `OUTPUT_FORMAT`/`FOCUS_AREA`; §8.0 step 5 finalizes consumption points; §8.5 verifies output. |
| R5 | Behavioral regression: thin-launcher output differs from baseline | low | high | §8.5 dogfood replay is the merge gate. Master path equivalence was already proven in Phase 4 §4.5. |
| R6 | `--skip-roundtable` path diverges after the rewrite | low | medium | Skip mode kept inline in the launcher, logic copied verbatim, never touches the master. §8.5 step 4 probes it. |
| R7 | PHASE 1 generalization changes the roundtable-native session-file shape and breaks `exp45` replay | medium | high | §3.3: the generalized skeleton is a strict superset (additive `by_state`/`validation`/snapshots); profile-driven so `roundtable.yaml` yields the same artifacts/agenda. §8.1 step 6 native smoke check + §8.5 step 1 are the gates. |
| R8 | Resume of a pre-Phase-8 specs/design/brainstorm session via the thin launcher fails | low | medium | Master resume already extended to all workflow_types in Phase 4 §4.3 step 4. §8.5 step 3 probes it explicitly. |
| R9 | "Command Reads a command" turns out brittle at runtime | low | medium | Mechanically identical to Reading `phase-2-core.md`. If it fails, §3.1 Pattern 2 is the documented escalation. |
| R10 | Master now creating `config-snapshot.yaml`/`context-snapshot.yaml` for roundtable native exposes a `phase-2-core.md` path that behaved differently with the in-context-variable fallback | medium | medium | §8.0 step 2 maps every snapshot read; §8.1 step 6 native smoke check compares dump shapes; the snapshot path is the one `phase-2-core.md` already documents as canonical, so this aligns rather than diverges. |
| R11 | 8.1 master generalization is the largest single change (~2.5h) and its regression surface spans all 4 workflows | medium | high | Sequenced first (8.1 before any launcher); §8.1 step 6 native check before the launcher rewrites; if 8.1 destabilizes, launchers are not yet touched and the phase can pause cleanly. |

## 6. Done criteria

- [x] 8.0 audit file produced (`.s2s/plans/20260521-tech002-phase8-8.0-audit.md`); canonical profile-driven session-file skeleton + snapshot spec frozen; snapshot-consumption mapped; per-command keep/delete classification complete; 5 hardcode sites confirmed empirically; handoff contract frozen; Smart Source Detection placement decided (inline).
- [x] roundtable.md master PHASE 0+1 generalized: profile-driven folder + snapshot creation (all 4 workflows); profile-driven session-file skeleton (artifacts / agenda-or-phases / metrics+by_state / validation); `workflow_type` parametric at 5 sites; `## Invocation modes` contract note added. (roundtable.md 479 → 587 lines)
- [ ] §8.1 native smoke check: `/s2s:roundtable --diagnostic` creates session folder + 3 snapshots; artifacts/agenda/rounds match `exp45` modulo additive fields. (runtime test, executed in §8.5)
- [x] `commands/specs.md` is a thin launcher, `wc -l` = 172 (≤180); no inline Phase 1/2/3.
- [x] `commands/design.md` is a thin launcher, `wc -l` = 114 (≤150); no inline Phase 1/2/3.
- [ ] `commands/brainstorm.md` is a thin launcher, `wc -l` ≤ 130; no inline Phase 1/2/3.
- [ ] All per-command flags preserved with current semantics (`--format`, `--focus`, `--skip-roundtable`, `--participants`, plus the generic set).
- [ ] §8.5 regression: exp44 specs/design/brainstorm + exp45 roundtable-native baselines replay structurally identically (additive fields allowed).
- [ ] §8.5: each thin-launcher session carries the correct `workflow_type`, a `{ts}-{workflow_type}-{slug}` id, and the session folder + snapshot files.
- [ ] §8.5: backward-compat resume probe passes; `--skip-roundtable` probe passes for specs and design.
- [ ] `.s2s/BACKLOG.md`: Phase 8 ✅; TECH-002 `completed`; acceptance criteria #3 and #6 DONE; line-count table refreshed with actuals.
- [ ] ADR-0011 Phase 8 addendum recorded (Pattern 1 + PHASE 0+1 generalization + snapshot consistency fix + final architecture + LOC table).
- [ ] MEMORY `project_tech002_progress.md` updated: TECH-002 complete, v0.4.0 ready for develop → main.
- [ ] PR opened against `develop`, milestone v0.4.0.
- [ ] Plan `Status` updated to `completed (PR #XX merged YYYY-MM-DD)` post-merge.

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase8-thin-launchers` → `develop`, milestone v0.4.0.

Commit structure:

1. `chore(plans): finalize TECH-002 Phase 4 plan status post PR #16 merge` (done, `048e2d2`)
2. `docs(plans): draft TECH-002 Phase 8 thin-launcher plan` (done, `2a173cf`) + self-review refinement commit
3. `docs(plans): TECH-002 Phase 8.0 audit` (8.0)
4. `feat(roundtable): generalize master PHASE 0+1 as profile-driven` (8.1)
5. `refactor(commands): convert specs.md to thin launcher` (8.2)
6. `refactor(commands): convert design.md to thin launcher` (8.3)
7. `refactor(commands): convert brainstorm.md to thin launcher` (8.4)
8. `test(baselines): Phase 8 regression replay + backward-compat resume probe` (8.5)
9. `docs(adr,backlog,plan): close TECH-002 Phase 8, ADR-0011 Phase 8 addendum` (8.6)

PR body must include: link to plan + 8.0 audit; Pattern 1 handoff decision with §3.1 matrix; the PHASE 0+1 generalization summary; before/after `wc -l` for all 4 commands; regression deltas table; explicit "v0.4.0 ready for develop → main" statement.

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **v0.4.0 → main release**: after Phase 8 merges, open the `develop → main` release PR and tag `v0.4.0` (tags only on main, per `project_release_flow`). §9 exit action, not a Phase 8 deliverable.
- **3 unrelated Phase 4 diagnostic findings**: agent-resume gap, R1 observer false-positive on empty artifact maps, token-tracker.sh exit 1 quirk. Remain tracked in Phase 4 plan §8.
- **Six-hats wiring**: prerequisite-blocked on empirical baseline acquisition. Separate task.
- **Pattern 2 (shared core skill)**: documented escalation if Pattern 1's command-Reads-command proves awkward. Post-v0.4.0.
- **specs Smart Source Detection as a reusable skill**: if §8.0 extracts it, design/brainstorm could later opt into source detection. Post-v0.4.0.

## 9. Exit pointer

After Phase 8 PR merges to develop:
- `.s2s/BACKLOG.md`: TECH-002 `in_progress` → `completed`; all 6 acceptance criteria checked.
- MEMORY `project_tech002_progress.md`: TECH-002 done; v0.4.0 ready.
- Open the `develop → main` release PR for **v0.4.0** (Phases 0, 1, 5, 6, 6b, 2, 3, 7B, 7-lite, 4, 8). Tag `v0.4.0` on main per `project_release_flow`.
- Close milestone v0.4.0 (Phase 8 was the 6th and final item).

TECH-002 is the last work item gating v0.4.0. Phase 8 completes the command-unification arc started 2026-01-20.

## 10. Contract invariants (must NOT change)

- **All 4 workflows replay structurally**. exp44 + exp45 baselines remain valid; no artifact-schema change, no removed session-file field. Additive fields (`metrics.by_state`, `validation:`, snapshot files) for roundtable native are permitted and expected.
- **`phase-2-core.md` Step 2.0-2.10 frozen**. Phase 8 touches command files and the master only; it feeds phase-2-core.md the canonical snapshot inputs it already expects.
- **CLI surface frozen**. No flag added, removed, or renamed for any of the 4 commands.
- **Native `/s2s:roundtable` behavior preserved**. The generalized PHASE 1 is parameter-neutral for the native path; new snapshot files are a correctness fix, not a behavior change.
- **`profiles/*.yaml` schema not changed**. Round-2 verification confirmed the profiles already carry every field PHASE 1 needs (`topic.pattern`/`topic.source`, `artifact_types[].session_key`, `progress.axis`/`agenda_reference`/`agenda_count`, `participants`, `default_strategy`, `strategy_constraints`). Phase 8 only *consumes* them. If §8.0 still finds a gap, any change is additive only and flagged in the audit.
- **`output-generation/`, `roundtable-strategies/`, `agents/` untouched**. Phase 8 is a command-layer plus master refactor.
- **`strategy_constraints.forced` still wins** (brainstorm `disney` forced): the thin launcher's `DEFAULT_STRATEGY_FALLBACK` is a fallback, not an override.

If any of these is violated, that is a regression and the PR cannot merge.
