# vRealize Network Insight and VMware HCX Integration
# Martijn Smit (@smitmartijn)
# msmit@vmware.com
# Version 1.0
#
# Copyright 2020 VMware, Inc.
# SPDX-License-Identifier: BSD-2-Clause
#Requires -Version 6

[CmdletBinding(DefaultParameterSetName = "vRNI")]
param (
  [Parameter(Mandatory = $true, ParameterSetName = "vRNI")]
  # vRealize Network Insight Platform Server
  [ValidateNotNullOrEmpty()]
  [String]$vRNI_Server,
  [Parameter(Mandatory = $false, ParameterSetName = "vRNI")]
  # vRealize Network Insight Platform username to login with
  [ValidateNotNullOrEmpty()]
  [String]$vRNI_Username,
  [Parameter(Mandatory = $false, ParameterSetName = "vRNI")]
  # vRealize Network Insight Platform password to login with
  [ValidateNotNullOrEmpty()]
  [securestring]$vRNI_Password,
  [Parameter (Mandatory = $false)]
  # PSCredential object containing vRNI API authentication credentials
  [PSCredential]$vRNI_Credential,
  [Parameter(Mandatory = $true)]
  # HCX Enterprise appliance
  [ValidateNotNullOrEmpty()]
  [String]$HCX_Server,
  [Parameter(Mandatory = $false)]
  # HCX Enterprise username to login with
  [ValidateNotNullOrEmpty()]
  [String]$HCX_Username,
  [Parameter(Mandatory = $false)]
  # HCX Enterprise password to login with
  [ValidateNotNullOrEmpty()]
  [securestring]$HCX_Password,
  [Parameter (Mandatory = $false)]
  # PSCredential object containing vRNI API authentication credentials
  [PSCredential]$HCX_Credential,
  [Parameter(Mandatory = $true)]
  # Hostname of the destination vCenter to create the Mobility Groups for
  [ValidateNotNullOrEmpty()]
  [String]$HCX_DestinationVC,
  [Parameter(Mandatory = $true)]
  # Hostname of the destination HCX Cloud appliance to create the Mobility Groups for
  [ValidateNotNullOrEmpty()]
  [String]$HCX_DestinationCloud,
  [Parameter(Mandatory = $false)]
  # Array of application names to limit the sync to
  [array[]]$Sync_Applications = @(),
  [Parameter(Mandatory = $true, ParameterSetName = "vRNICloud")]
  # String with the CSP API Refresh token for access to vRNI Cloud
  [string]$vRNI_Cloud_API_Token,
  [ValidateNotNullOrEmpty()]
  [switch]$SkipCertificateCheck
)

$ErrorActionPreference = 'SilentlyContinue'

# Load required modules; PowerCLI HCX, a custom extension to that module, and PowervRNI
$moduleHCX = Get-InstalledModule -Name VMware.VimAutomation.Hcx
if (!($moduleHCX)) {
  throw "Required module 'VMware.VimAutomation.Hcx' is missing. Please install it by using: Install-Module VMware.VimAutomation.Hcx"
}
if ([version]$moduleHCX.Version -lt [version]"11.5") {
  throw "Required module 'VMware.VimAutomation.Hcx' needs to be updated to 11.5+. It's at '$($moduleHCX.Version)' now. Please upgrade it by using: Update-Module VMware.VimAutomation.Hcx"
}
Import-Module VMware.VimAutomation.Hcx
# Load the HCX extension for Mobility Group management
Import-Module -Force "./modules/VMware.HCX.MobilityGroups.psm1"

# PowervRNI
$modulePowervRNI = Get-InstalledModule -Name PowervRNI
if (!($modulePowervRNI)) {
  throw "Required module 'PowervRNI' is missing. Please install it by using: Install-Module PowervRNI"
}
if ([version]$modulePowervRNI.Version -lt [version]"1.8") {
  throw "Required module 'PowervRNI' needs to be updated to 1.8+. It's at '$($modulePowervRNI.Version)' now. Please upgrade it by using: Update-Module PowervRNI"
}
Import-Module -Force PowervRNI
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Are we connecting to vRNI on-prem or vRNI Cloud?
if ($PSCmdlet.ParameterSetName -eq "vRNI") {
  # Make sure either -Credential is set, or both -Username and -Password
  if (($PsBoundParameters.ContainsKey("vRNI_Credential") -And $PsBoundParameters.ContainsKey("vRNI_Username")) -Or
    ($PsBoundParameters.ContainsKey("vRNI_Credential") -And $PsBoundParameters.ContainsKey("vRNI_Password"))) {
    throw "Specify either -Credential or -Username to authenticate (if using -Username and omitting -Password, a prompt will be given)"
  }

  # Build cred object for default auth if user specified username/pass
  $connection_credentials = ""
  if ($PsBoundParameters.ContainsKey("vRNI_Username")) {
    # Is the -Password omitted? Prompt securely
    if (!$PsBoundParameters.ContainsKey("vRNI_Password")) {
      $connection_credentials = Get-Credential -UserName $vRNI_Username -Message "vRealize Network Insight Platform Authentication"
    }
    # If the password has been given in cleartext,
    else {
      $connection_credentials = New-Object System.Management.Automation.PSCredential($vRNI_Username, $vRNI_Password)
    }
  }
  # If a credential object was given as a parameter, use that
  elseif ($PSBoundParameters.ContainsKey("vRNI_Credential")) {
    $connection_credentials = $vRNI_Credential
  }
  # If no -Username or -Credential was given, prompt for credentials
  elseif (!$PSBoundParameters.ContainsKey("vRNI_Credential")) {
    $connection_credentials = Get-Credential -Message "vRealize Network Insight Platform Authentication"
  }

  $connectionvRNI = Connect-vRNIServer -Server $vRNI_Server -Username $connection_credentials.Username -Password $connection_credentials.GetNetworkCredential().Password
}
else {
  $connectionvRNI = Connect-NIServer -RefreshToken $vRNI_Cloud_API_Token
}

if (!$connectionvRNI) {
  throw "Unable to connect to vRealize Network Insight"
}

# First, get a list of all applications that are in vRNI
# Are we looking for specified applications?
if ($Sync_Applications.Count -gt 0) {
  # If we are looking for specified applications, go through the specified apps and look them up individually
  $vRNI_applications = @()
  foreach ($app in $Sync_Applications) {
    $vRNI_app = Get-vRNIApplication -Connection $connectionvRNI -Name $app
    if ($vRNI_app) {
      # Save the located app to the array that we'll pass onto HCX
      $vRNI_applications += $vRNI_app
    }
  }
}
else {
  # No specified applications, so get all applications
  $vRNI_applications = @()
  $vRNI_applications += Get-vRNIApplication -Connection $connectionvRNI
}

# Now that we've got the applications, let's find the VMs associated with this application
$application_list = @()

foreach ($app in $vRNI_applications) {
  # Placeholder record to add to the array that is being passed to HCX later
  $application_record = @{
    "name"    = $app.name
    "members" = @()
  }
  # Retrieve the member VMs on the current application
  $memberVMs = Get-vRNIApplicationMemberVM -Application $app
  $entityIDs = @()
  foreach ($memberVM in $memberVMs) {
    # Only save VirtualMachines for now
    if ($memberVM.entity_type -eq "VirtualMachine") {
      $entityIDs += $memberVM.entity_id
    }
  }

  # Continue to the next application, if we don't have any VMs
  if (!($entityIDs)) {
    continue
  }

  # We now have a list of entity IDs that belong to the application. These need to be translated to VM Names and VM OIDs
  $VMInfo = Get-vRNIEntityNames -EntityIDs $entityIDs -EntityType VirtualMachine
  foreach ($vm in $VMInfo) {
    # Store them like this, as New-HcxMobilityGroup takes this format as a parameter
    $vm_record = @{
      "name" = $vm.entity.name
      "id"   = $vm.entity.vendor_id
    }
    $application_record.members += $vm_record
  }

  # Save the application record to the global app list
  $application_list += $application_record
}

# Sanity check
if (!($application_list)) {
  throw "No applications to synchronise to VMware HCX."
}

# Connect to HCX. We need both the VAMI connection (to get the VC UUID) and the regular connection (Mobility Groups)

# Make sure either -HCX_Credential is set, or both -HCX_Username and -HCX_Password
if (($PsBoundParameters.ContainsKey("HCX_Credential") -And $PsBoundParameters.ContainsKey("HCX_Username")) -Or
  ($PsBoundParameters.ContainsKey("HCX_Credential") -And $PsBoundParameters.ContainsKey("HCX_Password"))) {
  throw "Specify either -HCX_Credential or -HCX_Username to authenticate (if using -HCX_Username and omitting -HCX_Password, a prompt will be given)"
}

# Build cred object for default auth if user specified username/pass
$connection_credentials = ""
if ($PsBoundParameters.ContainsKey("HCX_Username")) {
  # Is the -Password omitted? Prompt securely
  if (!$PsBoundParameters.ContainsKey("HCX_Password")) {
    $connection_credentials = Get-Credential -UserName $HCX_Username -Message "VMware HCX Authentication"
  }
  # If the password has been given
  else {
    $connection_credentials = New-Object System.Management.Automation.PSCredential($HCX_Username, $HCX_Password)
  }
}
# If a credential object was given as a parameter, use that
elseif ($PSBoundParameters.ContainsKey("HCX_Credential")) {
  $connection_credentials = $HCX_Credential
}
# If no -Username or -Credential was given, prompt for credentials
elseif (!$PSBoundParameters.ContainsKey("HCX_Credential")) {
  $connection_credentials = Get-Credential -Message "VMware HCX Authentication"
}

$invokeRestMethodParams = @{
  "Server"   = $HCX_Server;
  "Username" = $connection_credentials.Username;
  "Password" = $connection_credentials.GetNetworkCredential().Password;
}

$hcx_connection = Connect-HcxServer @invokeRestMethodParams
if ($hcx_connection -eq "") {
  throw "Unable to connect to HCX!"
}

$invokeRestMethodParams.Add("SkipCertificateCheck", $True)
$custom_hcx_connection = Connect-HcxServer_Custom @invokeRestMethodParams
if ($custom_hcx_connection -eq "") {
  throw "Unable to connect to HCX Enterprise."
}

# Get source HCX and vCenter UUIDs (we need that to create the Mobility Groups)
$source_vc = Get-HCXSite -source -Server $HCX_Server
$Source_VC_UUID = $source_vc.Id

# Find the destination vCenter UUID
$destination_vc = Get-HCXSite -Destination -Server $HCX_Server -Name $HCX_DestinationVC
if ($destination_vc -eq "") {
  throw "Unable to find the destination vCenter instance. Make sure vCenter '$($HCX_DestinationVC)' is paired with your HCX Enterprise instance."
}
# Save the vCenter UUID
$Destination_VC_UUID = $destination_vc.Id

# Find the destination HCX Cloud UUID
$destination_hcx = Get-HCXSitePairing -Server $HCX_Server -Url "https://$($HCX_DestinationCloud)"
if ($destination_hcx -eq "") {
  throw "Unable to find the destination HCX Cloud instance. Make sure HCX Cloud '$($HCX_DestinationCloud)' is paired with your HCX Enterprise instance."
}
# Save the HCX Cloud appliance UUID
$Destination_HCX_UUID = $destination_hcx.Id

$newGroup = "";
$timestamp = (Get-Date).tostring("yyyy-MM-dd")

foreach ($application in $application_list) {
  # Adding HCX Mobility group
  try {
    $newGroup = New-HcxMobilityGroup -Connection $custom_hcx_connection -Name "vRNI_$($application.name)_$($timestamp)" -SourceVC_UUID $Source_VC_UUID -DestinationHCX_UUID $Destination_HCX_UUID -DestinationVC_UUID $Destination_VC_UUID -VMs $application.members
  }
  catch {
    continue
  }
}

if ($PSCmdlet.ParameterSetName -eq "vRNI") {
  Disconnect-vRNIServer
}

Write-Host ($newGroup | ConvertTo-Json)
