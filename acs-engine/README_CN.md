# 微软Azure容器服务引擎

微软容器服务引擎（`acs-engine`）用于将一个容器集群描述文件转化成一组ARM（Azure Resource Manager）模板，通过在Azure上部署这些模板，用户可以很方便地在Azure上建立一套基于Docker的容器服务集群。用户可以自由地选择集群编排引擎DC/OS, Kubernetes或者是Swarm/Swarm Mode。集群描述文件使用和ARM模板相同的语法，它们都可以用来部署Azure容器服务。关于acs-engine的详细内容请参考：https://github.com/Azure/acs-engine

## 1.  安装acs-engine（建议安装v0.9.1及后续的版本，之前的版本需要做一些额外的工作才可以工作）。支持直接安装包和通过源代码编译两种方式：
- 下载并解压具体版本的[acs-engine](https://github.com/Azure/acs-engine/releases/)，对于没有安装包的版本，可直接从国内的镜像站点下载：https://mirror.kaiyuanshe.cn/kubernetes/acs-engine/
```
  curl -LO https://mirror.kaiyuanshe.cn/kubernetes/acs-engine/v0.9.1/acs-engine-v0.9.1-linux-amd64.tar.gz
  tar -xvzf acs-engine-v0.9.1-linux-amd64.tar.gz
```
- [本地下载源代码并编译acs-engine](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.zh-CN.md)


## 2. 准备一个SSH公钥私钥对
除了使用Kubernetes APIs和集群进行交互外，还可以通过SSH的方式访问master和agent节点。如果你还没有生成SSH Key，[可以直接生成一个新的](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#ssh-key-generation)。
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
K8S集群集成了对各种云提供商核心功能的支持。在Azure上，acs-engine使用Service Principle和ARM进行交互。根据说明创建一个新的[service principal](https://github.com/Azure/acs-engine/blob/master/docs/serviceprincipal.md).
```
az cloud set -n AzureChinaCloud
az login
az account set --subscription="${SUBSCRIPTION_ID}" (if there is only one subscription, this step is optional)
az ad sp create-for-rbac --name XXX
```

## 5. 克隆并编辑Kubernetes集群定义文件[example/kubernetes.json](https://raw.githubusercontent.com/Azure/acs-engine/master/examples/kubernetes.json)，将需要的参数配置好。点击查看关于[集群定义文件](https://github.com/Azure/acs-engine/blob/master/docs/clusterdefinition.zh-CN.md)的详细说明。
* adminUsername - 修改agent用户名
* dnsPrefix - 设置集群DNS名称前缀
* keyData - 使用SSH公钥填充
* clientId - 使用Service Principle中的appId填充
* secret - 使用Service Principle中的password填充
* 在`apiVersion: "vlabs"`后面增加位置定义`"location": "chinaeast",` （这一步不能缺少）

## 6. 生成ARM模板
运行`acs-engine generate kubernetes.json`命令生成ARM模板。主要包括多个类似如下模板的文件：
* apimodel.json - 集群配置文件
* azuredeploy.json - 核心的ARM (Azure Resource Model)模板，用来部署Docker集群
* azuredeploy.parameters.json - 部署参数文件，其中的参数可以自定义
* certificate and access config files - 某些编排引擎例如kubernetes需要生成一些证书，这些证书文件和它依赖的kube config配置文件也存放在和ARM模板同级目录下面

## 7. 使用ARM模板部署K8S容器集群
```
az cloud set -n AzureChinaCloud
az login
az group create -l chinaeast -n xxx
az group deployment create -g xxx --template-file azuredeploy.json --parameters azuredeploy.parameters.json
```

## 8. 验证集群安装是否正确
SSH登录到集群master节点，并执行以下命令。如果在default和kube-system命名空间下面的services（kubernetes, heapster，kube-dns，kubernetes-dashboard，tiller-deploy）运行正常，则说明安装成功。
```
kubectl get services --all-namespaces
```

## 9. 配置Kubernetes管理网站 (可选)
> SSH登录到集群master节点
```
ssh -i <path_to_id_rsa> <adminUsername>@<master_node_fqdn>
```
> 下载 config_k8s_ui_http.sh 脚本
```
curl -LO https://raw.githubusercontent.com/Azure/devops-sample-solution-for-azure-china/acs-engine/config_k8s_ui_http.sh
```
> 通过以下命令运行脚本:
```
bash config_k8s_ui_http.sh -c <cloud_name> -g <rg_name> -t <tenant_id> -i <app_id> -s <app_secret> -u <user_name> -p <user_pass>
```
参数说明: 
* -c [Azure实例名, AzureCloud 或者 AzureChinaCloud]"
* -g [资源组名]"
* -t [Service principal tenant id, 例如. foo.onmicrosoft.com, bar.partner.onmschina.cn etc. ]"
* -i [Service principal app id]"
* -s [Service principal secret]"
* -u [Kubernetes 管理网站用户名, 默认值是 'admin']"
* -p [Kubernetes 管理网站用户密码, 默认值是 'password']"

> 通过以下链接访问Kubernetes管理网站:
```
http://<master_node_fqdn>/ui
```
