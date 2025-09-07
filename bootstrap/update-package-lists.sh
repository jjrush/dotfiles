#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/update-package-lists.sh - Update package list for current OS
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" # cd to bootstrap dir

case "$(uname -s)" in
  Linux)
    echo "Updating apt package list..."
    bash ./update-package-lists.linux.sh
    ;;
  Darwin)
    echo "Updating Homebrew package list..."
    bash ./update-package-lists.darwin.sh
    ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

echo "Done."
