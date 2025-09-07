#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap/update-package-lists.linux.sh - Update packages.apt
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" # cd to bootstrap dir

if ! command -v apt-mark &> /dev/null; then
    echo "apt-mark command not found. Are you on a Debian-based system?" >&2
    exit 1
fi

apt-mark showmanual > packages.apt
echo "Updated packages.apt"
