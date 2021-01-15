# Copyright (c) 2020 Teradici Corporation
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
    $application_id,

    [Parameter(Mandatory = $false)]
    [string]
    $tenant_id,

    [Parameter(Mandatory = $false)]
    [string]
    $aad_client_secret
)

$AgentLocation = 'C:\Program Files\Teradici\PCoIP Agent\'
$LOG_FILE = "C:\Teradici\provisioning.log"
$PCOIP_AGENT_FILENAME = ""
$PCOIP_AGENT_LOCATION_URL = "https://downloads.teradici.com/win/stable/"

#Disable Scheulded Tasks: ServerManager
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

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

Function Get-Secret
(   
    [string]$application_id,
    [string]$aad_client_secret,
    [string]$tenant_id,
    [string]$secret_identifier
) {
    $oath2Uri = "https://login.microsoftonline.com/$tenant_id/oauth2/token"
  
    $accessToken = Get-AccessToken $application_id $aad_client_secret $oath2Uri

    $queryUrl = "$secret_identifier" + '?api-version=7.0'       
  
    $headers = @{ 'Authorization' = "Bearer $accessToken"; "Content-Type" = "application/json" }

    $response = Invoke-RestMethod -Method GET -Ur $queryUrl -Headers $headers
  
    $result = $response.value

    return $result
}

function PCoIP-Agent-is-Installed {
    Get-Service "PCoIPAgent"
    return $?
}

function PCoIP-Agent-Install {
    "################################################################"
    "Installing PCoIP standard agent..."
    "################################################################"

    if (PCoIP-Agent-is-Installed) {
        "--> PCoIP standard agent is already installed. Skipping..."
        return
    }

    $agentInstallerDLDirectory = "C:\Teradici"
    if (![string]::IsNullOrEmpty($PCOIP_AGENT_FILENAME)) {
        "--> Using user-specified PCoIP standard agent filename..."
        $agent_filename = $PCOIP_AGENT_FILENAME
    }
    else {
        "--> Using default latest PCoIP standard agent..."
        $agent_latest = $PCOIP_AGENT_LOCATION_URL + "latest-standard-agent.json"
        $wc = New-Object System.Net.WebClient

        "--> Checking for the latest PCoIP standard agent version from $agent_latest..."
        $string = Retry -Action { $wc.DownloadString($agent_latest) }

        $agent_filename = $string | ConvertFrom-Json | Select-Object -ExpandProperty "filename"
    }
    $pcoipAgentInstallerUrl = $PCOIP_AGENT_LOCATION_URL + $agent_filename
    $destFile = $agentInstallerDLDirectory + '\' + $agent_filename
    $wc = New-Object System.Net.WebClient

    "--> Downloading PCoIP standard agent from $pcoipAgentInstallerUrl..."
    Retry -Action { $wc.DownloadFile($pcoipAgentInstallerUrl, $destFile) }
    "--> Teradici PCoIP standard agent downloaded: $agent_filename"

    "--> Installing Teradici PCoIP standard agent..."
    Start-Process -FilePath $destFile -ArgumentList "/S /nopostreboot _?$destFile" -PassThru -Wait

    if (!(PCoIP-Agent-is-Installed)) {
        "--> ERROR: Failed to install PCoIP standard agent."
        exit 1
    }

    "--> Teradici PCoIP standard agent installed successfully."
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
        & .\pcoip-register-host.ps1 -RegistrationCode $pcoip_registration_code
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

function Join-Domain 
(
    [string]$domain_name,
    [string]$ad_service_account_username,
    [string]$ad_service_account_password
) {
    Write-Output "Passed Variables $domain_name ; $ad_service_account_username ; $ad_service_account_password"
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
    $password = ConvertTo-SecureString $ad_service_account_password -AsPlainText -Force
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

#Decrypt Teradici Reg Key and AD Service Account Password
if (!($aad_client_secret -eq $null -or $aad_client_secret -eq "")) {
    Write-Output "Running Get-Secret!"
    $pcoip_registration_code = Get-Secret $application_id $aad_client_secret $tenant_id $pcoip_registration_code
    $ad_service_account_password = Get-Secret $application_id $aad_client_secret $tenant_id $ad_service_account_password
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

PCoIP-Agent-Install

PCoIP-Agent-Register

#Join Domain Controller
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
