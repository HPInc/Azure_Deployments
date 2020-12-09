  
# Copyright (c) 2020 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

#!/bin/bash

INST_LOG_PATH="/var/log/teradici/agent/"
INST_LOG_FILE="/var/log/teradici/agent/install.log"

log() {
    local message="$1"
    echo "[$(date)] ${message}" | tee -a "$INST_LOG_FILE"
}

error_exit() {
	log "$1" 1>&2
	exit 1
}

# Create log file
if [[ ! -f "$INST_LOG_FILE" ]]
then
    mkdir -p "$INST_LOG_PATH"
    touch "$INST_LOG_FILE"
    chmod +644 "$INST_LOG_FILE"
fi

# install dnf to replace yum based installations
log "Installing dnf"
yum -y -q install dnf-automatic

log "Starting dnf"
systemctl enable dnf-automatic.timer
systemctl start dnf-automatic.timer

log "Installing dos2unix"
yum install -y dos2unix

if (rpm -q pcoip-agent-standard); then
    exit
fi

# log "--> Installing wget and jq"
# yum -y install wget jq
# if [ $? -ne 0 ]; then
#     log "Failed to install wget and jq"
# fi

# Stage complete
log "centos-utility.sh stage complete"
log "- - - - - - - - - - - - - - - - - - - - - "