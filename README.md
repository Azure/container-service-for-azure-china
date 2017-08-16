# Microsoft Microservice reference Architectures

## Overview

Microsoft Microservice reference Architectures includes generates ARM (Azure Resource Manager) templates and scrips helper users to set up container based DevOps pipeline on Microsoft Azure China. We primarily leverage Open source software as our toolchains.

It includes below components
* Private Docker registry
* A sample CI/CD pipeline: which checks out project in git, build it as docker images and publish an Kubernetes clusters. 
* Container clusters: Created by[ACS-Engine](https://github.com/Azure/acs-engine), users could choose DC/OS, Kubernetes, Swarm  Mode, or Swarm as orchestrators. In our sample project we choose Kubernetes.
* Monitoring:

##Architecture
Below picture shows the design of CI/CD pipeline
![Image of CI/CD architecture](doc/imgs/cicd_architecture.png)

## User guides

If you deploy from beginning you could follow below steps to deploy the whole end to end pipeline. If you already have some devops components using in your project. You could pick one the missing parts from this project and deploy it separately.

* [Deploy a Kubernetes cluster using ACS Engine](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md) - shows you how to build and use the ACS engine to generate custom Docker enabled container clusters
* [Deploy a Private docker registry](azure-docker-registry/README.md) - describes how to deploy a secure private docker registry
* [CI/CD pipeline](cicd/README.md) - shows how to deploy a Jenkins master and create pipeline which includes below five stages :
    * Check out git repro
    * Build Docker Images 
    * Push docker image to private docker registry 
    * Test and Validation 
    * Deploy to Kubernetes 
* [Monitoring](docs/kubernetes.md) - shows how to set up monitoring infrastructure 

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.