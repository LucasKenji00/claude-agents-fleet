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
echo
echo "Pronto. Abra uma nova sessão do Claude Code e rode /agents para conferir."
