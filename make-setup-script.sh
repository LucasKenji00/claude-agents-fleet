#!/usr/bin/env bash
# Gera os scripts de setup para ambientes do Claude Code na nuvem:
#   setup-script.sh          -> curto: clona o repo público da frota e instala (use este)
#   setup-script-embedded.sh -> reserva: frota embutida em base64, sem depender do GitHub
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat > "$HERE/setup-script.sh" <<'EOF'
# Frota de agentes Claude Code (13 subagentes + roteamento + cérebro) -> ~/.claude
set -e
D=$(mktemp -d)
git clone -q --depth 1 https://github.com/LucasKenji00/claude-agents-fleet "$D"
bash "$D/install.sh"
rm -rf "$D"
EOF

TMP="$(mktemp -d)"
tar cJf "$TMP/fleet.tar.xz" -C "$HERE" agents CLAUDE.md install.sh
{
  echo '# Frota de agentes Claude Code embutida (agents/, CLAUDE.md, install.sh em tar.xz/base64) -> ~/.claude'
  echo 'set -e; D=$(mktemp -d)'
  echo "base64 -d > \"\$D/f.tar.xz\" <<'FLEET'"
  base64 -w 198 "$TMP/fleet.tar.xz"
  echo 'FLEET'
  echo 'tar xJf "$D/f.tar.xz" -C "$D"; bash "$D/install.sh"; rm -rf "$D"'
} > "$HERE/setup-script-embedded.sh"
rm -rf "$TMP"
for f in setup-script.sh setup-script-embedded.sh; do
  L=$(wc -l < "$HERE/$f"); M=$(awk '{ if (length($0) > m) m = length($0) } END { print m }' "$HERE/$f")
  echo "$f: $L linhas (limite 100), linha mais longa $M bytes (limite 200)"
done
