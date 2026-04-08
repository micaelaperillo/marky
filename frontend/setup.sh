#!/bin/bash
export APP_DIR="/app/frontend"
export APP_PORT="3000"
export HOME=/home/ec2-user
export NVM_DIR="$HOME/.nvm"
TMP_DIR="/tmp/marky"

set -euxo pipefail

exec > >(tee /tmp/user-data.log | logger -t user-data ) 2>&1

sudo dnf update -y
sudo dnf install -y nginx git libatomic

# Node

echo "=== Installing Node.js ==="
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
set +u
sudo -u ec2-user "$NVM_DIR/nvm.sh"
set -u
nvm install --lts

node -v
npm -v

echo "=== Preparing application directory ==="
sudo rm -rf "$APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo chown ec2-user:ec2-user "$APP_DIR"

echo "=== Cloning frontend repo ==="
cd "$TMP_DIR/frontend"

echo "=== Installing dependencies ==="
npm i

echo "=== Building SSR app ==="
npm run build

echo "=== Configuring build ==="
npm ci --omit-dev
cp -r build node_modules package.json "$APP_DIR"
chown -R ec2-user:ec2-user "$APP_DIR"

echo "=== Creating systemd service ==="
cat frontend.service | envsubst > /tmp/frontend.service
sudo mv /tmp/frontend.service /etc/systemd/system

echo "=== Enabling service ==="
sudo systemctl daemon-reload
sudo systemctl enable --now frontend

# nginx

echo "=== Setting up health checks at port 9090 ==="
sudo sed -i 's/listen\s*80;/listen 9090;/' /etc/nginx/nginx.conf
sudo sed -i 's/listen\s*\[::\]:80;/listen [::]:9090;/' /etc/nginx/nginx.conf

sudo systemctl enable --now nginx
