#!/bin/bash
# md5-dict-check.sh
# Usage: ./md5-dict-check.sh <password-or-md5hash> <dictionary_file>
# Accepts either a plaintext password or a 32-character MD5 hash as first arg.
# Note: MD5 is insecure for password storage; this script is for learning/forensics only.

set -u

# Determine available md5 command (md5sum on Linux, md5 -q on macOS)
_md5_cmd() {
    if command -v md5sum >/dev/null 2>&1; then
        # use md5sum (prints "<hash>  -"), we will extract the hash
        echo "md5sum"
    elif command -v md5 >/dev/null 2>&1; then
        # macOS 'md5' supports '-q' to only output the hash
        echo "md5"
    else
        echo ""
    fi
}

hash_password() {
    local input="$1"
    local cmd="$MD5_TOOL"
    if [ "$cmd" = "md5sum" ]; then
        # md5sum prints: <hash>  -
        echo -n "$input" | md5sum | awk '{print $1}'
    elif [ "$cmd" = "md5" ]; then
        # macOS md5: `md5 -q` prints only the hash
        echo -n "$input" | md5 -q
    else
        # Shouldn't happen if we checked earlier
        echo "ERROR_NO_MD5_TOOL"
        return 2
    fi
}

usage() {
    cat <<EOF
Usage: $0 <password-or-md5hash> <dictionary_file>

First argument may be:
  - a plaintext password (script will compute its MD5), or
  - a 32-character hex MD5 hash (script will use it directly).

Example:
  $0 secret123 wordlist.txt
  $0 5ebe2294ecd0e0f08eab7690d2a6ee69 wordlist.txt
EOF
    exit 1
}

# ----- argument check -----
if [ $# -ne 2 ]; then
    usage
fi

MD5_TOOL=$(_md5_cmd)
if [ -z "$MD5_TOOL" ]; then
    echo "Error: neither 'md5sum' nor 'md5' command found on PATH. Install one and retry."
    exit 5
fi

input="$1"
dictionary_file="$2"

# file checks
if [ ! -f "$dictionary_file" ]; then
    echo "Error: dictionary file '$dictionary_file' not found."
    exit 2
fi
if [ ! -r "$dictionary_file" ]; then
    echo "Error: dictionary file '$dictionary_file' is not readable."
    exit 3
fi

# Determine whether the first arg is a 32-character hex (MD5) or plaintext
if [[ "$input" =~ ^([A-Fa-f0-9]{32})$ ]]; then
    # it's an MD5 hash; normalize to lowercase
    target_hash="${BASH_REMATCH[1],,}"
    echo "Input detected as MD5 hash. Using target hash: $target_hash"
else
    # treat as plaintext password and compute MD5
    target_hash=$(hash_password "$input")
    if [ "$target_hash" = "ERROR_NO_MD5_TOOL" ]; then
        echo "Error computing MD5 of input."
        exit 6
    fi
    # normalize
    target_hash="${target_hash,,}"
    echo "Input detected as plaintext. Computed target MD5 hash: $target_hash"
fi

# Iterate dictionary and compare hashes
line_no=0
while IFS= read -r word || [ -n "$word" ]; do
    line_no=$((line_no + 1))

    # Skip empty lines
    if [ -z "$word" ]; then
        continue
    fi

    candidate_hash=$(hash_password "$word")
    # safety: normalize to lowercase
    candidate_hash="${candidate_hash,,}"

    if [ "$candidate_hash" = "$target_hash" ]; then
        printf "Match found on line %d: '%s'\n" "$line_no" "$word"
        exit 0
    fi

done < "$dictionary_file"

echo "No match found in dictionary."
exit 4

#A few notes and suggestions:
#If you plan to test with very large wordlists, tools like hashcat or john will be much faster (they can use rules, GPUs, and efficient I/O).

#This script preserves whitespace in dictionary words (it reads full line including spaces). If you need to trim spaces, tell me and I can add optional trimming.

#If you want case-insensitive matching for candidate words (e.g., try upper/lower/Title cases automatically), I can add simple rules or integrate an inline rule engine.
#If you prefer the script to accept STDIN for the dictionary (-), I can add that too.
#Want me to add case-variation rules (like try word, Word, WORD, word123, word!), or maybe an option to treat the second argument as a gzipped wordlist (.gz) and transparently read it?
