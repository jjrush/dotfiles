#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/sync.sh - Sync dotfiles and validate system state
# ---------------------------------------------------------------------------
# Run this after 'git pull' to ensure your system is up to date.
# Validates dependencies, symlinks, and configuration.
# ---------------------------------------------------------------------------
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

step() { printf "${BLUE}==> %s${NC}\n" "$*"; }
ok() { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${NC}  %s\n" "$*"; }
error() { printf "${RED}✗${NC} %s\n" "$*"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUES=0

echo ""
step "Syncing dotfiles and validating system state..."
echo ""

# 1. Check dependencies
step "Checking dependencies..."
if bash "$DOTFILES_DIR/bootstrap/check_dependencies.sh"; then
  ok "All required tools installed"
else
  warn "Some tools are missing (see above)"
  ((ISSUES++))
fi
echo ""

# 2. Validate symlinks
step "Validating tool symlinks..."
EXPECTED_LINKS=(
  "trim:remove_trailing_whitespace.sh"
  "zeek_runner:zeek_runner.sh"
  "check:check-env.sh"
)

for mapping in "${EXPECTED_LINKS[@]}"; do
  link="${mapping%%:*}"
  source_file="${mapping#*:}"
  link_path="$HOME/bin/$link"
  expected_target="$DOTFILES_DIR/tools/$source_file"

  if [ -L "$link_path" ]; then
    actual_target="$(readlink "$link_path")"
    if [ "$actual_target" = "$expected_target" ]; then
      ok "~/bin/$link → correct"
    else
      error "~/bin/$link → wrong target"
      ((ISSUES++))
    fi
  else
    error "~/bin/$link → missing or not a symlink"
    ((ISSUES++))
  fi
done
echo ""

# 3. Validate shell config
step "Validating shell configuration..."
if [ -f "$HOME/.bash_profile" ]; then
  if grep -q "dotfiles/shell/bashrc" "$HOME/.bash_profile"; then
    ok ".bash_profile configured correctly"
  else
    error ".bash_profile not configured correctly"
    ((ISSUES++))
  fi
else
  error ".bash_profile missing"
  ((ISSUES++))
fi

if [ "$SHELL" = "/bin/bash" ]; then
  ok "Default shell is bash"
else
  warn "Default shell is $SHELL (should be /bin/bash)"
  warn "Run: chsh -s /bin/bash"
  ((ISSUES++))
fi
echo ""

# 4. Validate git config
step "Validating git configuration..."
GITCONFIG="$DOTFILES_DIR/git/config/main.gitconfig"
if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$GITCONFIG"; then
  ok "Git includes dotfiles config"
else
  error "Git not configured to include dotfiles"
  warn "Run: bash $DOTFILES_DIR/bootstrap/configure_git.sh"
  ((ISSUES++))
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ISSUES -eq 0 ]; then
  echo -e "${GREEN}✓ System is fully synced and validated!${NC}"
  echo ""
  echo "Your dotfiles are up to date and working correctly."
else
  echo -e "${YELLOW}⚠ Found $ISSUES issue(s) - see details above${NC}"
  echo ""
  echo "Run the suggested commands to fix the issues."
  exit 1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
