# Jenkins to Private Docker Registry to Kubernetes cluster

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Feshop%2Fcicd%2Farmtemplate%2Fjenkins_private_registry_k8s%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Feshop%2Fcicd%2Farmtemplate%2Fjenkins_private_registry_k8s%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

The template allows you to host an instance of Jenkins on a DS1_v2 size Linux Ubuntu 14.04 LTS VM in Azure China. 

It also includes a basic Jenkins pipeline that will checkout a sample git repository with a Dockerfile embedded and it will build and push the Docker container in the provisioned private docker registry you provided, then deploy it to Kubernetes cluster.

## A. Deploy a Jenkins VM with an embedded Docker build and publish pipeline
1. Click the "Deploy to Azure" button. If you don't have an Azure subscription, you can follow instructions to signup for a free trial.
1. Enter the desired user name and password for the VM that's going to host the Jenkins instance. Also provide a DNS prefix for your VM.
1. Enter the appId and appKey for your Service Principal (used by the Jenkins pipeline to push the built docker container). If you don't have a service principal, use the [Azure CLI 2.0](https://docs.microsoft.com/cli/azure/install-azure-cli) to create one (see [here](https://docs.microsoft.com/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2fazure%2fazure-resource-manager%2ftoc.json) for more details):
    ```bash
    az cloud set -n AzureChinaCloud
    az login 
    az account set --subscription <Subscription ID>
    az ad sp create-for-rbac --name "Jenkins"
    ```
    > NOTE: You can run `az account list` after you login to get a list of subscription IDs for your account.
1. Enter a public git repository. The repository must have a Dockerfile in its root.
1. Provide a private Docker registry url , login user name and password
1. The Kubernetes master FQDN, user name and private key which is [base64](https://en.wikipedia.org/wiki/Base64) encoded, the pipeline will deploy sample project to this kubernetes cluster. You could use some online [tool](https://www.bing.com/search?q=base64+encode&qs=AS&pq=base64+&sk=AS1&sc=8-7&cvid=FFECC475833E43958634B83EA90B2364&FORM=QBLH&sp=2) to do encode.

## B. Setup SSH port forwarding
**By default the Jenkins instance is using the http protocol and listens on port 8080. Users shouldn't authenticate over unsecured protocols!**

You need to setup port forwarding to view the Jenkins UI on your local machine. If you do not know the full DNS name of your instance, go to the Portal and find it in the deployment outputs here: `Resource Groups > {Resource Group Name} > Deployments > {Deployment Name, usually 'Microsoft.Template'} > Outputs`

### If you are using Windows:
Install Putty or use any bash shell for Windows (if using a bash shell, follow the instructions for Linux or Mac).

Run this command:
```
putty.exe -ssh -L 8080:localhost:8080 <User name>@<Public DNS name of instance you just created>
```

Or follow these manual steps:
1. Launch Putty and navigate to 'Connection > SSH > Tunnels'
1. In the Options controlling SSH port forwarding window, enter 8080 for Source port. Then enter 127.0.0.1:8080 for the Destination. Click Add.
1. Click Open to establish the connection.

### If you are using Linux or Mac:
Run this command:
```bash
ssh -L 8080:localhost:8080 <User name>@<Public DNS name of instance you just created>
```

## C. Connect to Jenkins

1. After you have started your tunnel, navigate to http://localhost:8080/ on your local machine.
1. Unlock the Jenkins dashboard for the first time with the initial admin password. To get this token, SSH into the VM and run `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
1. Your Jenkins instance is now ready to use! You can access a read-only view by going to http://< Public DNS name of instance you just created >.
1. Go to http://aka.ms/azjenkinsagents if you want to build/CI from this Jenkins master using Azure VM agents.

## Important notes
If you are using unsecured private docker registry for example if your docker registry use http instead of https or your certs are not CA signed. You need to do below command on jenkins master all nodes in kuernetes cluster to make whole pipleline works
```bash
sudo touch /etc/docker/daemon.json
sudo vim /etc/docker/daemon.json
```
then add below entry to configuration:

{"insecure-registries" : [ "139.217.12.139" ]}

then save the changes and run below command to restart docker
```bash
sudo service restart docker
```

## Sample applications
The pipeline included in this template is based on the sample application(https://github.com/azure-devops/spin-kub-demo) to do build and deployment. You could use your own application, but the build and deployment scripts in Jenkins may need to be updated accordingly.


## Reference GitHub projects

### [Azure-devops-utils](https://github.com/Azure/azure-devops-utils) (MIT License)

This repository contains utility scripts to run/configure DevOp systems in Azure.