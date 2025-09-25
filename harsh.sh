#!/bin/bash

# Function to hash a password using MD5

hash_password() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

if [$# -ne 2]; then
    echo "Useage: <password> <dictionary_file>"
    exit
fi

password=$1
dictionary_file=$2