# Spec2Ship Backlog

**Updated**: 2026-07-13 (v0.9.0 cycle opened — headline **FEAT-014** design-to-plan bridge, lean cut VKT-037/038/069. Pre-cycle re-triage: QUAL-001 Context was factually wrong (dev tools DO ship → **BUG-027**); BUG-008 premise narrowed but alive (init writes only `.s2s/local/`); FEAT-007 **superseded** by BUG-025 + FEAT-012; TEST-003 confirmed open, e2e now unblocked by TECH-014. Carry-over filed: **BUG-028**, **TECH-015**. Previously: 2026-07-12 v0.8.0 RELEASED — tag on main, milestone #14 closed; baseline at test-baselines/v0.8.0-dogfood.md)
**Format**: Work items for active development

---

## ID conventions

| Prefix | Category | Example |
|--------|----------|---------|
| FEAT | Features | FEAT-001 |
| BUG | Bug fixes | BUG-001 |
| TECH | Technical tasks | TECH-001 |
| DEBT | Technical debt | DEBT-001 |

**Status values**: `planned` | `in_progress` | `blocked` | `completed`

> **Note**: Ideas and proposals are in `ideas.md`. Requirements are in `requirements.md`.

---

## In progress

### QUAL-001: Development tools suite (/s2s:dev:*)

**Status**: in_progress | **Created**: 2026-01-11 | **Updated**: 2026-07-13

**Context**: S2S development requires consistent adherence to patterns and ability to test resume/resilience. Development tools live in the plugin tree (`commands/dev/`, `agents/dev/`, `skills/dev-testing/`).

**Re-triage (2026-07-13, v0.9.0 pre-cycle)**: the original Context claimed the dev tools were "excluded from release". That was **false** — nothing excluded them: `marketplace.json` declares `"source": "./"` (the whole repo tree is the plugin), `plugin.json` has no `files`/`exclude` field, `.github/workflows/` has no release job and the Makefile states there is no build. The tools ship to every user. The exclusion work is now owned by **BUG-027**; this item keeps only the check-implementation work.

**Structure**:
```
skills/dev-testing/          # Check definitions + test specs
├── SKILL.md                 # Overview
├── references/
│   ├── check-registry.md    # INST-*, CONS-*, RES-*, EDGE-* definitions
│   └── roundtable-tests.md  # Roundtable-specific test cases (TECH-002)
agents/dev/dev-validator.md  # Unified agent
commands/dev/check.md        # /s2s:dev:check
commands/dev/test.md         # /s2s:dev:test
```

**Check categories** (from check-registry.md):
- ENV-* (7): Environment verification ✓ implemented
- VAL-RT-* (5): Session validation ✓ implemented
- INST-* (10): Instruction quality
- CONS-* (7): Consistency between commands
- RES-* (7): Resume capability
- EDGE-* (7): Edge cases

**Roundtable test categories** (from roundtable-tests.md):
- ENV-* (7): Environment checks - `auto`
- VAL-RT-* (5): Session validation - `auto`
- RES-RT-* (7): Resume tests - `semi`
- DIAG-RT-* (3): Diagnostic tests - `manual`
- EDGE-RT-* (7): Edge cases - mixed
- REG-* (5): Regression tests - `semi`

**Tasks**:
- [x] Create dev-testing skill with check definitions
- [x] Create dev-validator agent
- [x] Create check.md and test.md commands
- [x] Document in s2s-development.md
- [x] Create roundtable-tests.md with test specifications
- [x] Implement ENV-* checks in dev-validator (7 checks, all tested)
- [x] Implement VAL-RT-* checks in dev-validator (5 checks, all tested)
- [~] ~~Add release exclusion in .github/~~ → moved to **BUG-027** (never done; see re-triage above)
- [ ] Implement RES-RT-* state checks in dev-validator (priority 2)

**RES-RT-\* current state (2026-07-13)**: defined only. The 7 cases are specified in `skills/dev-testing/references/roundtable-tests.md` (RES-RT-001..007, still listed under "Pending — QUAL-001 Priority 2"); `agents/dev/dev-validator.md` has a generic 4-step RES stub with no per-check logic, its `categories` enum does not accept `RES-RT`, and `commands/dev/test.md` maps `--resume` → `["RES"]`. **Same edit as TEST-003's CTX-\*** — both need the dev-validator `categories` enum widened and the RES/EDGE stubs filled. Do them together.

**Acceptance criteria**:
- [~] `/s2s:dev:check` runs INST-*, CONS-*, ENV-* checks (ENV-* done)
- [~] `/s2s:dev:test` runs RES-*, EDGE-*, VAL-RT-* tests (VAL-RT-* done)
- [ ] ~~Tools NOT included in shipped plugin~~ → owned by **BUG-027**

---

### TEST-003: Session resilience verification

**Status**: in_progress | **Created**: 2026-01-18 | **Updated**: 2026-07-13 | **Linked to**: TECH-002 Phase 0, BUG-003, QUAL-001

**Context**: Roundtable sessions can be interrupted at various points. Need verification that resume works correctly.

**Note**: This task is foundational for TECH-002. Test cases created here become the baseline for validating refactoring does not cause regression.

**Location correction (2026-06-13 audit)**: written pre-TECH-002. There are no "inline commands" anymore: specs/design/brainstorm are thin launchers and resume logic is unified in `commands/roundtable.md` + `skills/roundtable-execution/references/phase-2-core.md` (§2.2a/§2.3a/§2.4). `session-qa` now exposes STR-*/STRAT-*/DIAG-* (not TRANS-*); CTX-* remain defined-only in `skills/dev-testing/references/roundtable-tests.md`. The live behavioral gap this item still owns (interrupted-round detection + recovery choice on resume) is VKT-007 in the Vektra analysis doc-set.

**Re-triage (2026-07-13, v0.9.0 pre-cycle)**: all four open tasks verified still open against current code. Detail:
- `agents/validation/session-qa.md` implements STR-001..006, STRAT-D1/D2, DIAG-001..003 — and nothing else. The closest thing to a transition check is STR-002, which validates that an artifact's state *value* is legal for its type, not that a *transition* between states is. No lifecycle/interrupted-round checks.
- CTX-001..005 are defined (`roundtable-tests.md`, `check-registry.md`) but unimplemented: `dev-validator.md` does not accept a `CTX` category. **Live doc/code contradiction**: `check-registry.md` documents the invocation `/s2s:dev:test --context`, but `commands/dev/test.md` has no such flag. Fix that regardless of the rest.
- `error-handling.md` is 54 lines: it has fail-fast on write failure, round-level partial recovery, and corruption *detection*. It has no mid-write protocol — no atomic write (temp+rename), no backup, and no reconciliation when `state.json` and the session YAML disagree (they are written by separate Write calls, so a crash between them leaves them divergent with nothing to repair them).
- The e2e resume tests are now **unblocked**: the procedure that was missing when this item was written now ships (`skills/dev-testing/references/dogfood-e2e.md`, TECH-014) and the manual interruption steps are in `roundtable-tests.md`. This task is now "execute the runbook", not "invent one".

**Tasks**:
- [x] ~~Align roundtable.md resume logic with inline commands~~ (obsolete: resume unified by TECH-002, no inline path left)
- [ ] Add state-transition checks to session-qa (current nomenclature: STR-*/STRAT-*/DIAG-*)
- [x] Define CTX-* checks in roundtable-tests.md (5 checks defined)
- [ ] Implement CTX-* in dev-validator (verbose dump analysis) — same edit as QUAL-001's RES-RT-*: widen the `categories` enum, fill the stubs, add the `--context` flag to `test.md`
- [ ] Enhance error-handling.md with mid-write recovery (atomic write + state.json/session-YAML reconciliation on resume)
- [ ] Run end-to-end resume tests using the dogfood-e2e runbook (partial: environment verified)
- [x] Create `skills/dev-testing/references/roundtable-tests.md` (for TECH-002)

**Acceptance criteria**:
- [ ] Resume works from all 7 critical interruption points
- [~] STR-*, CTX-* checks in session-qa (CTX defined, implementation pending; `TRANS-*` never existed post-TECH-002 — nomenclature corrected)
- [x] Baseline tests documented for TECH-002

---

## Planned

### QUAL-002: Execution compliance checks (EXEC-*)

**Status**: planned | **Created**: 2026-01-25 | **Priority**: medium

**Context**: Token tracking is always active (v2.3.0). Optional features (`--verbose`, `--diagnostic`) still require LLM to follow instructions. Post-hoc evidence-based validation catches skipped instructions.

**Principle**: Verify AFTER execution by checking artifacts, not DURING (inline validation adds skippable instructions).

**Proposed checks** (for session-qa agent):

| Check | Applies When | Evidence |
|-------|--------------|----------|
| EXEC-001 | always (token tracking) | `.s2s/sessions/{id}.cache` has entries per round |
| EXEC-002 | verbose_flag used | `rounds/*.yaml` dump files exist for each round |
| EXEC-003 | diagnostic_flag used | session-observer findings in session file |

**Tasks**:
- [ ] Add EXEC-* section to `agents/validation/session-qa.md`
- [ ] Implement EXEC-001 (token tracking compliance)
- [ ] Implement EXEC-002 (verbose dump compliance)
- [ ] Implement EXEC-003 (diagnostic compliance)
- [ ] Update `/s2s:session:validate` to show EXEC-* results

**Acceptance criteria**:
- [ ] `/s2s:session:validate` reports if features were properly executed
- [ ] Evidence files include EXEC-* results
- [ ] Clear indication when compliance failed

**Related**: s2s-development.md → "Validation Strategy: Post-Hoc Evidence-Based"

---

### TECH-008: Config-based feature toggles

**Status**: planned | **Created**: 2026-01-25 | **Priority**: low

**Context**: Token tracking and statusline setup are now always active. Some users may want to disable them for performance or simplicity. Add config options to toggle features.

**Proposed config.yaml additions**:
```yaml
features:
  token_tracking: true    # Enable/disable token tracking during roundtables
  statusline_setup: true  # Enable/disable statusline auto-setup in /s2s:init
```

**Implementation notes**:
- Default: both true (current behavior)
- If `token_tracking: false`, skip all token-tracking.md sections in SKILL.md
- If `statusline_setup: false`, skip Phase 5.5b in init.md

**Tasks**:
- [ ] Add `features:` section to templates/project/config.yaml
- [ ] Update SKILL.md to check config before token tracking
- [ ] Update init.md to check config before statusline setup
- [ ] Document in s2s-guide

**Acceptance criteria**:
- [ ] Token tracking can be disabled via config
- [ ] Statusline setup can be disabled via config
- [ ] Existing projects without `features:` section use defaults

---

### TECH-009: Round token tracking con precisione progressiva

**Status**: completed | **Created**: 2026-01-26 | **Completed**: 2026-01-26 | **Priority**: high | **Depends on**: TECH-002 Phase 6

**Context**: Token tracking attuale salva solo dati temporanei nel cache file (`.s2s/sessions/{id}.cache`). I dati per-round NON vengono persistiti nel session file. Serve persistere il consumo di token di ogni round per:
1. Stimare se il prossimo round supererà la soglia (95%)
2. Calcolare media token/round per decisioni intelligenti
3. Visualizzare nella statusline
4. Analisi post-sessione

**Problema attuale**: Il valore `T3-T1` (delta subagent) sottostima il consumo reale perché esclude l'overhead dell'orchestrator tra T3 di un round e T1 del successivo.

**Soluzione**: Precisione progressiva con due misurazioni:
- `estimate`: T3_n - T1_n (disponibile subito, sottostima, mostrato con ~)
- `actual`: T1_{n+1} - T1_n (disponibile al round successivo, preciso)

---

**Schema dati session file** (aggiungere a `metrics:`):

```yaml
metrics:
  rounds_completed: 3
  tokens:
    total: 45000           # Totale accumulato finale
    by_round:              # Array con dettaglio per round
      - round: 1
        estimate: 12000    # T3-T1 (immediato, con ~)
        actual: 14500      # T1_2 - T1_1 (calcolato al round 2)
        source: "measured" # measured | estimated | interrupted
      - round: 2
        estimate: 15000
        actual: 17200
        source: "measured"
      - round: 3
        estimate: 18000
        actual: null       # Non ancora calcolato (ultimo round o sessione chiusa)
        source: "estimated"

    # Statistiche aggregate (calcolate dallo script)
    stats:
      avg_actual: 15850        # Media dei soli "actual" (più precisa)
      avg_estimate: 15000      # Media dei soli "estimate"
      overhead_delta: 2200     # Media(actual - estimate) = overhead orchestrator tipico
      sample_count: 2          # Quanti round hanno "actual" valido
```

---

**Logica di aggiornamento** (tutto in token-tracker.sh):

**1. Fine round N (comando `recap`)**:
```bash
# Calcola estimate del round corrente
round_estimate = T3 - T1

# Output nuova variabile per SKILL.md
echo "ROUND_TOKENS_ESTIMATE=${round_estimate}"
```

SKILL.md scrive nel session file:
```yaml
rounds:
  - round: N
    # ... altri campi ...
    tokens_estimate: {ROUND_TOKENS_ESTIMATE}  # Nuovo campo
```

E aggiorna `metrics.tokens.by_round` (append o update).

**2. Inizio round N+1 (comando `init`)**:

Lo script deve:
1. Leggere `lastT1` dal cache file (T1 del round precedente)
2. Leggere `lastT3` dal cache file (T3 del round precedente)
3. Confrontare T1_new con T3_old per detect interruzioni

```bash
# Detect interruzione
if [[ $T1_NEW -lt $T3_OLD ]]; then
    # /compact o /clear detected - gap negativo impossibile
    PREV_ROUND_SOURCE="interrupted"
    PREV_ROUND_ACTUAL=""
elif [[ -z "$LAST_T1" ]]; then
    # Primo round o cache mancante
    PREV_ROUND_SOURCE="estimated"
    PREV_ROUND_ACTUAL=""
else
    # Continuità normale - calcola actual
    PREV_ROUND_ACTUAL=$((T1_NEW - LAST_T1))
    PREV_ROUND_SOURCE="measured"
fi

# Output per SKILL.md
echo "PREV_ROUND_ACTUAL=${PREV_ROUND_ACTUAL}"
echo "PREV_ROUND_SOURCE=${PREV_ROUND_SOURCE}"
```

SKILL.md aggiorna il round N-1 nel session file:
```yaml
metrics:
  tokens:
    by_round:
      - round: N-1
        estimate: 15000
        actual: 17200        # ← aggiornato
        source: "measured"   # ← aggiornato
```

**3. Calcolo statistiche (comando `init` o nuovo `stats`)**:

```bash
# Legge by_round dal session file (o cache)
# Calcola medie solo sui valori validi

actuals=(lista di actual dove source=="measured")
estimates=(lista di estimate)

if [[ ${#actuals[@]} -ge 2 ]]; then
    AVG_ACTUAL=$(media actuals)
    OVERHEAD_DELTA=$(media (actual - estimate per ogni round measured))
    NEXT_ESTIMATE=$AVG_ACTUAL
elif [[ ${#actuals[@]} -eq 1 ]]; then
    AVG_ACTUAL=${actuals[0]}
    NEXT_ESTIMATE=$AVG_ACTUAL
else
    # Solo stime disponibili
    AVG_ESTIMATE=$(media estimates)
    NEXT_ESTIMATE=$(awk "BEGIN {print int($AVG_ESTIMATE * 1.2)}")  # +20% buffer
fi

echo "AVG_ACTUAL_K=$(($AVG_ACTUAL / 1000))"
echo "AVG_ESTIMATE_K=$(($AVG_ESTIMATE / 1000))"
echo "OVERHEAD_DELTA_K=$(($OVERHEAD_DELTA / 1000))"
echo "NEXT_ESTIMATE_K=$(($NEXT_ESTIMATE / 1000))"
echo "SAMPLE_COUNT=${#actuals[@]}"
```

**4. Stima prossimo round e soglie**:

```bash
PROJECTED_TOTAL=$((CURRENT_TOKENS + NEXT_ESTIMATE))
PROJECTED_PCT=$(awk "BEGIN {printf \"%.0f\", ($PROJECTED_TOTAL / 200000) * 100}")

if [[ $PROJECTED_PCT -ge 95 ]]; then
    SHOULD_STOP=true
    SHOULD_WARN=false
elif [[ $PROJECTED_PCT -ge 85 ]]; then
    SHOULD_STOP=false
    SHOULD_WARN=true
else
    SHOULD_STOP=false
    SHOULD_WARN=false
fi

echo "PROJECTED_TOTAL_K=$(($PROJECTED_TOTAL / 1000))"
echo "PROJECTED_PCT=${PROJECTED_PCT}"
echo "SHOULD_STOP=${SHOULD_STOP}"
echo "SHOULD_WARN=${SHOULD_WARN}"
```

---

**Euristica "altri comandi utente"** (opzionale, fase 2):

Se `actual - estimate > 3 * overhead_delta` potrebbe indicare che l'utente ha fatto altri comandi tra i round. In tal caso:
- Marcare `source: "noisy"` invece di `measured`
- Escludere dal calcolo della media actual
- Usare estimate per quel round

```bash
if [[ $PREV_ROUND_ACTUAL -gt 0 && $OVERHEAD_DELTA -gt 0 ]]; then
    THRESHOLD=$((3 * OVERHEAD_DELTA))
    DELTA=$((PREV_ROUND_ACTUAL - PREV_ROUND_ESTIMATE))
    if [[ $DELTA -gt $THRESHOLD ]]; then
        PREV_ROUND_SOURCE="noisy"
    fi
fi
```

---

**Modifiche ai file**:

1. **`skills/roundtable-execution/scripts/token-tracker.sh`**:
   - Aggiungere `lastT1` al cache file (oltre a lastT3)
   - `init`: calcolare e outputtare PREV_ROUND_ACTUAL, PREV_ROUND_SOURCE, NEXT_ESTIMATE_K, SHOULD_STOP, SHOULD_WARN
   - `recap`: outputtare ROUND_TOKENS_ESTIMATE
   - Nuovo comando `stats` (opzionale): calcolare statistiche standalone

2. **`skills/roundtable-execution/SKILL.md`**:
   - Step 2.1: usare PREV_ROUND_ACTUAL/SOURCE per aggiornare round precedente
   - Step 2.1: usare SHOULD_STOP/SHOULD_WARN per decidere se continuare
   - Step 2.7: salvare ROUND_TOKENS_ESTIMATE nel session file

3. **`skills/roundtable-execution/references/session-schema.md`**:
   - Aggiornare schema `metrics.tokens` con nuovo formato

4. **`skills/roundtable-execution/references/token-tracking.md`**:
   - Documentare nuovo flusso di precisione progressiva
   - Aggiornare box output con statistiche

---

**Display boxes aggiornati**:

**Init (Round > 1)**:
```
┌─────────────────────────────────────────────────────────────┐
│ CONTEXT STATUS (Round 3 Start)              [statusline]    │
├─────────────────────────────────────────────────────────────┤
│ Current usage:     78k tokens (39%)                         │
│ Previous round:    17.2k (actual, updated from ~15k est)    │
│ Avg per round:     16.5k (2 samples)                        │
│ Next estimate:     ~16.5k                                   │
│ Projected:         94.5k (47%) ✓ OK                         │
│ Status:            [######----------] [OK]                  │
└─────────────────────────────────────────────────────────────┘
```

**Recap (fine round)**:
```
┌─────────────────────────────────────────────────────────────┐
│ TOKEN BREAKDOWN (Round 3)                   [statusline]    │
├─────────────────────────────────────────────────────────────┤
│ Facilitator (question):     2.1k tokens                     │
│ Participants (4):           8.2k tokens (2.1k avg)          │
│ Facilitator (synthesis):    3.8k tokens                     │
│ ─────────────────────────────────────────────────────────── │
│ Round subagents:            14.1k tokens                    │
│ ~Orchestrator gap:          ~2.4k tokens                    │
│ Round estimate:             ~16.5k (will refine next round) │
│ ─────────────────────────────────────────────────────────── │
│ Context total:              94.5k tokens (47%)              │
│ Status:                     [#########-------] [OK]         │
└─────────────────────────────────────────────────────────────┘
```

---

**Tasks**:
- [x] Aggiornare token-tracker.sh con lastT1 nel cache
- [x] Aggiungere output PREV_ROUND_ACTUAL, PREV_ROUND_SOURCE a init
- [x] Aggiungere output ROUND_TOKENS_ESTIMATE a recap
- [x] Aggiungere calcolo statistiche (AVG_ACTUAL, NEXT_ESTIMATE) a init
- [x] Aggiungere output SHOULD_STOP, SHOULD_WARN a init
- [x] Aggiornare SKILL.md Step 2.0 per salvare actual del round precedente
- [x] Aggiornare SKILL.md Step 2.7 per salvare estimate del round corrente
- [x] Aggiornare session-schema.md con nuovo formato metrics.tokens
- [x] Aggiornare token-tracking.md con documentazione
- [ ] Test: verificare che estimate viene salvato
- [ ] Test: verificare che actual viene aggiornato al round successivo
- [ ] Test: verificare SHOULD_STOP quando proiezione > 95%
- [ ] Test: verificare detect /compact (gap negativo)

**Acceptance criteria**:
- [x] Ogni round ha `estimate` salvato nel session file (instructions added)
- [x] Round precedenti hanno `actual` aggiornato (quando continuità) (instructions added)
- [x] Sessione si ferma automaticamente se SHOULD_STOP=true
- [x] Warning mostrato se SHOULD_WARN=true
- [x] Interruzioni (/compact, /clear) correttamente rilevate
- [x] Statistiche `avg_actual`, `overhead_delta` calcolate correttamente

---

### TECH-010: Evaluate compact option in mid-round user prompts

**Status**: planned | **Created**: 2026-02-02 | **Priority**: low

**Context**: During a design session at round 3 completion, the system detected:
- `min_rounds` reached (3/3)
- Context at 72% (56k remaining)
- Session had 4 architecture decisions, 3 component specs, 2 open questions

The system presented 4 options to the user:
1. Continue (1-2 more rounds)
2. Conclude now
3. Quick round then conclude
4. Type something

**Observation**: No "compact" option was offered. At 72% context usage, this is a first warning level (not critical), so the compact mechanism may not have triggered. However, offering compact as a proactive option could help users manage context before hitting critical thresholds.

**Questions to investigate**:
1. Should "Compact and continue" be a standard option in mid-round prompts?
2. At what context % threshold should compact be suggested (70%? 80%)?
3. Should compact be automatic at certain thresholds vs user-initiated?
4. What happens to session state after compact? (Round continuity, artifact retention)

**Location correction (2026-06-13 audit)**: written pre-TECH-002. The four per-command prompts no longer exist; the single mid-round prompt for all workflows is `skills/roundtable-execution/references/phase-2-core.md` Step 2.8 (Continue / conclude / exit, still no compact option — premise confirmed still open on current code).

**Tasks**:
- [ ] Review mid-round prompt logic in phase-2-core.md Step 2.8 (unified for all 4 workflows post-TECH-002)
- [ ] Determine if compact option should be added to standard options
- [ ] Define context threshold for suggesting compact (if applicable)
- [ ] Document decision (ADR if significant change)

**Acceptance criteria**:
- [ ] Mid-round options behavior documented for all commands
- [ ] Decision made: add compact option or document why not needed
- [ ] If adding: consistent implementation across all commands

**Related**: TECH-002 (roundtable unification), Phase 6b (context capacity check)

---

### DOC-001: Document jq as recommended dependency

**Status**: planned | **Created**: 2026-01-25 | **Priority**: low

**Context**: The context-reset.sh hook and other bash scripts use jq for JSON parsing. Scripts now have graceful degradation (work without jq using grep/sed fallback), but jq provides better performance and full functionality.

**Tasks**:
- [ ] Add "Prerequisites" section to docs/README.md mentioning jq
- [ ] Document installation commands for macOS, Linux, Windows
- [ ] Note that scripts work without jq but with reduced functionality
- [ ] Consider adding jq check to /s2s:init with installation suggestion

**Acceptance criteria**:
- [ ] Users know jq is recommended before using s2s
- [ ] Clear installation instructions for all platforms

---

### BUG-001: Agent resume fails across Claude sessions

**Status**: planned | **Created**: 2026-01-20 | **Priority**: low

**Context**: When resuming a roundtable session after restarting Claude, the command attempts to resume saved `agent_id` but fails because agent transcripts are session-scoped (not persisted across Claude restarts).

**Error observed**:
```
resuming aaf0f99
Error: No transcript found for agent ID: aaf0f99
```

**Root cause**: Agent IDs and transcripts exist only within a single Claude CLI session. When Claude is restarted, the transcripts are lost but the session file still contains the old agent_id.

**Location correction (2026-06-13 audit)**: premise confirmed still real on current code, but the resume logic moved: post-TECH-002 it lives in `skills/roundtable-execution/references/phase-2-core.md` §2.2a/§2.3a/§2.4 (not "workflow commands"). Resume still gates only on `agent_id != null AND round > 0` with no transcript-existence pre-check. Priority stays low: the harness fallback already degrades to a fresh agent after the error (solution 3 de facto). Sibling completed fix: BUG-014 (within-session delegated-master resume).

**Possible solutions**:
- [ ] Detect if transcript exists before attempting resume (official method TBD)
- [ ] Clear agent_id on session load if Claude session is new
- [ ] Accept the error and continue with fresh agent (current behavior after error)

**Tasks**:
- [ ] Research official method to check transcript existence
- [ ] Implement pre-check before resume attempt
- [ ] Update session resume logic in phase-2-core.md (§2.2a/§2.3a/§2.4)

**Acceptance criteria**:
- [ ] No failed resume attempts when Claude is restarted
- [ ] Session continues smoothly with fresh agents

---

### BUG-002: Consensus threshold 0.67 rejects exact 2/3 majority

**Status**: completed | **Created**: 2026-01-20 | **Completed**: 2026-05-29 | **Priority**: medium | **Target**: v0.5.0

**Context**: The threshold for 2/3 majority consensus is set to 0.67 in config files, but 2/3 = 0.6666... which means exact 2/3 votes fail the `>=0.67` check when participants are divisible by 3.

**Affected files**:
- `templates/project/config.yaml:38,55` (threshold: 0.67)
- `.s2s/config.yaml:32,49` (threshold: 0.67)

**Note**: Skill references already use 0.6 (`skills/roundtable-strategies/references/standard.md`, `disney.md`).

**Impact**: With 3, 6, or 9 participants, a 2/3 vote (0.6666...) does NOT pass threshold 0.67.

| Participants | Votes for 2/3 | Proportion | Passes 0.67? |
|--------------|---------------|------------|--------------|
| 3 | 2 | 0.6666 | NO |
| 6 | 4 | 0.6666 | NO |
| 9 | 6 | 0.6666 | NO |

**Fix applied (2026-05-29)**: changed both `standard` and `six-hats` thresholds from 0.67 to 0.6 in `templates/project/config.yaml` and `.s2s/config.yaml`; comments now read "60% (ensures an exact 2/3 majority passes)".

**Tasks**:
- [x] Update `templates/project/config.yaml` threshold values to 0.6
- [x] Update `.s2s/config.yaml` threshold values to 0.6
- [x] Update comment from "2/3 majority" to "60% (ensures 2/3 passes)"

**Acceptance criteria**:
- [x] All threshold values aligned to 0.6
- [x] Exact 2/3 votes pass consensus check

---

### BUG-003: SKILL.md uses context_files instead of inline context

**Status**: completed | **Created**: 2026-01-21 | **Completed**: 2026-01-21 | **Priority**: critical

**Context**: SKILL.md Step 2.2 and 2.3 used `context_files` pattern (file paths) instead of inline `context`. Participants have `tools: []` and cannot read files, so this broke context propagation.

**Root cause**: SKILL.md had outdated instructions from an earlier design. The specs.md, design.md, brainstorm.md commands had correct inline context passing, but roundtable.md relies on SKILL.md.

**Impact**:
- Participants received file paths they couldn't read
- Context not propagated correctly in roundtable.md sessions
- Session resume from scratch would fail to provide adequate context

**Fix applied** (2026-01-21):
1. Step 2.2: Changed facilitator response from `context_files` to `participant_context` block
2. Step 2.2: Added `project_context` and `session_state` to facilitator input
3. Step 2.3: Changed participant input from `context_files` to inline `context` block
4. Added explicit comments about participants having NO tools

**Files modified**:
- `skills/roundtable-execution/SKILL.md`

**Location correction (2026-06-13 audit)**: fix shipped and carried forward through TECH-002 (CHANGELOG v0.4.0), but the "SKILL.md Step 2.2/2.3" references above are pre-refactor: that logic now lives in `skills/roundtable-execution/references/phase-2-core.md` §2.2/§2.3 (inline context passing confirmed there, see also BUG-005).

**Related**: TEST-003 (context propagation checks)

---

### BUG-004: Verbose dumps not written incrementally during round

**Status**: completed | **Created**: 2026-01-22 | **Updated**: 2026-05-28 | **Completed**: 2026-06-06 | **Priority**: high | **Target**: v0.5.0 | **Verified**: see test-baselines/v0.5.0-dogfood.md

**Context**: Verbose dump files (`rounds/{NNN}-01-*.yaml`, `rounds/{NNN}-02-*.yaml`, `rounds/{NNN}-03-*.yaml`) are not written immediately after each phase. The command waits until the round completes before writing to disk.

**Root cause**: Instructions for verbose dump writes do NOT include "NOW" or "IMMEDIATELY":
- specs.md:703 - "IF verbose_flag == true: Write dump..." (no NOW)
- specs.md:957 - "IF verbose_flag == true: Write dump for each..." (no NOW)
- specs.md:1212 - "IF verbose_flag == true: Write dump..." (no NOW)

Compare with session file writes which use "YOU MUST use Edit tool **NOW**".

**Critical finding (2026-01-30)**: `--interactive` mode causes **complete dump loss**, not just delayed writes.

When `--interactive` is true:
1. Round executes (Steps 2.1-2.7), dump writes are "planned" but not executed
2. Step 2.8 calls `AskUserQuestion` - this **interrupts the LLM turn**
3. User responds, LLM resumes from new context
4. Planned writes from previous turn are **lost**
5. Result: `rounds/` directory exists but is empty after N completed rounds

**Evidence** (Vektra project, session `20260129-specs-vektra`):
- `config-snapshot.yaml` shows `verbose: true`, `interactive: true`
- `rounds/` directory created (mkdir worked in Phase 1)
- 7 rounds completed (`agent_state.*.last_round: 7`)
- `rounds/` directory is **empty** - zero dump files

Without `--interactive`, all rounds execute in one LLM turn, so deferred writes may still occur.

**Impact**:
- **CRITICAL**: With `--interactive`, verbose dumps are **never written** (not just delayed)
- If execution interrupted mid-round, verbose dumps for completed phases may be lost
- No incremental visibility into round progress
- Resume cannot recover partial round data from disk
- EXEC-002 validation fails for interactive sessions with verbose flag

**Affected files** (corrected 2026-05-28 — original refs were pre-v0.4.0 thin-launcher refactor; the round-loop logic is now consolidated in a single file):
- `skills/roundtable-execution/references/phase-2-core.md` — §2.2e (dump 01 facilitator-question), §2.3e (dump 02 participant), §2.4e (dump 03 synthesis). The §2.6c observer dump (04) already persists via FIX-S1.

The pre-refactor commands (`specs.md` / `design.md` / `brainstorm.md`) and `SKILL.md` no longer carry per-phase dump write instructions — they delegate to `phase-2-core.md`. Original line numbers (specs.md:703 etc.) no longer exist (files are now 78–172-line thin launchers).

**Fix applied (2026-05-28)**: Added "**YOU MUST use the Write tool NOW** ... before proceeding to the next step. Do NOT defer this write: in `--interactive` mode a later `AskUserQuestion` ends the turn and any deferred write is lost (BUG-004)." to dumps 01/02/03 in phase-2-core.md.

**Tasks**:
- [x] Add "YOU MUST use Write tool NOW" to dump 01 (facilitator question) — phase-2-core.md §2.2e
- [x] Add "YOU MUST use Write tool NOW" to dump 02 (participant) — phase-2-core.md §2.3e
- [x] Add "YOU MUST use Write tool NOW" to dump 03 (synthesis) — phase-2-core.md §2.4e
- [ ] Dogfood-verify in ElfGiftRush_s2s/exp*: `/s2s:specs --verbose --interactive`, 2+ rounds, confirm `rounds/` has 3 files per round

**Acceptance criteria**:
- [ ] Verbose dumps written immediately after each phase (2.2, 2.3, 2.4)
- [ ] Partial round data recoverable if interrupted
- [ ] **With `--verbose --interactive`**: dumps exist in `rounds/` after user continues
- [ ] Each dump file written before proceeding to next step (not batched)

**Test scenario**:
```bash
/s2s:specs --verbose --interactive
# Complete 2+ rounds with "Continue" responses
# Verify: .s2s/sessions/{id}/rounds/ contains 6+ files (3 per round)
```

**Related**: TEST-003 (session resilience)

---

### BUG-006: Token tracker compact detection missing

**Status**: completed | **Created**: 2026-01-24 | **Completed**: 2026-01-24

**Context**: When `/compact` occurs between rounds, the token tracker calculates a negative orchestrator gap because current tokens (post-compact) are lower than lastT3 (pre-compact).

**Resolution**: Fixed in token-tracker.sh v3.0.0 (lines 241-245):
```bash
if [[ $ORCHESTRATOR_GAP -lt 0 ]]; then
    ORCHESTRATOR_GAP=0
    COMPACT_DETECTED="true"
fi
```
Script now outputs `COMPACT_DETECTED=true` and UI shows "[compact detected]" note.

**Error observed**:
```
Round 1: T3 = 156k, saved in lastT3
/compact → context reduced to 42k
Round 2: init → orchestratorGapThisRound = 42k - 156k = -114k ❌
```

**Root cause**: The init command (lines 209-213) calculates `ORCHESTRATOR_GAP=$((ROUND_START_TOKENS - LAST_T3))` without checking if the result is negative, which indicates a compact occurred.

**Fix proposed**:
```bash
# In token-tracker.sh, init command, after calculating ORCHESTRATOR_GAP
if [[ $ORCHESTRATOR_GAP -lt 0 ]]; then
    # Compact detected - reset gap and flag it
    ORCHESTRATOR_GAP=0
    COMPACT_DETECTED=true
fi
```

**Tasks**:
- [ ] Add compact detection to init command
- [ ] Reset orchestratorGapThisRound to 0 when compact detected
- [ ] Optionally display "[compact detected]" indicator in output
- [ ] Update session file to note compact occurred

**Acceptance criteria**:
- [ ] No negative gap values after /compact
- [ ] Token tracking continues correctly post-compact
- [ ] User informed that compact was detected

**Related**: TECH-004 (token tracker improvements)

---

### BUG-013: Session-observer Step 2.6c silently skipped at runtime

**Status**: completed | **Created**: 2026-05-14 | **Updated**: 2026-05-29 | **Completed**: 2026-06-06 | **Priority**: medium | **Target**: v0.5.0 (verify-and-close)  | **Verified**: see test-baselines/v0.5.0-dogfood.md| **Related**: TECH-002 Phase 7B (baseline finding F2)

**Context**: Step 2.6c (Diagnostic Observation, per-round) is consistently skipped by the LLM during roundtable execution despite `diagnostic_flag == true`. Confirmed via exp42/exp43 dogfood: 0 session-observer invocations leave any persistence trail in design and brainstorm baselines (2026-05-13).

**Investigation summary (TECH-002 Phase 7B sub-phase 7B.2, 2026-05-14)**:
Root cause is mixed (spec ambiguity + runtime quirk). Five contributing factors:
1. Display-only output (no file artifact = no LLM commitment proof)
2. Step position in housekeeping cluster (between 2.6b and 2.7, both display-only)
3. Token budget pressure (6 → 7 agent invocations per round)
4. `IF diagnostic_flag == true` indirection (flag in config-snapshot)
5. SKILL.md has NO Step 2.6c (commands do; skill missing it)

Full investigation in `.s2s/plans/20260506-tech002-phase7b-deep-extraction.md` §7B.2.

**Fix planned in Phase 7B.4a/4b**:
- FIX-S1: persist observer output to `rounds/{NNN}-04-session-observer.yaml`
- FIX-S2: MANDATORY language ("MUST", "DO NOT skip")
- FIX-S3: SKILL.md alignment via 7B.5 (cross-reference to phase-2-core.md Step 2.6c)
- Update `verbose-dump-format.md` with new dump naming

**Acceptance**: exp44 replay shows ≥3/3 (specs/design/brainstorm) session-observer dump files per round when `--diagnostic` flag is set.

**Re-triage (2026-05-29)**: the planned mitigation is confirmed present in the current code:
- FIX-S1 persistence — `phase-2-core.md` §2.6c: `write rounds/{NNN}-04-session-observer.yaml ... (MANDATORY)` (L725).
- FIX-S2 MANDATORY language — `phase-2-core.md` §2.6c: "**MANDATORY when `DIAGNOSTIC_FLAG == true`.** Do NOT skip this step." (L689).
- Dump naming documented in `verbose-dump-format.md` (FIX-S1, BUG-013).
- Step 2.6c now lives in the single canonical `phase-2-core.md` consumed by all commands (the old FIX-S3 "SKILL.md missing 2.6c" gap is structurally gone post-v0.4.0).

The code mitigation is therefore complete; what remains is the empirical confirmation. **Folded into the v0.5.0 batch dogfood** (≥3/3 observer dump files per round under `--diagnostic`). Close once that replay passes. (BUG-015's R1 false-positive guard touches the same observer and is verified in the same run.)

### BUG-012: Token tracker non si riattiva dopo compact + resume

**Status**: completed | **Created**: 2026-02-02 | **Updated**: 2026-05-28 | **Completed**: 2026-06-06 | **Priority**: high | **Target**: v0.5.0 | **Verified**: see test-baselines/v0.5.0-dogfood.md

**Context**: Dopo `/compact`, quando si fa resume di una sessione roundtable, il token tracker non si riattiva. Di conseguenza, non tracciando più i token, il roundtable non è in grado di fermarsi quando sta per finire il contesto.

**Scenario**:
1. Roundtable in corso, round 2 completato
2. Utente esegue `/compact` (o auto-compact triggered)
3. Utente fa resume: `/s2s:specs --session {id}`
4. Token tracker NON si riattiva
5. Step 2.0d (context capacity check) non funziona
6. Roundtable continua fino a esaurimento contesto

**Root cause**: SKILL.md Step 2.0a ha questa condizione:

```
IF first round OR TOKEN_SCRIPT not set: resolve script path
```

Dopo compact + resume:
- `round_number` viene letto dal session file (es. 2) → NON è "first round"
- `TOKEN_SCRIPT` dovrebbe essere "not set" perché il contesto LLM è stato compattato
- Ma il LLM potrebbe non valutare correttamente "not set" (variabile non esiste vs variabile vuota vs "ricordo" residuo)

Il token-tracking.md (riga 31) dice:
> **At first round or after resume**, use the Read tool to get the resolved script path

Ma questa condizione "after resume" non è esplicitamente implementata in SKILL.md.

**Impatto**:
- Token tracking silenziosamente disabilitato dopo compact
- SHOULD_STOP mai true → sessione continua oltre capacità
- Context overflow → comportamento imprevedibile o errore

**Fix proposto**:

Opzione A - Controllo esplicito resume:
```markdown
#### Step 2.0a: Token tracking setup (execute EVERY round)

1. **IF first round OR is_resume OR TOKEN_SCRIPT not set**:
   Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-tracking.md`
   and execute "Script Location" section to get TOKEN_SCRIPT path

**Detect resume**: `is_resume = true` if session file exists AND `metrics.rounds_completed > 0`
```

Opzione B - Setup incondizionato (più robusto):
```markdown
#### Step 2.0a: Token tracking setup (ALWAYS execute)

**ALWAYS** read the script path at the start of EVERY round, regardless of whether
TOKEN_SCRIPT appears to be set. After /compact or /clear, LLM context variables
are lost and must be re-initialized.
```

**Raccomandazione**: Opzione B - setup incondizionato. Il costo di una Read aggiuntiva è trascurabile rispetto al rischio di token tracking silenziosamente disabilitato.

**Location correction (2026-05-28)**: post-v0.4.0 there is no `SKILL.md Step 2.0a`. Token-tracking setup lives in `phase-2-core.md` Step 2.0 (reads `token-tracking.md`, resolves `TOKEN_SCRIPT`) and in `token-tracking.md` "Script Location". The weakening language was "resolve ONCE, then reuse" + "cached if already loaded this session".

**Fix applied (2026-05-28, Option B)**:
- `token-tracking.md` "Script Location" → "resolve at the START of EVERY round"; removed "reuse for all subsequent rounds"; added compact/clear rationale (do NOT assume `TOKEN_SCRIPT` is still set — the model may "recall" it but the value is gone after context rebuild).
- `phase-2-core.md` Step 2.0 → re-resolve `TOKEN_SCRIPT` unconditionally every round; removed the "cached if already loaded" hedge.

**Tasks**:
- [x] Make TOKEN_SCRIPT resolution unconditional every round (phase-2-core.md Step 2.0 + token-tracking.md "Script Location")
- [x] Remove "resolve ONCE / cached" weakening language
- [x] Add rationale explaining why unconditional (compact/clear resilience)
- [ ] Dogfood-verify: token tracking active after /compact + resume, SHOULD_STOP fires

**Acceptance criteria**:
- [ ] Token tracking active after `/compact` + resume
- [ ] Token tracking active after `/clear` + resume
- [ ] SHOULD_STOP correctly evaluated at every round
- [ ] No performance regression (Read is fast)

**Related**: BUG-006 (compact detection for gap), TECH-009 (progressive precision), Phase 6b (context reset hook)

---

### BUG-005: Participant verbose dumps missing full context

**Status**: completed | **Created**: 2026-01-22 | **Updated**: 2026-05-28 | **Completed**: 2026-06-06 | **Priority**: high | **Target**: v0.5.0 | **Verified**: see test-baselines/v0.5.0-dogfood.md

**Context**: Despite BUG-003 fix (SKILL.md now specifies inline `context`), the actual verbose dump files for participants (`{NNN}-02-{participant}.yaml`) only contain `input.question` but NOT the full `input.context` block with project_summary, relevant_artifacts, etc.

**Observed behavior**:
```yaml
# Current dump (incomplete)
input:
  question: "What are the key requirements?"
  # Missing: context block with project_summary, relevant_artifacts, etc.
```

**Expected behavior** (per verbose-dump-format.md):
```yaml
input:
  question: "What are the key requirements?"
  exploration: "Are there edge cases?"
  context:
    project_summary: |
      {full project summary}
    relevant_artifacts: [...]
    open_conflicts: [...]
    open_questions: [...]
    recent_rounds: [...]
```

**Root cause** (confirmed 2026-01-22; location corrected 2026-05-28): the dump-write instruction emphasized response fields only. The canonical schema in `verbose-dump-format.md` (§ Participant Response Dump) already specifies the full `input.context` block, but the instruction in `phase-2-core.md` §2.3e did not require copying it — so the executor wrote `input.question` and the response while dropping the `input.context` block. (The original ticket cited `specs.md:884-886`, a pre-v0.4.0 location that no longer exists.)

**Impact**:
- CTX-* checks will fail (CTX-002, CTX-003)
- Cannot verify context propagation from dumps
- Resume from scratch cannot reconstruct what participants received

**Affected files** (corrected 2026-05-28):
- `skills/roundtable-execution/references/phase-2-core.md` §2.3e (participant dump-write instruction)

**Fix applied (2026-05-28)**: phase-2-core.md §2.3e now states the dump MUST include the full `input.context` block (`project_summary`, `relevant_artifacts`, `open_conflicts`, `open_questions`, `recent_rounds`) copied VERBATIM from what was sent to the participant in Step 2.3b — not only `input.question`.

**Tasks**:
- [x] Make phase-2-core.md §2.3e require the full `input.context` block in the participant dump
- [ ] Dogfood-verify in ElfGiftRush_s2s/exp*: `--verbose` run, confirm `{NNN}-02-*.yaml` contains the context block + CTX-002/003 pass

**Related**: BUG-003, BUG-004, TEST-003, CTX-*

---

### BUG-007: Internal ADR references leak into user project templates

**Status**: completed | **Created**: 2026-01-28 | **Completed**: 2026-05-29 | **Priority**: low | **Target**: v0.5.0

**Context**: The workspace and project templates contain references to internal Spec2Ship ADRs (ADR-0009, ADR-0010). When a user runs `/s2s:init`, these references end up in the generated files. Users have no access to these ADRs and the references are meaningless outside of s2s development.

**Note**: `ADR-001` in workspace.yaml line 31 is NOT a leak - it's a generic example showing the user how cross_cutting entries will look for their own project ADRs.

**Affected files**:
- `templates/workspace/workspace.yaml` (line 75, `context_note` block) - ADR-0009
- `templates/workspace/CONTEXT.md` (line 17) - ADR-0009
- `templates/project/CONTEXT.md` (line 17) - ADR-0009
- `templates/project/config.yaml` (line 35, consensus comment) - ADR-0010

**Fix applied (2026-05-29)**: removed all four internal ADR references from the user-facing templates. The `ADR-001` generic example in workspace.yaml stays (not a leak). The `.s2s/config.yaml` ADR-0010 comment was left untouched — it is the spec2ship repo's own config, not a shipped template.

**Tasks**:
- [x] Remove ADR-0009 reference from `templates/workspace/workspace.yaml` context_note
- [x] Remove ADR-0009 reference from `templates/workspace/CONTEXT.md`
- [x] Remove ADR-0009 reference from `templates/project/CONTEXT.md`
- [x] Remove ADR-0010 reference from `templates/project/config.yaml` consensus comment

**Acceptance criteria**:
- [x] Generated user files contain no references to internal s2s ADRs (ADR-0009, ADR-0010)
- [x] context_note in workspace.yaml retains its useful operational lines (71-74)
- [x] config.yaml consensus section remains functional without the ADR comment

---

### BUG-008: init does not configure .gitignore for s2s artifacts

**Status**: planned | **Created**: 2026-01-28 | **Updated**: 2026-07-13 | **Priority**: medium

**Context**: `/s2s:init` creates the `.s2s/` directory with config, context, and session files. Transient artifacts (session files, `state.json`, verbose dumps, caches) end up tracked, or shown as untracked noise, in the user's git.

**Re-triage (2026-07-13, v0.9.0 pre-cycle)**: the premise narrowed but did NOT go away. "Never touches `.gitignore`" is now false — `commands/init.md` §5.4b (shipped with TECH-013) appends `.s2s/local/`, idempotently, creating the file if absent. But that block is **privacy-only**, not artifact hygiene: every transient artifact below is still unignored. So the mechanism exists and the four original tasks are mechanically solved; what remains is **widening the content of the block**.

**Transient artifacts left unignored today** (verified against current code):

| Path | Written by |
|------|------------|
| `.s2s/state.json` | `commands/roundtable.md`, `phase-2-core.md` |
| `.s2s/sessions/**` (session YAML, snapshots, `rounds/*.yaml` verbose dumps, `*-summary.md`) | `commands/roundtable.md` |
| `.s2s/sessions/*.cache`, `.s2s/sessions/token-tracker.cache` | `token-tracker.sh` |
| `.s2s/context-window.json` | `templates/statusline/statusline.sh` — **rewritten on every statusline render**, so this is the loudest noise source |
| `.s2s/qa/evidence/*.yaml` | `agents/validation/session-qa.md`, `commands/session/validate.md` |

Tracked-by-design and NOT to be ignored: `config.yaml`, `CONTEXT.md`, `README.md`, `BACKLOG.md`, `ideas.md`, `workspace.yaml`, `requirements.md`, `architecture.md`, `decisions/`, `plans/`.

**Corrected .gitignore block** (denylist, replaces the stale allowlist that predated `state.json`, `context-window.json`, `qa/` and `.s2s/local/`):
```gitignore
# Spec2Ship - local state, sessions, caches
.s2s/sessions/
.s2s/state.json
.s2s/context-window.json
.s2s/qa/
.s2s/local/
```
The allowlist form (`.s2s/*` + `!` exceptions) is what the spec2ship repo itself uses, but it is fragile in user projects: every new tracked artifact type needs a new `!` line, and a forgotten one silently disappears from git. Prefer the denylist.

**Tasks**:
- [ ] Widen `commands/init.md` §5.4b from the `.s2s/local/`-only block to the full block above (keep the existing idempotent append/create logic)
- [ ] Update the init completion banner (it still describes `.gitignore` as local-only)
- [ ] Make the widening idempotent for projects initialized under TECH-013 (block already contains `.s2s/local/`)
- [ ] Align `skills/s2s-guide/references/workspace.md` ("Never Version" list), which already documents the intent but nothing enforces it

**Acceptance criteria**:
- [ ] After `init`, `git status` is clean of s2s transient files (state.json, sessions/*, context-window.json, qa/, caches)
- [ ] Running `init` twice does not duplicate the block, and upgrading a TECH-013-era project widens it in place
- [ ] Project artifacts (BACKLOG.md, CONTEXT.md, plans/, decisions/, requirements.md, architecture.md) remain trackable

---

### BUG-009: Facilitator concludes despite unmet criteria

**Status**: completed | **Created**: 2026-01-30 | **Updated**: 2026-05-28 | **Completed**: 2026-06-06 | **Priority**: high | **Target**: v0.5.0 | **Verified**: see test-baselines/v0.5.0-dogfood.md

**Context**: During a roundtable session (round 4), the facilitator returned `next: "conclude"` despite the agenda showing:

```
[partial] Project vision and positioning (CRITICAL)
[CLOSED] Documentation structure and strategy (CRITICAL)
[open]    Open-source governance and community
[open]    Development phases and priorities
```

The facilitator's conclude criteria (facilitator.md:391-398) require ALL of these to be true:

| Criterion | Required | Actual |
|-----------|----------|--------|
| `rounds_completed >= min_rounds` | 4 >= 3 | **MET** |
| ALL critical topics are `closed` | "Project vision" is `partial` | **NOT MET** |
| At least 50% of other topics `closed` or deferred | 0/2 = 0% | **NOT MET** |
| No unresolved blocking conflicts | None blocking | **MET** |
| At least `sum(min_requirements)` artifacts | 13 requirements | **MET** |

Criteria 2 and 3 are NOT met, yet the facilitator decided to conclude.

**Root cause**: The conclude decision is entirely delegated to the facilitator agent (an LLM) with no validation by the command. The `constraints_check.can_conclude` field is self-reported by the facilitator - the command trusts it without verification. If the facilitator gets it wrong (e.g., due to context pressure at 77%), the error propagates.

**Possible solutions**:

1. **Command-side validation** (recommended): After receiving `next: "conclude"`, the command verifies agenda status before accepting:
   ```markdown
   IF next == "conclude":
     Read session file agenda
     IF any critical topic != "closed":
       Override next = "continue"
       Log: "Facilitator wanted to conclude but critical topic X is not closed"
     IF closed_non_critical / total_non_critical < 0.5:
       Override next = "continue"
       Log: "Facilitator wanted to conclude but only N% of topics closed"
   ```

2. **Stricter facilitator instructions**: Add explicit checklist with numbered verification steps that must be logged in output.

3. **User confirmation on conclude**: See BUG-010 (separate issue).

**Impact**: Sessions may close prematurely with incomplete coverage, requiring manual session continuation or new session creation.

**Location correction (2026-05-28)**: validation lives in `phase-2-core.md` Step 2.9, new sub-step **2.9b** (post-v0.4.0 the round loop is in phase-2-core.md, not SKILL.md). It joins the `agenda.yaml` snapshot (`topics[].critical`) with the live `session.agenda` (`topic_id` → `status`).

**Fix applied (2026-05-28)**: phase-2-core.md Step 2.9b — applies when `next == "conclude"` AND agenda axis (specs/design). Overrides conclude→continue if any `critical` topic is not `closed`, or if <50% of non-critical topics are `closed`; records `validation_override` on the current round entry and displays the reason. Facilitator instructions untouched (independent gate). Brainstorm exempt (gated by `current_phase == "critic"`).

**Tasks**:
- [x] Add command-side conclude validation in phase-2-core.md Step 2.9b
- [x] Check critical topic closure before accepting conclude
- [x] Check 50% non-critical closure before accepting conclude
- [x] Log override reason when conclude is rejected (`validation_override` on round entry)
- [ ] Dogfood-verify: force a premature conclude with an open critical topic, confirm override + continue

**Acceptance criteria**:
- [x] Command rejects premature conclude when critical topics are not closed
- [x] Command rejects premature conclude when <50% of other topics closed
- [x] Override is logged in session file for debugging
- [x] Facilitator instructions remain unchanged (defense in depth)

**Related**: BUG-010 (user confirmation), TECH-002 Phase 3

---

### BUG-010: No user confirmation when facilitator decides to conclude

**Status**: completed | **Created**: 2026-01-30 | **Updated**: 2026-05-28 | **Completed**: 2026-06-06 | **Priority**: medium | **Target**: v0.5.0 | **Verified**: see test-baselines/v0.5.0-dogfood.md

**Context**: When the facilitator returns `next: "conclude"`, the command exits the round loop and proceeds directly to Phase 3 without any user interaction. The user has no opportunity to say "no, keep going - there are still open topics."

Current flow (SKILL.md Step 2.9):
```
next == "continue" → repeat loop
next == "conclude" → EXIT loop, proceed to PHASE 3  ← no confirmation
next == "escalate" → Step 2.10: AskUserQuestion
```

The automatic continuation rules (added in Phase 6b) list "Facilitator returns `next: conclude`" as a valid exit, not as a user confirmation point. This design trusts the facilitator's judgment completely.

**Root cause**: Design decision - conclude was treated as a facilitator prerogative, not a user decision point. This made sense when assuming the facilitator always follows its criteria correctly, but BUG-009 shows that assumption is flawed.

**Possible solutions**:

1. **Always confirm conclude** (recommended):
   ```markdown
   IF next == "conclude" AND interactive_flag == false:
     Display agenda summary
     Use AskUserQuestion:
       - "Accept conclusion (proceed to output generation)"
       - "Continue discussion (more rounds needed)"
       - "Review agenda before deciding"
     IF user chooses "Continue":
       Override next = "continue"
   ```

2. **Confirm only when agenda incomplete**:
   Only ask if any topic is not closed. Silent conclude when all topics closed.

3. **Add --auto-conclude flag**:
   New flag to opt into current behavior. Default becomes confirm.

**Trade-offs**:

| Approach | Pros | Cons |
|----------|------|------|
| Always confirm | User always in control | Extra interaction even for valid concludes |
| Confirm when incomplete | Balances automation and control | Still trusts "closed" status accuracy |
| --auto-conclude flag | Backward compatible | Another flag to remember |

**Recommendation**: Option 1 (always confirm) is safest. The conclude moment is significant - the session is about to close and output generated. A single confirmation is reasonable.

---

**Enhancement (2026-02-02): Summary checkpoint before output generation**

The confirmation should include a **session summary** that serves multiple purposes:

1. **User checkpoint**: Human-readable recap of decisions before committing
2. **Context compression**: Output generator uses summary (~50 lines) instead of full session file (~500 lines)
3. **Error detection**: User can spot missing items that BUG-009 validation might miss

**Why summary is NOT redundant with session YAML:**

| Aspect | Session YAML | Summary |
|--------|--------------|---------|
| Purpose | Machine processing, resume, audit | Human review, LLM context efficiency |
| Size | Grows with rounds (BUG-011) | Fixed ~50 lines |
| Content | Full artifact details, all rounds | Key decisions, coverage, open items |
| Optimized for | State reconstruction | Decision validation |

**Proposed Phase 3 flow:**

```
Phase 3: Completion
├── Step 3.0: Generate Session Summary
│   └── Compile from session file:
│       - Decisions made (approved artifacts)
│       - Coverage achieved (agenda status)
│       - Open items (draft artifacts, unresolved questions)
│       - Key trade-offs discussed
├── Step 3.1: Display Summary + Confirm Conclude
│   └── Show summary to user
│   └── AskUserQuestion:
│       - "Proceed to output generation"
│       - "Continue discussion (more rounds)"
│       - "Close without output"
│   └── IF "Continue": override next = "continue", return to Phase 2
├── Step 3.2: Update Session Status (status: "closed")
└── Step 3.3: Generate Outputs
    └── Use summary as primary context (not full session re-read)
    └── Write {session-id}-summary.md (already exists, now generated earlier)
    └── Generate workflow-specific outputs (requirements.md, etc.)
```

**Benefits:**

- Addresses BUG-009: User sees coverage gaps before confirming
- Addresses BUG-011: Output generator reads compact summary, not large session file
- Single mechanism solves multiple issues
- Summary file already exists in current design, just generated at better time

**Location + scope correction (2026-05-28)**: implemented in `phase-2-core.md` Step 2.9 as new sub-step **2.9c** (the conclude decision lives in the round loop, not in a separate Phase 3 SKILL.md step). Scoped to the **confirmation + inline summary display** (roadmap Option 1). The broader Phase 3 restructure — generating a `summary.md` early and feeding it to output generation instead of re-reading the session file — is the BUG-011 optimization and stays **out of v0.5.0 scope**.

**Fix applied (2026-05-28)**: phase-2-core.md Step 2.9c — when `next == "conclude"` survives 2.9b AND `INTERACTIVE_FLAG == false`, compile and display a short summary (decisions / coverage / open items), then `AskUserQuestion` (accept vs continue); "Continue" overrides `next = "continue"`. In interactive mode the user already chose at Step 2.8, so no double prompt.

**Tasks**:
- [x] Add conclude confirmation in phase-2-core.md Step 2.9c (non-interactive path)
- [x] Define inline summary content (decisions, coverage, open items)
- [x] AskUserQuestion (accept conclusion vs continue discussion); "Continue" overrides next
- [ ] Dogfood-verify: non-interactive run reaching conclude shows summary + prompt; "Continue" adds a round
- [~] (deferred to BUG-011) move summary.md generation earlier + use it as output-generation context

**Acceptance criteria**:
- [x] User sees session summary before confirming conclude
- [x] Summary includes: approved artifacts, agenda coverage, open items
- [x] User can choose to continue discussion instead of concluding
- [~] Output generator uses summary as context (deferred — BUG-011)
- [x] Confirmation runs on the non-interactive conclude path (interactive handled at Step 2.8)

**Related**: BUG-009 (facilitator criteria), BUG-011 (session file size + summary-as-context), TECH-002 Phase 3

---

### BUG-011: Session file grows large with embedded artifacts

**Status**: planned | **Created**: 2026-01-30 | **Priority**: low

**Context**: During a roundtable session (round 4 with 13 requirements and 6 open questions), the LLM executing the command commented "The session file is large" and decided to use "targeted edits" instead of a full file operation. This suggests the embedded artifacts design may have scaling concerns.

**Observed behavior**: The LLM's message:
> "The session file is large. I'll make targeted edits to add round 4 data and close the session."

At that point:
- 4 rounds completed
- 13 requirements with full descriptions and acceptance criteria
- 6 open questions
- 4 rounds of audit trail (facilitator questions, participant positions, synthesis, artifacts)
- Context usage at 77%

The session YAML file was likely 400-600+ lines.

**Potential issues**:

1. **Context pressure**: Reading large session file for editing at high context % reduces remaining capacity, potentially contributing to facilitator errors (BUG-009).

2. **Edit reliability**: "Targeted edits" on YAML require exact string matching. On large files, the LLM may:
   - Target the wrong section
   - Introduce indentation errors
   - Skip updates (e.g., forgetting metrics)
   - Create invalid YAML structure

3. **Compound effect**: Every round, the command reads the session file (facilitator input), writes to it (Step 2.5-2.6), and reads again (validation). A 500-line YAML touched 3+ times per round consumes significant context.

4. **Resume brittleness**: If targeted edits corrupt YAML structure, resume from that session becomes impossible.

**Root cause**: Design decision to embed all artifacts in session file (ADR-0010) for simplicity and single source of truth. Trade-off was accepted but scaling implications not fully analyzed.

**Possible solutions**:

1. **Compact session representation** (lightweight):
   - Store only artifact IDs in session file
   - Move full artifact content to separate files: `.s2s/sessions/{id}/artifacts/{type}/{ID}.yaml`
   - Session file stays slim (~100 lines regardless of artifact count)
   - **Breaks**: Single source of truth, increases file count

2. **Incremental session updates** (medium):
   - Instead of Edit tool, use append-only logging
   - Each round appends to session file
   - Rebuild full state on read
   - **Risk**: Append operations may still fail

3. **Session file compression** (lightweight):
   - Reduce verbosity in audit trail
   - Store only synthesis, not full participant positions
   - Remove redundant fields
   - **Trade-off**: Less debugging info

4. **Accept and document** (no change):
   - Document session size limits (e.g., "best for <10 rounds, <20 artifacts")
   - Recommend `/s2s:session:close` + new session for long discussions
   - Add warning when session file exceeds threshold

**Recommendation**: Start with option 4 (document limits) and option 3 (reduce verbosity). If problems persist, consider option 1 for future version.

**Impact**: Currently low priority - the session completed successfully despite the "large file" comment. This becomes higher priority if corruption or failures occur.

**Tasks**:
- [ ] Analyze actual session file sizes from real projects
- [ ] Identify verbose fields that can be trimmed
- [ ] Add session file size check with warning threshold
- [ ] Document recommended session limits in s2s-guide
- [ ] Consider separate artifacts approach for v2.0

**Acceptance criteria**:
- [ ] Session file size limits documented
- [ ] Warning displayed when session file exceeds threshold (e.g., 500 lines)
- [ ] Audit trail verbosity reduced without losing critical info
- [ ] No YAML corruption from targeted edits (regression test)

**Related**: ADR-0010 (single state field), TECH-002 (command unification), BUG-010 (summary checkpoint mitigation)

---

### BUG-014: Agent resume gap during master-delegated runs

**Status**: completed | **Created**: 2026-05-28 | **Updated**: 2026-05-29 | **Completed**: 2026-06-06 | **Priority**: medium | **Origin**: TECH-002 Phase 4 diagnostic finding (plan §8); reproduced in exp54 | **Target**: v0.5.0 | **Verified**: see test-baselines/v0.5.0-dogfood.md

**Context**: During a master-delegated run (`/s2s:design` through the roundtable.md master), an agent resume produced the error `summary is required when message is a string`. The harness fallback completed the run, so it was non-blocking, but the resume path is not clean.

**Reproduced**: exp54 (`/s2s:design --diagnostic`, 2026-05-22). The run never actually interrupted; the error surfaced and execution continued via harness fallback.

**Note**: this is distinct from BUG-001 (agent resume fails across Claude restarts). BUG-014 is within a single session, on the delegated master path.

**Fix applied (2026-05-29)**: the error means the Task tool resume call sent a plain-string message with no `summary`. Both resume points in `phase-2-core.md` now require a one-line `summary` on the Task call: §2.2a (facilitator) and §2.3a (participant). Covers either origin without needing to disambiguate which one fired.

**Tasks**:
- [x] Identify the cause: string resume message without `summary` (applies to both facilitator and participant resume)
- [x] Require a `summary` on both resume Task calls (phase-2-core.md §2.2a + §2.3a)
- [ ] Dogfood-verify deterministically (master-delegated `/s2s:design --diagnostic`, multi-round): resume succeeds with no `summary is required` error and no harness fallback

**Acceptance criteria**:
- [x] Resume input now carries a `summary` (no string-only message)
- [ ] Master-delegated runs resume without the `summary is required` error (dogfood)
- [ ] No reliance on harness fallback for normal resume (dogfood)

---

### BUG-015: R1 observer false-positive on empty artifact maps

**Status**: completed | **Created**: 2026-05-28 | **Updated**: 2026-05-29 | **Completed**: 2026-06-06 | **Priority**: low | **Origin**: TECH-002 Phase 4 diagnostic finding (plan §8) | **Target**: v0.5.0 | **Verified**: see test-baselines/v0.5.0-dogfood.md

**Context**: On round 1, the session-observer (diagnostic mode) flags an anomaly when artifact maps are still empty, but an empty artifact map at R1 is expected (artifacts accrue from R1 synthesis onward). The false-positive adds noise to the diagnostic report.

**Fix applied (2026-05-29)**: `agents/validation/session-observer.md` now states explicitly that at `round == 1` the artifact maps, `relevant_artifacts`, and `recent_rounds` are expected to be empty (baseline) and MUST NOT be reported as findings; "populated"/coherence checks apply only for `round > 1`. Added both as a callout in Per-Round Mode and a bullet in "Important".

**Tasks**:
- [x] Suppress the empty-artifact-map anomaly on round 1 (explicit baseline guard in the observer agent)
- [x] Keep "populated"/coherence checks active for round > 1 (genuine stalls still flagged)
- [ ] Dogfood-verify: `--diagnostic` run, no empty-artifact-map finding at R1; genuine stall past R1 still flagged

**Acceptance criteria**:
- [x] Observer instructed: no empty-artifact-map anomaly at R1
- [x] Genuine stalls (empty artifacts past R1) still flagged (checks gated to round > 1, not removed)

---

### BUG-016: token-tracker.sh exits 1 and breaks && chains

**Status**: completed | **Created**: 2026-05-28 | **Completed**: 2026-05-29 | **Priority**: low | **Origin**: TECH-002 Phase 4 diagnostic finding (plan §8) | **Target**: v0.5.0

**Context**: `token-tracker.sh` returns exit code 1 in a path that is not actually an error (observed during Phase 4 dogfood), which breaks `&&` command chains that invoke it. Callers must split the chain to avoid aborting subsequent steps.

**Root cause (2026-05-29)**: the script has no `set -e` and no trailing `exit 0`, so it inherits the exit status of the last command in the matched `case` branch. The `init` branch ends with `[[ "$COMPACT_DETECTED" == "true" ]] && echo ...`, which returns 1 whenever no compact occurred (the normal case) — so a successful `init` exited 1, aborting `eval $(... init ...) && ...` chains.

**Fix applied (2026-05-29)**: added `exit 0` after `esac` (the `*)` usage branch still `exit 1` before reaching it). Verified directly: normal `init` → exit 0; `init ... && echo CHAIN OK` → prints CHAIN OK; bogus action → exit 1.

**Tasks**:
- [x] Locate the exit-1 path that is not a real failure (init branch trailing `[[ ]] && echo`)
- [x] Return 0 on the non-error path (trailing `exit 0`)
- [x] Verify token tracking still surfaces real errors with a non-zero code (`*)` usage still exits 1)

**Acceptance criteria**:
- [x] `token-tracker.sh` returns 0 on success paths
- [x] `&&` chains invoking it do not abort spuriously

---

### BUG-017: Token-tracker recap math glitched after compact+resume

**Status**: completed | **Created**: 2026-06-06 | **Completed**: 2026-06-10 | **Priority**: low | **Target**: v0.6.0 | **Origin**: v0.5.0 dogfood (exp61) | **Verified-via**: test-baselines/v0.5.0-dogfood.md (F2) + hermetic regression test

**Context**: in exp61 (post-fix BUG-012 verification), the token-tracker `init` at round 3 post-compact ran cleanly (BUG-012 PASS), but the subsequent round-3 `recap` reported `statusline returned 0%` and produced negative round deltas. Model self-described as "non-blocking" and continued.

**Root cause (confirmed 2026-06-10)**: `init` already overwrites the whole cache file each round (`cat > $CACHE_FILE`), so stale pre-compact T1/T2/T3 are NOT the cause. The real failure is in `recap`: a `capture` can write `0` when the statusline momentarily reports 0% (right after `/compact`, before it re-runs) AND the JSONL fallback is unavailable, leaving `T3=0`. recap then computes `ROUND_DELTA = T3 - T0 < 0` and `CONTEXT_PCT = T3/LIMIT = 0%`. The cross-round compact gap is already handled by `init` (BUG-006/012 `compactDetected`); `recap` had no equivalent guard.

**Decision**: `recap` guards (not `init` clears). Chosen because init already produces a clean cache; the defect is recap trusting a possibly-zero end-of-round capture.

**Fix applied (2026-06-10, `token-tracker.sh` v5.3.1)**:
- recap recovers the end-of-round count when `T3<=0`: fresh `get_current_tokens` read → round-start `T0` fallback, so `CONTEXT_PCT` is never a phantom 0%.
- recap clamps any negative phase delta (`QUESTION`/`PARTICIPANTS`/`SYNTHESIS`/`ROUND_DELTA`) to 0 and emits `RECAP_DEGRADED=true` (also true when `compactDetected`), so the display can mark the breakdown approximate instead of printing negative tokens.
- recap now emits `COMPACT_DETECTED` + `RECAP_DEGRADED`; `init`'s compact semantics untouched.

**Tasks**:
- [x] Reproduce deterministically — hermetic test `skills/roundtable-execution/scripts/tests/test-token-tracker.sh` Test 1 (degenerate post-compact cache: T0=42000, T1=T2=T3=0, compactDetected=true) reproduces negative deltas + 0% pre-fix.
- [x] Decide whether `init` clears or `recap` guards on `compactDetected` — recap guards (see Decision).
- [x] Confirm: post-compact resume rounds report a sensible recap (no 0% statusline, no negative deltas).

**Acceptance criteria**:
- [x] Round-3 (or first post-compact round) recap produces non-negative deltas and a real percentage. (Test 1)
- [x] BUG-012's `compactDetected=true` semantics preserved. (Test 1 asserts `COMPACT_DETECTED=true`; init path unchanged + smoke-tested)
- [x] Guard does not degrade a healthy recap. (Test 2: normal monotonic captures → real positive deltas, `RECAP_DEGRADED=false`)

---

### BUG-018: Token-tracker cache loses workflow params after compact+resume

**Status**: completed | **Created**: 2026-06-06 | **Completed**: 2026-06-10 | **Priority**: low | **Target**: v0.6.0 | **Origin**: v0.5.0 dogfood (exp61) | **Verified-via**: test-baselines/v0.5.0-dogfood.md (F3)

**Context**: post-compact resume cache file in exp61 had `workflowType=`, `strategy=`, `phase=`, `participantsCount=` empty. The model called `token-tracker.sh init` with only `session-id` + `round-number` and omitted the optional positional params.

**Re-triage (2026-06-10) — premise was wrong**: the empty cache fields are real but **harmless**. Two findings:
1. **The four params are write-only.** `token-tracker.sh` wrote them to the cache (init) but **nothing ever read them back** (grep: only the write + tests; recap/summary `source` the cache but don't use them). They are leftovers from an older design where token-tracker wrote `state.json`.
2. **The statusline's roundtable info does not come from this cache.** It reads `state.json.active_session.*`, which `phase-2-core.md §2.1b` rewrites **every round** (including the resume round) from the on-disk `PROFILE` + config-snapshot + `session.yaml.metrics.rounds_completed`. Those files survive `/compact`, so the statusline RT info **already survives resume**, independent of the token cache. Acceptance criterion 2 was therefore already satisfied by design.

**Resolution (remove vestigial state, not preserve it)**: dropped `workflowType`/`strategy`/`phase`/`participantsCount` from the init cache write and the init signature (`token-tracker.sh` v5.5.0); `init` still accepts the extra positional args (ignored) for back-compat. Updated `token-tracking.md` init usage + a note explaining the state.json mechanism. Fixed the stale `templates/statusline/statusline.sh` header comment ("written by token-tracker" → written by phase-2-core.md §2.1b).

**Tasks**:
- [x] Decide: remove the write-only fields rather than preserve them (chosen over cache-merge — nothing reads them).
- [x] Remove fields from init cache write + signature; keep extra args accepted (back-compat).
- [x] Update `token-tracking.md` init call + document the state.json (§2.1b) mechanism.
- [x] Fix stale statusline template comment.

**Acceptance criteria** (re-interpreted after re-triage):
- [x] Cache no longer carries write-only `workflowType`/`strategy`/`phase`/`participantsCount`. (`scripts/tests/test-token-tracker.sh` Test 5)
- [x] Statusline roundtable info survives `/compact` + resume — confirmed to be driven by `state.json` (§2.1b re-derives from disk each round), not the token cache.

**Related**: BUG-017, BUG-019 (same file/cache, same v0.6.0 cycle).

---

### BUG-019: Token-tracker hardcoded 200K context limit (wrong on 1M-window models)

**Status**: completed | **Created**: 2026-06-10 | **Completed**: 2026-06-10 | **Priority**: medium | **Target**: v0.6.0 | **Origin**: user report (session 0ed30948, 2026-06-10)

**Context**: `token-tracker.sh` hardcoded `CONTEXT_LIMIT=200000` (used in 9 places) and `get_tokens_from_statusline` recomputed tokens as `200000 * used_pct / 100`. Current Claude models have a 1M window (Opus 4.6/4.7/4.8, Sonnet 4.6; only Haiku 4.5 is 200K — confirmed via claude-api skill, cached 2026-05-26), so 200K is stale for nearly every model. This session ran at `context_window_size: 1000000`.

**Impact (two token sources, hit differently)**:
- **Statusline path** (normal s2s): percentages round-trip correctly (the 200K cancels: `tokens/200000 == used_pct`), so `SHOULD_STOP`/`SHOULD_WARN` decisions were still right, but every absolute number was wrong by the window ratio — at 14% of 1M it displayed `28k used / 172k available` instead of `140k / 860k`.
- **JSONL fallback path** (statusline off): `get_tokens_from_jsonl` returns real absolute tokens, then `/200000` → at 140k real tokens it reported **70%** instead of 14%, so the roundtable would stop ~5× too early. Genuinely broken on large windows.

**Root insight**: the fix needs no per-model table — the statusline already writes `context_window_size` and `current_context_tokens` into `.s2s/context-window.json` (the statusline template reads them from Claude Code's input and defaults to 200000 only when absent, so it was already correct). Only the tracker's consumption was wrong.

**Fix applied (2026-06-10, `token-tracker.sh` v5.4.0)**:
- New `get_context_limit()` reads `context_window_size` from the JSON; `CONTEXT_LIMIT` is resolved per-invocation before the action dispatch. `DEFAULT_CONTEXT_LIMIT=200000` is now only the fallback when the JSON is absent.
- `get_tokens_from_statusline` prefers the absolute `current_context_tokens`; the percentage recompute fallback now uses the dynamic limit.
- All 9 `CONTEXT_LIMIT` uses (percentages, `AVAILABLE_K`, `REMAINING_K`, statusline back-calc) now adapt automatically.

**Tasks**:
- [x] Resolve `CONTEXT_LIMIT` from `context_window_size` (fallback to 200000 when JSON absent).
- [x] Use `current_context_tokens` directly instead of rescaling a percentage.
- [x] Regression test for a 1M window (absolute tokens + percentage correct) and the percentage-fallback path — `scripts/tests/test-token-tracker.sh` Tests 3-4.

**Acceptance criteria**:
- [x] On a 1M-window model the tracker reports real used/available tokens (140k/860k at 14%), not 200K-scaled values. (Test 3)
- [x] Percentage fallback (no `current_context_tokens`) also uses the real window. (Test 4)
- [x] Falls back to 200K only when the statusline JSON is unavailable; no per-model table to maintain.

**Note**: the JSONL-only fallback (statusline never active) still can't know the window and defaults to 200K — acceptable since `/s2s:init` sets up the statusline. Related: BUG-018 (same cache, post-compact param loss).

---

### TECH-011: assign_debate_sides launcher pre-step is vestigial for design+debate

**Status**: completed | **Created**: 2026-06-06 | **Completed**: 2026-06-11 | **Priority**: low | **Target**: v0.6.0 | **Origin**: v0.5.0 dogfood (exp58 step 2 design report) | **Verified-via**: test-baselines/v0.5.0-dogfood.md (F1)

**Context**: post-fix design run reported that the launcher's `assign_debate_sides` pre-step is vestigial when design uses the `debate` strategy. The static side assignment is no longer load-bearing because the per-round `facilitator_emergent` policy reassigns Pro/Con per topic at each round (Phase 4 / strategy-hooks). The launcher writes an initial side split into `session.yaml` that subsequent rounds ignore.

**Audit findings (2026-06-11)**: confirmed vestigial — same write-only pattern as BUG-018.
- `debate_sides` was written at setup (`roundtable.md`) and **read nowhere** (grep across commands/skills/agents: only the 3 write-side refs). The facilitator agent picks Pro/Con per round by LLM judgment under `facilitator_emergent` (`facilitator.md:198`); it never reads `debate_sides`.
- The pre-step invoked `action: "assign_debate_sides"`, which the facilitator agent doesn't even document handling — doubly dead.
- The gating `--pro`/`--con` flags (documented, debate-only) fed only the unread `debate_sides`, so they were **silently non-functional** — a user's explicit side choice was ignored.
- design+debate reaches the pre-step (design.md delegates to roundtable.md PHASE 0). Removing it is no semantic change (already ignored).

**Resolution (remove all — user decision, consistent with BUG-018)**:
- `commands/roundtable.md`: deleted the "Handle debate strategy" pre-step + `debate_sides` session-creation line; removed the non-functional `--pro`/`--con` flags from the argument-hint and the "Other optional arguments" docs.
- `skills/roundtable-strategies/references/debate.md`: rewrote § Side Assignment to state Pro/Con is per-round `facilitator_emergent`; `side_assignment` config value → `"facilitator_emergent"` with a clarifying comment.
- `skills/roundtable-execution/references/strategy-hooks.md`: behavior row no longer implies a session-start split.
- The live per-round mechanism (`Resolve strategy hooks` → `hook_overrides` → `phase-2-core.md §2.2c facilitator_emergent`) is untouched.

**Tasks**:
- [x] Audit launcher: `assign_debate_sides` was called from `roundtable.md` (shared PHASE 1, hit by design+debate too).
- [x] Confirm `facilitator_emergent` supersedes static assignment (`debate_sides` unread; per-round override is the real path).
- [x] Remove the pre-step (chosen over document; includes the dead `--pro`/`--con` flags).

**Acceptance criteria**:
- [x] `assign_debate_sides` removed; docs updated to reflect per-round emergent assignment.
- [x] No semantic change to design+debate runs (the removed split was never read).

**Note / follow-up**: if explicit user-controlled sides are wanted later, that is a NEW feature (wire a seed into `facilitator_emergent`), not a regression — `--pro`/`--con` never worked. Not filed; raise if needed.

---

### BUG-020: Statusline fallback progress bar hardcoded to 200K

**Status**: completed | **Created**: 2026-06-10 | **Completed**: 2026-06-11 | **Priority**: low | **Target**: v0.6.0 | **Origin**: BUG-019 review (2026-06-10)

**Context**: surfaced while reviewing BUG-019. `templates/statusline/statusline.sh` (the fallback statusline used only when the user has no global statusline to chain to) computed the ASCII bar as `FILLED = USED_K / 20` — 10 slots × 20k = 200K total. `USED_K`, `AVAIL_K`, and the percentage are already dynamic (read `context_window_size` from Claude Code's input), so only the bar was mis-scaled: on a 1M-window model it pegged to full at 200K used (≈20% of the window). Same 200K-hardcode family as BUG-019, different file.

**Fix applied (2026-06-11, statusline template v3.2.0)**: bar is now percentage-based — `FILLED = round(used_pct / 10)` (10 slots × 10%), window-agnostic, clamped 0–10. Verified: PCT 14→1/10, 50→5/10, 80→8/10, 95→10/10 (old formula on 1M: 14→7/10, 50→10/10 pegged). The repo's tracked dogfood copy `.claude/statusline.sh` had the identical bug (and was missing the BUG-018 comment fix) — re-synced byte-identical to the template (`statusline.sh` is a static script, no init-time placeholders).

**Tasks**:
- [x] Scale the bar to the real window: percentage-based `FILLED = round(used_pct / 10)`.
- [x] Update the "each = 20k tokens (200k total)" comment.
- [x] Sync the repo's tracked `.claude/statusline.sh` dogfood copy to match.

**Acceptance criteria**:
- [x] Bar reflects true fill fraction on a 1M window (half-full at 50%, not pegged).
- [x] No change for 200K-window models (percentage-based → identical result).

**Related**: BUG-019 (token-tracker dynamic limit).

---

### TECH-012: Automated script test suite + CI

**Status**: completed | **Created**: 2026-06-11 | **Completed**: 2026-06-11 | **Priority**: high | **Target**: v0.7.0 | **Origin**: 1.0 gate (automated test suite)

**Context**: before this, the only automated test was `test-token-tracker.sh`, run manually one file at a time. No runner, no CI: the "automated test suite" 1.0 gate was formally unmet (it was a manual script), and two of the three shipped bash helpers (`statusline.sh`, `context-reset.sh`) had zero coverage.

**Done (2026-06-11)**:
- **Runner**: `tests/run-all.sh` discovers every `*/tests/test-*.sh`, runs each in isolation, aggregates pass/fail, exits non-zero on any failure. `Makefile` exposes `make test`.
- **CI**: `.github/workflows/tests.yml` runs `bash tests/run-all.sh` on push to `develop`/`main` and on every PR (ubuntu-latest; bash + jq preinstalled; `LANG=C.UTF-8`).
- **Coverage — statusline** (`templates/statusline/tests/test-statusline.sh`, 11 asserts at merge; 16 after BUG-022/023): locks BUG-019 (dynamic context window: 1M → 140k/860k, default 200k when size absent) and BUG-020 (percentage-based bar: 14→1, 50→5, 80→8, 95→10 filled slots). Hermetic: feeds Claude Code statusline JSON on stdin with the REAL `$HOME` (faking it breaks `$HOME`-relative toolchains like an asdf jq shim, dropped in d72035c); fallback-only assertions self-skip when a global statusline is configured.
- **Coverage — context-reset hook** (`templates/hooks/tests/test-context-reset.sh`, 14 asserts): resume banner on `/compact`+`/clear` with an active session; no banner on `startup` / no active_session / non-s2s dir; jq path updates `state.json.last_activity`; no-jq fallback (simulated via a curated PATH without jq) still emits the banner and the install note and leaves `state.json` untouched. **Surfaced and fixed BUG-021** (see below).
- **Docs**: CONTRIBUTING.md → new "Automated script tests" section; `.s2s/test-baselines/README.md` updated ("only automated test" claim removed).
- Tests colocate next to their target; init copies template scripts by exact path, so the `tests/` subfolders never leak into user projects.

**Tasks**:
- [x] Discovery runner + `make test`.
- [x] GitHub Actions workflow (push develop/main + PR).
- [x] statusline.sh hermetic tests (BUG-019 + BUG-020).
- [x] context-reset.sh hermetic tests (jq + no-jq fallback).
- [x] Update CONTRIBUTING + test-baselines README.

**Acceptance criteria**:
- [x] `make test` / `bash tests/run-all.sh` runs all script tests and fails non-zero on any failure (51 asserts across 3 files at merge; 60 after BUG-022/023/024, all green).
- [x] CI runs the suite on every PR.
- [x] statusline.sh and context-reset.sh have regression coverage.

**Related**: BUG-019, BUG-020 (locked by the new statusline tests), BUG-021 (found while writing context-reset tests), DEBT-002 (dev-tools separation — test exclusion at release still open there).

---

### BUG-021: context-reset.sh no-jq fallback can't parse pretty-printed state.json

**Status**: completed | **Created**: 2026-06-11 | **Completed**: 2026-06-11 | **Priority**: medium | **Target**: v0.7.0 | **Origin**: found while writing TECH-012 context-reset tests

**Context**: `context-reset.sh`'s grep/sed fallback (used when `jq` is absent) extracted JSON values with the pattern `"key":"value"` — no whitespace after the colon. But `state.json` is written by `jq`, which always emits `"key": "value"` (with a space). So on a machine without jq, the fallback read **empty** `workflow_type`/`id`/`round`, and the resume banner — the whole point of that path — **never showed**. (The stdin parse worked only because Claude Code sends compact hook input.)

**Fix applied (2026-06-11, `context-reset.sh` v2.2.0)**: made the three fallback extractors whitespace-tolerant — `grep -oE "\"key\": *\"[^\"]*\""` (and `: *[0-9]+` for numbers, `sed -E 's/.*: *//'`). `cut -d'"' -f4` already worked for both spacings. Synced the tracked dogfood copy `.claude/context-reset.sh` byte-identical (static script, no init placeholders).

**Tasks**:
- [x] Whitespace-tolerant fallback extractors in `templates/hooks/context-reset.sh`.
- [x] Regression test (TECH-012 Test 6: no-jq fallback emits banner from a pretty-printed state.json).
- [x] Sync `.claude/context-reset.sh`.

**Acceptance criteria**:
- [x] Without jq, the resume banner shows from a real (jq-written, spaced) `state.json`.
- [x] jq path unchanged.

**Related**: TECH-012, BUG-020 (same dogfood-copy sync pattern).

---

### BUG-022: statusline.sh has no jq guard, breaks silently when jq is missing

**Status**: completed | **Created**: 2026-06-13 | **Completed**: 2026-06-13 | **Priority**: high | **Target**: v0.7.0 | **Origin**: Vektra dogfood (VKT-001; CodeRabbit/Gemini review of generated tooling, 2026-03-22)

**Context**: the generated `statusline.sh` called `jq` 8+ times across both code paths with every stderr suppressed (`2>/dev/null`) and no `command -v jq` check. Without jq, every variable silently went empty and the status line rendered blank/garbled with no hint why.

**Fix applied (2026-06-13, `statusline.sh` v3.3.0)**: early guard after reading stdin — when jq is absent, print a visible `[s2s] jq not found - install jq to enable the s2s statusline` line and exit 0. Synced `.claude/statusline.sh` byte-identical.

**Tasks**:
- [x] jq presence guard in `templates/statusline/statusline.sh`.
- [x] Regression test (test-statusline.sh Test 0: curated no-jq PATH, asserts the visible notice + exit 0; runs before the suite's jq skip).
- [x] Sync `.claude/statusline.sh`.

**Acceptance criteria**:
- [x] Without jq the statusline degrades visibly, not silently.
- [x] jq path unchanged (Tests 1-3 green).

**Related**: BUG-023 (same file, same review), DOC-001 (documenting jq as recommended dependency), BUG-021 (same dogfood-copy sync pattern).

---

### BUG-023: statusline.sh recurses forever when statusLine.command points at itself

**Status**: completed | **Created**: 2026-06-13 | **Completed**: 2026-06-13 | **Priority**: high | **Target**: v0.7.0 | **Origin**: Vektra dogfood (VKT-002; CodeRabbit review of generated tooling, 2026-03-22)

**Context**: the chain-to-global logic piped stdin into `statusLine.command` from the user's global settings unconditionally. If that command resolved to the generated statusline itself (a plausible misconfiguration after copying settings), the script forked itself until the process limit.

**Fix applied (2026-06-13, `statusline.sh` v3.3.0)**: resolve `SELF_PATH` and `GLOBAL_PATH` via portable `cd dirname && pwd` + `basename` (bash 3.2 safe) and chain only when they differ; otherwise fall through to the fallback renderer. Also introduced `S2S_GLOBAL_SETTINGS` (settings-path override) so hermetic tests can drive the chain branch without faking `$HOME`. A symlinked duplicate still differs and at worst chains one extra hop before its own guard stops.

**Tasks**:
- [x] Self-path comparison guard before chaining.
- [x] `S2S_GLOBAL_SETTINGS` override for tests.
- [x] Regression tests (Test 4: self-referential command renders the fallback exactly once, timeout-guarded; Test 5: a distinct global statusline still chains).
- [x] Sync `.claude/statusline.sh`.

**Acceptance criteria**:
- [x] Self-referential `statusLine.command` cannot recurse.
- [x] Legitimate chaining still works.

**Related**: BUG-022 (same file), TECH-012 (test suite home).

---

### BUG-024: context-reset.sh no-jq fallback reads session metadata from anywhere in state.json

**Status**: completed | **Created**: 2026-06-13 | **Completed**: 2026-06-13 | **Priority**: low | **Target**: v0.7.0 | **Origin**: Vektra dogfood (VKT-021; CodeRabbit review nitpick, 2026-03-22)

**Context**: the no-jq fallback extracted `workflow_type`/`id`/`round` with file-wide greps that took the FIRST match anywhere in `state.json`. With keys of the same name outside `active_session` (e.g. a history entry or `last_activity.session_id`), the resume banner could target the wrong session. The jq path was already correctly scoped.

**Fix applied (2026-06-13, `context-reset.sh` v2.3.0)**: isolate the `active_session` block first (newline-flattened `grep -oE '"active_session"...\{[^{}]*\}'`, works on pretty-printed and compact JSON since the block is a flat object), then extract from the block only; if the block cannot be isolated, leave the fields empty (no banner) instead of guessing. Removed the now-unused file-wide helpers. Synced `.claude/context-reset.sh`.

**Tasks**:
- [x] Block-scoped fallback extraction.
- [x] Regression test (Test 7: decoy `workflow_type`/`id`/`round` before `active_session` must not leak into the banner).
- [x] Sync `.claude/context-reset.sh`.

**Acceptance criteria**:
- [x] Fallback banner always reflects `active_session`, never a decoy key.
- [x] jq path and BUG-021 spacing tolerance unchanged.

**Related**: BUG-021 (same fallback machinery), BUG-001 (stale resume targets, sibling concern at the instruction layer).

---

### TECH-013: Private local area (.s2s/local/) + confidential-context guidance

**Status**: completed | **Created**: 2026-06-13 | **Completed**: 2026-06-13 | **Priority**: medium | **Target**: v0.7.0 | **Origin**: Vektra dogfood (VKT-073: a confidential client codename had to be manually scrubbed from CONTEXT.md with a standing local-only rule)

**Context**: `.s2s/CONTEXT.md` feeds every session and its content flows into generated artifacts that often live in public repos. s2s had no sanctioned private area and no warning, so users carried the discipline manually in gitignored files — one real leak-and-scrub case in the Vektra dogfood.

**Fix applied (2026-06-13)**:
- `commands/init.md` new step 5.4b: ensure the project `.gitignore` covers `.s2s/local/` (append or create); the final summary now carries a privacy note.
- `templates/project/CONTEXT.md`: CONFIDENTIALITY block in the header comment (never put client names/codenames in this file; use `.s2s/local/`).
- `s2s-guide` workflow-guide: `local/` in the file-structure tree + "Confidential context" section.

**Tasks**:
- [x] init.md 5.4b gitignore step + summary privacy note.
- [x] CONTEXT.md template confidentiality block.
- [x] s2s-guide confidential-context section.

**Acceptance criteria**:
- [x] A fresh `/s2s:init` leaves `.s2s/local/` gitignored and the user warned.
- [x] Instruction-layer behavior (init actually appends on a real run) verified at the v0.8.0 dogfood (exp50: entry appended to a pre-existing .gitignore, prior lines intact; see test-baselines/v0.8.0-dogfood.md).

**Related**: BUG-008 (broader init gitignore configuration, still open; 5.4b covers only the private area), VKT-052/VKT-073 in the Vektra analysis doc-set.

---

### BUG-025: Design output generates only ~4 of 12 arc42 sections

**Status**: completed | **Created**: 2026-07-11 | **Completed**: 2026-07-12 | **Priority**: high | **Target**: v0.8.0 | **Verified**: test-baselines/v0.8.0-dogfood.md | **Origin**: Vektra dogfood (VKT-025/026/082/063; 2 of 3 sources classify the arc42 gap as a defect, confirmed real on current code)

**Context**: `skills/output-generation/references/design-arc42.md` emitted only System Context, Principles, Components, Interfaces and an ADR pointer. Missing: quality goals, constraints, context diagram, runtime view, deployment view, cross-cutting concepts, decision index, quality tree/scenarios (arc42 §10), risks, glossary, traceability. No diagrams at all (VKT-026), thin/absent §10 (VKT-082), and no guard against artifacts silently dropped between session YAML and rendered Markdown (VKT-063).

**Fix (2026-07-11, v0.8.0 cycle)**:
- `design-arc42.md` rewritten around the full arc42 backbone (sections 1-12), always emitted; sections without session data get an explicit `*Not covered in this design session.*` placeholder instead of being dropped.
- Conditional subsections (Persistence, API Design, Configuration under §8) emitted ONLY when the backing artifacts exist (datastore tech in COMP-*, endpoints in INT-*, config values in decisions).
- 5 derivable Mermaid diagram types with artifact-only derivation rules: context, building blocks, runtime sequence, deployment, quality tree.
- §10 built from `.s2s/requirements.md` NFR-* entries (quality tree + scenarios with target/minimum/measurement) plus ARCH-derived scenarios.
- Fidelity rules table (which section each artifact ID must land in) + new mandatory Step 5 fidelity check in `output-generation/SKILL.md` (v1.2.0): every approved/accepted artifact ID must appear verbatim in the generated output, missing IDs are placed before completion and the result is reported in the summary.
- Traceability appendix mapping ARCH/COMP/INT to their `related_to` REQ/NFR ids (no schema change needed).
- ADR template: `Source: {ARCH-ID}` added; participants list now comes from the session file instead of a hardcoded trio.

**Tasks**:
- [x] Full arc42 skeleton in design-arc42.md with placeholder policy.
- [x] Conditional persistence/API/config subsections keyed to artifact presence.
- [x] Diagram derivation rules (Mermaid, artifact-backed only).
- [x] Section 10 from NFRs + ARCH scenarios.
- [x] Fidelity check step in SKILL.md (all workflows; mandatory for specs/design).
- [x] Dogfood-verify (v0.8.0 batch, exp50): all 12 sections emitted, 5 diagram types rendered, §10 populated from NFRs, artifact-id diff clean (20/20).

**Acceptance criteria**:
- [x] Generated architecture.md contains all 12 arc42 sections (content or explicit placeholder).
- [x] Conditional sections keyed to artifact presence (Persistence + API Design emitted with backing artifacts; Configuration correctly absent).
- [x] No approved artifact ID missing from the rendered document (fidelity check reported: specs 28/28, design 20/20).

**Related**: FEAT-006 (superseded by this item), VKT-079/080/081 (covered as the conditional subsections), VKT-083/084 (adjacent, not in scope), spec-validator arc42 checklist (compatible subset).

---

### FEAT-012: Roundtable quality — baseline ingestion, contradiction gate, technical panel

**Status**: completed | **Created**: 2026-07-11 | **Completed**: 2026-07-12 | **Priority**: high | **Target**: v0.8.0 | **Verified**: test-baselines/v0.8.0-dogfood.md | **Origin**: Vektra dogfood (VKT-004, VKT-006, VKT-035/061)

**Context**: three general roundtable gaps from the Vektra analysis keep-list:
- `/s2s:specs` could not load an existing `requirements.md` as a coverage baseline (VKT-004): its Smart Source Detection saw brainstorm/ideas/backlog only, and the existing document was read solely for the Override/Merge choice.
- Contradictions between approved artifacts from different rounds were invisible (VKT-006): the facilitator's per-round context is focused, and nothing re-checked the full artifact set before conclude.
- The specs panel had no technical role and `profiles/specs.yaml` blocked `--participants` (`configurable: false`) (VKT-035/061).

**Fix (2026-07-11, v0.8.0 cycle)**:
- **Baseline ingestion**: specs Smart Source Detection now detects `docs/specifications/requirements.md` / `.s2s/requirements.md` as a baseline source; selected baselines are parsed into `BASE-*` items stored in `INPUT_SOURCES.baseline_requirements` (context-snapshot), forwarded to the facilitator (`phase-2-core.md` §2.2b), tracked via `related_to`, and enforced at conclude by the new Step 2.9b gate 5 (uncovered/unflagged items reject conclude). Facilitator: new Baseline Coverage section, focus priority 5, Conclude Criteria 6.
- **Contradiction visibility**: facilitator gains a cross-round contradiction duty (raise CONF citing both ids instead of silently carrying both); orchestrator runs an independent contradiction sweep at conclude (Step 2.9b gate 6, all workflows) that files a CONF-* and rejects conclude.
- **Panel**: `technical-lead` added to the specs default panel (profile + config template + repo config + guide tables); `profiles/specs.yaml` now `configurable: true`; explicit participant-resolution precedence (`--participants` → config → profile) and a non-blocking "no technical role on the panel" warning at session start for specs/design (roundtable.md).

**Tasks**:
- [x] specs.md baseline detection + BASE-* parsing into INPUT_SOURCES.
- [x] roundtable.md input_sources block + participant resolution + panel coverage warning.
- [x] phase-2-core.md §2.2b input_sources forwarding + §2.9b gates 5 (baseline) and 6 (contradictions).
- [x] facilitator.md baseline coverage + contradiction duty + conclude criteria 6.
- [x] profiles/specs.yaml + config template/repo sync + profile-schema comment + s2s-guide panel tables.
- [x] Dogfood-verify (v0.8.0 batch, exp50): 8/8 baseline items covered, premature conclude rejected naming the uncovered item; injected contradiction raised as CONF in-round and escalated; panel warning initially skipped → fixed as BUG-026 (artifact carrier verified).

**Acceptance criteria**:
- [x] Every seeded baseline feature becomes REQ/EX/OQ or a flagged gap before conclude (VKT-004 proposed test; 2.9b gate 5 rejection observed live).
- [x] A REQ contradicting an approved artifact is detected before close (VKT-006 proposed test; in-round CONF + escalation).
- [x] Missing-domain warning with a non-technical panel (VKT-035; via BUG-026 artifact carrier in validation.warnings).

**Related**: BUG-009 (the 2.9b gate this extends), VKT-005/034/036 (broader coverage machinery, deliberately parked per decision record).

---

### FEAT-013: Plan source-grounding + structured plan template blocks

**Status**: completed | **Created**: 2026-07-11 | **Completed**: 2026-07-12 | **Priority**: high | **Target**: v0.8.0 | **Verified**: test-baselines/v0.8.0-dogfood.md | **Origin**: Vektra dogfood (VKT-060/031/016 source-grounding; VKT-032/042/043 template gaps, all three re-verified real on current code)

**Context**: `/s2s:plan` generated plans from documentation only: `commands/plan.md` Phase 1 sent doc content to a generic `Task(subagent_type="general-purpose")` while the existing `agents/exploration/codebase-analyzer.md` agent sat unused. Plans proposed fields/paths that already existed, and followed docs the code had drifted from. The plan template also had three structural gaps: free-text Testing Approach with no test-infrastructure declaration (criteria silently skipped and reported as passed, VKT-032), no state-lifecycle prompt (caches planned with a startup load and no runtime write paths, VKT-042), and no NFR benchmark block (NFR targets cited without a runnable verification, VKT-043).

**Fix (2026-07-11, v0.8.0 cycle)**:
- **Codebase analysis wired in (VKT-060/031/016)**: new Phase 1a in `commands/plan.md` detects source files and **uses the codebase-analyzer agent** (proper agent-file invocation, not a generic Task) with doc-derived focus areas; the report (`CODEBASE_ANALYSIS`) feeds Phase 1b work-item identification (existing-code column, code-wins-over-docs rule, drift flagging) and the per-plan generation prompt (real paths/signatures only, extend instead of re-create, note drift). Basic Mode runs a topic-scoped analysis. Greenfield projects skip with an explicit marker.
- **Template blocks (VKT-032/042/043)**: `templates/plan.md` gains a State & Data Lifecycle table (created/updated/invalidated-by per stateful element), a Test Infrastructure block (required infra, providing task, false-pass guard) and an NFR Verification table (dataset/tool/env/pass criterion per covered NFR); generation prompt and placeholder-replacement list updated to fill them.

**Tasks**:
- [x] plan.md Phase 1a codebase detection + codebase-analyzer invocation; Phase 1b grounding rules.
- [x] Plan Generation prompt: codebase grounding + structured sections; Basic Mode topic-scoped analysis.
- [x] templates/plan.md: lifecycle table, test-infra block, NFR verification table.
- [x] Dogfood-verify (v0.8.0 batch, exp50): codebase-analyzer invoked in Phase 1a; 11 plans grounded in source with drift flagged; all 3 structured blocks filled in 11/11 plans.

**Acceptance criteria**:
- [x] Plans match source, not docs, on a doc-drifted fixture (VKT-060/016 proposed test).
- [x] A plan proposing existing fields/paths flags them instead of re-creating (VKT-031 proposed test; matching code marked keep-as-is).
- [x] Generated plans carry test-infra, state-lifecycle and NFR-benchmark blocks (VKT-032/042/043 proposed tests; 11/11).

**Related**: TECH-001 (completed: plan ADR integration), IDEA-037 (parked Vektra-scale plan-validation cluster — this item ships only its general kernel per decision record D2).

---

### BUG-026: Panel coverage warning skipped at runtime (display-only step)

**Status**: completed | **Created**: 2026-07-12 | **Completed**: 2026-07-12 | **Priority**: medium | **Target**: v0.8.0 | **Origin**: exp50 dogfood scenario 1a (VKT-035 verdict FAIL)

**Context**: the FEAT-012 panel domain coverage check in `commands/roundtable.md` was written as a standalone display step after participant resolution. At the exp50 dogfood (specs session with `--participants product-manager,ux-researcher` on a technical project) the orchestrator read the instruction but never rendered the warning — the same display-only-step failure class as BUG-013 (five contributing factors documented in `.claude/s2s-development.md`; a display with no artifact and no anchor gets dropped under token pressure).

**Fix applied (2026-07-12, two attempts)**:
1. First attempt moved the warning inside the "Display session start" block. The exp50 re-test showed a non-interactive run skipping the WHOLE session-start display, warning included — the display layer as such is unreliable.
2. Final fix: two carriers. **Artifact (mandatory)**: with `PANEL_WARNING == true` the session file is created with the panel entry in `validation.warnings` (surfaced by `/s2s:session:status` / `validate`); **display (best-effort)**: the ⚠ line stays in the session-start block. Same lesson as BUG-013/FIX-S1: persist to a file, don't trust display-only steps.

**Tasks**:
- [x] roundtable.md: check sets `PANEL_WARNING`; warning line embedded in the session-start block.
- [x] roundtable.md: session skeleton persists the panel entry in `validation.warnings` (mandatory carrier).
- [x] Re-test on exp50 (scenario 1a repeat with the patched plugin): `validation.warnings` populated in the session file.

**Acceptance criteria**:
- [x] Non-technical specs/design panel leaves the warning in `validation.warnings` at session creation (artifact carrier — verified exp50 re-test, 2026-07-12).

**Known limitation** (not a gate): the display carrier is best-effort; observed skipped in non-interactive runs. The artifact carrier is the contract.

**Related**: FEAT-012 (introduced the check), BUG-013 (same runtime-skip class), VKT-035.

---

### TECH-014: Reusable e2e dogfood harness (lean)

**Status**: completed | **Created**: 2026-07-12 | **Completed**: 2026-07-12 | **Priority**: medium | **Origin**: v0.8.0 exp50 dogfood (first piloted run)

**Context**: every cycle ends with a synthetic dogfood, but until v0.8.0 the process lived in per-cycle runbooks and session memory. The v0.8.0 run (first piloted via local tmux) produced transferable mechanics worth versioning: fixture design rules, scenario derivation from proposed_tests, kitty-submit/tmux driving quirks, and the verification-source table (files + transcript JSONL, never the pane scrollback). A fully scripted e2e was evaluated and rejected: roundtables are interactive and non-deterministic, driving requires judgment; what is deterministic is the transport and the procedure.

**Shipped (2026-07-12)**: `skills/dev-testing/references/dogfood-e2e.md` (NOT SHIPPED with the plugin) — invariants, runbook template, user-driven and piloted modes, verification sources, transport-helper spec (tm.sh/watch.sh) as appendix.

**Tasks**:
- [x] Procedure reference in dev-testing + SKILL.md registration.
- [x] Transport helper promoted to the contributor's infra tooling (external repo; the appendix here is the authoritative spec).

**Deliberately NOT built** (revisit only on real demand): headless driver (`claude -p` cannot answer AskUserQuestion), Agent-SDK-based automation, scenario auto-generation.

**Related**: test-baselines/v0.8.0-dogfood.md (first execution), decision record D3 (lean dogfood policy).

---

### FEAT-014: Design-to-plan bridge (pre-implementation consistency gate)

**Status**: planned | **Created**: 2026-07-13 | **Priority**: high | **Target**: v0.9.0 (headline) | **Origin**: Vektra analysis — decision record D1, critical review 06

**Context**: nothing in s2s covers the transition from design to implementation. After 6 design sessions the Vektra team had documents that captured the *what* and the *how* but not enough to start coding: they ran 7 spec-completion steps and a custom 4-agent consistency review entirely outside s2s, tracked only in an unversioned doc. That review found **3 blockers and 33 warnings in documents the workflow treated as complete** (VKT-008). The cost argument from the source: "meglio trovarli ora (costo: un'ora di review) che durante l'implementazione" — the actual run took ~5 minutes.

The gate is explicitly **not a roundtable**: the decisions are already taken; the gate verifies they are coherent, mutually consistent and implementable.

**Scope — the lean cut (VKT-037, VKT-038, VKT-069)**:

| Finding | What it buys |
|---------|--------------|
| VKT-037 | the phase itself: a pre-implementation audit for implementation-blocking gaps between `/s2s:design` and `/s2s:plan` |
| VKT-038 | the consistency gate: referential integrity across ID families (REQ/ARCH/NFR/QS/SC/ADR/ERR/BR), cross-document contradiction detection, BLOCKER/WARNING/INFO taxonomy, plus a cheap incremental re-check after fixes |
| VKT-069 | open-question closure: an implementation-blocking OQ (in Vektra, the ORM decision) stayed open through 6 sessions and blocked the DB schema and all data-access code. `/s2s:plan` should surface it before generating tasks |

**Explicitly OUT of scope** (stay parked in the `ideas.md` plan-integration umbrella; do not let them creep in):
- **VKT-039** — validation/acceptance scenarios as a first-class artifact with 5 coverage matrices. In Vektra this was ~1300 lines / 48 scenarios. The critical review (06) kept only 037/038/069 as the genuine bridge; 039 is the Vektra-scale half.
- VKT-040 (import-boundary check), VKT-041 (decision resolution states), VKT-057, VKT-072 (roundtable sequencing guidance).

**Orchestration constraint (VKT-071) — read before designing this**: s2s subagents report only to the caller and **cannot talk to each other**. The Vektra gate that worked used 4 *communicating* agents (the ref-checker finishes first and broadcasts; the schema→api and api→schema tracers exchange findings by DM; a lead consolidates and dedups), and cross-confirmation from two directions is what validated 2 of its 3 blockers. That pattern is **not expressible** with s2s subagents. It must be re-expressed as **sequential orchestrator-mediated passes**: each pass returns its findings to the orchestrator, which feeds pass N-1's output into pass N's input. Do not design an agent team.

**Open questions** (each with a recommended answer, to be confirmed at design time):

1. *Command surface: a new command, or a gate inside `/s2s:plan`?* — **Recommended: a distinct command** (e.g. `/s2s:review`) run between design and plan. It is not a roundtable, and folding it into `plan.md` would make `plan` refuse to run on its own output. `plan` then *consumes* its report.
2. *Blocking or advisory?* — **Recommended: advisory, escalating on BLOCKERs.** `/s2s:plan` warns and asks for confirmation when the latest review report has open BLOCKER findings; it never hard-refuses. Matches the "lean core + optional opt-in rigor" principle that gates the whole lean path.
3. *Where do open questions live?* — **Recommended: reuse the existing `open_questions` artifacts**, adding a `blocking: true|false` field and a resolution state. No new file, no new ID family.
4. *Incremental re-check after fixes?* — **Recommended: yes.** A single lightweight ref-checker pass (`--quick`); the full multi-pass gate only on demand. The source is explicit that a full re-review after fixes yields diminishing returns.

**Tasks**:
- [ ] ADR: command surface + blocking policy (open questions 1-2)
- [ ] Define the review report artifact: path, schema, BLOCKER/WARNING/INFO taxonomy
- [ ] Pass 1 — referential integrity: orphan and dangling refs across all ID families
- [ ] Pass 2 — cross-document consistency: contradictions between `requirements.md`, `architecture.md` and the ADRs
- [ ] Pass 3 — implementability: open blocking questions, unresolved decisions
- [ ] Wire `/s2s:plan` to read the report and surface open BLOCKERs before generating tasks (VKT-069)
- [ ] `--quick` incremental mode (ref-checker pass only)
- [ ] Dogfood-verify on a fixture seeded with a cross-document contradiction and a blocking open question

**Acceptance criteria**:
- [ ] A design output with a seeded cross-document contradiction yields a BLOCKER finding
- [ ] An implementation-blocking open question is surfaced before `/s2s:plan` generates tasks
- [ ] The gate runs entirely through orchestrator-mediated passes — no agent-to-agent communication assumed
- [ ] `--quick` re-check after fixes runs the ref-checker alone

**Related**: decision record D1 ("later: design-to-plan bridge if still wanted"), critical review 06 ("keep only the design-to-plan bridge (VKT-037/038/069) as genuine 1.0"), FEAT-012 (its Step 2.9b contradiction sweep is the in-session sibling of pass 2), TECH-015.

---

### BUG-027: Development tools ship to end users

**Status**: planned | **Created**: 2026-07-13 | **Priority**: medium | **Target**: v0.9.0 | **Origin**: v0.9.0 pre-cycle re-triage

**Context**: `commands/dev/check.md`, `commands/dev/test.md`, `agents/dev/dev-validator.md` and `skills/dev-testing/**` (including the `dogfood-e2e.md` runbook) are installed into **every user's plugin**. Nothing excludes them:

- `.claude-plugin/marketplace.json` declares `"source": "./"` — the whole repo tree *is* the plugin.
- `.claude-plugin/plugin.json` has no `files` / `exclude` / `ignore` field.
- `.github/workflows/` contains only `tests.yml`; there is no release or packaging job.
- The Makefile states explicitly that there is no build step.

The only "exclusion" is prose *inside* the dev files themselves (`NOT SHIPPED - development only`), which excludes nothing. QUAL-001 has carried the acceptance criterion "Tools NOT included in shipped plugin" since January and its Context asserted the exclusion was already in place; both were wrong. DEBT-002 (separate dev-tools repo) is the radical fix and stays deferred to 1.0 — this item is the cheap one that stops the leak now.

**Tasks**:
- [ ] Check whether the plugin manifest schema supports a path filter or exclude list; if it does, prefer it (zero build, zero CI surface)
- [ ] Otherwise add a release job in `.github/workflows/` that publishes a stripped tree (drop `commands/dev/`, `agents/dev/`, `skills/dev-testing/`)
- [ ] Verify with a fresh `/plugin install` that no `/s2s:dev:*` command, dev agent or dev skill is exposed

**Acceptance criteria**:
- [ ] A freshly installed s2s exposes no dev command, dev agent or dev skill
- [ ] Contributors working on `develop` keep the tools

**Related**: QUAL-001 (owned this criterion, now delegated here), DEBT-002 (radical fix, deferred to 1.0)

---

### BUG-028: Template HTML comments leak into generated plans

**Status**: planned | **Created**: 2026-07-13 | **Priority**: low | **Target**: v0.9.0 | **Origin**: v0.8.0 exp50 dogfood carry-over

**Context**: `templates/plan.md` carries HTML comments that are **authoring instructions for the generator**, e.g. `<!-- Format: - REQ-XXX: description @.s2s/requirements.md -->` and `<!-- Source types: backlog (FEAT-*, BUG-*...) -->`. `commands/plan.md` reads the template and replaces the `{placeholders}`, but never strips the comments — so the instructions are copied verbatim into every generated plan file in the user's `.s2s/plans/`. Observed in the exp50 dogfood output.

**Tasks**:
- [ ] Strip the authoring comments in `commands/plan.md` when rendering the template (or move them out of the template into the command's own instructions)
- [ ] Check the same class of leak in the other comment-carrying templates (`templates/project/{BACKLOG,ideas,CONTEXT,README}.md`, `templates/workspace/CONTEXT.md`) — those are copied to the user at `init`, where a comment may be legitimate guidance rather than a leak; decide per template

**Acceptance criteria**:
- [ ] Generated plan files contain no template authoring comments

---

### TECH-015: Verify FEAT-012 contradiction sweep (Step 2.9b gate 6) at runtime

**Status**: planned | **Created**: 2026-07-13 | **Priority**: medium | **Target**: v0.9.0 | **Origin**: v0.8.0 exp50 dogfood carry-over

**Context**: FEAT-012 added an independent cross-round contradiction sweep over the full artifact set, run before conclude is accepted (`phase-2-core.md` Step 2.9b, gate 6). In the exp50 dogfood it was verified **only by static reading** — no seeded contradiction ever made it fire at runtime. Given BUG-013 and BUG-026 (steps without an artifact carrier get silently skipped under token pressure), an unverified gate is a plausible silent no-op, and this one is a *conclude gate*: if it no-ops, the session concludes with contradictions in the output and nobody notices.

**Tasks**:
- [ ] Seed a cross-round contradiction in the v0.9.0 dogfood fixture (an artifact approved in round N contradicted by one in round N+2)
- [ ] Confirm gate 6 rejects conclude and surfaces the contradiction
- [ ] If it no-ops: give it an artifact carrier, as BUG-026 did for the panel warning

**Acceptance criteria**:
- [ ] Gate 6 demonstrably rejects conclude on a seeded contradiction in a real session

**Related**: FEAT-012 (introduced the gate), BUG-013 / BUG-026 (the silent-skip failure class), FEAT-014 (its pass 2 is the out-of-session sibling — verify both on the same fixture)

---

### FEAT-004: Enhanced hybrid workspace support

**Status**: planned | **Created**: 2026-01-29 | **Priority**: medium | **Origin**: Vektra project feedback

**Context**: Workspace mode supports hybrid monorepo/multi-repo structures via `has_own_git` field, but lacks metadata for real-world hybrid scenarios: external repos referenced by GitHub path instead of relative path, component development phases, tech stack info, and lifecycle status tracking.

**Use case** (Vektra): Modular RAG platform with:
- Monorepo components: vektra-core, vektra-ingest, etc. (Python, share types)
- External repos: vektra-moodle (PHP plugin), vektra-sdk-py, vektra-sdk-js (published packages)

**Current limitations**:
1. External repos require relative paths (`../vektra-moodle`) - only works if cloned as siblings
2. No formal way to track component existence (planned vs created)
3. No phase metadata for staged development
4. No language/stack info for agent context
5. Component notes require YAML comments

**Proposed schema extensions** (additive, backward-compatible):

```yaml
components:
  - id: "vektra-moodle"
    name: "Moodle LMS Adapter"           # NEW: human-readable name
    # Existing fields
    path: "../vektra-moodle"
    type: "service"
    has_own_git: true
    depends_on: ["vektra-learn"]
    # New optional fields
    repo: "vektralabs/vektra-moodle"     # NEW: GitHub reference (org/repo)
    language: "php"                       # NEW: primary language
    phase: 2                              # NEW: development phase (integer)
    status: "planned"                     # NEW: planned | in_progress | stable
    notes: "PHP plugin for Moodle LMS"   # NEW: free-form description
```

**Validation behavior**:
- `repo`: If provided, `/s2s:init --workspace` can warn when not cloned
- `status: planned` + missing directory: no warning (expected)
- `status: in_progress|stable` + missing directory: warning
- `language`: Informational, used for agent context selection

**Impact on roundtable**:
- Facilitator can filter/group by phase
- Participants understand tech stack per component
- Strategy can prioritize by phase

**Tasks**:
- [ ] Extend workspace.yaml schema with new optional fields
- [ ] Update `templates/workspace/workspace.yaml` with documented examples
- [ ] Update `/s2s:init --workspace` to validate component status vs existence
- [ ] Update roundtable facilitator to expose component metadata in context
- [ ] Document in s2s-guide skill

**Acceptance criteria**:
- [ ] New fields are optional (existing workspaces unchanged)
- [ ] `repo` field parsed and validated (format: `org/repo`)
- [ ] `/s2s:init` warns on status/path inconsistencies
- [ ] Roundtable sessions receive component metadata
- [ ] s2s-guide documents workspace schema extensions

**Related**: FEAT-001 (decision propagation), FEAT-002 (dependency graph)

---

### FEAT-005: Setup workflow structured output

**Status**: planned | **Created**: 2026-01-29 | **Priority**: medium | **Origin**: Vektra project feedback

**Context**: `/s2s:roundtable --workflow setup` produces session artifacts (requirements, decisions) but no formal output files. Unlike `specs` (SRS) and `design` (arc42), setup workflow outputs remain in session files requiring manual extraction.

**Problem**: After a setup roundtable, users must manually create:
- `GOVERNANCE.md` (from governance requirements)
- `ROADMAP.md` (from roadmap requirements)
- `CONTRIBUTING.md` updates (from contribution process reqs)
- `README.md` updates (from positioning reqs)
- `ADR-*.md` files (from architectural decisions)

**Proposed solution**: Output mapping by requirement category.

```yaml
# In output-generation skill or setup workflow config
output_mapping:
  setup:
    categories:
      governance:
        target: "GOVERNANCE.md"
        topics: ["community-governance", "license", "contribution"]
      roadmap:
        target: "ROADMAP.md"
        topics: ["project-roadmap", "milestones", "phases"]
      documentation:
        target: "docs/README.md"
        topics: ["documentation-strategy", "diataxis"]
      positioning:
        target: "README.md"
        sections: ["overview", "audience", "differentiation"]
      architecture:
        target: ".s2s/decisions/ADR-{NNN}-{slug}.md"
        topics: ["architecture-decision", "technical-decision"]
```

**Output location**: Project root (not `.s2s/`). These are standard OSS project files required by GitHub and similar platforms. The setup workflow defines the one-time project structure for a proper OSS project.

**New vs existing project handling**:

| Scenario | Behavior |
|----------|----------|
| New project (file missing) | Generate file from template + roundtable decisions |
| Existing project (file exists) | Analyze current content, suggest merge/update strategy |
| Structure mismatch | Warn and propose migration (e.g., flat → `docs/` hierarchy) |

For existing projects, output generation should:
1. Detect existing files (GOVERNANCE.md, CONTRIBUTING.md, etc.)
2. Compare roundtable decisions against current content
3. Present diff or integration suggestions (not blind overwrite)
4. Allow user to accept, modify, or skip each file

**Classification approach**:
1. Primary: Match requirement `topic_id` to category topics
2. Fallback: Pattern match on requirement title/description
3. Unclassified: Remain in session summary (manual review)

**Output templates** (new directory):
```
templates/setup/
├── GOVERNANCE.md.template
├── ROADMAP.md.template
├── CONTRIBUTING.md.template
└── README-section.md.template
```

**Design decision needed**: First-class workflow vs enhanced output generation

| Approach | Pros | Cons |
|----------|------|------|
| First-class `workflow_type: setup` | Clear semantics, dedicated participants, full parity with specs/design | More code, another workflow to maintain |
| Enhanced output-generation | Lighter, reuses generic roundtable | Less discoverable, classification heuristics needed |

**Recommended**: Start with enhanced output-generation (detects setup sessions, prompts for file generation). Promote to first-class workflow if usage pattern stabilizes.

**Participant considerations**:
- Current setup mix: product-manager, documentation-specialist, oss-community-manager
- May need: architect (for ADR generation), tech-lead (for roadmap feasibility)
- Config in roundtable-strategies or dedicated setup.md reference

**Tasks**:
- [ ] Define setup output categories in output-generation skill
- [ ] Create templates/setup/ with standard OSS templates
- [ ] Add setup detection to `/s2s:output-generation` (or auto-trigger on close)
- [ ] Implement requirement classification by topic_id
- [ ] Generate GOVERNANCE.md from governance requirements
- [ ] Generate ROADMAP.md from roadmap requirements
- [ ] Generate/update ADRs from architecture requirements
- [ ] Implement existing file detection and diff/merge suggestions
- [ ] Implement structure analysis (detect current layout, suggest migrations)
- [ ] Add `--workflow setup` documentation to s2s-guide

**Acceptance criteria**:
- [ ] Setup roundtable session produces classified requirements
- [ ] `/s2s:output-generation` (or session close) offers file generation
- [ ] GOVERNANCE.md generated with license, governance model, contribution process
- [ ] ROADMAP.md generated with phases and milestones
- [ ] ADRs generated for architecture decisions
- [ ] Generated files reference source session and requirement IDs

**Related**: TECH-002 Phase 1 (output-generation skill), output-generation/SKILL.md

---

### FEAT-006: Enhanced arc42 output with traceability (SUPERSEDED by BUG-025)

**Status**: completed | **Created**: 2026-02-03 | **Superseded**: 2026-07-11 | **Priority**: medium

> **Superseded (2026-07-11)**: absorbed into BUG-025 (v0.8.0). The Vektra analysis decision record (2026-06-13) overturned this item's "no placeholders, never all 12 sections" principle: the full arc42 backbone is now always emitted with explicit placeholders, and Runtime/Deployment/Cross-cutting are derived from artifacts when possible. What this item proposed ships via BUG-025: traceability appendix (via existing `related_to`, no `traces_to` schema change), Mermaid building-blocks diagram, glossary, conditional risks. Original text kept below for history.

**Context**: Output generation for design workflow produces a subset of arc42 sections. After user testing, specific high-value additions were identified. The goal is NOT to generate all 12 arc42 sections (many require manual/tool input), but to maximize value from available roundtable data.

**Principle**: Generate sections IF AND ONLY IF data is available. No empty placeholders.

**High-value additions** (from user feedback):

| Addition | Value | Data source | Notes |
|----------|-------|-------------|-------|
| **Traceability table REQ → ARCH** | High | `traces_to` field in ARCH-* | Cross-workflow link |
| Building Blocks table | High | COMP-* artifacts | Already planned, add Mermaid stub |
| Glossary | Medium | Auto-extract from artifacts | Terms with definitions |
| Risks section | Medium | RISK-* if available | From brainstorm or explicit |

**Sections to ADD to current template**:

1. **Traceability Matrix** (NEW - high value)
   ```markdown
   ## Traceability

   | Requirement | Architecture Decisions | Components |
   |-------------|----------------------|------------|
   | REQ-001     | ARCH-001, ARCH-003   | COMP-002   |
   | REQ-002     | ARCH-002             | COMP-001   |
   ```
   Requires: `traces_to: [REQ-001]` field in ARCH-* and COMP-* artifacts.

2. **Building Blocks** (enhance existing)
   - Add Mermaid component diagram stub (auto-generated from COMP-* dependencies)
   - GitHub/GitLab render Mermaid natively
   ```mermaid
   graph TD
     COMP-001[API Gateway] --> COMP-002[Auth Service]
     COMP-001 --> COMP-003[Core Service]
   ```

3. **Glossary** (NEW)
   - Auto-extract terms from artifact titles and descriptions
   - Format: `**Term**: definition`

4. **Risks and Technical Debt** (conditional)
   - Only if RISK-* artifacts exist (from brainstorm or design session)
   - Omit section entirely if no risks defined

**Sections intentionally OMITTED** (require external tools/manual input):

| Section | Why omitted |
|---------|-------------|
| Runtime View | Requires sequence diagrams (creative, tool-dependent) |
| Deployment View | Requires infrastructure diagrams (PlantUML, draw.io) |
| Cross-cutting Concepts | Too generic, better as ADRs |

These can be added manually or via `/s2s:plan` tasks.

**Schema change required**:

Add `traces_to` field to ARCH-* and COMP-* artifact schemas:
```yaml
ARCH-001:
  title: "REST API design"
  decision: "..."
  traces_to: [REQ-001, REQ-005]  # NEW: links to requirements
```

**Tasks**:
- [ ] Add `traces_to` field to ARCH-* schema in session-schema.md
- [ ] Add `traces_to` field to COMP-* schema in session-schema.md
- [ ] Update facilitator to prompt for traceability during design rounds
- [ ] Add Traceability Matrix section to design-arc42.md template
- [ ] Add Mermaid stub generation for Building Blocks (from COMP-* deps)
- [ ] Add Glossary section with auto-extraction logic
- [ ] Add conditional Risks section (only if RISK-* exist)
- [ ] Update s2s-guide with new output format

**Acceptance criteria**:
- [ ] Traceability matrix generated from `traces_to` fields
- [ ] Building Blocks includes Mermaid component diagram
- [ ] Glossary auto-populated from artifact terms
- [ ] Risks section appears only when RISK-* artifacts exist
- [ ] No empty/TBD sections in output
- [ ] Existing architecture.md merged, not overwritten

**Related**: FEAT-005 (setup output), output-generation/SKILL.md, session-schema.md

---

### FEAT-007: Proactive documentation completeness (SUPERSEDED by BUG-025 + FEAT-012)

**Status**: superseded | **Created**: 2026-02-03 | **Superseded**: 2026-07-13 | **Priority**: medium

> **Superseded (2026-07-13, v0.9.0 pre-cycle re-triage)**. This item carried a `NEEDS REVIEW` flag and a first task reading "esplorare approcci alternativi". The exploration was settled by the Vektra decision record, in favour of an approach this item never listed. Specifically:
>
> - **The "derivati / auto-generabile ✅" row shipped in v0.8.0 (BUG-025)**: traceability appendix (from `related_to`), glossary and 5 Mermaid diagram types are now emitted unconditionally by `skills/output-generation/references/design-arc42.md`, with a mandatory fidelity check in `output-generation/SKILL.md` guarding against silent YAML→Markdown loss.
> - **The "facilitator gap awareness" row shipped in v0.8.0 (FEAT-012)** for requirements coverage: baseline `BASE-*` ingestion plus a conclude gate that rejects conclusion while baseline items are uncovered (`phase-2-core.md` Step 2.9b).
> - **Its acceptance criterion was deliberately inverted.** FEAT-007 asked for "no empty/TBD sections in output". BUG-025 chose the opposite: always emit all 12 arc42 sections, with an explicit `*Not covered in this design session.*` placeholder where the session has no data. Making the gap **visible in the document** is now the chosen mechanism for this item's own goal ("the user should not have to notice what's missing").
>
> What is genuinely unbuilt is only `/s2s:doc-status` + the documentation-profile schema (minimal/standard/enterprise) + profile inference — options B and C below, whose premise (the user cannot see what is missing) no longer holds. Not worth reviving as written. If a real need resurfaces, file a fresh item with the current baseline as its starting point.
>
> Original body kept below for the record.

**Problema**: Oggi ogni comando è isolato. L'utente deve sapere cosa manca (tracciabilità, diagrammi, glossario, NFR, etc.) quando il plugin ha tutte le informazioni per capirlo autonomamente.

**Goal**: Il plugin dovrebbe generare automaticamente tutta la documentazione possibile per la natura e contesto del progetto, senza che l'utente debba accorgersi di cosa manca.

**Opzioni considerate** (nessuna ancora scelta):

| Approccio | Descrizione | Pro | Contro |
|-----------|-------------|-----|--------|
| A) Checklist statica | Mostra cosa manca dopo ogni comando | Semplice | Utente deve agire |
| B) Documentation Profile | Config con profilo (minimal/standard/enterprise) | Configurabile | Utente deve sapere cosa configurare |
| C) Gap Analysis Agent | Inferisce profilo, analizza gap, auto-genera derivati | Proattivo | Complessità |
| D) Workflow orchestrato | Meta-comando che fa tutto | One-shot | Perde valore roundtable iterativi |
| E) Altro? | Da esplorare | ? | ? |

**Distinzione chiave**:

| Tipo | Esempio | Auto-generabile? |
|------|---------|------------------|
| Derivati | Traceability, Glossary, Mermaid diagrams | ✅ Sì |
| Decisioni | Nuovi ADR, scelte architetturali | ❌ Richiede roundtable |
| Tool-dependent | Sequence diagrams dettagliati | ❌ Richiede tool esterni |

**Bozza di soluzione** (da rivedere):

1. **`/s2s:doc-status`**: Mostra stato documentazione vs profilo atteso
2. **Auto-generation post-output**: Genera derivati senza chiedere
3. **Profile inference**: Inferisce profilo da contesto (OSS, enterprise, etc.)
4. **Facilitator awareness**: Facilitator rileva gap durante roundtable

**Domande aperte**:
- È meglio un comando dedicato (`doc-status`) o integrazione nei comandi esistenti?
- L'auto-generation dovrebbe essere opt-in o opt-out?
- Come gestire progetti con requisiti documentali molto diversi?
- Esiste un approccio più semplice che risolve l'80% del problema?

**Tasks** (preliminari, da confermare):
- [ ] **FIRST**: Esplorare approcci alternativi
- [ ] Decidere approccio finale (ADR?)
- [ ] Definire "documentation profile" schema
- [ ] Implementare gap analysis logic
- [ ] Creare `/s2s:doc-status` o equivalente
- [ ] Integrare auto-generation in output-generation
- [ ] Aggiornare facilitator per gap awareness

**Acceptance criteria** (da definire dopo review):
- [ ] TBD - dipende dall'approccio scelto

**Related**: FEAT-006 (arc42 traceability), FEAT-005 (setup output), output-generation

---

### FEAT-008: Auto-generate INDEX.md for --all plan execution

**Status**: planned | **Created**: 2026-02-18 | **Priority**: high

**Context**: When running `/s2s:plan --all`, the command computes a dependency-ordered wave structure, generates all plan files, and prints a summary to the terminal. However, no persistent artifact captures the wave structure, dependency graph, or per-plan status. The terminal output disappears after scrolling or session end.

During a real usage session on a project with 15 generated plans, the user had to manually create `.s2s/plans/INDEX.md` containing wave tables (plan ID, title, complexity, status), a compact dependency graph, and critical implementation notes. This file proved immediately valuable as a navigation reference for sequencing work.

**Observed pattern**: The `--all` execution already computes all the data needed (work items, dependencies, suggested order). The gap is that this data is only rendered to the terminal and not persisted.

**Proposed behavior**: After generating all plan files, `--all` auto-generates `.s2s/plans/INDEX.md` with:

1. **Wave tables**: Plans grouped by dependency wave (wave 1 = no deps, wave 2 = depends on wave 1, etc.)
   - Columns: plan ID, title, complexity, status (default: pending)
2. **Dependency graph**: Compact text representation showing which plans depend on which
3. **Critical notes**: Section for implementation-order notes (e.g., "shared types must be defined in wave 1 before consumers in wave 2")
4. **Status tracking**: Status field updatable manually (pending → in_progress → completed)

**Tasks**:
- [ ] Add INDEX.md generation step to plan.md after Phase 4 (all plans generated)
- [ ] Define INDEX.md template in `templates/plan-index.md`
- [ ] Compute wave structure from dependency graph
- [ ] Include status column with default `pending`
- [ ] Update Output Summary section to reference INDEX.md

**Acceptance criteria**:
- [ ] `/s2s:plan --all` creates `.s2s/plans/INDEX.md` alongside plan files
- [ ] INDEX.md contains wave tables with plan ID, title, complexity, status
- [ ] INDEX.md contains dependency graph (text-based)
- [ ] Status values are manually editable (pending → in_progress → completed)
- [ ] Re-running `--all` regenerates INDEX.md (with warning if existing has modified statuses)
- [ ] `/s2s:plan:list` reads INDEX.md if present for richer display

**Related**: FEAT-009 (--all-first guidance), plan.md Phase 4 (Output Summary)

---

### FEAT-009: Recommend --all-first pattern in Full Documentation Mode

**Status**: planned | **Created**: 2026-02-18 | **Priority**: medium

**Context**: In Full Documentation Mode (requirements.md + architecture.md exist), the most valuable implementation items (core components, features, infrastructure) live in the documentation and are only surfaced by the analysis agent during `--all` execution. These items are not in the backlog.

Without `--all`, the "No target provided" path (plan.md lines 169-197) shows only backlog items with `status: planned`. A user picking items one-by-one misses: (a) cross-plan dependency ordering, (b) the opportunity to define all component boundaries before writing any code, (c) the ability to review full scope before committing to a sequence.

The "plan everything before implementing anything" pattern is valuable but not guided. The skill does not explain or recommend it.

**Proposed behavior**: In Full Documentation Mode, when no `--all` flag, no `--component`, and no specific target are provided, the skill should proactively explain the `--all` pattern before listing individual backlog items:

```
This project has complete specs + architecture documentation.

Recommendation: Running --all will:
  - Identify all implementation work items from requirements and architecture
  - Compute cross-plan dependencies and execution waves
  - Generate an execution index (INDEX.md) for tracking

This is recommended for projects starting implementation, as it ensures
component boundaries are defined before any code is written.

Alternatively, select an individual item below.
```

Then proceed to show planned backlog items as currently done.

**Tasks**:
- [ ] Add Full Documentation Mode detection to "No Target Provided" path in plan.md
- [ ] Add recommendation block before planned items listing
- [ ] Add "Run --all (Recommended)" as first option in AskUserQuestion
- [ ] Keep existing individual item selection as alternative path

**Acceptance criteria**:
- [ ] In Full Documentation Mode without flags, user sees --all recommendation before item list
- [ ] Recommendation explains the value (dependencies, boundaries, scope review)
- [ ] User can still select individual items (recommendation is not blocking)
- [ ] In Basic Mode (no docs), behavior unchanged (no recommendation shown)
- [ ] If `--all` or `--component` or target provided, recommendation skipped

**Related**: FEAT-008 (INDEX.md generation), plan.md "No Target Provided" section

---

### FEAT-010: Cross-validate backlog status with git history

**Status**: planned | **Created**: 2026-02-18 | **Priority**: medium

**Context**: When listing planned backlog items (either in "No target provided" path or during `--all` analysis), the skill showed items like TECH-001 and INFRA-004 as `status: planned`, but both had already been completed in recent commits (`git log` referenced them by ID). The skill has no mechanism to detect stale backlog items whose work was done outside the s2s workflow.

This creates wasted planning effort: the user (or the analysis agent during `--all`) may generate plans for work that already exists in the codebase.

**Proposed behavior**: When listing planned items or during `--all` analysis, optionally check recent git history for references to planned backlog IDs:

1. Run `git log --oneline -20` (lightweight, last 20 commits only)
2. For each planned backlog item ID (FEAT-NNN, TECH-NNN, etc.), check if the ID appears in commit messages
3. If found, add a warning:

```
⚠️  Potentially stale items detected:
   TECH-001 appears in commit abc1234: "feat(TECH-001): implement ADR integration"
   INFRA-004 appears in commit def5678: "chore(INFRA-004): add CI pipeline"

   Verify if these items are already completed before planning them.
```

4. Do not auto-change status (user must confirm)

**Scope**: This is a lightweight heuristic, not a full traceability system. It catches the most common case (commit messages reference backlog IDs) without adding complexity.

**Tasks**:
- [ ] Add git history check step to plan.md before item listing
- [ ] Scan `git log --oneline -20` for planned item IDs (regex match)
- [ ] Display warning for matched items with commit hash and message
- [ ] Skip check if not a git repo or no planned items
- [ ] Consider adding to `/s2s:plan:list` as well

**Acceptance criteria**:
- [ ] Planned items referenced in recent git commits trigger a warning
- [ ] Warning includes commit hash and message for verification
- [ ] No automatic status changes (user decides)
- [ ] Check is fast (single git log call, regex scan)
- [ ] Graceful skip when not in a git repo
- [ ] Works in both `--all` and individual item listing paths

**Related**: FEAT-009 (--all-first guidance), backlog-management skill

---

### FEAT-011: Surface documentation-derived items in plan selection UX

**Status**: planned | **Created**: 2026-02-18 | **Priority**: medium

**Context**: In Full Documentation Mode without `--all`, the "No Target Provided" path (plan.md lines 169-197) shows only backlog items with `status: planned`. This is misleading in projects with complete documentation: the listed items are typically peripheral (CODEOWNERS file, docs structure, CI config) while the actual core implementation items (features, components, infrastructure from requirements.md and architecture.md) are invisible because they aren't in the backlog yet.

A user seeing only peripheral items may think "there's nothing substantial to plan" when in reality the bulk of the implementation work is waiting to be identified via `--all` or doc analysis.

**Proposed behavior**: In Full Documentation Mode without `--all`, after showing planned backlog items, add a contextual note:

```
Planned Items Ready for Implementation
══════════════════════════════════════

From BACKLOG.md:
1. TECH-001: CODEOWNERS file setup
   Status: planned | Priority: low
   ...

Note: Additional implementation items exist in your requirements and
architecture documentation but are not yet in the backlog. Run --all
to identify features, components, and infrastructure items from these
docs.
```

This makes the distinction between backlog items and documentation-derived items visible, so users understand what they're choosing from.

**Tasks**:
- [ ] Add documentation availability check to "No Target Provided" path
- [ ] Add contextual note after backlog item listing when docs exist
- [ ] Note should mention which docs are available (requirements, architecture, or both)
- [ ] Skip note in Basic Mode (no docs to analyze)

**Acceptance criteria**:
- [ ] In Full Documentation Mode, item listing includes note about doc-derived items
- [ ] Note mentions specific available docs (requirements.md, architecture docs)
- [ ] Note explains that --all surfaces additional items
- [ ] In Basic Mode, no note shown (nothing additional to surface)
- [ ] Note does not appear if --all or --component flags are present

**Related**: FEAT-009 (--all-first guidance), FEAT-008 (INDEX.md), plan.md "No Target Provided" section

---

### FEAT-003: Configuration command (/s2s:config)

**Status**: planned | **Created**: 2026-01-24 | **Priority**: medium | **Depends on**: TECH-005

**Context**: Need a unified way to view and modify s2s configurations, including token tracking setup, roundtable defaults, and session settings.

**Proposed UX**: Menu-driven interaction using AskUserQuestion tool:
```
s2s Configuration
═════════════════

What would you like to configure?

○ Token tracking setup
○ Roundtable defaults
○ Session settings
○ View current configuration
```

**Features**:
- Token tracking: enable/disable, statusline status, install/update
- Roundtable defaults: strategy, max rounds, participants
- Session settings: verbose mode, interactive mode
- View: show all current config values

**Tasks**:
- [ ] Create `commands/config.md` with menu structure
- [ ] Integrate statusline setup from TECH-005
- [ ] Add config.yaml toggle for token_tracking
- [ ] Support viewing merged config (global + project)

**Acceptance criteria**:
- [ ] `/s2s:config` shows interactive menu
- [ ] Token tracking can be enabled/disabled
- [ ] Statusline setup automated via menu option

---

### FEAT-001: Decision propagation (workspace)

**Status**: planned | **Created**: 2026-01-17 | **Depends on**: REQ-051

**Context**: Workspace-level decisions should propagate to affected components as backlog items.

**Tasks**:
- [ ] Add `affects: [components]` field to ADR template
- [ ] Session close suggests creating component backlog items
- [ ] Backlog items reference originating workspace decision
- [ ] workspace.yaml tracks propagation status

**Acceptance criteria**:
- [ ] Decisions with `affects` trigger propagation prompt
- [ ] Component backlog items reference workspace ADR

---

### FEAT-002: Dependency graph (workspace)

**Status**: planned | **Created**: 2026-01-17 | **Depends on**: REQ-052

**Context**: Auto-detect and maintain component dependencies in workspaces.

**Tasks**:
- [ ] Scan imports during init to detect dependencies
- [ ] Update workspace.yaml with depends_on
- [ ] `/s2s:init --update-deps` command
- [ ] Plan command considers dependency order

**Acceptance criteria**:
- [ ] Dependencies auto-detected during init
- [ ] Plan considers dependency order

---

### TECH-001: Plan command ADR integration

**Status**: completed | **Created**: 2026-01-16 | **Updated**: 2026-06-13 | **Completed**: 2026-06-13 (retroactive: shipped with the v0.3.0/v0.4.0 plan-command work, never marked)

**Context**: The `/s2s:plan` command should read decisions/ to inform plan generation.

**Resolution (2026-06-13 backlog audit)**: the work is in shipped code. `commands/plan.md` maps `ARCH-*` ids to `.s2s/decisions/` ("Read ADR, use as plan input", ID-pattern table) and the plan template substitutes `{decisions-list}` (relevant ADRs, or N/A). If a residual is ever wanted (proactive read of ALL `decisions/*.md` vs only ARCH-*-targeted planning), file it as a new narrow item.

**Tasks**:
- [x] plan.md reads .s2s/decisions/*.md
- [x] ADRs influence task breakdown
- [x] Reference relevant ADRs in plan output

**Acceptance criteria**:
- [x] Plan considers decisions/ content
- [x] Previous phases inform plan tasks

---

### TECH-002: Roundtable command unification

**Status**: completed | **Created**: 2026-01-20 | **Updated**: 2026-05-26 | **Origin**: IDEA-008
**ADRs**:
- [0011-roundtable-command-unification](decisions/0011-roundtable-command-unification.md)
- [0012-output-generation-skill](decisions/0012-output-generation-skill.md)

**Context**: specs.md, design.md, brainstorm.md have ~60% code duplication (~1600+ lines each). They claim to follow `roundtable-execution` and `roundtable-strategies` skills but implement everything inline. roundtable.md is underpowered in comparison.

**Analysis (2026-01-25, updated after Phase 6)**:

| Command | Lines | roundtable-execution | roundtable-strategies | Token tracking | state.json |
|---------|-------|---------------------|----------------------|----------------|------------|
| specs.md | 1717 | Declared, not used (inline) | Declared, not used | ✅ Added | ✅ Read+Write |
| design.md | 1590 | Declared, not used (inline) | Declared, not used | ✅ Added | ✅ Read+Write |
| brainstorm.md | 1571 | Declared, not used (inline) | Declared, not used (Disney inline) | ✅ Added | ✅ Read+Write |
| roundtable.md | 402 | "Follow skill" + reminders | ✅ Reads reference | ✅ Reminders | ✅ Read+Write |

**Root problems**:
1. Skills declared in frontmatter but not actually used
2. Duplicated content: workflow defaults, Disney phases, artifact types
3. New guidelines (token tracking, state.json) not propagated to any command
4. roundtable-strategies has useful content that's duplicated inline

**Goal**: Unify execution logic with "Core Inline + Skill Reference" pattern.

**Target architecture**:
```
commands/
├── roundtable.md         # ~600 lines: full implementation, all workflows
├── specs.md              # ~150 lines: thin launcher
├── design.md             # ~150 lines: thin launcher
├── brainstorm.md         # ~150 lines: thin launcher

skills/
├── roundtable-strategies/  # WHAT: phases, prompts, consensus
│   ├── SKILL.md            # Strategy selection + workflow defaults
│   └── references/{strategy}.md
│
└── roundtable-execution/   # HOW: execution loop, state, tracking
    ├── SKILL.md            # Overview + core inline template
    └── references/
        ├── phase-2-core.md       # Round execution details
        ├── token-tracking.md
        ├── state-management.md
        └── ...
```

**Phases** (revised 2026-01-25):

| Phase | Description | Status | Depends on |
|-------|-------------|--------|------------|
| 0 | Test baseline | ✅ | - |
| 1 | Output extraction | ✅ | Phase 0 |
| 5 | Skill cleanup | ✅ | Phase 0 |
| 6 | Critical guidelines propagation | ✅ | - |
| 2 | Validation consolidation | ✅ | Phase 6 |
| 3 | Phase 2 uniformization (approach A — drift elimination + canonical reference) | ✅ | Phase 2 |
| 7B | Phase 2 deep extraction (approach B — was originally part of Phase 3 scope) | ✅ | Phase 3 |
| 7-lite | Strategy doc hardening (rename 2.6d→2.10, SKILL.md dedup, §Strategy hooks formalization, disney cross-link) | ✅ (PR #15 merged 2026-05-18) | Phase 7B |
| 4 | roundtable.md as master for **all 4 workflows** (specs/design/brainstorm/roundtable) + `profiles/roundtable.yaml` + Option B wiring (3-branch dispatch) + D3 hierarchy | ✅ implementation+regression complete (PR pending; §4.5 8-run dogfood all PASS 2026-05-21) | Phase 7-lite |
| 8 | Thin launcher conversion (specs/design/brainstorm → ~150 lines each) + master PHASE 0+1 generalization | ✅ implementation+regression complete (PR pending; §8.5 5-run dogfood all PASS 2026-05-26) | Phase 4 |

**Phase 0: Test baseline** ✅
- [x] Create `skills/dev-testing/references/roundtable-tests.md` with test cases
- [x] Document acceptance criteria for specs, design, brainstorm, roundtable
- [x] Run baseline tests and document current behavior

**Phase 1: Output extraction** ✅ (~370 lines saved)
- [x] Create unified `skills/output-generation/` with SKILL.md + references/
- [x] Reference files: specs-srs.md, design-arc42.md, brainstorm.md
- [x] Modify commands to `Read` skill instead of inline
- [ ] Test output identical to current

**Phase 5: Skill cleanup** ✅
- [x] Slim SKILL.md to overview + references (2492 → 1912 words)
- [x] Move verbose content to references/

**Phase 6: Critical guidelines propagation** ✅ (completed 2026-01-25)

Applied token tracking always-active, state.json, and checkpoint reminders to all commands.

- [x] Add token tracking activation to specs.md Step 2.1
- [x] Add token tracking activation to design.md Step 2.1
- [x] Add token tracking activation to brainstorm.md Step 2.1
- [x] Add token tracking reminders to roundtable.md CRITICAL REMINDERS section
- [x] Add state.json updates to specs.md, design.md, brainstorm.md Step 2.1 and Step 3.1
- [x] Add state.json reminders to roundtable.md
- [x] Add checkpoint reminders (T1, T2, T3) to all 4 commands
- [x] Add state.json fast-path read in auto-detect (all 4 commands) - hybrid approach per TECH-007

**Phase 6b: Token tracking edge cases** ✅ (completed 2026-01-28)

Handle /clear, /compact, and context capacity limits.

- [x] Create `templates/hooks/context-reset.sh` (v2.1.0) - SessionStart hook
  - Updates state.json with last_activity (context_clear/context_compact)
  - Shows resume command if roundtable was interrupted
  - Graceful degradation: works without jq (uses grep/sed fallback)
  - Shows jq installation warning if not available
- [x] Update `templates/statusline/settings.json` with hooks config
- [x] Update `commands/init.md` to copy hook during initialization
- [x] Add Step 2.0 Context Capacity Check to SKILL.md (threshold 95%)
- [x] Update token-tracking.md with capacity check documentation
- [x] Propagate Step 2.0 to specs.md, design.md, brainstorm.md (2026-01-28)
- [x] Test hook with real /compact event (hook fires, state.json updated)
- [x] Fix token tracking display issues (script v5.3.0, 2026-01-28):
  - Add CURRENT_PCT alias (was CONTEXT_PCT mismatch)
  - Add AVG_ACTUAL_K and SAMPLE_COUNT to recap output
  - Make T1/T2/T3 captures MANDATORY with inline bash commands
  - Strengthen Step 2.0c with WARNING for actual update
- [x] Add automatic continuation rules to SKILL.md and commands (2026-01-28):
  - Explicit STOP CONDITIONS table (context, max_rounds, escalate, interactive)
  - DO NOT STOP list for common cases (min_rounds reached, topic partial, etc.)
  - Prevents LLM from stopping mid-session to ask confirmation

**Phase 2: Validation consolidation** ✅ (~88 lines simplified, 2026-01-28)

Consolidated per-round validation into shared reference file.

- [x] Create `references/round-validation.md` with standardized checks
- [x] Update specs.md, design.md, brainstorm.md to reference shared file
- [x] Add Step 2.6b to SKILL.md
- [ ] Test: same warnings produced

**Note**: Did NOT use session-qa agent (too heavy for per-round). Created lightweight reference instead.

**Phase 3: Phase 2 uniformization** ✅ (approach A, completed 2026-05-05)

Plan: `.s2s/plans/20260505-tech002-phase3-uniformization.md`

- [x] Map ALL differences between commands in Phase 2 execution
- [x] Classify: necessary (workflow-specific) vs accidental (drift)
- [x] Eliminate accidental divergences (6 textual fixes across 3 commands)
- [x] Document necessary differences in canonical reference (workflow profiles table)
- [x] Create `skills/roundtable-execution/references/phase-2-core.md` as descriptive single-source-of-truth (target spec for future Phase 7B deep extraction)

**Drift fixes applied**:
1. `design.md` Step 2.4 verification → canonical `expected_artifacts:[{map, expected_keys}]` schema (was `session_file_updates.artifacts_embedded:[{field, expected_ids}]`); added `round_summary` and `metrics_consistency` blocks
2. `design.md` Step 2.4 result → added `conflicts_resolved: {count}`
3. `brainstorm.md` Step 2.4 result → added `conflicts_resolved: {count}`
4. `brainstorm.md` Step 2.3 verbose dump → added `rationale`/`concerns`/`suggestions` (returned by participants but uncaptured)
5. `specs.md` Step 2.3 dump header → `{Role}` (was `{Participant Role}`)
6. `specs.md` Step 2.9 → full canonical block: replaced hardcoded `< 3` with `min_rounds (from config)` and added user-visible warning. Default config `min_rounds=3`, behavior preserved; if user has overridden, specs now respects it.

**Deferred to Phase 7B (deep extraction)**: turning the 3 inline Phase 2 sections into thin launchers that invoke a single executable algorithm. Approach A keeps inline behavior unchanged, eliminating only drift, so the exp42 baseline regression check remains comparable.

**Out-of-scope drifts found during mapping** (tracked separately):
- `session-schema.md:567` lists design artifact types as `ARCH-*, COMP-*, CONF-*, OQ-*` (no `INT-*`); design.md uses `INT-*`. Schema doc incomplete.
- `session-schema.md:568` does not list `CONF-*` for brainstorm; brainstorm.md creates conflicts. Same shape.

**Phase 7: Strategy skill consolidation** (NEW)

Make commands actually USE roundtable-strategies instead of duplicating.

- [ ] Verify roundtable-strategies/SKILL.md has complete workflow defaults
- [ ] Move Disney phase logic from brainstorm.md to disney.md (if missing)
- [ ] Update specs.md to read strategy config from skill
- [ ] Update design.md to read strategy config from skill
- [ ] Update brainstorm.md to read strategy config from skill
- [ ] Remove duplicated workflow defaults from commands
- [ ] Test: strategy-specific behavior works correctly

**Phase 4: roundtable.md as master** ✅ (implementation + §4.5 regression complete; PR pending)
- [x] Add full Phase 2 execution to roundtable.md (Round Execution Loop in PHASE 3 section, dispatches through `phase-2-core.md`)
- [x] Support `--workflow-type specs|design|brainstorm|roundtable` via uniform dispatch + `profiles/roundtable.yaml` (Option ε pivot)
- [x] Verify all workflows produce correct output via roundtable.md (§4.5 Steps 2/6/7-implicit/8 PASS: master path produces structurally-equivalent output for specs/design/brainstorm)
- [x] Add resume/validation/diagnostic (Phase 0 resume check extended to all 4 workflow_types)
- [x] roundtable.md = 479 lines (master, under 520 budget)
- **Bonus deliverables (Option B + D3 + Option ε)**:
  - `profiles/roundtable.yaml` created (per plugin runtime spec, artifact_types `[DEC, OQ, CONF]`)
  - Strategy-hook 3-branch dispatch (`{skip}`, policy dict, absent for pre-Phase-4 sessions)
  - D3 hierarchy codified (`config.yaml` → `profiles/*.yaml` → SKILL.md docs)
  - `output-generation/references/roundtable-summary.md` created (Phase 3 dispatch for roundtable native)
  - SKILL.md L178 commitment honored
  - CI anchor drift check script at `skills/dev-testing/references/strategy-hook-anchor-check.md`

**Phase 8: Thin launcher conversion + master generalization** ✅ (implementation + §8.5 regression complete; PR pending)
- [x] Generalize roundtable.md master PHASE 0+1 as profile-driven (folder + 3 snapshots + profile-driven skeleton + 5 workflow_type literals parametrized + `## Invocation modes` contract). 479 → 592 lines.
- [x] Convert specs.md to thin launcher (600 → 172 lines, ≤180). Smart Source Detection kept inline.
- [x] Convert design.md to thin launcher (536 → 114 lines, ≤150).
- [x] Convert brainstorm.md to thin launcher (482 → 78 lines, ≤130).
- [x] §8.5 regression: 5/5 PASS in `ElfGiftRush_s2s/exp53..exp57` (specs/design/brainstorm direct + roundtable native + specs `--skip-roundtable`). All Phase 8 invariants verified empirically.
- **Bonus deliverables**:
  - Pattern 1 handoff codified (thin launcher Read-and-follows the master)
  - PHASE 4 Step 4.3 wires `OUTPUT_MERGE_MODE` / `OUTPUT_FORMAT` / `FOCUS_AREA` handoff vars
  - Phase 4 §8 finding #4 (session_id divergence) auto-resolved (no direct path remains)

**Line count: actual results (post Phase 8, 2026-05-26)**:
| File | Pre-Phase-4 | Post-Phase-4 | **Post-Phase-8 (actual)** |
|------|-------------|--------------|---------------------------|
| specs.md | 1717 | 600 | **172** |
| design.md | 1607 | 536 | **114** |
| brainstorm.md | 1575 | 482 | **78** |
| roundtable.md | 402 | 479 | **592** (master) |
| **Total** | **5301** | **2097** | **956** (beats ~1050 target) |

**Acceptance criteria** (final):
- [x] All 4 commands have token tracking and state.json (Phase 6)
- [x] roundtable.md can execute all workflows (Phase 4: §4.5 8-run dogfood validates all 4 workflow_types via both direct and master paths)
- [x] specs/design/brainstorm are thin launchers (Phase 8: 172 / 114 / 78 lines, all within budget)
- [x] Skills actually used, not just declared (Phase 4 + 8: master dispatches through `phase-2-core.md`, `output-generation`, `roundtable-strategies`; profiles/*.yaml consumed at runtime for both PHASE 1 setup and PHASE 2 round loop)
- [x] No behavioral regression for the 4 workflow types (Phase 4 §4.5 + Phase 8 §8.5: 0 wiring regressions)
- [x] Total command lines reduced from ~5000 to ~1050 (Phase 8 actual: 956)

**Current state** (2026-05-18, post PR #15 merge, Phase 4 plan draft):
- Branch: `feature/TECH-002-phase4-roundtable-master` (forked from develop @ 3043c1a after Phase 7-lite PR #15 merge)
- Develop carries v0.4.0 with Phases 0, 1, 5, 6, 6b, 2, 3, **7B**, **7-lite** (PR #12 + PR #13 + PR #14 + **PR #15 merged 2026-05-18**)
- **Phase 7B complete and merged** (PR #14, all sub-phases 7B.0–7B.7 done):
  - `phase-2-core.md` rewritten as executable single-source (881 lines)
  - Commands shrunk: specs 1727→600, design 1607→536, brainstorm 1575→482 (~3300 lines removed)
  - 12 artifact-schemas/* files extracted; disney-phase-machine.md extracted; strategy-hooks.md contract documented
  - SKILL.md restructured 1002 → 178 lines (v2.7.0 → v3.0.0)
  - BUG-013 (session-observer Step 2.6c skip) fixed via FIX-S1: dump persistence
  - ADR-0011 promoted `proposed` → `accepted` with Phase 7B addendum
  - Plan: `.s2s/plans/20260506-tech002-phase7b-deep-extraction.md`
  - Final regression replay (7B.7) verified all 3 workflows — see `.s2s/test-baselines/exp44-{specs,design,brainstorm}-post-phase7b.md`
- **Phase 7-lite complete and merged** (PR #15, merged 2026-05-18 as 3043c1a):
  - Plan: `.s2s/plans/20260517-tech002-phase7-strategy-consolidation.md` (revised 2026-05-18 from "full" to "lite" after macro review #4)
  - 7.0 audit: `.s2s/plans/20260518-tech002-phase7-lite-7.0-audit.md` (3 passes, definitive site inventory)
  - 7.6 smoke: `.s2s/plans/20260518-tech002-phase7-lite-7.6-smoke.md` (4/4 PASS)
  - Deliverables: (1) 5 strategy reference docs with uniform `## Strategy hooks` sections [+73 lines doc]; (2) `roundtable-strategies/SKILL.md` v1.1.0 → v1.2.0 with "authoritative source: profiles/" disclaimers + drift D1/D2 fixes; (3) Step 2.6d renamed to Step 2.10 across 18 sites in 6 files (`phase-2-core.md` block relocated post-§2.9); (4) bidirectional cross-link `disney.md` ↔ `disney-phase-machine.md`; (5) `strategy-hooks.md` reframed with Option A/B/C decision matrix in §7 (Phase 4 target state); (6) ADR-0011 addendum.
  - 13 stale `Phase 7 → Phase 4` references resolved across 4 files; 18 stale `Step 2.6d → 2.10` resolved across 6 files.
- **Phase 4 in_progress** (plan drafted 2026-05-18, revised 4 times: reviews #2, #4 Option δ, then **Option ε pivot 2026-05-20** post smoke test):
  - Plan: `.s2s/plans/20260518-tech002-phase4-roundtable-master.md` (~550 lines post pivot)
  - 4.0 audit: `.s2s/plans/20260518-tech002-phase4-4.0-audit.md` (389 lines + Option ε pivot notes)
  - Smoke test baseline: `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md` (outcome (c) graceful captured 2026-05-20)
  - §3.1 contains explicit Option A/B/C decision matrix (8 criteria); recommendation = **Option B** (command-side parsing in roundtable.md, deterministic resolution via `strategy-hook-resolution.md` fixture).
  - §3.3 codifies **D3 triple-duplication hierarchy**: `config.yaml` user-canonical → `profiles/*.yaml` plugin fallback → `SKILL.md` documentation-only.
  - §3.5 documents **Option ε pivot** (post smoke test 2026-05-20): pre-Phase-4 `/s2s:roundtable` native graceful abort + SKILL.md L178 pre-existing Phase 4 commitment + plugin runtime spec for roundtable.yaml invalidated previous Approach 4 deferral. Phase 4 now creates `profiles/roundtable.yaml` (per plugin's authoritative spec: `artifact_types: [OQ, CONF]`, `progress.axis: agenda` single `main` topic, `participants.default` from config). Phase 9 ELIMINATED; generic-mode fully resolved in Phase 4.
  - 6 sub-phases (was 7-8 pre-pivot): 4.0 audit (✅ done) → 4.1 D3 codification + profiles/roundtable.yaml creation → 4.2 Option B 3-file impl + anchor drift check → 4.3 uniform dispatch (no conditional needed) → 4.4 drift fix → 4.5 regression replay (expanded master coverage + roundtable native) → 4.6 close-out. Estimated ~7.5h execution.
  - Option B implementation spans 3 files: roundtable.md parser + `phase-2-core.md` Step 2.2c 3-branch dispatch (skip/policy/absent) + facilitator agent consumer. Backward-compat preserved for pre-Phase-4 sessions via Branch 3 (LLM-emergent fallback).
  - Acceptance criteria #2 ("execute all workflows") and #4 ("Skills actually used") will be marked **FULLY DONE** after Phase 4 (all 4 workflow types covered including generic roundtable; specs/design/brainstorm inline until Phase 8 but routable via roundtable.md master path).
  - **Pre-existing commitment honored**: `roundtable-execution/SKILL.md:178` parenthetical "(Phase 4 will align it)" updated to "(aligned in Phase 4 PR #XX)" in §4.1 step 7.
- **Phase 8 (after Phase 4, ~2-3h)**: thin launcher conversion (specs/design/brainstorm → ~150 lines each).
- **Phase 9**: ELIMINATED by Option ε pivot. Generic-mode roundtable hardening resolved in Phase 4 via `profiles/roundtable.yaml` creation.
- **Six-hats wiring** (prerequisite-blocked): requires empirical baseline acquisition. Separate task; Option B parser in Phase 4 makes six-hats wiring a configuration change only.
- **Next action**: execute §4.1 (D3 hierarchy + profiles/roundtable.yaml creation), then §4.2 → §4.6, then open PR `feature/TECH-002-phase4-roundtable-master` → develop, milestone v0.4.0. Until Phase 4 + 8 done, do NOT release v0.4.0 → main.

**Current state** (2026-05-26, post Phase 8 §8.5 regression replay):
- All 6 acceptance criteria met. TECH-002 status = completed.
- Phase 8 §8.0-§8.4 implementation on branch `feature/TECH-002-phase8-thin-launchers`; §8.5 dogfood 5/5 PASS in `ElfGiftRush_s2s/exp53..exp57`; §8.6 close-out in this commit.
- Plan: `.s2s/plans/20260521-tech002-phase8-thin-launchers.md`. Audit: `.s2s/plans/20260521-tech002-phase8-8.0-audit.md`. ADR-0011 has Phase 8 addendum.
- **v0.4.0 is now ready for the `develop → main` release PR**. Phase 8 was the 6th and final item in milestone v0.4.0.

**Earlier state** (2026-05-21, post §4.5 regression replay):
- §4.1 → §4.5 all complete; §4.6 close-out in progress (BACKLOG ✓ [this update], ADR-0011 Phase 4 addendum pending, MEMORY.md pending, PR open pending).
- **§4.5 8-run dogfood verdict**: all PASS. 7 worktrees exercised (Step 7 implicit via Step 2):
  - exp45: `/s2s:roundtable` native (post-Phase-4 baseline captured at `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md`)
  - exp52: `/s2s:roundtable --workflow-type design` (master path, debate strategy, Branch 2 hook_overrides populated)
  - exp46/47/48: direct `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` (no regression vs exp44-post-phase7b baselines)
  - exp49/51: `/s2s:roundtable --workflow-type {specs, brainstorm}` (master path equivalence to direct path)
- **4 cumulative diagnostic findings** (all non-blocking, pre-existing, plan §8): agent-resume gap, R1 observer false-positive on empty artifact maps, token-tracker.sh exit 1 quirk, session_id timestamp format divergence between direct vs master paths.
- **Backward-compat resume probe deferred**: non-blocking; Branch 3 logic statically reviewed during §4.2 step 3 implementation. Tracked for post-Phase-4 hardening.
- **Phase 9 status**: ELIMINATED by Option ε pivot — confirmed by exp45 post-Phase-4 baseline (clean Phase 2 + Phase 3 execution, no abort).
- **Next action**: complete §4.6 (ADR + MEMORY + PR), then start Phase 8 planning. v0.4.0 → main release still gated on Phase 8.

---

### DEBT-002: Separate dev tools repository

**Status**: deferred | **Created**: 2026-01-19 | **Trigger**: v1.0 release

**Context**: Development tools in main repo risk accidental inclusion in release.

**Tasks**:
- [ ] Create spec2ship-devkit repository
- [ ] Migrate dev/ folders
- [ ] Configure CI/CD
- [ ] Update documentation

**Trigger conditions**:
- v1.0 release planned
- Release workflow stable
- At least 3 contributors using dev tools

---

### TECH-005: Token tracking auto-setup via per-project statusline

**Status**: completed | **Created**: 2026-01-24 | **Completed**: 2026-05-28 | **Priority**: high

**Re-triage (2026-05-28)**: Closed as completed. The implementation shipped with v0.4.0: `templates/statusline/{statusline.sh,settings.json}`, `templates/hooks/context-reset.sh`, and `commands/init.md` Phase 5.5b (statusline setup with chain-to-global) all exist in the repo. The two remaining unchecked boxes are not blockers: "test session isolation (requires restart)" is a manual verification, and "config toggle for token tracking" is tracked separately as TECH-008. FEAT-003 (`/s2s:config`), which depended on this, is now unblocked but stays out of v0.5.0 scope.

**Context**: Token tracking requires statusline configuration to save `context-window.json`. Previously this required manual user setup. Now using per-project statusline with chain to global.

**Approach** (validated 2026-01-24):
- Per-project `.claude/settings.json` with statusLine config
- Per-project `.claude/statusline.sh` that:
  1. Saves context_window.json (s2s requirement)
  2. Reads global statusline command from `~/.claude/settings.json` and chains to it if configured
  3. Falls back to minimal statusline with context % display

**Benefits**:
- No modification to global `~/.claude/` files
- Works automatically for all s2s projects
- Preserves user's existing statusline customizations
- Self-contained per project

**Token tracker v3.0.0** (2026-01-24):

Architecture changes:
- Session-specific context files: `$TMPDIR/s2s-context-window-{cc-session-id}.json`
- Project-local cache: `.s2s/sessions/{rt-session}.cache` instead of global
- CC session ID passed via `${CLAUDE_SESSION_ID}` substitution
- Compact detection (BUG-006 fix): negative gap reset to 0

Bug fixes from v2.3.0:
| Issue | Resolution |
|-------|------------|
| lastT3 not updated | Fixed in recap command |
| roundsDeltaAccum not incremented | Fixed in recap command |
| contextSource unstable | Removed 60s check, now uses session-specific files |
| Stale data from other sessions | Session isolation via temp files |
| BUG-006 compact detection | Negative gap check added |

**Current state** (2026-01-24):
- [x] Prototype created in spec2ship project
- [x] Manual test passed (context-window.json updated, chain works)
- [x] Test with real Claude Code session (restart confirmed working)
- [x] Integrate into `/s2s:init` (Phase 5.5b added)
- [x] Create statusline templates in `templates/statusline/`
- [x] Session isolation with CC session ID
- [x] Token tracker v3.0.0 with temp directory
- [ ] Test session isolation (requires restart)
- [x] Remove `--tokens` flag (token tracking now always active - v2.3.0)
- [ ] Create config toggle for token tracking (see TECH-008)

**Files created/updated**:
- `templates/statusline/statusline.sh` - v3.0.2 (visual bar, correct token calc, no cost)
- `templates/statusline/settings.json` - Settings template
- `skills/roundtable-execution/scripts/token-tracker.sh` - v3.1.0 (roundtable state file)
- `skills/roundtable-execution/references/token-tracking.md` - Updated with CC session ID + params
- `commands/init.md` - Phase 5.5b for statusline setup
- `.claude/statusline.sh` - Updated to v3.0.2

**Statusline v3.0.2 features** (2026-01-25):
- Visual token bar: `⛁ ⛁ ⛁ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶` (10 slots, 20k each)
- Correct token calculation from `context_window_size * used_percentage`
- Shows used/available: `62k (31%) ⛁⛁⛁⛶⛶⛶... 138k`
- Color coding: green < 60%, yellow 60-79%, red ≥ 80%
- Removed cost display (not relevant for subscription users)
- Roundtable state integration (reads `s2s-roundtable-{cc-session}.json`)
- Chain to global statusline if configured

**Token tracker v3.1.0 features** (2026-01-25):
- Writes `s2s-roundtable-{cc-session}.json` with RT state for statusline
- New init params: workflow_type, strategy, phase, participants_count
- Removes roundtable state on summary/cleanup

**Related**: TECH-004 (token tracker history), TECH-007 (unified state file)

**Note** (2026-01-25): Session isolation approach being revised. TECH-007 proposes using `.s2s/state.json` instead of `$TMPDIR` with cc-session-id. This simplifies implementation significantly.

---

### TECH-007: Unified project state file (.s2s/state.json)

**Status**: completed | **Created**: 2026-01-25 | **Completed**: 2026-01-25 | **Priority**: high | **Supersedes**: TECH-006

**Context**: TECH-006 explored using `$TMPDIR` with cc-session-id for session isolation. After analysis, a simpler approach emerged: write state files directly to `.s2s/` directory. This eliminates session ID complexity and enables intelligent resume suggestions.

**Goals**:
1. Provide immediate session state lookup (no grep scanning needed)
2. Enable resume suggestions for interrupted sessions
3. Simplify statusline roundtable info display
4. Centralize ephemeral state in project directory

**Proposed architecture**:

```
.s2s/
├── state.json              # Current s2s state (persistent, updated by commands)
├── context-window.json     # Written by statusline (~300ms, ephemeral)
└── sessions/
    └── {id}.yaml           # Complete session data (existing)
```

**state.json schema**:

```json
{
  "active_session": {
    "id": "20260125-specs-auth",
    "workflow_type": "specs",
    "strategy": "standard",
    "round": 2,
    "phase": "discussion",
    "participants_count": 3
  },
  "active_plan": "20260125-143022-user-auth",
  "last_activity": {
    "timestamp": "2026-01-25T11:18:30Z",
    "action": "round_completed",
    "session_id": "20260125-specs-auth"
  }
}
```

**Integration with existing resume logic**:

Current logic (specs.md, design.md, brainstorm.md):
```bash
# Scans all session files with grep
grep -l 'workflow_type: specs' .s2s/sessions/*.yaml | xargs grep -l 'status: active'
```

New logic (hybrid approach):
```markdown
1. **First**: Check `.s2s/state.json` for `active_session`
   - If present AND matching workflow_type → immediate resume suggestion
   - Fast path: no grep scanning needed

2. **Fallback**: If state.json missing/stale → grep scan (existing logic)
   - Handles edge cases (state.json deleted, multiple active sessions)
   - Backward compatible

3. **Consistency check**: If state.json says session X active but X.yaml says closed
   - state.json is stale → clear it and use grep result
```

**Resume suggestion on startup** (new feature):

When any s2s command runs:
```
⚠️  Interrupted session found: specs "User authentication" (round 2)
    Last activity: 2026-01-24 18:32

    [R] Resume session
    [C] Close and start new
    [I] Ignore (keep in background)
```

This triggers when:
- `state.json.active_session` exists
- Session YAML `status` is NOT "closed"
- User hasn't explicitly dismissed

**Inconsistency handling** (key design decision):

Inconsistency between state.json and session YAML is a **feature**, not a bug:
- Indicates interrupted session (crash, closed terminal)
- Enables resume suggestion
- On explicit close: both files updated atomically

**Comparison: TECH-006 ($TMPDIR) vs TECH-007 (.s2s/)**:

| Aspect | TECH-006 ($TMPDIR) | TECH-007 (.s2s/) |
|--------|-------------------|------------------|
| Session isolation | cc-session-id in filename | Not needed (one state per project) |
| Resume detection | No | Yes (state.json persists) |
| Multi-session same project | Supported | Limitation (documented) |
| File discovery | Complex (auto-discover) | Simple (fixed path) |
| Cleanup | OS temp cleanup | Explicit (session close) |
| Statusline integration | Needs cc-session-id | Direct read |

**Known limitation**:

Multiple Claude Code sessions on same project will interfere (last writer wins).
This is an acceptable trade-off because:
- Uncommon use case
- Documented behavior
- Alternative ($TMPDIR) adds significant complexity

**Impact on existing code**:

1. **statusline.sh**: Write to `.s2s/context-window.json` (simple)
2. **token-tracker.sh**: Read from `.s2s/context-window.json`, write to `.s2s/state.json` (replaces roundtable-state.json)
3. **Commands (specs, design, brainstorm, roundtable)**: Update `.s2s/state.json` on session start/round/close
4. **Session commands**: `/s2s:session:close` clears `active_session` in state.json

**Tasks**:
- [x] Update statusline.sh to write `.s2s/context-window.json` (v3.1.0)
- [x] Update token-tracker.sh to read from `.s2s/context-window.json` (v4.1.0)
- [x] Move state.json update logic to SKILL.md inline (Opzione B - best practice)
- [x] Document "Core Inline + Reference Extensions" pattern in s2s-development.md
- [x] Add INST-011 check for core inline vs reference pattern
- [x] Update session close to clear state.json (inline in SKILL.md Step 3.1)
- [x] Add `.s2s/context-window.json` and `.s2s/state.json` to .gitignore (already covered by `.s2s/*`)
- [x] Update token-tracking.md documentation
- [x] Test: statusline writes context-window.json correctly
- [x] Test: token-tracker reads from statusline
- [x] Add state.json check to command auto-detect sections (TECH-002 Phase 6)
- [ ] Implement resume suggestion on s2s command startup (future enhancement)
- [ ] Test: statusline shows RT info (requires Claude restart)
- [ ] Test: resume suggestion works after interrupt

**Acceptance criteria**:
- [ ] Statusline displays roundtable info from state.json
- [x] Resume suggestion shown for interrupted sessions (TECH-002 Phase 6)
- [ ] Session close clears state.json.active_session
- [ ] Fallback to grep scan works when state.json missing
- [ ] .gitignore includes ephemeral state files

**Files to modify**:
- `templates/statusline/statusline.sh`
- `skills/roundtable-execution/scripts/token-tracker.sh`
- `skills/roundtable-execution/SKILL.md` (state.json updates)
- `commands/specs.md`, `design.md`, `brainstorm.md`, `roundtable.md` (auto-detect)
- `commands/session/close.md` (state.json cleanup)
- `templates/project/.gitignore`

---

### TECH-006: Token tracker cc-session-id resolution (SUPERSEDED)

**Status**: superseded | **Created**: 2026-01-25 | **Superseded by**: TECH-007

**Original problem**: `${CLAUDE_SESSION_ID}` is empty when passed to bash commands.

**Resolution**: TECH-007 eliminates the need for cc-session-id by using project-local `.s2s/` files instead of `$TMPDIR` with session-specific filenames.

**Archive** (original analysis):

The approach of using `$TMPDIR/s2s-context-window-{cc-session}.json` was explored but found to have issues:
1. `${CLAUDE_SESSION_ID}` not substituted in bash command context
2. Auto-discovery with 60-second freshness check is fragile
3. Project matching via transcript_path adds complexity
4. Files persist in temp dir, requiring cleanup logic

TECH-007's `.s2s/` approach is simpler:
- No session ID needed (one state per project)
- Fixed paths (`.s2s/context-window.json`, `.s2s/state.json`)
- Project-local by definition
- Cleanup is explicit (session close)

---

### TECH-003: Centralize artifact schemas in session-schema.md

**Status**: completed | **Created**: 2026-01-21 | **Priority**: low | **Origin**: TECH-002 review | **Completed**: 2026-06-13 (by different means: TECH-002 delivered the goal in v0.4.0)

**Context**: During TECH-002 format consolidation review, found that `session-schema.md` only contains schemas for specs workflow artifacts (REQ-*, BR-*, NFR-*, EX-*, CONF-*, OQ-*). Schemas for design (ARCH-*, COMP-*) and brainstorm (IDEA-*, RISK-*, MIT-*) were defined inline in their respective commands.

**Resolution (2026-06-13 backlog audit)**: the maintainability goal was achieved by TECH-002, just not in the file this ticket proposed. The 12 artifact schemas live centralized in `skills/roundtable-execution/references/artifact-schemas/*.md` (not `session-schema.md`); `design.md` and `brainstorm.md` are thin launchers with zero inline schema definitions, referencing the central schemas via `phase-2-core.md`. Residual (not filed, note only): the specs schemas still sit inline in `session-schema.md`; moving them into `artifact-schemas/` for full uniformity is possible but not needed.

**Acceptance criteria**:
- [x] All per-type artifact schemas in a single reference home (`artifact-schemas/`)
- [x] Commands reference schemas instead of defining inline

---

## Completed

| ID | Description | Completed |
|----|-------------|-----------|
| TECH-009 | Round token tracking with progressive precision (T1/T2/T3 capture) | 2026-01-26 |
| TECH-007 | Unified project state file (.s2s/state.json) - supersedes TECH-006 | 2026-01-25 |
| TECH-004 | Token tracker v2.3.0 - session isolation + statusline + 60s fix | 2026-01-24 |
| BUG-006 | Token tracker compact detection missing | 2026-01-24 |
| BUG-003 | SKILL.md uses context_files instead of inline participant_context | 2026-01-21 |
| FLOW-001 | Ideas and artifact traceability | 2026-01-19 |
| TEST-002 | Progressive disclosure for diagnostic | 2026-01-18 |
| WORK-002 | Roundtable scope awareness | 2026-01-17 |
| WORK-001 | Workspace core structure | 2026-01-17 |
| TEMPL-002 | Workspace template cleanup | 2026-01-17 |
| TEMPL-001 | Template usage model decision | 2026-01-17 |
| EXT-003 | s2s-guide skill | 2026-01-17 |
| INIT-003 | Init template copy refactor | 2026-01-17 |
| PLAN-002 | Plan template alignment | 2026-01-17 |
| DEBT-001 | Config hardcoding removal | 2026-01-16 |
| BACK-001 | Backlog file in init | 2026-01-16 |
| PATH-001 | Consolidate output to .s2s | 2026-01-15 |
| ARCH-001 | Session management simplification | 2026-01-15 |
| OSS-001 | OSS compliance | 2026-01-14 |

---

## Notes

- Ideas and proposals: See `ideas.md`
- Requirements: See `requirements.md`
- Architecture: See `architecture.md`
- Decisions: See `decisions/`
