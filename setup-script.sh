# Frota de agentes Claude Code (13 subagentes + roteamento + cérebro) -> ~/.claude
set -e
D=$(mktemp -d)
git clone -q --depth 1 https://github.com/LucasKenji00/claude-agents-fleet "$D"
bash "$D/install.sh"
rm -rf "$D"
