#!/bin/bash
export APP_DIR="/app/backend"
export APP_PORT="3000"
TMP_DIR="/tmp/marky"

set -euxo pipefail

exec > >(tee /tmp/user-data.log | logger -t user-data ) 2>&1

sudo dnf update -y
sudo dnf install -y nginx git python3.13

curl -LsSf https://astral.sh/uv/install.sh | sh
#source $HOME/.local/bin/env

# Python

python3.13 --version
uv --version

echo "=== Preparing application directory ==="
sudo rm -rf "$APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo chown ec2-user:ec2-user "$APP_DIR"

echo "=== Cloning backend repo ==="
cd "$TMP_DIR/backend"

echo "=== Installing dependencies ==="
uv sync

echo "=== Configuring build ==="
npm ci --omit-dev
cp -r build node_modules package.json "$APP_DIR"
chown -R ec2-user:ec2-user "$APP_DIR"

echo "=== Creating systemd service ==="
cat backend.service | envsubst > /tmp/backend.service
cat backend.timer | envsubst > /tmp/backend.timer
sudo mv /tmp/backend.service /tmp/backend.timer /etc/systemd/system

echo "=== Enabling service ==="
sudo systemctl daemon-reload
sudo systemctl enable --now backend

# nginx

echo "=== Setting up health checks at port 9090 ==="
sudo sed -i 's/listen\s*80;/listen 9090;/' /etc/nginx/nginx.conf
sudo sed -i 's/listen\s*\[::\]:80;/listen [::]:9090;/' /etc/nginx/nginx.conf

sudo systemctl enable --now nginx
