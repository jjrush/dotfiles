#!/bin/bash

# Exit on error inside pipeline, treat unset vars as error, and propagate failures
set -euo pipefail

############################################
# Configuration
############################################
# Lists of filenames (without dot prefix) for each platform and shared
LINUX_FILES=(bashrc bash_aliases bash_func)
MACOS_FILES=(zshrc zsh_aliases zsh_func)
SHARED_FILES=(docker_aliases shared_aliases shared_functions shared_rc)

############################################
# Helper functions
############################################
# copy_file <src> <dst>
# Performs a recursive, attribute-preserving copy and prints a ✔︎/✘ indicator.
copy_file() {
    local src=$1 dst=$2
    if cp -a "$src" "$dst" 2>/dev/null; then
        echo "✔︎ Copied $src → $dst"
    else
        echo "✘ Failed to copy $src" >&2
        return 1
    fi
}

mk_target_dir() {
    local dir=$1
    [[ -d $dir ]] || mkdir -p "$dir"
}

# NEW: detect if two files differ (ignores if either is missing)
files_differ() {
    local f1=$1 f2=$2
    [[ -f "$f1" && -f "$f2" ]] && ! cmp -s "$f1" "$f2"
}

# NEW: before overwriting during restore, back up the destination if it diverges
backup_if_different() {
    local src=$1 dst=$2
    if files_differ "$src" "$dst"; then
        local ts
        ts=$(date +%Y%m%d%H%M%S)
        local bak="${dst}.pre-restore-${ts}"
        echo "⚠︎ $dst differs from repo; backing up to $bak"
        cp -a "$dst" "$bak"
    fi
}

# NEW: show which files in ~ differ from the repo versions
status_dotfiles() {
    local dotfiles_dir="$HOME/dotfiles"
    local platform_files source_dir

    if [[ "${OSTYPE}" == "darwin"* ]]; then
        platform_files=("${MACOS_FILES[@]}")
        source_dir="$dotfiles_dir/macos"
    else
        platform_files=("${LINUX_FILES[@]}")
        source_dir="$dotfiles_dir/linux"
    fi
    local shared_dir="$dotfiles_dir/shared"

    local changed=0

    for f in "${platform_files[@]}"; do
        local repo="$source_dir/${f}"
        local home="$HOME/.${f}"
        if files_differ "$repo" "$home"; then
            echo "modified: .${f}"
            changed=1
        fi
    done

    for f in "${SHARED_FILES[@]}"; do
        local repo="$shared_dir/${f}"
        local home="$HOME/${f}"
        if files_differ "$repo" "$home"; then
            echo "modified: ${f}"
            changed=1
        fi
    done

    if [[ $changed -eq 0 ]]; then
        echo "No local modifications detected."
    fi
    return $changed
}

############################################
# backup_dotfiles – copies the user's current files into the repo
############################################
backup_dotfiles() {
    local dotfiles_dir="$HOME/dotfiles"
    local failed=0

    # Determine platform-specific settings
    local platform_files target_dir
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        platform_files=("${MACOS_FILES[@]}")
        target_dir="$dotfiles_dir/macos"
    else
        platform_files=("${LINUX_FILES[@]}")
        target_dir="$dotfiles_dir/linux"
    fi
    local shared_dir="$dotfiles_dir/shared"

    # Ensure directories exist
    mk_target_dir "$target_dir"
    mk_target_dir "$shared_dir"

    # Copy platform-specific dotfiles
    for f in "${platform_files[@]}"; do
        local src="$HOME/.${f}"
        local dst="$target_dir/${f}"
        [[ -f "$src" ]] && copy_file "$src" "$dst" || echo "(skip) $src not found"
    done

    # Copy shared files (no leading dot in home)
    for f in "${SHARED_FILES[@]}"; do
        local src="$HOME/${f}"
        local dst="$shared_dir/${f}"
        [[ -f "$src" ]] && copy_file "$src" "$dst" || echo "(skip) $src not found"
    done

    echo "Backup completed!"
    return $failed
}

############################################
# restore_dotfiles – copies the repo versions into the user's home
############################################
restore_dotfiles() {
    local dotfiles_dir="$HOME/dotfiles"
    local failed=0

    # Determine platform-specific settings
    local platform_files source_dir
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        platform_files=("${MACOS_FILES[@]}")
        source_dir="$dotfiles_dir/macos"
    else
        platform_files=("${LINUX_FILES[@]}")
        source_dir="$dotfiles_dir/linux"
    fi
    local shared_dir="$dotfiles_dir/shared"

    # Copy platform-specific files
    for f in "${platform_files[@]}"; do
        local src="$source_dir/${f}"
        local dst="$HOME/.${f}"
        if [[ -f "$src" ]]; then
            backup_if_different "$src" "$dst"
            copy_file "$src" "$dst"
        else
            echo "(skip) $src not found"
        fi
    done

    # Copy shared files
    for f in "${SHARED_FILES[@]}"; do
        local src="$shared_dir/${f}"
        local dst="$HOME/${f}"
        if [[ -f "$src" ]]; then
            backup_if_different "$src" "$dst"
            copy_file "$src" "$dst"
        else
            echo "(skip) $src not found"
        fi
    done

    echo "Restore completed!"
    return $failed
}

############################################
# Command-line interface
############################################
usage() {
    echo "Usage: $(basename "$0") {backup|restore|status}"
}

# If the script is executed directly (not sourced), dispatch CLI
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        backup)  backup_dotfiles ;;
        restore) restore_dotfiles ;;
        status)  status_dotfiles  ;;
        *) usage; exit 1 ;;
    esac
fi