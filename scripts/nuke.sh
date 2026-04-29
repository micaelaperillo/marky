#!/usr/bin/env bash
#
# nuke.sh — Destroy all marky AWS resources in Academy account.
# Uses docker (auto-removed container) with ghcr.io/ekristen/aws-nuke:v3.64.1.
#
# Usage:
#   ./scripts/nuke.sh           # dry-run (default)
#   ./scripts/nuke.sh --confirm # actually delete
#
# Requires: docker, AWS credentials in environment (AWS_ACCESS_KEY_ID, etc.)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_TEMPLATE="$SCRIPT_DIR/nuke-config.yml"
IMAGE="ghcr.io/ekristen/aws-nuke:v3.64.1"

# Verify AWS creds in env
for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: $var not set. Source credentials first:" >&2
    echo "  source <(cat credentials.txt | ./scripts/aws-creds.sh)" >&2
    exit 1
  fi
done

# Resolve account ID from current credentials
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
if [[ -z "$ACCOUNT_ID" ]]; then
  echo "Error: failed to get account ID. Check credentials." >&2
  exit 1
fi

# Generate config with actual account ID
CONFIG_RENDERED="/tmp/nuke-config-${ACCOUNT_ID}.yml"
sed "s/{{ ACCOUNT_ID }}/$ACCOUNT_ID/g" "$CONFIG_TEMPLATE" > "$CONFIG_RENDERED"

echo "Account: $ACCOUNT_ID"

if [[ "${1:-}" == "--confirm" ]]; then
  echo "=== LIVE RUN — deleting all marky resources ==="
  docker run --rm \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    -v "$CONFIG_RENDERED":/nuke-config.yml \
    "$IMAGE" \
    run \
    --config /nuke-config.yml \
    --no-alias-check \
    --no-dry-run \
    --log-level error \
    --force 2>&1 | grep -v -E "not authorized|listing failed|no such host|TLS handshake timeout|status code: [45]"
else
  echo "=== DRY RUN — showing what would be deleted ==="
  echo "Run with --confirm to actually delete."
  echo ""
  docker run --rm \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    -v "$CONFIG_RENDERED":/nuke-config.yml \
    "$IMAGE" \
    run \
    --config /nuke-config.yml \
    --no-alias-check \
    --log-level error \
    --force 2>&1 | grep -v -E "not authorized|listing failed|no such host|TLS handshake timeout|status code: [45]"
fi

rm -f "$CONFIG_RENDERED"
