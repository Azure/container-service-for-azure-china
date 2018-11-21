# AKS on Azure China Best Practices
## 1. How to create AKS on Azure China
Currently AKS on Azure China could only be created by [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and only supports `chinaeast2` region (in **Private Preview** from 2018.11.13)
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

## 2. Container registry proxies
Since some container registries like `gcr.io`, `docker.io` are not accessible or very slow in China, we have set up container registry proxies in `chinaeast2` region now:

| global | registry proxy in Azure China | Example |
| ---- | ---- | ---- |
| dockerhub (docker.io) | [dockerhub.azk8s.cn](http://mirror.azk8s.cn/help/docker-registry-proxy-cache.html) | dockerhub.azk8s.cn/library/centos |
| gcr.io | [gcr.azk8s.cn](http://mirror.azk8s.cn/help/gcr-proxy-cache.html) | gcr.azk8s.cn/google_containers/hyperkube-amd64:v1.9.2 |
| quay.io | [quay.azk8s.cn](http://mirror.azk8s.cn/help/quay-proxy-cache.html) | quay.azk8s.cn/deis/go-dev:v1.10.0 |

> Note:
`k8s.gcr.io` would redirect to `gcr.io/google-containers`, following images are identical:
k8s.gcr.io/pause-amd64:3.1
gcr.io/google_containers/pause-amd64:3.1 |

## 3. Install kubectl
Original `az aks install-cli` does not work in azure china, follow detailed steps [here](https://mirror.azk8s.cn/help/kubernetes.html)

## 4. Install helm
follow detailed steps [here](https://mirror.azk8s.cn/help/kubernetes.html)

> Note:
All kubernetes related binaries on github could be found under [https://mirror.azk8s.cn/kubernetes](https://mirror.azk8s.cn/kubernetes), e.g. helm, charts, etc.

## Links
 - Click for trial: [http://aka.ms/aks/chinapreview](http://aka.ms/aks/chinapreview)
  > Note: please make sure you already have an **Azure China** Subscription
 - AKS doc: [https://docs.microsoft.com/en-us/azure/aks/](https://docs.microsoft.com/en-us/azure/aks/) 
  > Chinese version: [https://docs.microsoft.com/zh-cn/azure/aks/](https://docs.microsoft.com/zh-cn/azure/aks/) 
 - Contact AKS China Team: [akscn@micrsoft.com](mailto:akscn@micrsoft.com)  
