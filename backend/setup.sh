#!/bin/bash
set -euxo pipefail

export APP_DIR="/app/backend"
export UV_INSTALL_DIR="/usr/local/bin"
TMP_DIR="/tmp/marky"

exec > >(tee /tmp/user-data.log | logger -t user-data ) 2>&1

sudo dnf update -y
sudo dnf install -y git python3.13

curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR="/usr/local/bin" sh

# Python

python3.13 --version
$UV_INSTALL_DIR/uv --version

echo "=== Preparing application directory ==="
sudo rm -rf "$APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo chown ec2-user:ec2-user "$APP_DIR"

echo "=== Installing dependencies ==="
cd "$TMP_DIR/backend"
$UV_INSTALL_DIR/uv sync

echo "=== Deploying application ==="
cp -r . "$APP_DIR"
sudo chown -R ec2-user:ec2-user "$APP_DIR"

echo "=== Creating .env from example ==="
cp "$APP_DIR/.env.example" "$APP_DIR/.env"

echo "=== Creating systemd services ==="
envsubst '$APP_DIR $UV_INSTALL_DIR' < marky-api.service > /tmp/marky-api.service
envsubst '$APP_DIR $UV_INSTALL_DIR' < marky-ingest.service > /tmp/marky-ingest.service
cp marky-ingest.timer /tmp/marky-ingest.timer
sudo mv /tmp/marky-api.service /tmp/marky-ingest.service /tmp/marky-ingest.timer /etc/systemd/system

echo "=== Enabling services ==="
sudo systemctl daemon-reload
sudo systemctl enable --now marky-api
sudo systemctl enable --now marky-ingest.timer
