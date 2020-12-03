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

log "deployed from local files."

error_exit() {
	log "$1" 1>&2
	exit 1
}

yum_wait() {
    # Wait for yum to finish
    log "Checking yum has released its lock"
    n=0
    while true; do
        n=$[$n+1]
        if [ $n -ge 5 ]; then
            log "Waited too long for yum to release lock"
            break
        fi

        if [ -f /var/run/sshd.pid ] && (ps -p $(cat /var/run/sshd.pid) > /dev/null 2>&1); then
            log "Waiting for yum to release lock"
            sleep 30s
        else
            break
        fi
    done

    # There is a bug where sometimes yum will never finish so just kill the process and proceed with dnf installation
    if [ -f /var/run/sshd.pid ] && (ps -p $(cat /var/run/sshd.pid) > /dev/null 2>&1); then
        log "Yum still has a lock so killing the process"
        kill $(cat /var/run/sshd.pid)
    fi
}

# Create log file
if [[ ! -f "$INST_LOG_FILE" ]]
then
    mkdir -p "$INST_LOG_PATH"
    touch "$INST_LOG_FILE"
    chmod +644 "$INST_LOG_FILE"
fi

# Wait for yum to complete
log "Jump through hoops because yum tends to lock its process"

log "Installing dos2unix"
yum install -y dos2unix

# Stage complete
log "centos-utility.sh complete"
log " - - - - - - - - - - - - - - "
exit 0