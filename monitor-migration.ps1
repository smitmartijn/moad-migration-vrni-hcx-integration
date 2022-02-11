# this is a target script for a specific demo. Don't use without modifying.
param(
    [Parameter(Mandatory = $true)]
    # HCX Enterprise appliance
    [ValidateNotNullOrEmpty()]
    [String]$HCX_Server,
    [Parameter(Mandatory = $true)]
    # HCX Enterprise username to login with
    [ValidateNotNullOrEmpty()]
    [String]$HCX_Username,
    [Parameter(Mandatory = $true)]
    # HCX Enterprise password to login with
    [ValidateNotNullOrEmpty()]
    [securestring]$HCX_Password,
    [Parameter(Mandatory = $true)]
    # The Mobility Group name of which we'll find the status
    [ValidateNotNullOrEmpty()]
    [String]$MobilityGroupName
)

$ErrorActionPreference = 'SilentlyContinue'

# Load required modules; PowerCLI & HCX
$moduleHCX = Get-InstalledModule -Name VMware.VimAutomation.Hcx
if (!($moduleHCX)) {
    throw "Required module 'VMware.VimAutomation.Hcx' is missing. Please install it by using: Install-Module VMware.VimAutomation.Hcx"
}
if ([version]$moduleHCX.Version -lt [version]"11.5") {
    throw "Required module 'VMware.VimAutomation.Hcx' needs to be updated to 11.5+. It's at '$($moduleHCX.Version)' now. Please upgrade it by using: Update-Module VMware.VimAutomation.Hcx"
}
Import-Module VMware.VimAutomation.Hcx
Import-Module -Force "./modules/VMware.HCX.MobilityGroups.psm1"

### connect to HCX

# Build cred object for default auth if user specified username/pass
$connection_credentials = New-Object System.Management.Automation.PSCredential($HCX_Username, $HCX_Password)

$invokeRestMethodParams = @{
    "Server"   = $HCX_Server;
    "Username" = $connection_credentials.Username;
    "Password" = $connection_credentials.GetNetworkCredential().Password;
}

$custom_hcx_connection = Connect-HcxServer_Custom @invokeRestMethodParams
if ($custom_hcx_connection -eq "") {
    throw "Unable to connect to HCX Enterprise."
}

# first the the ID of the Mobility Group
$mobilityGroupID = (Get-HcxMobilityGroup -Connection $custom_hcx_connection | Where-Object { $_.entityName -eq $MobilityGroupName }).id
Write-Host "Found Mobility Group ID: $($mobilityGroupID)"

# now start checking for the migration status of this mobility group
$url = $custom_hcx_connection.Server + "/migrations?action=query"
$body = "{filter={skipDrafts=true,migrationGroupId=['$($mobilityGroupID)']},options={resultLevel='MOBILITYGROUP_ITEMS',compat=2.1}}"
#Write-Host $body

$invokeRestMethodParams = @{
    "Uri"     = $url;
    "Body"    = $body;
    "Method"  = "POST";
    "Headers" = $custom_hcx_connection.headers;
}

$migrationsRunning = $true
while ($migrationsRunning -eq $true) {
    $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing -SkipCertificateCheck
    $json = ($results | ConvertFrom-Json)
    $atLeastOneMigrationIsRunning = $false
    Write-Host "$(Get-Date) Migration status: "
    foreach ($migration in $json.data.items) {
        if ($migration.state -eq "MIGRATION_COMPLETE") {
            Write-Host "VM: $($migration.entity.entityName): Migration Complete"
        }
        else {
            Write-Host "VM: $($migration.entity.entityName): Migration Ongoing"
            $atLeastOneMigrationIsRunning = $true
        }
    }

    if ($atLeastOneMigrationIsRunning -eq $true) {
        Write-Host "There are still ongoing migrations..sleeping for 30s and checking again.."
        Start-Sleep -Seconds 30
    }
    else {
        $migrationsRunning = $false
    }
}