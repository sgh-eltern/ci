#!/bin/sh

set -e

echo "Storing in $endpoint/$bucket:"
find backup -type f

# https://www.backblaze.com/b2/docs/quick_command_line.html
b2 authorize_account "$access_key_id" "$secret_access_key"
b2 sync backup b2:"$bucket"

echo
echo "Existing backups:"
b2 ls "$bucket"
