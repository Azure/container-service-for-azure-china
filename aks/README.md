# AKS on Azure China Best Practices

Azure Kubernetes Service is in **General Available**, this page provides best practices about how to operate AKS on Azure China cloud.

- Contact AKS China Team: [akscn@microsoft.com](mailto:akscn@microsoft.com)

## Limitations of current AKS General Available on Azure China

- Preview features on Global Azure won't be supported on Azure China, e.g. [Windows Container](https://docs.microsoft.com/en-us/azure/aks/windows-container-cli)

## 1. How to create AKS on Azure China

Currently AKS on Azure China could be created by [Azure portal](https://portal.azure.cn/#create/microsoft.aks) or [azure cli](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli?view=azure-cli-latest), AKS on `chinaeast2`, `chinanorth2` regions are available now. This page shows to create AKS cluster by azure cli.

- How to use [azure cli](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli?view=azure-cli-latest) on Azure China.

    ```console
    az cloud set --name AzureChinaCloud
    az login
    az account list
    az account set -s <subscription-name>
    ```

- Pick one available AKS version on `chinaeast2` or `chinanorth2`.
```console
az aks get-versions -l chinaeast2 -o table
KubernetesVersion    Upgrades
-------------------  ----------------------------------------
1.22.2(preview)      None available
1.22.1(preview)      1.22.2(preview)
1.21.2               1.22.1(preview), 1.22.2(preview)
1.21.1               1.21.2, 1.22.1(preview), 1.22.2(preview)
1.20.9               1.21.1, 1.21.2
1.20.7               1.20.9, 1.21.1, 1.21.2
1.19.13              1.20.7, 1.20.9
1.19.11              1.19.13, 1.20.7, 1.20.9
```

- Example: create an AKS cluster on Azure China

    ```console
    RESOURCE_GROUP_NAME=demo-aks
    CLUSTER_NAME=demo-aks
    LOCATION=chinaeast2  #or chinanorth2
    VERSION=1.20.7  # select an available version by "az aks get-versions -l chinaeast2 -o table"
    
    # create a resource group
    az group create -n $RESOURCE_GROUP_NAME -l $LOCATION
    
    # create AKS cluster with 1 agent node
    az aks create -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --node-count 1 --node-vm-size Standard_D3_v2 --generate-ssh-keys --kubernetes-version $VERSION -l $LOCATION --node-osdisk-size 128
    
    # wait about 5 min for `az aks create` running complete
    
    # get the credentials for the cluster
    az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
    
    # get all agent nodes
    kubectl get nodes
    
    # open the Kubernetes dashboard
    az aks browse --resource-group $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
    
    # scale up/down AKS cluster nodes 
    az aks scale -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --node-count=2
    
    # delete AKS cluster node
    az aks delete -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
    ```

    > Get more detailed [AKS set up steps](https://docs.azure.cn/zh-cn/aks/kubernetes-walkthrough)
 
    > Detailed "az aks" command line manual could be found [here](https://docs.microsoft.com/zh-cn/cli/azure/aks)


## 2. Container Registry

### 2.1 Azure Container Registry(ACR)

[Azure Container Registry](https://azure.microsoft.com/zh-cn/services/container-registry/)(ACR) provides storage of private Docker container images, enabling fast, scalable retrieval, and network-close deployment of container workloads on Azure. 

- AKS has good integration with ACR, container image stored in ACR could be pulled in AKS after [Configure ACR authentication](https://docs.azure.cn/zh-cn/aks/tutorial-kubernetes-deploy-cluster#configure-acr-authentication).

### 2.2 Container Registry Proxy

Since some container registries like `docker.io`, `gcr.io` are not accessible or very slow in China, we have set up container registry proxy servers for Azure China VMs:
> First docker pull of new image will be still slow, and then image would be cached, would be much faster in the next docker pull action.

> **Note**:
currently *.azk8s.cn could only be accessed by Azure China IP, we don't provide public outside access any more. If you have such requirement to whitelist your IP, please contact akscn@microsoft.com, provide your IP address, we will decide whether to whitelist your IP per your reasonable requirement, thanks for understanding.
>
> Please note that we can only offer SLA-based technical support for mcr.azk8s.cn among the listed registries.
 
| Global | Proxy in China | format | example |
| ---- | ---- | ---- | ---- |
| [dockerhub](hub.docker.com) (docker.io) | [dockerhub.azk8s.cn](http://mirror.azk8s.cn/help/docker-registry-proxy-cache.html) | `dockerhub.azk8s.cn/<repo-name>/<image-name>:<version>` | `dockerhub.azk8s.cn/microsoft/azure-cli:2.0.61` `dockerhub.azk8s.cn/library/nginx:1.15` |
| gcr.io | [gcr.azk8s.cn](http://mirror.azk8s.cn/help/gcr-proxy-cache.html) | `gcr.azk8s.cn/<repo-name>/<image-name>:<version>` | `gcr.azk8s.cn/google_containers/hyperkube-amd64:v1.18.4` |
| us.gcr.io | usgcr.azk8s.cn | `usgcr.azk8s.cn/<repo-name>/<image-name>:<version>` | `usgcr.azk8s.cn/k8s-artifacts-prod/ingress-nginx/controller:v0.34.1` |
| k8s.gcr.io | k8sgcr.azk8s.cn | `k8sgcr.azk8s.cn/<repo-name>/<image-name>:<version>` | `k8sgcr.azk8s.cn/ingress-nginx/controller:v0.35.0` <br>`k8sgcr.azk8s.cn/autoscaling/cluster-autoscaler:v1.18.2` |
| registry.k8s.io | registryk8s.azk8s.cn | `registryk8s.azk8s.cn/<repo-name>/<image-name>:<version>` | `registryk8s.azk8s.cn/ingress-nginx/kube-webhook-certgen:v20230407` |
| quay.io | [quay.azk8s.cn](http://mirror.azk8s.cn/help/quay-proxy-cache.html) | `quay.azk8s.cn/<repo-name>/<image-name>:<version>` | `quay.azk8s.cn/deis/go-dev:v1.10.0` |
| mcr.microsoft.com | mcr.azk8s.cn| `mcr.azk8s.cn/<repo-name>/<image-name>:<version>` | `mcr.azk8s.cn/oss/nginx/nginx:1.17.3-alpine` |

- Container Registry Proxy Example

    specify `defaultBackend.image.repository` as `gcr.azk8s.cn/google_containers/defaultbackend` in [nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) chart since original `k8s.gcr.io` does not work in Azure China:

    ```
    helm install stable/nginx-ingress --set defaultBackend.image.repository=gcr.azk8s.cn/google_containers/defaultbackend --set defaultBackend.image.tag=1.4
    ```

## 3. Install helm
- Install helm v3
```console
VER=v3.3.4
wget https://mirror.azure.cn/kubernetes/helm/helm-$VER-linux-amd64.tar.gz
tar -xvf helm-$VER-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin
```

- Helm application example:
```console
# Install wordpress
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install bitnami/wordpress --generate-name --set global.imageRegistry=dockerhub.azk8s.cn

# Install nginx-ingress
helm repo add stable https://mirror.azure.cn/kubernetes/charts/
helm install stable/nginx-ingress --generate-name --set controller.image.registry=usgcr.azk8s.cn --set defaultBackend.image.repository=k8sgcr.azk8s.cn/defaultbackend-amd64
```
  
> Note:
- Download Kubernetes related binaries from [https://mirror.azure.cn/kubernetes](https://mirror.azure.cn/kubernetes), e.g. helm, charts, etc.
- Charts under https://mirror.azure.cn/kubernetes/charts are synced from https://charts.helm.sh/stable

## Hands on
 - [run a simple web application on AKS cluster](https://github.com/andyzhangx/k8s-demo/tree/master/nginx-server#nginx-server-demo)
 - [AKS workshop](https://aksworkshop.io/)
 
### Tips
- For production usage:
  - agent VM size should have at least **8** CPU cores(e.g. D4_v2) since k8s components would also occupy CPU, memory resources on the node, details about [AKS resource reservation](https://docs.microsoft.com/zh-cn/azure/aks/concepts-clusters-workloads#resource-reservations).
  - it's better set a bigger os disk size on agent VM in AKS cluster creation, e.g. set `--node-osdisk-size 128`, original 30GB os disk size is not enough since all images are stored on os disk.

- [GPU workload support best practices on Azure China](https://docs.azure.cn/zh-cn/aks/gpu-cluster)

### Links
- AKS doc: https://docs.azure.cn/zh-cn/aks/

- [Azure Kubernetes Service Issues](https://github.com/Azure/AKS/)

- [Frequently asked questions about Azure Container Service (AKS)](https://docs.azure.cn/zh-cn/aks/faq)
