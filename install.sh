#!/usr/bin/env bash
# Instala a frota de agentes do Claude Code.
#   ./install.sh            -> instala para o usuário (~/.claude), vale em todos os projetos
#   ./install.sh --project  -> instala no projeto atual (./.claude), versionável no git
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--project" ]]; then
  DEST="$(pwd)/.claude"
else
  DEST="${HOME}/.claude"
fi
mkdir -p "$DEST/agents"
cp "$HERE"/agents/*.md "$DEST/agents/"
echo "Agentes instalados em $DEST/agents:"
ls "$DEST/agents"

# CLAUDE.md global: o bloco da frota fica entre marcadores e é substituído a cada instalação;
# tudo que estiver fora dos marcadores (conteúdo do usuário) é preservado.
python3 - "$DEST/CLAUDE.md" "$HERE/CLAUDE.md" <<'PYEOF2'
import os, sys
dest, src = sys.argv[1], sys.argv[2]
S, E = "<!-- claude-agents-fleet:start -->", "<!-- claude-agents-fleet:end -->"
LEGACY = "# Frota de agentes — política de roteamento do orquestrador"
block = S + "\n" + open(src, encoding="utf-8").read().rstrip("\n") + "\n" + E + "\n"
cur = open(dest, encoding="utf-8").read() if os.path.exists(dest) else ""
if S in cur and E in cur:
    a, b = cur.index(S), cur.index(E) + len(E)
    cur = cur[:a] + block.rstrip("\n") + cur[b:]
    msg = "bloco da frota atualizado"
elif LEGACY in cur:
    cur = cur[:cur.index(LEGACY)].rstrip("\n") + ("\n\n" if cur.strip() else "") + block
    msg = "bloco antigo da frota substituído"
else:
    cur = (cur.rstrip("\n") + "\n\n" if cur.strip() else "") + block
    msg = "bloco da frota adicionado"
open(dest, "w", encoding="utf-8").write(cur)
print("CLAUDE.md global:", msg, "em", dest)
PYEOF2

# Modelo padrão do orquestrador (só define se ainda não houver um configurado)
SETTINGS="$DEST/settings.json"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" <<'PYEOF'
import json, os, sys
p = sys.argv[1]
d = {}
if os.path.exists(p):
    try:
        d = json.load(open(p))
    except Exception:
        d = {}
if "model" not in d:
    d["model"] = "claude-fable-5-1"
    json.dump(d, open(p, "w"), indent=2)
    print("Modelo padrão definido: claude-fable-5-1 em", p)
else:
    print("Modelo padrão já definido em", p, ":", d["model"])
PYEOF
else
  echo "python3 ausente: defina \"model\": \"claude-fable-5-1\" em $SETTINGS manualmente."
fi
# Cérebro (memória central): clona ou atualiza ~/claude-brain quando houver acesso ao GitHub
BRAIN="${HOME}/claude-brain"
if [[ -d "$BRAIN/.git" ]]; then
  git -C "$BRAIN" pull --rebase --autostash -q && echo "Cérebro atualizado em $BRAIN." || echo "Cérebro presente em $BRAIN (pull falhou; segue com a cópia local)."
elif git clone -q --depth 50 https://github.com/LucasKenji00/claude-brain "$BRAIN" 2>/dev/null; then
  echo "Cérebro clonado em $BRAIN."
else
  echo "Cérebro não clonado (sem acesso ao repo privado neste ambiente). A sessão pedirá para vincular quando precisar."
fi

echo
echo "Pronto. Abra uma nova sessão do Claude Code e rode /agents para conferir."
