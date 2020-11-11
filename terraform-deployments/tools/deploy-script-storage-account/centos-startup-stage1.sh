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

error_exit()
{
	log "$1" 1>&2
	exit 1
}

# ------------------------------------------------------------
# Install required components including graphical tools
# ------------------------------------------------------------

if (rpm -q pcoip-agent-standard); then
    exit
fi

if [[ ! -f "$INST_LOG_FILE" ]]
then
    mkdir -p "$INST_LOG_PATH"
    touch "$INST_LOG_FILE"
    chmod +644 "$INST_LOG_FILE"
fi

log "--> Installing security upgrades"
dnf -y -q upgrade
if [ $? -ne 0 ]; then
    error_exit "Failed upgrade"
fi

log "--> Install wget"
dnf -y -q install wget
if [ $? -ne 0 ]; then
    error_exit "Failed to install wget"
fi

dnf -y -q install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
if [ $? -ne 0 ]; then
    error_exit "Failed to install epel"
fi

dnf -y -q install jq
if [ $? -ne 0 ]; then
    error_exit "Failed to install jq"
fi

# Install GNOME and set it as the desktop
log "--> Install Linux GUI ..."
#dnf -y -q groupinstall workstation
dnf -y -q upgrade grub2 firewalld
if [ $? -ne 0 ]; then
    error_exit "Failed to install grub2 firewalld"
fi

dnf -y -q groupinstall 'Server with GUI' --setopt=strict=False
if [ $? -ne 0 ]; then
    error_exit "Failed to install Linux GUI"
fi

log "--> Set default to graphical target"
systemctl set-default graphical.target

# Stage complete
log "Installation stage completed"