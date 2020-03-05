# vRNI and HCX Integration

## Example

```
./sync-vrni-to-hcx.ps1 -vRNI_Server 10.196.164.134 -vRNI_Username admin@local -vRNI_Password 'xxx' -HCX_Server hcxe.vrni.cmbu.local -HCX_Username hcx@cmbu.local -HCX_Password 'xxx' -HCX_DestinationVC vc-pks.vrni.cmbu.local -HCX_DestinationCloud hcxc.vrni.cmbu.local
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