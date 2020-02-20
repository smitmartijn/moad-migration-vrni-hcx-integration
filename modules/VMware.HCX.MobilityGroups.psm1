

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
        If (-Not $global:hcxConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxServer " } Else {
            $url = $global:hcxConnection.Server + "/mobility/groups/query"

            $body = @{
                "filters" = @{
                    "pagination" = @{
                        "page" = 1
                        "limit" = 5
                    }
                }
            }

            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-WebRequest -Uri $url -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $results = Invoke-WebRequest -Uri $url -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing
            }

            $json = ($results | ConvertFrom-Json)
            $json

        }
}