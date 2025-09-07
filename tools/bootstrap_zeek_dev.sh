#!/usr/bin/env bash
# bootstrap_zeek_dev.sh
# -------------------------------------------------------------
# Sets up:
#   • uv-powered wrapper for zkg (~/tools/zkg_wrapper.sh)
#   • user-mode zkg config  (~/.zkg/config)
#   • static Zeek env file  (~/.zkg/env.sh)
#   • fast PATH / history / alias lines in ~/.bashrc (one copy)
#   • symlink in ~/bin/zkg  (shadowing /opt/zeek/bin/zkg)
# -------------------------------------------------------------

set -euo pipefail

##############################################################################
# Config – tweak for non-default layouts
##############################################################################
ZEEDIR=/opt/zeek                 # change if Zeek is elsewhere
WRAPPER_DIR="$HOME/tools"
WRAPPER="$WRAPPER_DIR/zkg_wrapper.sh"
BIN_DIR="$HOME/bin"
SHELL_RC="$HOME/.bashrc"         # or ~/.zshrc
ZKG_ENV_FILE="$HOME/.zkg/env.sh"

##############################################################################
step() { printf '\e[1;34m==> %s\e[0m\n' "$*"; }

append_if_missing() {
  # append literal line $2 to file $1 unless it already exists
  local file=$1 line=$2
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

##############################################################################
step "1. Create directories"
mkdir -p "$WRAPPER_DIR" "$BIN_DIR"

##############################################################################
step "2. Write uv-powered zkg wrapper"
cat >"$WRAPPER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ZKG_UV_VENV="${ZKG_UV_VENV:-${XDG_CONFIG_HOME:-$HOME/.config}/zkg-uv}"
DEPS=(GitPython semantic-version)
UV_BIN="${UV_BIN:-$(command -v uv)}"

if [[ ! -d "$ZKG_UV_VENV" ]]; then
  "$UV_BIN" venv "$ZKG_UV_VENV"
fi
export PATH="$ZKG_UV_VENV/bin:$PATH"

python -I -S - <<'PY' >/dev/null 2>&1 || "$UV_BIN" pip install "${DEPS[@]}"
import importlib, sys
sys.exit(any(importlib.util.find_spec(m) is None for m in ("git","semantic_version")))
PY

exec /opt/zeek/bin/zkg.real --user "$@"
EOF
chmod +x "$WRAPPER"

##############################################################################
step "3. Symlink wrapper as ~/bin/zkg"
ln -sf "$WRAPPER" "$BIN_DIR/zkg"


