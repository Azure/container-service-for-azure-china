We use [eshop](https://github.com/dotnet-architecture/eShopOnContainers) as a sample to demonstrate how to setup the environment with CI/CD and monitoring. We will take WebMVC as the sample app for testing CI/CD (updating the image) and monitoring.

## Prerequisite
* Azure China Cloud subscription
* Existing Kubernetes cluster 

## A. Deploy eshop services on Kubernetes cluster

To enable eshop services on Mooncake, we've updated the offical deployment script from [eshop k8s deployment](https://github.com/dotnet-architecture/eShopOnContainers/tree/dev/k8s), by pulling images from Mooncake proxy server.
1. Fork the repo from [sampleapp-eshop](https://github.com/mizow8/sampleapp-eshop)
2. In Powershell, run k8s/deploy.ps1 as below:
    ```bash
    ./deploy.ps1 -configFile ./conf_local.yml -buildImages $false -imageTag latest -registry crproxy.trafficmanager.net:5000 -dockerOrg ccgmsref -imagePrefix eshop_
    ```
   After this command run successfully, you will see the deployments and services of eshop on your Kubernetes cluster. 
   
   Check the frontend by accessing http://< externalDns >/webmvc. 
3. Browse the sampleapp-eshop.sln and /src folder in this repo, which is the source code of WebMVC that we will customize later.

## B. Setup CI/CD

1. Follow the [instruction](https://github.com/Azure/microservice-reference-architectures/tree/eshop/cicd) to setup CI/CD, with setting gitRepository to the sample repo forked in Step A.
2. Once jenkins runs successfully, make a change in the sample repo (e.g. change color in src/Web/WebMVC/wwwroot/css/_variables.scss) and commit. Check if the jenkins job run successfully, and once completed access http://< externalDns >/webmvc again to see if the change applied.

## C. Setup Monitoring

1. Follow the [instruction](https://github.com/Azure/microservice-reference-architectures/tree/eshop/monitoring) to setup monitoring stacks.
2. In the last step, customize the config for data collection. Edit monitoring/k8s/helm-charts/configs/heartbeat-config with 
    ```bash
    urls: ["http://< externalDns >/webmvc"]
    ```
   And then update the helm chart following the instruction.

