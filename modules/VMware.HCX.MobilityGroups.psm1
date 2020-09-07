# vRealize Network Insight and VMware HCX Integration
# Martijn Smit (@smitmartijn)
# msmit@vmware.com
# Version 1.0
#
# Copyright 2020 VMware, Inc.
# SPDX-License-Identifier: BSD-2-Clause

function Get-HcxMobilityGroup {
  <#
        .NOTES
        ===========================================================================
        Created by:    Martijn Smit
        Date:          21/11/2019
        Organization:  VMware
        Blog:          http://lostdomain.org
        Twitter:       @smitmartijn
        ===========================================================================

        .SYNOPSIS

        .DESCRIPTION

        .EXAMPLE
            Get-HcxMobilityGroup
    #>
  Param (
    [Parameter(Mandatory = $true)][psobject]$Connection
  )
  If (-Not $Connection) { Write-error "HCX Auth Token not found, please run Connect-HcxServer " } Else {
    $url = $Connection.Server + "/migration/queryMobilityGroups"

    $body = '{"filter":{"skipDrafts":false},"options":{"compat":2.1}}'

    $invokeRestMethodParams = @{
      "Uri"     = $url;
      "Body"    = $body;
      "Method"  = "POST";
      "Headers" = $Connection.headers;
    }

    if ($PSVersionTable.PSEdition -eq "Core") {
      if ($Connection.SkipCertificateCheck -eq $True) {
        $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing -SkipCertificateCheck
      }
      else {
        $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
      }
    }
    else {
      $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
    }

    $json = ($results.Content | ConvertFrom-Json)
    $json.data.items
  }
}


function Remove-HcxMobilityGroup {
  <#
        .NOTES
        ===========================================================================
        Created by:    Martijn Smit
        Date:          21/11/2019
        Organization:  VMware
        Blog:          http://lostdomain.org
        Twitter:       @smitmartijn
        ===========================================================================

        .SYNOPSIS

        .DESCRIPTION

        .EXAMPLE
            Remove-HcxMobilityGroup -MigrationGroupIds ("1", "2")
    #>
  Param (
    [Parameter(Mandatory = $true)][array[]]$MigrationGroupIds,
    [Parameter(Mandatory = $true)][psobject]$Connection
  )
  If (-Not $Connection) { Write-error "HCX Auth Token not found, please run Connect-HcxServer " } Else {
    $url = $Connection.Server + "/mobility/groups/delete"

    $payload = @{
      "items" = @()
    }

    # Loop through given VMs and add them to the migrations payload
    foreach ($MG_ID in $MigrationGroupIds) {
      $tmp = @{
        "migrationGroupId" = "$MG_ID"
      }
      $payload.items += $tmp
    }


    # Convert payload into the JSON body
    $body = $payload | ConvertTo-Json -Depth 10

    $invokeRestMethodParams = @{
      "Uri"     = $url;
      "Body"    = $body;
      "Method"  = "POST";
      "Headers" = $Connection.headers;
    }

    if ($PSVersionTable.PSEdition -eq "Core") {
      if ($Connection.SkipCertificateCheck -eq $True) {
        $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing -SkipCertificateCheck
      }
      else {
        $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
      }
    }
    else {
      $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
    }

    $results
  }
}


function New-HcxMobilityGroup {
  <#
        .NOTES
        ===========================================================================
        Created by:    Martijn Smit
        Date:          20/02/2020
        Organization:  VMware
        Blog:          http://lostdomain.org
        Twitter:       @smitmartijn
        ===========================================================================

        .SYNOPSIS

        .DESCRIPTION

        .EXAMPLE
            $VCConfig = Get-HcxVCConfig
            $UUID_VC  = $VCConfig.HCXUUID
            $VMs = @(
                @{
                    "name" = "Ubuntu-Cloud-Init"
                    "id" = "vm-956"
                },
                @{
                    "name" = "Arista CVX EOS-4.21.1F"
                    "id" = "vm-130"
                }
            )

            New-HcxMobilityGroup -Name "MyGroup" -SourceVC_UUID $UUID_VC -VMs $VMs
    #>
  Param (
    [Parameter(Mandatory = $true)][String]$Name,
    [Parameter(Mandatory = $true)][String]$SourceVC_UUID,
    [Parameter(Mandatory = $true)][String]$DestinationHCX_UUID,
    [Parameter(Mandatory = $true)][String]$DestinationVC_UUID,
    [Parameter(Mandatory = $true)][psobject]$Connection,
    [Parameter(Mandatory = $true)][Hashtable[]]$VMs
  )
  If (-Not $Connection) { Write-error "HCX Auth Token not found, please run Connect-HcxServer " } Else {
    $url = $Connection.Server + "/mobility/groups"

    $payload = @{
      "items" = @(
        @{
          "name"          = $Name
          "tags"          = @("vRNI")
          "groupDefaults" = @{
            "source"      = @{
              "endpointType" = "VC"
              "endpointId"   = $Connection.HCXUUID
              "resourceType" = "VC"
              "resourceId"   = $SourceVC_UUID
            }
            "destination" = @{
              "endpointType" = "VC"
              "endpointId"   = $DestinationHCX_UUID
              "resourceType" = "VC"
              "resourceId"   = $DestinationVC_UUID
            }
          }
          "migrations"    = @()
        }
      )
    }

    # Loop through given VMs and add them to the migrations payload
    foreach ($record in $VMs) {
      $VM_record = @{
        "migrationType" = "ColdMigration"
        "entity"        = @{
          "entityId"   = $record.id
          "entityName" = $record.name
          "entityType" = "VirtualMachine"
        }
        "operationType" = "ADD"
      }
      $payload.items[0].migrations += $VM_record
    }

    # Convert payload into the JSON body
    $body = $payload | ConvertTo-Json -Depth 10

    $invokeRestMethodParams = @{
      "Uri"     = $url;
      "Body"    = $body;
      "Method"  = "POST";
      "Headers" = $Connection.headers;
    }

    try {
      if ($PSVersionTable.PSEdition -eq "Core") {
        if ($Connection.SkipCertificateCheck -eq $True) {
          $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing -SkipCertificateCheck
        }
        else {
          $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
        }
      }
      else {
        $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
      }
    }
    catch {
      # Look for known errors
      $json_error = ($_.ErrorDetails.Message | ConvertFrom-Json)
      $error_message = $json_error.items[0].errors[0].message
      if ($error_message -eq "Mobility group with same name exist.") {
        throw "HCX Mobility Group $($Name) already exists."
      }

      # Unmatched error, so just return the message from HCX
      throw $error_message
    }

    # Return
    $json = ($results | ConvertFrom-Json)
    $json.items
  }
}


Function Connect-HcxServer_Custom {
  <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/16/2018
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Connect to the HCX Enterprise Manager
        .DESCRIPTION
            This cmdlet connects to the HCX Enterprise Manager
        .EXAMPLE
            Connect-HcxServer -Server $HCXServer -Username $Username -Password $Password
    #>
  Param (
    [Parameter(Mandatory = $true)][String]$Server,
    [Parameter(Mandatory = $true)][String]$Username,
    [Parameter(Mandatory = $true)][String]$Password,
    [Parameter(Mandatory = $false)][Bool]$SkipCertificateCheck = $True
  )

  $payload = @{
    "username" = $Username
    "password" = $Password
  }
  $body = $payload | ConvertTo-Json

  $hcxLoginUrl = "https://$Server/hybridity/api/sessions"
  $headers = @{
    "Accept"      = "application/json"
    "ContentType" = "application/json"
  }

  $invokeRestMethodParams = @{
    "Uri"         = $hcxLoginUrl;
    "Body"        = $body;
    "Method"      = "POST";
    "Headers"     = $headers;
    "ContentType" = "application/json";
  }

  if ($PSVersionTable.PSEdition -eq "Core") {
    if ($SkipCertificateCheck -eq $True) {
      $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing -SkipCertificateCheck -Debug
    }
    else {
      $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
    }
  }
  else {
    $results = Invoke-WebRequest @invokeRestMethodParams -UseBasicParsing
  }

  if ($results.StatusCode -eq 200) {
    $hcxAuthToken = $results.Headers.'x-hm-authorization'

    $headers = @{
      "x-hm-authorization" = "$hcxAuthToken"
      "Content-Type"       = "application/json"
      "Accept"             = "application/json"
    }

    $res = ($results.Content | ConvertFrom-Json)
    $Connection = new-object PSObject -Property @{
      'Server'               = "https://$server/hybridity/api";
      'headers'              = $headers
      'HCXUUID'              = $res.data.endpointInfo.uuid
      'SkipCertificateCheck' = $SkipCertificateCheck
    }
    $Connection
  }
  else {
    Write-Error "Failed to connect to HCX Manager, please verify your vSphere SSO credentials"
  }
}