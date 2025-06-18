#!/usr/bin/env bash

# zeek_runner.sh — A convenience wrapper for running Zeek against either
# BinPAC or Spicy based analyzers that live somewhere below
#   $WORK_ROOT/parsers/
#
# Features:
#   * Detects whether the current repository is a Spicy or BinPAC plugin.
#   * Temporarily sets ZEEK_PLUGIN_PATH to the repository root.
#   * Can build the plugin with the --build flag.
#   * Automates construction of command-line parameters for Zeek.
#   * Provides easy pcap pattern matching and argument pass-through.
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- helper functions ---------------------------------------------------------
usage() {
    cat <<'USAGE'

zeek_runner.sh (zr) - Run Zeek against BinPAC or Spicy plugins

Usage:
  zr [--build] [--list|-l] [--find|-f]
     [--target <icsnpp/foo>] [--hlto <file> --scripts <file>]
     --pcap <pattern|index> [--] <extra zeek args>

Flags:
  --build           Build (cmake && make) before running
  --list,  -l       List available parser directories ($WORK_ROOT/parsers)
  --find,  -f       List pcaps under the current repository with indices
  --pcap <pat|idx>  Required pattern or numeric index identifying a pcap
  --target <str>    Override BinPAC target (icsnpp/<name>)
  --hlto <file>     Path to .hlto file (Spicy)
  --scripts <file>  Path to __load__.zeek (Spicy)
  -h, --help        Show this help
  --                End option parsing; remaining args go to Zeek

Examples:
  zr -f                         # show pcaps with numbers
  zr --pcap 0 -- -B             # run on first pcap, forward -B to Zeek
  zr --build --p auth           # build then run on pcap matching 'auth'

USAGE
}

echo_err() {
    echo -e "${BLUE}[zeek_runner]${NC} $*" >&2
}

die() {
    echo -e "${RED}[zeek_runner]${NC} $1" >&2; exit 1
}

# Explanation helper -----------------------------------------------------------
explain() {
    cat <<'EXPLAIN'

Why does zr/zeek_runner exist?
+--------------------------------
• BinPAC plugins - compiled with the classic Zeek plugin skeleton:
    zeek icsnpp/<plugin-name> -Cr <file.pcap>

  Build step:   ./configure && make

• Spicy plugins - load a compiled HLTO (the parser) *and* the corresponding
  Zeek scripts that export events/protocol logic:
    zeek build/<something>.hlto scripts/__load__.zeek -Cr <file.pcap>

  Build step:   mkdir build && cd build && cmake .. && make

zr abstracts these differences so you can simply:

    zr --pcap <pattern-or-index>

and it will:
  1. Detect whether the repo is Spicy (looks for .spicy/.hlto files) or BinPAC.
  2. Temporarily set ZEEK_PLUGIN_PATH so Zeek finds the freshly-built plugin
     without installing it system-wide.
  3. Build the plugin when you pass --build (running ./configure for BinPAC
     if present, otherwise CMake for Spicy).
  4. Find a matching pcap (or use an index from --find) so you don't have
     to type long paths.
  5. Forward any extra flags after "--" straight to Zeek.

Shortcuts & discovery:
  zr -l            # list all parser repos in $WORK_ROOT/parsers
  zr -f            # list pcaps in the current repo with indices
  zr --pcap 3      # use the 3rd pcap from that list

That's it—no more looking up how to build/run each flavour.

EXPLAIN
}

# Ascend the directory tree until we hit a directory containing CMakeLists.txt
# (the presumed repository root) or $WORK_ROOT/parsers.
find_repo_root() {
    local dir="$1"
    local last=""
    while [[ "$dir" != "$last" ]]; do
        [[ -f "$dir/CMakeLists.txt" ]] && { echo "$dir"; return; }
        [[ "$dir" == "$WORK_ROOT/parsers" ]] && { echo "$dir"; return; }
        last="$dir"; dir="$(dirname "$dir")"
    done
    die "Failed to locate repository root (CMakeLists.txt not found)."
}

is_spicy_repo() {
    # Treat the repository as Spicy if it contains any *.spicy source files.
    # Using Bash's recursive globbing avoids 'permission denied' errors that can
    # arise with `find`. We enable `globstar` briefly for this check.
    shopt -s globstar nullglob
    local spicy_files=( "$1"/**/*.spicy )
    shopt -u globstar nullglob
    (( ${#spicy_files[@]} > 0 ))
}

search_pcap() {
    local repo="$1" pattern="$2"
    local match
    # If pattern is a non-negative integer, treat as index.
    if [[ "$pattern" =~ ^[0-9]+$ ]]; then
        local pcaps_array
        mapfile -t pcaps_array < <(gather_pcaps "$repo")
        local idx=$pattern
        if (( idx < 0 || idx >= ${#pcaps_array[@]} )); then
            die "Index $idx is out of range (0-${#pcaps_array[@]}). Use --find to list indices."
        fi
        echo "${pcaps_array[$idx]}"
        return 0
    fi
    # Search common directories first.
    match=$(gather_pcaps "$repo" | grep -i "$pattern" || true)
    if [[ -z "$match" ]]; then
        die "No pcap matching '$pattern' found under $repo."
    fi
    # If multiple, pick first and warn.
    local count; count=$(echo "$match" | wc -l)
    if (( count > 1 )); then
        echo_err "Multiple pcaps match '$pattern'; choosing first. Use --pcap with a more specific pattern."
    fi
    echo "$(echo "$match" | head -n1)"
}

# gather_pcaps(): collect up to 100 pcap/pcapng files for consistent ordering
gather_pcaps() {
    local base="$1"
    # Recursively search for capture files under the supplied base directory.
    # We keep the output deterministic (sorted) and limit it to the first 100
    # hits to avoid overwhelming the display.
    find "$base" -type f -regextype posix-extended -regex ".*\\.(pcap|pcapng)$" -print 2>/dev/null |
        sort | head -n 100
}

# Pretty listing helpers -------------------------------------------------------

list_parsers() {
    local base="${WORK_ROOT}/parsers"
    [[ -d "$base" ]] || die "Directory $base does not exist."
    echo -e "${GREEN}Available parsers in $base:${NC}"
    for dir in "$base"/*; do
        [[ -d "$dir" ]] || continue
        local name="$(basename "$dir")"
        local type
        if is_spicy_repo "$dir"; then type="spicy"; else type="binpac"; fi
        echo -e "  ${YELLOW}${name}${NC} ($type)"
    done
}

find_pcaps_in_dir() {
    local dir="$1"
    echo -e "${GREEN}PCAP files under $dir:${NC}"

    # Read all pcap paths into an array to avoid edge-cases with here-strings
    # when the final line lacks a trailing newline (common with command
    # substitution). Using an array guarantees we iterate over every entry.
    local -a pcaps_array
    mapfile -t pcaps_array < <(gather_pcaps "$dir")

    if (( ${#pcaps_array[@]} == 0 )); then
        echo -e "${RED}  (none found)${NC}"
        return 1
    fi

    for idx in "${!pcaps_array[@]}"; do
        local file="${pcaps_array[$idx]}"
        local size
        size=$(du -h "$file" | cut -f1)
        echo -e "  [${idx}] ${BLUE}${file}${NC} ${YELLOW}($size)${NC}"
    done
}

# --- argument parsing ---------------------------------------------------------
BUILD=0
TARGET=""
HLTO=""
SCRIPTS=""
PCAP_PATTERN=""
EXTRA_ZEEK_ARGS=()
LIST_PARSERS=0
SHOW_PCAPS=0
SHOW_EXPLAIN=0

PARSE_EXTRA=0
while (( $# > 0 )); do
    if (( PARSE_EXTRA )); then
        EXTRA_ZEEK_ARGS+=("$1"); shift; continue
    fi
    case "$1" in
        --build)    BUILD=1; shift;;
        --target)   TARGET="$2"; shift 2;;
        --hlto)     HLTO="$2"; shift 2;;
        --scripts)  SCRIPTS="$2"; shift 2;;
        --pcap|-p)  PCAP_PATTERN="$2"; shift 2;;
        --list|-l)  LIST_PARSERS=1; shift;;
        --find|-f)  SHOW_PCAPS=1; shift;;
        --explain)  SHOW_EXPLAIN=1; shift;;
        -h|--help)  usage; exit 0;;
        --)         PARSE_EXTRA=1; shift;;
        *)          # Unknown option, treat as passthrough
                    EXTRA_ZEEK_ARGS+=("$1"); shift;;
    esac
done

if (( LIST_PARSERS )); then
    list_parsers
    exit 0
fi

if (( SHOW_EXPLAIN )); then
    explain
    exit 0
fi

# Determine repository root based on the caller's *current* directory, not the
# location of this helper script. This allows `zr` to live anywhere on the
# $PATH while still correctly identifying the plugin repository the user is
# working inside of.
REPO_ROOT="$(find_repo_root "$(pwd)")"

# Validate location: ensure inside $WORK_ROOT/parsers
[[ "${REPO_ROOT}" != ${WORK_ROOT}/parsers/* ]] && \
    die "Repository root '$REPO_ROOT' is not inside ${WORK_ROOT}/parsers."

if (( SHOW_PCAPS )); then
    find_pcaps_in_dir "$REPO_ROOT"
    exit 0
fi

[[ -z "$PCAP_PATTERN" ]] && die "--pcap is required."

echo_err "Repository root detected: $REPO_ROOT"

# Build if requested.
if (( BUILD )); then
    echo_err "Building plugin..."
    pushd "$REPO_ROOT" >/dev/null
    if [[ -x ./configure ]]; then
        # Typical BinPAC plugin build chain (configure && make)
        echo_err "Found ./configure - running classical build sequence."
        ./configure
        pushd build >/dev/null
        make -j"$(nproc)"
        popd >/dev/null
    else
        # CMake-style build directory (Spicy or modern plugins)
        mkdir -p build && pushd build >/dev/null
        cmake ..
        make -j"$(nproc)"
        popd >/dev/null
    fi
    popd >/dev/null
fi

# Detect plugin type if needed.
if is_spicy_repo "$REPO_ROOT"; then
    TYPE="spicy"
else
    TYPE="binpac"
fi

echo_err "Detected plugin type: $TYPE"

# Prepare Zeek command parts depending on type.
if [[ "$TYPE" == "spicy" ]]; then
    # Discover .hlto
    if [[ -z "$HLTO" ]]; then
        # Look for a compiled HLTO somewhere under the build directory (up to 4
        # levels deep), again silencing any permission errors.
        HLTO=$(find "$REPO_ROOT/build" -maxdepth 4 -name '*.hlto' -print -quit 2>/dev/null || true)
        if [[ -z "$HLTO" ]]; then
            die "No .hlto file found under build/. The plugin may not be built yet. Run 'zr --build --pcap <file>' (or build manually) and try again, or use --hlto to specify the path explicitly."
        fi
    fi
    [[ ! -f "$HLTO" ]] && die "HLTO file '$HLTO' not found."

    # Discover scripts path
    if [[ -z "$SCRIPTS" ]]; then
        SCRIPTS=$(find "$REPO_ROOT" -name '__load__.zeek' -print -quit 2>/dev/null || true)
        [[ -z "$SCRIPTS" ]] && die "Could not locate __load__.zeek. Use --scripts to specify."
    fi
    [[ ! -f "$SCRIPTS" ]] && die "Zeek script '$SCRIPTS' not found."

    ZEEK_MAIN_ARGS=("$HLTO" "$SCRIPTS")
else
    # BinPAC target path
    if [[ -z "$TARGET" ]]; then
        repo_name="$(basename "$REPO_ROOT")"

        # If the directory name starts with the common "icsnpp-" prefix, drop it
        # so we don't end up with "icsnpp/icsnpp-foo".
        repo_name="${repo_name#icsnpp-}"

        # Replace invalid characters while preserving hyphens so that names like
        #   "icsnpp-opcua-binary" -> "opcua-binary" (hyphen intact).  We:
        #  * convert '+' to '_' (common in some repo names)
        #  * convert any remaining character that's *not* alnum, hyphen, or
        #    underscore to '_'
        #  * collapse multiple consecutive underscores
        #  * trim leading/trailing underscores or hyphens for neatness
        repo_name="$(echo "$repo_name" |
            sed -e 's/+/_/g' -e 's/[^A-Za-z0-9_-]/_/g' \
                -e 's/__*/_/g' -e 's/^[_-]\+//' -e 's/[_-]\+$//')"

        TARGET="icsnpp/${repo_name}"
    fi
    ZEEK_MAIN_ARGS=("$TARGET")
fi

# Resolve pcap file
PCAP_FILE=$(search_pcap "$REPO_ROOT" "$PCAP_PATTERN")

echo_err "Using pcap: $PCAP_FILE"

# Assemble full command
ZEEK_CMD=(zeek "${ZEEK_MAIN_ARGS[@]}" -Cr "$PCAP_FILE" "${EXTRA_ZEEK_ARGS[@]}")

echo_err "Running: ${ZEEK_CMD[*]}"

# Export plugin path, preserving previous value
PREV_ZEEK_PLUGIN_PATH="${ZEEK_PLUGIN_PATH:-}"
if [[ "$TYPE" == "binpac" ]]; then
    # BinPAC plugins live at the repository root, so we expose that via
    # ZEEK_PLUGIN_PATH.  Spicy analyzers don't need this and leaving it unset
    # avoids permission-denied warnings when Zeek walks the directory tree.
    export ZEEK_PLUGIN_PATH="$REPO_ROOT"
fi

# --- run ----------------------------------------------------------------------
"${ZEEK_CMD[@]}"
STATUS=$?

# Restore previous ZEEK_PLUGIN_PATH
if [[ -z "${PREV_ZEEK_PLUGIN_PATH}" ]]; then
    unset ZEEK_PLUGIN_PATH
else
    export ZEEK_PLUGIN_PATH="$PREV_ZEEK_PLUGIN_PATH"
fi

exit $STATUS