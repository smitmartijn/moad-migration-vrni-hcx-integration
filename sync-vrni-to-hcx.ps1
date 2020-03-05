param (
    [Parameter(Mandatory=$true)]
        # vRealize Network Insight Platform Server
        [ValidateNotNullOrEmpty()]
        [String]$vRNI_Server,
    [Parameter(Mandatory=$true)]
        # vRealize Network Insight Platform username to login with
        [ValidateNotNullOrEmpty()]
        [String]$vRNI_Username,
    [Parameter(Mandatory=$true)]
        # vRealize Network Insight Platform password to login with
        [ValidateNotNullOrEmpty()]
        [String]$vRNI_Password,
    [Parameter(Mandatory=$true)]
        # HCX Enterprise appliance
        [ValidateNotNullOrEmpty()]
        [String]$HCX_Server,
    [Parameter(Mandatory=$true)]
        # HCX Enterprise username to login with
        [ValidateNotNullOrEmpty()]
        [String]$HCX_Username,
    [Parameter(Mandatory=$true)]
        # HCX Enterprise password to login with
        [ValidateNotNullOrEmpty()]
        [String]$HCX_Password,
    [Parameter(Mandatory=$true)]
        # Hostname of the destination vCenter to create the Mobility Groups for
        [ValidateNotNullOrEmpty()]
        [String]$HCX_DestinationVC,
    [Parameter(Mandatory=$true)]
        # Hostname of the destination HCX Cloud appliance to create the Mobility Groups for
        [ValidateNotNullOrEmpty()]
        [String]$HCX_DestinationCloud
)

Import-Module VMware.VimAutomation.Hcx -Force
Import-Module "./modules/VMware.HCX.MobilityGroups.psm1" -Force
Import-Module "./modules/PowervRNI/PowervRNI.psm1" -Force

# @lamw function
Function My-Logger {
    param(
        [Parameter(Mandatory=$true)]
        [String]$message,
        [Parameter(Mandatory=$false)]
        [String]$color = "Green"
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
}

My-Logger -message "Connecting to vRealize Network Insight.."
$connectionvRNI = Connect-vRNIServer -Server $vRNI_Server -Username $vRNI_Username -Password $vRNI_Password

if(!$connectionvRNI) {
    throw "Unable to connect to vRealize Network Insight"
}

# First, get a list of all applications that are in vRNI
My-Logger -message "Retrieving all applications.."
$vRNI_applications = Get-vRNIApplication -Connection $connectionvRNI
$application_list = @()

foreach($app in $vRNI_applications)
{
    $application_record = @{
        "name" = $app.name
        "members" = @()
    }
    #Write-Host "App Name: $($app.name)"
    $memberVMs = Get-vRNIApplicationMemberVM -Application $app
    $entityIDs = @()
    foreach($memberVM in $memberVMs) {
        if($memberVM.entity_type -eq "VirtualMachine") {
            $entityIDs += $memberVM.entity_id
        }
    }

    if(!($entityIDs)) {
        continue
    }

    # We now have a list of entity IDs that belong to the application. These need to be translated to VM Names and VM OIDs
    $VMInfo = Get-vRNIEntityNames -EntityIDs $entityIDs -EntityType VirtualMachine
    foreach($vm in $VMInfo)
    {
        # Store them like this, as New-HcxMobilityGroup takes this format as a parameter
        $vm_record = @{
            "name" = $vm.entity.name
            "id" = $vm.entity.vendor_id
        }
        $application_record.members += $vm_record
    }

    # Save the application record to the global app list
    $application_list += $application_record

    My-Logger -message "Found application: '$($app.name)' with $($application_record.members.Count) VMs" -color "Gray"
}

# Sanity check
if(!($application_list)) {
    throw "No applications to synchronise to VMware HCX."
}

# Connect to HCX. We need both the VAMI connection (to get the VC UUID) and the regular connection (Mobility Groups)
My-Logger -message "Connecting to VMware HCX.."
$hcx_connection = Connect-HcxServer -Server $HCX_Server -Username $HCX_Username -Password $HCX_Password
$custom_hcx_connection = Connect-HcxServer_Custom -Server $HCX_Server -Username $HCX_Username -Password $HCX_Password
if($custom_hcx_connection -eq "") {
    throw "Unable to connect to HCX Enterprise."
}

# Get source HCX and vCenter UUIDs (we need that to create the Mobility Groups)
$source_vc = Get-HCXSite -source -Server $HCX_Server
$Source_VC_UUID  = $source_vc.Id

# Find the destination vCenter UUID
$destination_vc = Get-HCXSite -Destination -Server $HCX_Server -Name $HCX_DestinationVC
if($destination_vc -eq "") {
    throw "Unable to find the destination vCenter instance. Make sure vCenter '$($HCX_DestinationVC)' is paired with your HCX Enterprise instance."
}
# Save the vCenter UUID
$Destination_VC_UUID = $destination_vc.Id

# Find the destination HCX Cloud UUID
$destination_hcx = Get-HCXSitePairing -Server $HCX_Server -Url "https://$($HCX_DestinationCloud)"
if($destination_hcx -eq "") {
    throw "Unable to find the destination HCX Cloud instance. Make sure HCX Cloud '$($HCX_DestinationCloud)' is paired with your HCX Enterprise instance."
}
# Save the HCX Cloud appliance UUID
$Destination_HCX_UUID = $destination_hcx.Id


$timestamp = (Get-Date).tostring("yyyy-MM-dd")

foreach($application in $application_list)
{
    # Adding HCX Mobility group
    try {
        $newGroup = New-HcxMobilityGroup -Connection $custom_hcx_connection -Name "vRNI_$($application.name)_$($timestamp)" -SourceVC_UUID $Source_VC_UUID -DestinationHCX_UUID $Destination_HCX_UUID -DestinationVC_UUID $Destination_VC_UUID -VMs $application.members
    }
    catch {
        if($_.Exception -like "*already exists*") {
            My-Logger -message "Mobility Group '$($application.name)_$($timestamp)' already exists - skipping" -color "Gray"
        }
        continue
    }

    My-Logger -message "Created Mobility Group: '$($application.name)_$($timestamp)'"
}

Disconnect-vRNIServer