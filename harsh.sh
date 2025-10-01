#!/bin/bash

# Function to hash a password using MD5
hash_password() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <password> <dictionary_file>"
    exit 1
fi

password=$1
dictionary_file=$2

