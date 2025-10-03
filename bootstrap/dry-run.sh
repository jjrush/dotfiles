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
      mapfile -t missing < <(comm -23 \
        <(grep -v '^\s*$' "$DOTFILES_DIR/bootstrap/packages.apt" | sort -u) \
        <(dpkg-query -W -f='${Package}\n' 2>/dev/null | sort -u))
      if [ ${#missing[@]} -gt 0 ]; then
        printf "Would install (apt): %s\n" "${missing[*]}"
      else
        echo "All listed apt packages appear installed."
      fi
    else
      echo "apt-get not found; skipping apt package check."
    fi
    ;;
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      mapfile -t missing < <(comm -23 \
        <(grep -v '^\s*$' "$DOTFILES_DIR/bootstrap/packages.brew" | sort -u) \
        <(brew list --formula | sort -u))
      if [ ${#missing[@]} -gt 0 ]; then
        printf "Would install (brew): %s\n" "${missing[*]}"
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

# 2) Nix install + flakes
section "Nix + flakes"
if command -v nix >/dev/null 2>&1; then
  echo "nix is installed."
else
  echo "Would install nix (not installed)."
fi
mkdir -p "$HOME/.config/nix" >/dev/null 2>&1 || true
if grep -Fxq "experimental-features = nix-command flakes" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
  echo "Flakes already enabled."
else
  echo "Would enable flakes in ~/.config/nix/nix.conf"
fi

# 3) Tool links
section "Tool links"
DRY_RUN=1 bash "$DOTFILES_DIR/bootstrap/link_tools.sh"

# 4) Git include + template dir
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

echo "\n==> Dry-run complete. No changes were made."
