#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/check_dependencies.sh – Check for missing tools/dependencies
# ---------------------------------------------------------------------------
# Checks if tools used by aliases/functions are installed.
# Prompts to install missing packages via brew (macOS) or apt (Linux).
# ---------------------------------------------------------------------------
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==> Checking for missing dependencies..."
echo ""

# Map of command → package name (if different)
declare -a TOOL_CHECKS=(
  "fd:fd"
  "bat:bat"
  "eza:eza"
  "rg:ripgrep"
  "gh:gh"
  "jq:jq"
)

missing_tools=()

for check in "${TOOL_CHECKS[@]}"; do
  cmd="${check%%:*}"
  pkg="${check#*:}"

  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $cmd"
  else
    echo -e "${RED}✗${NC} $cmd (missing)"
    missing_tools+=("$pkg")
  fi
done

echo ""

if [ ${#missing_tools[@]} -eq 0 ]; then
  echo -e "${GREEN}All required tools are installed!${NC}"
  exit 0
fi

# Show missing packages
echo -e "${YELLOW}Missing packages:${NC} ${missing_tools[*]}"
echo ""

# Offer to install based on OS
case "$OS" in
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      echo -e "${RED}Error: Homebrew not found.${NC}"
      echo "Install Homebrew from https://brew.sh then run this script again."
      exit 1
    fi

    echo "Install missing packages with Homebrew?"
    echo -e "${YELLOW}Command:${NC} brew install ${missing_tools[*]}"
    read -p "Proceed? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      brew install "${missing_tools[@]}"
      echo ""
      echo -e "${GREEN}Installation complete!${NC}"
    else
      echo "Skipped. You can install manually with:"
      echo "  brew install ${missing_tools[*]}"
    fi
    ;;

  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      echo "Install missing packages with apt?"
      echo -e "${YELLOW}Command:${NC} sudo apt-get install ${missing_tools[*]}"
      read -p "Proceed? (y/N) " -n 1 -r
      echo

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y "${missing_tools[@]}"
        echo ""
        echo -e "${GREEN}Installation complete!${NC}"
      else
        echo "Skipped. You can install manually with:"
        echo "  sudo apt-get install ${missing_tools[*]}"
      fi
    else
      echo "Package manager not found. Please install manually:"
      echo "  ${missing_tools[*]}"
    fi
    ;;

  *)
    echo "Unsupported OS: $OS"
    echo "Please install manually: ${missing_tools[*]}"
    exit 1
    ;;
esac
