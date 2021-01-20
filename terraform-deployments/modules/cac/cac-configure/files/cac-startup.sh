# Copyright (c) 2019 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

#!/bin/bash

LOG_FILE="/var/log/teradici/provisioning.log"
AD_SERVICE_ACCOUNT_PASSWORD=${ad_service_account_password}
CAC_BIN_PATH="/usr/sbin/cloud-access-connector"
CAC_TOKEN=${cac_token}
PCOIP_REGISTRATION_CODE=${pcoip_registration_code}
INSTALL_DIR="/root"
CAC_INSTALL_LOG="/var/log/teradici/cac-install.log"
cd $INSTALL_DIR

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

check_connector_installed() {
    if [[ -f "$CAC_BIN_PATH" ]]; then
        log "--> Connector already installed. Skipping provisioning script..."
        exit 0
    fi
}

config_network() {
    if [[ ! -f $PCOIP_NETWORK_CONF_FILE ]]; then
        log "--> Configuring network..."
        # Note the indented HEREDOC lines must be preceded by tabs, not spaces
        cat <<- EOF > $PCOIP_NETWORK_CONF_FILE
			# System Control network settings for CAC
			net.core.rmem_max=160000000
			net.core.rmem_default=160000000
			net.core.wmem_max=160000000
			net.core.wmem_default=160000000
			net.ipv4.udp_mem=120000 240000 600000
			net.core.netdev_max_backlog=2000
			EOF

        sysctl -p $PCOIP_NETWORK_CONF_FILE
    fi
}

install_prereqs() {
    log "--> Installing wget, jq..."
    apt-get -y update
    apt install -y wget jq

    if [ $? -ne 0 ]
    then
        log "--> ERROR: Failed to install prerequisites. Exiting provisioning script..."
        exit 1
    fi
}

get_access_token() {
    accessToken=`curl -X POST -d "grant_type=client_credentials&client_id=$1&client_secret=$2&resource=https%3A%2F%2Fvault.azure.net" https://login.microsoftonline.com/$3/oauth2/token`
    token=$(echo $accessToken | jq ".access_token" -r)
    json_map=`curl -X GET -H "Authorization: Bearer $token" -H "Content-Type: application/json" --url "$4?api-version=2016-10-01"`
    value=$(echo $json_map | jq -r '.value')
    echo "$value"
}

get_credentials() {
    # Check if we need to get secrets from Azure Key Vault
    if [[ -z "${aad_client_secret}" ]]; then
        log "Not getting secrets from Azure Key Vault. Exiting get_credentials..."
    else
        log "Getting secrets from Azure Key Vault. Using the following passed variables: $2, $1, $3, $4, $5, $6"
        PCOIP_REGISTRATION_CODE=$(get_access_token $2 $1 $3 $4)
        AD_SERVICE_ACCOUNT_PASSWORD=$(get_access_token $2 $1 $3 $5)
        CAC_TOKEN=$(get_access_token $2 $1 $3 $6)
    fi
}

download_cac() {
    log "--> Downloading CAC installer..."
    curl -L ${cac_installer_url} -o $INSTALL_DIR/cloud-access-connector.tar.gz
    tar xzvf $INSTALL_DIR/cloud-access-connector.tar.gz --no-same-owner -C /
}

wait_for_dc() {
    local timeout=25
    local interval=5

    # Wait for service account to be added. Do this last because it takes
    # a while for new AD user to be added in a new Domain Controller.
    # Note: using the domain controller IP instead of the domain name for
    #       the host is more resilient.

    log "--> Updating apt-get package list..."
    retry $timeout \
          $interval \
          "apt-get -qq update" \
          "--> Updating apt-get package list..." \
          "--> ERROR: Failed to update apt-get package list."

    log "--> Installing ldap_utils..."
    retry $timeout \
          $interval \
          "apt-get -qq install ldap-utils" \
          "--> Installing ldap_utils..." \
          "--> ERROR: Failed to install ldap-utils."

    timeout=1200
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
          "netcat -vz ${domain_name} 636" \
          "--> Trying to contact ${domain_name}:636." \
          "--> ERROR: Timed out trying to contact ${domain_name}:636. Continuing..."
}

install_cac() {
    log "--> Installing Cloud Access Connector..."
    local retries=10
    local args=""

    log "--> Running command: $CAC_BIN_PATH install"
    log "--> CAC install options:"
    log "  -t <cac_token>"
    log "  --accept-policies"
    log "  --sa-user <ad_service_account_username>"
    log "  --sa-password <ad_service_account_password>"
    log "  --domain ${domain_name}"
    log "  --domain-group ${domain_group}"
    log "  --reg-code <pcoip_registration_code>"
    log "  --retrieve-agent-state true"
    log "  --sync-interval 5"

    # Set pipefail option to return status of the connector install command
    set -o pipefail

    if [ "${ssl_key}" ]
    then
        log "  --ssl-key <ssl_key>"
        log "  --ssl-cert <ssl_cert>"
        wget ${_artifactsLocation}${ssl_key} -P $INSTALL_DIR
        wget ${_artifactsLocation}${ssl_cert} -P $INSTALL_DIR

        args=$args"--ssl-key $INSTALL_DIR/${ssl_key} "
        args=$args"--ssl-cert $INSTALL_DIR/${ssl_cert} "
    else
        log "  --insecure"
        args=$args"--insecure "
    fi

    set +x
    while true
    do
        $CAC_BIN_PATH install \
            -t $CAC_TOKEN \
            --accept-policies \
            --sa-user ${ad_service_account_username} \
            --sa-password "$AD_SERVICE_ACCOUNT_PASSWORD" \
            --domain ${domain_name} \
            --domain-group "${domain_group}" \
            --reg-code $PCOIP_REGISTRATION_CODE \
            --sync-interval 5 \
            $args \
            2>&1 | tee -a $CAC_INSTALL_LOG

        local rc=$?
        if [ $rc -eq 0 ]
        then
            log "--> Successfully installed Cloud Access Connector."
            break
        fi

        if [ $retries -eq 0 ]
        then
            log "--> ERROR: Failed to install Cloud Access Connector. No retries remaining."
            exit 1
        fi

        log "--> ERROR: Failed to install Cloud Access Connector. $retries retries remaining..."
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

get_credentials ${aad_client_secret} ${application_id} ${tenant_id} $PCOIP_REGISTRATION_CODE $AD_SERVICE_ACCOUNT_PASSWORD $CAC_TOKEN

check_required_vars

check_connector_installed

config_network

download_cac

wait_for_dc

install_cac

docker service ls

log "--> Provisioning script completed successfully."