# vRNI and HCX Integration
This integration script between vRealize Network Insight (vRNI) and VMware HCX, allows you to streamline the application migration process.

First, use the application discovery methods within vRNI to discover the application boundaries, including the VMs (or other workloads), to form application constructs within vRNI. This integration script then synchronizes the vRNI application constructs into HCX Mobility Groups, saving you the time that it would've taken to do this manually. After the sync, you can pick up the migration process and execute the migration.

## Example

### Synchronising all vRNI applications
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

### Synchronising selective vRNI applications:
```
./sync-vrni-to-hcx.ps1 -vRNI_Server 10.196.164.134 -vRNI_Username admin@local -vRNI_Password 'xxx' -HCX_Server hcxe.vrni.cmbu.local -HCX_Username hcx@cmbu.local -HCX_Password 'xxx' -HCX_DestinationVC vc-pks.vrni.cmbu.local -HCX_DestinationCloud hcxc.vrni.cmbu.local -Sync_Applications ("app_hcx-3tierapp", "Top-Video")
```

### Synchronising from vRNI Cloud
```
./sync-vrni-to-hcx.ps1 -vRNI_Cloud_API_Token 'xxx' -HCX_Server hcxe.vrni.cmbu.local -HCX_Username hcx@cmbu.local -HCX_Password 'xxx' -HCX_DestinationVC vc-pks.vrni.cmbu.local -HCX_DestinationCloud hcxc.vrni.cmbu.local
```

## HCX API Calls

### Authentication
Authenticate against the HCX Enterprise appliance before doing any other HCX API calls.

#### Request
```
POST https://hcx.enterprise.appliance/hybridity/api/sessions
{"username": "username@vsphere.local","password": "password"}
```

#### Result body
```
{
  "success": true,
  "completed": true,
  "time": 1582194800716,
  "version": "1.0",
  "data": {
    "certificate": "MIIDZDCCAkygAwIBAgIEFY+d1DANBgkqhkiG9w0BAQsFADB0MQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExEjAQBgNVBAcTCVBhbG8gQWx0bzEPMA0GA1UEChMGVk13YXJlMR8wHQYDVQQLDBZIeWJyaWRpdHkgJiBOZXR3b3JraW5nMRIwEAYDVQQDEwloeWJyaWRpdHkwHhcNMjAwMTMxMTQ1MzIwWhcNNDAwMTI2MTQ1MzIwWjB0MQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExEjAQBgNVBAcTCVBhbG8gQWx0bzEPMA0GA1UEChMGVk13YXJlMR8wHQYDVQQLDBZIeWJyaWRpdHkgJiBOZXR3b3JraW5nMRIwEAYDVQQDEwloeWJyaWRpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC43Cgkk/1UMe5k+vJCDVaQmKlsVD9WtFDj0XgTo/lp2vd+xxZJNehHO+n5Wm1ZMThHnVsecXrkUNyPt4dN4NoQtxWUs/R2fIu+AeQ+MitevWIlrWOhhM0WV41ayz7xbaiU8I3A8ZxL9CaZ+PA4CUVpS5UIzhFOV8IuSuFbJt2y5diP1wBbLbKwPHcWaSBROwENCEuriQYVZU61eVNlirp5L8UQ3yZuqSD2XdY19Cl2drf3uDIWbBYgaj5r7ypqk8ljuodrEtM3i7v+XQJfsJayRD2u9khoYe7szy6NkotfwBklz6WuWEO3/Vo/YQEoSM5h28UILr8rw30t1kouzk09AgMBAAEwDQYJKoZIhvcNAQELBQADggEBABNnEK6q6rS31/Bv1mg6Gouwbb1s/SnWP9GRNAYlPxIezndVmprnz655qDm2il9M5284/KIYrDgVrSQsdB1VRSLHhkulpUqAKFjVGY7onJskTvnXc0+I3DdKuYBdksLXhqJjCC9C7n9XXC70EG6N8IDFTXV7e6/hBY+OFr7w4YxFvHgJAIXsy0o7Xb6ZZnlTfce1bxr6UkyNiUFZRDkFIj+oRu+nZN2m4QsRw4/i483QS9AuukteW43n5rAj0q4p5nLsPB95fjcCygvw7h6mzl724yiSGx3z19aqqUBeKK5iYthRShwUvL4xiFYu3Zc5CEfDba3FvVTLI3Log6Rfkv0=",
    "cloud": {
      "cloudType": "VC",
      "isVCDGVRDepricated": false,
      "delegateAuthToVCD": false
    },
    "user": {
      "enterprise": "HybridityAdmin",
      "organization": [
        "DEFAULT"
      ],
      "currentOrganization": "DEFAULT",
      "roles": [
        "System Administrator",
        "Enterprise Administrator"
      ],
      "username": "hcx@CMBU.LOCAL",
      "transactionId": "c2d3fbce-8e6a-46be-ae68-b7f484d0b34f"
    },
    "organizations": [
      {
        "uuid": "DEFAULT"
      }
    ],
    "endpointInfo": {
      "uuid": "20200131145334716-85327bc6-11f4-4a1e-a74e-ba8da678aeaf"
    }
  }
}
```

#### Result Headers

```
auth_token_name: x-hm-authorization
cache-control: no-cache, no-store, max-age=0, must-revalidate
connection: Keep-Alive
content-encoding: gzip
content-type: application/json;charset=UTF-8  date: Thu, 20 Feb 2020 10:33:20 GMT
expires: 0  keep-alive: timeout=5, max=98
pragma: no-cache
server: Apache
strict-transport-security: max-age=31536000 ; includeSubDomains
transfer-encoding: chunked
vary: Accept-Encoding
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
x-hm-authorization: 78a7ac4e:ab72:483c:9f66:a76525838fd1
x-transaction-id: c2d3fbce-8e6a-46be-ae68-b7f484d0b34f
x-xss-protection: 1; mode=block
```


Save `x-hm-authorization` for subsequent API calls.

Save `data→endpointInfo→uuid` to identify the HCX source appliance ID.

### Getting the Source vCenter HCX UUID
API Call for source vCenter details, which we need in order to create Mobility Groups. This call is against the VAMI of the HCX Enterprise appliance, so the format is a little different than the regular HCX enterprise API calls.

#### Request
```GET https://hcx.enterprise.appliance:9443/api/admin/global/config/vcenter```

Set these headers:
```
Content-Type: application/json
Authorization: Basic YWRtaW46Vk13YXJlMSE=
```

Authorization is basic auth with the HCX enterprise admin credentials (typically username = admin)

#### Result Body
```
{
	"data":
	{
		"items":[{
			"config":
			{
				"url":"https:\\/\\/vc-south.cmbu.local",
				"userName":"hcx@cmbu.local",
				"vcuuid":"6e0fb504-af04-4d14-bf69-c4f61f90e217",
				"version":"6.7.0.8546293",
				"buildNumber":"8546293",
				"osType":"linux-x64",
				"name":"vc-south.cmbu.local",
				"UUID":"8f8401fc-337b-4ae5-8dea-5da2b88d3aa5"
			},
			"section":"vcenter"
		}]
	}
}
```

Save data→items[0]→config→UUID to identify the source vCenter UUID, in order to create Mobility Groups.

**Note:** In this script, this is done using the *Get-HCXSite -Source* function that's in VMware.VimAutomation.Hcx.

### Getting the Destination vCenter HCX UUID
*To do*

**Note:** In this script, this is done using the *Get-HCXSite -Destination* function that's in VMware.VimAutomation.Hcx.

### Getting the Destination HCX Cloud Appliance UUID
*To do*

**Note:** In this script, this is done using the *Get-HCXSitePairing* function that's in VMware.VimAutomation.Hcx.

### Creating HCX Mobility Groups

1 request per Mobility Group. In theory you can do more than 1 group at a time, but the error handling is not very good, and it'll error all groups, when only 1 group is faulty.

Source and destination is required.

#### Request
```
POST https://hcx.enterprise.appliance/hybridity/mobility/groups
{
    "items":
    [
        {
            "name": $Name,
            "tags": {"vRNI"}
            "groupDefaults":
            {
                "source":
                {
                    "endpointType": "VC",
                    "endpointId": $Connection.HCXUUID,
                    "resourceType": "VC",
                    "resourceId": $SourceVC_UUID
                },
                "destination":
                {
                    "endpointType": "VC",
                    "endpointId": $DestinationHCX_UUID,
                    "resourceType": "VC",
                    "resourceId": $DestinationVC_UUID,
                }
            },
            "migrations":
            []
                {
                    "migrationType": "ColdMigration"
                    "entity":
                    {
                        "entityId": $vm-id,
                        "entityName": $vm-name,
                        "entityType": "VirtualMachine"
                    },
                    "operationType": "ADD"
                },
                {
                    "migrationType": "ColdMigration"
                    "entity":
                    {
                        "entityId": $vm-id,
                        "entityName": $vm-name,
                        "entityType": "VirtualMachine"
                    },
                    "operationType": "ADD"
                },
                {
                    ...etc..
                }
            ]
        }
    ]
}
```

#### Result body

The result is an JS respond, encoded in JSON. A few messages to look out for:

- Mobility group with same name exist.