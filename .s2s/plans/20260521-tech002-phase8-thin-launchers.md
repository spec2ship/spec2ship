# TECH-002 Phase 8: thin launcher conversion (specs/design/brainstorm)

**Plan ID**: `20260521-tech002-phase8-thin-launchers`
**Branch**: `feature/TECH-002-phase8-thin-launchers`
**Forked from**: `develop` @ `773fb75` (post Phase 4 PR #16 merge)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: draft
**Created**: 2026-05-21
**Predecessor plan**: `.s2s/plans/20260518-tech002-phase4-roundtable-master.md` (Phase 4, completed)
**Baselines**:
- `.s2s/test-baselines/exp44-{specs,design,brainstorm}-post-phase7b.md` (structural reference, 3 workflows)
- `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md` (roundtable native)
- Phase 4 §4.5 8-run dogfood scoreboard (master path equivalence already proven)

---

## 1. Goal

Collapse `commands/{specs,design,brainstorm}.md` from their current post-Phase-4 sizes (specs 600, design 536, brainstorm 482) into **thin launchers (~150 lines each)** that delegate execution to the `roundtable.md` master built in Phase 4. Each thin launcher keeps only what is genuinely workflow-specific (frontmatter, prerequisite gates, source detection, existing-output handling, skip-roundtable mode) and hands off the generic orchestration (auto-detect, session setup, Phase 2 round loop, completion) to the master.

Phase 4 made `roundtable.md` *capable* of running all 4 workflow types but left specs/design/brainstorm inline (explicitly Phase 8 territory, plan §4.3 exit condition). Phase 8 is the downstream consumer that finally removes the inline duplication.

Phase 8 also **hardens `roundtable.md` to be genuinely workflow-type-parametric**. Phase 4 left the master with hardcoded `roundtable` literals in three write sites and one grep scope. Native `/s2s:roundtable` works because its `workflow_type` defaults to `roundtable`, but a thin `/s2s:specs` delegating to the master needs those sites parametrized. This is surfaced and quantified in §8.0 audit and fixed in §8.1.

Phase 8 delivers five concrete wins:

1. **Command-layer LOC collapse**: ~2097 lines (600 + 536 + 482 + 479) drop to ~920 (~150×3 + ~490). TECH-002 acceptance criterion #6 ("total command lines reduced") satisfied for the command layer.
2. **Single execution path**: all 4 workflows run through `roundtable.md` → `phase-2-core.md`. Zero inline Phase 2 / Phase 3 duplication remains in any command. Acceptance criterion #4 ("skills actually used") becomes structurally airtight.
3. **roundtable.md genuinely workflow-parametric**: 4 hardcoded `roundtable` sites fixed; auto-detect scoped to the invoked workflow_type.
4. **Acceptance criterion #3 DONE**: specs/design/brainstorm are thin launchers (~150 lines each).
5. **v0.4.0 → main release unblocked**: Phase 8 is the last item in milestone v0.4.0 (6th of 6).

### Non-goals (explicit deferrals)

- **No behavior change** for any of the 4 workflows. Output must replay structurally identically vs the exp44/exp45 baselines. Any deviation is a regression and the PR cannot merge.
- **No new strategies, no new flags, no flag renames.** Every existing per-command flag is preserved with current semantics.
- **roundtable.md is NOT shrunk into a launcher.** It stays the fat master per the BACKLOG target architecture. Phase 8 only hardens it (~+10-15 lines), it does not refactor it.
- **Six-hats wiring**: still prerequisite-blocked on baseline acquisition. Separate task, unchanged by Phase 8.
- **The 3 unrelated Phase 4 diagnostic findings** (agent-resume gap, R1 observer false-positive, token-tracker.sh exit 1): out of scope, remain tracked in Phase 4 plan §8. The 4th finding (session_id format divergence) is auto-resolved by Phase 8, see §8.6.

## 2. Inputs and constraints

### What we know (post Phase 4)

- `roundtable.md` master (479 lines) runs all 4 workflow types via uniform dispatch (Phase 4 §4.3): Phase 0 auto-detect → Phase 1 setup → Phase 3 round loop (`phase-2-core.md`) → Phase 4 completion. Profiles `profiles/{specs,design,brainstorm,roundtable}.yaml` all exist.
- Phase 4 §4.5 dogfood **already proved** `/s2s:roundtable --workflow-type {specs,design,brainstorm}` produces output structurally equivalent to the direct commands (Steps 2/6/8 PASS). The master *can* run all workflows; Phase 8 only needs the thin launchers to delegate to it.
- The 3 commands post Phase 7B already delegate **Phase 2 only** to `phase-2-core.md` (specs.md:452-476 and equivalents). Phase 8 removes the remaining inline scaffolding (Phase 0 generic parts, Phase 1 session setup, Phase 3 completion) by delegating to `roundtable.md`.
- The master's completion phase is **already workflow-aware**: roundtable.md:463-470 has the per-workflow output dispatch table and reads `output-generation/SKILL.md`. No new output wiring needed.
- **Master hardcode sites** (confirmed by static read 2026-05-21, to be re-verified against a dogfood session file in §8.0):
  - `roundtable.md:108`: fallback grep `grep -l 'workflow_type: roundtable'` (hardcoded scope).
  - `roundtable.md:260`: session file body `workflow_type: "roundtable"` (literal, not `{workflow_type}`).
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
| Default-strategy fallback | `consensus-driven` | `debate` | `disney` |
| Workflow flags | `--format srs\|volere\|simple` | `--focus components\|api\|deployment` | `--participants` |
| Skip-roundtable mode | yes (~6 lines) | yes (~5 lines) | no |

Everything else (generic flag parse, auto-detect, session-id generation, session file creation, snapshot files, Phase 2 round loop, diagnostic report, status update, summary, output dispatch) is **already in `roundtable.md`** and is removed from the launchers.

### Hard constraints

- **Backward-compatible output**. exp44-post-phase7b (specs/design/brainstorm) and exp45-roundtable-native-post-phase4 baselines must replay structurally identically. Verified in §8.5.
- **CLI surface frozen**. Every flag of every command keeps current name and semantics. `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` invocation UX is unchanged from the user's perspective.
- **State machine frozen**. `phase-2-core.md` Step 2.0-2.10 untouched. Phase 8 changes command files and the master only.
- **Native `/s2s:roundtable` unaffected**. Master hardening must leave `workflow_type` defaulting to `roundtable` when invoked natively, producing identical results.
- **No new third-party dependencies**.
- **Atomic PR** → `develop`, milestone v0.4.0 (6th and final milestone item).

## 3. Approach

Phase 8 is the mechanical completion of TECH-002's command-unification arc. The architecturally hard decisions were made in Phases 7B (extraction) and 4 (master + Option B). Phase 8's only genuine design choice is the launcher→master handoff mechanism (§3.1); the rest is disciplined deletion plus a small master hardening pass.

### 3.1 Handoff mechanism: Pattern 1 (delegate to master) vs Pattern 2 (shared core skill)

| Criterion | Pattern 1: launcher Read-and-follows `commands/roundtable.md` | Pattern 2: extract master's generic orchestration into a new `roundtable-execution/references/command-orchestration.md`; all 4 commands Read it |
|-----------|---------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| **Matches BACKLOG target architecture** | Yes (roundtable.md = fat master ~490; others = thin launchers) | No (roundtable.md would also become thin, contradicting "roundtable.md ~600 lines full implementation") |
| **Reuses Phase 4 deliverable** | Yes (roundtable.md master is consumed as-is + hardened) | Partially (master's body migrates into a new skill file) |
| **Blast radius** | Low: 3 launchers rewritten + ~15 lines master hardening | High: master gutted into a skill ref + 4 commands rewired + new reference file + regression surface on roundtable native |
| **Precedent in codebase** | `phase-2-core.md` is a non-command file Read-and-followed by commands; Reading `roundtable.md` (a command file) the same way is mechanically identical | `phase-2-core.md` itself is this pattern, but applied to the *whole* orchestration |
| **Reversibility** | Easy (launchers are small) | Hard (master decomposition is a one-way refactor) |
| **Anti-pattern risk** | A command Reading another command file is unusual; mitigated because it is a plain `Read`, not a `SlashCommand` invocation (which is async, per CLAUDE.md) | Cleaner separation (no command Reads a command) |

**Recommendation: Pattern 1.** It matches the BACKLOG target architecture and Phase 4's design intent (roundtable.md *is* the master), consumes the Phase 4 deliverable directly, and has the smallest regression surface. Pattern 2 is architecturally tidier but re-opens roundtable.md two weeks after Phase 4 stabilized it, and the BACKLOG explicitly assigns roundtable.md the fat-master role. Pattern 2 is recorded as the rejected alternative; if Pattern 1's "command Reads a command" proves awkward in dogfood, Pattern 2 is the documented escalation.

### 3.2 Thin launcher anatomy (Pattern 1)

Each thin launcher executes, in order:

1. **`## Context` block**: `pwd`, `ls -la`, `date` timestamp, ISO timestamp. This block MUST be a superset of what `roundtable.md`'s own Context block provides, because Read-and-follow does **not** re-execute the master's `!`-prefixed directives (they run only when a file is invoked as a slash command). The launcher's Context block is the single context-capture point. (Risk R1.)
2. **`## Interpret Context`**: S2S-init check; workflow-specific file reads (CONTEXT.md, requirements.md).
3. **Workflow-specific Phase 0 prep**: prerequisite gate; Smart Source Detection (specs only); existing-output override/merge/cancel.
4. **Parse workflow-specific flags**: `--format` (specs), `--focus` (design), `--participants` (brainstorm), `--skip-roundtable` (specs/design).
5. **`--skip-roundtable` branch**: if present, run the inline skip mode and exit. Unchanged logic, kept in the launcher (workflow-specific, never touches the master).
6. **Set handoff variables**: `WORKFLOW_TYPE`, `DEFAULT_STRATEGY_FALLBACK`, `OUTPUT_TYPE` default, plus carry-through vars: `INPUT_SOURCES` (specs), `OUTPUT_MERGE_MODE` (specs/design), `OUTPUT_FORMAT` (specs `--format`), `FOCUS_AREA` (design `--focus`).
7. **Delegate**: Read `${CLAUDE_PLUGIN_ROOT}/commands/roundtable.md` and follow it from `PHASE 0`, treating the invocation as if `--workflow-type {WORKFLOW_TYPE}` were passed. The master owns auto-detect, session setup, round loop, completion.

The launcher does **not** auto-detect sessions itself (Risk R2): auto-detect lives entirely in the master's PHASE 0, scoped to `WORKFLOW_TYPE` after §8.1 hardening. This avoids double-prompting and conflicting resume logic. Session-flag arguments (`--new`, `--session`) pass through untouched in `$ARGUMENTS` and the master handles them.

### 3.3 Master hardening (§8.1)

`roundtable.md` becomes genuinely parametric on `workflow_type`:

- L108 grep → `grep -l "workflow_type: ${WORKFLOW_TYPE}"` (scope to invoked workflow).
- L260 session file body → `workflow_type: "{workflow_type}"` (resolved value).
- L323 display banner → `Workflow: {workflow_type}`.
- L346/L352 resume state.json → `"workflow_type": "{workflow_type}"`.
- L75 fast-path → check `active_session.workflow_type == {WORKFLOW_TYPE}` (narrow from the 4-element `IN` set).
- Add an **`## Invocation modes`** note near the top of roundtable.md documenting the two entry modes (native vs delegated) and the handoff-variable contract from §3.2, so the launcher↔master coupling is explicit and auditable.

When invoked natively, `WORKFLOW_TYPE` defaults to `roundtable` and every site above resolves exactly as it does today: native behavior is unchanged by construction. Re-verified in §8.5.

### 3.4 Work breakdown

Phase 8 delivers in 7 sub-phases over an estimated **~6.5 hours**:

- **8.0** audit (~1h): inventory workflow-specific vs shared per command; re-verify the 5 master hardcode sites against a real dogfood session file; finalize the handoff-variable contract; capture pre-Phase-8 line counts; write the audit file.
- **8.1** master hardening (~1h): parametrize roundtable.md (`workflow_type` at 4 write sites + grep + fast-path); add `## Invocation modes` contract note.
- **8.2** specs thin launcher (~1.25h): rewrite `commands/specs.md` to ~150 lines.
- **8.3** design thin launcher (~1h): rewrite `commands/design.md` to ~150 lines.
- **8.4** brainstorm thin launcher (~0.75h): rewrite `commands/brainstorm.md` to ~120 lines (simplest: no prereq doc, no existing-output check, no skip mode).
- **8.5** regression replay (~1h): dogfood all 4 workflows via thin launchers + roundtable native; structural compare to exp44/exp45 baselines; backward-compat resume probe (folds in the Phase 4 §6 deferred item).
- **8.6** close-out (~0.5h): BACKLOG, ADR-0011 Phase 8 addendum, plan Status, MEMORY, refreshed line-count table, v0.4.0 release-readiness note.

## 4. Sub-phases

**Execution order**: 8.0 → 8.1 → 8.2 → 8.3 → 8.4 → 8.5 → 8.6.

(8.1 precedes the launcher rewrites because a launcher cannot be regression-tested against a master that still hardcodes `roundtable`.)

### 8.0: audit current state (~1h)

**Goal**: produce a definitive inventory so the launcher rewrites are deletion, not redesign.

**Actions**:
1. For each of specs/design/brainstorm, classify every section as **keep-in-launcher** (workflow-specific) or **delete-delegate-to-master** (generic). Produce a per-command line-range table.
2. Re-verify the 5 master hardcode sites by reading an actual Phase 4 dogfood session file produced by the master path (e.g. an `exp52`/`exp49`/`exp51` `--workflow-type` run, if the worktree still exists; otherwise confirm by static read). Record whether `workflow_type` in the written session file is correct or stale.
3. Finalize the handoff-variable contract (names, which command sets which, where the master consumes each). Decide whether `--focus` (design) affects only output or also the discussion context passed to the facilitator.
4. Capture pre-Phase-8 line counts: `wc -l commands/{specs,design,brainstorm,roundtable}.md`.
5. Decide the specs Smart Source Detection placement: inline (~150-180 line budget) vs extract to `roundtable-execution/references/specs-source-detection.md` (keeps specs.md ≤150). Record the decision with rationale.
6. Write `.s2s/plans/20260521-tech002-phase8-8.0-audit.md`.

**Exit condition**: audit file exists; every line of the 3 commands is classified keep/delete; 5 hardcode sites confirmed; handoff contract frozen.

### 8.1: harden roundtable.md as workflow-parametric master (~1h)

**Goal**: the master honors `workflow_type` everywhere; native invocation unchanged.

**Actions**:
1. Parametrize the 4 write sites (L260 session file, L323 display, L346/L352 resume state.json) and the L108 grep to use the resolved `workflow_type`.
2. Narrow the L75 fast-path to `active_session.workflow_type == WORKFLOW_TYPE`.
3. Add `## Invocation modes` section near the top: documents native vs delegated entry and the handoff-variable contract (§3.2 list).
4. Confirm Phase 4 output dispatch table (L463-470) already covers all 4 workflows (it does); no change expected, just verify.

**Exit condition**: `grep -n 'roundtable' commands/roundtable.md` shows no hardcoded `workflow_type` literal where a parameter belongs; native `/s2s:roundtable` smoke run still produces a `roundtable`-typed session.

### 8.2: convert specs.md to thin launcher (~1.25h)

**Goal**: `commands/specs.md` ~150 lines, delegating to the master.

**Actions**:
1. Keep: frontmatter; Context + Interpret Context; Check prerequisites (CONTEXT.md populated); Smart Source Detection (or its Read pointer per §8.0 step 5); Check existing requirements.md (override/merge/cancel); parse `--format`/`--skip-roundtable`; Skip Roundtable Mode.
2. Delete: generic flag parse, auto-detect (Phase 0 lines ~31-120), Phase 1 Session Setup (lines ~253-450), Phase 2 inline block, Phase 3 Completion (lines ~480-590).
3. Add the handoff block (§3.2 steps 6-7): set `WORKFLOW_TYPE=specs`, `DEFAULT_STRATEGY_FALLBACK=consensus-driven`, `OUTPUT_TYPE=requirements`, carry `INPUT_SOURCES`/`OUTPUT_MERGE_MODE`/`OUTPUT_FORMAT`; Read and follow `roundtable.md`.
4. `wc -l` budget: ≤180 (≤150 if Smart Source Detection is extracted per §8.0 step 5).

**Exit condition**: specs.md ≤180 lines; no inline Phase 1/2/3; `/s2s:specs --help`-equivalent surface unchanged.

### 8.3: convert design.md to thin launcher (~1h)

**Goal**: `commands/design.md` ~150 lines.

**Actions**:
1. Keep: frontmatter; Context + Interpret; Check prerequisites (requirements.md absent → warn/continue); Check existing architecture.md (override/merge/cancel); parse `--focus`/`--skip-roundtable`; Skip Roundtable Mode.
2. Delete: same generic blocks as §8.2.
3. Handoff: `WORKFLOW_TYPE=design`, `DEFAULT_STRATEGY_FALLBACK=debate`, `OUTPUT_TYPE=architecture`, carry `OUTPUT_MERGE_MODE`/`FOCUS_AREA`.
4. `wc -l` budget: ≤150.

**Exit condition**: design.md ≤150 lines; no inline Phase 1/2/3.

### 8.4: convert brainstorm.md to thin launcher (~0.75h)

**Goal**: `commands/brainstorm.md` ~120 lines (simplest of the three).

**Actions**:
1. Keep: frontmatter; Context + Interpret; Validate environment; parse `topic`/`--participants`; the Disney intro display (optional, workflow-flavored UX, keep ~8 lines).
2. Delete: same generic blocks; note brainstorm has no prereq doc, no existing-output check, no skip-roundtable mode, so it is the cleanest conversion.
3. Handoff: `WORKFLOW_TYPE=brainstorm`, `DEFAULT_STRATEGY_FALLBACK=disney`, `OUTPUT_TYPE=summary`, carry `--participants` override.
4. `wc -l` budget: ≤130.

**Exit condition**: brainstorm.md ≤130 lines; no inline Phase 1/2/3.

### 8.5: regression replay + backward-compat probe (~1h)

**Goal**: confirm zero behavioral regression across all 4 workflows.

**Actions**:
1. Dogfood replay (ElfGiftRush_s2s worktrees, per `project_dogfood_test_env` convention):
   - `/s2s:specs "..."` → structural compare to `exp44-specs-post-phase7b.md`.
   - `/s2s:design "..."` → compare to `exp44-design-post-phase7b.md`.
   - `/s2s:brainstorm "..."` → compare to `exp44-brainstorm-post-phase7b.md`.
   - `/s2s:roundtable "..." --diagnostic` (native, master unchanged) → compare to `exp45-roundtable-native-post-phase4.md`.
2. Verify each thin-launcher run produces a session file with the **correct** `workflow_type` field (the §8.1 hardening payoff) and a `{ts}-{workflow_type}-{slug}` session id.
3. **Backward-compat resume probe** (folds in Phase 4 plan §6 deferred item): resume a pre-Phase-8 specs/design/brainstorm session via the thin launcher; assert the master's resume path (Phase 4 §4.3 step 4, all workflow_types) handles it without error.
4. `--skip-roundtable` probe: `/s2s:specs --skip-roundtable` and `/s2s:design --skip-roundtable` produce output without entering the round loop.
5. Acceptable deltas: session-id format now uniform across all paths (resolves Phase 4 §8 finding #4, see §8.6). Unacceptable deltas: any artifact-schema change, missing artifacts, Phase 2 numbering change, all of which block the PR.

**Exit condition**: 4 baselines match structurally; thin-launcher sessions carry correct `workflow_type`; resume probe passes; skip-roundtable passes.

### 8.6: close-out (~0.5h)

**Actions**:
1. `.s2s/BACKLOG.md` TECH-002 block: Phase 8 row → ✅ completed; acceptance criteria #3 and #6 marked DONE; refresh the line-count table with **actuals** (the pre-Phase-4 estimate had roundtable.md at ~600; actual is ~490). Update "Current state" block.
2. `.s2s/decisions/0011-roundtable-command-unification.md` Phase 8 addendum: Pattern 1 handoff decision + master hardening + final architecture (1 master + 3 thin launchers) + final LOC table + session_id divergence resolved.
3. Plan Status: `draft` → `completed (PR #XX merged YYYY-MM-DD)` post-merge.
4. `MEMORY.md` `project_tech002_progress.md`: TECH-002 fully complete; v0.4.0 ready for `develop → main`; index entry updated.
5. Note: Phase 4 §8 finding #4 (session_id format divergence direct vs master) is **resolved** by Phase 8: there is no longer a direct path, all workflows generate session ids through the master.

**Exit condition**: BACKLOG + ADR + plan + memory consistent with post-Phase-8 state; v0.4.0 release-readiness explicitly stated.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Read-and-follow does not execute the master's `## Context` `!` directives; the master runs without pwd/ls/timestamp | high | high | §3.2: the launcher's Context block is the single capture point and must be a superset of the master's. §8.0 audits this; §8.5 dogfood is the proof. |
| R2 | Launcher and master both run auto-detect → double prompt or conflicting resume | medium | medium | §3.2: launcher does NO auto-detect; it lives entirely in the master PHASE 0, scoped to `WORKFLOW_TYPE` after §8.1. |
| R3 | specs.md cannot reach ~150 lines with Smart Source Detection inline (~60 lines) | medium | low | §8.0 step 5 decides: inline (budget ≤180) or extract to a skill reference (≤150). Either is acceptable; budget is a soft target. |
| R4 | Workflow-specific flags (`--format`, `--focus`) consumed by the launcher never reach output generation in the master | medium | medium | Handoff-variable contract (§3.2 step 6) carries `OUTPUT_FORMAT`/`FOCUS_AREA`; §8.0 step 3 finalizes consumption points; §8.5 verifies output. |
| R5 | Behavioral regression: thin-launcher output differs from baseline | low | high | §8.5 dogfood replay is the merge gate. Master path equivalence was already proven in Phase 4 §4.5; Phase 8 only changes the launcher shell. |
| R6 | `--skip-roundtable` path diverges after the rewrite | low | medium | Skip mode kept inline in the launcher, logic copied verbatim, never touches the master. §8.5 step 4 probes it. |
| R7 | Master hardening breaks native `/s2s:roundtable` | low | high | §3.3: native invocation defaults `workflow_type=roundtable`, every parametrized site resolves to the prior literal by construction. §8.5 step 1 runs native roundtable. |
| R8 | Resume of a pre-Phase-8 specs/design/brainstorm session via the thin launcher fails | low | medium | Master resume already extended to all workflow_types in Phase 4 §4.3 step 4. §8.5 step 3 probes it explicitly. |
| R9 | "Command Reads a command" turns out brittle at runtime | low | medium | Mechanically identical to Reading `phase-2-core.md`. If it fails, §3.1 Pattern 2 (shared core skill) is the documented escalation. |

## 6. Done criteria

- [ ] 8.0 audit file produced; per-command keep/delete classification complete; 5 master hardcode sites confirmed against a real session file; handoff contract frozen; Smart Source Detection placement decided.
- [ ] roundtable.md hardened: `workflow_type` parametric at 4 write sites + grep + fast-path; `## Invocation modes` contract note added; native smoke run produces a `roundtable`-typed session.
- [ ] `commands/specs.md` is a thin launcher, `wc -l` ≤ 180 (≤150 if source-detection extracted); no inline Phase 1/2/3.
- [ ] `commands/design.md` is a thin launcher, `wc -l` ≤ 150; no inline Phase 1/2/3.
- [ ] `commands/brainstorm.md` is a thin launcher, `wc -l` ≤ 130; no inline Phase 1/2/3.
- [ ] All per-command flags preserved with current semantics (`--format`, `--focus`, `--skip-roundtable`, `--participants`, plus the generic set).
- [ ] §8.5 regression: exp44 specs/design/brainstorm baselines + exp45 roundtable-native baseline replay structurally identically.
- [ ] §8.5: each thin-launcher session file carries the correct `workflow_type` and a `{ts}-{workflow_type}-{slug}` id.
- [ ] §8.5: backward-compat resume probe passes (pre-Phase-8 session resumed via thin launcher).
- [ ] §8.5: `--skip-roundtable` probe passes for specs and design.
- [ ] `.s2s/BACKLOG.md`: Phase 8 ✅; acceptance criteria #3 and #6 DONE; line-count table refreshed with actuals.
- [ ] ADR-0011 Phase 8 addendum recorded (Pattern 1 + master hardening + final architecture + LOC table).
- [ ] MEMORY `project_tech002_progress.md` updated: TECH-002 complete, v0.4.0 ready for develop → main.
- [ ] PR opened against `develop`, milestone v0.4.0.
- [ ] Plan `Status` updated to `completed (PR #XX merged YYYY-MM-DD)` post-merge.

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase8-thin-launchers` → `develop`, milestone v0.4.0.

Commit structure (in execution order):

1. `chore(plans): finalize TECH-002 Phase 4 plan status post PR #16 merge` (already committed, `048e2d2`)
2. `docs(plans): draft TECH-002 Phase 8 thin-launcher plan` (this file)
3. `docs(plans): TECH-002 Phase 8.0 audit` (8.0)
4. `feat(roundtable): harden master as workflow-type parametric` (8.1)
5. `refactor(commands): convert specs.md to thin launcher` (8.2)
6. `refactor(commands): convert design.md to thin launcher` (8.3)
7. `refactor(commands): convert brainstorm.md to thin launcher` (8.4)
8. `test(baselines): Phase 8 regression replay + backward-compat resume probe` (8.5)
9. `docs(adr,backlog,plan): close TECH-002 Phase 8, ADR-0011 Phase 8 addendum` (8.6)

PR body must include: link to plan + 8.0 audit; Pattern 1 handoff decision with §3.1 matrix; before/after `wc -l` for all 4 commands; regression deltas table; explicit "v0.4.0 ready for develop → main" statement.

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **v0.4.0 → main release**: after Phase 8 merges to develop, open `develop → main` release PR and tag `v0.4.0` (tags only on main, per `project_release_flow`). This is the §9 exit action, not a Phase 8 deliverable.
- **3 unrelated Phase 4 diagnostic findings**: agent-resume gap, R1 observer false-positive on empty artifact maps, token-tracker.sh exit 1 quirk. Remain tracked in Phase 4 plan §8; not Phase 8 scope.
- **Six-hats wiring**: prerequisite-blocked on empirical baseline acquisition. Separate task; Phase 8 does not touch it.
- **Pattern 2 (shared core skill)**: if Pattern 1's command-Reads-command proves awkward, the documented escalation is to extract the master's generic orchestration into `roundtable-execution/references/command-orchestration.md`. Post-v0.4.0 only.
- **specs Smart Source Detection as a reusable skill**: if §8.0 extracts it to a reference, design/brainstorm could later opt into source detection too. Post-v0.4.0.

## 9. Exit pointer

After Phase 8 PR merges to develop:
- Update `.s2s/BACKLOG.md`: TECH-002 status `in_progress` → `completed`; all 6 acceptance criteria checked.
- Verify MEMORY `project_tech002_progress.md`: TECH-002 done; v0.4.0 ready for release.
- Open the `develop → main` release PR for **v0.4.0** (Phases 0, 1, 5, 6, 6b, 2, 3, 7B, 7-lite, 4, 8). Tag `v0.4.0` on main per `project_release_flow`.
- Close milestone v0.4.0 (Phase 8 was the 6th and final item).

TECH-002 is the last work item gating v0.4.0. Phase 8 completes the command-unification arc started 2026-01-20.

## 10. Contract invariants (must NOT change)

- **All 4 workflows replay structurally**. exp44 + exp45 baselines remain valid; no artifact-schema change, no session.yaml structural change.
- **`phase-2-core.md` Step 2.0-2.10 frozen**. Phase 8 touches command files and the master only.
- **CLI surface frozen**. No flag added, removed, or renamed for any of the 4 commands.
- **Native `/s2s:roundtable` unchanged**. Master hardening is parameter-neutral for the native path.
- **`profiles/*.yaml`, `output-generation/`, `roundtable-strategies/`, `agents/` untouched**. Phase 8 is a command-layer refactor.
- **`strategy_constraints.forced` still wins** (brainstorm `disney` forced): the thin launcher's `DEFAULT_STRATEGY_FALLBACK` is a fallback, not an override.

If any of these is violated, that is a regression and the PR cannot merge.
