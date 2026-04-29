#!/usr/bin/env bash
#
# aws-creds.sh — Convert AWS credentials format to export commands.
#
# Usage:
#   source <(cat credentials.txt | ./scripts/aws-creds.sh)
#   source <(pbpaste | ./scripts/aws-creds.sh)
#

while IFS='=' read -r key value; do
  [[ "$key" =~ ^aws_ ]] || continue
  key=$(echo "$key" | tr '[:lower:]' '[:upper:]' | xargs)
  value=$(echo "$value" | xargs)
  echo "export ${key}=${value}"
done
