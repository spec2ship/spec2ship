# Spec2Ship Backlog

**Updated**: 2026-01-26 (TECH-009 round token tracking)
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

**Status**: planned | **Created**: 2026-01-20 | **Priority**: medium

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

**Fix**: Change threshold from 0.67 to 0.6 for consistency with skill references.

**Tasks**:
- [ ] Update `templates/project/config.yaml` threshold values to 0.6
- [ ] Update `.s2s/config.yaml` threshold values to 0.6
- [ ] Update comment from "2/3 majority" to "60% (ensures 2/3 passes)"

**Acceptance criteria**:
- [ ] All threshold values aligned to 0.6
- [ ] Exact 2/3 votes pass consensus check

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

**Status**: planned | **Created**: 2026-01-22 | **Priority**: medium

**Context**: Verbose dump files (`rounds/{NNN}-01-*.yaml`, `rounds/{NNN}-02-*.yaml`, `rounds/{NNN}-03-*.yaml`) are not written immediately after each phase. The command waits until the round completes before writing to disk.

**Root cause**: Instructions for verbose dump writes do NOT include "NOW" or "IMMEDIATELY":
- specs.md:619 - "IF verbose_flag == true: Write dump..." (no NOW)
- specs.md:871 - "IF verbose_flag == true: Write dump for each..." (no NOW)
- specs.md:1124 - "IF verbose_flag == true: Write dump..." (no NOW)

Compare with session file writes which use "YOU MUST use Edit tool **NOW**".

**Impact**:
- If execution interrupted mid-round, verbose dumps for completed phases may be lost
- No incremental visibility into round progress
- Resume cannot recover partial round data from disk

**Affected files**:
- `commands/specs.md` (~lines 619, 871, 1124)
- `commands/design.md` (equivalent lines)
- `commands/brainstorm.md` (equivalent lines)
- `skills/roundtable-execution/SKILL.md` (lines 342, 420, 520)

**Fix**: Add "YOU MUST use Write tool NOW" to verbose dump instructions for each phase.

**Tasks**:
- [ ] Update specs.md verbose write instructions with "NOW"
- [ ] Update design.md verbose write instructions with "NOW"
- [ ] Update brainstorm.md verbose write instructions with "NOW"
- [ ] Update roundtable-execution/SKILL.md verbose write instructions with "NOW"

**Acceptance criteria**:
- [ ] Verbose dumps written immediately after each phase (2.2, 2.3, 2.4)
- [ ] Partial round data recoverable if interrupted

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

**Status**: in_progress | **Created**: 2026-01-20 | **Updated**: 2026-01-25 | **Origin**: IDEA-008
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
| 2 | Validation consolidation | **NEXT** | Phase 6 |
| 3 | Phase 2 uniformization | planned | Phase 2 |
| 7 | Strategy skill consolidation | planned | Phase 3 |
| 4 | roundtable.md as master | planned | Phase 3, 7 |
| 8 | Thin launcher conversion | planned | Phase 4 |

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

**Phase 6b: Token tracking edge cases** ✅ (completed 2026-01-25)

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
- [ ] Propagate Step 2.0 to specs.md, design.md, brainstorm.md (defer to Phase 3)
- [x] Test hook with real /compact event (hook fires, state.json updated)

**Phase 2: Validation consolidation** (~120 lines simplified)
- [ ] Verify session-qa can perform Step 2.6b checks
- [ ] Modify commands to call `Task(session-qa)` for validation
- [ ] Remove inline validation from commands
- [ ] Test: same warnings produced

**Phase 3: Phase 2 uniformization**
- [ ] Map ALL differences between commands in Phase 2 execution
- [ ] Classify: necessary (workflow-specific) vs accidental (drift)
- [ ] Eliminate accidental divergences
- [ ] Parameterize necessary differences via workflow_type
- [ ] Create `roundtable-execution/references/phase-2-core.md` with unified logic

**Phase 7: Strategy skill consolidation** (NEW)

Make commands actually USE roundtable-strategies instead of duplicating.

- [ ] Verify roundtable-strategies/SKILL.md has complete workflow defaults
- [ ] Move Disney phase logic from brainstorm.md to disney.md (if missing)
- [ ] Update specs.md to read strategy config from skill
- [ ] Update design.md to read strategy config from skill
- [ ] Update brainstorm.md to read strategy config from skill
- [ ] Remove duplicated workflow defaults from commands
- [ ] Test: strategy-specific behavior works correctly

**Phase 4: roundtable.md as master** (revised)
- [ ] Add full Phase 2 execution to roundtable.md (currently "follow skill")
- [ ] Support `--workflow-type specs|design|brainstorm`
- [ ] Verify all workflows produce correct output via roundtable.md
- [ ] Add resume/validation/diagnostic (currently missing)
- [ ] roundtable.md becomes ~600 lines with full capability

**Phase 8: Thin launcher conversion** (NEW)
- [ ] Convert specs.md to thin launcher (~150 lines):
  - Validate environment
  - Check prerequisites (CONTEXT.md)
  - Set workflow defaults
  - Invoke roundtable.md execution
- [ ] Convert design.md to thin launcher
- [ ] Convert brainstorm.md to thin launcher
- [ ] Test: identical behavior via thin launchers
- [ ] Document pattern in s2s-development.md

**Line count targets**:
| File | Before Phase 6 | After Phase 6 (complete) | After Phase 8 |
|------|----------------|--------------------------|---------------|
| specs.md | 1631 | 1717 (+86) | ~150 |
| design.md | 1504 | 1590 (+86) | ~150 |
| brainstorm.md | 1485 | 1571 (+86) | ~150 |
| roundtable.md | 360 | 402 (+42) | ~600 (master) |
| **Total** | 4980 | 5280 (+300) | ~1050 |

**Acceptance criteria** (final):
- [x] All 4 commands have token tracking and state.json (Phase 6)
- [ ] roundtable.md can execute all workflows
- [ ] specs/design/brainstorm are thin launchers (~150 lines each)
- [ ] Skills actually used, not just declared
- [ ] No behavioral regression (all tests pass)
- [ ] Total command lines reduced from ~5000 to ~1050

**Current state** (2026-01-25):
- Branch: `feature/TECH-002-roundtable-unification`
- Token tracker v4.1.0, statusline v3.1.0
- Phase 6 complete: all 4 commands have token tracking, state.json write (Step 2.1/3.1), AND state.json read (auto-detect fast path)
- **Next action**: Phase 2 - validation consolidation

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

**Status**: in_progress | **Created**: 2026-01-24 | **Priority**: high

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
| TECH-004 | Token tracker v2.3.0 - session isolation + statusline + 60s fix | 2026-01-24 |
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
