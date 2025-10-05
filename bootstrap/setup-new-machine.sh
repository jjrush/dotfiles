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

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║            Dotfiles Setup - New Machine                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# --- Main Setup Logic ------------------------------------------------------

# 1. Check and install missing dependencies
step "Checking for required tools..."
bash "$DOTFILES_DIR/bootstrap/check_dependencies.sh"
echo ""

# 2. Link custom tools into ~/bin
step "Linking custom tools..."
bash "$DOTFILES_DIR/bootstrap/link_tools.sh"
echo ""

# 3. Configure Git (idempotent)
step "Configuring Git (global) via dotfiles include..."
bash "$DOTFILES_DIR/bootstrap/configure_git.sh"
echo ""

# 4. Setup shell profile (bash-only)
step "Setting up bash profile..."
bash "$DOTFILES_DIR/bootstrap/setup_shell.sh"
echo ""

# 5. Validate system state
step "Validating system configuration..."
bash "$DOTFILES_DIR/bootstrap/sync.sh"
echo ""

info "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. If not using bash: chsh -s /bin/bash"
echo "  2. Close this terminal and open a new one"
echo "  3. Enjoy your dotfiles!"
echo ""
