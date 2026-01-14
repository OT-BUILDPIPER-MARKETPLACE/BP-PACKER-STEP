#!/bin/bash
set -euo pipefail

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

# Assume role if enabled
if [ "$ASSUME_OTHER_ROLE" == "true" ]; then
    logInfoMessage "Assuming IAM role..."

    role_output=$(aws sts assume-role \
        --role-arn arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME \
        --role-session-name "$ROLE_SESSION_NAME")

    if [ $? -ne 0 ]; then
        echo "Failed to assume role."
        exit 1
    fi

    export AWS_ACCESS_KEY_ID=$(echo "$role_output" | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$role_output" | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo "$role_output" | jq -r '.Credentials.SessionToken')
fi

logInfoMessage "Performing action: ${ACTION}"

# ----------------------------------------
# Main execution
# ----------------------------------------
{
    logInfoMessage "Initializing Packer"
    packer init packer/

    logInfoMessage "Starting AMI build"
    packer build \
      -var aws_region="${AWS_REGION}" \
      -var source_ami="${SOURCE_AMI}" \
      -var vpc_id="${VPC_ID}" \
      -var subnet_id="${SUBNET_ID}" \
      -var security_group_id="${SECURITY_GROUP_ID}" \
      packer/packer.pkr.hcl

    logSuccessMessage "AMI build completed successfully"
}
catch() {
    TASK_STATUS=1
    logErrorMessage "AMI build failed"
}

# ----------------------------------------
# Save task status (VERY IMPORTANT)
# ----------------------------------------
saveTaskStatus "${TASK_STATUS}" "${ACTIVITY_SUB_TASK_CODE}"

exit "${TASK_STATUS}"
