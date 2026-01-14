#!/bin/bash
set -euo pipefail

APP_DIR="/var/www/html"
SRC_DIR="/tmp/app"

echo "🔧 Installing base packages"
apt-get update
apt-get install -y git rsync unzip

echo " Deploying application files"
mkdir -p "$APP_DIR"

rsync -a --delete \
  "$SRC_DIR"/ \
  "$APP_DIR"/

chmod +x "$APP_DIR"/.scripts/*.sh

echo " BeforeInstall"
bash "$APP_DIR/.scripts/install_dependencies.sh"

echo "AfterInstall"
bash "$APP_DIR/.scripts/parameter_env.sh"
bash "$APP_DIR/.scripts/install_composer.sh"
bash "$APP_DIR/.scripts/copy_files.sh"

echo "✅ Deployment complete"
