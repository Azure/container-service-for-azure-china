## GPU workload support on Azure China AKS
[Use GPUs for compute-intensive workloads on Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/gpu-cluster) provides detailed steps about how to run GPU workloads on AKS cluster, while there are some configurations needed to change on Azure China. e.g. following docker hub images should be changed to use `dockerhub.azk8s.cn`:

| original image in doc | supported images on Azure China |
| ---- | ---- |
| k8s-device-plugin:1.11 | dockerhub.azk8s.cn/nvidia/k8s-device-plugin:1.11 |
| microsoft/samples-tf-mnist-demo:gpu | dockerhub.azk8s.cn/microsoft/samples-tf-mnist-demo:gpu |

Below are detailed steps about how to run GPU workload on Azure China AKS cluster: 

## 1. set up AKS cluster on GPU enabled VM
> Below example sets `node-vm-size` as `Standard_NC6s_v3` which supports GPU on Azure China, on global azure, `node-vm-size` could be `Standard_NC6` etc.

```sh
RESOURCE_GROUP_NAME=demo-gpu1126
CLUSTER_NAME=demo-gpu1126
LOCATION=chinaeast2
az group create -n $RESOURCE_GROUP_NAME -l $LOCATION
		 
az aks create -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --node-count 1 --node-vm-size Standard_NC6s_v3 --disable-rbac --generate-ssh-keys --kubernetes-version 1.12.6 -l $LOCATION	
az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
kubectl get nodes
```

## 2. install GPU plugin on AKS cluster
```sh
kubectl create -f https://raw.githubusercontent.com/andyzhangx/demo/master/linux/gpu/nvidia-device-plugin-ds-mooncake.yaml
```

## 3. Run GPU workload on AKS cluster
```sh
kubectl create -f https://raw.githubusercontent.com/andyzhangx/demo/master/linux/gpu/gpu-demo-mooncake.yaml
```

For more detailed steps, refer to [Use GPUs for compute-intensive workloads on Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/gpu-cluster) 
