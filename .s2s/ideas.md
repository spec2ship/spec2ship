# Spec2Ship Ideas

**Updated**: 2026-02-07
**Format**: Structured ideas from analysis and brainstorming

---

## ID conventions

| Prefix | Category | Example |
|--------|----------|---------|
| IDEA | Ideas and concepts | IDEA-001 |

**Status values**: `draft` | `validated` | `promoted` | `parked` | `rejected`

---

## Active

### IDEA-001: Custom agents in user projects

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Projects may want specialized agents (e.g., project-specific code reviewer) without modifying the plugin.

**Solution outline**:
- Roundtable commands scan `.claude/agents/` in project
- Project agents available alongside plugin agents (named `project:{agent-name}`)
- Agent creation command `/s2s:agent:create {name}`

**Next**: Consider for /s2s:specs when extension system is prioritized

---

### IDEA-002: Dynamic context-aware roundtables

**Status**: draft | **Created**: 2026-01-18
**Origin**: manual (post-roundtable analysis)

**Problem**: During roundtables, participants propose elaborate patterns without awareness of project-specific constraints. Example: proposing WAL/transaction patterns for a system that has no persistent state.

**Solution outline**:
1. Facilitator builds `execution_context` at session start by reading ADRs, requirements, architecture
2. Context includes: executor capabilities, limitations, established principles, guardrails
3. Participants receive context before formulating positions
4. Facilitator validates proposals against context in synthesis
5. Context evolves: new principles captured at session close

**Key insight**: Not s2s-specific - every project has execution constraints that should inform proposals.

**Complexity**: High - requires changes to facilitator, participants, session schema

**Next**: Validate with /s2s:specs roundtable on "execution context design"

---

### IDEA-003: Simulate mode for context efficiency

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Context window limits constrain roundtable depth. Spawning multiple agents uses significant tokens.

**Solution outline**:
- `--simulate` flag where command impersonates participants WITHOUT spawning agents
- Read participant .md files, generate responses inline as each role
- No Task() invocations
- Output marked as "SIMULATED"
- Target: 70%+ token reduction

**Risk**: Quality may be lower without true multi-agent deliberation

**Next**: Prototype and measure token savings vs quality trade-off

---

### IDEA-004: Phase tracking for multi-phase strategies

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Strategies like Disney and Six Hats have phases, but phase tracking is not explicit in session files.

**Solution outline**:
- Add `current_phase` field to session schema
- Phase transitions managed by facilitator
- Validation in session-observer
- `/compact` suggested at phase boundaries

**Phases by workflow**:
- Specs: Discovery → Definition → Refinement
- Design: Architecture → Components → Integration
- Brainstorm: Dreamer → Realist → Critic (already exists)

**Next**: Define phase schemas for specs and design

---

### IDEA-005: Optional session linking

**Status**: draft | **Created**: 2026-01-15
**Origin**: manual

**Problem**: Related sessions (specs → design → plan) are not formally linked.

**Solution outline**:
- `linked_sessions` field in session file
- Command to visualize session chain
- Context inheritance between linked sessions

**Next**: Low priority - manual linking works for now

---

### IDEA-006: Enhanced interactive mode

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Users want more intervention points during roundtables.

**Solution outline**:
- More frequent checkpoints in `--interactive`
- After facilitator question: "Provide input or continue?"
- User input passed to facilitator in next prompt

**Next**: Evaluate complexity vs benefit

---

### IDEA-007: Intelligent project assessment

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Commands don't assess project state before starting.

**Solution outline**:
- Analyze project state before workflow commands
- Detect: CONTEXT.md, requirements.md, architecture.md, decisions/, git status
- Suggest next step: "No requirements? Run /s2s:specs"

**Next**: Could be integrated into existing commands

---

### IDEA-009: Test framework with s2s:test

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: Testing s2s commands is manual and cumbersome.

**Solution outline**:
- `/s2s:test specs|design|roundtable` subcommands
- Creates test environment (temp dir, test CONTEXT.md, config)
- Automatically adds `--diagnostic --verbose`

**Next**: Define test scenarios and expected outcomes

---

### IDEA-010: Unified export command

**Status**: partially-addressed | **Created**: 2026-01-15 | **Updated**: 2026-01-21
**Origin**: manual
**Related**: TECH-002 Phase 1, ADR-0012

**Problem**: With PATH-001, all output goes to `.s2s/`. Need a way to export/publish to project `docs/` for public documentation.

**Solution outline**:
- Single `/s2s:export` command
- Flags: `--specs`, `--design`, `--decisions`
- Format conversion: `--format ieee830`, `--format arc42`
- First export asks for target path, stores in config

**Update (2026-01-21)**: Output format generation addressed by TECH-002 Phase 1:
- Created `skills/output-generation/` with SKILL.md + references/ (ADR-0012)
- Decision made: **transform at generation time** (not at export time)
- Formats are pseudo-code that LLM interprets during roundtable completion
- Current formats: specs-srs.md, design-arc42.md, brainstorm.md

**Remaining scope for /s2s:export**:
- Copy from `.s2s/` to `docs/` (or configured target)
- Optional: convert format at export time (e.g., SRS to IEEE 830)
- This is now a simpler "copy + optional reformat" command

**Next**: Evaluate if dedicated export command still needed, or if simple copy suffices

---

### IDEA-011: Validate default to full

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: `/s2s:session:validate` has different levels but default should run ALL checks.

**Solution outline**:
- Default runs all checks (structural + deep + strategy)
- Add `--skip` flags for excluding specific checks

**Next**: Low priority - current behavior is acceptable

---

### IDEA-012: Optional init structure

**Status**: draft | **Created**: 2026-01-11
**Origin**: manual

**Problem**: `/s2s:init` creates full structure. Users may want minimal setup.

**Solution outline**:
- `--minimal` flag creates only config.yaml and CONTEXT.md
- Interactive prompt when no flag provided
- Detect existing `.s2s/` structure

**Next**: Evaluate user demand

---

---

## Cluster: Collective roundtable intelligence

> **Theme**: Migliorare la qualita dei roundtable attingendo da sessioni precedenti (proprie e della community), feedback degli utenti, e knowledge pack per dominio. Queste idee formano una progressione dal livello locale a quello comunitario.
>
> **Problema osservato**: Nonostante round multipli di specs e design, e difficile ottenere una progettazione che tenga conto di tutto e sia allineata allo stato dell'arte. Ogni facilitator genera agende da zero, senza memoria di cosa ha funzionato in passato ne di come altri utenti hanno affrontato lo stesso dominio. Questo crea un tetto di qualita artificiale e ripetibile.

---

### IDEA-030: Roundtable feedback e quality scoring

**Status**: draft | **Created**: 2026-02-07
**Origin**: osservazione sperimentale su sessioni reali
**Cluster**: collective-roundtable-intelligence

**Problema**: Non esiste modo per l'utente di indicare quanto un roundtable sia stato utile, completo, o soddisfacente. Senza feedback, non c'e base per migliorare sessioni future ne per identificare pattern di successo.

**Soluzione proposta**:

1. **Feedback soggettivo** (post-sessione):
   - Al termine di un roundtable (o alla chiusura sessione), prompt con 2-3 domande rapide:
     - Completezza percepita (1-5)
     - Utilita per il progetto (1-5)
     - Commento libero opzionale
   - Salvato nel session file sotto `feedback:`

2. **Quality scoring automatico** (calcolato dal sistema):
   - Copertura agenda: % di topic chiusi vs totali
   - Profondita artefatti: media acceptance criteria per artefatto
   - Convergenza: round necessari per raggiungere consensus
   - Diversita posizioni: quanti partecipanti hanno posizioni distinte (non echo chamber)
   - Score composito salvato in `metrics.quality_score`

3. **Trend locale**:
   - `/s2s:session:list` mostra quality score accanto a ogni sessione
   - Comparazione tra sessioni sullo stesso workflow/topic

**Schema**:
```yaml
feedback:
  completeness: 4        # 1-5, user-provided
  usefulness: 5           # 1-5, user-provided
  comment: "Mancava copertura sui requisiti non funzionali"
  timestamp: "2026-02-07T10:30:00Z"

metrics:
  quality_score:
    agenda_coverage: 0.85     # closed_topics / total_topics
    artifact_depth: 3.2       # avg acceptance_criteria per artifact
    convergence_speed: 2.5    # avg rounds to consensus per topic
    position_diversity: 0.7   # distinct positions / participants
    composite: 0.78           # weighted aggregate
```

**Valore**: Base necessaria per tutte le altre idee del cluster. Senza metriche, non si puo decidere cosa condividere, cosa migliorare, o cosa funziona.

**Complessita**: Media - richiede modifiche a Phase 3 (completion) e session schema.

**Next**: Definire formula composite score. Integrare in BUG-010 (session summary checkpoint).

---

### IDEA-031: Cross-session learning (locale)

**Status**: draft | **Created**: 2026-02-07
**Origin**: estensione naturale di IDEA-030
**Cluster**: collective-roundtable-intelligence
**Depends on**: IDEA-030 (quality scoring)

**Problema**: Ogni roundtable parte da zero, anche quando l'utente ha gia fatto sessioni sullo stesso dominio o argomento simile. Le lezioni apprese si perdono.

**Soluzione proposta**:

1. **Session tagging**: Aggiungere tag di dominio alle sessioni (`domain: ["rag", "authentication", "api-design"]`), derivabili automaticamente dal topic o impostati dall'utente.

2. **Agenda seeding da sessioni passate**: Quando il facilitator genera l'agenda per una nuova sessione:
   - Cerca sessioni locali con tag di dominio simili
   - Se trovate (e con quality_score sufficiente), propone:
     - "Trovate 2 sessioni precedenti su argomenti simili. Usare le agende come base?"
   - Il facilitator riceve i topic delle sessioni precedenti come contesto aggiuntivo

3. **Question bank locale**: Accumula le domande piu rilevanti (quelle che hanno generato convergenza rapida o artefatti di alta qualita) in un index locale.

**Schema sessione** (aggiunta):
```yaml
metadata:
  domain_tags: ["rag", "vector-search", "embeddings"]
```

**File indice** (nuovo):
```
.s2s/knowledge/
├── question-bank.yaml      # Domande migliori per dominio
└── session-index.yaml       # Indice sessioni per domain tag
```

**Valore**: Miglioramento incrementale senza infrastruttura. Ogni progetto diventa piu "smart" nel tempo.

**Complessita**: Media - richiede session tagging, facilitator context injection, file di indice.

**Next**: Prototipare il tagging automatico dal session topic.

---

### IDEA-032: Domain knowledge packs

**Status**: draft | **Created**: 2026-02-07
**Origin**: generalizzazione di IDEA-031 per la distribuzione
**Cluster**: collective-roundtable-intelligence

**Problema**: Anche con learning locale, un utente che affronta un dominio per la prima volta non ha sessioni precedenti da cui attingere. Serve una base di partenza curata.

**Soluzione proposta**:

1. **Knowledge packs distribuiti col plugin** (o installabili separatamente):
   ```
   skills/knowledge-packs/
   ├── SKILL.md
   └── packs/
       ├── rag-system.yaml
       ├── authentication.yaml
       ├── api-design.yaml
       ├── microservices.yaml
       └── ...
   ```

2. **Contenuto di un pack**:
   ```yaml
   pack: "rag-system"
   version: "1.0"
   description: "RAG system design and implementation"

   agenda_template:
     critical_topics:
       - "Embedding strategy and model selection"
       - "Chunking strategy and document preprocessing"
       - "Vector store selection and indexing"
       - "Retrieval pipeline design (hybrid search, reranking)"
       - "Generation pipeline and prompt engineering"
       - "Evaluation framework (retrieval quality, answer quality)"
     recommended_topics:
       - "Scaling and performance"
       - "Security and access control"
       - "Monitoring and observability"
       - "Cost optimization"

   key_questions:
     - "What chunk sizes and overlap have worked best for similar content types?"
     - "How will you handle multi-modal content (tables, images, code)?"
     - "What is your strategy for keeping embeddings in sync with source data?"
     - "How will you measure retrieval quality beyond simple recall?"

   common_pitfalls:
     - "Choosing embedding model before understanding query patterns"
     - "Ignoring chunking strategy impact on retrieval quality"
     - "No evaluation framework from the start"

   recommended_participants:
     - "software-architect"
     - "technical-lead"
     - "qa-lead"
   ```

3. **Integrazione nel facilitator**:
   - Il facilitator legge il pack corrispondente al dominio (se esiste)
   - L'agenda generata integra i topic del pack con quelli derivati dal contesto del progetto
   - Le key_questions vengono usate come "seed" per i round
   - I pitfalls vengono inclusi nel contesto dei partecipanti

4. **Pack creation da sessioni reali**: Comando per estrarre un pack da una sessione con alto quality_score:
   `/s2s:session:export-pack --session {id}`

**Valore**: Colma il gap per chi affronta un dominio nuovo. Curato dal team s2s o dalla community.

**Complessita**: Media-alta - richiede schema pack, integrazione facilitator, distribuzione.

**Vincolo**: Compatibile con l'architettura attuale (puro YAML, nessuna dipendenza esterna).

**Next**: Creare 1-2 pack pilota basati su sessioni reali (RAG, authentication). Validare con utenti.

---

### IDEA-033: Community knowledge hub

**Status**: draft | **Created**: 2026-02-07
**Origin**: visione a lungo termine per apprendimento collettivo
**Cluster**: collective-roundtable-intelligence
**Depends on**: IDEA-030 (feedback), IDEA-032 (knowledge packs)

**Problema**: Anche con pack curati, la conoscenza resta statica. Utenti diversi che affrontano lo stesso dominio producono risultati di qualita variabile. Non c'e modo di far convergere questa conoscenza collettiva.

**Soluzione proposta (a lungo termine)**:

1. **Hub centralizzato** (GitHub repo, API, o servizio):
   - Repository di knowledge packs contribuiti dalla community
   - Session digests anonimizzati (senza IP del progetto)
   - Ranking per quality score aggregato e feedback utenti

2. **Flusso di contribuzione**:
   ```
   Utente completa roundtable
   → Feedback (IDEA-030)
   → quality_score > soglia
   → Prompt: "Vuoi condividere questa sessione nella community?"
   → Export digest anonimizzato (topic, agenda, questions, pitfalls)
   → Upload a hub (con consenso)
   ```

3. **Flusso di consumo**:
   ```
   Utente avvia roundtable su "RAG system"
   → Facilitator cerca pack locale (IDEA-032)
   → Se abilitato: cerca anche su hub
   → Presenta: "3 pack community disponibili (avg score 4.2/5)"
   → Utente sceglie quale usare come base
   → Download + merge con contesto locale
   ```

4. **Governance**:
   - Contributi anonimi o pseudonimi
   - Rating community (upvote/downvote su pack)
   - Curation da maintainer s2s per "featured packs"
   - Versioning dei pack (evoluzione nel tempo)

**Sfide critiche**:

| Sfida | Rischio | Mitigazione |
|-------|---------|-------------|
| Privacy/IP | Sessioni contengono dettagli del progetto | Digest anonimizzato, opt-in esplicito |
| Qualita | Pack di bassa qualita inquinano il sistema | Quality score minimo, moderation |
| Infrastruttura | Serve hosting, API, storage | GitHub repo come MVP, API dopo |
| Trust | Chi garantisce la qualita? | Rating + curation + transparency |
| Costo Claude | Query all'hub durante init | Cache locale dei pack scaricati |

**MVP realistico**: GitHub repository di pack YAML, scaricabili con `git clone` o singolo file fetch. Nessun API. Nessun database. Contribuzione via pull request.

**Complessita**: Alta - richiede infrastruttura, governance, privacy policy.

**Next**: Validare prima IDEA-030 e IDEA-032 (livelli locale e curato). L'hub ha senso solo se i pack funzionano e gli utenti li trovano utili.

---

### IDEA-034: Agenda refinement dal facilitator

**Status**: draft | **Created**: 2026-02-07
**Origin**: osservazione sulla qualita delle agende generate
**Cluster**: collective-roundtable-intelligence

**Problema**: Il facilitator genera l'agenda in un singolo passo (Phase 1), senza iterazione. L'agenda risultante potrebbe mancare topic critici o avere priorita sbagliate, specialmente su domini complessi.

**Soluzione proposta**:

1. **Agenda review step**: Dopo la generazione iniziale dell'agenda, il facilitator esegue un self-review:
   - Confronta con knowledge pack del dominio (se disponibile)
   - Verifica copertura di aspetti standard (NFR, security, scalability, testing)
   - Aggiunge topic mancanti con priorita "suggested"

2. **User agenda review** (se `--interactive`):
   - Mostra agenda proposta all'utente prima di iniziare i round
   - Utente puo aggiungere, rimuovere, riordinare topic
   - Riduce il rischio di roundtable "incompleti"

3. **Agenda enrichment da fonti esterne** (opzionale):
   - Se pack disponibile: merge automatico topic pack + topic generati
   - Se sessioni precedenti disponibili (IDEA-031): suggerisce topic che hanno generato valore in passato

**Integrazione**: Modifica a Phase 1 del roundtable, tra generazione agenda e inizio round.

**Valore**: Migliora la qualita dell'agenda senza dipendere da infrastruttura esterna. Funziona anche in isolamento.

**Complessita**: Bassa-media - modifica a un singolo step nel facilitator flow.

**Relazione con BUG-009**: Agende migliori riducono anche il rischio di conclude prematuro, perche i topic critici sono identificati fin dall'inizio.

**Next**: Prototipare l'agenda review step con checklist NFR/security/testing.

---

### IDEA-035: Analytics e trend sui topic discussi

**Status**: draft | **Created**: 2026-02-07
**Origin**: richiesta utente su identificazione argomenti piu discussi
**Cluster**: collective-roundtable-intelligence
**Depends on**: IDEA-030 (feedback/scoring)

**Problema**: Non c'e visibilita su quali argomenti generano piu valore, quali sono controversi, su quali la convergenza e rapida o lenta.

**Soluzione proposta**:

1. **Analisi locale** (`/s2s:session:analytics`):
   - Topic piu ricorrenti tra sessioni
   - Topic con convergenza rapida vs lenta
   - Correlazione tra participant mix e quality score
   - Strategie piu efficaci per tipo di workflow

2. **Output esempio**:
   ```
   Topic analytics (12 sessions)
   ───────────────────────────────
   Most discussed:     "API design" (5 sessions, avg score 4.1)
   Fastest consensus:  "Authentication" (avg 1.5 rounds)
   Most debated:       "Database choice" (avg 4.2 rounds)
   Best strategy:      "debate" for design, "disney" for brainstorm
   Top participants:   architect + tech-lead → highest scores
   ```

3. **A livello community** (se IDEA-033 implementata):
   - Aggregazione anonima di trend
   - "Trending topics" nella community
   - Best practice emergenti per dominio

**Complessita**: Bassa (locale), alta (community).

**Next**: Implementare versione locale dopo IDEA-030.

---

### IDEA-036: Session digest esportabile

**Status**: draft | **Created**: 2026-02-07
**Origin**: meccanismo di trasporto per la condivisione
**Cluster**: collective-roundtable-intelligence

**Problema**: Per condividere sessioni (localmente o con la community) serve un formato anonimizzato che contenga il valore senza esporre dettagli del progetto.

**Soluzione proposta**:

1. **Comando export**: `/s2s:session:export-digest --session {id}`
2. **Contenuto digest**:
   ```yaml
   digest:
     version: "1.0"
     domain_tags: ["rag", "vector-search"]
     workflow: "design"
     strategy: "standard"
     rounds: 5
     quality_score: 0.82

     agenda:
       topics: ["Embedding strategy", "Chunking", "Vector store", ...]
       coverage: 0.90

     key_questions:      # Le domande che hanno generato piu valore
       - "How will embeddings stay in sync with source changes?"
       - "What is the reranking strategy?"

     insights:           # Pattern emersi dalla discussione
       - "Hybrid search (dense + sparse) preferred over pure vector"
       - "Chunk overlap of 10-20% recommended for narrative content"

     common_pitfalls:    # Dall'esperienza della sessione
       - "Choosing embedding model before profiling query patterns"

     # NOT included: project name, company, specific implementation details
   ```

3. **Import**: `/s2s:session:import-digest {file.yaml}` - aggiunge al knowledge locale

**Valore**: Meccanismo di trasporto leggero che funziona con o senza hub centralizzato. Gli utenti possono scambiarsi digest via email, Slack, GitHub gist.

**Complessita**: Media - richiede logica di anonimizzazione e selezione dei contenuti.

**Next**: Definire cosa includere/escludere nel digest per garantire privacy.

---

## Parked

### IDEA-020: Ready-to-use roundtable templates

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Focus on core stability first

**Problem**: Users might want pre-configured templates for common decisions.

**Solution outline**: Templates for tech stack selection, API design review, security review, etc.

**Revisit when**: v1.0 stable, user feedback indicates demand

---

### IDEA-021: Context-aware roundtable splitting

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Context management is improving with other features

**Problem**: Large roundtables may exceed context limits.

**Solution outline**: Suggest splitting based on context size estimation.

**Revisit when**: Context limits become a proven bottleneck

---

### IDEA-022: Product owner observer agent

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Low priority, niche use case

**Problem**: Need a silent observer that tracks discussion and speaks only when user intervenes.

**Solution outline**: Observer agent that summarizes but doesn't participate unless prompted.

**Revisit when**: User feedback indicates demand

---

### IDEA-023: Workflow configuration wizard

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Current defaults work well

**Problem**: New users may find roundtable configuration overwhelming.

**Solution outline**: Interactive wizard to configure roundtable options.

**Revisit when**: Onboarding feedback indicates confusion

---

### IDEA-024: Custom participants skill

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Related to IDEA-001

**Problem**: Creating new participant types requires manual work.

**Solution outline**: Skill with templates for creating new participants.

**Revisit when**: Extension system is prioritized

---

### IDEA-025: Parallel transcriber agent

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: No GUI planned currently

**Problem**: Real-time structured output for potential GUI consumption.

**Solution outline**: Agent that produces JSON output stream.

**Revisit when**: GUI development starts

---

### IDEA-026: Rules folder best practices

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Current CLAUDE.md approach works

**Problem**: Unclear best practices for `.claude/rules/` vs `CLAUDE.md`.

**Solution outline**: Research and document best practices.

**Revisit when**: Claude Code documentation clarifies

---

### IDEA-027: File size verification

**Status**: parked | **Created**: 2026-01-11 | **Parked**: 2026-01-19
**Origin**: manual
**Reason**: Dev tools cover this

**Problem**: Large files may waste tokens.

**Solution outline**: Audit for large files, add to dev-check.

**Revisit when**: Part of QUAL-001 dev tools

---

### IDEA-028: GitHub Issues integration

**Status**: parked | **Created**: 2026-01-19 | **Parked**: 2026-01-19
**Origin**: manual (from notes)
**Reason**: Out of scope for v1

**Problem**: Backlog management could sync with GitHub Issues.

**Solution outline**: Bidirectional sync between BACKLOG.md and GitHub Issues.

**Revisit when**: v1.0 stable, user demand for integration

---

### IDEA-029: Session templates for common scenarios

**Status**: parked | **Created**: 2026-01-19 | **Parked**: 2026-01-19
**Origin**: manual (from notes)
**Reason**: Related to IDEA-020

**Problem**: Starting roundtables requires specifying many options.

**Solution outline**: Pre-configured session templates (quick-specs, deep-design, etc.)

**Revisit when**: User feedback indicates demand

---

## Promoted

<!-- Ideas that became work items - kept for traceability -->

### IDEA-008: Reduce code duplication in workflow commands

**Status**: promoted | **Created**: 2026-01-11 | **Promoted**: 2026-01-20
**Origin**: manual
**Promoted to**: [TECH-002](BACKLOG.md#tech-002-roundtable-command-unification) | [ADR-0011](decisions/0011-roundtable-command-unification.md)

**Problem**: specs.md, design.md, brainstorm.md have ~60% code duplication (~1600+ lines each).

**Solution outline**:
- Extract output generation to on-demand skills
- Use session-qa agent for validation
- Uniformize Phase 2 (Round Execution) across commands
- Align roundtable.md to have same capabilities
- Slim roundtable-execution skill to reference only

**Analysis completed**: Full comparison of skill vs commands documented in ADR-0011.

**Implementation**: See TECH-002 in BACKLOG.md for 6-phase plan.

---

## Rejected

<!-- Ideas that were evaluated and rejected -->
