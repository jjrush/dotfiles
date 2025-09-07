#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/update-package-lists.darwin.sh - Update packages.brew
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" # cd to bootstrap dir

if ! command -v brew &> /dev/null; then
    echo "brew command not found. Is Homebrew installed?" >&2
    exit 1
fi

brew list --formula > packages.brew
echo "Updated packages.brew"
