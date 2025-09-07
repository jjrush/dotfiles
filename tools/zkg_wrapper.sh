#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
ZKG_UV_VENV="${ZKG_UV_VENV:-${XDG_CONFIG_HOME:-$HOME/.config}/zkg-uv}"
DEPS=(GitPython semantic-version)
UV_BIN="${UV_BIN:-$(command -v uv)}"

# ---------------------------------------------------------------------------
# 1. Create or reuse the venv
# ---------------------------------------------------------------------------
if [[ ! -d "$ZKG_UV_VENV" ]]; then
  "$UV_BIN" venv "$ZKG_UV_VENV"
fi
export PATH="$ZKG_UV_VENV/bin:$PATH"

# ---------------------------------------------------------------------------
# 2. Ensure wheels are present (quietly)
# ---------------------------------------------------------------------------
python -I -S - <<'PY' >/dev/null 2>&1 || "$UV_BIN" pip install "${DEPS[@]}"
import importlib, sys
sys.exit(any(importlib.util.find_spec(m) is None
             for m in ("git", "semantic_version")))
PY

# ---------------------------------------------------------------------------
# 3. Run real zkg
# ---------------------------------------------------------------------------
echo "Running zkg with args: $@"
exec /opt/zeek/bin/zkg.real "$@"