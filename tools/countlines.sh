#!/usr/bin/env bash
# Count lines of code, comments, and blank lines in Python files recursively.

set -euo pipefail

TARGET_DIR=${1:-.}

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Directory '$TARGET_DIR' not found."
  exit 1
fi

echo "Scanning for Python files in '$TARGET_DIR'..."

tmp_prog="$(mktemp)"
cat >"$tmp_prog" <<'AWK'
BEGIN {
  code = comments = blanks = 0
}
# Reset docstring state at each new file
FNR == 1 { in_doc = 0 }

{
  line = $0
  sub(/\r$/, "", line)                               # strip CR
  trimmed = line
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", trimmed)

  if (trimmed == "") { blanks++; next }

  # NEW: treat a lone brace line as non-code (bucket it with blanks)
  if (!in_doc && trimmed ~ /^[{}]$/) { blanks++; next }

  # Pure line comment (only if not inside a docstring)
  if (!in_doc && trimmed ~ /^#/) { comments++; next }

  # Count occurrences of triple-double and triple-single quotes on this line
  tmp = line; dq = gsub(/"""/, "", tmp)
  tmp = line; sq = gsub(/'''/, "", tmp)
  toggles = dq + sq

  if (in_doc) {
    comments++
    if (toggles % 2 == 1) in_doc = 0
    next
  }

  if (toggles > 0) {
    # Determine which triple-quote appears first on the line
    pos1 = index(line, "\"\"\"")
    pos2 = index(line, "'''")
    if (pos1 == 0) firstpos = pos2
    else if (pos2 == 0) firstpos = pos1
    else firstpos = (pos1 < pos2 ? pos1 : pos2)

    prefix = (firstpos > 1) ? substr(line, 1, firstpos - 1) : ""
    p = prefix
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", p)

    # If there is code before the first triple-quote, count as code; else comment
    if (p != "") code++; else comments++

    if (toggles % 2 == 1) in_doc = 1
    next
  }

  # Default: code (inline "# ..." after code still counts as code)
  code++
}

END {
  total = code + comments + blanks
  if (total == 0) {
    print "\nNo Python files found or no lines to count."
    exit
  }
  printf "\n------------------------------------------------\n"
  printf "  Lines of Code Statistics for Python Files\n"
  printf "------------------------------------------------\n"
  printf "%-20s %-15s %-15s\n", "Category", "Count", "Percentage"
  printf "------------------------------------------------\n"
  printf "%-20s %-15d %-15.2f%%\n", "Code", code, (code * 100.0) / total
  printf "%-20s %-15d %-15.2f%%\n", "Comments", comments, (comments * 100.0) / total
  printf "%-20s %-15d %-15.2f%%\n", "Blanks", blanks, (blanks * 100.0) / total
  printf "------------------------------------------------\n"
  printf "%-20s %-15d %-15.2f%%\n", "Total", total, 100.00
  printf "------------------------------------------------\n"
}
AWK

find "$TARGET_DIR" -type f -name "*.py" -print0 \
  | xargs -0 -r awk -f "$tmp_prog"

rm -f "$tmp_prog"
