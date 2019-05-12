#!/bin/sh

set -e

mkdir -p ~/.ssh
ssh-keyscan -H "$host" >> ~/.ssh/known_hosts
echo "$ssh_key" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

scp "$user"@"$host":"$pointer_file" latest

echo "Latest backup is $(cat latest)"

echo "Fetching it from $host:"
scp -C "$user"@"$host":"$(cat latest)" backup/

echo "Result:"
ls -al backup
