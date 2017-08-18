# Microservices on Container Reference Architecture

## Overview

Microservices on container reference architecture includes ARM(Azure Resource Manager) templates and scrips help users to set up container based DevOps pipeline quickly and easily on Microsoft Azure China by leveraging open source software as our toolchains.

It includes below components:
* Container Clusters: Created by [ACS Engine](https://github.com/Azure/acs-engine), users could choose DC/OS, Kubernetes, or Swarm as the orchestrator. We choose Kubernetes as the implementation reference in this project.
* Private Docker registry: store custom images
* CI/CD Pipeline: which checks out project in git, build it as docker images and publish an Kubernetes clusters. 
* Monitoring Stack: cluster resource monitoring and container/app monitoring

## Architecture

CI/CD with Open Source Toolchain:
![Image of CI/CD architecture](doc/imgs/cicd_architecture.png)

Monitor with OSS Solution:
![Image of monitor architecture](doc/imgs/monitor.png)

## User guides

If you'd like to deploy from beginning, please follow below holistic steps. If you already have some components being used in your project, you could pick the missing parts from this project and deploy it separately.

* [Deploy a Kubernetes cluster using ACS Engine](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md) - shows you how to use the ACS engine to build custom Docker enabled container clusters
* [Deploy a Private docker registry](azure-docker-registry/README.md) - describes how to deploy a secure private docker registry
* [CI/CD pipeline](cicd/README.md) - shows how to deploy a Jenkins master and create pipeline which includes below 5 steps:
    * Check out git repro
    * Build Docker images 
    * Push docker image to private docker registry 
    * Test and validation 
    * Deploy to Kubernetes 
* [Monitor](monitoring/k8s/README.md) - shows how to set up monitoring stack

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
