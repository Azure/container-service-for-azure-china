# AKS on Azure China Best Practices
## 1. How to create AKS on Azure China
Currently AKS on Azure China could be only created by [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and only `chinaeast2` region is supported now
 - How to use [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) on Azure China
```sh
az cloud set --name AzureChinaCloud
az login
az account list
az account set -s <subscription-name>
```

Detailed "az aks" command line manual could be found [here](https://docs.microsoft.com/en-us/cli/azure/aks)

 - Example: create a `v1.10.8` AKS cluster on `chinaeast2`
```sh
RESOURCE_GROUP_NAME=demo-aks1108
CLUSTER_NAME=demo-aks1108
LOCATION=chinaeast2
az group create -n $RESOURCE_GROUP_NAME -l $LOCATION
az aks create -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --node-count 1 --node-vm-size Standard_D2_v2 --generate-ssh-keys --kubernetes-version 1.10.8
az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
kubectl get nodes
```
