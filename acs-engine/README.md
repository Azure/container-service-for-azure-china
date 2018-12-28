# Microsoft Azure Container Service Engine

The Azure Container Service Engine (acs-engine) generates ARM (Azure Resource Manager) templates for Docker enabled clusters on Microsoft Azure with your choice of DCOS, Kubernetes, or Swarm orchestrators. The input to acs-engine is a cluster definition file which describes the desired cluster, including orchestrator, features, and agents. The structure of the input files is very similar to the public API for Azure Container Service.


## 1. Install acs-engine. It supports build acd-engine from source and install binary download:
* Binary downloads for the specific version(take v0.26.3 as an example) of acs-engine for are available [here](https://github.com/Azure/acs-engine/releases/). For other binary packages, please download from [Azure China mirror site](https://mirror.azure.cn/kubernetes/acs-engine/). 
```
acs_version=v0.26.3
wget https://mirror.azure.cn/kubernetes/acs-engine/$acs_version/acs-engine-$acs_version-linux-amd64.tar.gz
tar -xvzf acs-engine-$acs_version-linux-amd64.tar.gz
```
* [Build acs-engine from source](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.zh-CN.md)


## 2. Generate an SSH Key 
In addition to using Kubernetes APIs to interact with the clusters, cluster operators may access the master and agent machines using SSH. If you don't have an SSH key [cluster operators may generate a new one](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#ssh-key-generation).
```
ssh-keygen -t rsa
```

## 3. [Install azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
```
sudo su
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
apt-get install -y apt-transport-https
apt-get update
apt-get install -y azure-cli
```

## 4. Create a Service Principle
Kubernetes clusters have integrated support for various cloud providers as core functionality. On Azure, acs-engine uses a Service Principal to interact with Azure Resource Manager (ARM). Follow the instructions to [create a new service principal](https://github.com/Azure/acs-engine/blob/master/docs/serviceprincipal.md).
```
az cloud set -n AzureChinaCloud
az login
az account set --subscription="${SUBSCRIPTION_ID}" (if there is only one subscription, this step is optional)
az ad sp create-for-rbac --name XXX
```

## 5. Clone & edit kubernetes cluster definition file [example/kubernetes.json](https://raw.githubusercontent.com/Azure/acs-engine/master/examples/kubernetes.json)
Acs-engine consumes a cluster definition which outlines the desired shape, size, and configuration of Kubernetes. There are a number of features that can be enabled through the cluster definition:
* adminUsername - change username for agent nodes
* dnsPrefix - must be a region-unique name and will form part of the hostname (e.g. myprod1, staging, leapingllama) 
* keyData - must contain the public portion of an SSH key - this will be associated with the adminUsername value found in the same section of the cluster definition (e.g. 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA....')
* clientId - this is the service principal's appId uuid or name from step 4
* secret - this is the service principal's password or randomly-generated password from step 4
* add location definition `"location": "chinaeast",` behind `apiVersion: "vlabs"`
> specify `location` as (`chinaeast`, `chinanorth`, `chinaeast2`, `chinanorth2`) in cluster defination file

## 6. Generate ARM templates
Run `acs-engine generate kubernetes.json` command to generate a number of files that may be submitted to ARM. By default, generate will create a new directory named after your cluster nested in the `_output` directory. The generated files include:
* apimodel.json - is an expanded version of the cluster definition provided to the generate command. All default or computed values will be expanded during the generate phase
* azuredeploy.json - represents a complete description of all Azure resources required to fulfill the cluster definition from apimodel.json
* azuredeploy.parameters.json - the parameters file holds a series of custom variables which are used in various locations throughout azuredeploy.json
* certificate and access config files - orchestrators like Kubernetes require certificates and additional configuration files (e.g. Kubernetes apiserver certificates and kubeconfig)

## 7. Deploy K8S cluster with ARM
[Deploy the output azuredeploy.json and azuredeploy.parameters.json](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#deployment-usage)
```
az cloud set -n AzureChinaCloud
az login
az group create -l chinaeast -n xxx
az group deployment create -g xxx --template-file azuredeploy.json --parameters azuredeploy.parameters.json
```

## 8. Verify the cluster status
Log in to master node via SSH and run below command. If all services(like kubernetes, heapster, kube-dns, kubernetes-dashboard, tiller-deploy) in `default` and `kube-system` namespaces are working fine, it indicates the cluster were installed correctly.
```
kubectl get services --all-namespaces
```

## 9. Config kubernetes dashboard (Optional)
> Login to master node via SSH
```
ssh -i <path_to_id_rsa> <adminUsername>@<master_node_fqdn>
```
> Download config_k8s_ui_http.sh script
```
curl -LO https://raw.githubusercontent.com/Azure/devops-sample-solution-for-azure-china/master-dev/acs-engine/config_k8s_ui_http.sh
```
> Run following command:
```
bash config_k8s_ui_http.sh -c <cloud_name> -g <rg_name> -t <tenant_id> -i <app_id> -s <app_secret> -u <user_name> -p <user_pass>
```
Usages: 
* -c [Cloud instance name, AzureCloud or AzureChinaCloud]"
* -g [Resource group]"
* -t [Service principal tenant id, e.g. foo.onmicrosoft.com, bar.partner.onmschina.cn etc. ]"
* -i [Service principal app id]"
* -s [Service principal secret]"
* -u [Kubernetes dashboard user name, default value is 'admin']"
* -p [Kubernetes dashboard user password, default value is 'password']"

> Access dashboard via following link:
```
http://<master_node_fqdn>/ui
```
