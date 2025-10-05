#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 50_zeek.sh - Configurations for the Zeek Network Security Monitor
# ---------------------------------------------------------------------------

# Alias to ensure the user-mode zkg is used
alias zkg="command zkg --user"

# Source the zkg environment file if it exists
if [ -f "$HOME/.zkg/env.sh" ]; then
  source "$HOME/.zkg/env.sh"
fi
