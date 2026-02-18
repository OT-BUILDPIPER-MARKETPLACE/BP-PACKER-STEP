#!/bin/bash
set -euo pipefail
export DEPLOYMENT_GROUP_NAME="ship.nimbuspost-deploy-group"
# Directories
APP_DIR="/var/www/html"
SRC_DIR="/home/ubuntu"   # Packer uploaded files here

echo "🔧 Installing base packages"
sudo apt-get install -y rsync unzip tzdata

echo "🕒 Setting timezone to IST (Asia/Kolkata)"
sudo timedatectl set-timezone Asia/Kolkata
timedatectl

# ----------------------------
# List contents of SRC_DIR recursively
# ----------------------------
echo "📂 Listing all contents of source directory: $SRC_DIR"
# find "$SRC_DIR" -type d -o -type f | sort

echo "📂 Deploying application files"
# Ensure target directory exists
sudo mkdir -p "$APP_DIR"

for folder in "$SRC_DIR"/*/; do
    echo "📂 Copying contents of $folder to $APP_DIR"
    sudo rsync -av --delete --exclude='.git' --exclude='.git/' --no-owner --no-group --no-perms "$folder"/ "$APP_DIR"/
done

[ -d "$APP_DIR/reports" ] && sudo mv "$APP_DIR/reports" "$APP_DIR/bp-reports" || echo "⚠️ reports directory not found"


# Make scripts executable if they exist
if [ -d "$APP_DIR/scripts" ]; then
    echo "🔧 Making scripts executable in $APP_DIR/scripts"
    sudo chmod +x "$APP_DIR/scripts/"*.sh || true
else
    echo "⚠️ No scripts directory found in $APP_DIR"
fi

echo "⚙️ Running BeforeInstall script"
[ -f "$APP_DIR/scripts/install_dependencies.sh" ] && sudo bash "$APP_DIR/scripts/install_dependencies.sh" || echo "⚠️ install_dependencies.sh not found"

echo "⚙️ Running AfterInstall scripts"
[ -f "$APP_DIR/scripts/configure_server.sh" ] && sudo bash "$APP_DIR/scripts/configure_server.sh" || echo "⚠️ configure_server.sh not found"
#[ -f "$APP_DIR/scripts/start_server.sh" ] && sudo bash "$APP_DIR/scripts/start_server.sh" || echo "⚠️ start_server.sh not found"
#[ -f "$APP_DIR/scripts/validate_service.sh" ] && sudo bash "$APP_DIR/scripts/validate_service.sh" || echo "⚠️ validate_service.sh not found"

echo "✅ Deployment complete"

