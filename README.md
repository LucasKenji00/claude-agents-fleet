# Frota de agentes para Claude Code

Treze subagentes em três camadas de custo, mais uma política de roteamento que faz o modelo principal (Fable 5.1) agir como cérebro e delegar o trabalho mecânico aos modelos mais baratos.

## Camadas

| Camada | Modelo | Agentes | Para quê |
|---|---|---|---|
| Verde | Haiku 5.5 (`haiku`) | `triage`, `scout`, `scribe`, `runner` | mecânico, repetitivo, leitura, execução |
| Azul | Sonnet 5.5 (`sonnet`) | `coder`, `tester`, `reviewer`, `researcher`, `writer`, `analyst` | trabalho padrão de engenharia, pesquisa, texto, dados |
| Roxo | Opus 5.5 (`opus`) | `architect`, `debugger`, `security` | raciocínio difícil, decisões de design, causa raiz |
| Cérebro | Fable 5.1 (sessão principal) | — | conversa, decisões, integração, revisão final |

Os aliases `haiku`/`sonnet`/`opus` apontam sempre para a versão atual de cada família, então a frota se atualiza sozinha quando sai modelo novo. Se quiser fixar, troque por um ID completo (ex.: `model: claude-haiku-5-5`).

## Como os agentes "trocam" entre si

1. **Escalonamento para cima.** Todo agente termina com `STATUS: DONE | PARTIAL | ESCALATE(agente): motivo`. O orquestrador lê isso e redespacha para o agente indicado, passando o relatório anterior. Escada padrão: Haiku -> Sonnet -> Opus -> Fable.
2. **Delegação para baixo.** `coder`, `tester`, `debugger`, `architect` e `security` têm a ferramenta `Agent` e podem chamar `scout`, `runner` e `scribe` sozinhos, sem passar pelo Fable. A regra "só para agentes mais baratos" está no prompt deles (o Claude Code não impõe lista de tipos permitidos dentro de subagentes, então é disciplina de prompt).
3. **Planos etiquetados.** `architect` devolve cada passo do plano com `[agente]`, e o orquestrador despacha cada um ao agente certo, em paralelo quando possível.
4. **Classificador barato.** `triage` (Haiku) decide quem faz o quê quando não é óbvio, por uma fração de centavo.

## Instalar

### Na sua máquina (ambiente local, ex.: "Plataforma prepaid")

```bash
./install.sh            # usuário: ~/.claude/agents + ~/.claude/CLAUDE.md + modelo padrão Fable 5.1 (vale em todo projeto)
./install.sh --project  # projeto: ./.claude/agents + ./.claude/CLAUDE.md (versionável)
```

Instalação única; persiste entre sessões e projetos.

### Na nuvem (claude.ai/code)

O contêiner da nuvem nasce limpo em toda sessão, então a frota precisa ser instalada pelo **Setup script** do ambiente. O arquivo `setup-script.sh` é autocontido (frota compactada em base64) e cabe no limite do campo. Cole-o em: menu do ambiente na barra de título da sessão > Edit > Setup script. Coloque no ambiente **Default** para valer em todos os repositórios.

Editou um agente? Rode `./make-setup-script.sh` e cole o novo `setup-script.sh` no ambiente.

Depois abra uma sessão nova do Claude Code e rode `/agents` para ver a lista. Se o Fable não estiver delegando o suficiente, diga "use a frota" ou "delegue isso ao coder" nas primeiras vezes; a descrição de cada agente já diz "use PROATIVAMENTE", então ele deve pegar o hábito.

### Modelo orquestrador

`install.sh` grava `"model": "claude-fable-5-1"` em `settings.json` se ainda não houver modelo definido. Na interface web o seletor de modelo da sessão tem prioridade; deixe-o em Fable 5.1.

## Ajustes

- **Esforço**: `effort: low|medium|high|xhigh|max` no frontmatter. Haiku está em `low`, Sonnet em `medium`, Opus em `high`. Aumente só onde medir ganho.
- **Ferramentas**: `tools:` é allowlist. Para dar MCP a um agente: `tools: Read, Grep, mcp__github__*`. Para bloquear comandos específicos de Bash, use `permissions.deny` no `settings.json` (vale para a sessão e para os subagentes).
- **Memória persistente**: adicione `memory: user` (vale entre projetos) ou `memory: project` (versionado) a um agente para que ele acumule aprendizados em `MEMORY.md`. Requer auto-memory ligado.
- **Forçar um modelo em todos**: variáveis `CLAUDE_CODE_SUBAGENT_MODEL=haiku` e `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1`.
- **Isolamento**: `isolation: worktree` faz o agente trabalhar num worktree git temporário (útil para `coder` em mudanças arriscadas).

## Adicionar um agente novo

Crie `agents/<nome>.md` com frontmatter (`name`, `description`, `model`, `effort`, `tools`) e um corpo com: papel, fluxo, regras, formato de resposta terminando em `STATUS: ...`. Adicione a linha dele na tabela de `CLAUDE.md` e em `agents/triage.md`.

## Duas contas GitHub (pessoal e empresa)

Como funciona o acesso no Claude Code na nuvem:

- Cada conta claude.ai conecta **uma** identidade GitHub (hoje: a sua pessoal). O acesso aos repositórios vem do **Claude GitHub App** instalado no dono do repositório (sua conta ou uma organização).
- A frota não depende de qual GitHub está conectado: ela é instalada pelo setup script do ambiente, em qualquer repositório que a sessão abrir.

Cenários:

1. **Repos da empresa estão numa Organização GitHub.** Peça a um owner da org para instalar o Claude GitHub App nela (mesma página: claude.ai/connect-github, "Install"). Sua conta pessoal precisa ser membro da org com acesso aos repos. Resultado: pessoal e empresa na mesma conta Claude, mesma frota, mesmo ambiente Default.
2. **Repos da empresa estão em outra conta de usuário GitHub (não org).** Opções: (a) o dono adiciona sua conta pessoal como colaborador e instala o App nessa conta; ou (b) a empresa tem/terá a própria organização Claude: conecte o GitHub corporativo lá e cole o mesmo `setup-script.sh` no ambiente Default dessa organização. A frota é portátil.
3. **Quer separar o que cada lado usa.** Instale por projeto (`./install.sh --project`) e faça commit da pasta `.claude/` no repo: todo mundo da equipe recebe a mesma frota, e você pode manter versões diferentes para pessoal e empresa. Para restringir ferramentas por contexto, use `permissions.allow/deny` no `.claude/settings.json` do projeto.

Na sua máquina (ambiente local), o `gh` suporta várias contas: `gh auth login` para cada uma e `gh auth switch` para alternar. Para o git usar nome/e-mail certos por pasta, use `includeIf` no `~/.gitconfig` apontando para `~/trabalho/` e `~/pessoal/`.
