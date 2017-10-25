# Azure Docker Registry Template
This is a Azure ARM template to deploy Docker registry on Azure China. ***Some urls are hard coded to Azure China now, so this template is NOT workable on Global Azure.***

## Overview

This template deploy a simple Docker registry cluster based on Swarm Mode with TLS. The following is the architecture of the resources:

![arch](images/1.png)

The default VM node is 2 and this value can be set when deploying.

## Prerequisite
* Azure China Cloud subscription
* Linux dev machine with [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed
* Login into the subscription with commands below
```
$ az cloud set -n AzureChinaCloud
$ az login -u <username>
```
* Clone the repo to dev machine with commands below
```
$ mkdir -p /path/to/project
$ cd /path/to/project
$ git clone https://github.com/Azure/devops-sample-solution-for-azure-china.git
$ cd /path/to/project/devops-sample-solution-for-azure-china/azure-docker-registry
```

## Parameters in azuredeploy.parameters.json
| Parameter         | Descrption                                         | Default Value  |
|-------------------|----------------------------------------------------|----------------|
| adminUsername     | Admin username                                     | azureuser      |
| adminPassword     | Password for the Virtual Machine                   |                |
| dnsNameforLBIP    | DNS for Load Balancer IP                           | myhub01        |
| registryPort      | Port of registry                                   | 5000           |
| numberOfInstances | Number of Virtual Machine instances                | 2              |
| vmSize            | The size of the Virtual Machine                    | Standard_D2_v2 |
| sshRSAPublicKey   | SSH public key used for auth to all Linux machines |                |

## A. Deploy a plain HTTP registry
For test purpose, you can deploy a plain HTTP registry. Notice that this is very insecure and not recommended.
1. Edit azuredeploy.parameters.json, and run command below
```
$ ./deploy-docker-registry.sh -n <resource_group_name> -l <location> -m mirror.azure.cn
```
2. Once deployment completed, on each machine that wants to access the registry, following the [instruction](https://docs.docker.com/registry/insecure/#deploy-a-plain-http-registry) to configure client.
E.g. for linux, edit /etc/docker/daemon.json with 
```
{
  "insecure-registries" : ["<dns of the public IP created>:5000"]
}
```
and then restart docker with `sudo service docker restart`.

## B. Deploy a TLS enabled registry with a self-signed certificate
To be more secure than plain HTTP solution, you can [deploy with a self-signed certificate](https://docs.docker.com/registry/insecure/#use-self-signed-certificates).
1. Generate your own certificate following the link above, and replace certs/server.crt and certs/server.key.
2. Edit cloud-config-template.yml, and un-comment the lines below
```
- REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt
- REGISTRY_HTTP_TLS_KEY=/certs/server.key
- REGISTRY_HTTP_SECRET="<<<variables('httpSecretString')>>>"
```
3. Edit azuredeploy.parameters.json, and run command below
```
$ ./deploy-docker-registry.sh -n <resource_group_name> -l <location> -m mirror.azure.cn
```
4. Once deployment completed, on each machine that wants to access the registry, following the [instruction](https://docs.docker.com/registry/insecure/#use-self-signed-certificates).
E.g. for linux, copy server.crt file to /etc/docker/certs.d/< dns of the public IP created >:5000/server.crt

## C. Deploy a TLS enabled registry with a CA certificate
This is the secure way to deploy a TLS enabled registry in production. Similar to self-signed certification solution, without the last step on each client to access the registry.


