#!/bin/bash
set -euo pipefail

echo "Starting Packer build"

# -------------------------
# Validate required vars
# -------------------------
REQUIRED_VARS=(
  AWS_REGION
  SOURCE_AMI
  VPC_ID
  SUBNET_ID
  SECURITY_GROUP_ID
  REPO_URL
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing env var: $var"
    exit 1
  fi
done

cd /app/packer

packer init .

packer build \
  -var aws_region="$AWS_REGION" \
  -var source_ami="$SOURCE_AMI" \
  -var vpc_id="$VPC_ID" \
  -var subnet_id="$SUBNET_ID" \
  -var security_group_id="$SECURITY_GROUP_ID" \
  -var repo_url="$REPO_URL" \
  -var branch="${BRANCH:-main}" \
  -var app_dir="${APP_DIR:-/var/www/html}" \
  -var "run_commands=${RUN_COMMANDS}" \
  packer.pkr.hcl
