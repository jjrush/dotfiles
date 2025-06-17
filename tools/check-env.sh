#!/bin/bash
# check-env.sh
# This script checks consistency of key environment variables across all .env files
# in a given directory.
#
# Usage: ./check-env.sh /path/to/config-directory

# Enable nullglob so that non-matching globs expand to an empty list.
shopt -s nullglob

# Define color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Check for directory parameter
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

CONFIG_DIR="$1"
if [ ! -d "$CONFIG_DIR" ]; then
  echo -e "${RED}Error: Directory '$CONFIG_DIR' does not exist.${NC}"
  exit 1
fi

# Collect .env files in the specified directory
env_files=("$CONFIG_DIR"/*.env)
if [ ${#env_files[@]} -eq 0 ]; then
  echo -e "${RED}No .env files found in $CONFIG_DIR.${NC}"
  exit 1
fi

echo "=== Checking .env files in $CONFIG_DIR ==="

# Declare associative arrays to store variable values keyed by file
declare -A db_passwords
declare -A postgres_passwords
declare -A redis_passwords
declare -A redis_cache_passwords

# Loop over each .env file
for file in "${env_files[@]}"; do
  # echo "Processing $file"
  
  # Extract DB_PASSWORD if present
  if grep -q '^DB_PASSWORD=' "$file"; then
    value=$(grep '^DB_PASSWORD=' "$file" | cut -d '=' -f2-)
    db_passwords["$file"]="$value"
  fi
  
  # Extract POSTGRES_PASSWORD if present
  if grep -q '^POSTGRES_PASSWORD=' "$file"; then
    value=$(grep '^POSTGRES_PASSWORD=' "$file" | cut -d '=' -f2-)
    postgres_passwords["$file"]="$value"
  fi
  
  # Extract REDIS_PASSWORD if present
  if grep -q '^REDIS_PASSWORD=' "$file"; then
    value=$(grep '^REDIS_PASSWORD=' "$file" | cut -d '=' -f2-)
    redis_passwords["$file"]="$value"
  fi
  
  # Extract REDIS_CACHE_PASSWORD if present
  if grep -q '^REDIS_CACHE_PASSWORD=' "$file"; then
    value=$(grep '^REDIS_CACHE_PASSWORD=' "$file" | cut -d '=' -f2-)
    redis_cache_passwords["$file"]="$value"
  fi
done

echo ""

# Function to check consistency of values in an associative array.
check_consistency() {
  local -n arr=$1
  local var_name=$2
  local first=""
  local consistent=1
  echo "$var_name values:"
  for file in "${!arr[@]}"; do
    echo "  $file: ${arr[$file]}"
    if [ -z "$first" ]; then
      first="${arr[$file]}"
    else
      if [ "$first" != "${arr[$file]}" ]; then
        consistent=0
      fi
    fi
  done
  if [ $consistent -eq 1 ]; then
    echo -e "${GREEN}$var_name is consistent: $first${NC}"
  else
    echo -e "${RED}$var_name is inconsistent!${NC}"
  fi
  echo ""
}

# Check each variable group if found
[ ${#db_passwords[@]} -gt 0 ] && check_consistency db_passwords "DB_PASSWORD"
[ ${#postgres_passwords[@]} -gt 0 ] && check_consistency postgres_passwords "POSTGRES_PASSWORD"
[ ${#redis_passwords[@]} -gt 0 ] && check_consistency redis_passwords "REDIS_PASSWORD"
[ ${#redis_cache_passwords[@]} -gt 0 ] && check_consistency redis_cache_passwords "REDIS_CACHE_PASSWORD"

echo "Done."
