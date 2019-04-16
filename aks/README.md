# AKS on Azure China Best Practices

Azure Kubernetes Service is in **Public Preview**, this page provides best practices about how to use AKS on Azure China cloud.

- Contact AKS China Team: [akscn@microsoft.com](mailto:akscn@microsoft.com)

## Limitations of current AKS Public Preview on Azure China

- AKS monitoring and logging are not available, there will be error when clicking on `Monitor containers` and `View logs` links in AKS overview page.

- AKS addons are not enabled on Azure China yet, including `monitoring` and `http_application_routing` addons.
  > note: for [`http_application_routing`](https://docs.microsoft.com/en-us/azure/aks/http-application-routing) addon functionality, it's not for production use, you could use [ingress controller](https://docs.microsoft.com/en-us/azure/aks/ingress-basic) instead.

- Preview features on Global Azure won't be supported on Azure China, e.g. [Network Policy](https://docs.microsoft.com/en-us/azure/aks/use-network-policies)
- [AAD integration support with AKS](https://docs.microsoft.com/en-us/azure/aks/aad-integration) requires kubectl version >= `v1.14.0`, download `kubectl` binary from [here](https://mirror.azure.cn/kubernetes/kubectl/v1.14.0/bin/)

## 1. How to create AKS on Azure China

Currently AKS on Azure China could only be created by [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and only supports `chinaeast2`, `chinanorth2` regions.

- How to use [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) on Azure China.

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
    -------------------  ------------------------
    1.12.6               None available
    1.12.5               1.12.6
    1.11.8               1.12.5, 1.12.6
    1.11.7               1.11.8, 1.12.5, 1.12.6
    1.10.13              1.11.7, 1.11.8
    1.10.12              1.10.13, 1.11.7, 1.11.8
    1.9.11               1.10.12, 1.10.13
    1.9.10               1.9.11, 1.10.12, 1.10.13
    ```

- Example: create a `v1.11.5` AKS cluster on `chinaeast2`

    ```sh
    RESOURCE_GROUP_NAME=demo-aks
    CLUSTER_NAME=demo-aks
    LOCATION=chinaeast2  #or chinanorth2
    VERSION=1.11.5
    
    # create a resource group
    az group create -n $RESOURCE_GROUP_NAME -l $LOCATION
    
    # create AKS cluster with 1 agent node (if your azure cli version is low, remove `--disable-rbac`)
    az aks create -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --node-count 1 --node-vm-size Standard_D3_v2 --disable-rbac --generate-ssh-keys --kubernetes-version $VERSION -l $LOCATION
    
    # wait about 10 min for `az aks create` running complete
    
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
 
    > Detailed "az aks" command line manual could be found [here](https://docs.microsoft.com/en-us/cli/azure/aks)


## 2. Container Registry

### 2.1 Azure Container Registry(ACR)

[Azure Container Registry](https://azure.microsoft.com/en-us/services/container-registry/)(ACR) provides storage of private Docker container images, enabling fast, scalable retrieval, and network-close deployment of container workloads on Azure. It's now available on `chinanorth` region.

- ACR does not provide **public anonymous access** functionality.

- AKS has good integration with ACR, container image stored in ACR could be pulled in AKS after [Configure ACR authentication](https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster#configure-acr-authentication).

### 2.2 Container Registry Proxy

Since some well known container registries like `docker.io`, `gcr.io` are not accessible or very slow in China, we have set up container registry proxies in `chinaeast2` region for **public anonymous access**:

> The first docker pull of new image will be slow, and then image would be cached, would be much faster in the next docker pull action.
 
| global | proxy in China | Example |
| ---- | ---- | ---- |
| [dockerhub](hub.docker.com) (docker.io) | [dockerhub.azk8s.cn](http://mirror.azk8s.cn/help/docker-registry-proxy-cache.html) | `dockerhub.azk8s.cn/library/nginx`|
| gcr.io | [gcr.azk8s.cn](http://mirror.azk8s.cn/help/gcr-proxy-cache.html) | `gcr.azk8s.cn/google_containers/hyperkube-amd64:v1.9.2` |
| quay.io | [quay.azk8s.cn](http://mirror.azk8s.cn/help/quay-proxy-cache.html) | `quay.azk8s.cn/deis/go-dev:v1.10.0` |

> Note:
`k8s.gcr.io` would redirect to `gcr.io/google-containers`, following image urls are identical:

```
k8s.gcr.io/pause-amd64:3.1
gcr.io/google_containers/pause-amd64:3.1
```
- Container Registry Proxy Example

    specify `defaultBackend.image.repository` as `gcr.azk8s.cn/google_containers/defaultbackend` in [nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) chart since original `k8s.gcr.io` does not work in Azure China:

    ```
    helm install stable/nginx-ingress --name ingress --namespace kube-system --set controller.replicaCount=2 --set defaultBackend.image.repository=gcr.azk8s.cn/google_containers/defaultbackend --set rbac.create=false --set rbac.createRole=false --set rbac.createClusterRole=false
    ```

## 3. Install kubectl

Original `az aks install-cli` command does not work on Azure China, follow detailed steps [here](https://mirror.azk8s.cn/help/kubernetes.html)

- There is a PR [add "az aks install-cli" support for Azure China](https://github.com/Azure/azure-cli/pull/8675) to fix this issue, following command will start up containerized azure-cli(`dockerhub.azk8s.cn/andyzhangx/azure-cli:v2.0.60-china`) to download latest `kubectl` version to `/usr/local/bin/` on Linux:

    ```
    # docker run -v ${HOME}:/root -v /usr/local/bin/:/kube -it dockerhub.azk8s.cn/andyzhangx/azure-cli:v2.0.60-china
    root@09feb993f352:/# az cloud set --name AzureChinaCloud
    root@09feb993f352:/# az aks install-cli --install-location /kube/kubectl
    ```

## 4. Install helm

Follow detailed steps [here](https://mirror.azk8s.cn/help/kubernetes.html).

- Example: 
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install bitnami/wordpress --set global.imageRegistry=dockerhub.azk8s.cn
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

## Hands on
 - [run a simple web application on AKS cluster](https://github.com/andyzhangx/k8s-demo/tree/master/nginx-server#nginx-server-demo)
 - [AKS workshop](https://aksworkshop.io/)

### Known issues

- RBAC related issues(RABC is enabled on AKS cluster): https://github.com/andyzhangx/demo/blob/master/issues/rbac-issues.md
 
### Tips

- For production usage, agent VM size should have at least **8** CPU cores(e.g. D4_v2) since k8s components would also occupy CPU, memory resources on the node, details about [AKS resource reservation](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#resource-reservations).

- [GPU workload support best practices on Azure China](./gpu-support.md)

### Links
- AKS doc: https://docs.azure.cn/zh-cn/aks/

- [Azure Kubernetes Service Issues](https://github.com/Azure/AKS/)

- [Frequently asked questions about Azure Container Service (AKS)](https://docs.microsoft.com/zh-cn/azure/aks/faq)
