#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/configure_git.sh – Idempotent global git config setup
# ---------------------------------------------------------------------------
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="$DOTFILES_DIR/git/config/main.gitconfig"

echo "Configuring global git settings…"

if [ ! -f "$CFG" ]; then
  echo "Error: missing $CFG" >&2
  exit 1
fi

# Include our dotfiles-managed gitconfig exactly once
if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$CFG"; then
  echo "✔ Already included: $CFG"
else
  git config --global --add include.path "$CFG"
  echo "✔ Included: $CFG"
fi

# Ensure templateDir exists if referenced
tmpl_dir="$HOME/.git_template"
if [ ! -d "$tmpl_dir" ]; then
  mkdir -p "$tmpl_dir"
  echo "✔ Created $tmpl_dir"
else
  echo "✔ Template dir exists: $tmpl_dir"
fi

# Ensure helper and hook scripts are executable
for f in "$DOTFILES_DIR/git/bin/upstream-map" "$DOTFILES_DIR/git/hooks"/*; do
  [ -e "$f" ] || continue
  if [ ! -x "$f" ]; then
    chmod +x "$f"
    echo "✔ Made executable: $f"
  fi
done

echo "Git config bootstrap complete."
