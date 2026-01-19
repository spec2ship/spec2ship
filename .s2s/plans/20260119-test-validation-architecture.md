# Test and Validation Architecture Proposal

**Created**: 2026-01-19
**Status**: draft - in discussion
**Related**: TEST-003, TEST-001, QUAL-001

---

## Obiettivo

Definire un'architettura chiara che separi:
1. **Validazione runtime** - per utenti finali, inclusa nel plugin
2. **Test di sviluppo** - per contributor, non inclusa nel plugin

---

## Analisi dello Stato Attuale

### Cosa già esiste nel plugin

```
agents/validation/
├── session-qa.md        # Valida sessioni (STR-*, STRAT-*, DIAG-*)
├── spec-validator.md    # Valida specs/arch/decisions
└── plan-validator.md    # Valida piani implementativi

commands/session/
└── validate.md          # Invoca session-qa agent
```

**Scopo**: Questi validatori sono per **utenti finali** - verificano che l'output prodotto da s2s sia corretto e consistente.

### Cosa già esiste nel progetto

```
.claude/
├── CLAUDE.md            # Context principale
└── s2s-development.md   # Patterns e lessons learned
```

**Scopo**: Guida per contributor, caricata automaticamente quando si lavora nel repo s2s.

---

## Tassonomia: Tre Livelli di Verifica

### Livello 1: Runtime Validation (Utente Finale)

**Scopo**: Verificare correttezza dell'output prodotto durante l'uso normale.

| Check | Descrizione | Quando | Dove |
|-------|-------------|--------|------|
| STR-* | Struttura session file | Durante/dopo sessione | `session-qa.md` |
| STRAT-* | Compliance strategia | Durante/dopo sessione | `session-qa.md` |
| DIAG-* | Verbose dumps | Con --diagnostic | `session-qa.md` |
| SPEC-* | Qualità requirements.md | Dopo /s2s:specs | `spec-validator.md` |
| PLAN-* | Qualità piano | Dopo /s2s:plan | `plan-validator.md` |

**Inclusione**: NEL PLUGIN (già presente)

**Invocazione**:
- `/s2s:session:validate` - manuale
- `--diagnostic` flag - automatico per-round

---

### Livello 2: Development Checks (Contributor)

**Scopo**: Verificare che command/agent/skill seguano guideline e patterns.

| Check | Descrizione | Quando | Target |
|-------|-------------|--------|--------|
| INST-001 | Imperative voice | Pre-commit/PR | Commands |
| INST-002 | Tool usage explicit ("YOU MUST") | Pre-commit/PR | Commands |
| INST-003 | No ambiguity in steps | Pre-commit/PR | Commands |
| INST-004 | Template/inline alignment | Pre-commit/PR | Commands |
| INST-005 | Config from config.yaml, no hardcoded | Pre-commit/PR | Commands |
| INST-006 | ADR compliance (state field, etc.) | Pre-commit/PR | Commands, Agents |
| CONS-001 | Session ID format consistency | Pre-commit/PR | Commands |
| CONS-002 | Snapshot file structure consistency | Pre-commit/PR | Commands |
| CONS-003 | Resume logic equivalence | Pre-commit/PR | Commands |
| CONS-004 | Verbose dump format consistency | Pre-commit/PR | Commands |
| CONS-005 | Error handling patterns | Pre-commit/PR | Commands |
| CONS-006 | Diagnostic mode consistency | Pre-commit/PR | Commands |

**Inclusione**: FUORI DAL PLUGIN

**Invocazione**:
- `/s2s:dev:check` - manuale durante sviluppo
- CI/pre-commit hook - automatico

---

### Livello 3: Integration Tests (QA/Release)

**Scopo**: Verificare funzionamento end-to-end con scenari reali.

| Test | Descrizione | Quando | Scenario |
|------|-------------|--------|----------|
| RES-001 | Resume after round 2 complete | QA/Release | Interrupt + resume |
| RES-002 | Resume during participant responses | QA/Release | Interrupt mid-round |
| RES-003 | Resume after synthesis, before artifacts | QA/Release | Interrupt mid-round |
| EDGE-001 | Empty session resume | QA/Release | Edge case |
| EDGE-002 | Max rounds reached | QA/Release | Limit hit |
| EDGE-003 | Partial participant failure | QA/Release | Error recovery |
| EDGE-004 | YAML special chars in artifacts | QA/Release | Content edge |

**Inclusione**: FUORI DAL PLUGIN

**Invocazione**:
- `/s2s:dev:test` - manuale durante QA
- CI con test environment - automatico su PR

---

## Opzioni di Collocazione per Livello 2 e 3

### Opzione A: Nel plugin, esclusi prima del release

```
spec2ship/
├── commands/dev/           # DA ESCLUDERE
│   ├── check.md
│   └── test.md
├── agents/dev/             # DA ESCLUDERE
│   └── instruction-analyzer.md
└── .github/
    └── release-exclude.txt # Lista file da escludere
```

**Pro**:
- Tutto nello stesso repo
- Facile da trovare e mantenere

**Contro**:
- RISCHIOSO: facile dimenticare di escludere
- Complica il processo di release
- Aumenta dimensione repo (anche se non nel plugin finale)

**Valutazione**: SCONSIGLIATO

---

### Opzione B: Repo fratello separato

```
github.com/spec2ship/
├── spec2ship/              # Plugin principale
└── spec2ship-dev/          # Tool di sviluppo
    ├── commands/
    │   ├── check.md
    │   └── test.md
    ├── agents/
    │   └── instruction-analyzer.md
    └── .claude-plugin/
        └── manifest.json   # Plugin separato
```

**Pro**:
- Separazione netta
- Nessun rischio di inclusione accidentale
- Può avere versioning indipendente

**Contro**:
- Overhead di gestione (2 repo, 2 install)
- Difficile mantenere sincronizzati
- Contributor devono installare entrambi

**Valutazione**: ACCETTABILE ma con overhead

---

### Opzione C: Nella cartella .claude del progetto

```
spec2ship/
├── .claude/
│   ├── CLAUDE.md
│   ├── s2s-development.md
│   ├── agents/             # NUOVO
│   │   ├── instruction-analyzer.md
│   │   └── resume-tester.md
│   └── commands/           # NUOVO (se supportato)
│       ├── dev-check.md
│       └── dev-test.md
└── [resto del plugin]
```

**Pro**:
- Disponibile SOLO quando si lavora nel repo s2s
- Non incluso nel plugin (`.claude/` è per il progetto, non per il plugin)
- Tutto in un unico repo
- Zero overhead per utenti finali

**Contro**:
- Da verificare: Claude Code supporta agent/command in `.claude/`?
- Naming potrebbe confliggere con plugin

**Valutazione**: IDEALE se tecnicamente fattibile

---

## Verifica Tecnica: .claude/ supporta agent e command?

### Agent locali

Dalla documentazione Claude Code e dal comportamento osservato:
- `.claude/agents/` **NON è un path standard** per agent
- Gli agent del plugin sono in `agents/` (senza `.claude/` prefix)
- Gli agent vengono caricati dal plugin installato, non dalla cartella corrente

**Conclusione**: Agent locali in `.claude/agents/` probabilmente NON funzionano.

### Command locali

- `.claude/commands/` **NON è un path standard**
- I command vengono caricati dal plugin installato

**Conclusione**: Command locali in `.claude/commands/` probabilmente NON funzionano.

### Workaround: Skill locale?

- Le skill sono reference documentation, non eseguibili
- Potrebbero essere incluse via CLAUDE.md con `@` reference
- Ma non sarebbero invocabili come command

**Conclusione**: Opzione C nella forma proposta NON è tecnicamente fattibile con l'architettura attuale di Claude Code.

---

## Proposta Finale: Opzione Ibrida B+

Data l'infeasibility di Opzione C, propongo:

### Struttura

```
github.com/spec2ship/
├── spec2ship/                    # Plugin principale (SHIPPED)
│   ├── agents/validation/        # Runtime validators (utente)
│   │   ├── session-qa.md
│   │   ├── spec-validator.md
│   │   └── plan-validator.md
│   ├── commands/session/
│   │   └── validate.md
│   └── [resto del plugin]
│
└── spec2ship-devkit/             # Development toolkit (NON SHIPPED)
    ├── .claude-plugin/
    │   └── manifest.json
    ├── agents/
    │   ├── instruction-analyzer.md
    │   ├── resume-tester.md
    │   └── consistency-checker.md
    ├── commands/
    │   ├── check.md              # /devkit:check
    │   └── test.md               # /devkit:test
    └── README.md
```

### Installazione per contributor

```bash
# Plugin principale (sempre)
/plugin marketplace add https://github.com/spec2ship/spec2ship.git#develop
/plugin install s2s@spec2ship

# Development toolkit (solo per contributor)
/plugin marketplace add https://github.com/spec2ship/spec2ship-devkit.git
/plugin install devkit@spec2ship-devkit
```

### Naming Convention

| Scope | Prefix | Example |
|-------|--------|---------|
| Runtime validation (utente) | `/s2s:session:validate` | Già esistente |
| Development checks | `/devkit:check` | Nuovo |
| Integration tests | `/devkit:test` | Nuovo |

### Organizzazione Check per Plugin

**spec2ship (runtime - utente finale)**:

| Agent | Check Categories | Invoked By |
|-------|-----------------|------------|
| `session-qa` | STR-*, STRAT-*, DIAG-* | `/s2s:session:validate` |
| `spec-validator` | SPEC-* | Automatico o manuale |
| `plan-validator` | PLAN-* | Automatico o manuale |

**spec2ship-devkit (development - contributor)**:

| Agent | Check Categories | Invoked By |
|-------|-----------------|------------|
| `instruction-analyzer` | INST-* | `/devkit:check --instructions` |
| `consistency-checker` | CONS-* | `/devkit:check --consistency` |
| `resume-tester` | RES-* | `/devkit:test --resume` |
| (orchestrator) | EDGE-* | `/devkit:test --scenarios` |

---

## Alternativa Semplificata: Tutto nel Plugin con Folder Esclusione

Se l'overhead di due repo è considerato eccessivo:

```
spec2ship/
├── agents/validation/          # Runtime (SHIPPED)
├── agents/dev/                 # Development (NOT SHIPPED)
├── commands/session/validate.md  # Runtime (SHIPPED)
├── commands/dev/               # Development (NOT SHIPPED)
│   ├── check.md
│   └── test.md
└── .github/
    └── release.yml             # Esclude agents/dev/ e commands/dev/
```

**Workflow di release**:

```yaml
# .github/release.yml
release:
  exclude:
    - agents/dev/**
    - commands/dev/**
    - .s2s/**
    - .claude/**
```

**Pro**:
- Un solo repo da gestire
- Contributor vedono tutto insieme

**Contro**:
- Richiede disciplina nel processo di release
- Plugin in develop branch ha più file di quello in main/release

---

## Raccomandazione

**Per ora**: Opzione ibrida "tutto nel plugin con esclusione"

1. Creare `agents/dev/` e `commands/dev/` nel repo principale
2. Configurare `.github/release.yml` per escluderli
3. Documentare chiaramente la separazione
4. Se l'overhead diventa problematico, migrare a repo separato (Opzione B+)

**Naming finale**:

| Comando | Scopo | Collocazione |
|---------|-------|--------------|
| `/s2s:session:validate` | Runtime validation | `commands/session/validate.md` (SHIPPED) |
| `/s2s:dev:check` | Development checks | `commands/dev/check.md` (NOT SHIPPED) |
| `/s2s:dev:test` | Integration tests | `commands/dev/test.md` (NOT SHIPPED) |

Questo mantiene il namespace `/s2s:*` consistente e usa il prefix `:dev:` per identificare chiaramente i tool di sviluppo.

---

## Piano di Implementazione

### Fase 1: Struttura Base

1. [ ] Creare `commands/dev/` folder
2. [ ] Creare `agents/dev/` folder
3. [ ] Aggiungere esclusione in `.github/release.yml`
4. [ ] Documentare in `.claude/s2s-development.md`

### Fase 2: Development Checks (INST-*, CONS-*)

1. [ ] Creare `agents/dev/instruction-analyzer.md`
2. [ ] Creare `agents/dev/consistency-checker.md`
3. [ ] Creare `commands/dev/check.md`

### Fase 3: Integration Tests (RES-*, EDGE-*)

1. [ ] Creare `agents/dev/resume-tester.md`
2. [ ] Creare `commands/dev/test.md`
3. [ ] Definire test scenarios in `skills/dev-testing/`

### Fase 4: CI Integration

1. [ ] GitHub Action per `/devkit:check` su PR
2. [ ] GitHub Action per `/devkit:test` su PR to main

---

## Domande Aperte

1. **Release workflow**: Come escludere folder in modo affidabile?
   - GitHub Actions con rsync --exclude?
   - Branch separato per release?
   - Tag con .gitattributes export-ignore?

2. **CI con Claude Code**: È possibile eseguire Claude Code in CI?
   - Richiede API key
   - Potenzialmente costoso
   - Alternative: check script-based per INST-*/CONS-*?

3. **Naming conflict**: `/s2s:dev:*` potrebbe confondere utenti?
   - Alternativa: `/s2s:internal:*`?
   - Alternativa: repo separato con `/devkit:*`?

---

## Prossimi Passi

1. Discutere questa proposta
2. Decidere tra opzioni
3. Verificare fattibilità release workflow
4. Procedere con implementazione
