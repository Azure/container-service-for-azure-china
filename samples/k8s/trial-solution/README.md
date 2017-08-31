# Kubernetes based CI/CD and monitoring trial solution

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fccgmsref.blob.core.windows.net%2Fscripts%2Fk8s_trial%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Trial Scenarios

1. Provision a kubernetes cluster based on ACS engine.
2. Provision a jumpbox VM to manage the cluster
3. Expose the kubernetes dashboard UI in jumbpx VM, could access the dashboard via http://{{jumpbox-host-name}}/ui 

## Prerequisite

* Azure subscription
* Azure Active Directory Service Principal
* SSH Key for kubernetes cluster

## Deployment

1. Click the "Deply to Azure" button
2. Create new resource group or using existed
3. Enter the deployment parameters

| Parameter                       | Descrption                                                               | Default Value |
|---------------------------------|--------------------------------------------------------------------------|---------------|
| clusterDnsPrefix                | DNS name prefix of the trial cluster                                     |               |
| cloudEnvironmentName            | Azure cloud environment 'AzureCloud' or 'AzureChinaCloud'                | AzureCloud    |
| linuxAdminUserName              | Administrator user name for all linux VMs                                | azureuser     |
| jumpboxAdminPassword            | Administrator password to login jumpbox VM and kubernates dashboard      |               |
| k8sLinuxSshPublicKey            | Public key for kubernetes cluster SSH connection                         |               |
| k8sLinuxSshPrivateKeyBase64     | BASE64 encoded private key for kubernetes cluster SSH connection         |               |
| servicePrincipalTenantId        | The AAD tenant id for service principal                                  |               |
| servicePrincipalClientId        | The service principal client id                                          |               |
| servicePrincipalSecret          | The service principal secret                                             |               |

4. Accecpt the EULA and click the "Create" button

## Hints for deployment parameters

> For SSH Key, you could use the following parameter values for demo purpose but **MUST NOT** use it in production environment.

**k8sLinuxSshPublicKey:**

_ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCj0GHnhX8L8cPtCFhNPTClvDMzeMsB+ys5uMaqFgTa2mrWSUBsbsVwK91H6mwtrKRJf42Ry5DVYKLPf8XSz22v5iyZ1DrbkGJcmHRWEBFA47habQFg+eXBUSENUf1cMOh4RwkN1olCLpsdeKrF0Rj6k3ZFODUJIf+v5HYKFkj+8iVdQh0wgnPVxneqIKcbqNLO8ymmAiTT+fYaubPWzJmq8nUKoNZRiPXSSAwHHtNouR4vvPtOU7je2TxzoYIcM/Ja6YycBx44W+A7ygY5/hmij4Byhm20MLZLoBLX2AMp8horzqWhdF/wvFMhv8FTTzlWpwhuEpbd2M4B6Tylajm8lwA9u/9MO6lEbqnX/XH/KS9hPZdKvqXgbPTzM265Aea0LPXHDdF0f9AID6Xl3grHrtkKFGMzbgqFtF9nd51kwDTZr2b1zIVWb6XxDXXVhX4XqWniCT8xEzuGyMp4/mhaghRDhT45Alu6Frv6d5+IjeabBSXOwwe+8NpTDc0+hxM/MYiE4K6EHpPqwxOoRJcZFrjdSxQGGrCD+bLJbGfI8tn96Wq4zBBUMp+iX1iXXNScgqUAaSoNKEH8ag177oOvtH3AsB/b7Nm/eUIr/WYfYESlft1M1h25Lvu6QgFyqJlwdXSPCiIYbR6nK6WI2Zz6cActCLoJaN7IPw6RLeY+tw==_

**k8sLinuxSshPrivateKeyBase64:**

_LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ0KTUlJSktRSUJBQUtDQWdFQW85Qmg1NFYvQy9IRDdRaFlUVDB3cGJ3ek0zakxBZnNyT2JqR3FoWUUydHBxMWtsQQ0KYkc3RmNDdmRSK3BzTGF5a1NYK05rY3VRMVdDaXozL0Ywczl0citZc21kUTYyNUJpWEpoMFZoQVJRT080V20wQg0KWVBubHdWRWhEVkg5WEREb2VFY0pEZGFKUWk2YkhYaXF4ZEVZK3BOMlJUZzFDU0gvcitSMkNoWkkvdklsWFVJZA0KTUlKejFjWjNxaUNuRzZqU3p2TXBwZ0lrMC9uMkdybXoxc3lacXZKMUNxRFdVWWoxMGtnTUJ4N1RhTGtlTDd6Nw0KVGxPNDN0azhjNkdDSERQeVd1bU1uQWNlT0Z2Z084b0dPZjRab28rQWNvWnR0REMyUzZBUzE5Z0RLZklhSzg2bA0Kb1hSZjhMeFRJYi9CVTA4NVZxY0liaEtXM2RqT0FlazhwV281dkpjQVBidi9URHVwUkc2cDEvMXgveWt2WVQyWA0KU3I2bDRHejA4ek51dVFIbXRDejF4dzNSZEgvUUNBK2w1ZDRLeDY3WkNoUmpNMjRLaGJSZlozZWRaTUEwMmE5bQ0KOWN5RlZtK2w4UTExMVlWK0Y2bHA0Z2svTVJNN2hzaktlUDVvV29JVVE0VStPUUpidWhhNytuZWZpSTNtbXdVbA0KenNNSHZ2RGFVdzNOUG9jVFB6R0loT0N1aEI2VDZzTVRxRVNYR1JhNDNVc1VCaHF3Zy9teXlXeG55UExaL2VscQ0KdU13UVZES2ZvbDlZbDF6VW5JS2xBR2txRFNoQi9Hb05lKzZEcjdSOXdMQWYyK3padjNsQ0svMW1IMkJFcFg3ZA0KVE5ZZHVTNzd1a0lCY3FpWmNIVjBqd29pR0cwZXB5dWxpTm1jK25BSExRaTZDV2pleUQ4T2tTM21QcmNDQXdFQQ0KQVFLQ0FnQlM3NEZoMGZpTWQ0NldSdzlOcTVraGo3THNjRTkzWlU1eEh0ZVY3U2Z3Rlh6Wm1LU0JRV084Y3JqSg0KWENvQXhkTTNVdGk5NDY0a0daVFVNUUJheHFIbDJFYmthc3FSdHZ2Vm5Xbm8yS0dqbEtjVlFQTGR3aWRNUkdMVA0KZDVzcVBhaTBuR0k5RzB6S3NRWGZXZVE3MnEwbXo5bWxHZHZnRDlKL25zOFVORXdvcHplN2kybHowZGdMZHp2Rw0KYWxtd2F6eXZnZlNvRTVYSnJGZXBHRE93b0UxOGV0dyswVWN3YUlMc1A0VzNaU2ZyY1MyVFJiNkYzV1ZQamZSSg0KSm8vVTc0Zlg5ejQxRUhXQVd5T2ZvWnlkWjhSYXhRUm05eUE3aGg0RkU3bjJoV3EwcGRvU0s4RTNpTSs1OWQ2dw0KeTRCNVNUYmlaQmFrZzh6VjdKbi81YkhLbllrMDNoQ202VTM1VHV3Y0RYUVhGRGQ5MWlCc3RXRWdlUVloNXRaRA0KNVhZMFN5djg0NThadlI4S3hQSktTck9CTWpZZnp1aFdiS0RMZENyTy9Wb3RIdkhLSUxHQnRweCtBeUJHc2xqeA0KZjZ3TVZlVzd4OVByNUw4UUdDNHhnR095Y0xYbk80ZjkwQkw4Ym9wVjlnM0FJUUN2WUdRdTVwTERlUlFwRk9PcA0KeHRFWkxYV0VNQ2lRdFVGcWt3N2JGNnFTNkY5TDN1NDNxK09xRlRFVkh3aFpVbGxWdWtxcW1JRFJ2N2lJdExtSg0KbE05YnppSEVrekNEZkxvREZPZVVLTFpZQ1U4S1MxQ0VRT1FxYmVqeVJXaUtyamRKNEdrOW5BcUhMelVoTzFBVA0KY3IxNjJRdkRnZGM1UU11V09LRllkVW1rZmlkaU9hMyt2RnZmcEJEZXB4dGN2RkFSQVFLQ0FRRUEyWm1GcXlISQ0KVWNMdkZCYjFqTnF5ODMyTFd3MDVvaVpHRmxyU0NWclg4ZHNzbHl6RjZNRlA2NU5mYTh4Q1AyUVBGbVlBaWNXbQ0KYlorS2FJdVZRRkVEZW9kRlF4WjRVbW5jYW11dlEvRzJZSUpWZlVlSmU5cWpRamV2L24vaDJPUVp6MjFFeW9aKw0KRTgrS2RnM0V3OG1FQU41Yzd5b1htQjRCek9KMFk4SlRQQmlndk1RZ0JVcytsQ1BTUzlqZEpEaktBSEkvaE1uaQ0KZTQ0OTRCNzdpT0lnK04vVUljTU9GMnhlOW52V21yTlFXN2prdXpOaCtERTgwUm9OczNTYWwwSjBPdlpuSkFOaw0KSGtiWW50dEk0ZkFiNlNIeExvaHR6MjAwTlRTbXlPQ2ZWM04wN1c0Yk5aekwveDlGTmpWVmU3ZXRSeEFOa0E5cg0KVUs4SDhBOWZBRUM2b1FLQ0FRRUF3TGo5VGhhdXJuTGJHUFhMQTJHc3M5OHVRbm1hWmt6WDNwd0ZtMU1wMnYyNw0KM2tldXJnMmsxMnBQT2F2UFZvQlFMbmZmVUpuWXdxVkpVR0xSQVBWMjR5TjhHbHZmbHhHdDZQWDE3SGlFZXVzRQ0Kc3VFNnRDSHlobCtFVm9UV0FseTRENVZzbVBMVHM4UGJidWNDZ3hsRFdNRmpqOWdsaitWdXJtakY3TGFTeXJvTA0KQS8zaUZLNmJaU1ZGQXM0emduNFFZNkYwTCs5cnJYMjdHTU43dHFEWVR5YzIvc2RvQ2lRdnBadlV5dWRCYUNUcw0KdXhjMEhMenhiczU4ZmFzZEoyMEhUTUhXS0RVeGxIY3ZzemRqejYzL0ZkV29SSXFMenhMbmJBUy9jZllKM0lnZQ0KakJ2WXg0MWNjZ05UR0FTeDF6Y05SSDRVUUJPTVdXeStqTFNLeVJlU1Z3S0NBUUJxYzJWbUE5L1l4OUZuOVpkbw0Kc2ZETGw0WmVJOGtuSHl3NGNYUEJLZFRzdDdsSHQ1cVdORVBoempYbktZVGJPQnI5YlNja1B6SWMvT2ljSG5VRQ0KZ3QxOXlzRkNnYktaTnJxaXdVMTdvcnNDMloveTZ0VkNad0pwT1k3NnBSc2FuUFJYZW5BbDE4ZkQ3MHNnVjdvRA0Kd2dpMjJCR0Uyd1d4NERRblJEMkdOQ0crQzVwTzNtOS94NEMwdmhWNkQzeVg1TVJGbFo2bldwQld1NDVmbnlpVQ0KblhOZDdUbjh6a3lOZnZHeUNZRkNLeWpMeGxiM2ticUN6YXVmNit2NTk3aE0rVENkUzcvSGFYVklMb1o0cUhRdQ0KTytXYmxvUkRySEIwQWt1QkgrSGI4YTloKzlTZTlyZU84Y2NHWndqWDdSMkZxYVMyV0E4YWc4Q1BOeUZkK2xjUw0KYTVnaEFvSUJBUUM5ZEoyL0tGa3NzVWhscnl1VjlXMDduZ2p4M0cxR2FBQkduSVorZlRER1VXMWdSSU9hSTF1TA0KVUx6MWFzcjJ0RWtlaFVVSkRWU2pkSzB2MHhTM3BwYnJEN1V1akdhdk1mZ083Y3lHWEt1UDBuM2FBOFFiMU11QQ0KQVdJdFU0UzI2Y01mdnJyMVdMRjVKTzhRaFJSWklIcXVROTdHUjZ3VlcyeUZGQWFPZjZTcW1sMjkzTlZsazRpNw0KMC9tVm1uUFVzbTBXSkYvOXg1WEpCYkxwMHpKSkJMSGdqaUpvTUVzOHZQb0NDY0VVZm1ZMEpTaDdlNElGUmxEcA0KcHgrR3dySjBVYUE5ZXNnMjJxUVUyVjRSQmtDZXB1UCs2UHp6OUdjZ2QrcjhxMll3ZDdpV0RWSktWZzJ6am1uMA0Kd3dQcXRxTEZlUjhYMkFHOFEvdFM1YTRrMEU4bkJIOGRBb0lCQVFDVFNzaVNPOU1iMWJxUUVoSzhDem9aRWJaNw0KeTdYOFpQYVdZUzUvKzd0NWtVNTRadmhSemhWRjZ4cnZ6QzlSeDF6QUF3ajIxek8wYTFiR1BTRDhMLzZJdlhnNQ0KZUxFdlZMSU52azJyY1MySkE2cGlnSlNzSmp2OCtha29RUW9ETHZUSnNFQ2NSWEZmNGk5RGY3cnV6STkvN3pWVg0KLzB1SDRmMUZFTXRnKzRRVlRoRDhZNVp3ZlEyN3h2MW1NV2kvNFJhVzdOM1hYZlE0T1NtQjMyT1ZCSlllUGlESw0KNm5BYTJnRXBnVjB3K09KajhtS0lSa3JTSGFPTSs0d2hGY0E1WHd4dHpsQXVLSkhCajkvZWhpdm40RE9DcWlpVg0KdVNWdjlneXIvS1hXYVhrbzBDdlZudGZRS3pDdUhaQnhiMXE2aVJGZzBtTzdhaERGa2hVaXlxWjAzckRrDQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQ0K_

> For Azure Active Directory Service Principal, you could use Azure CLI 2.0 to create:

1. install Azure CLI 2.0 based on [this document](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

2. login to Azure CLI 2.0, could follow [this document](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)

    _command:_ az login

3. create service principal based on [this document](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)

    _command:_ az ad sp create-for-rbac --name {appId}

4. copy the **appId** in the output to **servicePrincipalClientId** and **password** to **servicePrincipalSecret**

> For Azure Active Directory (AAD) tenant id, you could use Azure CLI 2.0 to get:

1. get account info via Azure CLI 2.0 after login

    _command:_ az account show

2. copy the **tenantId** in the output to **servicePrincipalTenantId**

> for Azure China Cloud user

1. need to set Azure CLI enviornment before login:

    _command:_ az cloud set --name AzureChinaCloud

2. need to set **cloudEnvironmentName** to **_AzureChinaCloud_**