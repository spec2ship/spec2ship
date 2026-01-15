# Session Management Simplification

## Status

accepted

## Context and Problem Statement

La gestione delle sessioni aveva complessità non necessaria: state.yaml come fonte di verità separata, stati multipli (active, paused, completed, failed, abandoned), comandi duplicati per le stesse operazioni. Come semplificare mantenendo funzionalità?

## Decision Drivers

- Semplicità UX: meno stati = meno confusione per l'utente
- Single source of truth: evitare desincronizzazione tra file
- Coerenza terminologica: stessi termini per concetti simili
- Uniformità comandi: stessa struttura per workflow simili

## Considered Options

- Mantenere struttura attuale (state.yaml + stati multipli)
- Eliminare state.yaml, semplificare stati
- Eliminare state.yaml, mantenere stati multipli

## Decision Outcome

Chosen option: "Eliminare state.yaml, semplificare stati", perché riduce complessità senza perdere funzionalità.

### Decisioni specifiche

**1. Eliminare state.yaml**
- Session file = unica fonte di verità
- Discovery sessioni via grep sui session file
- Performance accettabile per <20 sessioni tipiche

**2. Due soli stati: active | closed**
- Niente "paused" - semanticamente equivalente a "active"
- Niente "failed", "abandoned", "completed" separati - tutti "closed"
- `closed_at` timestamp opzionale per audit
- Il motivo della chiusura è deducibile dal contenuto

**3. Auto-detect all'avvio dei workflow commands**
- Tutti i comandi (specs, design, brainstorm, roundtable, plan) cercano sessioni active
- Lista sempre visibile, poi domanda singola
- Flag `--new` per forzare nuova sessione
- Flag `--session <id>` per riprendere specifica

**4. Comandi unificati**
- `roundtable:start` → `roundtable` (uniformato agli altri)
- `plan:create` + `plan:start` → `plan` (fuso con auto-detect)
- `plan:complete` → `plan:close` (terminologia uniforme)
- `roundtable:list`, `roundtable:resume` → eliminati (usare session:*)

**5. Terminologia: "close" ovunque**
- "close" è neutro (non implica successo come "complete")
- Funziona per sessioni e piani

**6. Collegamento tra sessioni**
- `linked_sessions` opzionale nel session file
- Prompt: "Vuoi associare a una sessione esistente?"
- Tutti i tipi possono linkare (non solo design→specs)

**7. Cartella sessioni unica**
- Tutte le sessioni in `.s2s/sessions/` (non più cartelle separate per tipo)
- Naming: `YYYYMMDD-HHMMSS-{type}-{topic}.yaml` (tipo nel nome per leggibilità)
- Filtering via grep su `workflow_type` nel contenuto, non sul nome file
- Coerente con centralizzazione comandi `session:*`

### Consequences

- Good, perché elimina rischio desincronizzazione state.yaml
- Good, perché UX più semplice (meno stati da capire)
- Good, perché comandi uniformi (stessa struttura ovunque)
- Good, perché terminologia coerente ("close" ovunque)
- Good, perché meno file di comando da mantenere
- Good, perché cartella unica semplifica comandi session:*
- Neutral, perché grep leggermente più lento di lookup state.yaml
- Neutral, perché il "motivo" della chiusura non è esplicito

## Pros and Cons of the Options

### Mantenere struttura attuale

- Good, perché nessun refactoring necessario
- Bad, perché state.yaml può desincronizzarsi
- Bad, perché stati multipli confondono
- Bad, perché terminologia inconsistente (complete vs close)

### Eliminare state.yaml, semplificare stati

- Good, perché single source of truth
- Good, perché meno complessità cognitiva
- Good, perché comandi uniformi
- Bad, perché richiede refactoring significativo

### Eliminare state.yaml, mantenere stati multipli

- Good, perché single source of truth
- Bad, perché mantiene complessità stati
- Bad, perché effort di migrazione senza beneficio completo

## More Information

### Struttura comandi finale

```
commands/
├── init.md
├── specs.md          # + auto-detect
├── design.md         # + auto-detect
├── brainstorm.md     # + auto-detect
├── roundtable.md     # era roundtable/start.md
├── plan.md           # fuso create + start + auto-detect
├── plan/
│   ├── close.md      # era complete.md
│   └── list.md
└── session/
    ├── list.md
    ├── status.md
    ├── close.md
    ├── cleanup.md
    └── validate.md
```

### Struttura sessioni

```
.s2s/
├── sessions/                              # Cartella unica per tutte le sessioni
│   ├── 20260111-143022-specs-tasktracker.yaml
│   ├── 20260111-150000-design-api.yaml
│   ├── 20260110-093000-brainstorm-ideas.yaml
│   └── 20260112-100000-roundtable-techstack.yaml
├── config.yaml
└── decisions/
```

**Da eliminare** (cartelle separate):
- `.s2s/specs/sessions/`
- `.s2s/design/sessions/`
- `.s2s/ideas/sessions/`

### Schema session file

```yaml
# .s2s/sessions/20260111-143022-specs-tasktracker.yaml
workflow_type: specs          # Usato per filtering via grep
status: active                # active | closed
topic: tasktracker
created_at: 2026-01-11T14:30:22Z
closed_at: null               # Opzionale, per audit
linked_sessions:
  brainstorm: ["20260110-093000-brainstorm-mvp"]
# ... resto del contenuto sessione
```

### Flusso auto-detect

```
/s2s:specs
  │
  └─ Grep in .s2s/sessions/*.yaml:
     - workflow_type: specs
     - status: active
         │
         ├─ 0 trovate → Crea nuova
         │
         └─ 1+ trovate → Mostra lista:
                "Sessioni specs attive:
                 1. 20260111-specs-tasktracker (round 3)
                 2. 20260110-specs-auth (round 1)
                 [n] Nuova sessione

                 Quale vuoi continuare?"
```

### Schema linked_sessions

```yaml
# In session design
linked_sessions:
  specs: "20260110-143022-specs-tasktracker"
  brainstorm: ["20260109-093000-brainstorm-ideas"]

# In session specs
linked_sessions:
  brainstorm: ["20260108-100000-brainstorm-v1"]
```

### Backlog reference

Questa decisione è tracciata come **ARCH-001** nel backlog.
Include e supera SESS-001 (Intelligent Auto-Resume).
