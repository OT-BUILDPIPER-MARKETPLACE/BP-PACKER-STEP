#!/bin/bash
set -euo pipefail

# Directories
APP_DIR="/var/www/html"
SRC_DIR="/home/ubuntu"   # Packer uploaded files here

echo "🔧 Installing base packages"
sudo apt-get update
sudo apt-get install -y git rsync unzip

# ----------------------------
# List contents of SRC_DIR recursively
# ----------------------------
echo "📂 Listing all contents of source directory: $SRC_DIR"
find "$SRC_DIR" -type d -o -type f | sort

echo "📂 Deploying application files"
# Ensure target directory exists
sudo mkdir -p "$APP_DIR"

# Sync files with sudo
sudo rsync -a --delete "$SRC_DIR"/ "$APP_DIR"/

# Make scripts executable if they exist
if [ -d "$APP_DIR/.scripts" ]; then
    echo "🔧 Making scripts executable in $APP_DIR/.scripts"
    sudo chmod +x "$APP_DIR/.scripts/"*.sh || true
else
    echo "⚠️ No .scripts directory found in $APP_DIR"
fi

echo "⚙️ Running BeforeInstall script"
[ -f "$APP_DIR/.scripts/install_dependencies.sh" ] && sudo bash "$APP_DIR/.scripts/install_dependencies.sh" || echo "⚠️ install_dependencies.sh not found"

echo "⚙️ Running AfterInstall scripts"
[ -f "$APP_DIR/.scripts/parameter_env.sh" ] && sudo bash "$APP_DIR/.scripts/parameter_env.sh" || echo "⚠️ parameter_env.sh not found"
[ -f "$APP_DIR/.scripts/install_composer.sh" ] && sudo bash "$APP_DIR/.scripts/install_composer.sh" || echo "⚠️ install_composer.sh not found"
[ -f "$APP_DIR/.scripts/copy_files.sh" ] && sudo bash "$APP_DIR/.scripts/copy_files.sh" || echo "⚠️ copy_files.sh not found"

echo "✅ Deployment complete"

