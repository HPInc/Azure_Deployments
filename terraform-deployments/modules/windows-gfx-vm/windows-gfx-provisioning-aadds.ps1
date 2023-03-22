# Copyright (c) 2021 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

[CmdletBinding(DefaultParameterSetName = "_AllParameterSets")]
param(

    [Parameter(Mandatory = $true)]
    [string]
    $pcoip_registration_code,

    [Parameter(Mandatory = $true)]
    [string]
    $domain_name,

    [Parameter(Mandatory = $true)]
    [string]
    $ad_service_account_username,

    [Parameter(Mandatory = $true)]
    [string]
    $ad_service_account_password,

    [Parameter(Mandatory = $false)]
    [string]
    $NVIDIA_DRIVER_URL,

    [Parameter(Mandatory = $false)]
    [string]
    $NVIDIA_DRIVER_FILENAME,

    [Parameter(Mandatory = $false)]
    [string]
    $application_id,

    [Parameter(Mandatory = $false)]
    [string]
    $aad_client_secret,

    [Parameter(Mandatory = $false)]
    [string]
    $enable_workstation_idle_shutdown,

    [Parameter(Mandatory = $false)]
    [string]
    $minutes_idle_before_shutdown,

    [Parameter(Mandatory = $false)]
    [string]
    $minutes_cpu_polling_interval,

    [Parameter(Mandatory = $false)]
    [string]
    $tenant_id
)

$AgentLocation = 'C:\Program Files\Teradici\PCoIP Agent\'
$LOG_FILE = "C:\Teradici\provisioning.log"
$NVIDIA_DIR = "C:\Program Files\NVIDIA Corporation\NVSMI"
$TERADICI_DOWNLOAD_TOKEN = "yj39yHtgj68Uv2Qf"
$PCOIP_AGENT_LOCATION_URL = "https://dl.teradici.com/${TERADICI_DOWNLOAD_TOKEN}/pcoip-agent/raw/names/pcoip-agent-graphics-exe/versions/latest/"

$DATA = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$DATA.Add("pcoip_registration_code", "${pcoip_registration_code}")
$DATA.Add("ad_service_account_password", "${ad_service_account_password}")

$ENABLE_AUTO_SHUTDOWN = [System.Convert]::ToBoolean("${enable_workstation_idle_shutdown}")
$AUTO_SHUTDOWN_IDLE_TIMER = ${minutes_idle_before_shutdown}
$CPU_POLLING_INTERVAL = ${minutes_cpu_polling_interval}

$global:restart = $false

# Retry function, defaults to trying for 5 minutes with 10 seconds intervals
function Retry([scriptblock]$Action, $Interval = 10, $Attempts = 30) {
    $Current_Attempt = 0

    while ($true) {
        $Current_Attempt++
        $rc = $Action.Invoke()

        if ($?) { return $rc }

        if ($Current_Attempt -ge $Attempts) {
            Write-Error "--> ERROR: Failed after $Current_Attempt attempt(s)." -InformationAction Continue
            Throw
        }

        Write-Information "--> Attempt $Current_Attempt failed. Retrying in $Interval seconds..." -InformationAction Continue
        Start-Sleep -Seconds $Interval
    }
}


Function Get-AccessToken
(
    [string]$application_id,
    [string]$aad_client_secret,
    [string]$oath2Uri
) {
    $body = 'grant_type=client_credentials'
    $body += '&client_id=' + $application_id
    $body += '&client_secret=' + [Uri]::EscapeDataString($aad_client_secret)
    $body += '&resource=' + [Uri]::EscapeDataString("https://vault.azure.net")
    $response = Invoke-RestMethod -Method POST -Uri $oath2Uri -Headers @{} -Body $body

    return $response.access_token
}

Function Decrypt-Credentials {
    $oath2Uri = "https://login.microsoftonline.com/${tenant_id}/oauth2/token"
    $accessToken = Get-AccessToken ${application_id} ${aad_client_secret} $oath2Uri

    $pcoipRegCodeQueryUrl = "${pcoip_registration_code}" + '?api-version=7.0'       
    $headers = @{ 'Authorization' = "Bearer $accessToken"; "Content-Type" = "application/json" }
    $response = Invoke-RestMethod -Method GET -Ur $pcoipRegCodeQueryUrl -Headers $headers
    $DATA."pcoip_registration_code" = $response.value

    $adAdminPasswordCodeQueryUrl = "${ad_service_account_password}" + '?api-version=7.0'       
    $headers = @{ 'Authorization' = "Bearer $accessToken"; "Content-Type" = "application/json" }
    $response = Invoke-RestMethod -Method GET -Ur $adAdminPasswordCodeQueryUrl -Headers $headers
    $DATA."ad_service_account_password" = $response.value
}

function Nvidia-is-Installed {
    if (!(test-path $NVIDIA_DIR)) {
        return $false
    }

    cd $NVIDIA_DIR
    & .\nvidia-smi.exe
    return $?
    return $false
}

function Nvidia-Install {
    "################################################################"
    "Installing NVIDIA driver..."
    "################################################################"

    if (Nvidia-is-Installed) {
        "--> NVIDIA driver is already installed. Skipping..."
        return
    }

    mkdir 'C:\Nvidia'
    $driverDirectory = "C:\Nvidia"

    # $nvidiaInstallerUrl = $NVIDIA_DRIVER_URL + $NVIDIA_DRIVER_FILENAME
    $destFile = $driverDirectory + "\" + $NVIDIA_DRIVER_FILENAME
    $wc = New-Object System.Net.WebClient

    "--> Downloading NVIDIA GRID driver from $NVIDIA_DRIVER_URL..."
    Retry -Action { $wc.DownloadFile($NVIDIA_DRIVER_URL, $destFile) }
    "--> NVIDIA GRID driver downloaded."

    "--> Installing NVIDIA GRID Driver..."
    $ret = Start-Process -FilePath $destFile -ArgumentList "/s /noeula /noreboot" -PassThru -Wait

    if (!(Nvidia-is-Installed)) {
        "--> ERROR: Failed to install NVIDIA GRID driver."
        exit 1
    }

    "--> NVIDIA GRID driver installed successfully."
    # $global:restart = $true
    Restart-Computer -Force
}

function PCoIP-Agent-is-Installed {
    Get-Service "PCoIPAgent"
    return $?
}

function PCoIP-Agent-Install {
    "################################################################"
    "Installing PCoIP graphics agent..."
    "################################################################"

    if (PCoIP-Agent-is-Installed) {
        "--> PCoIP graphics agent is already installed. Skipping..."
        return
    }

    $agentInstallerDLDirectory = "C:\Teradici"
    $agent_filename = "pcoip-agent-graphics_latest.exe"
    $pcoipAgentInstallerUrl = $PCOIP_AGENT_LOCATION_URL + $agent_filename
    $destFile = $agentInstallerDLDirectory + '\' + $agent_filename
    $wc = New-Object System.Net.WebClient

    "--> Downloading PCoIP graphics agent from $pcoipAgentInstallerUrl..."
    Retry -Action { $wc.DownloadFile($pcoipAgentInstallerUrl, $destFile) }
    "--> Teradici PCoIP graphics agent downloaded: $agent_filename"

    "--> Installing Teradici PCoIP graphics agent..."
    Start-Process -FilePath $destFile -ArgumentList "/S /nopostreboot _?$destFile" -PassThru -Wait

    if (!(PCoIP-Agent-is-Installed)) {
        "--> ERROR: Failed to install PCoIP graphics agent."
        exit 1
    }

    "--> Teradici PCoIP graphics agent installed successfully."
    $global:restart = $true
}

function PCoIP-Agent-Register {
    "################################################################"
    "Registering PCoIP agent..."
    "################################################################"

    cd 'C:\Program Files\Teradici\PCoIP Agent'

    "--> Checking for existing PCoIP License..."
    & .\pcoip-validate-license.ps1
    if ( $LastExitCode -eq 0 ) {
        "--> Found valid license."
        return
    }

    # License registration may have intermittent failures
    $Interval = 10
    $Timeout = 600
    $Elapsed = 0

    do {
        $Retry = $false
        & .\pcoip-register-host.ps1 -RegistrationCode $DATA."pcoip_registration_code"
        # The script already produces error message

        if ( $LastExitCode -ne 0 ) {
            if ($Elapsed -ge $Timeout) {
                "--> ERROR: Failed to register PCoIP agent."
                exit 1
            }

            "--> Retrying in $Interval seconds... (Timeout in $($Timeout-$Elapsed) seconds)"
            $Retry = $true
            Start-Sleep -Seconds $Interval
            $Elapsed += $Interval
        }
    } while ($Retry)

    "--> PCoIP agent registered successfully."
}

function Cam-Idle-Shutdown-is-Installed {
    Get-Service "CamIdleShutdown"
    return $?
}
function Install-Idle-Shutdown {
    "################################################################"
    "Installing Idle Shutdown..."
    "################################################################"
    $path = "C:\Program Files\Teradici\PCoIP Agent\bin"
    cd $path

    # Skip if already installed
    if (Cam-Idle-Shutdown-is-Installed) {  
        "--> Idle shutdown is already installed. Skipping..."
        return 
    }

    # Install service and check for success
    $ret = .\IdleShutdownAgent.exe -install
    if ( !$? ) {
        "ERROR: failed to install idle shutdown."
        exit 1
    }
    "--> Idle shutdown is successfully installed."

    $idleShutdownRegKeyPath = "HKLM:SOFTWARE\Teradici\CAMShutdownIdleMachineAgent"
    $idleTimerRegKeyName = "MinutesIdleBeforeShutdown"
    $cpuPollingIntervalRegKeyName = "PollingIntervalMinutes"

    if (!(Test-Path $idleShutdownRegKeyPath)) {
        New-Item -Path $idleShutdownRegKeyPath -Force
    }
    New-ItemProperty -Path $idleShutdownRegKeyPath -Name $idleTimerRegKeyName -Value $AUTO_SHUTDOWN_IDLE_TIMER -PropertyType DWORD -Force
    New-ItemProperty -Path $idleShutdownRegKeyPath -Name $cpuPollingIntervalRegKeyName -Value $CPU_POLLING_INTERVAL -PropertyType DWORD -Force

    if (!$ENABLE_AUTO_SHUTDOWN) {
        $svc = Get-Service -Name "CAMIdleShutdown"
        "Attempting to disable CAMIdleShutdown..."
        try {
            if ($svc.Status -ne "Stopped") {
                Start-Sleep -s 15
                $svc.Stop()
                $svc.WaitForStatus("Stopped", 180)
            }
            Set-Service -InputObject $svc -StartupType "Disabled"
            $status = if ($?) { "succeeded" } else { "failed" }
            $msg = "Disabling CAMIdleShutdown {0}." -f $status
            "$msg"
        }
        catch {
            throw "ERROR: Failed to disable CAMIdleShutdown service."
        }
    }
}
function Join-Domain 
(
    [string]$domain_name,
    [string]$ad_service_account_username,
    [string]$ad_service_account_password
) {
    $obj = Get-WmiObject -Class Win32_ComputerSystem

    if ($obj.PartOfDomain) {
        if ($obj.Domain -ne "$domain_name") {
            "ERROR: Trying to join '$domain_name' but computer is already joined to '$obj.Domain'"
            continue
        }

        "Computer already part of the '$obj.Domain' domain."
        return
    } 

    "Computer not part of a domain. Joining $domain_name..."

    $username = "$ad_service_account_username" + "@" + "$domain_name"
    #$password = ConvertTo-SecureString $DATA."ad_service_account_password" -AsPlainText -Force
    $password = $ad_service_account_password | ConvertTo-SecureString -asPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($username, $password)

    # Looping in case Domain Controller is not yet available
    $Interval = 10
    $Timeout = 3600
    $Elapsed = 0

    do {
        Try {
            $Retry = $false
            # Don't do -Restart here because there is no log showing the restart
            Add-Computer -DomainName "$domain_name" -Credential $cred -Verbose -Force -ErrorAction Stop
        }

        # The same Error, System.InvalidOperationException, is thrown in these cases: 
        # - when Domain Controller not reachable (retry waiting for DC to come up)
        # - when password is incorrect (retry because user might not be added yet)
        # - when computer is already in domain
        Catch [System.InvalidOperationException] {
            $_.Exception.Message
            if (($Elapsed -ge $Timeout) -or ($_.Exception.GetType().FullName -match "AddComputerToSameDomain,Microsoft.PowerShell.Commands.AddComputerCommand")) {
                exit 1
            }

            "Retrying in $Interval seconds... (Timeout in $($Timeout-$Elapsed) seconds)"
            $Retry = $true
            Start-Sleep -Seconds $Interval
            $Elapsed += $Interval
        }
        Catch {
            $_.Exception.Message
            exit 1
        }
    } while ($Retry)

    $obj = Get-WmiObject -Class Win32_ComputerSystem
    if (!($obj.PartOfDomain) -or ($obj.Domain -ne "$domain_name") ) {
        "ERROR: failed to join $domain_name"
        exit 1
    }

    "Successfully joined $domain_name"
    $global:restart = $true
}

Start-Transcript -path $LOG_FILE -append

"--> Script running as user '$(whoami)'."
if ([string]::IsNullOrWhiteSpace("${tenant_id}")) {
    Write-Output "Not using Key Vault Secrets. Skipping .."
}
else {
    Write-Output "Decrypting Key Vault Secrets .."
    Decrypt-Credentials
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Nvidia-Install

PCoIP-Agent-Install

if ("${pcoip_registration_code}" -ne "null") {
    PCoIP-Agent-Register
}

Install-Idle-Shutdown

Write-Output "Joining Domain"

Join-Domain $domain_name $ad_service_account_username $ad_service_account_password

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    "--> Running as Administrator..."
}
else {
    "--> Not running as Administrator..."
}

if ($global:restart) {
    "--> Restart required. Restarting..."
    Restart-Computer -Force
}
else {
    "--> No restart required."
}
