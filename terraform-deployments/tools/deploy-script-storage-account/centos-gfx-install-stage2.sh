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

install_kernel_header()
{
    log "Installing kernel headers and development packages"
	#yum -y update
    dnf install kernel-devel kernel-headers -y
    exitCode=$?
    if [[ $exitCode -ne 0 ]]; then
        error_exit "--> Failed to install kernel header"
    fi

    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	
	dnf -y -q install dkms
	exitCode=$?
    if [[ $exitCode -ne 0 ]]; then
        error_exit "--> Failed to install dkms"
    fi
	
	dnf -y -q install hyperv-daemons
	exitCode=$?
    if [[ $exitCode -ne 0 ]]; then
        error_exit "--> Failed to install hyper-v daemons"
    fi

    dnf -y -q install gcc
    exitCode=$?
    if [[ $exitCode -ne 0 ]]; then
        error_exit "--> Failed to install gcc"
    fi
}

# Create log file if needed
if [[ ! -f "$INST_LOG_FILE" ]]
then
    mkdir -p "$INST_LOG_PATH"
    touch "$INST_LOG_FILE"
    chmod +644 "$INST_LOG_FILE"
fi

log "Starting install of kernel header"
install_kernel_header

# Stage complete
log "Installation stage completed"