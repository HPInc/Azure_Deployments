# Copyright (c) 2021 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

#!/bin/bash

PROVISIONING_DIR="/root"
LOG_FILE="/var/log/teradici/provisioning.log"
AWC_BIN_PATH="/usr/local/bin/anyware-connector"
AWC_INSTALL_LOG="/var/log/teradici/awc-install.log"
COMPUTERS_DN=${computers_dn}
USERS_DN=${users_dn}
TERADICI_DOWNLOAD_TOKEN=${teradici_download_token}
AWC_REPO_SETUP_SCRIPT_URL="https://dl.teradici.com/$TERADICI_DOWNLOAD_TOKEN/anyware-manager/cfg/setup/bash.rpm.sh"

cd $PROVISIONING_DIR

log() {
    local message="$1"
    echo "[$(date)] $message"
}

retry() {
    local timeout="$1"
    local interval="$2"
    local command="$3"
    local log_message="$4"
    local err_message="$5"

    until $command
    do
        if [ $timeout -le 0 ]
        then
            log $err_message
            break
        fi

        log "$log_message Retrying in $interval seconds... (Timeout in $timeout seconds)"

        timeout=$((timeout-interval))
        sleep $interval
    done
}

install_prereqs() {
    log "--> Installing wget, jq, dos2unix, python3..."
    dnf update -y
    dnf install -y dos2unix python3 firewalld

    if [ $? -ne 0 ]
    then
        log "--> ERROR: Failed to install prerequisites. Exiting provisioning script..."
        exit 1
    fi
}

configure_firewall(){
    # Ran into the following dbus error when using firewall-cmd. Using firewall-offline-cmd as a workaround.
    # ERROR:dbus.proxies:Introspect error on :1.30:/org/fedoraproject/FirewallD1: dbus.exceptions.DBusException: org.freedesktop.DBus.Error.NoReply

    firewall-offline-cmd --set-default-zone trusted
    firewall-offline-cmd --add-port=6443/tcp # virtual network flannel
    firewall-offline-cmd --add-port=4172/tcp # PCoIP SG port
    firewall-offline-cmd --add-port=4172/udp # PCoIP SG port
    firewall-offline-cmd --zone=trusted --add-source=10.42.0.0/16 # This subnet is for the pods
    firewall-offline-cmd --zone=trusted --add-source=10.43.0.0/16 # This subnet is for the services

    systemctl enable firewalld
    systemctl start firewalld
}

check_connector_installed() {
    if [[ -f "$AWC_BIN_PATH" ]]; then
        log "--> Connector already installed. Skipping provisioning script..."
        exit 0
    fi
}

get_credentials() {
    if [[ -z "${tenant_id}" ]]; then
        log "Not getting secrets from Azure Key Vault. Exiting get_credentials..."
        AD_SERVICE_ACCOUNT_PASSWORD=${ad_service_account_password}
        AWC_TOKEN=${cac_token}
    else
        set +x
        log "Getting secrets from Azure Key Vault..."
        ACCESS_TOKEN=$(curl -X POST -d "grant_type=client_credentials&client_id=${application_id}&client_secret=${aad_client_secret}&resource=https%3A%2F%2Fvault.azure.net" https://login.microsoftonline.com/${tenant_id}/oauth2/token | jq ".access_token" -r)
        AD_SERVICE_ACCOUNT_PASSWORD=$(curl -X GET -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" --url "${ad_service_account_password}?api-version=2016-10-01" | jq -r '.value')
        AWC_TOKEN=$(curl -X GET -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" --url "${cac_token}?api-version=2016-10-01" | jq -r '.value')
        set -x
    fi
}

add_awm_repo() {
    log "--> Adding Anyware Manager repo..."
    local package="anyware-connector"
    local timeout=200
    local interval=10
    until dnf search "$package" | grep -q "^$package"
    do
        if [ $timeout -le 0 ]
        then
            log "--> ERROR: Timeout! Failed to add Anyware Manager repo..."
            exit 1
        fi

        log "--> Try to add Anyware Mananger repo..."
        curl -1sLf $AWC_REPO_SETUP_SCRIPT_URL | sudo -E distro=el codename=8 bash
        dnf repolist --enabled teradici-anyware-manager*
        timeout=$((timeout-interval))
        sleep $interval
    done
}

config_selinux() {
    log "--> Configuring SE Linux..."
    dnf install -y selinux-policy-base container-selinux
    dnf install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.1.stable.1/k3s-selinux-1.1-1.el8.noarch.rpm
    dnf install -y anyware-manager-selinux
}

download_awc() {
    log "--> Downloading Anyware Connector..."
    dnf install -y anyware-connector 2>&1 | tee -a $AWC_INSTALL_LOG

    if [ $? -ne 0 ]
    then
        log "--> ERROR: Failed to install Anyware Connector..."
        exit 1
    fi
}

wait_for_dc() {
    local timeout=25
    local interval=5

    # Wait for service account to be added. Do this last because it takes
    # a while for new AD user to be added in a new Domain Controller.
    # Note: using the domain controller IP instead of the domain name for
    #       the host is more resilient.

    log "--> Updating dnf package list..."
    retry $timeout \
          $interval \
          "dnf -q -y update" \
          "--> Updating dnf package list..." \
          "--> ERROR: Failed to update dnf package list."

    log "--> Installing ldap_utils..."
    retry $timeout \
          $interval \
          "dnf -y install bind-utils nc openldap-clients" \
          "--> ERROR: Failed to install ldap-utils."

    timeout=480
    interval=10

    set +x
    log "--> Ensure AD account is available..."
    retry $timeout \
          $interval \
          "ldapwhoami \
            -H ldap://${domain_controller_ip} \
            -D ${ad_service_account_username}@${domain_name} \
            -w $AD_SERVICE_ACCOUNT_PASSWORD \
            -o nettimeout=1" \
          "--> Waiting for AD account ${ad_service_account_username}@${domain_name} to become available." \
          "--> ERROR: Timed out waiting for AD account ${ad_service_account_username}@${domain_name} to become available. Continuing..."
    set -x
    # Check that the domain name can be resolved and that the LDAP port is accepting
    # connections. This could have been all done with the ldapwhoami command, but
    # due to a number of occasional cac-installation issues, such as "domain
    # controller unreachable" or "DNS error occurred" errors, check these explicitly
    # for logging and debug purposes.
    log "--> Ensure domain ${domain_name} can be resolved..."
    retry $timeout \
          $interval \
          "host ${domain_name}" \
          "--> Trying to resolve ${domain_name}." \
          "--> ERROR: Timed out trying to resolve ${domain_name}. Continuing..."

    log "--> Ensure domain ${domain_name} port 636 is reacheable..."
    retry $timeout \
          $interval \
          "nc -vz ${domain_name} 636" \
          "--> Trying to contact ${domain_name}:636." \
          "--> ERROR: Timed out trying to contact ${domain_name}:636. Continuing..."
}

wait_for_lls() {
    local timeout=1200
    local interval=10
    local lls_health_check_url="http://${lls_ip}:7070/api/1.0/health"

    log "--> Performing LLS health check using endpoint $lls_health_check_url..."
    retry $timeout \
          $interval \
          # Need to escape Terraform template directive using %%
          "[ $(curl --silent --write-out "%%{http_code}\n" --output /dev/null $lls_health_check_url) -eq 200 ]" \
          "--> Performing LLS health check using endpoint $lls_health_check_url..." \
          "--> ERROR: Timed out trying to perform health check using endpoint $lls_health_check_url. Continuing..."
}

check_required_vars() {
    set +x
    if [[ -z "$AD_SERVICE_ACCOUNT_PASSWORD" ]]; then
        log "--> ERROR: Missing Active Directory Service Account Password."
        missing_vars="true"
    fi

    if [[ -z "$AWC_TOKEN" ]]; then
        log "--> ERROR: Missing Anyware Connector Token."
        missing_vars="true"
    fi
    set -x

    if [[ "$missing_vars" == "true" ]]; then
        log "--> Exiting..."
        exit 1
    fi
}

configure_awc() {
    log "--> configuring Anyware Connector..."
    local retries=10

    log "--> Running command: $AWC_BIN_PATH install"
    log "--> AWC install options:"
    log "  -t <awc_token>"
    log "  --accept-policies"
    log "  --sa-user <${ad_service_account_username}>"
    log "  --sa-password <ad_service_account_password>"
    log "  --domain ${domain_name}"
    log "  --retrieve-agent-state true"
    log "  --sync-interval 5"
    log "  --manager-url ${cas_mgr_url}"

    # Set pipefail option to return status of the connector install command
    set -o pipefail

    if [ "${tls_key}" ]
    then
        log "  --tls-key <tls_key>"
        log "  --tls-cert <tls_cert>"

        mv /tmp/${tls_key} $PROVISIONING_DIR
        mv /tmp/${tls_cert} $PROVISIONING_DIR

        args=$args"--tls-key $PROVISIONING_DIR/${tls_key} "
        args=$args"--tls-cert $PROVISIONING_DIR/${tls_cert} "
    else
        log "  --self-signed"
        args=$args"--self-signed "
    fi

    if [ "${cas_mgr_insecure}" ]
    then
        log "  --manager-insecure"
        args=$args"--manager-insecure "
    fi

    if [ "${lls_ip}" ]
    then
        log "  --local-license-server-url http://${lls_ip}:7070/request"
        args=$args"--local-license-server-url http://${lls_ip}:7070/request "
    fi

    set +x
    while true
    do
        $AWC_BIN_PATH configure \
            --debug \
            --token $AWC_TOKEN \
            --manager-url ${cas_mgr_url} \
            --domain ${domain_name} \
            --computers-dn $COMPUTERS_DN \
            --users-dn $USERS_DN \
            --sa-user ${ad_service_account_username} \
            --sa-password "$AD_SERVICE_ACCOUNT_PASSWORD" \
            --accept-policies \
            --ldaps-insecure \
            --retrieve-agent-state true \
            --show-agent-state true \
            --sync-interval 5 \
            $args \
            2>&1 | tee -a $AWC_INSTALL_LOG

        local rc=$?
        if [ $rc -eq 0 ]
        then
            log "--> Successfully installed Anyware Connector."
            break
        fi

        if [ $retries -eq 0 ]
        then
            log "--> ERROR: Failed to install Anyware Connector. No retries remaining."
            exit 1
        fi

        log "--> ERROR: Failed to install Anyware Connector. $retries retries remaining..."
        retries=$((retries-1))
        sleep 60
    done
    set -x
}

if [[ ! -f "$LOG_FILE" ]]
then
    mkdir -p "$(dirname $LOG_FILE)"
    touch "$LOG_FILE"
    chmod +644 "$LOG_FILE"
fi

log "$(date)"

# Print all executed commands to the terminal
set -x

# Redirect stdout and stderr to the log file
exec &>>$LOG_FILE

install_prereqs

get_credentials

configure_firewall

check_connector_installed

add_awm_repo

config_selinux

download_awc

wait_for_dc

if [ "${lls_ip}" ]
then
    wait_for_lls
fi

check_required_vars

configure_awc

log "--> Provisioning script completed successfully."