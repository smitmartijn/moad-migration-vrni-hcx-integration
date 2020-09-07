# vRNI and HCX Integration
This integration script between vRealize Network Insight (vRNI) and VMware HCX, allows you to streamline the application migration process.

First, use the application discovery methods within vRNI to discover the application boundaries, including the VMs (or other workloads), to form application constructs within vRNI. This integration script then synchronizes the vRNI application constructs into HCX Mobility Groups, saving you the time that it would've taken to do this manually. After the sync, you can pick up the migration process and execute the migration.

## vRNI & HCX Requirements
Before running this integration script, make sure both vRealize Network Insight and HCX are licensed with Enterprise licenses.

## Usage
```
./sync-vrni-to-hcx.ps1
```

### Parameters

`-vRNI_Server`: vRealize Network Insight Platform appliance

`-vRNI_Username`: vRNI Username to login with
`-vRNI_Password`: vRNI Password to login with - a PowerShell secure string
`-vRNI_Credential`: Optional PowerShell credential object to login with. This would be given instead of the username and password

`-HCX_Server`: HCX Enterprise appliance
`-HCX_Username`: HCX Enterprise username to login with
`-HCX_Password`: HCX Enterprise password to login with - a PowerShell secure string
`-HCX_Credential`: Optional PowerShell credential object to login with. This would be given instead of the username and password

`-HCX_DestinationVC`: Hostname of the destination vCenter to create the Mobility Groups for
`-HCX_DestinationCloud`: Hostname of the destination HCX Cloud appliance to create the Mobility Groups for

`-Sync_Applications`: Array of application names to limit the sync with. This is an optional paramater and should be formatted like this: `("MyApp1", "MyApp2", "..")`

`-SkipCertificateCheck`: Switch to skip SSL certificate validation. Without the switch, this script will expect valid certificates on vRNI and HCX

### vRNI Authentication
This script can be run against vRealize Network Insight and vRealize Network Insight Cloud. Each have different authentication methods, and there are different parameters to use:

#### vRNI Cloud

To use vRNI Cloud, only the `-vRNI_Cloud_API_Token` parameter is required. This will be the VMware Cloud Services Portal (CSP) Refresh token, which you can generate under "My Account" in CSP.

#### vRNI on-prem

For vRNI on-prem, the following (self-explanatory) parameters are required:

`-vRNI_Server your-platform-appliance -vRNI_Username myusername -vRNI_Password mypassword`

The vRNI_Password parameter is a SecureString, meaning you have to create a secure string from your plaintext password:

```
$vrni_pw = ConvertTo-SecureString 'admin' -AsPlainText -Force
./sync-vrni-to-hcx.ps1 -Password $vrni_pw
```

## Example

### Synchronising all vRNI applications
```
$vrni_pw = ConvertTo-SecureString 'admin' -AsPlainText -Force
$hcx_pw = ConvertTo-SecureString 'VMware1!' -AsPlainText -Force
./sync-vrni-to-hcx.ps1 -vRNI_Server 10.196.164.134 -vRNI_Username admin@local -vRNI_Password $vrni_pw -HCX_Server hcxe.vrni.cmbu.local -HCX_Username hcx@cmbu.local -HCX_Password $hcx_pw -HCX_DestinationVC vc-pks.vrni.cmbu.local -HCX_DestinationCloud hcxc.vrni.cmbu.local
[03-05-2020_05:19:59] Connecting to vRealize Network Insight..
[03-05-2020_05:20:01] Retrieving all applications..
[03-05-2020_05:20:20] Found application: 'onprem_imagic' with 6 VMs
[03-05-2020_05:20:22] Found application: '3TierApp02' with 1 VMs
[03-05-2020_05:20:25] Found application: 'HIVE Training' with 1 VMs
[03-05-2020_05:20:27] Found application: 'VDI Pool 1' with 8 VMs
[03-05-2020_05:20:29] Found application: 'app_mcclanahanc' with 2 VMs
[03-05-2020_05:20:31] Found application: 'Top-Video' with 15 VMs
[03-05-2020_05:20:33] Found application: 'F5-3TierApp05' with 5 VMs
[03-05-2020_05:20:34] Connecting to VMware HCX..
[03-05-2020_05:20:48] Created Mobility Group: 'onprem_imagic_2020-03-05'
[03-05-2020_05:20:49] Created Mobility Group: '3TierApp02_2020-03-05'
[03-05-2020_05:20:50] Created Mobility Group: 'HIVE Training_2020-03-05'
[03-05-2020_05:20:51] Created Mobility Group: 'VDI Pool 1_2020-03-05'
[03-05-2020_05:20:52] Created Mobility Group: 'app_mcclanahanc_2020-03-05'
[03-05-2020_05:20:53] Created Mobility Group: 'Top-Video_2020-03-05'
[03-05-2020_05:20:54] Created Mobility Group: 'F5-3TierApp05_2020-03-05'
```

### Synchronising selective vRNI applications:
```
$vrni_pw = ConvertTo-SecureString 'admin' -AsPlainText -Force
$hcx_pw = ConvertTo-SecureString 'VMware1!' -AsPlainText -Force
./sync-vrni-to-hcx.ps1 -vRNI_Server 10.196.164.134 -vRNI_Username admin@local -vRNI_Password $vrni_pw -HCX_Server hcxe.vrni.cmbu.local -HCX_Username hcx@cmbu.local -HCX_Password $hcx_pw -HCX_DestinationVC vc-pks.vrni.cmbu.local -HCX_DestinationCloud hcxc.vrni.cmbu.local -Sync_Applications ("app_hcx-3tierapp", "Top-Video") -SkipCertificateCheck
```

### Synchronising from vRNI Cloud
```
./sync-vrni-to-hcx.ps1 -vRNI_Cloud_API_Token 'xxx' -HCX_Server hcxe.vrni.cmbu.local -HCX_Username hcx@cmbu.local -HCX_Password 'xxx' -HCX_DestinationVC vc-pks.vrni.cmbu.local -HCX_DestinationCloud hcxc.vrni.cmbu.local
```

## Installation

This PowerShell script requires at a minimum PowerShell version 6.2. Beyond that, it also needs the modules VMware.VimAutomation.Hcx version 11.5+ and PowervRNI version 1.8+. These are the steps to get up and running:

```
1. Download the vRealize Network Insight and HCX Integration fling.
2. Open PowerShell and execute the following:
3. PS > Install-Module VMware.VimAutomation.Hcx
4. PS > Install-Module PowervRNI
5. PS > Get-Help ./sync-vrni-to-hcx.ps1
6. You can now run the sync-vrni-to-hcx.ps1 script.
```

# Contact

Currently, [@smitmartijn](https://twitter.com/smitmartijn) started this project and will keep maintaining it. Reach out to me via twitter or the [Issues Page](https://github.com/vrealize-network-insight/vrni-hcx-integration/issues) here on GitHub. If you want to contribute, also get in touch with me.

# License
This integration script is licensed under BSD-2.

The BSD-2 license (the "License") set forth below applies to all parts of the vRealize Network Insight and HCX Integration project. You may not use this file except in compliance with the License.

### BSD-2 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
