#!/bin/bash

# Function to hash a password using MD5

hash_password() {
    echo -n "$1" | md5sum | awk '{print $1}'
}
