## 1. 下载并解压最近的[acs-engine](https://github.com/Azure/acs-engine/releases/tag/v0.8.0), 也可以下载源代码进行编译
```
curl -LO https://github.com/Azure/acs-engine/releases/download/v0.8.0/acs-engine-v0.8.0-linux-amd64.tar.gz
tar -xvzf acs-engine-v0.8.0-linux-amd64.tar.gz
```
## 2. 准备一个[SSH公钥私钥对](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#ssh-key-generation)
```
ssh-keygen -t rsa
```
## 3. [安装azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
```
sudo su
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
apt-get install -y apt-transport-https
apt-get update
 apt-get install -y azure-cli
```
## 4. 创建Service Principle
```
az cloud set -n AzureChinaCloud
az login
az account set --subscription="${SUBSCRIPTION_ID}" (if there is only one subscription, this step is optional)
az ad sp create-for-rbac --name XXX
```
## 5. 编辑[kubernetes.json](https://raw.githubusercontent.com/Azure/acs-engine/master/examples/kubernetes.json),将其需要的参数配置好
* dnsPrefix：设置集群DNS名称前缀
* keyData：对应于SSH公钥
* clientId: 对应于Service Principle中的appId
* secret：对应于Service Principle中的password
* 在apiVersion: "vlabs"后面增加位置信息"location": "chinaeast",
## 6. 生成ARM模板
运行`acs-engine generate kubernetes.json`命令生成ARM模板
## 7. 使用ARM模板部署K8S容器集群
```
az cloud set -n AzureChinaCloud
az login
az group create -l chinaeast -n xxx
az group deployment create -g xxx --template-file azuredeploy.json --parameters azuredeploy.parameters.json
```
## 8. 验证集群安装是否正确
登录集群master node，并执行以下命令
```
kubectl get pods --all-namespaces
```
