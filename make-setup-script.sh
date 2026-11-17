#!/usr/bin/env bash
# Gera setup-script.sh: script autocontido (frota compactada em base64) para colar
# como "Setup script" de um ambiente do Claude Code na nuvem. Rode após editar agentes.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
tar cJf "$TMP/fleet.tar.xz" -C "$HERE" agents CLAUDE.md install.sh
{
  echo '# Frota de agentes Claude Code: instala 13 subagentes + politica de roteamento em ~/.claude'
  echo '# Gerado por make-setup-script.sh. Conteudo: agents/*.md, CLAUDE.md, install.sh (tar.xz em base64).'
  echo 'set -e'
  echo 'D=$(mktemp -d)'
  echo "base64 -d > \"\$D/fleet.tar.xz\" <<'FLEET'"
  base64 -w 190 "$TMP/fleet.tar.xz"
  echo 'FLEET'
  echo 'tar xJf "$D/fleet.tar.xz" -C "$D"'
  echo 'bash "$D/install.sh"'
  echo 'rm -rf "$D"'
} > "$HERE/setup-script.sh"
rm -rf "$TMP"
L=$(wc -l < "$HERE/setup-script.sh"); M=$(awk '{ if (length($0) > m) m = length($0) } END { print m }' "$HERE/setup-script.sh")
echo "setup-script.sh gerado: $L linhas (limite 100), linha mais longa $M bytes (limite 200)."
