# 🪞 Inception — O Agente que Melhora Agentes

> *"Um sonho dentro de um sonho"* — Um projeto Pi standalone para evolução contínua de qualquer agente.

---

## 1. O Problema

O padrão "Improve" está duplicado em 3 projetos:

| Projeto | Arquivo | Experts | Orquestrador |
|---------|---------|---------|--------------|
| Akita | `extensions/improve.ts` | 4 experts | `orchestrator.md` |
| Navi | `extensions/improve.ts` | 5 experts | `orchestrator.md` |
| Pi-Agents | `extensions/pi-pi.ts` | 9 experts | `pi-orchestrator.md` |

Os três têm **~95% do código idêntico** — mesma engine de spawn paralelo, mesmo widget, mesmo footer. A diferença são os experts específicos de cada projeto.

### Problemas atuais:
1. **Código duplicado** — bugfix em um não propaga para os outros
2. **Acoplado ao projeto** — precisa estar DENTRO do diretório do harness
3. **Sem fluxo estruturado** — melhoria ad-hoc, sem plano formal
4. **Sem git integrado** — mudanças ficam uncommitted
5. **Sem histórico** — melhorias anteriores se perdem
6. **Conhecimento isolado** — cada improve só conhece seu próprio projeto

---

## 2. A Visão: Inception como Projeto

O Inception é um **projeto Pi standalone** (como Akita e Navi) que vive em `~/dev/agents/inception/` e pode melhorar — ou criar — qualquer agente Pi.

```
~/dev/agents/
├── akita/          ← harness de coding (alias: pc)
├── navi/           ← harness de PR review
├── pi-agents/      ← lab de extensões Pi
└── inception/      ← 🪞 meta-agente (alias: pp)
```

### Como funciona:
1. Você faz `cd ~/dev/agents/navi && pp`
2. Inception detecta que está no Navi
3. Carrega experts universais + experts locais do Navi
4. Pergunta: "O que quer melhorar?"
5. Pesquisa em paralelo com experts
6. Mostra plano formal com opções
7. Implementa as mudanças aprovadas
8. Faz git commit + push
9. Registra no histórico

### Também cria agentes novos:
- `pp new` → scaffold interativo de um novo harness (como `scripts/scaffold-harness.sh` mas inteligente)
- "Crie um agente que faz X" → pesquisa, planeja e constrói

---

## 3. Estrutura do Projeto

```
~/dev/agents/inception/
├── .gitignore
├── .pi/
│   ├── settings.json
│   └── agents/
│       └── inception/              ← experts do Inception
│           ├── orchestrator.md     ← orquestrador principal
│           ├── pi-core-expert.md   ← Pi Extension API
│           ├── tui-expert.md       ← TUI/UI components
│           ├── agent-def-expert.md ← definições de agentes .md
│           ├── pattern-expert.md   ← padrões de harnesses Pi
│           └── meta-expert.md      ← self-improvement & scaffolding
├── extensions/
│   └── inception.ts                ← extension principal
├── install.sh                      ← instala alias `pp` no zsh
├── justfile                        ← just improve / just code
├── package.json
├── AGENTS.md
└── README.md
```

**Dados persistentes (fora do repo):**
```
~/.inception/
├── config.json                     ← configurações globais (git, etc.)
├── known-harnesses.json            ← registry de harnesses descobertos
└── history/                        ← histórico de melhorias por projeto
    ├── akita/
    │   ├── 2026-04-27_timeout.json
    │   └── evolution.json
    ├── navi/
    └── global-stats.json
```

---

## 4. Alias e Invocação

### Install
```bash
cd ~/dev/agents/inception && ./install.sh
```

O `install.sh` faz:
1. Checa prerequisites (node, bun, pi, just)
2. `bun install`
3. Registra alias `pp` no zsh apontando para `inception/extensions/inception.ts`

### O Alias
```bash
# Gerado pelo install.sh — a extension roda NO diretório atual, não no inception/
alias pp='pi -e ~/dev/agents/inception/extensions/inception.ts'
```

### Uso
```bash
cd ~/dev/agents/akita && pp           # Melhora o Akita
cd ~/dev/agents/navi && pp            # Melhora o Navi
cd ~/random-project && pp             # Detecta ou pergunta
pp                                     # Do diretório do inception, melhora a si mesmo
```

### Dentro do projeto inception
```bash
just improve     # Mesmo que `pp` mas via justfile
just code        # Modo coding normal (para trabalhar no próprio inception)
```

---

## 5. Fluxo Completo

```
┌──────────────────────────────────────────────────────────────┐
│                     INCEPTION FLOW                            │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  1. DETECT ─── Estou num harness Pi?                          │
│     │           ├─ SIM → Carrega contexto automático          │
│     │           └─ NÃO → Lista harnesses conhecidos,          │
│     │                    pergunta qual melhorar                │
│     ▼                                                          │
│  2. LOAD ──── Merge de experts                                │
│     │          ├─ Universais: ~/dev/agents/inception/.pi/...  │
│     │          ├─ Locais: <target>/.pi/agents/improve/        │
│     │          └─ Locais têm prioridade (mesmo nome)          │
│     ▼                                                          │
│  3. ASK ───── O que quer melhorar?                            │
│     │          ├─ Melhoria específica ("add timeout")          │
│     │          ├─ Melhoria geral ("torne mais robusto")        │
│     │          └─ Diagnóstico ("/scan")                        │
│     ▼                                                          │
│  4. RESEARCH ── Experts em paralelo                           │
│     │            ├─ 🔴 Pi Core Expert                          │
│     │            ├─ 🔵 Agent Def Expert                        │
│     │            ├─ 🟣 TUI Expert                              │
│     │            ├─ 🟢 Pattern Expert                          │
│     │            ├─ 🟡 Meta Expert                              │
│     │            └─ 🟠 [Experts locais do projeto]              │
│     ▼                                                          │
│  5. PLAN ──── Plano formal com opções                         │
│     │          ├─ Lista de mudanças com prioridade             │
│     │          ├─ Impacto estimado                             │
│     │          ├─ Preview do commit message                    │
│     │          └─ ⏸️  PAUSA: Usuário aprova/edita plano        │
│     ▼                                                          │
│  6. EXECUTE ── Implementa mudanças aprovadas                  │
│     │           ├─ Uma mudança por vez                         │
│     │           ├─ Rollback se der erro                        │
│     │           └─ Checkpoint após cada mudança                │
│     ▼                                                          │
│  7. VERIFY ── Valida resultado                                │
│     │          ├─ Re-scan do agente                            │
│     │          └─ Smoke test se possível                       │
│     ▼                                                          │
│  8. COMMIT ── Git commit & push                               │
│     │          ├─ git add dos arquivos alterados               │
│     │          ├─ Commit message semântico automático          │
│     │          ├─ ⏸️  Confirma? [C]ommit+Push / [E]dit /       │
│     │          │   [O]nly commit / [S]kip                      │
│     │          └─ git push origin main                         │
│     ▼                                                          │
│  9. LOG ───── Registra no histórico                           │
│                ├─ ~/.inception/history/<project>/<ts>.json     │
│                ├─ Commit hash referenciado                     │
│                └─ Evolution score atualizado                   │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## 6. Detecção de Contexto

### Marcadores de harness Pi

```typescript
const HARNESS_MARKERS = [
  { check: ".pi/agents",           weight: 3 },
  { check: ".pi/settings.json",    weight: 2 },
  { check: "extensions/*.ts",      weight: 2 },
  { check: "justfile",             weight: 1 },
  { check: "AGENTS.md",            weight: 1 },
];
// Score >= 4 → auto-detecta
// Score 1-3 → pergunta: "Parece ser um projeto Pi. Confirma?"
// Score 0   → mostra harnesses conhecidos ou aceita path
```

### Known Harnesses Registry

```json
// ~/.inception/known-harnesses.json
[
  {
    "name": "akita",
    "path": "/Users/lucca/dev/agents/akita",
    "last_improved": "2026-04-27T10:45:00Z",
    "improvements_count": 12
  },
  {
    "name": "navi",
    "path": "/Users/lucca/dev/agents/navi",
    "last_improved": "2026-04-25T14:30:00Z",
    "improvements_count": 8
  }
]
```

---

## 7. Merge de Experts

O Inception combina experts de dois lugares:

```
Experts Finais = Universais (inception/.pi/agents/inception/)
               + Locais     (<target>/.pi/agents/improve/)

Se mesmo nome → local tem prioridade (conhece o código específico)
```

### Experts Universais (sempre presentes)

| Expert | Domínio | Primeira ação |
|--------|---------|---------------|
| `pi-core-expert` | Extension API: registerTool, registerCommand, events, ctx | Ler Pi docs + extensions do alvo |
| `tui-expert` | Widgets, footer, header, themes, Text component | Ler Pi TUI docs |
| `agent-def-expert` | Formato .md, frontmatter, teams.yaml, orchestration | Ler .pi/agents/ do alvo |
| `pattern-expert` | Padrões de harnesses: spawn, parallel, state | Ler extensions/ do alvo |
| `meta-expert` | Self-improvement, scaffolding de novos harnesses | Ler inception spec + código |

### Experts Locais (se existirem no projeto-alvo)

Exemplos do Akita: `extension-expert`, `agent-expert`, `ui-expert`, `pi-api-expert`
Exemplos do Navi: os mesmos + `workflow-expert`

O widget mostra TODOS igualmente — o orquestrador sabe quais são universais e quais locais.

---

## 8. Plano de Melhoria

### Formato

```markdown
# 🪞 Plano de Melhoria — Akita
**Solicitação:** "Adicionar timeout nos experts e melhorar error handling"

## Mudanças Propostas

### 1. [ALTA] Timeout no queryExpert()
**Arquivo:** `extensions/improve.ts`
**O quê:** Adicionar AbortController com timeout configurável (60s)
**Por quê:** Experts podem travar se o modelo não responder
**Impacto:** Médio — toca na função core de spawn
**Estimativa:** ~30 linhas

### 2. [ALTA] Error recovery no spawn
**Arquivo:** `extensions/improve.ts`
**O quê:** Retry automático (1x) com backoff em caso de erro transiente
**Impacto:** Baixo — adição incremental
**Estimativa:** ~20 linhas

### 3. [MÉDIA] Status de timeout no widget
**Arquivo:** `extensions/improve.ts`
**O quê:** Novo status "timeout" com cor amarela nos cards
**Impacto:** Baixo — UI only
**Estimativa:** ~15 linhas

---
**Git:** 1 commit → `feat(akita): add timeout and error handling to expert queries`

**Opções:**
- [A] Executar todas (1, 2, 3)
- [B] Só alta prioridade (1, 2)
- [C] Customizar — escolha quais
- [D] Refinar plano
```

---

## 9. Git: Commit & Push

### Fluxo

Após executar melhorias, o orquestrador (via bash tool):

1. `git add` dos arquivos alterados
2. Gera commit message em **Conventional Commits**:
   ```
   feat(akita): add timeout and error handling

   - Add AbortController with 60s timeout to queryExpert()
   - Add retry with backoff on transient errors
   - Add 'timeout' status to expert grid cards

   Inception-Score: +8 (78 → 86)
   ```
3. Mostra ao usuário com opções (via conversação):
   - **[C]** Commit + Push
   - **[E]** Editar mensagem, depois commit + push
   - **[O]** Commit only (sem push)
   - **[S]** Skip
4. Executa `git commit` e `git push origin main`

### Configuração

```json
// ~/.inception/config.json
{
  "git": {
    "auto_commit": true,
    "auto_push": true,
    "confirm_before_push": true,
    "default_branch": "main"
  }
}
```

---

## 10. Histórico de Evolução

```json
// ~/.inception/history/akita/2026-04-27_timeout.json
{
  "harness": "akita",
  "date": "2026-04-27T10:45:00Z",
  "request": "Adicionar timeout nos experts",
  "changes": [
    { "file": "extensions/improve.ts", "type": "edit", "description": "AbortController timeout" },
    { "file": "extensions/improve.ts", "type": "edit", "description": "Retry with backoff" },
    { "file": "extensions/improve.ts", "type": "edit", "description": "Timeout status in widget" }
  ],
  "commit_hash": "abc1234",
  "commit_message": "feat(akita): add timeout and error handling",
  "score_delta": 8
}
```

---

## 11. Comandos

### Slash commands dentro do Inception
```
/scan              → Analisa o agente-alvo e mostra profile
/experts           → Lista experts ativos e status
/experts-grid N    → Colunas do grid (1-5)
/history           → Histórico de melhorias do projeto atual
/switch <path>     → Muda o agente-alvo
/diff              → Diff das mudanças da sessão
```

### Widget TUI
```
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Pi Core Expert   │ │ TUI Expert       │ │ Pattern Expert   │
│ ◉ researching    │ │ ✓ done     12s   │ │ ◉ researching    │
│ "Como funciona   │ │ "setWidget API   │ │ "Padrão de spawn │
│  AbortController"│ │  e tokens"       │ │  em improve.ts"  │
└─────────────────┘ └─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐
│ Agent Def Expert │ │ workflow-expert  │  ← expert LOCAL
│ ○ idle           │ │ ○ idle           │    do Navi
└─────────────────┘ └─────────────────┘
```

---

## 12. Diferenças do Inception vs Improve atual

| Aspecto | Improve (atual) | Inception (proposta) |
|---------|----------------|---------------------|
| **Tipo** | Extension dentro de cada projeto | Projeto standalone próprio |
| **Localização** | `<projeto>/extensions/improve.ts` | `~/dev/agents/inception/` |
| **Escopo** | 1 projeto específico | Qualquer projeto Pi |
| **Experts** | Só locais | Universais + locais (merge) |
| **Invocação** | `just improve` (dentro do projeto) | `pp` (de qualquer lugar) |
| **Instalação** | Manual por projeto | `./install.sh` uma vez |
| **Detecção** | Manual | Automática com scoring |
| **Planejamento** | Ad-hoc | Plano formal com opções |
| **Git** | Nenhum | Commit + push integrado |
| **Histórico** | Nenhum | Completo com scoring |
| **Criar agentes** | Não | Sim (scaffold + construção) |

---

## 13. Compatibilidade

### O que NÃO muda nos projetos existentes
- Os `improve.ts` dos projetos continuam funcionando via `just improve`
- Os `.pi/agents/improve/*.md` locais são carregados pelo Inception como experts adicionais
- Migração gradual: projetos podem remover seu `improve.ts` e confiar no `pp`

### O Inception melhora a si mesmo
- `cd ~/dev/agents/inception && pp` → detecta como harness, carrega seus próprios experts
- O `meta-expert` sabe como o Inception funciona e pode evoluí-lo

---

*"You mustn't be afraid to dream a little bigger, darling."* — Eames, Inception
