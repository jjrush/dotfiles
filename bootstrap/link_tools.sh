#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/link_tools.sh – symlink helper scripts from dotfiles/tools → ~/bin
# ---------------------------------------------------------------------------
# Makes ~/bin (if missing) and then links a curated set of scripts so that they
# can be run system-wide. Existing links are replaced; real files are backed up
# with a timestamp when they're *not* symlinks.
# ---------------------------------------------------------------------------
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
say() { printf "%s\n" "$*"; }
run() { if [ "$DRY_RUN" = 1 ]; then say "DRY-RUN: $*"; else eval "$*"; fi }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${DOTFILES_DIR}/tools"
TARGET_DIR="$HOME/bin"

if [ "$DRY_RUN" = 1 ]; then
  say "Would ensure dir exists: $TARGET_DIR"
else
  mkdir -p "$TARGET_DIR"
fi

# Map of link-name → source-script
declare -A LINKS=(
  [trim]="remove_trailing_whitespace.sh"
  [zeek_runner]="zeek_runner.sh"
  [zkg]="zkg_wrapper.sh"
  [check]="check-env.sh"
)

for link in "${!LINKS[@]}"; do
  src="$TOOLS_DIR/${LINKS[$link]}"
  dest="$TARGET_DIR/$link"
  if [[ ! -f "$src" ]]; then
    echo "Warning: source $src not found, skipping $link" >&2
    continue
  fi

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    ts=$(date +%Y%m%d-%H%M%S)
    if [ "$DRY_RUN" = 1 ]; then
      say "Would backup existing $dest → ${dest}.pre-dotfiles.$ts"
    else
      mv "$dest" "${dest}.pre-dotfiles.$ts"
      echo "Backed up existing $dest → ${dest}.pre-dotfiles.$ts"
    fi
  fi

  if [ "$DRY_RUN" = 1 ]; then
    say "Would link $dest → $src"
    say "Would chmod +x $src"
  else
    ln -sf "$src" "$dest"
    chmod +x "$src"               # ensure executable bit
    echo "Linked $dest → $src"
  fi
done
if [ "$DRY_RUN" = 1 ]; then
  say "Tool symlinks dry-run complete."
else
  echo "Tool symlinks complete.  Make sure ~/bin is in your PATH (it is by default in 00_env)."
fi
