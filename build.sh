#!/bin/bash
set -euo pipefail

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
