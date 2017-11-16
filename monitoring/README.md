# Kubernetes based microservice monitoring solution on Azure platform.

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Fmaster-dev%2Fmonitoring%2Fk8s%2Fdeployment%2Fcontroller_template.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Fmaster-dev%2Fmonitoring%2Fk8s%2Fdeployment%2Fcontroller_template.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This ARM template will deploy a controller VM of Linux Ubuntu 16.04 with default size Standard_A1 in Azure China.

The controller VM will access and manage the Kubernetes cluster you provided, by installing helm charts for monitoring, and acting as proxy of the cluster for accessing.

Two monitoring stacks will be installed:

* Heapster + Influxdb + Grafana
* Beats + Logstash + Elasticsearch + Kibana (ELK)

The first one is for cluster resource monitoring (e.g. CPU and memory of Node and Pod), and the second one is for container/app monitoring (e.g. logs of container and heartbeat of the service).

## Prerequisite
* Azure China Cloud subscription
* Existing Kubernetes cluster 

## A. Deploy a controller VM for installing monitoring stacks
1. Click the "Deply to Azure" button 
2. Enter the deployment parameters

| Parameter                       | Descrption                                                               | Default Value   |
|---------------------------------|--------------------------------------------------------------------------|-----------------|
| vmDnsName                       | DNS name of the controller VM                                            |                 |
| vmAdminUsername                 | Administrator user name for the controller VM                            | azureuser       |
| vmAdminPassword                 | Administrator password to login controller VM                            |                 |
| vmUbuntuOSVersion               | The Ubuntu version for the controller VM                                 | 16.04.0-LTS     |
| vmSize                          | The size of the Virtual Machine as controller                            | Standard_A1     |
| k8sMasterNodeHostname           | Kubernetes cluster master node hostname                                  |                 |
| k8sMasterNodeUsername           | Kubernetes cluster master node username                                  |                 |
| k8sMasterNodeIdentityFileBase64 | Kubernetes cluster master node identity file in base64 encoded string    |                 |
| monitorClusterNamespace         | Monitoring cluster namespace in Kubernetes                               |                 |
| azureCloudEnvironment           | Azure cloud environment 'AzureCloud' or 'AzureChinaCloud'                | AzureChinaCloud |
| enableElkStack                  | Feature flag to enable ELK monitoring stack or not                       | enabled         |
| enableHigStack                  | Feature flag to enable Heapster-InfluxDB-Grafana monitoring stack or not | enabled         |


## B. Connect to the controller VM
1. Once the deployment completed, get the Public IP address and DNS of the controller VM
2. SSH into the VM, with the admin username and password provided in deployment parameters
3. Run the kubectl command below to check if the VM accesses Kubernetes correctly
```
Kubectl cluster-info
```
4. Open a brower, and go to http://< DNS or Public IP address of controller VM >/ui, with the admin username and password provided in deployment parameters, to check if the Kubernetes UI shows correctly

## C. Customize the config for data collection
[Beats](https://www.elastic.co/products/beats) are the data shipper which ships kinds of data to ELK stack. Currently we install [Filebeat](https://www.elastic.co/products/beats/filebeat) for shipping container logs, and [Heartbeat](https://www.elastic.co/products/beats/heartbeat) for service health check.

You can config the Beats per your request, following the official documentation. Here we take Heartbeat as an example to show how to customize the config.

1. SSH into the controller VM, switch to root account (sudo -i)
2. Go to /tmp/install/msref, this is where the repo file downloaded
3. Go to monitoring/k8s/helm-charts/configs/heartbeat-config, edit heartbeat.yml (reference [Heartbeat Configuration Options](https://www.elastic.co/guide/en/beats/heartbeat/current/heartbeat-configuration-details.html))
4. Go back to  monitoring/k8s/helm-charts, run the commands below
```
yes | cp -rf configs/heartbeat-config/heartbeat.yml heartbeat/config
helm upgrade -f configs/heartbeat.yaml heartbeat heartbeat/
```

## D. View the monitoring stacks
1. In kubernetes UI, browse the namespace in which the monitoring stacks are deployed
2. In Services, Grafana and Kibana are exposed as a services with Public IP address
3. Go to Grafana portal, check if there are dashboards of Node and Pod, and if the data show correctly
4. Go to Kibana portal, make sure the two indexes are added (if not, add by yourself)
   * filebeat-*
   * heartbeat-* （should be automatically added after step C）
   In Discovery page, check if there are data corrected for these two indexes. And in Dashboard page, check if there's a dashboard of Heartbeat HTTP monitoring.

## Troubleshooting

If the deployment does not succeed, or after succeed there's no monitoring stacks deploymented, please ssh to the controller VM with the admin username and password provided in ARM template. Go to /var/lib/waagent/custom-script/download/0/ to check the stdout and stderr files with all the installation details in them.


## Reference GitHub projects

### [elk-acs-kubernetes](https://github.com/Microsoft/elk-acs-kubernetes) (MIT License)

This repo contains tools that enable user to deploy ELK stack in Kubernetes cluster hosted in Azure Container Service.

### [charts](https://github.com/kubernetes/charts) (Apach-2.0 License)

Use this repository to submit official Charts for Kubernetes Helm. Charts are curated application definitions for Kubernetes Helm. For more information about installing and using Helm, see its README.md. To get a quick introduction to Charts see this chart document.