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

MARK="# Frota de agentes — política de roteamento do orquestrador"
if [[ -f "$DEST/CLAUDE.md" ]] && grep -qF "$MARK" "$DEST/CLAUDE.md"; then
  echo "Política de roteamento já presente em $DEST/CLAUDE.md (não alterada)."
else
  { [[ -f "$DEST/CLAUDE.md" ]] && printf '\n\n'; cat "$HERE/CLAUDE.md"; } >> "$DEST/CLAUDE.md"
  echo "Política de roteamento adicionada a $DEST/CLAUDE.md."
fi

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
echo
echo "Pronto. Abra uma nova sessão do Claude Code e rode /agents para conferir."
