#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/cleanup.sh – Remove old/conflicting dotfiles and shell configs
# ---------------------------------------------------------------------------
# Cleans up old zsh files and other conflicting configs.
# These dotfiles are BASH-ONLY. Zsh users must switch to bash.
# ---------------------------------------------------------------------------
set -euo pipefail

echo "==> Cleaning up old shell configurations..."

# Files to remove (backed up first)
# .bash_profile will be recreated by setup_shell.sh
# .zshrc will be replaced with a "switch to bash" message
CLEANUP_FILES=(
  "$HOME/.zprofile"
  "$HOME/.zsh_aliases"
  "$HOME/.zsh_func"
  "$HOME/.zsh_history"
  "$HOME/.local/bin/env"
  "$HOME/.local/bin/env.fish"
)

BACKUP_DIR="$HOME/.dotfiles-cleanup-$(date +%Y%m%d-%H%M%S)"

for file in "${CLEANUP_FILES[@]}"; do
  if [ -e "$file" ]; then
    # Create backup directory on first file
    if [ ! -d "$BACKUP_DIR" ]; then
      mkdir -p "$BACKUP_DIR"
      echo "Created backup directory: $BACKUP_DIR"
    fi

    # Move file to backup
    mv "$file" "$BACKUP_DIR/"
    echo "✔ Backed up and removed: $file"
  fi
done

# Remove .profile if it only sources .local/bin/env
if [ -f "$HOME/.profile" ]; then
  if grep -q '^\. "\$HOME/\.local/bin/env"$' "$HOME/.profile" && [ "$(wc -l < "$HOME/.profile")" -le 3 ]; then
    mv "$HOME/.profile" "$BACKUP_DIR/" 2>/dev/null || true
    echo "✔ Backed up and removed: $HOME/.profile (was only sourcing .local/bin/env)"
  fi
fi

if [ -d "$BACKUP_DIR" ]; then
  echo ""
  echo "✔ Cleanup complete. Old files backed up to: $BACKUP_DIR"
  echo "  You can safely delete this directory after verifying everything works."
else
  echo "✔ No files needed cleanup."
fi
