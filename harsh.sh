#!/bin/bash
# simple-md5-dict-crack.sh
# Usage: ./simple-md5-dict-crack.sh <password> <dictionary_file>
# Note: MD5 is insecure for password storage; this is for learning/forensics only.

hash_password() {
    # echo -n to avoid newline being included
    echo -n "$1" | md5sum | awk '{print $1}'
}

usage() {
    echo "Usage: $0 <password> <dictionary_file>"
    exit 1
}

# arguments check
if [ $# -ne 2 ]; then
    usage
fi

password="$1"
dictionary_file="$2"

# dictionary file checks
if [ ! -f "$dictionary_file" ]; then
    echo "Error: dictionary file '$dictionary_file' not found."
    exit 2
fi

if [ ! -r "$dictionary_file" ]; then
    echo "Error: dictionary file '$dictionary_file' is not readable."
    exit 3
fi

# compute target hash
target_hash=$(hash_password "$password")
echo "Target MD5 hash: $target_hash"

# iterate dictionary
line_no=0
while IFS= read -r word || [ -n "$word" ]; do
    line_no=$((line_no + 1))
    # skip empty lines
    if [ -z "$word" ]; then
        continue
    fi

    # compute hash of candidate (preserves spaces in word)
    candidate_hash=$(hash_password "$word")

    if [ "$candidate_hash" = "$target_hash" ]; then
        printf "Match found on line %d: '%s'\n" "$line_no" "$word"
        exit 0
    fi

done < "$dictionary_file"

echo "No match found in dictionary."
exit 4
