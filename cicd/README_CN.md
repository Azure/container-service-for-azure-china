# 基于 Jenkins 的持续集成和持续部署（CI/CD）管道实现

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Fmaster-dev%2Fcicd%2Farmtemplate%2Fjenkins_private_registry_k8s%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Fmaster-dev%2Fcicd%2Farmtemplate%2Fjenkins_private_registry_k8s%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

这个模板帮助你在Azure中国上快速搭建一台基于Linux Ubuntu 14.04 LTS的型号为DS1_v2的Jenkins虚拟机

另外它会创建一个Jenkins流水线，包括从一个包含dockerfile的代码仓库中迁出代码，编译并生成Docker镜像，然后将Docker镜像推送到一个私有镜像仓库，最后将镜像部署到一个Kubernetes集群。

## A. 部署一个内嵌了包含编译和发布Docker镜像流水线的Jenkins虚拟机
1. 点击 "Deploy to Azure" 按钮. 如果你还没有Azure中国的订阅，可以到[Azure中国的官网](http://www.azure.cn)申请订阅并免费试用.
1. 输入用来部署Jenkins虚拟机的用户名和密码，并提供虚拟机的DNS前缀。
1. 输入一个代码仓库，代码仓库必须在根目录中包含一个Dockerfile。
1. 提供一个私有Docker镜像仓库的地址， 以及登陆的用户名和密码。(如果使用本项目中部署的HTTP private registry，镜像仓库地址应为http://< DNS or Public IP >:5000)
1. 提供Kubernetes master FQDN, 用户名和私有的encode过的key [base64](https://en.wikipedia.org/wiki/Base64),流水线会部署一个示例项目到kubernetes集群中. 你可以使用[在线工具](https://www.bing.com/search?q=base64+encode&qs=AS&pq=base64+&sk=AS1&sc=8-7&cvid=FFECC475833E43958634B83EA90B2364&FORM=QBLH&sp=2) 进行encode.

## B. 配置 SSH port forwarding
**默认Jenkins使用http协议， 监听8080端口，用户不能通过不安全的协议被验证!**

你需要配置端口forwarding以在你本机打开Jenkins的图形界面，如果你不知道虚拟机的完整DNS名字，可以通过: `Resource Groups > {Resource Group Name} > Deployments > {Deployment Name, usually 'Microsoft.Template'} > Outputs`来查看。

### 如果你使用Windows系统:
安装putty并运行以下命令

```
putty.exe -ssh -L 8080:localhost:8080 <User name>@<Public DNS name of instance you just created>
```

或者通过以下步骤手动操作:
1. 打开putty,选则 'Connection > SSH > Tunnels'
1. 在 Options controlling SSH port forwarding 界面,  输入8080端口. 然后输入 127.0.0.1:8080作为目标. 点击添加
1. 点击 Open to establish the connection.

### 如果你使用的是 Linux or Mac:
运行以下命令:
```bash
ssh -L 8080:localhost:8080 <User name>@<Public DNS name of instance you just created>
```

## C. 连接 Jenkins

1. 当你配置了ssh forwarding以后，你可以在本机上通过 http://localhost:8080/ 访问jenkins的管理界面.
1. 第一次登陆jenkins管理界面需要一个token, 你可以登陆到虚拟机然后运行 `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` 查看token.
1. 现在你可以开始使用jenkins了! 或者你可以通过http://< Public DNS name of instance you just created > 查看一个不可修改的jenkins管理界面.
1. 如果你想利用Azure VM作为jenkins的agent，可以安装插件 http://aka.ms/azjenkinsagents

## 注意事项
如果你使用的是不安全的私有镜像仓库， 例如你是通过http而不是https访问镜像仓库，或者你使用的证书没有被授信。你需要在jenkins master和kubernets集群的每个节点上都运行以下命令
```bash
sudo touch /etc/docker/daemon.json
sudo vim /etc/docker/daemon.json
```
then add below entry to configuration:

{"insecure-registries" : [ "私有镜像仓库的DNS/IP：端口" ]}

then save the changes and run below command to restart docker
```bash
sudo service docker restart
```

## 示例项目
这个模板中包含的jenkins流水线基于示例项目(https://github.com/azure-devops/spin-kub-demo).你可以使用你自己的项目，但需要更新jenkins流水线中编译和部署的脚本。

## 故障排除

如果部署出现错误，或者部署成功后不能成功访问Jeknis UI，需要登陆到跳板机上（使用部署模板中提供的用户名密码），访问/var/lib/waagent/custom-script/download/0/目录，检查stdout和stderr两个文件的内容，获得所有安装过程信息。

## 参考项目

### [Azure-devops-utils](https://github.com/Azure/azure-devops-utils) (MIT License)

This repository contains utility scripts to run/configure DevOp systems in Azure.
