# vRealize Network Insight
# Download a zipfile with the recommended firewall rules for a specified application
#Requires -Version 6

param (
    [Parameter(Mandatory = $true)]
    # CSP API Token
    [ValidateNotNullOrEmpty()]
    [String]$vRNI_Cloud_API_Token,
    [Parameter(Mandatory = $true)]
    # Application name
    [ValidateNotNullOrEmpty()]
    [String]$vRNI_ApplicationName,
    [Parameter(Mandatory = $true)]
    # Output zipfile
    [ValidateNotNullOrEmpty()]
    [String]$OutFile
)


$connectionvRNI = Connect-NIServer -RefreshToken $vRNI_Cloud_API_Token
if (!$connectionvRNI) {
    throw "Unable to connect to vRealize Network Insight"
}

$app_id = (Get-vRNIApplication -Name $vRNI_ApplicationName).entity_id
Get-vRNIRecommendedRulesNsxBundle -ApplicationID $app_id -OutFile $OutFile