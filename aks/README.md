# AKS on Azure China Best Practices

Azure Kubernetes Service is in **General Available**, this page provides best practices about how to operate AKS on Azure China cloud.

- Contact AKS China Team: [akscn@microsoft.com](mailto:akscn@microsoft.com)

## Limitations of current AKS General Available on Azure China

- Preview features on Global Azure won't be supported on Azure China, e.g. [Windows Container](https://docs.microsoft.com/en-us/azure/aks/windows-container-cli)

## 1. How to create AKS on Azure China

Currently AKS on Azure China could be created by [Azure portal](https://portal.azure.cn/#create/microsoft.aks) or [azure cli](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli?view=azure-cli-latest), AKS on `chinaeast2`, `chinanorth2` regions are available now. This page shows to create AKS cluster by azure cli.
 > You need the Azure CLI version 2.0.61 or later installed and configured. Run `az --version` to find the version. If you need to install or upgrade, see [Install Azure CLI](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli?view=azure-cli-latest).

- How to use [azure cli](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli?view=azure-cli-latest) on Azure China.

    ```sh
    az cloud set --name AzureChinaCloud
    az login
    az account list
    az account set -s <subscription-name>
    ```

- Pick one available kubernetes version on `chinaeast2` or `chinanorth2`.

    ```
    az aks get-versions -l chinaeast2 -o table
    KubernetesVersion    Upgrades
    -------------------  ----------------------------------------
    KubernetesVersion    Upgrades
    -------------------  -----------------------
    1.17.3(preview)      None available
    1.16.7               1.17.3(preview)
    1.15.10              1.16.7
    1.15.7               1.15.10, 1.16.7
    1.14.8               1.15.7, 1.15.10
    1.14.7               1.14.8, 1.15.7, 1.15.10
    ```

- Example: create an AKS cluster on Azure China

    ```sh
    RESOURCE_GROUP_NAME=demo-aks
    CLUSTER_NAME=demo-aks
    LOCATION=chinaeast2  #or chinanorth2
    VERSION=1.15.10  # select an available version by "az aks get-versions -l chinaeast2 -o table"
    
    # create a resource group
    az group create -n $RESOURCE_GROUP_NAME -l $LOCATION
    
    # create AKS cluster with 1 agent node (if your azure cli version is low, remove `--disable-rbac`)
    az aks create -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --node-count 1 --node-vm-size Standard_D3_v2 --disable-rbac --generate-ssh-keys --kubernetes-version $VERSION -l $LOCATION --node-osdisk-size 128
    
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

- ACR does not provide **public anonymous access** functionality on Azure China, this feature is in [public preview](https://github.com/Azure/acr/blob/master/docs/acr-roadmap.md) on global Azure.

- AKS has good integration with ACR, container image stored in ACR could be pulled in AKS after [Configure ACR authentication](https://docs.azure.cn/zh-cn/aks/tutorial-kubernetes-deploy-cluster#configure-acr-authentication).

### 2.2 Container Registry Proxy

Since some container registries like `docker.io`, `gcr.io` are not accessible or very slow in China, we have set up container registry proxy servers for Azure China VMs:
> First docker pull of new image will be still slow, and then image would be cached, would be much faster in the next docker pull action.
 
| global | proxy in China | format | example |
| ---- | ---- | ---- | ---- |
| [dockerhub](hub.docker.com) (docker.io) | [dockerhub.azk8s.cn](http://mirror.azk8s.cn/help/docker-registry-proxy-cache.html) | `dockerhub.azk8s.cn/<repo-name>/<image-name>:<version>` | `dockerhub.azk8s.cn/microsoft/azure-cli:2.0.61` `dockerhub.azk8s.cn/library/nginx:1.15` |
| gcr.io | [gcr.azk8s.cn](http://mirror.azk8s.cn/help/gcr-proxy-cache.html) | `gcr.azk8s.cn/<repo-name>/<image-name>:<version>` | `gcr.azk8s.cn/google_containers/hyperkube-amd64:v1.13.5` |
| quay.io | [quay.azk8s.cn](http://mirror.azk8s.cn/help/quay-proxy-cache.html) | `quay.azk8s.cn/<repo-name>/<image-name>:<version>` | `quay.azk8s.cn/deis/go-dev:v1.10.0` |
| mcr.microsoft.com | mcr.azk8s.cn| `mcr.azk8s.cn/<repo-name>/<image-name>:<version>` | `mcr.azk8s.cn/oss/kubernetes/hyperkube:v1.15.7` |

> Note:
`k8s.gcr.io` would redirect to `gcr.io/google-containers`, following image urls are identical:

```
k8s.gcr.io/pause-amd64:3.1
gcr.io/google_containers/pause-amd64:3.1
```
- Container Registry Proxy Example

    specify `defaultBackend.image.repository` as `gcr.azk8s.cn/google_containers/defaultbackend` in [nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) chart since original `k8s.gcr.io` does not work in Azure China:

    ```
    helm install stable/nginx-ingress --set defaultBackend.image.repository=gcr.azk8s.cn/google_containers/defaultbackend --set defaultBackend.image.tag=1.4
    ```

## 3. Install kubectl

`az aks install-cli` command is used to download `kubectl` binary, it works on Azure China from version `2.0.61` or later, another alternative is use following command to download `kubectl` if don't have azure-cli:

```sh
# docker run -v ${HOME}:/root -v /usr/local/bin/:/kube -it dockerhub.azk8s.cn/microsoft/azure-cli:2.0.61
root@09feb993f352:/# az cloud set --name AzureChinaCloud
root@09feb993f352:/# az aks install-cli --install-location /kube/kubectl
```

 > run `sudo az aks install-cli` if hit following permission error
 > ```
 > Connection error while attempting to download client ([Errno 13] Permission denied: '/usr/local/bin/kubectl'
 > ```

## 4. Install helm

Follow detailed installation steps [here](https://mirror.azk8s.cn/help/kubernetes.html).

- Example:
```
# Install wordpress
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install bitnami/wordpress --set global.imageRegistry=dockerhub.azk8s.cn

# Install nginx-ingress
helm repo add stable https://mirror.azure.cn/kubernetes/charts/
helm install stable/nginx-ingress  --set defaultBackend.image.repository=gcr.azk8s.cn/google_containers/defaultbackend
```
  
> Note:
All kubernetes related binaries on github could be found under [https://mirror.azk8s.cn/kubernetes](https://mirror.azk8s.cn/kubernetes), e.g. helm, charts, etc.

## 5. Cluster autoscaler
 > Note: AKS integrated [Cluster-autoscaler](https://docs.microsoft.com/zh-cn/azure/aks/cluster-autoscaler) is not availalbe on Azure China now since it's still in Preview on Global Azure, instead following autoscaler is supported on Azure China now, it supports both VMAS and VMSS:
Follow detailed steps in [Cluster Autoscaler on Azure](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/azure#cluster-autoscaler-on-azure) and in `Deployment` config of `aks-cluster-autoscaler.yaml`:

- use `gcr.azk8s.cn/google-containers/cluster-autoscaler:version` instead of `gcr.io/google-containers/cluster-autoscaler:version`

- add following environment variable:

    ```
    - name: ARM_CLOUD
      value: AzureChinaCloud
    ```

    Here is the complete `Deployment` config [example](https://github.com/Azure/container-service-for-azure-china/blob/master/aks/cluster-autoscaler-deployment-mooncake.yaml).

## 6. VMSS Cluster

VMSS cluster and Multi-node pool is now available in Mooncake: https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools

> Note: Currently, only Azure CLI is supported to create VMSS cluster.
        
There's a potential issue of ARM throttling for VMSS cluster. Azure ARM API has request limits and would throttle the client if there're too many requests are sent: https://docs.azure.cn/zh-cn/azure-resource-manager/resource-manager-request-limits

A few things could reduce the API requests number:

   - Reduce number of nodes and frequency of node scaling
   - Reduce frequency of AzureDisk detaching or attaching
   - Reduce frequency of LoadBalancer typed service creating or deleting

## Hands on
 - [run a simple web application on AKS cluster](https://github.com/andyzhangx/k8s-demo/tree/master/nginx-server#nginx-server-demo)
 - [AKS workshop](https://aksworkshop.io/)

### Known issues

- RBAC related issues(RABC is enabled on AKS cluster): https://github.com/andyzhangx/demo/blob/master/issues/rbac-issues.md
 
### Tips

- For production usage:
  - agent VM size should have at least **8** CPU cores(e.g. D4_v2) since k8s components would also occupy CPU, memory resources on the node, details about [AKS resource reservation](https://docs.microsoft.com/zh-cn/azure/aks/concepts-clusters-workloads#resource-reservations).
  - it's better set a bigger os disk size on agent VM in AKS cluster creation, e.g. set `--node-osdisk-size 128`, original 30GB os disk size is not enough since all images are stored on os disk.

- [GPU workload support best practices on Azure China](https://docs.azure.cn/zh-cn/aks/gpu-cluster)

### Links
- AKS doc: https://docs.azure.cn/zh-cn/aks/

- [Azure Kubernetes Service Issues](https://github.com/Azure/AKS/)

- [Frequently asked questions about Azure Container Service (AKS)](https://docs.azure.cn/zh-cn/aks/faq)
