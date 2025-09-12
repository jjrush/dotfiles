#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 60_nix.sh - Load Nix environment
# ---------------------------------------------------------------------------

# Load the Nix environment if it exists
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
