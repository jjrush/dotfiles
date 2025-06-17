#!/bin/bash

# Check if a file was provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    echo "       $0 -i <filename>  (to modify file in-place)"
    exit 1
fi

# Check if -i flag is provided for in-place editing
if [ "$1" = "-i" ]; then
    if [ $# -ne 2 ]; then
        echo "Error: When using -i, please provide a filename"
        echo "Usage: $0 -i <filename>"
        exit 1
    fi
    # Remove trailing whitespace and save directly to the file
    sed -i 's/[[:space:]]*$//' "$2"
    echo "Removed trailing whitespace from $2"
else
    # Output the file contents without trailing whitespace to stdout
    sed 's/[[:space:]]*$//' "$1"
fi 