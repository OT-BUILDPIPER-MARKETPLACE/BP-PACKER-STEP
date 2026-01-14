#!/bin/bash
set -euo pipefail
[[ "${DEBUG:-false}" == "true" ]] && set -x

SHELL_FUNCTIONS_PATH="/opt/buildpiper/shell-functions"

# ----------------------------------------
# Load BuildPiper shell framework
# ----------------------------------------
source "${SHELL_FUNCTIONS_PATH}/functions.sh"
source "${SHELL_FUNCTIONS_PATH}/log-functions.sh"
source "${SHELL_FUNCTIONS_PATH}/str-functions.sh"
source "${SHELL_FUNCTIONS_PATH}/file-functions.sh"
source "${SHELL_FUNCTIONS_PATH}/aws-functions.sh"

TASK_STATUS=0

# ----------------------------------------
# Resolve codebase location
# ----------------------------------------
CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
logInfoMessage "Processing codebase at [${CODEBASE_LOCATION}]"
cd "${CODEBASE_LOCATION}"

# ----------------------------------------
# Assume role if enabled
# ----------------------------------------
if [ "${ASSUME_OTHER_ROLE:-false}" == "true" ]; then
    logInfoMessage "Assuming IAM role..."

    : "${ACCOUNT_ID:?ACCOUNT_ID is required}"
    : "${ROLE_NAME:?ROLE_NAME is required}"
    : "${ROLE_SESSION_NAME:=buildpiper-session}"

    role_output=$(aws sts assume-role \
        --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" \
        --role-session-name "${ROLE_SESSION_NAME}")

    if [ $? -ne 0 ]; then
        logErrorMessage "Failed to assume role."
        exit 1
    fi

    export AWS_ACCESS_KEY_ID=$(echo "$role_output" | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$role_output" | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo "$role_output" | jq -r '.Credentials.SessionToken')

    logInfoMessage "Successfully assumed role: ${ROLE_NAME}"
fi

logInfoMessage "Performing action: ${ACTION}"

# ----------------------------------------
# Main execution
# ----------------------------------------
{
    logInfoMessage "Initializing Packer..."
    # Use absolute path for Packer templates
    PACKER_DIR="/home/buildpiper/packer"
    packer init "$PACKER_DIR"

    logInfoMessage "Starting AMI build..."

    # Base Packer command with mandatory variables
    PACKER_CMD="packer build \
        -var aws_region='${AWS_REGION}' \
        -var source_ami='${SOURCE_AMI}' \
        -var vpc_id='${VPC_ID}' \
        -var subnet_id='${SUBNET_ID}' \
        -var security_group_id='${SECURITY_GROUP_ID}' \
        -var repo_url='${REPO_URL}' \
        -var branch='${BRANCH:-master}' \
        -var app_dir='${APP_DIR:-/var/www/html}'"

    # Add extra commands at runtime if provided
    if [ -n "${RUN_COMMANDS:-}" ]; then
        for cmd in "${RUN_COMMANDS[@]}"; do
            PACKER_CMD+=" -var 'run_commands[]=${cmd}'"
        done
    fi

    # Use absolute path for packer.pkr.hcl
    PACKER_CMD+=" ${PACKER_DIR}/packer.pkr.hcl"

    logInfoMessage "Executing: $PACKER_CMD"
    eval "$PACKER_CMD"

    logSuccessMessage "AMI build completed successfully"
}
catch() {
    TASK_STATUS=1
    logErrorMessage "AMI build failed"
}

catch() {
    TASK_STATUS=1
    logErrorMessage "AMI build failed"
}

# ----------------------------------------
# Save task status (MANDATORY for BuildPiper)
# ----------------------------------------
saveTaskStatus "${TASK_STATUS}" "${ACTIVITY_SUB_TASK_CODE}"

exit "${TASK_STATUS}"
