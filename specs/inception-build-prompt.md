# Prompt de Construção: Inception

> **Como usar:** `cd ~/dev/agents/pi-agents && just ext-pi-pi`
> Depois cole o prompt do bloco abaixo.
>
> O Pi Pi tem 9 experts (Extensions, TUI, Agents, Settings, etc.) que vão
> pesquisar a documentação do Pi em paralelo antes de construir — exatamente
> o conhecimento que o Inception precisa herdar.

---

## O Prompt

```
Preciso que você construa o **Inception** — um projeto Pi standalone que melhora (e cria) qualquer agente Pi.

## Contexto

Leia estes arquivos primeiro (nesta ordem):
1. `specs/inception.md` — spec completa com arquitetura e decisões
2. `extensions/pi-pi.ts` — engine de experts paralelos que o Inception vai usar como base
3. `.pi/agents/pi-pi/pi-orchestrator.md` — formato do orquestrador com placeholders
4. `.pi/agents/pi-pi/ext-expert.md` — exemplo de expert definition
5. `../akita/install/install.sh` — padrão de install script com alias
6. `../akita/extensions/improve.ts` — improve existente (referência do que extrair)
7. `../akita/AGENTS.md` — padrão de documentação de harness

## O que é o Inception

É um projeto como Akita e Navi — vive em `~/dev/agents/inception/`, tem suas próprias extensions, agents, justfile e install.sh. A diferença é que ele não trabalha NO seu próprio diretório: quando eu rodo `pp` de dentro do `~/dev/agents/navi/`, ele melhora o Navi. Quando rodo de dentro do `~/dev/agents/akita/`, melhora o Akita. Quando rodo de dentro do próprio `inception/`, melhora a si mesmo.

O alias `pp` aponta para a extension do inception mas roda no cwd atual:
```bash
alias pp='pi -e ~/dev/agents/inception/extensions/inception.ts'
```

## O que construir

Criar o projeto completo em `~/dev/agents/inception/` com esta estrutura:

### 1. Arquivos de projeto raiz

**package.json:**
```json
{
  "name": "inception",
  "private": true,
  "type": "module",
  "description": "Inception — meta-agent that improves and creates Pi agents",
  "dependencies": {
    "yaml": "^2.8.0"
  }
}
```

**justfile:**
```just
set dotenv-load := true

default:
    @just --list

# Run inception on the current directory (improve whatever agent is here)
code:
    pi -e extensions/inception.ts

# Same as code — improve this project (inception itself)
improve:
    pi -e extensions/inception.ts
```

**.gitignore:**
```
node_modules/
.pi/agent-sessions/
bun.lock
```

**AGENTS.md:** Documentação do projeto seguindo o padrão do Akita (tooling, modes, estrutura).

**README.md:** Documentação para o usuário (o que é, como instalar, como usar).

### 2. Extension principal: `extensions/inception.ts`

Baseada em `pi-pi.ts` mas com estas diferenças fundamentais:

**A) Detecção de contexto no session_start:**
- Analisar o `cwd` com marcadores de harness Pi:
  - `.pi/agents` (peso 3), `.pi/settings.json` (peso 2), presença de `extensions/*.ts` (peso 2), `justfile` (peso 1), `AGENTS.md` (peso 1)
  - Score >= 4 → auto-detecta, mostra nome do harness no notify
  - Score 1-3 → `ctx.ui.notify` perguntando se é um harness
  - Score 0 → mostra lista de known harnesses de `~/.inception/known-harnesses.json` ou pede path
- Quando detecta harness, registrar/atualizar em `~/.inception/known-harnesses.json`
- Determinar o `targetPath` (diretório do harness alvo) e o `targetName` (nome do harness)

**B) Merge de experts:**
- Carregar experts universais de `<inception_root>/.pi/agents/inception/` (onde `inception_root` é o diretório do projeto inception, resolúvel via `import.meta.url` ou hardcoded como `~/dev/agents/inception`)
- Carregar experts locais de `<targetPath>/.pi/agents/improve/` (se existirem)
- Se expert local tem mesmo nome que universal → local tem prioridade
- Map final é a união, widget mostra todos igualmente

**C) Orchestrator path:**
- Ler orchestrator de `<inception_root>/.pi/agents/inception/orchestrator.md`
- Injetar no system prompt via `before_agent_start` com placeholders:
  - `{{EXPERT_COUNT}}`, `{{EXPERT_NAMES}}`, `{{EXPERT_CATALOG}}`
  - `{{TARGET_PATH}}`, `{{TARGET_NAME}}` (novos — para o orquestrador saber onde operar)

**D) Self-contained:**
- NÃO depender de `themeMap.ts` ou imports locais do pi-agents
- Todas as cores de expert cards inline (como no akita/improve.ts)
- Copiar o padrão de EXPERT_COLORS com cores distintas para os 5 experts universais

**E) Diretórios de dados:**
- No session_start, criar `~/.inception/` e subdiretórios se não existirem (mkdirSync recursive)
- Inicializar `config.json` e `known-harnesses.json` com defaults se não existirem

**F) Comandos:**
- `/scan` — analisa o harness-alvo e mostra profile (extensions, agents, capabilities)
- `/experts` — lista experts (universais + locais) e status
- `/experts-grid N` — colunas do grid (1-5)
- `/history` — lê `~/.inception/history/<targetName>/` e mostra resumo
- `/switch <path>` — muda o targetPath sem reiniciar sessão

**G) Footer:**
- Modelo, "🪞 inception", target name, experts ativos/done, context usage bar

### 3. Experts universais: `.pi/agents/inception/`

Criar 6 arquivos .md com frontmatter + system prompt:

**orchestrator.md** — Orquestrador principal:
- Tools: `read,write,edit,bash,grep,find,ls,query_experts`
- System prompt com fases: Research (parallel) → Plan (formal com opções A/B/C/D) → Execute → Git Commit → Log
- Regra: SEMPRE pesquisar com experts antes de implementar
- Regra: SEMPRE mostrar plano antes de executar
- Regra: Após implementar, fazer git commit com Conventional Commits (`feat/fix/refactor(<scope>): description`)
- Regra: Mostrar commit message e perguntar [C]ommit+Push / [E]dit / [O]nly commit / [S]kip
- Regra: Registrar melhoria em `~/.inception/history/<targetName>/`
- Placeholder: `{{TARGET_PATH}}` para saber onde ler/escrever
- Placeholder: `{{TARGET_NAME}}` para scope do commit

**pi-core-expert.md** — Pi Extension API:
- Tools: `read,grep,find,ls,bash`
- Expertise: registerTool, registerCommand, events, ctx, sendMessage, TypeBox
- Primeira ação: ler docs em `~/.local/node/lib/node_modules/@mariozechner/pi-coding-agent/docs/extensions.md` + extensions do alvo

**tui-expert.md** — TUI/UI:
- Tools: `read,grep,find,ls,bash`
- Expertise: widgets, footer, header, Text, truncateToWidth, visibleWidth, themes, select, prompt
- Primeira ação: ler docs em `~/.local/node/lib/node_modules/@mariozechner/pi-coding-agent/docs/tui.md`

**agent-def-expert.md** — Definições de agentes:
- Tools: `read,grep,find,ls,bash`
- Expertise: formato .md, frontmatter (name, description, tools), system prompts, teams.yaml, agent discovery
- Primeira ação: ler `.pi/agents/` do projeto-alvo (path passado na question)

**pattern-expert.md** — Padrões de harnesses Pi:
- Tools: `read,grep,find,ls,bash`
- Expertise: spawn de subagents via child_process, parallel queries com Promise.allSettled, state management, justfile patterns, install scripts
- Primeira ação: ler `extensions/*.ts` do projeto-alvo + exemplos em ~/dev/agents/

**meta-expert.md** — Self-improvement & scaffolding:
- Tools: `read,grep,find,ls,bash`
- Expertise: como o Inception funciona, scaffold de novos harnesses, o padrão improve.ts, como o merge de experts funciona
- Primeira ação: ler `specs/inception.md` e `extensions/inception.ts` do próprio inception

### 4. Install script: `install.sh`

Seguir o padrão do `akita/install/install.sh`:

1. Banner "🪞 Inception"
2. Checar prerequisites: node, bun, pi, just (opcional), git
3. Instalar dependências: `bun install`
4. Criar diretórios de dados: `~/.inception/`, `~/.inception/history/`
5. Criar config default: `~/.inception/config.json` (se não existir)
6. Criar known harnesses: `~/.inception/known-harnesses.json` (se não existir)
7. Registrar alias `pp` no zsh:
   ```bash
   alias pp='pi -e ~/dev/agents/inception/extensions/inception.ts'
   ```
   Usar o padrão de markers do Akita (`# inception-aliases-start` / `# inception-aliases-end`)
   Suportar `~/.zsh/aliases/pi.zsh` ou fallback para `~/.zshrc`
8. Summary com next steps

### 5. Dados iniciais

**~/.inception/config.json:**
```json
{
  "git": {
    "auto_commit": true,
    "auto_push": true,
    "confirm_before_push": true,
    "default_branch": "main"
  }
}
```

**~/.inception/known-harnesses.json:**
```json
[]
```

## Referências de código

Arquivos para ler e usar como base (em ordem de importância):
1. `extensions/pi-pi.ts` — engine de experts paralelos, widget grid, query_experts (BASE PRINCIPAL)
2. `.pi/agents/pi-pi/pi-orchestrator.md` — orquestrador com placeholders
3. `.pi/agents/pi-pi/ext-expert.md` — expert de extensões (referência de formato)
4. `.pi/agents/pi-pi/tui-expert.md` — expert de TUI (referência)
5. `../akita/install/install.sh` — padrão de install script (COPIAR E ADAPTAR)
6. `../akita/extensions/improve.ts` — improve existente (referência de merge)
7. `../navi/extensions/improve.ts` — improve existente (referência)
8. `../akita/AGENTS.md` — formato de documentação
9. `../akita/justfile` — formato de justfile

## Regras

1. O inception.ts DEVE ser **self-contained** — sem imports de themeMap.ts ou qualquer arquivo do pi-agents
2. O `inception_root` (path do projeto inception) deve ser resolvido via `import.meta.url` para funcionar independente de onde está clonado
3. Os experts universais vivem em `<inception_root>/.pi/agents/inception/`, NÃO em ~/.pi/
4. Os dados persistentes (config, history, known harnesses) vivem em `~/.inception/`
5. O alias `pp` roda a extension do inception mas o `cwd` é o diretório onde o usuário está
6. Criar o diretório `~/dev/agents/inception/` e TODOS os arquivos dentro dele
7. Rodar `bun install` no diretório após criar tudo
8. O install.sh deve ser executável (`chmod +x`)

## Entrega

Ao finalizar, listar todos os arquivos criados e mostrar como testar:
```bash
cd ~/dev/agents/inception && ./install.sh
source ~/.zshrc
cd ~/dev/agents/akita && pp    # Deve detectar Akita e mostrar 5+ experts
```
```

---

## Notas

- **Por que Pi Pi?** Porque ele já tem os experts que sabem construir componentes Pi — extensões, TUI, agents, settings. O Inception é basicamente um Pi Pi que opera em outros projetos.
- **Tempo estimado**: O Pi Pi com experts deve levar ~5-10 min para construir tudo.
- **Após criação**: teste com `cd ~/dev/agents/akita && pp` e verifique que detecta o harness e carrega experts universais + locais do Akita.
