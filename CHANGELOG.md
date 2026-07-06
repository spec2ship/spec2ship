# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - Unreleased

### Highlights

**Test-infrastructure release.** Turns the lone, manually-run token-tracker test into a real automated suite, the substance of the v1.0 "automated test suite" gate. Adds a discovery runner (`make test`), GitHub Actions CI on every push/PR, and hermetic coverage for the two previously-untested shipped helpers (`statusline.sh`, `context-reset.sh`). Writing the new tests surfaced and fixed one latent bug (BUG-021). Merged to develop via PR #31 (`de3a033`).

Also closes the script-layer findings from the Vektra dogfood analysis (BUG-022/023/024, filed from findings VKT-001/002/021) and ships the confidential-context guardrail (TECH-013): `/s2s:init` now gitignores a sanctioned `.s2s/local/` private area and the CONTEXT.md template + guide warn that CONTEXT.md content flows into every generated document. The suite grows to 60 assertions across the three bash helpers.

### Added
- **`tests/run-all.sh`** — discovery runner: finds every `*/tests/test-*.sh`, runs each in isolation, exits non-zero on any failure. Bash 3.2 compatible (default macOS bash). `Makefile` exposes `make test` as the single local/CI entrypoint. (TECH-012)
- **`.github/workflows/tests.yml`** — CI that runs the suite on push to `develop`/`main` and on every pull request (ubuntu-latest; bash + jq; `LANG=C.UTF-8`). This is what makes the suite "automated", closing the structural half of the v1.0 gate. (TECH-012)
- **`templates/statusline/tests/test-statusline.sh`** (11 assertions) — hermetic black-box tests locking BUG-019 (dynamic context window: 1M → 140k/860k, default 200k when size absent) and BUG-020 (percentage-based progress bar: 14→1, 50→5, 80→8, 95→10 filled slots). Runs with the real `$HOME` (faking it breaks a `$HOME`-relative jq, e.g. an asdf shim); the fallback-only assertions self-skip when a real global statusline is configured, while the `context-window.json` assertions always run. (TECH-012)
- **`templates/hooks/tests/test-context-reset.sh`** (14 assertions) — hermetic tests for the resume banner on `/compact` + `/clear`, the no-op cases (startup / no active session / non-s2s dir), the jq path (`state.json.last_activity` update), and the no-jq fallback (banner + install note, `state.json` untouched). (TECH-012)
- **Docs** — CONTRIBUTING.md gains an "Automated script tests" section (run with `make test`); `.s2s/test-baselines/README.md` drops the stale "only automated test is the token tracker" claim. (TECH-012)

### Fixed
- **BUG-021 (medium)** — `templates/hooks/context-reset.sh` no-jq fallback now parses pretty-printed `state.json`. The grep/sed extractors matched `"key":"value"` (no space), but `state.json` is jq-written as `"key": "value"`, so without jq the extracted `workflow_type`/`id`/`round` were empty and the resume banner (the whole point of that path) never showed. Made the three extractors whitespace-tolerant; the tracked `.claude/context-reset.sh` dogfood copy re-synced byte-identical. Found while writing the context-reset tests. Script → v2.2.0.
- **BUG-022 (high)** — generated `statusline.sh` had no `jq` guard: 8+ jq calls with stderr suppressed meant that without jq every variable silently went empty and the status line rendered blank/garbled with no hint why. Early guard now prints a visible `[s2s] jq not found - install jq to enable the s2s statusline` and exits 0. From Vektra dogfood finding VKT-001 (external CodeRabbit/Gemini review of the generated tooling). Template → v3.3.0, dogfood copy re-synced. Locked by test-statusline.sh Test 0 (runs on a curated no-jq PATH, before the suite's jq skip).
- **BUG-023 (high)** — generated `statusline.sh` could fork itself forever when the user's global `statusLine.command` resolved to the generated script itself: the chain-to-global pipe had no self-check. Now compares directory-resolved `SELF_PATH`/`GLOBAL_PATH` (bash 3.2 portable) and chains only when they differ; a new `S2S_GLOBAL_SETTINGS` override lets hermetic tests drive the chain branch without faking `$HOME`. From VKT-002. Locked by Tests 4 (self-chain suppressed, rendered exactly once, timeout-guarded) and 5 (distinct global still chains).
- **BUG-024 (low)** — `context-reset.sh` no-jq fallback extracted `workflow_type`/`id`/`round` with file-wide first-match greps; same-named keys outside `active_session` (history entries, `last_activity.session_id`) could aim the resume command at the wrong session. The fallback now isolates the `active_session` block first (newline-flattened, works on pretty and compact JSON) and leaves the fields empty (no banner) when the block cannot be isolated; removed the now-unused file-wide helpers. From VKT-021. Script → v2.3.0, dogfood copy re-synced. Locked by Test 7 (decoy keys must not leak into the banner).

### Security
- **TECH-013** — confidential-context guardrail, from VKT-073 (a real client codename had to be manually scrubbed from a dogfood project's CONTEXT.md): `/s2s:init` step 5.4b now ensures the project `.gitignore` covers a sanctioned `.s2s/local/` private area (append or create) and the init summary carries a privacy note; the CONTEXT.md template gains a CONFIDENTIALITY header block; the s2s-guide gains a "Confidential context" section. CONTEXT.md feeds every session and generated document, so confidential names must live in `.s2s/local/`, never in CONTEXT.md.

### Changed
- Backlog hygiene from the 2026-06-13 Vektra-analysis audit: TECH-001 (plan ADR integration) and TECH-003 (schema centralization) retro-marked completed (shipped by earlier work, never flagged); stale pre-TECH-002 file references corrected in TEST-003, TECH-010, BUG-001, BUG-003; the Vektra-scale plan-validation cluster parked as IDEA-037 instead of entering the backlog. Native multi-agent conversion for the roundtable evaluated and declined (constraints recorded in `.claude/s2s-development.md`).

## [0.6.0] - 2026-06-11

### Highlights

**Bug-fix release.** Token-tracker hardening: the three follow-up tickets opened during the v0.5.0 dogfood (BUG-017, BUG-018, TECH-011) plus one user-reported bug (BUG-019) and its review spin-off (BUG-020). Recurring theme: three of the five items were vestigial write-only state, removed rather than preserved. Ships the first hermetic regression test for `token-tracker.sh` (seed for the v1.0 automated-test-suite gate). Verified live in `ElfGiftRush_s2s/exp65` (debate strategy, 3 rounds); structural summary in `.s2s/test-baselines/v0.6.0-dogfood.md`.

### Fixed
- **BUG-019 (medium)** — `token-tracker.sh` no longer hardcodes a 200K context limit. New `get_context_limit()` reads `context_window_size` from `.s2s/context-window.json` (the statusline already writes it), and `get_tokens_from_statusline` prefers the absolute `current_context_tokens` instead of rescaling a percentage. All limit-dependent values (percentages, available/remaining, statusline back-calc) now adapt to the model's real window. On a 1M-window model (Opus 4.6/4.7/4.8, Sonnet 4.6) the tracker reported `28k used / 172k available` at 14% instead of `140k / 860k`; on the JSONL-fallback path it reported 70% at 140k real tokens and could stop the roundtable ~5x too early. Falls back to 200K only when the statusline JSON is absent (no per-model table to maintain). User-reported, filed and fixed the same session. Script → v5.4.0.
- **BUG-017 (low)** — `token-tracker.sh recap` now survives `/compact`. When an end-of-round capture lands `0` (statusline momentarily at 0% right after a compact, JSONL fallback unavailable), recap recovers the count (fresh read → round-start fallback) so the percentage is never a phantom 0%, clamps any negative phase delta to 0, and emits `RECAP_DEGRADED` so the display marks the breakdown approximate instead of printing negative tokens. `init`'s `compactDetected` semantics (BUG-006/012) untouched. Script → v5.3.1.
- **BUG-020 (low)** — `templates/statusline/statusline.sh` fallback progress bar was `FILLED = USED_K / 20` (10 slots x 20k = 200K), pegged full at ~20% of a 1M window. Now percentage-based `FILLED = round(used_pct / 10)`, window-agnostic and clamped 0-10 (identical result on a 200K window). The repo's tracked `.claude/statusline.sh` dogfood copy carried the same bug and was re-synced byte-identical. Template → v3.2.0.

### Removed
- **BUG-018 (low)** — Dropped the write-only `workflowType`/`strategy`/`phase`/`participantsCount` fields from the `token-tracker.sh init` cache write and signature. Re-triage showed the four params were never read back (the statusline's roundtable info comes from `state.json`, rewritten every round by `phase-2-core.md §2.1b` from on-disk profile/config, which already survives `/compact`). `init` still accepts the extra positional args (ignored) for back-compat. Fixed the stale `statusline.sh` header comment ("written by token-tracker" → `phase-2-core.md §2.1b`). Script → v5.5.0.
- **TECH-011** — Removed the vestigial `assign_debate_sides` launcher pre-step and the `debate_sides` session field from `commands/roundtable.md`, plus the non-functional `--pro`/`--con` flags. `debate_sides` was written at setup and read nowhere; Pro/Con is assigned per round by the `facilitator_emergent` policy (`facilitator.md`), so the static split was ignored and `--pro`/`--con` were silently no-ops. Docs (`debate.md` § Side Assignment, `strategy-hooks.md`) updated to the per-round wording. No semantic change to design+debate runs. Explicit user-controlled sides, if wanted later, would be a new feature (seed into `facilitator_emergent`), not a regression.

### Added
- **`skills/roundtable-execution/scripts/tests/test-token-tracker.sh`** — first hermetic regression test for the token tracker (5 tests, 26 assertions, black-box, no network/statusline/JSONL needed). Covers BUG-017 (post-compact recap, healthy-recap guard), BUG-019 (1M window via `current_context_tokens` + percentage fallback), and BUG-018 (cache drops vestigial fields, extra args still accepted). Seed for the automated test suite that gates v1.0.

### Verification
- One end-of-cycle dogfood in `ElfGiftRush_s2s/exp65` (`--strategy debate`, 3 rounds, against this working tree as the plugin source): `session.yaml` carries 0 `debate_sides` and wires `hook_overrides` to `facilitator_emergent`; the run concluded with no error from the removed pre-step (TECH-011 live). BUG-018/019 incidentally confirmed live (cache without `workflowType`; `context_window_size: 1000000`, ~16% of 1M = dynamic limit). BUG-017/020 unit-verified by the new test harness. Structural summary in `.s2s/test-baselines/v0.6.0-dogfood.md`; raw kept local per `feedback_test_data_split`.
- A false-start run (exp64) tested a stale local clone and was discarded; an audit confirmed the v0.5.0 dogfood was unaffected.

## [0.5.0] - 2026-06-06

### Highlights

**Bug-fix release.** Eight bugs closed against the v0.4.0 round-loop, including the four high/critical bugs that were the v1.0 BUG gate (BUG-004, BUG-005, BUG-009, BUG-012). All fixes verified end-to-end via dogfood in `ElfGiftRush_s2s/exp*` (structural summary in `.s2s/test-baselines/v0.5.0-dogfood.md`).

### Fixed
- **BUG-004 (critical)** — Verbose dumps now survive `--interactive` turn boundaries. Each per-phase dump instruction in `phase-2-core.md` (§2.2e, §2.3e, §2.4e) starts with "**YOU MUST use the Write tool NOW** ... before proceeding"; pre-fix the planned writes were lost when `AskUserQuestion` ended the LLM turn, leaving `rounds/` empty after N completed rounds.
- **BUG-005 (high)** — Participant dump (`{NNN}-02-{participant}.yaml`) now requires the full `input.context` block (`project_summary`, `relevant_artifacts`, `open_conflicts`, `open_questions`, `recent_rounds`) copied verbatim from what was sent to the participant in Step 2.3b. Pre-fix the instruction emphasized response fields only and the context block was dropped.
- **BUG-009 (high)** — Command-side conclude validation added as `phase-2-core.md` §2.9b (defense in depth). When `next == "conclude"` on the agenda axis, the gate joins the `agenda.yaml` snapshot (`topics[].critical`) with the live `session.agenda` statuses and overrides `conclude → continue` if any critical topic is not `closed` or if <50% of non-critical topics are `closed`. Records `validation_override` on the round entry. Facilitator instructions unchanged.
- **BUG-010 (medium)** — Conclude confirmation added as `phase-2-core.md` §2.9c for the non-interactive path. Displays a short session summary (decisions / coverage / open items) and an Accept-vs-Continue prompt before output generation. Interactive mode keeps the Step 2.8 choice unchanged.
- **BUG-012 (high)** — `TOKEN_SCRIPT` is now re-resolved at the start of EVERY round, unconditionally. `token-tracking.md` "Script Location" and `phase-2-core.md` Step 2.0 lost the "resolve ONCE, then reuse" / "cached if already loaded" hedges; instead they carry an explicit compact/clear rationale (the model may "recall" `TOKEN_SCRIPT` after `/compact` even when the value is gone, silently disabling token tracking and letting the loop run past capacity).
- **BUG-014 (medium)** — Task-tool agent resume calls now require a one-line `summary` (`phase-2-core.md` §2.2a facilitator and §2.3a participants). Without it the harness rejects the resume with "summary is required when message is a string" and falls back to a fresh re-invocation. Preventive fix; the original Phase 4 repro was non-blocking via harness fallback.
- **BUG-015 (low)** — Session-observer agent now explicitly states that at `round == 1` the artifact maps, `relevant_artifacts`, and `recent_rounds` are the expected empty baseline and MUST NOT be reported as findings. Populated/coherence checks are gated to `round > 1`.
- **BUG-016 (low)** — `token-tracker.sh` now ends with an explicit `exit 0`. Without it the script inherited the exit status of the last branch command — the `init` branch ends with `[[ "$COMPACT_DETECTED" == "true" ]] && echo …`, returning 1 when no compact occurred, which spuriously aborted `eval $(... init ...) && ...` chains.

### Templates
- **BUG-002 (medium)** — Consensus threshold lowered from `0.67` to `0.6` in `templates/project/config.yaml` and `.s2s/config.yaml` so an exact 2/3 majority passes for participant counts divisible by 3. Aligned with the skill references.
- **BUG-007 (low)** — Internal `ADR-0009` and `ADR-0010` references removed from `templates/workspace/workspace.yaml`, `templates/workspace/CONTEXT.md`, `templates/project/CONTEXT.md`, and `templates/project/config.yaml`. The generic `ADR-001` example remains as a placeholder.

### Closed by re-triage
- **TECH-005** — Marked completed: token tracking auto-setup via per-project statusline was already shipped in v0.4.0 (`templates/statusline/{statusline.sh,settings.json}`, `templates/hooks/context-reset.sh`, `commands/init.md` Phase 5.5b). The two remaining tasks were either a manual restart test or tracked as TECH-008 (config toggle).

### Verification
- Five dogfood worktrees against `ElfGiftRush_s2s` bare repo: three forward post-fix (exp58, exp60, exp61) and two pre-fix A/B (exp62, exp63 vs `main @ v0.4.0`). Raw kept local per `feedback_test_data_split`; structural summary in `.s2s/test-baselines/v0.5.0-dogfood.md`.
- BUG-009 and BUG-010 confirmed by A/B (pre-fix reproduced, post-fix corrected). BUG-012 and BUG-014 A/B came back non-deterministic this run (LLM-context-dependent); both fixes are preventive instruction changes.
- Three non-blocking follow-up tickets opened (`BUG-017`, `BUG-018`, `TECH-011`) for findings observed during the dogfood: token-tracker recap math after compact, cache loses workflow params after compact, vestigial `assign_debate_sides` pre-step.

## [0.4.0] - 2026-05-27

### Highlights

**TECH-002 Roundtable command unification complete**. The four roundtable commands (`specs`, `design`, `brainstorm`, `roundtable`) now share a single execution engine via `commands/roundtable.md` (master) plus profile-driven workflow shapes. Command-layer line count: 5301 (v0.3.0) to 956 (this release).

| File | v0.3.0 | v0.4.0 |
|------|--------|--------|
| `commands/specs.md` | 1717 | 172 |
| `commands/design.md` | 1607 | 114 |
| `commands/brainstorm.md` | 1575 | 78 |
| `commands/roundtable.md` | 402 | 592 (master) |
| Total | 5301 | 956 |

### Added
- **TECH-002 master command** (`commands/roundtable.md`): single orchestrator for all 4 workflow types. Profile-driven PHASE 0+1 (folder, snapshots, skeleton from profile); uniform PHASE 2 round loop via `phase-2-core.md`; PHASE 3 phase-2-core delegation; PHASE 4 completion with handoff variables (`OUTPUT_MERGE_MODE`, `OUTPUT_FORMAT`, `FOCUS_AREA`). Both native and delegated invocation modes.
- **TECH-002 thin launchers**: `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md` reduced to workflow-specific prep + Read-and-follow handoff to the master (Pattern 1).
- **`profiles/*.yaml`** (4 files in `skills/roundtable-execution/profiles/`): single source of truth for workflow shape. Drives both PHASE 1 setup and PHASE 2 round loop. Includes new `profiles/roundtable.yaml` for native generic mode.
- **`skills/roundtable-execution/references/phase-2-core.md`** (881 lines): canonical executable single-source for the round loop (Phase 7B deep extraction).
- **12 artifact-schemas extracted** under `skills/roundtable-execution/references/artifact-schemas/`.
- **`disney-phase-machine.md`** reference: extracted Disney phase logic.
- **`strategy-hooks.md`** contract: Option A/B/C decision matrix, formal hook resolution.
- **5 strategy reference docs** with uniform `## Strategy hooks` sections (`standard`, `disney`, `debate`, `consensus-driven`, `six-hats`); bidirectional cross-link `disney.md` <-> `disney-phase-machine.md`.
- **`output-generation/references/roundtable-summary.md`**: Phase 3 dispatch for native roundtable mode.
- **D3 hierarchy** codified: `config.yaml` (user-canonical) -> `profiles/*.yaml` (plugin fallback) -> `SKILL.md` (documentation-only).
- **Option B 3-branch dispatch** for strategy hooks: `{skip}`, policy dict, absent for pre-Phase-4 sessions.
- **TECH-009 Token tracking with progressive precision**: T1/T2/T3 checkpoints per round, measured-then-estimated precision pipeline (`token-tracker.sh` up to v5.3.0).
- **TECH-007 Unified project state**: `.s2s/state.json` as single source of truth for active session and plan; fast-path session resume across all roundtable commands.
- **TECH-004 Token tracker v2.x to v5.x**: session isolation, statusline integration, auto-setup, Windows support, `CONTEXT_SOURCE` visibility.
- **Context-reset hook**: `SessionStart` hook captures `/clear` and `/compact` events into `state.json`; graceful jq-optional degradation.
- **Context capacity check**: Step 2.0 in all roundtable commands stops sessions before context overflow (95% threshold).
- **`/s2s:dev:check` command**: development validation runner (ENV-*, INST-*, CONS-* checks) via `dev-validator` agent.
- **`/s2s:dev:test` command**: integration test runner (VAL-RT-*, RES-*, EDGE-*) on real or synthetic sessions.
- **`dev-validator` agent**: scalable check execution architecture.
- **`dev-testing` skill**: comprehensive test reference suite (check-registry, inst-checks, cons-checks, res-checks, edge-scenarios, roundtable-tests).
- **`output-generation` skill** (TECH-002 Phase 1): extracted output rendering from commands; references for SRS, arc42, brainstorm formats.
- **`round-validation` reference** (TECH-002 Phase 2): shared per-round validation logic across specs/design/brainstorm.
- **`--diagnostic` flag** for roundtable commands: progressive disclosure mode invoking `session-observer` agent.
- **`--tokens` flag** for roundtable command (later made always-active).
- **ADR-0010**: single state field model for artifacts.
- **ADR-0011**: roundtable command unification rationale (with Phase 7B and Phase 8 addenda).
- **ADR-0012**: output-generation skill rationale.
- **`.s2s/architecture.md`, `.s2s/requirements.md`, structured `.s2s/ideas.md`**.
- **Plans**: `context-restructure`, `session-resilience-verification`, `test-validation-architecture`, and the full TECH-002 Phase 3/7B/7-lite/4/8 plan + audit set under `.s2s/plans/`.
- **`.claude/s2s-development.md`**: contributor patterns guide (Feature Activation Pattern, Optional Feature Hooks, `CLAUDE_PLUGIN_ROOT` references, skill reference triggers).
- **Test baselines**: `.s2s/test-baselines/` directory for TECH-002 regression captures (exp42/43/44/45 across all 4 workflows).

### Changed
- **Roundtable execution**: workflow shape is now data (`profiles/*.yaml`) rather than duplicated procedural code across 4 commands.
- **Strategy hooks**: formalized contract with `skip` / policy / absent semantics; `Step 2.6d` renamed to `Step 2.10` across 18 sites in 6 files; strategy doc disclaimers point to `profiles/` as the authoritative source.
- **`roundtable-strategies/SKILL.md`** v1.1.0 to v1.3.0: drift fixes D1/D2 + "authoritative source: profiles/" disclaimers (v1.2.0 in Phase 7-lite); strategy resolution hierarchy section added per D3 codification (v1.3.0 in Phase 4).
- **`roundtable-execution/SKILL.md`** restructured 1002 to 178 lines (v2.7.0 to v3.0.0) following Phase 7B deep extraction.
- **Token tracking always-active** (v2.3.0): no longer behind a flag, integrated by default.
- **State.json fast-path** in all 4 roundtable commands' auto-detect.
- **`.s2s` structure reorganized** with proper artifact separation.
- **Validation simplified** (ADR-0008): consolidated into per-round shared reference.
- **Diagnostic moved** from command to skill (progressive disclosure pattern).
- **`CLAUDE_PLUGIN_ROOT`** used for skill references in agents and commands (portability).
- **Token tracker hooks** moved from command to skill.
- **Resume reads `round_number`** from session file (no longer hardcoded 0).
- **Token estimate formula** changed from `T3-T1` to `T3-T0` (more accurate).
- **Token tracking instructions** made explicit and mandatory (Feature Activation Pattern).
- **Statusline** renamed to `statusline.sh`, reads global config dynamically.
- **Single state field model** (ADR-0010) applied across artifact handling.

### Fixed
- **BUG-003**: `participant_context` propagation via inline content instead of `context_files` reference.
- **BUG-006**: token tracker now detects `/compact` events.
- **BUG-013** (TECH-002 Phase 7B FIX-S1): session-observer Step 2.6c output now persisted to `rounds/{NNN}-04-session-observer.yaml`.
- **Phase 3 drift elimination** (6 textual fixes across 3 commands): canonical verification schema, missing `conflicts_resolved` counters, missing `rationale`/`concerns`/`suggestions` in brainstorm verbose dump, header normalization, `min_rounds` correctly read from config in specs.
- **Phase 4 finding #4** (session_id timestamp format divergence between direct and master paths): auto-resolved by Phase 8 (no direct path remains).
- Token tracker portability: `sed` instead of `BASH_REMATCH`.
- JSONL path encoding: leading dash preserved.
- Float arithmetic in `statusline.sh`.
- Removed counterproductive 60s staleness check.
- Step 2.0 alignment for token tracking across commands.
- ADR-0008 reference correction.
- Artifact `state` field correction (was `status`).
- Missing `tokens` section in session template.
- Token field naming alignment across schemas.
- Path resolution in agent skill references.
- Resume: state.json and display alignment from session file.
- `CLAUDE_PLUGIN_ROOT` resolution at hook startup.
- Roundtable token tracking: Phase 3 step numbers and order alignment.
- Automatic continuation enforcement to prevent mid-session stops.

### Removed
- `.s2s/specs/WORK-001-workspace-specification.md` (superseded by `.s2s` reorganization).
- ~3300 lines of duplicated round-execution code from `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md` (Phase 7B + Phase 8).

### Pull requests delivered in this release
- PR #12: TECH-002 Phases 0, 1, 5, 6, 6b, 2.
- PR #13: TECH-002 Phase 3 (approach A, drift elimination + canonical reference).
- PR #14: TECH-002 Phase 7B (deep extraction, `phase-2-core.md` rewrite).
- PR #15: TECH-002 Phase 7-lite (strategy doc hardening, Step 2.6d to 2.10 rename).
- PR #16: TECH-002 Phase 4 (master + Option B + D3 + Option epsilon, `profiles/roundtable.yaml`).
- PR #17: TECH-002 Phase 8 (thin launchers + master PHASE 0+1 generalization).

## [0.3.0] - 2026-01-18

### Added
- **s2s-guide skill**: Comprehensive usage and extension guide, activated by questions like "what is s2s", "how to extend s2s"
- **Workspace structure detection**: Init command now detects existing project structure and adapts accordingly
- **BACKLOG.md template**: Automatic backlog creation during init for tracking project work
- **Workspace scope awareness**: Roundtable participants now receive project context via `@.s2s/CONTEXT.md` references
- **Template-based generation**: Plans and init files now use templates with placeholder substitution
- **Backlog management skill**: Track development artifacts in `.s2s/BACKLOG.md`
- `--plugin-dir` development workflow documented in CONTRIBUTING.md (hot reload support)
- GitHub alerts and execution tips in documentation

### Changed
- **Output consolidation**: All artifacts now under `.s2s/` directory (requirements.md, architecture.md, plans/, sessions/)
- **Session architecture**: Simplified to ARCH-001 with embedded artifacts in single YAML file
- **Config handling**: Removed hardcoded defaults from workflow commands; config.yaml is single source of truth
- **Strategy selection**: Workflow-specific fallbacks instead of global default
- **Validation system**: Unified session validation with script-first approach
- **Requirement IDs**: Standardized from FR-* to REQ-* pattern
- **Documentation**: Comprehensive README rewrite with positioning, comparison table, and visual improvements
- **CONTRIBUTING.md**: Added `--plugin-dir` as recommended dev workflow with hot reload

### Fixed
- Missing ux-researcher and security-champion in default participants
- Broken links in templates, examples, and documentation
- ASCII diagram alignment in README
- Session schema alignment with ARCH-001 structure
- Plan states now correctly use active|closed only

### Removed
- Hardcoded defaults from workflow commands (now read from config.yaml)
- Redundant documentation (consolidated into s2s-guide skill)
- `.claude/decisions/` folder (decisions now in `.s2s/decisions/` local to user projects)

## [0.2.0] - 2026-01-10

### Added
- Complete roundtable system with 12 specialized agents
- 5 facilitation strategies: standard, disney, debate, consensus-driven, six-hats
- Session management commands: list, status, validate, cleanup
- Verbose and diagnostic modes for debugging
- Critical Stance and Context Check for anti-sycophancy
- Plan management: list, close (unified create/start into plan command)

### Changed
- Session architecture: embedded artifacts in single YAML file
- Agent model tiers: opus (critical), inherit (default), haiku (fast)

## [0.1.0] - 2024-12-28

### Added
- Initial release
- Core workflows: init, specs, design, brainstorm, plan
- Basic roundtable implementation
- Arc42, ISO 25010, MADR skills
- Project templates

[Unreleased]: https://github.com/spec2ship/spec2ship/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/spec2ship/spec2ship/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/spec2ship/spec2ship/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/spec2ship/spec2ship/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/spec2ship/spec2ship/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/spec2ship/spec2ship/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/spec2ship/spec2ship/releases/tag/v0.1.0
