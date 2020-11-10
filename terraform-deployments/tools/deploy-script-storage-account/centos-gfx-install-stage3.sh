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

# Download installation script and run to install NVIDIA driver
install_nvidia_driver() {
    # the first part to check if GPU is attached
    # NVIDIA VID = 10DE
    # Display class code = 0300
    # the second part to check if the NVIDIA driver is installed
    if [[ $(lspci -d '10de:*:0300' -s '.0' | wc -l) -gt 0 ]] && ! (modprobe --resolve-alias nvidia > /dev/null 2>&1)
    then
        log "--> Start to install gpu driver ..."

        CUDA_REPO_PKG=cuda-repo-rhel7-10.0.130-1.x86_64.rpm
        wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/${CUDA_REPO_PKG} -O /tmp/${CUDA_REPO_PKG}
        rpm -ivh /tmp/${CUDA_REPO_PKG}
        rm -f /tmp/${CUDA_REPO_PKG}

        log "--> Installing cuda drivers"
        dnf -y install cuda-drivers
        exitCode=$?
        if [[ $exitCode -ne 0 ]]; then
            error_exit "--> Failed to install cuda drivers"
        fi

        log "--> Installing cuda toolkit"
        dnf -y install cuda
        exitCode=$?
        if [[ $exitCode -ne 0 ]]; then
            error_exit "--> Failed to install cuda toolkit"
        fi
    fi
}

# Create log file if needed
if [[ ! -f "$INST_LOG_FILE" ]]
then
    mkdir -p "$INST_LOG_PATH"
    touch "$INST_LOG_FILE"
    chmod +644 "$INST_LOG_FILE"
fi

log "Starting install of NVidia driver"
install_nvidia_driver

# Stage complete
log "Installation stage completed"