#!/usr/bin/env bash
#
# deploy.sh — Build and deploy frontend (S3) + API (Lambda).
#
# Usage:
#   ./scripts/deploy.sh          # deploy both
#   ./scripts/deploy.sh frontend # deploy frontend only
#   ./scripts/deploy.sh api      # deploy API only
#
# Requires: AWS credentials in environment, terraform outputs available.
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"

# Resolve terraform outputs
get_output() {
  terraform -chdir="$TF_DIR" output -raw "$1" 2>/dev/null
}

deploy_frontend() {
  echo "=== Deploying Frontend ==="

  local bucket
  bucket=$(get_output frontend_bucket_name)
  echo "Bucket: $bucket"

  echo "Building frontend (BASE_PATH=/prod)..."
  cd "$ROOT_DIR/frontend"
  BASE_PATH=/prod pnpm build

  echo "Uploading to S3..."
  aws s3 sync build/ "s3://$bucket/" --delete

  echo "Frontend deployed."
}

deploy_api() {
  echo "=== Deploying API ==="

  local fn_name
  fn_name=$(get_output lambda_function_name)
  echo "Lambda: $fn_name"

  echo "Building API..."
  cd "$ROOT_DIR/api"
  npm run build

  echo "Packaging..."
  cd dist
  zip -j "$ROOT_DIR/api/lambda.zip" index.js

  echo "Deploying to Lambda..."
  aws lambda update-function-code \
    --function-name "$fn_name" \
    --zip-file "fileb://$ROOT_DIR/api/lambda.zip" \
    --output text --query 'FunctionName'

  rm -f "$ROOT_DIR/api/lambda.zip"

  echo "API deployed."
}

TARGET="${1:-both}"

case "$TARGET" in
  frontend) deploy_frontend ;;
  api)      deploy_api ;;
  both)
    deploy_frontend
    echo ""
    deploy_api
    ;;
  *)
    echo "Usage: $0 [frontend|api|both]" >&2
    exit 1
    ;;
esac

echo ""
echo "=== Done ==="
echo "URL: $(get_output api_url)"
