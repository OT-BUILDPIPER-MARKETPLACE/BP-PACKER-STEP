#!/bin/bash
set -euo pipefail

# Directories
APP_DIR="/var/www/html"
SRC_DIR="/tmp"   # Packer uploaded files here

echo "🔧 Installing base packages"
sudo apt-get update
sudo apt-get install -y git rsync unzip

echo "📂 Deploying application files"
# Ensure target directory exists
sudo mkdir -p "$APP_DIR"

# Sync files with sudo
sudo rsync -a --delete "$SRC_DIR"/ "$APP_DIR"/

# Make scripts executable
sudo chmod +x "$APP_DIR"/.scripts/*.sh

echo "⚙️ Running BeforeInstall script"
sudo bash "$APP_DIR/.scripts/install_dependencies.sh"

echo "⚙️ Running AfterInstall scripts"
sudo bash "$APP_DIR/.scripts/parameter_env.sh"
sudo bash "$APP_DIR/.scripts/install_composer.sh"
sudo bash "$APP_DIR/.scripts/copy_files.sh"

echo "✅ Deployment complete"
