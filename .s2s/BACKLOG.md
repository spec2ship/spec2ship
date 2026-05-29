# Spec2Ship Backlog

**Updated**: 2026-05-26 (TECH-002 closed at Phase 8; v0.4.0 ready for develop -> main release)
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

**Status**: in_progress | **Created**: 2026-01-11 | **Updated**: 2026-01-20

**Context**: S2S development requires consistent adherence to patterns and ability to test resume/resilience. Development tools are in the plugin but excluded from release.

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
- [ ] Add release exclusion in .github/
- [ ] Implement RES-RT-* state checks in dev-validator (priority 2)

**Acceptance criteria**:
- [~] `/s2s:dev:check` runs INST-*, CONS-*, ENV-* checks (ENV-* done)
- [~] `/s2s:dev:test` runs RES-*, EDGE-*, VAL-RT-* tests (VAL-RT-* done)
- [ ] Tools NOT included in shipped plugin

---

### TEST-003: Session resilience verification

**Status**: in_progress | **Created**: 2026-01-18 | **Updated**: 2026-01-21 | **Linked to**: TECH-002 Phase 0, BUG-003

**Context**: Roundtable sessions can be interrupted at various points. Need verification that resume works correctly.

**Note**: This task is foundational for TECH-002. Test cases created here become the baseline for validating refactoring does not cause regression.

**Tasks**:
- [ ] Align roundtable.md resume logic with inline commands
- [ ] Add TRANS-* checks to session-qa (state transitions)
- [x] Define CTX-* checks in roundtable-tests.md (5 checks defined)
- [ ] Implement CTX-* in dev-validator (verbose dump analysis)
- [ ] Enhance error-handling.md with mid-write recovery
- [ ] Run manual end-to-end resume tests (partial: environment verified)
- [x] Create `skills/dev-testing/references/roundtable-tests.md` (for TECH-002)

**Acceptance criteria**:
- [ ] Resume works from all 7 critical interruption points
- [~] STR-*, TRANS-*, CTX-* checks in session-qa (CTX defined, implementation pending)
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

**Other commands to check**: specs.md, brainstorm.md, roundtable.md may have similar mid-round prompts that don't offer compact option.

**Tasks**:
- [ ] Review mid-round prompt logic in design.md
- [ ] Review mid-round prompt logic in specs.md
- [ ] Review mid-round prompt logic in brainstorm.md
- [ ] Review mid-round prompt logic in roundtable.md (SKILL.md)
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

**Possible solutions**:
- [ ] Detect if transcript exists before attempting resume (official method TBD)
- [ ] Clear agent_id on session load if Claude session is new
- [ ] Accept the error and continue with fresh agent (current behavior after error)

**Tasks**:
- [ ] Research official method to check transcript existence
- [ ] Implement pre-check before resume attempt
- [ ] Update session resume logic in workflow commands

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

**Related**: TEST-003 (context propagation checks)

---

### BUG-004: Verbose dumps not written incrementally during round

**Status**: planned | **Created**: 2026-01-22 | **Priority**: high

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

**Affected files**:
- `commands/specs.md` (lines 703, 957, 1212)
- `commands/design.md` (lines 595, 845, 1094)
- `commands/brainstorm.md` (lines 588, 841, 1082)
- `skills/roundtable-execution/SKILL.md` (lines 504, 587, 692)

**Fix**: Add "YOU MUST use Write tool NOW" to verbose dump instructions for each phase.

**Tasks**:
- [ ] Update specs.md verbose write instructions with "YOU MUST use Write tool NOW"
- [ ] Update design.md verbose write instructions with "YOU MUST use Write tool NOW"
- [ ] Update brainstorm.md verbose write instructions with "YOU MUST use Write tool NOW"
- [ ] Update roundtable-execution/SKILL.md verbose write instructions with "YOU MUST use Write tool NOW"

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

**Status**: in_progress | **Created**: 2026-05-14 | **Updated**: 2026-05-29 | **Priority**: medium | **Target**: v0.5.0 (verify-and-close) | **Related**: TECH-002 Phase 7B (baseline finding F2)

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

**Status**: planned | **Created**: 2026-02-02 | **Priority**: high

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

**Tasks**:
- [ ] Update SKILL.md Step 2.0a to always resolve TOKEN_SCRIPT
- [ ] Remove conditional "IF first round OR TOKEN_SCRIPT not set"
- [ ] Add comment explaining why unconditional (compact/clear resilience)
- [ ] Update token-tracking.md to match
- [ ] Test: verify token tracking works after compact + resume

**Acceptance criteria**:
- [ ] Token tracking active after `/compact` + resume
- [ ] Token tracking active after `/clear` + resume
- [ ] SHOULD_STOP correctly evaluated at every round
- [ ] No performance regression (Read is fast)

**Related**: BUG-006 (compact detection for gap), TECH-009 (progressive precision), Phase 6b (context reset hook)

---

### BUG-005: Participant verbose dumps missing full context

**Status**: planned | **Created**: 2026-01-22 | **Priority**: high

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

**Root cause** (confirmed 2026-01-22):
The command dump template at specs.md:884-886 uses ambiguous placeholder:
```yaml
input:
  question: "{the question}"
  context: {... context sent ...}   # <-- This placeholder is not expanded
```

The executor doesn't know what to put in `{... context sent ...}`.
Fix: Replace placeholder with explicit template matching verbose-dump-format.md.

**Impact**:
- CTX-* checks will fail (CTX-002, CTX-003)
- Cannot verify context propagation from dumps
- Resume from scratch cannot reconstruct what participants received

**Affected files** (to investigate):
- `commands/specs.md` (~line 871 participant dump section)
- `commands/design.md` (equivalent section)
- `commands/brainstorm.md` (equivalent section)

**Tasks**:
- [ ] Verify specs.md participant dump template includes full context
- [ ] Verify design.md participant dump template includes full context
- [ ] Verify brainstorm.md participant dump template includes full context
- [ ] Test with --verbose and verify dump content

**Acceptance criteria**:
- [ ] Participant dumps include full `input.context` block
- [ ] CTX-002 and CTX-003 checks pass on new sessions

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

**Status**: planned | **Created**: 2026-01-28 | **Priority**: medium

**Context**: `/s2s:init` creates the `.s2s/` directory with config, context, and session files, but never touches `.gitignore`. This means session files, `state.json`, verbose dumps, and other transient artifacts end up tracked (or shown as untracked noise) in git. The init command should append s2s-specific rules to `.gitignore`, whether git was already initialized or not.

**Proposed .gitignore block**:
```gitignore
# Spec2Ship - local state and sessions
.s2s/*

# Track project artifacts (specs, decisions, backlog, architecture)
!.s2s/BACKLOG.md
!.s2s/CONTEXT.md
!.s2s/README.md
!.s2s/config.yaml
!.s2s/workspace.yaml
!.s2s/requirements.md
!.s2s/architecture.md
!.s2s/ideas.md
!.s2s/decisions/
!.s2s/decisions/**
!.s2s/plans/
!.s2s/plans/**
# sessions/ intentionally NOT tracked - temporary working artifacts
```

**Tasks**:
- [ ] Add gitignore update step to `commands/init.md`
- [ ] If `.gitignore` exists, append the block (with a blank line separator); if not, create it
- [ ] Make the step idempotent (skip if s2s block already present)
- [ ] Handle `--workspace` mode (workspace.yaml is only relevant there)

**Acceptance criteria**:
- [ ] After `init`, `.gitignore` contains the s2s block
- [ ] Running `init` twice does not duplicate the block
- [ ] `git status` shows no s2s transient files (state.json, sessions/*, verbose dumps)
- [ ] Project artifacts (BACKLOG.md, CONTEXT.md, plans/, decisions/) remain trackable

---

### BUG-009: Facilitator concludes despite unmet criteria

**Status**: planned | **Created**: 2026-01-30 | **Priority**: high

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

**Tasks**:
- [ ] Add command-side conclude validation in SKILL.md Step 2.9
- [ ] Check critical topic closure before accepting conclude
- [ ] Check 50% non-critical closure before accepting conclude
- [ ] Log override reason when conclude is rejected
- [ ] Consider adding `validation_override` field to round record for audit

**Acceptance criteria**:
- [ ] Command rejects premature conclude when critical topics are not closed
- [ ] Command rejects premature conclude when <50% of other topics closed
- [ ] Override is logged in session file for debugging
- [ ] Facilitator instructions remain unchanged (defense in depth)

**Related**: BUG-010 (user confirmation), TECH-002 Phase 3

---

### BUG-010: No user confirmation when facilitator decides to conclude

**Status**: planned | **Created**: 2026-01-30 | **Priority**: medium

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

**Tasks**:
- [ ] Add Step 3.0: Generate Session Summary in SKILL.md
- [ ] Define summary format (decisions, coverage, open items, trade-offs)
- [ ] Add Step 3.1: Display summary + AskUserQuestion
- [ ] Update automatic continuation rules to exclude conclude from "no stop" conditions
- [ ] Modify Step 3.3 to use summary as context for output generation
- [ ] Update commands (specs, design, brainstorm) with new steps
- [ ] Move summary.md generation from current location to Step 3.0

**Acceptance criteria**:
- [ ] User sees session summary before confirming conclude
- [ ] Summary includes: approved artifacts, agenda coverage, open items
- [ ] User can choose to continue discussion instead of concluding
- [ ] Output generator uses summary as context (not full session re-read)
- [ ] Summary file written at Step 3.0 (before confirmation)
- [ ] Works in both interactive and non-interactive modes

**Related**: BUG-009 (facilitator criteria), BUG-011 (session file size), TECH-002 Phase 3

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

**Status**: planned | **Created**: 2026-05-28 | **Priority**: medium | **Origin**: TECH-002 Phase 4 diagnostic finding (plan §8); reproduced in exp54 | **Target**: v0.5.0

**Context**: During a master-delegated run (`/s2s:design` through the roundtable.md master), an agent resume produced the error `summary is required when message is a string`. The harness fallback completed the run, so it was non-blocking, but the resume path is not clean.

**Reproduced**: exp54 (`/s2s:design --diagnostic`, 2026-05-22). The run never actually interrupted; the error surfaced and execution continued via harness fallback.

**Note**: this is distinct from BUG-001 (agent resume fails across Claude restarts). BUG-014 is within a single session, on the delegated master path.

**Tasks**:
- [ ] Reproduce deterministically and capture the exact failing agent input
- [ ] Identify whether the missing `summary` is on facilitator or participant resume input
- [ ] Fix the resume input construction so no harness fallback is needed

**Acceptance criteria**:
- [ ] Master-delegated runs resume without the `summary is required` error
- [ ] No reliance on harness fallback for normal resume

---

### BUG-015: R1 observer false-positive on empty artifact maps

**Status**: planned | **Created**: 2026-05-28 | **Priority**: low | **Origin**: TECH-002 Phase 4 diagnostic finding (plan §8) | **Target**: v0.5.0

**Context**: On round 1, the session-observer (diagnostic mode) flags an anomaly when artifact maps are still empty, but an empty artifact map at R1 is expected (artifacts accrue from R1 synthesis onward). The false-positive adds noise to the diagnostic report.

**Tasks**:
- [ ] Suppress the empty-artifact-map anomaly on round 1 (or until first synthesis)
- [ ] Verify the observer still flags genuinely-stuck rounds later

**Acceptance criteria**:
- [ ] No empty-artifact-map anomaly reported at R1
- [ ] Genuine stalls (empty artifacts past R1) still flagged

---

### BUG-016: token-tracker.sh exits 1 and breaks && chains

**Status**: planned | **Created**: 2026-05-28 | **Priority**: low | **Origin**: TECH-002 Phase 4 diagnostic finding (plan §8) | **Target**: v0.5.0

**Context**: `token-tracker.sh` returns exit code 1 in a path that is not actually an error (observed during Phase 4 dogfood), which breaks `&&` command chains that invoke it. Callers must split the chain to avoid aborting subsequent steps.

**Tasks**:
- [ ] Locate the exit-1 path that is not a real failure
- [ ] Return 0 on the non-error path (reserve non-zero for genuine failures)
- [ ] Verify token tracking still surfaces real errors with a non-zero code

**Acceptance criteria**:
- [ ] `token-tracker.sh` returns 0 on success paths
- [ ] `&&` chains invoking it do not abort spuriously

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

### FEAT-006: Enhanced arc42 output with traceability

**Status**: planned | **Created**: 2026-02-03 | **Priority**: medium

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

### FEAT-007: Proactive documentation completeness

**Status**: planned | **Created**: 2026-02-03 | **Priority**: medium | **⚠️ NEEDS REVIEW**

> **Nota**: Questa proposta è in fase esplorativa. L'approccio descritto potrebbe non essere quello finale. Valutare alternative prima di implementare.

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

**Status**: planned | **Created**: 2026-01-16 | **Updated**: 2026-01-19

**Context**: The `/s2s:plan` command should read decisions/ to inform plan generation.

**Tasks**:
- [ ] plan.md reads .s2s/decisions/*.md
- [ ] ADRs influence task breakdown
- [ ] Reference relevant ADRs in plan output

**Acceptance criteria**:
- [ ] Plan considers decisions/ content
- [ ] Previous phases inform plan tasks

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

**Status**: planned | **Created**: 2026-01-21 | **Priority**: low | **Origin**: TECH-002 review

**Context**: During TECH-002 format consolidation review, found that `session-schema.md` only contains schemas for specs workflow artifacts (REQ-*, BR-*, NFR-*, EX-*, CONF-*, OQ-*). Schemas for design (ARCH-*, COMP-*) and brainstorm (IDEA-*, RISK-*, MIT-*) are defined inline in their respective commands.

**Current state**:
- specs artifacts: defined in `session-schema.md` ✓
- design artifacts: defined inline in `design.md`
- brainstorm artifacts: defined inline in `brainstorm.md`

**Tasks**:
- [ ] Add ARCH-* schema to session-schema.md
- [ ] Add COMP-* schema to session-schema.md
- [ ] Add IDEA-* schema to session-schema.md
- [ ] Add RISK-* schema to session-schema.md
- [ ] Add MIT-* schema to session-schema.md
- [ ] Update commands to reference centralized schemas

**Acceptance criteria**:
- [ ] All artifact schemas in single reference file
- [ ] Commands reference schemas instead of defining inline

**Note**: Low priority - current inline definitions work, centralization is for maintainability.

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
