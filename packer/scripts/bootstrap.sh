#!/bin/bash
set -euo pipefail
export DEPLOYMENT_GROUP_NAME="ship.nimbuspost-deploy-group"
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

for folder in "$SRC_DIR"/*/; do
    echo "📂 Copying contents of $folder to $APP_DIR"
    sudo rsync -av --delete --exclude='.git' --exclude='.git/' --no-owner --no-group --no-perms "$folder"/ "$APP_DIR"/
done

[ -d "$APP_DIR/reports" ] && sudo mv "$APP_DIR/reports" "$APP_DIR/bp-reports" || echo "⚠️ reports directory not found"


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
[ -f "$APP_DIR/.ship.nimbuspost/index.php" ] && sudo cp "$APP_DIR/.ship.nimbuspost/index.php" "$APP_DIR/index.php" || echo "⚠️ index.php not found"
[ -f "$APP_DIR/.ship.nimbuspost/config.php" ] && sudo cp "$APP_DIR/.ship.nimbuspost/config.php" "$APP_DIR/application/config/config.php" || echo "⚠️ config.php not found"
[ -f "$APP_DIR/.ship.nimbuspost/.htaccess" ] && sudo cp "$APP_DIR/.ship.nimbuspost/.htaccess" "$APP_DIR/.htaccess" || echo "⚠️ .htaccess not found"
echo "✅ Deployment complete"

