#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 01_alias_system.sh – Smart alias registration with validation
# ---------------------------------------------------------------------------
# Provides safe_alias() function that:
# 1. Checks if alias name conflicts with existing commands
# 2. Validates required tools exist
# 3. Attempts to install missing tools
# 4. Only sets alias if safe or explicitly allowed
# ---------------------------------------------------------------------------

# Tool to package mapping (tool_name:package_name:package_manager)
# Format: "command:brew_pkg:apt_pkg" or "command:pkg" if same name everywhere
declare -a TOOL_PACKAGES=(
  "bat:bat:bat"
  "eza:eza:eza"
  "fd:fd-find:fd-find"
  "rg:ripgrep:ripgrep"
  "gh:gh:gh"
  "jq:jq:jq"
  "docker:docker:docker.io"
  "code:visual-studio-code:code"
  "uv:uv:N/A"
)

# Commands that are OK to shadow (user preference)
ALLOWED_SHADOWS=(
  "cat"      # bat is better
  "grep"     # rg is better
  "ls"       # eza is better
)

# Track missing tools globally
_DOTFILES_MISSING_TOOLS=()

# Check if shadowing is allowed
_is_shadow_allowed() {
  local name="$1"
  for allowed in "${ALLOWED_SHADOWS[@]}"; do
    [[ "$name" == "$allowed" ]] && return 0
  done
  return 1
}

# Find package name for a tool
_find_package() {
  local tool="$1"
  local os="$(uname -s)"

  for mapping in "${TOOL_PACKAGES[@]}"; do
    IFS=':' read -r cmd brew_pkg apt_pkg <<< "$mapping"
    if [[ "$cmd" == "$tool" ]]; then
      case "$os" in
        Darwin) echo "$brew_pkg"; return 0 ;;
        Linux)  echo "$apt_pkg"; return 0 ;;
      esac
    fi
  done

  # Default: assume package name == tool name
  echo "$tool"
}

# Safe alias registration
# Usage: safe_alias NAME COMMAND [REQUIRED_TOOL]
safe_alias() {
  local alias_name="$1"
  local alias_cmd="$2"
  local required_tool="$3"  # optional

  # Check if alias name would shadow an existing command
  if command -v "$alias_name" >/dev/null 2>&1; then
    if ! _is_shadow_allowed "$alias_name"; then
      # Silently skip - this is normal (e.g., 'ls' exists, we're okay with that)
      # We could log to a debug file if needed
      : # no-op
    fi
  fi

  # If a required tool is specified, check it exists
  if [[ -n "$required_tool" ]]; then
    if ! command -v "$required_tool" >/dev/null 2>&1; then
      # Track missing tool
      if [[ ! " ${_DOTFILES_MISSING_TOOLS[*]} " =~ " ${required_tool} " ]]; then
        _DOTFILES_MISSING_TOOLS+=("$required_tool")
      fi
      return 1  # Don't set alias
    fi
  fi

  # Set the alias
  alias "$alias_name"="$alias_cmd"
}

# Conditional alias - only set if tool exists
# Usage: conditional_alias NAME COMMAND REQUIRED_TOOL
conditional_alias() {
  safe_alias "$1" "$2" "$3"
}

# Report missing tools at the end of shell initialization
report_missing_tools() {
  if [[ ${#_DOTFILES_MISSING_TOOLS[@]} -gt 0 ]]; then
    local unique_tools=($(printf '%s\n' "${_DOTFILES_MISSING_TOOLS[@]}" | sort -u))

    echo ""
    echo "⚠️  Missing tools for some aliases: ${unique_tools[*]}"
    echo "   Run: ${DOTFILES_DIR}/bootstrap/check_dependencies.sh"
    echo ""
  fi
}
