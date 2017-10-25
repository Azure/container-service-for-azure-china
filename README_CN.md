# DevOps开源解决方案

## 概览

此开源解决方案帮助用户快速搭建基于Azure容器技术的微服务和DevOps容器集群，并提供基于Jenkins的持续集成和持续部署管道，以及基于ELK和Grafana的监控和分析实现。主要包括下面几个组成部分：
* 容器集群: 使用[acs-engine](https://github.com/Azure/acs-engine)创建容器集群，用户可以选择DC/OS，Kubernetes，Swarm作为编排工具。在这个项目中，我们选择Kubernetes作为参考实现。
* 私有镜像仓库: store custom images
* CI/CD管道: which checks out project in git, build it as docker images and publish an Kubernetes clusters. 
* 监控和日志: cluster resource monitoring and container/app monitoring

## 架构

CI/CD开源解决方案：
![Image of CI/CD architecture](doc/imgs/cicd_architecture.png)
Currently we only support to deploy application to kubernetes cluster, we will add support for service fabric and other orchestrators in following releases.

监控和日志参考架构：
![Image of monitor architecture](doc/imgs/monitor.png)

## 用户指南

If you'd like to deploy from beginning, please follow below holistic steps. If you already have some components being used in your project, you could pick the missing parts from this project and deploy it separately.

* [Deploy a Kubernetes cluster using ACS Engine](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md) - shows you how to use the ACS engine to build custom Docker enabled container clusters
* [Deploy a Private docker registry](azure-docker-registry/README.md) - describes how to deploy a secure private docker registry
* [CI/CD pipeline](cicd/armtemplate/jenkins_private_registry_k8s/README.md) - shows how to deploy a Jenkins master and create pipeline which includes below five stages :
    * Check out git repro
    * Build Docker images 
    * Push docker image to private docker registry 
    * Test and validation 
    * Deploy to Kubernetes 
* [Monitor](monitoring/k8s/README.md) - shows how to set up monitoring stack

