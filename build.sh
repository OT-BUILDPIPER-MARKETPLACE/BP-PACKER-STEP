#!/bin/bash
set -uo pipefail
[[ "${DEBUG:-false}" == "true" ]] && set -x

# ----------------------------------------
# Constants
# ----------------------------------------
SHELL_FUNCTIONS_PATH="/opt/buildpiper/shell-functions"
ACTIVITY_SUB_TASK_CODE="PACKER_AMI_BUILD"

# ----------------------------------------
# Load BP shell modules
# ----------------------------------------
source "${SHELL_FUNCTIONS_PATH}/functions.sh"
source "${SHELL_FUNCTIONS_PATH}/log-functions.sh"
source "${SHELL_FUNCTIONS_PATH}/aws-functions.sh"

# ----------------------------------------
# Initialize
# ----------------------------------------
TASK_STATUS=0
CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
logInfoMessage "Processing codebase at [${CODEBASE_LOCATION}]"
cd "${CODEBASE_LOCATION}"

# ----------------------------------------
# Assume IAM role if requested
# ----------------------------------------
if [ "${ASSUME_OTHER_ROLE:-false}" == "true" ]; then
    : "${ACCOUNT_ID:?ACCOUNT_ID is required}"
    : "${ROLE_NAME:?ROLE_NAME is required}"
    : "${ROLE_SESSION_NAME:=buildpiper-session}"

    logInfoMessage "Assuming IAM role ${ROLE_NAME}..."
    role_output=$(aws sts assume-role \
        --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" \
        --role-session-name "${ROLE_SESSION_NAME}")

    export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<<"$role_output")
    export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<<"$role_output")
    export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<<"$role_output")

    logInfoMessage "Successfully assumed role: ${ROLE_NAME}"
fi

# ----------------------------------------
# Initialize Packer
# ----------------------------------------
PACKER_DIR="/home/buildpiper/packer"
logInfoMessage "Initializing Packer in ${PACKER_DIR}"
packer init "${PACKER_DIR}"

# ----------------------------------------
# Build Packer command
# ----------------------------------------
PACKER_CMD="packer build \
  -var-file=${PACKER_DIR}/variables.pkr.hcl \
  -var aws_region='${AWS_REGION}' \
  -var source_ami='${SOURCE_AMI}' \
  -var vpc_id='${VPC_ID}' \
  -var subnet_id='${SUBNET_ID}' \
  -var security_group_id='${SECURITY_GROUP_ID}' \
  -var app_dir='${APP_DIR:-/var/www/html}' \
  -var src_dir='${SRC_DIR:-/tmp/app}' \
  -var ami_name='${AMI_NAME:-app}' \
  -var instance_type='${INSTANCE_TYPE:-t3.micro}' \
  -var root_volume_size='${ROOT_VOLUME_SIZE:-8}' \
  -var root_volume_type='${ROOT_VOLUME_TYPE:-gp3}' \
  ${PACKER_DIR}"

if [ -n "${RUN_COMMANDS:-}" ]; then
    PACKER_CMD+=" -var \"run_commands=${RUN_COMMANDS}\""
fi

logInfoMessage "Executing Packer command:"
logInfoMessage "${PACKER_CMD}"

# ----------------------------------------
# Run Packer (capture exit code safely)
# ----------------------------------------
set +e
eval "${PACKER_CMD}"
PACKER_EXIT_CODE=$?
set -e

# ----------------------------------------
# Update task status
# ----------------------------------------
if [ "${PACKER_EXIT_CODE}" -ne 0 ]; then
    TASK_STATUS=1
    logInfoMessage "AMI build failed"
else
    TASK_STATUS=0
    logInfoMessage "AMI build completed successfully"
fi

saveTaskStatus "${TASK_STATUS}" "${ACTIVITY_SUB_TASK_CODE}"

# ----------------------------------------
# END OF SCRIPT
# Let BuildPiper handle lifecycle naturally
# ----------------------------------------
