#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/dry-run.sh – Preview what setup-new-machine.sh would change
# ---------------------------------------------------------------------------
set -euo pipefail

echo "==> Dry-run: inspecting system for required changes"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

section() { printf "\n-- %s --\n" "$*"; }

# 1) System packages
section "System packages"
case "$(uname -s)" in
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      # Compute difference desired − installed using one dpkg-query call
      missing=$(comm -23 \
        <(grep -v '^\s*$' "$DOTFILES_DIR/bootstrap/packages.apt" | sort -u) \
        <(dpkg-query -W -f='${Package}\n' 2>/dev/null | sort -u))
      if [ -n "$missing" ]; then
        printf "Would install (apt):\n%s\n" "$missing"
      else
        echo "All listed apt packages appear installed."
      fi
    else
      echo "apt-get not found; skipping apt package check."
    fi
    ;;
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      missing=$(comm -23 \
        <(grep -v '^\s*$' "$DOTFILES_DIR/bootstrap/packages.brew" | sort -u) \
        <(brew list --formula | sort -u))
      if [ -n "$missing" ]; then
        printf "Would install (brew):\n%s\n" "$missing"
      else
        echo "All listed brew packages appear installed."
      fi
    else
      echo "brew not found; skipping brew package check."
    fi
    ;;
  *)
    echo "Unsupported OS: $(uname -s); skipping package checks."
    ;;
esac

# 2) Tool links
section "Tool links"
DRY_RUN=1 bash "$DOTFILES_DIR/bootstrap/link_tools.sh"

# 3) Git include + template dir
section "Git config include"
CFG="$DOTFILES_DIR/git/config/main.gitconfig"
if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$CFG"; then
  echo "Include already present: $CFG"
else
  echo "Would add include.path = $CFG"
fi
if [ -d "$HOME/.git_template" ]; then
  echo "Template dir exists: $HOME/.git_template"
else
  echo "Would create template dir: $HOME/.git_template"
fi

# 4) Bash profile setup
section "Bash profile"
if [ -f "$HOME/.bash_profile" ]; then
  if grep -q "DOTFILES_DIR.*dotfiles" "$HOME/.bash_profile" 2>/dev/null && \
     grep -q "shell/bash/bash_profile" "$HOME/.bash_profile" 2>/dev/null; then
    echo "Bash profile already configured to source from dotfiles"
  else
    echo "Would update $HOME/.bash_profile to source from dotfiles"
  fi
else
  echo "Would create $HOME/.bash_profile"
fi

# Check for old shell configs that should be cleaned up
section "Shell cleanup check"
OLD_FILES=("$HOME/.zprofile" "$HOME/.zsh_aliases" "$HOME/.local/bin/env")
FOUND_OLD=0
for f in "${OLD_FILES[@]}"; do
  if [ -e "$f" ]; then
    echo "Found old file that should be cleaned: $f"
    FOUND_OLD=1
  fi
done
if [ $FOUND_OLD -eq 0 ]; then
  echo "No old shell configs found (clean)"
fi

echo ""
echo "==> Dry-run complete. No changes were made."
