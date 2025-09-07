#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/setup-new-machine.sh - Full system setup script
# ---------------------------------------------------------------------------
set -euo pipefail

# --- Helper Functions ------------------------------------------------------
step() { printf '\e[1;34m==> %s\e[0m\n' "$*"; }
warn() { printf '\e[1;33mWarning: %s\e[0m\n' "$*"; }
info() { printf '\e[1;32m%s\e[0m\n' "$*"; }

# --- Configuration ---------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIX_CONFIG_DIR="$HOME/nix-config"

# --- Main Setup Logic ------------------------------------------------------

# 1. Install System Packages (apt or brew)
step "Installing system packages for $(uname -s)..."
case "$(uname -s)" in
  Linux)
    if ! command -v apt-get &> /dev/null; then
        warn "apt-get not found. Skipping system package installation."
    else
        sudo apt-get update
        sudo apt-get install -y $(cat "$DOTFILES_DIR/bootstrap/packages.apt")
    fi
    ;;
  Darwin)
    if ! command -v brew &> /dev/null; then
        warn "Homebrew not found. Please install it first: https://brew.sh"
    else
        brew install $(cat "$DOTFILES_DIR/bootstrap/packages.brew")
    fi
    ;;
  *)
    warn "Unsupported OS: $(uname -s). Skipping system package installation."
    ;;
esac

# 2. Install Nix Package Manager
step "Checking for Nix installation..."
if ! command -v nix &> /dev/null; then
    info "Nix not found. Installing now..."
    curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
    
    # Source Nix for the current shell session
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    
    # Enable flakes
    mkdir -p "$HOME/.config/nix"
    echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
else
    info "Nix is already installed."
fi

# 3. Link custom tools into ~/bin
step "Linking custom tools..."
bash "$DOTFILES_DIR/bootstrap/link_tools.sh"

# 4. Apply Nix Configuration
step "Applying Nix configuration from $NIX_CONFIG_DIR..."
if [ ! -d "$NIX_CONFIG_DIR" ]; then
    warn "Nix config directory not found at $NIX_CONFIG_DIR."
    warn "Please clone it first: git clone <your-repo-url> $NIX_CONFIG_DIR"
else
    # Source the nix profile again to ensure nix command is available
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    nix run home-manager/master -- --flake "$NIX_CONFIG_DIR#rush" switch
fi

info "\nSetup complete! Please open a new terminal session."
