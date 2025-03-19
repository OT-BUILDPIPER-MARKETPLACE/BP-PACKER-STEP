#!/bin/bash

source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/str-functions.sh
source /opt/buildpiper/shell-functions/file-functions.sh
source /opt/buildpiper/shell-functions/aws-functions.sh

logInfoMessage "Manage the packer code available at [$WORKSPACE] and have mounted at [${CODEBASE_DIR}/${PACKER_DIR}]"
sleep  $SLEEP_DURATION


cd  ${WORKSPACE}/${CODEBASE_DIR}/${PACKER_DIR}
logInfoMessage "packer ${INSTRUCTION}"

packer ${INSTRUCTION} ${EXTRA_VARS}

TASK_STATUS=$?

saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
