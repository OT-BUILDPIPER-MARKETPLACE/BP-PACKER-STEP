#!/bin/bash
set -uo pipefail
[[ "${DEBUG:-false}" == "true" ]] && set -x

# --------------------------------------------------
# Constants & Framework
# --------------------------------------------------
SHELL_FUNCTIONS_PATH="/opt/buildpiper/shell-functions"
ACTIVITY_SUB_TASK_CODE="PACKER_AMI_BUILD"

source "${SHELL_FUNCTIONS_PATH}/functions.sh"
source "${SHELL_FUNCTIONS_PATH}/log-functions.sh"
source "${SHELL_FUNCTIONS_PATH}/str-functions.sh"
source "${SHELL_FUNCTIONS_PATH}/file-functions.sh"
source "${SHELL_FUNCTIONS_PATH}/aws-functions.sh"

TASK_STATUS=0
AMI_ID=""

CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"

logInfoMessage "Processing codebase at [${CODEBASE_LOCATION}]"
cd "${CODEBASE_LOCATION}"

# --------------------------------------------------
# Assume IAM Role (Optional)
# --------------------------------------------------
if [ "${ASSUME_OTHER_ROLE:-false}" == "true" ]; then
    : "${ACCOUNT_ID:?}"
    : "${ROLE_NAME:?}"
    : "${ROLE_SESSION_NAME:=buildpiper-session}"

    logInfoMessage "Assuming IAM role ${ROLE_NAME}..."

    ROLE_OUTPUT=$(aws sts assume-role \
        --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" \
        --role-session-name "${ROLE_SESSION_NAME}")

    export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<<"${ROLE_OUTPUT}")
    export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<<"${ROLE_OUTPUT}")
    export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<<"${ROLE_OUTPUT}")

    logInfoMessage "Successfully assumed role: ${ROLE_NAME}"
fi

# --------------------------------------------------
# Packer Build
# --------------------------------------------------
PACKER_DIR="/home/buildpiper/packer"
PACKER_LOG_FILE="/bp/workspace/packer-build.log"

logInfoMessage "Initializing Packer in ${PACKER_DIR}"
packer init "${PACKER_DIR}"

PACKER_CMD="packer build \
  -var-file=${PACKER_DIR}/variables.pkr.hcl \
  -var aws_region='${AWS_REGION}' \
  -var source_ami='${SOURCE_AMI}' \
  -var vpc_id='${VPC_ID}' \
  -var subnet_id='${SUBNET_ID}' \
  -var security_group_id='${SECURITY_GROUP_ID}' \
  -var app_dir='${APP_DIR:-/var/www/html}' \
  -var src_dir='${SRC_DIR:-/tmp}' \
  -var ami_name='${AMI_NAME:-app}' \
  -var instance_type='${INSTANCE_TYPE:-t3.micro}' \
  -var root_volume_size='${ROOT_VOLUME_SIZE:-8}' \
  -var root_volume_type='${ROOT_VOLUME_TYPE:-gp3}' \
  ${PACKER_DIR}"

if [ -n "${RUN_COMMANDS:-}" ]; then
    PACKER_CMD+=" -var \"run_commands=${RUN_COMMANDS}\""
fi

logInfoMessage "Executing Packer build"
logInfoMessage "${PACKER_CMD}"

set +e
eval "${PACKER_CMD}" | tee "${PACKER_LOG_FILE}"
PACKER_EXIT_CODE=${PIPESTATUS[0]}
set -e

# --------------------------------------------------
# Extract AMI ID (UI OUTPUT – VERIFIED)
# --------------------------------------------------
if [ "${PACKER_EXIT_CODE}" -eq 0 ]; then
    AMI_ID=$(awk '
        /AMIs were created:/ {found=1; next}
        found && /ami-/ {print $2; exit}
    ' "${PACKER_LOG_FILE}")

    if [ -z "${AMI_ID}" ]; then
        logErrorMessage "Packer succeeded but AMI ID could not be extracted"
        PACKER_EXIT_CODE=1
    fi
fi

# --------------------------------------------------
# Exit Handling
# --------------------------------------------------
if [ "${PACKER_EXIT_CODE}" -eq 0 ]; then
    TASK_STATUS=0

    logInfoMessage "AMI build completed successfully"
    logInfoMessage "Generated AMI ID: ${AMI_ID}"

    echo "AMI_ID=${AMI_ID}" >> /bp/workspace/output.env
    echo "AWS_REGION=${AWS_REGION}" >> /bp/workspace/output.env

    saveTaskStatus "${TASK_STATUS}" "${ACTIVITY_SUB_TASK_CODE}" || true
    logInfoMessage "Congratulations ${ACTIVITY_SUB_TASK_CODE} succeeded!!! AMI=${AMI_ID}"
else
    TASK_STATUS=1
    logErrorMessage "AMI build failed"
    saveTaskStatus "${TASK_STATUS}" "${ACTIVITY_SUB_TASK_CODE}" || true
fi

# --------------------------------------------------
# Force Exit Container
# --------------------------------------------------
logInfoMessage "Force exiting container to ensure it stops completely"
sleep 2
kill -TERM 1 || true
exit "${TASK_STATUS}"
