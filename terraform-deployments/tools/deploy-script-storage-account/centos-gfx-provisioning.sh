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

log "Disable the Nouveau kernel driver ..."
for driver in vga16fb nouveau nvidiafb rivafb rivatv; do
    echo "blacklist $driver" >> /etc/modprobe.d/blacklist.conf
done

sed -i 's/\(^GRUB_CMDLINE_LINUX=".*\)"/\1 rdblacklist=nouveau"/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

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

log "Starting install of kernel header"
install_kernel_header

log "Starting install of NVidia driver"
install_nvidia_driver

# Stage complete
log "centos-gfx-provisioning.sh complete"
log "- - - - - - - - - - - - - - - - - - -"