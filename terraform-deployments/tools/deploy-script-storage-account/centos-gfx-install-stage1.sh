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

# Create log file if needed
if [[ ! -f "$INST_LOG_FILE" ]]
then
    mkdir -p "$INST_LOG_PATH"
    touch "$INST_LOG_FILE"
    chmod +644 "$INST_LOG_FILE"
fi

log "Disable the Nouveau kernel driver ..."
for driver in vga16fb nouveau nvidiafb rivafb rivatv; do
    echo "blacklist $driver" >> /etc/modprobe.d/blacklist.conf
done

sed -i 's/\(^GRUB_CMDLINE_LINUX=".*\)"/\1 rdblacklist=nouveau"/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Stage complete
log "Installation stage completed"